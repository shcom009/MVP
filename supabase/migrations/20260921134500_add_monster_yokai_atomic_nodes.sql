-- Promote five source-explicit headwords from source_memo.id = 100.
-- IDs in the imported legacy schema have no defaults, so allocation is serialized.

select pg_advisory_xact_lock(hashtext('kimtokki_atomic_expression_seed'));

create temporary table _kimtokki_monster_seed (
  seed_order integer primary key,
  seed_key text not null unique,
  display_pronunciation text not null,
  meaning_text text not null,
  source_excerpt text not null
) on commit drop;

insert into _kimtokki_monster_seed
  (seed_order, seed_key, display_pronunciation, meaning_text, source_excerpt)
values
  (1, 'KAIBUTSU', '카이부츠', '괴물', '카이부츠, 괴물 정체 불명의 생물'),
  (2, 'MONONOKE', '모노노케', '귀신·원령', '모노노케, 귀신 원령'),
  (3, 'ONI', '오니', '귀신', '오니, 귀신'),
  (4, 'BAKEMONO', '바케모노', '도깨비·괴이한 힘을 지닌 존재', '바케모노, 도깨비, 괴이한 힘을 지닌 존재'),
  (5, 'KEMONO', '케모노', '짐승', '케모노, 짐승');

with missing as (
  select s.*
  from _kimtokki_monster_seed s
  where not exists (
    select 1
    from public.candidate_unit cu
    where cu.legacy_candidate_key = 'ASSOC_ATOMIC:100:' || s.seed_key
  )
)
insert into public.candidate_unit (
  source_memo_id,
  legacy_candidate_key,
  korean_meaning,
  display_pronunciation,
  japanese_original,
  personal_note,
  literal_translation,
  recovery_method,
  verification_status,
  source_record_ref,
  source_excerpt,
  source_folder_snapshot,
  source_file_snapshot
)
select
  100,
  'ASSOC_ATOMIC:100:' || m.seed_key,
  m.meaning_text,
  m.display_pronunciation,
  null,
  null,
  null,
  'SOURCE_ATOMIC_SPLIT',
  'VERIFIED',
  'memoSeq:1358794',
  m.source_excerpt,
  '일어-외워',
  'source_memo:100'
from missing m;

with missing as (
  select s.*
  from _kimtokki_monster_seed s
  where not exists (
    select 1
    from public.expression e
    where regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
          regexp_replace(lower(s.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g')
      and e.status <> 'EXCLUDED'
  )
)
insert into public.expression (
  display_pronunciation,
  japanese_original,
  status,
  verification_status,
  speaking_enabled,
  listening_enabled,
  edge_flag,
  created_at,
  updated_at
)
select
  m.display_pronunciation,
  null,
  'ACTIVE',
  'VERIFIED',
  true,
  true,
  false,
  now(),
  now()
from missing m;

with resolved as (
  select distinct on (s.seed_key)
    s.*,
    e.id as expression_id
  from _kimtokki_monster_seed s
  join public.expression e
    on regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
       regexp_replace(lower(s.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g')
   and e.status <> 'EXCLUDED'
  order by s.seed_key, case e.status when 'ACTIVE' then 0 else 1 end, e.id
), missing as (
  select r.*
  from resolved r
  where not exists (
    select 1
    from public.expression_meaning em
    where em.expression_id = r.expression_id
      and em.is_primary = true
  )
)
insert into public.expression_meaning (
  expression_id,
  meaning_text,
  meaning_norm,
  meaning_order,
  is_primary,
  usage_note,
  created_at
)
select
  m.expression_id,
  m.meaning_text,
  lower(btrim(m.meaning_text)),
  1,
  true,
  null,
  now()
from missing m;

with resolved as (
  select distinct on (s.seed_key)
    s.*,
    e.id as expression_id
  from _kimtokki_monster_seed s
  join public.expression e
    on regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
       regexp_replace(lower(s.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g')
   and e.status = 'ACTIVE'
  order by s.seed_key, e.id
), missing as (
  select r.*
  from resolved r
  where not exists (
    select 1
    from public.search_alias sa
    where sa.expression_id = r.expression_id
      and sa.alias_type = 'NORMALIZED'
      and sa.alias_norm = lower(btrim(r.display_pronunciation))
  )
)
insert into public.search_alias (
  expression_id,
  alias_text,
  alias_norm,
  alias_type,
  origin,
  created_at
)
select
  m.expression_id,
  m.display_pronunciation,
  lower(btrim(m.display_pronunciation)),
  'NORMALIZED',
  'SOURCE',
  now()
from missing m;

with resolved as (
  select distinct on (s.seed_key)
    s.*,
    e.id as expression_id,
    cu.id as candidate_unit_id
  from _kimtokki_monster_seed s
  join public.expression e
    on regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
       regexp_replace(lower(s.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g')
   and e.status = 'ACTIVE'
  join public.candidate_unit cu
    on cu.legacy_candidate_key = 'ASSOC_ATOMIC:100:' || s.seed_key
  order by s.seed_key, e.id
), missing as (
  select r.*
  from resolved r
  where not exists (
    select 1
    from public.expression_source es
    where es.candidate_unit_id = r.candidate_unit_id
  )
)
insert into public.expression_source (expression_id, candidate_unit_id, created_at)
select
  m.expression_id,
  m.candidate_unit_id,
  now()
from missing m;

-- Rebuild source-memo groups so the five new cards also inherit memo context.
select * from public.refresh_learning_association_groups();

insert into public.learning_association_member
  (group_id, expression_id, member_role, association_level, display_order)
select
  g.id,
  e.id,
  'CORE',
  1,
  s.seed_order
from _kimtokki_monster_seed s
join public.expression e
  on regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
     regexp_replace(lower(s.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g')
 and e.status = 'ACTIVE'
join public.learning_association_group g
  on g.group_key = 'SEMANTIC:MONSTER_YOKAI'
on conflict (group_id, expression_id) do update
  set member_role = excluded.member_role,
      association_level = excluded.association_level,
      display_order = excluded.display_order;

-- Keep the previously linked sentence and beast expressions as broader related items.
insert into public.learning_association_member
  (group_id, expression_id, member_role, association_level, display_order)
select
  g.id,
  e.id,
  'RELATED',
  2,
  case e.id when 1221 then 10 when 7162 then 20 when 8194 then 21 end
from public.learning_association_group g
join public.expression e on e.id in (1221, 7162, 8194) and e.status = 'ACTIVE'
where g.group_key = 'SEMANTIC:MONSTER_YOKAI'
on conflict (group_id, expression_id) do update
  set member_role = excluded.member_role,
      association_level = excluded.association_level,
      display_order = excluded.display_order;
