-- Promote a short, unmarked first-line headword only when the exact headword
-- occurs in the group's active pronunciation/meaning text.

create or replace function public.source_memo_unmarked_headword_label(
  p_original_text text,
  p_member_text text
)
returns text
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  v_first_line text;
  v_candidate text;
begin
  select trim(line)
    into v_first_line
  from unnest(regexp_split_to_array(coalesce(p_original_text, ''), E'\r?\n'))
       with ordinality x(line, ord)
  where trim(line) <> ''
  order by ord
  limit 1;

  if v_first_line !~ '^[가-힣ぁ-んァ-ヶ一-龠][가-힣ぁ-んァ-ヶ一-龠0-9~-]{1,9}$' then
    return null;
  end if;

  v_candidate := regexp_replace(v_first_line, '[-~]+$', '', 'g');

  if char_length(v_candidate) not between 2 and 10 then
    return null;
  end if;

  if lower(coalesce(p_member_text, '')) like '%' || lower(v_candidate) || '%' then
    return v_candidate;
  end if;

  return null;
end;
$$;

revoke all on function public.source_memo_unmarked_headword_label(text, text)
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
      ) as explicit_heading_label,
      public.source_memo_unmarked_headword_label(
        sm.original_text,
        mt.member_text
      ) as unmarked_headword_label
    from public.learning_association_group g
    join first_members fm on fm.group_id = g.id
    join member_texts mt on mt.group_id = g.id
    join public.source_memo sm
      on sm.id = substring(g.group_key from 'MEMO:([0-9]+)')::bigint
    where g.status = 'ACTIVE'
      and g.group_type = 'SOURCE_MEMO'
  ), resolved as (
    select
      group_id,
      case
        when first_member_label <> '연관' then first_member_label
        else coalesce(explicit_heading_label, unmarked_headword_label, '연관')
      end as label
    from proposed
  )
  update public.learning_association_group g
  set label = r.label,
      updated_at = now()
  from resolved r
  where g.id = r.group_id
    and g.label is distinct from r.label;

  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

revoke all on function public.refresh_source_memo_association_labels()
  from public, anon, authenticated;

select public.refresh_source_memo_association_labels();
