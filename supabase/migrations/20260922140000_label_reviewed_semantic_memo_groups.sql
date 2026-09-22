-- Persist manually reviewed labels for source-memo groups whose headings and
-- members are semantically aligned despite spelling, inflection, or wording
-- differences. Deliberately unrelated headings remain unlabeled.

create or replace function public.source_memo_reviewed_label(
  p_group_key text
)
returns text
language sql
immutable
set search_path = public, pg_temp
as $$
  select v.label
  from (
    values
      ('MEMO:33', '기차역 안내방송'),
      ('MEMO:45', '아케루·히라쿠'),
      ('MEMO:154', '이카가데스까·어떠세요'),
      ('MEMO:207', '호텔'),
      ('MEMO:222', '요즘 보기 힘드네'),
      ('MEMO:239', '할로윈에 뭐해'),
      ('MEMO:245', '콘나 토코로니 이루노'),
      ('MEMO:253', '카레시 이나이노'),
      ('MEMO:263', '데·쿠테 연결'),
      ('MEMO:345', '신주쿠역 정차'),
      ('MEMO:351', '주문하지 않았습니다'),
      ('MEMO:357', '종조사'),
      ('MEMO:371', '조사'),
      ('MEMO:386', '도망치다·뛰쳐나가다'),
      ('MEMO:400', '길 찾기·건물 안내'),
      ('MEMO:423', '길찾기·길안내'),
      ('MEMO:461', '누쿠·뽑다'),
      ('MEMO:531', '공항·항공편'),
      ('MEMO:539', '가·지만'),
      ('MEMO:561', '나니 시타라 이이'),
      ('MEMO:630', '하루 종일 구경'),
      ('MEMO:671', '츠마라나이·시시하다'),
      ('MEMO:683', '어떻게 가면 돼'),
      ('MEMO:681', '사소우·사세루'),
      ('MEMO:690', '후쿠로·봉투'),
      ('MEMO:721', '예쁜 다리'),
      ('MEMO:733', '소레요리·그보다'),
      ('MEMO:744', '먼저 가기·기다리기'),
      ('MEMO:770', '개인적인 취향'),
      ('MEMO:771', '시간별 요금'),
      ('MEMO:785', '불길함·착각'),
      ('MEMO:818', '늦어서 미안해요'),
      ('MEMO:820', '내일은 안 돼요'),
      ('MEMO:839', '치트 사용'),
      ('MEMO:877', '평범한 요즘'),
      ('MEMO:928', '뭐라고 합니까'),
      ('MEMO:933', '요캇타라·요로시케레바'),
      ('MEMO:939', '오모이데·추억'),
      ('MEMO:945', '결혼 여부 묻기'),
      ('MEMO:959', '쿠라스·생활하다'),
      ('MEMO:979', '싫어한다고 답하기'),
      ('MEMO:983', '호텔 외국인 응대'),
      ('MEMO:984', '길묻기·길찾기'),
      ('MEMO:1058', '견디다·버티다'),
      ('MEMO:1082', '기대하지 마'),
      ('MEMO:1361', '배고파요'),
      ('MEMO:1398', '야리나오스·다시하다'),
      ('MEMO:1429', '무엇으로 만들었나요'),
      ('MEMO:1440', '진쟈·신사'),
      ('MEMO:1452', '일본은 처음인가요'),
      ('MEMO:1463', '남녀 취향'),
      ('MEMO:1491', '한국인인 줄 알았어'),
      ('MEMO:1496', '돗토리 여행'),
      ('MEMO:1503', '내일 약속'),
      ('MEMO:1547', '이이카겐니 시테·그만해'),
      ('MEMO:1548', '소치라·그쪽'),
      ('MEMO:1564', '게다가'),
      ('MEMO:1623', '장음 발음'),
      ('MEMO:1656', '일본 여행지'),
      ('MEMO:1677', '나이가 들어서'),
      ('MEMO:1729', '나가이키·장수'),
      ('MEMO:1806', '나카요쿠·친하게'),
      ('MEMO:1825', '지하철 안내'),
      ('MEMO:1833', '매장 재고 확인'),
      ('MEMO:1861', '어느 편이야'),
      ('MEMO:1879', '차량 이상·긴급정차'),
      ('MEMO:1937', '쇼오라이·장래'),
      ('MEMO:1943', '노니·그런데도'),
      ('MEMO:1956', '테이블 위에 놓기'),
      ('MEMO:2012', '하즈스·떼다'),
      ('MEMO:2104', '보다·보여주다'),
      ('MEMO:2114', '스레치가이·엇갈림'),
      ('MEMO:2246', '와타스·건네다'),
      ('MEMO:2272', '테키토오·적당'),
      ('MEMO:2329', '생각보다'),
      ('MEMO:2587', '다로오카나·일까'),
      ('MEMO:2635', '한번 해줘'),
      ('MEMO:2646', '상관없어'),
      ('MEMO:2727', '연락처 교환'),
      ('MEMO:2860', '엇갈리다'),
      ('MEMO:2885', '열사병 알아'),
      ('MEMO:2897', '진정하고 쉬기'),
      ('MEMO:2934', '세상은 힘들어'),
      ('MEMO:2938', '옷 입어보기'),
      ('MEMO:2951', '양이 많아 보여'),
      ('MEMO:3002', '어리석음을 깨닫다'),
      ('MEMO:3115', '후회는 늘어간다'),
      ('MEMO:3133', '난토 이에바 이이카'),
      ('MEMO:3182', '화제 전환'),
      ('MEMO:3245', '느끼한 맛'),
      ('MEMO:3257', '가능형'),
      ('MEMO:3308', '소레요리·테유우카'),
      ('MEMO:3311', '익숙하지 않아'),
      ('MEMO:3365', '다정한 말'),
      ('MEMO:3412', '치카미치·지름길'),
      ('MEMO:3439', '튀김가루 묻히기'),
      ('MEMO:3452', '살찐 것 같아'),
      ('MEMO:3462', '감사히 받겠습니다'),
      ('MEMO:3473', '노리 와루이·흥이 없다'),
      ('MEMO:3477', '들어보고 싶어요'),
      ('MEMO:3483', '시간이 금방 지나가다'),
      ('MEMO:3491', '칼과 풋고추'),
      ('MEMO:3507', '텟키리·확실히'),
      ('MEMO:3510', '다레시모·누구든'),
      ('MEMO:3512', '케이크 고르기'),
      ('MEMO:3533', '키라와레루·미움받다'),
      ('MEMO:3560', '쉬고 나서'),
      ('MEMO:3568', '다테쟈나이·진짜다'),
      ('MEMO:3570', '토이우·라고 하다'),
      ('MEMO:3573', '우리 사이잖아'),
      ('MEMO:3579', '여기서 뭐 하세요'),
      ('MEMO:3600', '이케테루·신조어'),
      ('MEMO:3601', '도오모 코오모·어쩔 수 없다'),
      ('MEMO:3603', '고양이가 되고 싶다'),
      ('MEMO:3608', '더 신경 썼더라면'),
      ('MEMO:3647', '천국에 갈 거야'),
      ('MEMO:3648', '간이 잘 배어 있다'),
      ('MEMO:3649', '가마할아버지 같아'),
      ('MEMO:3654', '사거리 건너편'),
      ('MEMO:3657', '타소가레루·사색하다'),
      ('MEMO:3664', '일본은 10년 만'),
      ('MEMO:3667', '분명 잘 될 거야'),
      ('MEMO:3669', '꿈을 꾸다'),
      ('MEMO:3670', '운에 맡기다'),
      ('MEMO:3680', '테라스하우스 소개'),
      ('MEMO:3687', '후코오헤이·불공평'),
      ('MEMO:3688', '스스로 판단하기'),
      ('MEMO:3692', '미세모노·구경거리'),
      ('MEMO:3695', '코오죠오·공장'),
      ('MEMO:3697', '해봐도 괜찮을지도'),
      ('MEMO:3698', '라시이·답다/답지 않다'),
      ('MEMO:3702', '날씨 경보'),
      ('MEMO:3712', '다른 것도 먹어볼까'),
      ('MEMO:3713', '결국 ~일 뿐'),
      ('MEMO:3725', '이쪽으로 오고 있어'),
      ('MEMO:3736', '일본인처럼 말하기'),
      ('MEMO:3745', '사적인 건 묻지 않기'),
      ('MEMO:3780', '라멘이 질리다'),
      ('MEMO:3785', '안 가도 돼'),
      ('MEMO:3789', '이럴 때가 아니야'),
      ('MEMO:3791', '나니가 나니야라'),
      ('MEMO:3792', '바카니 스루·무시하다'),
      ('MEMO:3793', '아직 아가씨 같아요'),
      ('MEMO:3818', '야바이·비주얼'),
      ('MEMO:3819', '국물을 머금다'),
      ('MEMO:3823', '고를 수 없으니까'),
      ('MEMO:3824', '코시·면발 탄력'),
      ('MEMO:3826', '틀림없이 최고'),
      ('MEMO:3835', '시메·마무리'),
      ('MEMO:3849', '먹지만 좋아하진 않아'),
      ('MEMO:3854', '한국의 치지미'),
      ('MEMO:3859', '향과 단맛이 퍼지다'),
      ('MEMO:3863', '고항 도로보오·밥도둑'),
      ('MEMO:3866', '정진하겠습니다'),
      ('MEMO:3869', '발음이 이상하죠'),
      ('MEMO:3872', '아리다·괜찮은 선택'),
      ('MEMO:3873', '와케쟈 나이·아닌 건 아니다'),
      ('MEMO:3874', '토 이우 요리·라기보다'),
      ('MEMO:3875', '아이테니 스루나·상대하지 마')
  ) as v(group_key, label)
  where v.group_key = p_group_key
  limit 1;
$$;

revoke all on function public.source_memo_reviewed_label(text)
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
      ) as structured_heading_label,
      public.source_memo_exact_phrase_label(
        sm.original_text,
        mt.member_text
      ) as exact_phrase_label,
      public.source_memo_reviewed_label(g.group_key) as reviewed_label
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
          exact_phrase_label,
          reviewed_label,
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
