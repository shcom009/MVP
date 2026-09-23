-- Add the approved learning material for 空く / 空いている / 空いてる.
-- Keep the current study-chat source separate from the original Naver memo source.

select pg_advisory_xact_lock(hashtext('kimtokki_aku_aiteru_learning_material_v1'));

create temporary table _aku_source on commit drop as
select
  -20260923095000::bigint as memo_seq,
  'conversation:2026-09-23:AKU_AITERU'::text as source_ref,
  $text$아시타 요루니 아이테루? 내일 저녁에 만날래? 시간 비어있어? '아이테루'가 시간이 비어있다는 의미로 쓰이는데 원래 뜻과 예문 알려줘$text$::text as user_input,
  $text$明日の夜、空いてる？ (아시타노 요루, 아이테루?) = 내일 저녁 시간 비어 있어? / 내일 저녁에 시간 돼?
空く (아쿠) = 비다, 자리가 나다, 이용 가능한 상태가 되다
空いている (아이테이루) → 空いてる (아이테루) = 비어 있는 상태가 계속되다
明日の夜、会える？ (아시타노 요루, 아에루?) = 내일 저녁에 만날 수 있어?$text$::text as summary;

create temporary table _aku_candidate on commit drop as
select * from jsonb_to_recordset($json$[
  {
    "key": "AKU",
    "legacy_key": "CHAT-20260923-AKU",
    "jp": "空く",
    "pronunciation": "아쿠",
    "meaning": "비다, 자리가 나다, 이용 가능한 상태가 되다",
    "usage_note": "차 있거나 사용 중이던 곳이 비거나 이용 가능한 상태가 되는 기본형. 좌석·방·가게·도로·일정에 폭넓게 쓴다."
  },
  {
    "key": "AITEIRU",
    "legacy_key": "CHAT-20260923-AITEIRU",
    "jp": "空いている",
    "pronunciation": "아이테이루",
    "meaning": "비어 있다, 한산하다, 시간이 비어 있다",
    "usage_note": "空く(아쿠)의 상태 표현. 비게 된 상태가 계속되고 있다는 뜻이며 회화에서는 空いてる(아이테루)로 자주 줄인다."
  },
  {
    "key": "AITERU",
    "legacy_key": "CHAT-20260923-AITERU",
    "jp": "空いてる",
    "pronunciation": "아이테루",
    "meaning": "비어 있다, 한산하다, 시간이 비어 있다",
    "usage_note": "空いている(아이테이루)의 자연스러운 회화 축약형. 자리·방뿐 아니라 일정에 빈 시간이 있을 때도 쓴다."
  },
  {
    "key": "ASHITANO_YORU_AITERU",
    "legacy_key": "CHAT-20260923-ASHITANO-YORU-AITERU",
    "jp": "明日の夜、空いてる？",
    "pronunciation": "아시타노 요루, 아이테루?",
    "meaning": "내일 저녁 시간 비어 있어? / 내일 저녁에 시간 돼?",
    "usage_note": "친구나 가까운 사람에게 약속 가능 시간을 가볍게 묻는 자연스러운 표현. 직접 만나자는 제안보다 먼저 시간이 되는지를 묻는다."
  },
  {
    "key": "KONO_SEKI_AITERU",
    "legacy_key": "CHAT-20260923-KONO-SEKI-AITERU",
    "jp": "この席、空いてる？",
    "pronunciation": "코노 세키, 아이테루?",
    "meaning": "이 자리 비어 있어?",
    "usage_note": "좌석을 누가 사용 중인지 가볍게 확인하는 회화 표현."
  },
  {
    "key": "ASHITANO_GOGO_AITERU",
    "legacy_key": "CHAT-20260923-ASHITANO-GOGO-AITERU",
    "jp": "明日の午後、空いてる？",
    "pronunciation": "아시타노 고고, 아이테루?",
    "meaning": "내일 오후에 시간 돼?",
    "usage_note": "상대의 내일 오후 일정에 빈 시간이 있는지 묻는 회화 표현."
  },
  {
    "key": "ASHITANO_YORU_AERU",
    "legacy_key": "CHAT-20260923-ASHITANO-YORU-AERU",
    "jp": "明日の夜、会える？",
    "pronunciation": "아시타노 요루, 아에루?",
    "meaning": "내일 저녁에 만날 수 있어?",
    "usage_note": "시간이 비는지만 묻는 空いてる？와 달리 직접 만날 수 있는지를 묻는다."
  }
]$json$::jsonb) as x(
  key text, legacy_key text, jp text, pronunciation text, meaning text, usage_note text
);

