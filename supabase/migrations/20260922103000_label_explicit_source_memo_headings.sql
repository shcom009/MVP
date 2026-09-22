-- Use author-written memo headings only when the heading is short, specific,
-- and visibly aligned with at least one expression or meaning in the group.

create or replace function public.source_memo_explicit_heading_label(
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
  v_token text;
  v_token_norm text;
begin
  select trim(line)
    into v_first_line
  from unnest(regexp_split_to_array(coalesce(p_original_text, ''), E'\r?\n'))
       with ordinality x(line, ord)
  where trim(line) <> ''
  order by ord
  limit 1;

  if v_first_line ~ '^\(주제[-:：]' then
    v_candidate := regexp_replace(v_first_line, '^\(주제[-:：][[:space:]]*|\)$', '', 'g');
  elsif v_first_line ~ '^\[[^]]+\]$' then
    v_candidate := regexp_replace(v_first_line, '^\[|\]$', '', 'g');
  elsif v_first_line ~ '^[#●○■□◆◇▶▷※]' then
    v_candidate := regexp_replace(v_first_line, '^[#●○■□◆◇▶▷※[:space:]]+', '', 'g');
  else
    return null;
  end if;

  v_candidate := trim(regexp_replace(
    v_candidate,
    '[[:space:]]*[,.、]+[[:space:]]*',
    '·',
    'g'
  ));
  v_candidate := regexp_replace(v_candidate, '[·[:space:];,.-]+$', '', 'g');

  if char_length(v_candidate) not between 1 and 20
     or v_candidate ~ '[!?？。]'
     or v_candidate in (
       '신조어', '예문', '사용 예시', '발음', '뜻', '의미', '분석', '조사', '종조사'
     ) then
    return null;
  end if;

  for v_token in
    select token
    from unnest(regexp_split_to_array(lower(v_candidate), '[·/[:space:]~]+')) token
  loop
    v_token_norm := regexp_replace(
      v_token,
      '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]',
      '',
      'g'
    );
    if char_length(v_token_norm) >= 2
       and lower(coalesce(p_member_text, '')) like '%' || left(v_token_norm, 2) || '%' then
      return v_candidate;
    end if;
  end loop;

  return null;
end;
$$;

revoke all on function public.source_memo_explicit_heading_label(text, text)
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
  where g.id = p.group_id;

  return query
  select v_group_count, v_member_count;
end;
$$;

revoke all on function public.refresh_learning_association_groups()
  from public, anon, authenticated;

-- Apply the same deterministic rule to the current active groups.
with first_members as (
  select distinct on (g.id)
    g.id as group_id,
    e.display_pronunciation,
    em.meaning_text
  from public.learning_association_group g
  join public.learning_association_member m on m.group_id = g.id
  join public.expression e on e.id = m.expression_id and e.status = 'ACTIVE'
  left join lateral (
    select meaning_text
    from public.expression_meaning
    where expression_id = e.id
    order by is_primary desc, meaning_order, id
    limit 1
  ) em on true
  where g.status = 'ACTIVE' and g.group_type = 'SOURCE_MEMO'
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
  join public.expression e on e.id = m.expression_id and e.status = 'ACTIVE'
  left join lateral (
    select meaning_text
    from public.expression_meaning
    where expression_id = e.id
    order by is_primary desc, meaning_order, id
    limit 1
  ) em on true
  where g.status = 'ACTIVE' and g.group_type = 'SOURCE_MEMO'
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
  where g.status = 'ACTIVE' and g.group_type = 'SOURCE_MEMO'
)
update public.learning_association_group g
set label = case
      when p.first_member_label <> '연관' then p.first_member_label
      else coalesce(p.explicit_heading_label, '연관')
    end,
    updated_at = now()
from proposed p
where g.id = p.group_id;
