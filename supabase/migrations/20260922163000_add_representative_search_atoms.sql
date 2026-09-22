-- Promote source-explicit headwords needed by the representative searches.
-- Each atom keeps a link to its original Naver memo; no inferred bulk data is
-- created.

select pg_advisory_xact_lock(hashtext('kimtokki_atomic_expression_seed'));

create temporary table _kimtokki_representative_seed (
  seed_order integer primary key,
  seed_key text not null unique,
  source_memo_id bigint not null,
  display_pronunciation text not null,
  japanese_original text,
  meaning_text text not null
) on commit drop;

insert into _kimtokki_representative_seed
  (seed_order, seed_key, source_memo_id, display_pronunciation, japanese_original, meaning_text)
values
  (1, 'HIROU',      1120, '히로우',   '拾う', '줍다'),
  (2, 'AISHOU',      966, '아이쇼오', '相性', '궁합·상성'),
  (3, 'TOMODACHI',  3807, '토모다치', '友達', '친구'),
  (4, 'YUUJIN',     3807, '유우진',   '友人', '친구(격식)'),
  (5, 'NAKAMA',     3807, '나카마',   '仲間', '동료·같은 편'),
  (6, 'SHINYUU',    3807, '신유우',   '親友', '절친·가장 친한 친구'),
  (7, 'DACHI',      3807, '다치',     'ダチ', '친구(속어)'),
  (8, 'AIBOU',      3807, '아이보오', '相棒', '파트너·둘도 없는 친구');

