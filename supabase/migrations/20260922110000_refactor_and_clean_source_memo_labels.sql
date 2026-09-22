-- Normalize label-only punctuation and centralize deterministic source-memo
-- label refreshes so later classification stages do not duplicate the update.

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
      trim(regexp_replace(
        trim(coalesce(p_display_pronunciation, '')),
        '[[:space:].,;:]+$',
        '',
        'g'
      )) as pronunciation,
      trim(regexp_replace(
        split_part(
          split_part(
            split_part(
              split_part(coalesce(p_meaning_text, ''), '/', 1),
              '(', 1
            ),
            '.', 1
          ),
          ';', 1
        ),
        '^[→*~[:space:]]+|[[:space:].,;:]+$',
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

create or replace function public.refresh_source_memo_association_labels()
returns bigint
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_updated bigint;
begin
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
  ), member_texts as (
    select
      g.id as group_id,
      string_agg(
        coalesce(e.display_pronunciation, '') || ' ' || coalesce(em.meaning_text, ''),
        ' '
      ) as member_text
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
    group by g.id
  ), proposed as (
    select
      g.id as group_id,
      public.source_memo_association_label(
        fm.display_pronunciation,
        fm.meaning_text
      ) as first_member_label,
      public.source_memo_explicit_heading_label(
        sm.original_text,
        mt.member_text
      ) as explicit_heading_label
    from public.learning_association_group g
    join first_members fm on fm.group_id = g.id
    join member_texts mt on mt.group_id = g.id
    join public.source_memo sm
      on sm.id = substring(g.group_key from 'MEMO:([0-9]+)')::bigint
    where g.status = 'ACTIVE'
      and g.group_type = 'SOURCE_MEMO'
  )
  update public.learning_association_group g
  set label = case
        when p.first_member_label <> '연관' then p.first_member_label
        else coalesce(p.explicit_heading_label, '연관')
      end,
      updated_at = now()
  from proposed p
  where g.id = p.group_id
    and g.label is distinct from case
      when p.first_member_label <> '연관' then p.first_member_label
      else coalesce(p.explicit_heading_label, '연관')
    end;

  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

revoke all on function public.refresh_source_memo_association_labels()
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

  perform public.refresh_source_memo_association_labels();

  return query
  select v_group_count, v_member_count;
end;
$$;

revoke all on function public.refresh_learning_association_groups()
  from public, anon, authenticated;

select public.refresh_source_memo_association_labels();
