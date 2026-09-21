-- Broad learning associations for compact, cyclic exploration from search results.
-- Strict SIMILAR / OPPOSITE / FORM relations remain in expression_relation.

create table if not exists public.learning_association_group (
  id bigint generated always as identity primary key,
  group_key text not null unique,
  label text not null,
  group_type text not null check (group_type in ('CATEGORY', 'SOURCE_MEMO', 'SEMANTIC')),
  status text not null default 'ACTIVE' check (status in ('ACTIVE', 'INACTIVE')),
  display_order integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.learning_association_member (
  id bigint generated always as identity primary key,
  group_id bigint not null references public.learning_association_group(id) on delete cascade,
  expression_id bigint not null references public.expression(id) on delete cascade,
  member_role text not null default 'CONTEXT' check (member_role in ('CORE', 'RELATED', 'CATEGORY', 'CONTEXT')),
  association_level smallint not null default 3 check (association_level between 1 and 3),
  display_order integer,
  created_at timestamptz not null default now(),
  unique (group_id, expression_id)
);

create index if not exists ix_learning_association_member_expression
  on public.learning_association_member(expression_id, group_id);

create index if not exists ix_learning_association_member_group_order
  on public.learning_association_member(group_id, display_order, expression_id);

alter table public.learning_association_group enable row level security;
alter table public.learning_association_member enable row level security;

drop policy if exists learning_association_group_read_active on public.learning_association_group;
create policy learning_association_group_read_active
  on public.learning_association_group
  for select
  to anon, authenticated
  using (status = 'ACTIVE');

drop policy if exists learning_association_member_read_active on public.learning_association_member;
create policy learning_association_member_read_active
  on public.learning_association_member
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.learning_association_group g
      where g.id = group_id
        and g.status = 'ACTIVE'
    )
    and exists (
      select 1
      from public.expression e
      where e.id = expression_id
        and e.status = 'ACTIVE'
    )
  );

grant select on public.learning_association_group to anon, authenticated;
grant select on public.learning_association_member to anon, authenticated;

create or replace function public.refresh_learning_association_groups()
returns table(group_count bigint, member_count bigint)
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- Rebuild only groups derived from existing category and memo links.
  delete from public.learning_association_group
  where group_type in ('CATEGORY', 'SOURCE_MEMO');

  insert into public.learning_association_group
    (group_key, label, group_type, status, display_order)
  select
    'CATEGORY:' || c.id,
    c.name,
    'CATEGORY',
    'ACTIVE',
    coalesce(c.display_order, 100)
  from public.category c
  where c.status = 'ACTIVE'
    and exists (
      select 1
      from public.expression_category ec
      join public.expression e on e.id = ec.expression_id and e.status = 'ACTIVE'
      where ec.category_id = c.id
    )
  on conflict (group_key) do update
    set label = excluded.label,
        status = excluded.status,
        display_order = excluded.display_order,
        updated_at = now();

  insert into public.learning_association_member
    (group_id, expression_id, member_role, association_level, display_order)
  select
    g.id,
    ec.expression_id,
    'CATEGORY',
    2,
    row_number() over (partition by ec.category_id order by ec.id, ec.expression_id)::integer
  from public.expression_category ec
  join public.category c on c.id = ec.category_id and c.status = 'ACTIVE'
  join public.expression e on e.id = ec.expression_id and e.status = 'ACTIVE'
  join public.learning_association_group g on g.group_key = 'CATEGORY:' || ec.category_id
  on conflict (group_id, expression_id) do update
    set member_role = excluded.member_role,
        association_level = excluded.association_level,
        display_order = excluded.display_order;

  with eligible_memos as (
    select cu.source_memo_id
    from public.candidate_unit cu
    join public.expression_source es on es.candidate_unit_id = cu.id
    join public.expression e on e.id = es.expression_id and e.status = 'ACTIVE'
    group by cu.source_memo_id
    having count(distinct es.expression_id) >= 2
  )
  insert into public.learning_association_group
    (group_key, label, group_type, status, display_order)
  select
    'MEMO:' || em.source_memo_id,
    '연관',
    'SOURCE_MEMO',
    'ACTIVE',
    200
  from eligible_memos em
  on conflict (group_key) do update
    set status = excluded.status,
        updated_at = now();

  with source_members as (
    select
      cu.source_memo_id,
      es.expression_id,
      min(cu.id) as first_candidate_id
    from public.candidate_unit cu
    join public.expression_source es on es.candidate_unit_id = cu.id
    join public.expression e on e.id = es.expression_id and e.status = 'ACTIVE'
    group by cu.source_memo_id, es.expression_id
  )
  insert into public.learning_association_member
    (group_id, expression_id, member_role, association_level, display_order)
  select
    g.id,
    sm.expression_id,
    'CONTEXT',
    3,
    row_number() over (partition by sm.source_memo_id order by sm.first_candidate_id, sm.expression_id)::integer
  from source_members sm
  join public.learning_association_group g on g.group_key = 'MEMO:' || sm.source_memo_id
  on conflict (group_id, expression_id) do update
    set member_role = excluded.member_role,
        association_level = excluded.association_level,
        display_order = excluded.display_order;

  return query
  select
    (select count(*) from public.learning_association_group where status = 'ACTIVE'),
    (select count(*) from public.learning_association_member);
