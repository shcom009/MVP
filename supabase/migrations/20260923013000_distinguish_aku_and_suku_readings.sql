-- 空く / 空いている have different readings and meanings.
-- あく / あいている describe vacancy or availability;
-- すく / すいている describe being uncrowded.

select pg_advisory_xact_lock(hashtext('kimtokki_distinguish_aku_suku_v1'));

create temporary table _suku_candidate on commit drop as
select * from jsonb_to_recordset($json$[
  {
    "key":"SUKU",
    "legacy_key":"CHAT-20260923-SUKU",
    "jp":"空く",
    "pronunciation":"스쿠",
    "meaning":"한산해지다, 붐비지 않게 되다",
    "usage_note":"도로·가게·전철처럼 붐비던 곳이 한산해질 때 읽는 기본형. 같은 표기 空く를 아쿠로 읽으면 자리·일정 등이 비거나 이용 가능해진다는 뜻이다."
  },
  {
    "key":"SUITEIRU",
    "legacy_key":"CHAT-20260923-SUITEIRU",
    "jp":"空いている",
    "pronunciation":"스이테이루",
    "meaning":"한산하다, 붐비지 않다",
    "usage_note":"도로·가게·전철 등이 붐비지 않는 상태. 회화에서는 스이테루로 자주 줄인다. 자리·일정이 비었다는 아이테이루와 발음과 뜻을 구분한다."
  }
]$json$::jsonb) as x(
  key text, legacy_key text, jp text, pronunciation text, meaning text, usage_note text
);

-- Remove the uncrowded sense from the あいている entries.
update public.candidate_unit
set korean_meaning='비어 있다, 자리가 나 있다, 시간이 비어 있다',
    personal_note=case legacy_candidate_key
      when 'CHAT-20260923-AITEIRU' then '空く(아쿠)의 상태 표현. 자리·방·일정이 비거나 이용 가능한 상태이며 회화에서는 空いてる(아이테루)로 자주 줄인다. 도로나 가게가 한산하다는 뜻은 스이테이루로 읽는다.'
      else '空いている(아이테이루)의 자연스러운 회화 축약형. 자리·방·일정에 빈 공간이나 시간이 있을 때 쓴다. 한산하다는 뜻은 스이테루로 읽는다.'
    end
where legacy_candidate_key in ('CHAT-20260923-AITEIRU','CHAT-20260923-AITERU');

update public.expression_meaning em
set meaning_text='비어 있다, 자리가 나 있다, 시간이 비어 있다',
    meaning_norm=lower('비어 있다, 자리가 나 있다, 시간이 비어 있다'),
    usage_note=case
      when regexp_replace(lower(coalesce(e.display_pronunciation,'')), '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]', '', 'g')='아이테이루'
        then '空く(아쿠)의 상태 표현. 자리·방·일정이 비거나 이용 가능한 상태이며 회화에서는 空いてる(아이테루)로 자주 줄인다. 도로나 가게가 한산하다는 뜻은 스이테이루로 읽는다.'
      else '空いている(아이테이루)의 자연스러운 회화 축약형. 자리·방·일정에 빈 공간이나 시간이 있을 때 쓴다. 한산하다는 뜻은 스이테루로 읽는다.'
    end
from public.expression e
where em.expression_id=e.id and em.is_primary=true
  and regexp_replace(lower(coalesce(e.display_pronunciation,'')), '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]', '', 'g') in ('아이테이루','아이테루')
  and e.japanese_original in ('空いている','空いてる');

update public.note n
set note_text=cu.personal_note
from public.candidate_unit cu
where n.candidate_unit_id=cu.id
  and cu.legacy_candidate_key in ('CHAT-20260923-AITEIRU','CHAT-20260923-AITERU')
  and n.source_record_ref='conversation:2026-09-23:AKU_AITERU';

insert into public.candidate_unit (
  source_memo_id, legacy_candidate_key, korean_meaning, display_pronunciation,
  japanese_original, personal_note, literal_translation, recovery_method,
  verification_status, source_record_ref, source_excerpt,
  source_folder_snapshot, source_file_snapshot
)
select sm.id, c.legacy_key, c.meaning, c.pronunciation, c.jp, c.usage_note, null,
       'STUDY_CHAT_VERIFIED', 'VERIFIED', 'conversation:2026-09-23:AKU_AITERU',
       sm.original_text, '김토끼니혼고/일어수집', 'ChatGPT 일어수집 2026-09-23'
from _suku_candidate c
join public.source_memo sm on sm.memo_seq=-20260923095000
where not exists (
  select 1 from public.candidate_unit cu where cu.legacy_candidate_key=c.legacy_key
);

