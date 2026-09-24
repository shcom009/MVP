-- Public, read-only projection used by nihongo-hub.html.
-- It deliberately exposes only ACTIVE, non-edge learning data and avoids
-- granting anon direct SELECT privileges on the underlying tables.
create or replace function public.get_expression_hub(
  p_expression_id bigint,
  p_limit_per_group integer default 32
)
returns table(
  item_kind text,
  group_id bigint,
  group_label text,
  group_type text,
  target_expression_id bigint,
  meaning_text text,
  display_pronunciation text,
  japanese_original text,
  content_text text,
  item_label text,
  association_level smallint,
  display_order integer
)
language sql
stable
security definer
set search_path = ''
as $function$
with anchor as materialized (
  select e.id, e.display_pronunciation, e.japanese_original, em.meaning_text
  from public.expression e
  join public.expression_meaning em
    on em.expression_id = e.id and em.is_primary
  where e.id = p_expression_id
    and e.status = 'ACTIVE'
    and not coalesce(e.edge_flag, false)
),
limits as (
  select least(greatest(coalesce(p_limit_per_group, 32), 1), 64) n
),
self_row as (
  select 'SELF'::text item_kind, 0::bigint group_id,
    '현재 표현'::text group_label, 'SELF'::text group_type,
    a.id target_expression_id, a.meaning_text,
    a.display_pronunciation, a.japanese_original,
    null::text content_text, null::text item_label,
    0::smallint association_level, 0::integer display_order
  from anchor a
),
note_rows as (
  select 'NOTE'::text, 0::bigint, '예문·메모'::text, n.note_type,
    a.id, a.meaning_text, a.display_pronunciation, a.japanese_original,
    n.note_text, n.note_type, 0::smallint, coalesce(n.display_order, n.id::integer)
  from anchor a
  join public.note n on n.expression_id = a.id
  where n.note_type in ('EXAMPLE', 'HINT', 'REFERENCE')
  order by coalesce(n.display_order, n.id::integer)
  limit (select n from limits)
),
relation_base as (
  select r.id relation_id, r.relation_type, r.relation_subtype,
    coalesce(r.display_order, r.id::integer) relation_order,
    case when r.from_expression_id = a.id then r.to_expression_id else r.from_expression_id end target_id
  from anchor a
  join public.expression_relation r
    on r.from_expression_id = a.id or r.to_expression_id = a.id
),
relation_rows as (
  select 'RELATION'::text, 0::bigint,
    case rb.relation_type
      when 'FORM' then '기본형·활용'
      when 'SIMILAR' then '비슷한 뜻'
      when 'OPPOSITE' then '반대 표현'
      when 'PRONUNCIATION_SIMILAR' then '비슷한 발음'
      when 'SAME_SITUATION' then '같은 상황'
      when 'SAME_GROUP' then '같은 그룹'
      else '관련 표현'
    end::text,
    rb.relation_type, e.id, em.meaning_text, e.display_pronunciation,
    e.japanese_original, rb.relation_subtype, rb.relation_subtype,
    1::smallint, rb.relation_order
  from relation_base rb
  join public.expression e
    on e.id = rb.target_id
   and e.status = 'ACTIVE'
   and not coalesce(e.edge_flag, false)
  join public.expression_meaning em
    on em.expression_id = e.id and em.is_primary
  order by rb.relation_order
  limit (select n * 8 from limits)
),
association_rows as (
  select 'ASSOCIATION'::text, ga.group_id, ga.group_label, ga.group_type,
    e.id, em.meaning_text, e.display_pronunciation, e.japanese_original,
    ga.member_role, ga.member_role, ga.association_level, ga.display_order
  from anchor a
  cross join limits l
  cross join lateral public.get_learning_associations(array[a.id], l.n) ga
  join public.expression e
    on e.id = ga.target_expression_id
   and e.status = 'ACTIVE'
   and not coalesce(e.edge_flag, false)
  join public.expression_meaning em
    on em.expression_id = e.id and em.is_primary
  where ga.target_expression_id <> a.id
),
category_rows as (
  select 'CATEGORY'::text, c.id, c.name, c.category_type,
    member.id, mem.meaning_text, member.display_pronunciation,
    member.japanese_original, null::text, c.category_type,
    2::smallint, ranked.member_order::integer
  from anchor a
  join public.expression_category own on own.expression_id = a.id
  join public.category c on c.id = own.category_id and c.status = 'ACTIVE'
  cross join limits l
  cross join lateral (
    select ec.expression_id,
      row_number() over (order by ec.id) member_order
    from public.expression_category ec
    where ec.category_id = c.id and ec.expression_id <> a.id
    limit l.n
  ) ranked
  join public.expression member
    on member.id = ranked.expression_id
   and member.status = 'ACTIVE'
   and not coalesce(member.edge_flag, false)
  join public.expression_meaning mem
    on mem.expression_id = member.id and mem.is_primary
),
dialogue_rows as (
  select 'DIALOGUE'::text, d.id, coalesce(d.title, d.situation, '대화'),
    'DIALOGUE'::text, null::bigint, dl.korean_text,
    dl.display_pronunciation, dl.japanese_original,
    dl.korean_text, coalesce(dl.speaker, '대화'), 2::smallint, dl.line_order
  from anchor a
  join public.dialogue_expression de on de.expression_id = a.id
  join public.dialogue_line linked on linked.id = de.dialogue_line_id
  join public.dialogue d
    on d.id = linked.dialogue_id
   and d.status = 'ACTIVE'
   and not coalesce(d.story_only, false)
  join public.dialogue_line dl
    on dl.dialogue_id = d.id
   and dl.line_order between greatest(linked.line_order - 2, 0) and linked.line_order + 2
  order by d.id, dl.line_order
  limit (select n * 4 from limits)
)
select * from self_row
union all select * from note_rows
union all select * from relation_rows
union all select * from association_rows
union all select * from category_rows
union all select * from dialogue_rows
order by item_kind, group_id, display_order, target_expression_id;
$function$;

revoke all on function public.get_expression_hub(bigint, integer) from public;
grant execute on function public.get_expression_hub(bigint, integer) to anon, authenticated;

comment on function public.get_expression_hub(bigint, integer) is
  'Restricted ACTIVE/non-edge projection for the public expression exploration hub.';