end;
$$;

revoke all on function public.refresh_learning_association_groups() from public, anon, authenticated;

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
  ), candidates as (
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
      count(*) over (partition by i.expression_id, g.id) as group_member_count,
      row_number() over (
        partition by i.expression_id, g.id
        order by
          m_target.association_level,
          coalesce(m_target.display_order, 2147483647),
          m_target.expression_id
      ) as result_order
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
  )
  select
    c.anchor_expression_id,
    c.group_id,
    c.group_label,
    c.group_type,
    c.group_member_count,
    c.target_expression_id,
    c.meaning_text,
    c.display_pronunciation,
    c.member_role,
    c.association_level,
    c.display_order
  from candidates c
  where c.result_order <= least(greatest(coalesce(p_limit_per_group, 24), 1), 50)
  order by
    c.anchor_expression_id,
    case c.group_type when 'SEMANTIC' then 1 when 'CATEGORY' then 2 else 3 end,
    c.group_label,
    c.result_order;
$$;

revoke all on function public.get_learning_associations(bigint[], integer) from public;
grant execute on function public.get_learning_associations(bigint[], integer) to anon, authenticated;

select * from public.refresh_learning_association_groups();

-- Curated semantic anchors supplement broad category and same-memo groups.
insert into public.learning_association_group
  (group_key, label, group_type, status, display_order)
values
  ('SEMANTIC:TIME', '시간', 'SEMANTIC', 'ACTIVE', 10),
  ('SEMANTIC:MONSTER_YOKAI', '괴물·요괴', 'SEMANTIC', 'ACTIVE', 20)
on conflict (group_key) do update
  set label = excluded.label,
      status = excluded.status,
      display_order = excluded.display_order,
      updated_at = now();

insert into public.learning_association_member
  (group_id, expression_id, member_role, association_level, display_order)
select
  g.id,
  e.id,
  case when e.id = 9312 then 'CORE' else 'RELATED' end,
  case when e.id = 9312 then 1 else 2 end,
  row_number() over (
    order by
      case when e.id = 9312 then 0 when e.id between 5385 and 5389 then 1 else 2 end,
      e.id
  )::integer
from public.learning_association_group g
join public.expression e on e.status = 'ACTIVE'
left join public.expression_category ec on ec.expression_id = e.id and ec.category_id = 8
where g.group_key = 'SEMANTIC:TIME'
  and (
    e.id = 9312
    or e.id between 5385 and 5389
    or ec.expression_id is not null
    or (' ' || regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', ' ', 'g') || ' ') like '% 지칸 %'
  )
on conflict (group_id, expression_id) do update
  set member_role = excluded.member_role,
      association_level = excluded.association_level,
      display_order = excluded.display_order;

insert into public.learning_association_member
  (group_id, expression_id, member_role, association_level, display_order)
select
  g.id,
  e.id,
  case when e.id in (1221, 7162, 8194) then 'CORE' else 'RELATED' end,
  case when e.id in (1221, 7162, 8194) then 1 else 2 end,
  row_number() over (order by array_position(array[1221, 7162, 8194]::bigint[], e.id), e.id)::integer
from public.learning_association_group g
join public.expression e on e.id in (1221, 7162, 8194) and e.status = 'ACTIVE'
where g.group_key = 'SEMANTIC:MONSTER_YOKAI'
on conflict (group_id, expression_id) do update
  set member_role = excluded.member_role,
      association_level = excluded.association_level,
      display_order = excluded.display_order;