insert into public.expression (
  display_pronunciation, japanese_original, status, verification_status,
  speaking_enabled, listening_enabled, edge_flag, created_at, updated_at
)
select c.pronunciation, c.jp, 'ACTIVE', 'VERIFIED', true, true, false, now(), now()
from _suku_candidate c
where not exists (
  select 1 from public.expression e
  where regexp_replace(lower(coalesce(e.display_pronunciation,'')), '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]', '', 'g') =
        regexp_replace(lower(c.pronunciation), '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]', '', 'g')
    and e.japanese_original=c.jp and e.status <> 'EXCLUDED'
);

create temporary table _suku_resolved on commit drop as
select distinct on (c.key) c.*, sm.id source_memo_id, cu.id candidate_unit_id, e.id expression_id
from _suku_candidate c
join public.source_memo sm on sm.memo_seq=-20260923095000
join public.candidate_unit cu on cu.legacy_candidate_key=c.legacy_key
join public.expression e
  on regexp_replace(lower(coalesce(e.display_pronunciation,'')), '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]', '', 'g') =
     regexp_replace(lower(c.pronunciation), '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]', '', 'g')
 and e.japanese_original=c.jp and e.status='ACTIVE'
order by c.key, e.id;

insert into public.expression_meaning
  (expression_id, meaning_text, meaning_norm, meaning_order, is_primary, usage_note, created_at)
select r.expression_id, r.meaning, lower(btrim(r.meaning)), 1, true, r.usage_note, now()
from _suku_resolved r
where not exists (
  select 1 from public.expression_meaning em where em.expression_id=r.expression_id and em.is_primary=true
);

insert into public.search_alias
  (expression_id, alias_text, alias_norm, alias_type, origin, created_at)
select r.expression_id, r.pronunciation, lower(btrim(r.pronunciation)), 'NORMALIZED', 'SOURCE', now()
from _suku_resolved r
where not exists (
  select 1 from public.search_alias sa where sa.expression_id=r.expression_id and sa.alias_norm=lower(btrim(r.pronunciation))
);

insert into public.expression_source (expression_id, candidate_unit_id, created_at)
select r.expression_id, r.candidate_unit_id, now()
from _suku_resolved r
where not exists (select 1 from public.expression_source es where es.candidate_unit_id=r.candidate_unit_id);

insert into public.note (
  source_memo_id, candidate_unit_id, expression_id, source_record_ref,
  note_type, note_text, source_excerpt, display_order, created_at
)
select r.source_memo_id, r.candidate_unit_id, r.expression_id,
       'conversation:2026-09-23:AKU_AITERU', 'REFERENCE', r.usage_note,
       '空く·空いている의 아쿠/스쿠 읽기와 뜻 구분', 2, now()
from _suku_resolved r
where not exists (
  select 1 from public.note n where n.candidate_unit_id=r.candidate_unit_id
    and n.source_record_ref='conversation:2026-09-23:AKU_AITERU'
);

create temporary table _aku_suku_members on commit drop as
select distinct on (x.key) x.key, e.id expression_id
from (values
  ('AKU','아쿠'),
  ('AITERU','아이테루'),
  ('SUKU','스쿠'),
  ('SUITEIRU','스이테이루')
) x(key, pronunciation_norm)
join public.expression e
  on regexp_replace(lower(coalesce(e.display_pronunciation,'')), '[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]', '', 'g')=x.pronunciation_norm
 and e.status='ACTIVE'
order by x.key, e.id;

insert into public.learning_association_group
  (group_key, label, group_type, status, display_order, created_at, updated_at)
values ('STUDY_CHAT:AKU_SUKU_DISTINCTION','아쿠·스쿠 구분','SEMANTIC','ACTIVE',29,now(),now())
on conflict (group_key) do update
set label=excluded.label, status='ACTIVE', display_order=excluded.display_order, updated_at=now();

insert into public.learning_association_member
  (group_id, expression_id, member_role, association_level, display_order, created_at)
select g.id, m.expression_id,
       case when m.key in ('AKU','SUKU') then 'CORE' else 'RELATED' end,
       case when m.key in ('AKU','SUKU') then 1 else 2 end,
       case m.key when 'AKU' then 1 when 'AITERU' then 2 when 'SUKU' then 3 else 4 end,
       now()
from _aku_suku_members m
join public.learning_association_group g on g.group_key='STUDY_CHAT:AKU_SUKU_DISTINCTION'
on conflict (group_id, expression_id) do update
set member_role=excluded.member_role,
    association_level=excluded.association_level,
    display_order=excluded.display_order;

do $$
begin
  if (select count(*) from _suku_resolved) <> 2 then
    raise exception 'suku resolved count mismatch';
  end if;
  if (select count(*) from _aku_suku_members) <> 4 then
    raise exception 'aku/suku member count mismatch';
  end if;
end $$;
