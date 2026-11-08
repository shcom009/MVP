-- Let the existing trigram indexes narrow dynamic association candidates
-- before calculating the stricter normalized-string similarity.

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
with curated as materialized (
  select * from public.get_learning_associations_curated(p_expression_ids,p_limit_per_group)
), input_ids as (
  select distinct x expression_id
  from unnest(coalesce(p_expression_ids,array[]::bigint[])) x
  where x is not null
), anchors as (
  select e.id,em.meaning_text,em.meaning_norm,e.display_pronunciation,
         regexp_replace(lower(e.display_pronunciation),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g') pron_norm
  from input_ids i
  join public.expression e on e.id=i.expression_id and e.status='ACTIVE'
  join public.expression_meaning em on em.expression_id=e.id and em.is_primary
), pronunciation_candidates as (
  select a.id anchor_expression_id,e.id target_expression_id,
         em.meaning_text,e.display_pronunciation,2 priority
  from anchors a
  cross join lateral (
    select e2.id,e2.display_pronunciation
    from public.expression e2
    where e2.status='ACTIVE' and e2.id<>a.id and char_length(a.pron_norm)>=2
      and e2.display_pronunciation % a.display_pronunciation
      and similarity(
        regexp_replace(lower(e2.display_pronunciation),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g'),
        a.pron_norm
      )>=0.48
    order by similarity(
      regexp_replace(lower(e2.display_pronunciation),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g'),
      a.pron_norm
    ) desc,char_length(e2.display_pronunciation),e2.id
    limit 10
  ) e
  join public.expression_meaning em on em.expression_id=e.id and em.is_primary
), meaning_candidates as (
  select a.id anchor_expression_id,e.id target_expression_id,
         em.meaning_text,e.display_pronunciation,3 priority
  from anchors a
  cross join lateral (
    select e2.id,e2.display_pronunciation,em2.meaning_text,em2.meaning_norm
    from public.expression e2
    join public.expression_meaning em2 on em2.expression_id=e2.id and em2.is_primary
    where e2.status='ACTIVE' and e2.id<>a.id and char_length(a.meaning_norm)>=2
      and em2.meaning_norm % a.meaning_norm
      and similarity(em2.meaning_norm,a.meaning_norm)>=0.52
    order by similarity(em2.meaning_norm,a.meaning_norm) desc,
             char_length(em2.meaning_text),e2.id
    limit 10
  ) e
  join public.expression_meaning em on em.expression_id=e.id and em.is_primary
), dynamic_raw as (
  select * from pronunciation_candidates
  union all select * from meaning_candidates
), dynamic_unique as (
  select d.*,
         row_number() over(partition by d.anchor_expression_id,d.target_expression_id order by d.priority) target_order
  from dynamic_raw d
  where not exists (
    select 1 from curated c
    where c.anchor_expression_id=d.anchor_expression_id
      and c.target_expression_id=d.target_expression_id
  )
), dynamic_ranked as (
  select d.*,
         count(*) over(partition by d.anchor_expression_id,d.priority) member_count,
         row_number() over(partition by d.anchor_expression_id,d.priority
           order by char_length(d.display_pronunciation),d.target_expression_id) result_order
  from dynamic_unique d
  where d.target_order=1
), dynamic_rows as (
  select d.anchor_expression_id,
         -(d.priority::bigint*1000000000+d.anchor_expression_id) group_id,
         case d.priority when 2 then '비슷한 발음' else '비슷한 뜻' end group_label,
         case d.priority when 2 then 'PRONUNCIATION' else 'SEMANTIC_AUTO' end group_type,
         d.member_count group_member_count,d.target_expression_id,d.meaning_text,d.display_pronunciation,
         'RELATED'::text,3::smallint,d.result_order::integer
  from dynamic_ranked d
  where d.result_order<=least(greatest(coalesce(p_limit_per_group,24),1),10)
)
select u.*
from (
  select * from curated
  union all
  select * from dynamic_rows
) u
order by u.anchor_expression_id,
  case u.group_type when 'SEMANTIC' then 1 when 'PRONUNCIATION' then 2 when 'SEMANTIC_AUTO' then 3 when 'CATEGORY' then 4 else 5 end,
  u.group_id,u.display_order;
$$;

revoke all on function public.get_learning_associations(bigint[], integer) from public;
grant execute on function public.get_learning_associations(bigint[], integer) to anon, authenticated;
