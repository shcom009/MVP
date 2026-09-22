-- Put a small, explicitly named source group ahead of a broad category only
-- when its label contains both the anchor pronunciation and a meaning token.
-- Semantic groups remain first, and noisy or large source groups remain last.

create or replace function public.get_learning_associations(
  p_expression_ids bigint[],
  p_limit_per_group integer default 24
)
returns table(
  anchor_expression_id bigint,
  group_id bigint,
  group_label text,
  group_type text,
  group_member_count bigint,
  target_expression_id bigint,
  meaning_text text,
  display_pronunciation text,
  member_role text,
  association_level smallint,
  display_order integer
)
language sql
stable
security invoker
set search_path = public, pg_temp
as $function$
  with input_ids as (
    select distinct id as expression_id
    from unnest(coalesce(p_expression_ids, array[]::bigint[])) id
    where id is not null
  ), raw_candidates as (
    select
      i.expression_id as anchor_expression_id,
      anchor_e.display_pronunciation as anchor_display_pronunciation,
      anchor_em.meaning_text as anchor_meaning_text,
      g.id as group_id,
      g.label as group_label,
      g.group_type,
      g.display_order as group_display_order,
      m_anchor.association_level as anchor_level,
      m_target.expression_id as target_expression_id,
      em.meaning_text,
      e.display_pronunciation,
      m_target.member_role,
      m_target.association_level,
      m_target.display_order,
      regexp_replace(
        lower(e.display_pronunciation),
        '[^[:alnum:]가-힣ぁ-んァ-ヶ一-龠]', '', 'g'
      ) || '|' || regexp_replace(
        lower(em.meaning_text),
        '[^[:alnum:]가-힣ぁ-んァ-ヶ一-龠]', '', 'g'
      ) as target_display_key,
      row_number() over (
        partition by
          i.expression_id,
          g.id,
          regexp_replace(lower(e.display_pronunciation), '[^[:alnum:]가-힣ぁ-んァ-ヶ一-龠]', '', 'g'),
          regexp_replace(lower(em.meaning_text), '[^[:alnum:]가-힣ぁ-んァ-ヶ一-龠]', '', 'g')
        order by
          m_target.association_level,
          coalesce(m_target.display_order, 2147483647),
          m_target.expression_id
      ) as duplicate_order
    from input_ids i
    join public.expression anchor_e
      on anchor_e.id = i.expression_id
     and anchor_e.status = 'ACTIVE'
    join public.expression_meaning anchor_em
      on anchor_em.expression_id = anchor_e.id
     and anchor_em.is_primary = true
    join public.learning_association_member m_anchor
      on m_anchor.expression_id = i.expression_id
    join public.learning_association_group g
      on g.id = m_anchor.group_id
     and g.status = 'ACTIVE'
    join public.learning_association_member m_target
      on m_target.group_id = g.id
     and m_target.expression_id <> i.expression_id
    join public.expression e
      on e.id = m_target.expression_id
     and e.status = 'ACTIVE'
    join public.expression_meaning em
      on em.expression_id = e.id
     and em.is_primary = true
  ), unique_candidates as (
    select *
    from raw_candidates
    where duplicate_order = 1
  ), preferred_target_ids as materialized (
    select distinct anchor_expression_id, target_expression_id
    from unique_candidates
    where group_type in ('SEMANTIC', 'CATEGORY')
  ), preferred_display_keys as materialized (
    select distinct anchor_expression_id, target_display_key
    from unique_candidates
    where group_type in ('SEMANTIC', 'CATEGORY')
  ), display_candidates as (
    select preferred_candidate.*
    from unique_candidates preferred_candidate
    where preferred_candidate.group_type <> 'SOURCE_MEMO'

    union all

    select source_candidate.*
    from unique_candidates source_candidate
    left join preferred_target_ids target_match
      on target_match.anchor_expression_id = source_candidate.anchor_expression_id
     and target_match.target_expression_id = source_candidate.target_expression_id
    left join preferred_display_keys display_match
      on display_match.anchor_expression_id = source_candidate.anchor_expression_id
     and display_match.target_display_key = source_candidate.target_display_key
    where source_candidate.group_type = 'SOURCE_MEMO'
      and target_match.target_expression_id is null
      and display_match.target_display_key is null
  ), ranked as (
    select
      d.*,
      count(*) over (
        partition by d.anchor_expression_id, d.group_id
      ) as group_member_count,
      row_number() over (
        partition by d.anchor_expression_id, d.group_id
        order by
          d.association_level,
          char_length(regexp_replace(d.display_pronunciation, '[[:space:]]', '', 'g')),
          (d.display_pronunciation ~ '[[:space:]]')::integer,
          coalesce(d.display_order, 2147483647),
          d.target_expression_id
      ) as result_order
    from display_candidates d
  ), scored as (
    select
      r.*,
      case
        when r.group_type = 'SEMANTIC' then 1
        when r.group_type = 'SOURCE_MEMO'
         and r.group_member_count <= 12
         and regexp_replace(
               lower(r.group_label),
               '[^[:alnum:]가-힣ぁ-んァ-ヶ一-龠]', '', 'g'
             ) like '%' || regexp_replace(
               lower(r.anchor_display_pronunciation),
               '[^[:alnum:]가-힣ぁ-んァ-ヶ一-龠]', '', 'g'
             ) || '%'
         and exists (
           select 1
           from regexp_split_to_table(
             lower(r.anchor_meaning_text),
             '[^[:alnum:]가-힣ぁ-んァ-ヶ一-龠]+'
           ) token
           where char_length(token) >= 1
             and regexp_replace(
                   lower(r.group_label),
                   '[^[:alnum:]가-힣ぁ-んァ-ヶ一-龠]', '', 'g'
                 ) like '%' || token || '%'
         ) then 2
        when r.group_type = 'CATEGORY' then 3
        else 4
      end as group_relevance_order
    from ranked r
  )
  select
    r.anchor_expression_id,
    r.group_id,
    r.group_label,
    r.group_type,
    r.group_member_count,
    r.target_expression_id,
    r.meaning_text,
    r.display_pronunciation,
    r.member_role,
    r.association_level,
    r.display_order
  from scored r
  where r.result_order <= least(greatest(coalesce(p_limit_per_group, 24), 1), 50)
  order by
    r.anchor_expression_id,
    r.group_relevance_order,
    r.anchor_level,
    r.group_display_order,
    r.group_member_count,
    r.group_label,
    r.result_order;
$function$;

revoke all on function public.get_learning_associations(bigint[], integer)
  from public;
grant execute on function public.get_learning_associations(bigint[], integer)
  to anon, authenticated;
