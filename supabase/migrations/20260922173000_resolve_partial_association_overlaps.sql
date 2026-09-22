-- Resolve the three reviewed category/source partial overlaps without losing
-- source provenance. Two ambiguous pairs move into focused semantic groups;
-- the direction source group is already a clean subset of its category.

do $$
begin
  if to_regprocedure('public.refresh_learning_association_groups_partial_overlap_base()') is null then
    alter function public.refresh_learning_association_groups()
      rename to refresh_learning_association_groups_partial_overlap_base;
  end if;
end
$$;

revoke all on function public.refresh_learning_association_groups_partial_overlap_base()
  from public, anon, authenticated;

create or replace function public.apply_partial_overlap_learning_overrides()
returns table(active_group_count bigint, active_member_count bigint)
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_count integer;
begin
  -- Clarify the meanings of the two timetable terms while preserving both.
  update public.expression_meaning em
  set meaning_text = case
        when regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '지코쿠효오'
          then '교통 시간표'
        when regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '지칸효오'
          then '수업·업무 시간 배정표'
      end,
      meaning_norm = lower(case
        when regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '지코쿠효오'
          then '교통 시간표'
        when regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '지칸효오'
          then '수업·업무 시간 배정표'
      end),
      usage_note = case
        when regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '지코쿠효오'
          then '열차·버스 등의 출발·도착 시간을 적은 표.'
        when regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '지칸효오'
          then '수업이나 업무 시간을 배정한 표. 교통 시간표는 지코쿠효오를 사용.'
      end
  from public.expression e
  where e.id = em.expression_id
    and em.is_primary = true
    and e.status = 'ACTIVE'
    and regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g')
        in ('지코쿠효오', '지칸효오');

  -- Keep the original archery sentence, but explain which form is the normal
  -- choice when the intended activity is Japanese kyudo.
  update public.expression_meaning em
  set usage_note = case
        when regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
             '사이킨큐우도오오나랏테마스가'
          then '궁도를 배우고 있다는 자연스러운 표현.'
        when regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
             '사이킨유미야오나랏테마스가'
          then '원문 표현. 일반적인 궁도 학습은 큐우도오오 나랏테마스가를 사용.'
      end
  from public.expression e
  where e.id = em.expression_id
    and em.is_primary = true
    and e.status = 'ACTIVE'
    and regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g')
        in ('사이킨큐우도오오나랏테마스가', '사이킨유미야오나랏테마스가');

  insert into public.learning_association_group
    (group_key, label, group_type, status, display_order)
  values
    ('SEMANTIC:TIMETABLE_TERMS', '시간표 구분', 'SEMANTIC', 'ACTIVE', 70),
    ('SEMANTIC:ARCHERY_EXPRESSIONS', '활쏘기·궁도', 'SEMANTIC', 'ACTIVE', 80)
  on conflict (group_key) do update
    set label = excluded.label,
        group_type = excluded.group_type,
        status = excluded.status,
        display_order = excluded.display_order,
        updated_at = now();

  delete from public.learning_association_member m
  using public.learning_association_group g
  where m.group_id = g.id
    and g.group_key in (
      'SEMANTIC:TIMETABLE_TERMS',
      'SEMANTIC:ARCHERY_EXPRESSIONS'
    );

  -- These expressions keep their expression_source rows. Only the overly broad
  -- memo-group membership is replaced by the focused semantic group.
  delete from public.learning_association_member m
  using public.learning_association_group g, public.expression e
  where m.group_id = g.id
    and e.id = m.expression_id
    and (
      (
        g.group_key = 'MEMO:124'
        and regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') = '지칸효오'
      )
      or
      (
        g.group_key = 'MEMO:739'
        and regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
            '사이킨유미야오나랏테마스가'
      )
    );

  with reviewed(group_key, pronunciation_norm, member_order) as (
    values
      ('SEMANTIC:TIMETABLE_TERMS', '지코쿠효오', 1),
      ('SEMANTIC:TIMETABLE_TERMS', '지칸효오', 2),
      ('SEMANTIC:ARCHERY_EXPRESSIONS', '사이킨큐우도오오나랏테마스가', 1),
      ('SEMANTIC:ARCHERY_EXPRESSIONS', '사이킨유미야오나랏테마스가', 2)
  ), resolved as (
    select
      r.group_key,
      r.member_order,
      (
        select e.id
        from public.expression e
        where e.status = 'ACTIVE'
          and regexp_replace(lower(e.display_pronunciation), '[^0-9a-z가-힣]+', '', 'g') =
              r.pronunciation_norm
        order by e.id
        limit 1
      ) as expression_id
    from reviewed r
  )
  insert into public.learning_association_member
    (group_id, expression_id, member_role, association_level, display_order)
  select
    g.id,
    r.expression_id,
    'CORE',
    1,
    r.member_order
  from resolved r
  join public.learning_association_group g on g.group_key = r.group_key
  where r.expression_id is not null
  on conflict (group_id, expression_id) do update
    set member_role = excluded.member_role,
        association_level = excluded.association_level,
        display_order = excluded.display_order;

  select count(*) into v_count
  from public.learning_association_member m
  join public.learning_association_group g on g.id = m.group_id
  where g.group_key in (
    'SEMANTIC:TIMETABLE_TERMS',
    'SEMANTIC:ARCHERY_EXPRESSIONS'
  );
  if v_count <> 4 then
    raise exception 'partial-overlap semantic member count expected 4, got %', v_count;
  end if;

  -- After moving the two unique rows, all three source groups must be clean
  -- subsets of their paired categories.
  with pairs(category_key, source_key) as (
    values
      ('CATEGORY:18', 'MEMO:124'),
      ('CATEGORY:3', 'MEMO:739'),
      ('CATEGORY:29', 'MEMO:77')
  )
  select count(*) into v_count
  from pairs p
  join public.learning_association_group sg on sg.group_key = p.source_key
  join public.learning_association_member sm on sm.group_id = sg.id
  where not exists (
    select 1
    from public.learning_association_group cg
    join public.learning_association_member cm on cm.group_id = cg.id
    where cg.group_key = p.category_key
      and cm.expression_id = sm.expression_id
  );
  if v_count <> 0 then
    raise exception 'reviewed source groups still contain % non-category members', v_count;
  end if;

  return query
  select
    (select count(*) from public.learning_association_group where status = 'ACTIVE'),
    (select count(*)
       from public.learning_association_member m
       join public.learning_association_group g on g.id = m.group_id
      where g.status = 'ACTIVE');
end;
$$;

revoke all on function public.apply_partial_overlap_learning_overrides()
  from public, anon, authenticated;

create or replace function public.refresh_learning_association_groups()
returns table(group_count bigint, member_count bigint)
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  perform * from public.refresh_learning_association_groups_partial_overlap_base();
  return query
  select o.active_group_count, o.active_member_count
  from public.apply_partial_overlap_learning_overrides() o;
end;
$$;

revoke all on function public.refresh_learning_association_groups()
  from public, anon, authenticated;

select * from public.apply_partial_overlap_learning_overrides();
