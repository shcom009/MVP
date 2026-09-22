-- Split the eight remaining generic source-memo groups into only the
-- high-confidence learning clusters, and keep the decisions reproducible
-- after a full association refresh.

alter function public.refresh_learning_association_groups()
  rename to refresh_learning_association_groups_labeled_base;

revoke all on function public.refresh_learning_association_groups_labeled_base()
  from public, anon, authenticated;

create or replace function public.apply_curated_learning_association_overrides()
returns table(active_group_count bigint, active_member_count bigint)
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- These source memos mix unrelated topics. Keep the source memo itself,
  -- but do not expose the broad derived group in the learning UI.
  update public.learning_association_group
  set status = 'INACTIVE',
      updated_at = now()
  where group_key in (
    'MEMO:302', 'MEMO:475', 'MEMO:1326', 'MEMO:1484',
    'MEMO:2602', 'MEMO:3161', 'MEMO:3367', 'MEMO:3813'
  );

  delete from public.learning_association_member m
  using public.learning_association_group g
  where m.group_id = g.id
    and g.group_key in (
      'MEMO:302', 'MEMO:475', 'MEMO:1326', 'MEMO:1484',
      'MEMO:2602', 'MEMO:3161', 'MEMO:3367', 'MEMO:3813'
    );

  -- Stable label overrides for reviewed groups. The first merges two groups
  -- with the same learning meaning; the second makes a pronunciation-comparison
  -- group explicit instead of looking like a broad lexical relation.
  update public.learning_association_group
  set label = case group_key
        when 'MEMO:2329' then '생각보다·의외로'
        when 'MEMO:91' then '비슷한 발음 비교'
      end,
      updated_at = now()
  where group_key in ('MEMO:2329', 'MEMO:91');

  insert into public.learning_association_group
    (group_key, label, group_type, status, display_order)
  values
    ('MEMO:475:TTOITTE', '토 잇테·라고 해서', 'SOURCE_MEMO', 'ACTIVE', 140),
    ('MEMO:475:DIFFERENCE', '차이 묻기', 'SOURCE_MEMO', 'ACTIVE', 140),
    ('MEMO:475:NANAMI', '나나미 찾기', 'SOURCE_MEMO', 'ACTIVE', 140),
    ('MEMO:475:CHOICE', '고르기·결정', 'SOURCE_MEMO', 'ACTIVE', 140),
    ('MEMO:475:OUTING', '외출·약속', 'SOURCE_MEMO', 'ACTIVE', 140),
    ('MEMO:1484:ENOUGH', '충분·딱 좋음', 'SOURCE_MEMO', 'ACTIVE', 140),
    ('MEMO:3813:QUESTION', '그게 뭐야·몰라', 'SOURCE_MEMO', 'ACTIVE', 140)
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
      'MEMO:475:TTOITTE', 'MEMO:475:DIFFERENCE', 'MEMO:475:NANAMI',
      'MEMO:475:CHOICE', 'MEMO:475:OUTING', 'MEMO:1484:ENOUGH',
      'MEMO:3813:QUESTION'
    );

  with reviewed(group_key, pronunciation, member_order) as (
    values
      ('MEMO:475:TTOITTE', '호무타운토 잇떼', 1),
      ('MEMO:475:TTOITTE', '소주토잇떼', 2),
      ('MEMO:475:DIFFERENCE', '비묘오니 치가이마스', 1),
      ('MEMO:475:DIFFERENCE', '난노 치가이가 아리마스까?', 2),
      ('MEMO:475:NANAMI', '모시카시테 나나미짱 미나캇타?', 1),
      ('MEMO:475:NANAMI', '마다 모돗테 나이', 2),
      ('MEMO:475:NANAMI', '도코 잇타노요', 3),
      ('MEMO:475:CHOICE', '소레 이가이노 모노와?', 1),
      ('MEMO:475:CHOICE', '고레니 시마쇼', 2),
      ('MEMO:475:OUTING', '카루쿠 고항 이키마센카?', 1),
      ('MEMO:475:OUTING', '도코니 이쿠?', 2),
      ('MEMO:475:OUTING', '소토 이끼마쇼카?', 3),
      ('MEMO:475:OUTING', '소토니 데요오', 4),
      ('MEMO:475:OUTING', '나나코짱모 이쿠?', 5),
      ('MEMO:475:OUTING', '아토데 아이마셍카', 6),
      ('MEMO:475:OUTING', '도코카 야스메루 토코로가 아루카나?', 7),
      ('MEMO:475:OUTING', '소레데 이키마쇼', 8),
      ('MEMO:1484:ENOUGH', '소레데 이이자 나이노카나', 1),
      ('MEMO:1484:ENOUGH', '소주토 삼겹사루노 아이쇼 밧치리데스', 2),
      ('MEMO:3813:QUESTION', '나니소레', 1),
      ('MEMO:3813:QUESTION', '와칸나이', 2)
  ), resolved as (
    select
      r.group_key,
      r.member_order,
      (
        select e.id
        from public.expression e
        where e.status = 'ACTIVE'
          and e.display_pronunciation = r.pronunciation
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
    'RELATED',
    2,
    r.member_order
  from resolved r
  join public.learning_association_group g on g.group_key = r.group_key
  where r.expression_id is not null
  on conflict (group_id, expression_id) do update
    set member_role = excluded.member_role,
        association_level = excluded.association_level,
        display_order = excluded.display_order;

  if (
    select count(*)
    from public.learning_association_member m
    join public.learning_association_group g on g.id = m.group_id
    where g.group_key in (
      'MEMO:475:TTOITTE', 'MEMO:475:DIFFERENCE', 'MEMO:475:NANAMI',
      'MEMO:475:CHOICE', 'MEMO:475:OUTING', 'MEMO:1484:ENOUGH',
      'MEMO:3813:QUESTION'
    )
  ) <> 21 then
    raise exception 'curated association override expected 21 members';
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

revoke all on function public.apply_curated_learning_association_overrides()
  from public, anon, authenticated;

create or replace function public.refresh_learning_association_groups()
returns table(group_count bigint, member_count bigint)
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  perform * from public.refresh_learning_association_groups_labeled_base();
  return query
  select o.active_group_count, o.active_member_count
  from public.apply_curated_learning_association_overrides() o;
end;
$$;

revoke all on function public.refresh_learning_association_groups()
  from public, anon, authenticated;

-- Keep high-confidence/curated groups first and make compact words and base
-- forms precede long example sentences in every group type.
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
  ), raw_candidates as (
    select
      i.expression_id as anchor_expression_id,
      g.id as group_id,
      g.label as group_label,
      g.group_type,
      g.display_order as group_display_order,
      m_anchor.association_level as anchor_level,
      m_target.expression_id as target_expression_id,
      em.meaning_text,
      e.display_pronunciation,
      m_target.member_role,
      m_target.association_level,
      m_target.display_order,
      row_number() over (
        partition by
          i.expression_id,
          g.id,
          regexp_replace(lower(e.display_pronunciation), '[^[:alnum:]가-힣ぁ-んァ-ヶ一-龠]', '', 'g'),
          regexp_replace(lower(em.meaning_text), '[^[:alnum:]가-힣ぁ-んァ-ヶ一-龠]', '', 'g')
        order by
          m_target.association_level,
          coalesce(m_target.display_order, 2147483647),
          m_target.expression_id
      ) as duplicate_order
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
  ), unique_candidates as (
    select *
    from raw_candidates
    where duplicate_order = 1
  ), ranked as (
    select
      u.*,
      count(*) over (
        partition by u.anchor_expression_id, u.group_id
      ) as group_member_count,
      row_number() over (
        partition by u.anchor_expression_id, u.group_id
        order by
          u.association_level,
          char_length(regexp_replace(u.display_pronunciation, '[[:space:]]', '', 'g')),
          (u.display_pronunciation ~ '[[:space:]]')::integer,
          coalesce(u.display_order, 2147483647),
          u.target_expression_id
      ) as result_order
    from unique_candidates u
  )
  select
    r.anchor_expression_id,
    r.group_id,
    r.group_label,
    r.group_type,
    r.group_member_count,
    r.target_expression_id,
    r.meaning_text,
    r.display_pronunciation,
    r.member_role,
    r.association_level,
    r.display_order
  from ranked r
  where r.result_order <= least(greatest(coalesce(p_limit_per_group, 24), 1), 50)
  order by
    r.anchor_expression_id,
    case r.group_type when 'SEMANTIC' then 1 when 'CATEGORY' then 2 else 3 end,
    r.anchor_level,
    r.group_display_order,
    r.group_member_count,
    r.group_label,
    r.result_order;
$$;

revoke all on function public.get_learning_associations(bigint[], integer)
  from public;
grant execute on function public.get_learning_associations(bigint[], integer)
  to anon, authenticated;

select * from public.apply_curated_learning_association_overrides();