insert into public.source_memo (memo_seq, original_text, legacy_folder_id)
select s.memo_seq,
       '[사용자]' || E'\n' || s.user_input || E'\n\n[검토 결과]\n' || s.summary,
       'CHAT_일어수집'
from _aku_source s
where not exists (select 1 from public.source_memo sm where sm.memo_seq=s.memo_seq);

insert into public.source_memo_origin
  (source_memo_id, source_folder, source_file, occurrence_order)
select sm.id, '김토끼니혼고/일어수집', 'ChatGPT 일어수집 2026-09-23', 1
from _aku_source s
join public.source_memo sm on sm.memo_seq=s.memo_seq
where not exists (
  select 1 from public.source_memo_origin o
  where o.source_memo_id=sm.id and o.source_folder='김토끼니혼고/일어수집'
    and o.source_file='ChatGPT 일어수집 2026-09-23'
);

insert into public.candidate_unit (
  source_memo_id, legacy_candidate_key, korean_meaning, display_pronunciation,
  japanese_original, personal_note, literal_translation, recovery_method,
  verification_status, source_record_ref, source_excerpt,
  source_folder_snapshot, source_file_snapshot
)
select sm.id, c.legacy_key, c.meaning, c.pronunciation, c.jp, c.usage_note, null,
       'STUDY_CHAT_VERIFIED', 'VERIFIED', s.source_ref, s.user_input,
       '김토끼니혼고/일어수집', 'ChatGPT 일어수집 2026-09-23'
from _aku_candidate c
cross join _aku_source s
join public.source_memo sm on sm.memo_seq=s.memo_seq
where not exists (
  select 1 from public.candidate_unit cu where cu.legacy_candidate_key=c.legacy_key
);

-- Reuse the verified existing 아이테루 expression instead of creating a duplicate.
update public.expression e
set japanese_original='空いてる', updated_at=now()
where regexp_replace(lower(coalesce(e.display_pronunciation,'')), '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]', '', 'g')='아이테루'
  and e.status='ACTIVE'
  and e.japanese_original is null;

insert into public.expression (
  display_pronunciation, japanese_original, status, verification_status,
  speaking_enabled, listening_enabled, edge_flag, created_at, updated_at
)
select c.pronunciation, c.jp, 'ACTIVE', 'VERIFIED', true, true, false, now(), now()
from _aku_candidate c
where not exists (
  select 1 from public.expression e
  where regexp_replace(lower(coalesce(e.japanese_original,'')), '[[:space:]、。！？!?「」『』（）()・]', '', 'g') =
        regexp_replace(lower(c.jp), '[[:space:]、。！？!?「」『』（）()・]', '', 'g')
    and e.status <> 'EXCLUDED'
);

create temporary table _aku_resolved on commit drop as
select distinct on (c.key)
       c.*, s.source_ref, s.user_input, sm.id source_memo_id,
       cu.id candidate_unit_id, e.id expression_id
from _aku_candidate c
cross join _aku_source s
join public.source_memo sm on sm.memo_seq=s.memo_seq
join public.candidate_unit cu on cu.legacy_candidate_key=c.legacy_key
join public.expression e
  on regexp_replace(lower(coalesce(e.japanese_original,'')), '[[:space:]、。！？!?「」『』（）()・]', '', 'g') =
     regexp_replace(lower(c.jp), '[[:space:]、。！？!?「」『』（）()・]', '', 'g')
 and e.status='ACTIVE'
order by c.key, e.id;

insert into public.expression_meaning
  (expression_id, meaning_text, meaning_norm, meaning_order, is_primary, usage_note, created_at)