with missing as (
  select s.*
  from _kimtokki_representative_seed s
  where not exists (
    select 1
    from public.candidate_unit cu
    where cu.legacy_candidate_key =
      'ASSOC_ATOMIC:' || s.source_memo_id || ':' || s.seed_key
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
  m.source_memo_id,
  'ASSOC_ATOMIC:' || m.source_memo_id || ':' || m.seed_key,
  m.meaning_text,
  m.display_pronunciation,
  m.japanese_original,
  null,
  null,
  'SOURCE_ATOMIC_SPLIT',
  'VERIFIED',
  'memoSeq:' || sm.memo_seq,
  m.display_pronunciation || ', ' || m.meaning_text,
  sm.legacy_folder_id,
  'source_memo:' || sm.id
from missing m
join public.source_memo sm on sm.id = m.source_memo_id;

with missing as (
  select s.*
  from _kimtokki_representative_seed s
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
  m.japanese_original,
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
  from _kimtokki_representative_seed s
  join public.expression e
    on regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
       regexp_replace(lower(s.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g')
   and e.status <> 'EXCLUDED'
  order by s.seed_key, case e.status when 'ACTIVE' then 0 else 1 end, e.id
), missing as (
  select r.*
  from resolved r
  where not exists (
    select 1 from public.expression_meaning em
    where em.expression_id = r.expression_id and em.is_primary = true
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
  from _kimtokki_representative_seed s
  join public.expression e
    on regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
       regexp_replace(lower(s.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g')
   and e.status = 'ACTIVE'
  order by s.seed_key, e.id
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
  r.expression_id,
  r.display_pronunciation,
  lower(btrim(r.display_pronunciation)),
  'NORMALIZED',
  'SOURCE',
  now()
from resolved r
on conflict (expression_id, alias_type, alias_norm) do nothing;

-- Common Korean input omits the long vowel in 아이쇼오.
insert into public.search_alias (
  expression_id, alias_text, alias_norm, alias_type, origin, created_at
)
select e.id, '아이쇼', '아이쇼', 'NORMALIZED', 'SOURCE', now()
from public.expression e
where e.status = 'ACTIVE'
  and regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '아이쇼오'
on conflict (expression_id, alias_type, alias_norm) do nothing;

with resolved as (
  select distinct on (s.seed_key)
    s.*,
    e.id as expression_id,
    cu.id as candidate_unit_id
  from _kimtokki_representative_seed s
  join public.expression e
    on regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
       regexp_replace(lower(s.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g')
   and e.status = 'ACTIVE'
  join public.candidate_unit cu
    on cu.legacy_candidate_key =
       'ASSOC_ATOMIC:' || s.source_memo_id || ':' || s.seed_key
  order by s.seed_key, e.id
)
insert into public.expression_source (expression_id, candidate_unit_id, created_at)
select r.expression_id, r.candidate_unit_id, now()
from resolved r
on conflict (candidate_unit_id) do nothing;

-- Rebuild automatically derived groups so the new atoms inherit their source
-- contexts, then add compact learning groups with deliberate labels.
select * from public.refresh_learning_association_groups();

insert into public.learning_association_group
  (group_key, label, group_type, status, display_order)
values
  ('SEMANTIC:COMPATIBILITY', '아이쇼·궁합', 'SEMANTIC', 'ACTIVE', 30),
  ('SEMANTIC:FRIEND_TERMS', '친구 표현', 'SEMANTIC', 'ACTIVE', 40),
  ('SEMANTIC:PICK_DISCARD', '줍다·버리다', 'SEMANTIC', 'ACTIVE', 50),
  ('SEMANTIC:KIKU_SENSES', '키쿠·듣다/효과', 'SEMANTIC', 'ACTIVE', 60)
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
  case when regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '아이쇼오'
       then 'CORE' else 'RELATED' end,
  case when regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '아이쇼오'
       then 1 else 2 end,
  case when regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '아이쇼오'
       then 1 else 10 end + row_number() over (order by e.id)::integer
from public.learning_association_group g
join public.expression e
  on e.status = 'ACTIVE'
 and regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') like '%아이쇼%'
where g.group_key = 'SEMANTIC:COMPATIBILITY'
on conflict (group_id, expression_id) do update
  set member_role = excluded.member_role,
      association_level = excluded.association_level,
      display_order = excluded.display_order;

with friend_order(pronunciation, display_order) as (
  values
    ('토모다치', 1), ('유우진', 2), ('나카마', 3),
    ('신유우', 4), ('다치', 5), ('아이보오', 6)
)
insert into public.learning_association_member
  (group_id, expression_id, member_role, association_level, display_order)
select g.id, e.id, 'CORE', 1, f.display_order
from friend_order f
join public.expression e
  on e.status = 'ACTIVE'
 and regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = f.pronunciation
join public.learning_association_group g on g.group_key = 'SEMANTIC:FRIEND_TERMS'
on conflict (group_id, expression_id) do update
  set member_role = excluded.member_role,
      association_level = excluded.association_level,
      display_order = excluded.display_order;

with pick_order(pronunciation, display_order) as (
  values ('히로우', 1), ('스테루', 2)
)
insert into public.learning_association_member
  (group_id, expression_id, member_role, association_level, display_order)
select g.id, e.id, 'CORE', 1, p.display_order
from pick_order p
join public.expression e
  on e.status = 'ACTIVE'
 and regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = p.pronunciation
join public.learning_association_group g on g.group_key = 'SEMANTIC:PICK_DISCARD'
on conflict (group_id, expression_id) do update
  set member_role = excluded.member_role,
      association_level = excluded.association_level,
      display_order = excluded.display_order;

insert into public.learning_association_member
  (group_id, expression_id, member_role, association_level, display_order)
select
  g.id,
  e.id,
  'CORE',
  1,
  row_number() over (order by em.meaning_text)::integer
from public.learning_association_group g
join public.expression e
  on e.status = 'ACTIVE'
 and regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '키쿠'
join public.expression_meaning em on em.expression_id = e.id and em.is_primary = true
where g.group_key = 'SEMANTIC:KIKU_SENSES'
  and em.meaning_text in ('소리를 듣다', '효과가 있다')
on conflict (group_id, expression_id) do update
  set member_role = excluded.member_role,
      association_level = excluded.association_level,
      display_order = excluded.display_order;

do $$
declare v_count integer;
begin
  select count(*) into v_count
  from _kimtokki_representative_seed s
  join public.expression e
    on e.status = 'ACTIVE'
   and regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
       regexp_replace(lower(s.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g');
  if v_count <> 8 then
    raise exception 'representative search atom count expected 8, got %', v_count;
  end if;

  select count(*) into v_count
  from public.learning_association_member m
  join public.learning_association_group g on g.id = m.group_id
  where g.group_key in (
    'SEMANTIC:FRIEND_TERMS', 'SEMANTIC:PICK_DISCARD', 'SEMANTIC:KIKU_SENSES'
  );
  if v_count <> 10 then
    raise exception 'compact semantic member count expected 10, got %', v_count;
  end if;
end
$$;
