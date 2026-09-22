-- Keep source-memo provenance intact while removing targets that are already
-- exposed by a higher-priority semantic or category group for the same anchor.
-- A partially overlapping source group keeps its unique targets; an exact
-- duplicate naturally disappears from the public lookup output.

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
as $$
  with input_ids as (
    select distinct id as expression_id
    from unnest(coalesce(p_expression_ids, array[]::bigint[])) id
    where id is not null
  ), raw_candidates as (
    select
      i.expression_id as anchor_expression_id,
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
  ), display_candidates as (
    select source_candidate.*
    from unique_candidates source_candidate
    where source_candidate.group_type <> 'SOURCE_MEMO'
       or not exists (
         select 1
         from unique_candidates preferred_candidate
         where preferred_candidate.anchor_expression_id = source_candidate.anchor_expression_id
           and preferred_candidate.group_type in ('SEMANTIC', 'CATEGORY')
           and (
             preferred_candidate.target_expression_id = source_candidate.target_expression_id
             or preferred_candidate.target_display_key = source_candidate.target_display_key
           )
       )
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
  from ranked r
  where r.result_order <= least(greatest(coalesce(p_limit_per_group, 24), 1), 50)
  order by
    r.anchor_expression_id,
    case r.group_type when 'SEMANTIC' then 1 when 'CATEGORY' then 2 else 3 end,
    r.anchor_level,
    r.group_display_order,
    r.group_member_count,
    r.group_label,
    r.result_order;
$$;

revoke all on function public.get_learning_associations(bigint[], integer)
  from public;
grant execute on function public.get_learning_associations(bigint[], integer)
  to anon, authenticated;