select r.expression_id, r.meaning, lower(btrim(r.meaning)), 1, true, r.usage_note, now()
from _aku_resolved r
where not exists (
  select 1 from public.expression_meaning em
  where em.expression_id=r.expression_id and em.is_primary=true
);

update public.expression_meaning em
set meaning_text=r.meaning,
    meaning_norm=lower(btrim(r.meaning)),
    usage_note=r.usage_note
from _aku_resolved r
where em.expression_id=r.expression_id and em.is_primary=true;

-- Correct two existing time-check meanings that were previously shown as direct meeting proposals.
update public.expression_meaning em
set meaning_text='오늘 저녁 시간 비어 있어? / 오늘 저녁에 시간 돼?',
    meaning_norm=lower('오늘 저녁 시간 비어 있어? / 오늘 저녁에 시간 돼?'),
    usage_note='직접 만나자는 말보다 오늘 저녁 시간이 되는지를 묻는다. 원문 발음은 보존하되 쿄오노 요루 아이테루?가 더 자연스럽다.'
from public.expression e
where em.expression_id=e.id and em.is_primary=true
  and regexp_replace(lower(coalesce(e.display_pronunciation,'')), '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]', '', 'g')='쿄오요루니아이테루';

update public.expression_meaning em
set meaning_text='내일 시간 비어 있어? / 내일 시간 돼?',
    meaning_norm=lower('내일 시간 비어 있어? / 내일 시간 돼?'),
    usage_note='직접 만나자는 말보다 내일 시간이 되는지를 먼저 묻는 표현.'
from public.expression e
where em.expression_id=e.id and em.is_primary=true
  and regexp_replace(lower(coalesce(e.display_pronunciation,'')), '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]', '', 'g')='아시타아이테루';

insert into public.search_alias
  (expression_id, alias_text, alias_norm, alias_type, origin, created_at)
select r.expression_id, r.pronunciation,
       regexp_replace(regexp_replace(regexp_replace(lower(btrim(r.pronunciation)), '[↗↘~]', '', 'g'), '\s+', ' ', 'g'), '[?？!！。．.]+$', '', 'g'),
       'NORMALIZED', 'SOURCE', now()
from _aku_resolved r
where not exists (
  select 1 from public.search_alias sa
  where sa.expression_id=r.expression_id
    and sa.alias_norm=regexp_replace(regexp_replace(regexp_replace(lower(btrim(r.pronunciation)), '[↗↘~]', '', 'g'), '\s+', ' ', 'g'), '[?？!！。．.]+$', '', 'g')
);

create temporary table _aku_alias on commit drop as
select * from jsonb_to_recordset($json$[
  {"key":"ASHITANO_YORU_AITERU","alias_text":"아시타 요루니 아이테루"},
  {"key":"ASHITANO_YORU_AITERU","alias_text":"아시타 요루 아이테루"},
  {"key":"ASHITANO_YORU_AITERU","alias_text":"아시타노 요루 아이테루"}
]$json$::jsonb) as x(key text, alias_text text);

insert into public.search_alias
  (expression_id, alias_text, alias_norm, alias_type, origin, created_at)
select r.expression_id, a.alias_text,
       regexp_replace(regexp_replace(regexp_replace(lower(btrim(a.alias_text)), '[↗↘~]', '', 'g'), '\s+', ' ', 'g'), '[?？!！。．.]+$', '', 'g'),
       'SOURCE_VARIANT', 'SOURCE', now()
from _aku_alias a
join _aku_resolved r using (key)
where not exists (
  select 1 from public.search_alias sa
  where sa.expression_id=r.expression_id
    and sa.alias_norm=regexp_replace(regexp_replace(regexp_replace(lower(btrim(a.alias_text)), '[↗↘~]', '', 'g'), '\s+', ' ', 'g'), '[?？!！。．.]+$', '', 'g')
);

insert into public.expression_source (expression_id, candidate_unit_id, created_at)
select r.expression_id, r.candidate_unit_id, now()
from _aku_resolved r
where not exists (
  select 1 from public.expression_source es where es.candidate_unit_id=r.candidate_unit_id
);

