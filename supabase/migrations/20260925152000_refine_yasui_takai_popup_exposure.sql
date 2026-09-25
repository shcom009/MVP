-- Keep source provenance while excluding seven verified broad memo memberships
-- that mix the yasui/takai pilot senses in list association popovers.

create or replace function public.apply_popup_exposure_overrides()
returns table(active_group_count bigint, active_member_count bigint)
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_count integer;
begin
  -- Existing reviewed override: keep the focused growth/erection groups only.
  delete from public.learning_association_member m
  using public.learning_association_group g, public.expression e
  where m.group_id = g.id
    and e.id = m.expression_id
    and g.group_key in ('MEMO:1611', 'MEMO:2509')
    and regexp_replace(
          lower(e.display_pronunciation),
          '[^0-9a-z가-힣]+', '', 'g'
        ) = '오오키쿠낫타쟝';

  -- Yasui/takai pilot: remove only the broad memo memberships that cross
  -- confirmed sense boundaries. expression_source provenance is untouched.
  delete from public.learning_association_member m
  using public.learning_association_group g
  where m.group_id = g.id
    and (
      (g.group_key = 'MEMO:81' and m.expression_id = 7030)
      or (g.group_key = 'MEMO:289' and m.expression_id in (1580, 1582, 1583, 1584))
      or (g.group_key in ('MEMO:226', 'MEMO:2832') and m.expression_id = 6159)
    );

  select count(*) into v_count
  from public.learning_association_member m
  join public.learning_association_group g on g.id = m.group_id
  join public.expression e on e.id = m.expression_id
  where g.group_key in ('MEMO:1611', 'MEMO:2509')
    and regexp_replace(
          lower(e.display_pronunciation),
          '[^0-9a-z가-힣]+', '', 'g'
        ) = '오오키쿠낫타쟝';
  if v_count <> 0 then
    raise exception 'broad popup memberships expected 0, got %', v_count;
  end if;

  select count(*) into v_count
  from public.learning_association_member m
  join public.learning_association_group g on g.id = m.group_id
  join public.expression e on e.id = m.expression_id
  where g.group_key in ('MEMO:1840', 'MEMO:2024')
    and regexp_replace(
          lower(e.display_pronunciation),
          '[^0-9a-z가-힣]+', '', 'g'
        ) = '오오키쿠낫타쟝';
  if v_count <> 2 then
    raise exception 'focused popup memberships expected 2, got %', v_count;
  end if;

  select count(*) into v_count
  from public.learning_association_member m
  join public.learning_association_group g on g.id = m.group_id
  where (g.group_key = 'MEMO:81' and m.expression_id = 7030)
     or (g.group_key = 'MEMO:289' and m.expression_id in (1580, 1582, 1583, 1584))
     or (g.group_key in ('MEMO:226', 'MEMO:2832') and m.expression_id = 6159);
  if v_count <> 0 then
    raise exception 'yasui/takai broad popup memberships expected 0, got %', v_count;
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

revoke all on function public.apply_popup_exposure_overrides()
  from public, anon, authenticated;

select * from public.apply_popup_exposure_overrides();

