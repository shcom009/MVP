-- Give high-confidence source-memo groups a useful bilingual label, keep
-- ambiguous sentence-led groups generic, and rank compact learning atoms first.

create or replace function public.source_memo_association_label(
  p_display_pronunciation text,
  p_meaning_text text
)
returns text
language sql
immutable
set search_path = public, pg_temp
as $$
  with cleaned as (
    select
      trim(coalesce(p_display_pronunciation, '')) as pronunciation,
      trim(regexp_replace(
        split_part(
          split_part(
            split_part(coalesce(p_meaning_text, ''), '/', 1),
            '(', 1
          ),
          '.', 1
        ),
        '^[→*~[:space:]]+|[[:space:]]+$',
        '',
        'g'
      )) as short_meaning
  )
  select case
    when char_length(pronunciation) between 1 and 9
     and char_length(short_meaning) between 1 and 10
      then pronunciation || '·' || short_meaning
    when char_length(pronunciation) between 1 and 10
      then pronunciation
    else '연관'
  end
  from cleaned;
$$;

revoke all on function public.source_memo_association_label(text, text)
  from public, anon, authenticated;

-- Preserve the original rebuild as an internal base, then decorate its result.
alter function public.refresh_learning_association_groups()
  rename to refresh_learning_association_groups_base;

revoke all on function public.refresh_learning_association_groups_base()
  from public, anon, authenticated;

create or replace function public.refresh_learning_association_groups()
returns table(group_count bigint, member_count bigint)
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_group_count bigint;
  v_member_count bigint;
begin
  select r.group_count, r.member_count
    into v_group_count, v_member_count
  from public.refresh_learning_association_groups_base() r;

  with first_members as (
    select distinct on (g.id)
      g.id as group_id,
      e.display_pronunciation,
      em.meaning_text
    from public.learning_association_group g
    join public.learning_association_member m on m.group_id = g.id
    join public.expression e
      on e.id = m.expression_id
     and e.status = 'ACTIVE'
    left join lateral (
      select meaning_text
      from public.expression_meaning
      where expression_id = e.id
      order by is_primary desc, meaning_order, id
      limit 1
    ) em on true
    where g.status = 'ACTIVE'
      and g.group_type = 'SOURCE_MEMO'
    order by g.id, m.display_order nulls last, m.id
  )
  update public.learning_association_group g
  set label = public.source_memo_association_label(
        fm.display_pronunciation,
        fm.meaning_text
      ),
      updated_at = now()
  from first_members fm
  where g.id = fm.group_id;

  return query
  select v_group_count, v_member_count;
end;
$$;

revoke all on function public.refresh_learning_association_groups()
  from public, anon, authenticated;

-- Deduplicate before applying the per-group limit. For source memos only,
-- compact words and short phrases are displayed before long example sentences.
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
      m_target.expression_id as target_expression_id,
      em.meaning_text,
      e.display_pronunciation,
      m_target.member_role,
      m_target.association_level,
      m_target.display_order,
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
  ), ranked as (
    select
      u.*,
      count(*) over (
        partition by u.anchor_expression_id, u.group_id
      ) as group_member_count,
      row_number() over (
        partition by u.anchor_expression_id, u.group_id
        order by
          u.association_level,
          case when u.group_type = 'SOURCE_MEMO'
            then char_length(regexp_replace(u.display_pronunciation, '[[:space:]]', '', 'g'))
            else 0
          end,
          case when u.group_type = 'SOURCE_MEMO'
            then (u.display_pronunciation ~ '[[:space:]]')::integer
            else 0
          end,
          coalesce(u.display_order, 2147483647),
          u.target_expression_id
      ) as result_order
    from unique_candidates u
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
    r.group_label,
    r.result_order;
$$;

revoke all on function public.get_learning_associations(bigint[], integer)
  from public;
grant execute on function public.get_learning_associations(bigint[], integer)
  to anon, authenticated;

-- Apply labels to the existing groups without rebuilding their curated peers.
with first_members as (
  select distinct on (g.id)
    g.id as group_id,
    e.display_pronunciation,
    em.meaning_text
  from public.learning_association_group g
  join public.learning_association_member m on m.group_id = g.id
  join public.expression e
    on e.id = m.expression_id
   and e.status = 'ACTIVE'
  left join lateral (
    select meaning_text
    from public.expression_meaning
    where expression_id = e.id
    order by is_primary desc, meaning_order, id
    limit 1
  ) em on true
  where g.status = 'ACTIVE'
    and g.group_type = 'SOURCE_MEMO'
  order by g.id, m.display_order nulls last, m.id
)
update public.learning_association_group g
set label = public.source_memo_association_label(
      fm.display_pronunciation,
      fm.meaning_text
    ),
    updated_at = now()
from first_members fm
where g.id = fm.group_id;