insert into public.note (
  source_memo_id, candidate_unit_id, expression_id, source_record_ref,
  note_type, note_text, source_excerpt, display_order, created_at
)
select r.source_memo_id, r.candidate_unit_id, r.expression_id, r.source_ref,
       'REFERENCE', r.usage_note, r.user_input, 1, now()
from _aku_resolved r
where not exists (
  select 1 from public.note n
  where n.expression_id=r.expression_id and n.source_record_ref=r.source_ref
    and n.note_type='REFERENCE' and n.note_text=r.usage_note
);

create temporary table _aku_existing on commit drop as
select distinct on (x.key) x.key, e.id as expression_id
from (values
  ('ANTA_KONYA_AITERU','안타콘야아이테루'),
  ('AITERU_KA','아이테루카'),
  ('ASHITA_AITERU','아시타아이테루')
) as x(key, pronunciation_norm)
join public.expression e
  on regexp_replace(lower(coalesce(e.display_pronunciation,'')), '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]', '', 'g')=x.pronunciation_norm
 and e.status='ACTIVE'
order by x.key, e.id;

create temporary table _aku_all_resolved on commit drop as
select key, expression_id from _aku_resolved
union all
select key, expression_id from _aku_existing;

create temporary table _aku_group on commit drop as
select * from jsonb_to_recordset($json$[
  {
    "group_key":"STUDY_CHAT:AKU_AITERU_FORM",
    "label":"아쿠·아이테루",
    "keys":["AKU","AITEIRU","AITERU"]
  },
  {
    "group_key":"STUDY_CHAT:AITERU_TIME_SEAT",
    "label":"시간·자리 비다",
    "keys":["AITERU","ASHITANO_YORU_AITERU","KONO_SEKI_AITERU","ASHITANO_GOGO_AITERU","ASHITA_AITERU","ANTA_KONYA_AITERU","AITERU_KA"]
  },
  {
    "group_key":"STUDY_CHAT:TIME_CHECK_MEETING",
    "label":"시간 확인·만남 제안",
    "keys":["ASHITANO_YORU_AITERU","ASHITANO_YORU_AERU"]
  }
]$json$::jsonb) as x(group_key text, label text, keys jsonb);

insert into public.learning_association_group
  (group_key, label, group_type, status, display_order, created_at, updated_at)
select g.group_key, g.label, 'SEMANTIC', 'ACTIVE', 30, now(), now()
from _aku_group g
on conflict (group_key) do update
set label=excluded.label, status='ACTIVE', display_order=excluded.display_order, updated_at=now();

insert into public.learning_association_member
  (group_id, expression_id, member_role, association_level, display_order, created_at)
select g.id, r.expression_id,
       case when k.ord=1 then 'CORE' else 'RELATED' end,
       case when k.ord=1 then 1 else 2 end,
       k.ord::integer, now()
from _aku_group sg
join public.learning_association_group g on g.group_key=sg.group_key
cross join lateral jsonb_array_elements_text(sg.keys) with ordinality as k(key, ord)
join _aku_all_resolved r on r.key=k.key
on conflict (group_id, expression_id) do update
set member_role=excluded.member_role,
    association_level=excluded.association_level,
    display_order=excluded.display_order;

do $$
declare
  v_sources integer;
  v_resolved integer;
  v_group_members integer;
begin
  select count(*) into v_sources
  from _aku_source s join public.source_memo sm on sm.memo_seq=s.memo_seq;
  select count(*) into v_resolved from _aku_resolved;
  select count(*) into v_group_members
  from _aku_group sg
  cross join lateral jsonb_array_elements_text(sg.keys) k
  join _aku_all_resolved r on r.key=k.value;

  if v_sources <> 1 then raise exception 'aku source count mismatch: %', v_sources; end if;
  if v_resolved <> 7 then raise exception 'aku resolved count mismatch: %', v_resolved; end if;
  if v_group_members <> 12 then raise exception 'aku group member count mismatch: %', v_group_members; end if;
  if not exists (
    select 1 from public.search_alias sa
    join _aku_resolved r on r.expression_id=sa.expression_id and r.key='ASHITANO_YORU_AITERU'
    where sa.alias_norm='아시타 요루니 아이테루'
  ) then raise exception 'aku source pronunciation alias missing'; end if;
end $$;
