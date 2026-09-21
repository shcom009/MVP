-- Promote source-explicit time headwords from source_memo.id = 149.
-- Source spellings are preserved for learning; they can be normalized separately later.

do $$
declare
  r record;
  v_candidate_id bigint;
  v_expression_id bigint;
  v_group_id bigint;
begin
  perform pg_advisory_xact_lock(hashtext('kimtokki_atomic_expression_seed'));

  select id into v_group_id
  from public.learning_association_group
  where group_key = 'SEMANTIC:TIME';

  if v_group_id is null then
    raise exception 'SEMANTIC:TIME group is missing';
  end if;

  for r in
    select *
    from (values
      (1,  'GOZEN',          '고젠',          '오전'),
      (2,  'GOGO',           '고고',          '오후'),
      (3,  'GOZEN_07',       '고젠 나나지',   '오전7시'),
      (4,  'GOZEN_08',       '고젠 하치지',   '오전8시'),
      (5,  'GOZEN_09',       '고젠 큐지',     '오전9시'),
      (6,  'GOZEN_10',       '고젠 쥬지',     '오전10시'),
      (7,  'GOZEN_11',       '고젠 쥬이치지', '오전11시'),
      (8,  'GOZEN_12',       '고젠 쥬니지',   '오전12시'),
      (9,  'GOGO_01',        '고고 이치지',   '오후1시'),
      (10, 'GOGO_02',        '고고 니지',     '오후2시'),
      (11, 'GOGO_03',        '고고 산지',     '오후3시'),
      (12, 'GOGO_04',        '고고 욘지',     '오후4시'),
      (13, 'GOGO_05',        '고고 고지',     '오후5시'),
      (14, 'GOGO_06',        '고고 로쿠지',   '오후6시'),
      (15, 'GOGO_07',        '고고 나나지',   '오후7시'),
      (16, 'GOGO_08',        '고고 하치지',   '오후8시'),
      (17, 'GOGO_09',        '고고 큐지',     '오후9시'),
      (18, 'GOGO_10',        '고고 쥬지',     '오후10시'),
      (19, 'GOGO_11',        '고고 쥬이치지', '오후11시'),
      (20, 'GOGO_12',        '고고 쥬니지',   '오후12시'),
      (21, 'JUPPUN_10',      '쥽뿐',           '십분'),
      (22, 'NIJUPPUN_20',    '니쥽뿐',         '이십분'),
      (23, 'SANJUPPUN_30',   '산쥽뿐',         '삼십분'),
      (24, 'ICHIJIKAN',      '이치지깐',       '한시간'),
      (25, 'ATODE_10',       '아토데 쥿분',    '앞으로 10분'),
      (26, 'ATO_SUKOSHI',    '아토 스코시',    '앞으로 조금더'),
      (27, 'SANJUUPUN_DE',   '산쥬분데',       '30분에')
    ) as seed(seed_order, seed_key, display_pronunciation, meaning_text)
  loop
    select cu.id into v_candidate_id
    from public.candidate_unit cu
    where cu.legacy_candidate_key = 'ASSOC_ATOMIC:149:' || r.seed_key;

    if v_candidate_id is null then
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
      ) values (
        149,
        'ASSOC_ATOMIC:149:' || r.seed_key,
        r.meaning_text,
        r.display_pronunciation,
        null,
        null,
        null,
        'SOURCE_ATOMIC_SPLIT',
        'VERIFIED',
        'memoSeq:1358886',
        r.display_pronunciation || ', ' || r.meaning_text,
        '일어-외워',
        'source_memo:149'
      ) returning id into v_candidate_id;
    end if;

    select e.id into v_expression_id
    from public.expression e
    where regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
          regexp_replace(lower(r.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g')
      and e.status = 'ACTIVE'
    order by e.id
    limit 1;

    if v_expression_id is null then
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
      ) values (
        r.display_pronunciation,
        null,
        'ACTIVE',
        'VERIFIED',
        true,
        true,
        false,
        now(),
        now()
      ) returning id into v_expression_id;

      insert into public.expression_meaning (
        expression_id,
        meaning_text,
        meaning_norm,
        meaning_order,
        is_primary,
        usage_note,
        created_at
      ) values (
        v_expression_id,
        r.meaning_text,
        lower(btrim(r.meaning_text)),
        1,
        true,
        null,
        now()
      );
    end if;

    insert into public.search_alias (
      expression_id,
      alias_text,
      alias_norm,
      alias_type,
      origin,
      created_at
    ) values (
      v_expression_id,
      r.display_pronunciation,
      lower(btrim(r.display_pronunciation)),
      'NORMALIZED',
      'SOURCE',
      now()
    ) on conflict (expression_id, alias_type, alias_norm) do nothing;

    insert into public.expression_source (expression_id, candidate_unit_id, created_at)
    values (v_expression_id, v_candidate_id, now())
    on conflict (candidate_unit_id) do nothing;

    insert into public.learning_association_member (
      group_id,
      expression_id,
      member_role,
      association_level,
      display_order
    ) values (
      v_group_id,
      v_expression_id,
      'CORE',
      1,
      r.seed_order
    ) on conflict (group_id, expression_id) do update
      set member_role = excluded.member_role,
          association_level = excluded.association_level,
          display_order = excluded.display_order;
  end loop;
end
$$;

-- Refresh only automatically derived category/memo membership.
select * from public.refresh_learning_association_groups();
