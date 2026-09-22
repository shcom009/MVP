-- Read-only audit of expressions assigned to more than one active category.
-- An overlap is accepted only when the category pair and the complete shared
-- pronunciation signature match the reviewed snapshot. Any new or changed
-- overlap is returned as REVIEW without modifying source data.

with reviewed_pair(group_a_key, group_b_key, shared_pronunciations) as (
  values
    ('CATEGORY:1',  'CATEGORY:17', array['아스']::text[]),
    ('CATEGORY:5',  'CATEGORY:10', array['오또또']::text[]),
    ('CATEGORY:17', 'CATEGORY:18', array['쇼쿠도오']::text[]),
    ('CATEGORY:18', 'CATEGORY:33', array['쇼쿠타쿠', '이마']::text[]),
    ('CATEGORY:21', 'CATEGORY:31', array['미카츠키', '호시']::text[]),
    ('CATEGORY:25', 'CATEGORY:27', array['나츠노하나가 사이타네']::text[]),
    ('CATEGORY:30', 'CATEGORY:33', array['고미']::text[])
), category_member as (
  select
    g.id as group_id,
    g.group_key,
    g.label,
    m.expression_id,
    e.display_pronunciation
  from public.learning_association_group g
  join public.learning_association_member m on m.group_id = g.id
  join public.expression e on e.id = m.expression_id
  where g.status = 'ACTIVE'
    and g.group_type = 'CATEGORY'
    and e.status = 'ACTIVE'
), category_count as (
  select group_id, count(*)::integer as member_count
  from category_member
  group by group_id
), pair_overlap as (
  select
    a.group_key as group_a_key,
    a.label as group_a_label,
    ac.member_count as group_a_count,
    b.group_key as group_b_key,
    b.label as group_b_label,
    bc.member_count as group_b_count,
    count(*)::integer as shared_count,
    array_agg(a.display_pronunciation order by a.display_pronunciation) as shared_pronunciations
  from category_member a
  join category_member b
    on b.expression_id = a.expression_id
   and a.group_id < b.group_id
  join category_count ac on ac.group_id = a.group_id
  join category_count bc on bc.group_id = b.group_id
  group by
    a.group_key, a.label, ac.member_count,
    b.group_key, b.label, bc.member_count
)
select
  p.*,
  p.shared_count * (p.shared_count - 1) as potential_duplicate_directed_rows,
  case
    when r.group_a_key is not null then 'INTENTIONAL_MULTI_CATEGORY'
    else 'REVIEW'
  end as audit_status
from pair_overlap p
left join reviewed_pair r
  on r.group_a_key = p.group_a_key
 and r.group_b_key = p.group_b_key
 and r.shared_pronunciations @> p.shared_pronunciations
 and p.shared_pronunciations @> r.shared_pronunciations
order by
  (r.group_a_key is null) desc,
  potential_duplicate_directed_rows desc,
  p.group_a_key,
  p.group_b_key;
