-- Align study-chat aliases with search_expressions() query normalization.

select pg_advisory_xact_lock(hashtext('kimtokki_study_chat_alias_fix_v1'));

with target_expression as (
  select distinct es.expression_id
  from public.expression_source es
  join public.candidate_unit cu on cu.id=es.candidate_unit_id
  where cu.source_folder_snapshot='김토끼니혼고/일어수집'
    and cu.legacy_candidate_key like 'CHAT-%'
)
update public.search_alias sa
set alias_norm=regexp_replace(
                 regexp_replace(
                   regexp_replace(lower(btrim(sa.alias_text)), '[↗↘~]', '', 'g'),
                   '\s+', ' ', 'g'
                 ),
                 '[?？!！。．.]+$', '', 'g'
               )
from target_expression te
where te.expression_id=sa.expression_id
  and sa.origin='SOURCE';

insert into public.search_alias
  (expression_id, alias_text, alias_norm, alias_type, origin, created_at)
select es.expression_id, '쿠치쿠세', '쿠치쿠세', 'SOURCE_VARIANT', 'SOURCE', now()
from public.candidate_unit cu
join public.expression_source es on es.candidate_unit_id=cu.id
where cu.legacy_candidate_key='CHAT-20260919-151055-KUCHIGUSE'
  and not exists (
    select 1 from public.search_alias sa
    where sa.expression_id=es.expression_id and sa.alias_norm='쿠치쿠세'
  );

do $$
begin
  if not exists (
    select 1 from public.search_expressions('쿠치쿠세', 5)
    where display_pronunciation='쿠치구세' and match_type='PRON_EXACT'
  ) then raise exception '쿠치쿠세 source alias is not searchable'; end if;

  if not exists (
    select 1 from public.search_expressions('잇테 쿠레테 이이', 5)
    where display_pronunciation='코코니 이테 이이' and match_type='PRON_EXACT'
  ) then raise exception '잇테 쿠레테 이이 correction alias is not searchable'; end if;
end $$;
