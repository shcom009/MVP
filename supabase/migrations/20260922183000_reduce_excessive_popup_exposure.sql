-- Remove one expression from two broad mixed-topic memo groups while keeping
-- its expression_source provenance and two genuinely related learning groups. Reapply the
-- override after every association refresh.

do $$
begin
  if to_regprocedure('public.refresh_learning_association_groups_popup_exposure_base()') is null then
    alter function public.refresh_learning_association_groups()
      rename to refresh_learning_association_groups_popup_exposure_base;
  end if;
end
$$;

revoke all on function public.refresh_learning_association_groups_popup_exposure_base()
  from public, anon, authenticated;

create or replace function public.apply_popup_exposure_overrides()
returns table(active_group_count bigint, active_member_count bigint)
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_count integer;
begin
  -- The expression remains in MEMO:1840 (growth forms) and MEMO:2024
  -- (erection-context forms). These two large mixed-topic memo groups create
  -- unrelated popup paths and are excluded from association display only.
  delete from public.learning_association_member m
  using public.learning_association_group g, public.expression e
  where m.group_id = g.id
    and e.id = m.expression_id
    and g.group_key in ('MEMO:1611', 'MEMO:2509')
    and regexp_replace(
          lower(e.display_pronunciation),
          '[^0-9a-z가-힣]+', '', 'g'
        ) = '오오키쿠낫타쟝';

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

create or replace function public.refresh_learning_association_groups()
returns table(group_count bigint, member_count bigint)
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  perform * from public.refresh_learning_association_groups_popup_exposure_base();
  return query
  select o.active_group_count, o.active_member_count
  from public.apply_popup_exposure_overrides() o;
end;
$$;

revoke all on function public.refresh_learning_association_groups()
  from public, anon, authenticated;

select * from public.apply_popup_exposure_overrides();
