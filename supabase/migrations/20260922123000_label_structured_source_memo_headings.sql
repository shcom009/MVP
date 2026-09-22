-- Promote structured first-line headings when their pronunciation or complete
-- meaning is visibly present in the group's active member text.

create or replace function public.source_memo_structured_heading_label(
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
  v_anchor text;
  v_left text;
  v_right text;
begin
  select trim(line)
    into v_first_line
  from unnest(regexp_split_to_array(coalesce(p_original_text, ''), E'\r?\n'))
       with ordinality x(line, ord)
  where trim(line) <> ''
  order by ord
  limit 1;

  -- A complete Korean topic enclosed in parentheses.
  if v_first_line ~ '^\([^()]{2,20}\)$' then
    v_candidate := substring(v_first_line from '^\(([^()]*)\)$');
    if lower(coalesce(p_member_text, '')) like '%' || lower(v_candidate) || '%' then
      return v_candidate;
    end if;
    return null;
  end if;

  -- Japanese script followed by the Korean pronunciation.
  if v_first_line ~ '^[ぁ-んァ-ヶ一-龠]+[[:space:]]*\([가-힣]{2,10}\)$' then
    v_candidate := substring(v_first_line from '\(([가-힣]{2,10})\)$');
    if lower(coalesce(p_member_text, '')) like '%' || lower(v_candidate) || '%' then
      return v_candidate;
    end if;
    return null;
  end if;

  -- A Korean pronunciation followed by a short optional variant.
  if v_first_line ~ '^[가-힣]{2,10}\([가-힣 ]{1,10}\)$' then
    v_anchor := split_part(v_first_line, '(', 1);
    v_candidate := regexp_replace(
      v_first_line,
      '^([가-힣]{2,10})\(([가-힣 ]{1,10})\)$',
      '\1·\2'
    );
    if char_length(v_candidate) <= 20
       and lower(coalesce(p_member_text, '')) like '%' || lower(v_anchor) || '%' then
      return v_candidate;
    end if;
    return null;
  end if;

  -- Japanese script + Korean pronunciation + arrow meaning.
  if v_first_line ~ '[→⇒]'
     and v_first_line ~ '\([가-힣]{2,10}\)' then
    v_anchor := substring(v_first_line from '\(([가-힣]{2,10})\)');
    v_right := trim(split_part(split_part(v_first_line, '→', 2), ',', 1));
    v_candidate := v_anchor || '·' || v_right;
    if char_length(v_candidate) <= 20
       and lower(coalesce(p_member_text, '')) like '%' || lower(v_anchor) || '%' then
      return v_candidate;
    end if;
    return null;
  end if;

  -- A short pronunciation/meaning pair separated by a comma.
  if v_first_line ~ '^\*?[가-힣][가-힣0-9~-]{1,11}[,，][[:space:]]*[가-힣][가-힣 ]{0,11}[.]?$' then
    v_left := regexp_replace(
      trim(split_part(regexp_replace(v_first_line, '，', ',', 'g'), ',', 1)),
      '^\*',
      ''
    );
    v_right := regexp_replace(
      trim(split_part(regexp_replace(v_first_line, '，', ',', 'g'), ',', 2)),
      '[.]$',
      ''
    );
    v_candidate := v_left || '·' || v_right;
    if char_length(v_candidate) <= 20
       and lower(coalesce(p_member_text, '')) like '%' || lower(v_left) || '%' then
      return v_candidate;
    end if;
  end if;

  return null;
end;
$$;

revoke all on function public.source_memo_structured_heading_label(text, text)
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
      ) as unmarked_headword_label,
      public.source_memo_structured_heading_label(
        sm.original_text,
        mt.member_text
      ) as structured_heading_label
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
        else coalesce(
          explicit_heading_label,
          unmarked_headword_label,
          structured_heading_label,
          '연관'
        )
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
