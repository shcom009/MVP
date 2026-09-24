-- Pending reproducible DB change. Supabase CLI is unavailable in this workspace,
-- so this file is applied directly and should later be imported into migration history.

select pg_advisory_xact_lock(hashtext('kimtokki_source_complete_search'));

-- HOLD no longer blocks useful source expressions. Verification status remains intact.
update public.expression
set status = 'ACTIVE', updated_at = now()
where status = 'HOLD';

-- Restore the source-explicit skin atoms that were skipped inside memo 2398508.
create temporary table _kimtokki_skin_seed (
  seed_order integer primary key,
  seed_key text not null unique,
  source_memo_id bigint not null,
  display_pronunciation text not null,
  japanese_original text,
  meaning_text text not null,
  source_excerpt text not null
) on commit drop;

insert into _kimtokki_skin_seed values
  (1,'HADA',3709,'하다','肌','피부·살갗','하다, (일상적으로 말하는) 피부'),
  (2,'HADA_KIREI',3709,'하다가 키레이다네','肌がきれいだね','피부가 예쁘네','하다가 키레이다네 - 피부가 예쁘네'),
  (3,'HADA_YOWAI',3709,'하다가 요와이','肌が弱い','피부가 약하다','하다가 요와이 - 피부가 약하다'),
  (4,'MOCHIHADA',3709,'모치하다','もち肌','탱글하고 촉촉한 피부','모치하다 - 탱글하고 촉촉한 피부'),
  (5,'BIHADA',3709,'비하다','美肌','고운 피부·미백 피부','비하다 - 고운 피부, 미백 피부'),
  (6,'HIHU',3709,'히후','皮膚','피부(의학·해부학)','히후, 의학적·해부학적 표현'),
  (7,'HIHUKA',3709,'히후카','皮膚科','피부과','히후카 - 피부과'),
  (8,'HIHUEN',3709,'히후엔','皮膚炎','피부염','히후엔 - 피부염');

insert into public.candidate_unit (
  source_memo_id, legacy_candidate_key, korean_meaning, display_pronunciation,
  japanese_original, recovery_method, verification_status, source_record_ref,
  source_excerpt, source_folder_snapshot, source_file_snapshot
)
select s.source_memo_id, 'SOURCE_ATOMIC:'||s.source_memo_id||':'||s.seed_key,
       s.meaning_text, s.display_pronunciation, s.japanese_original,
       'SOURCE_ATOMIC_SPLIT', 'VERIFIED', 'memoSeq:'||sm.memo_seq,
       s.source_excerpt, sm.legacy_folder_id, 'source_memo:'||sm.id
from _kimtokki_skin_seed s
join public.source_memo sm on sm.id=s.source_memo_id
where not exists (
  select 1 from public.candidate_unit cu
  where cu.legacy_candidate_key='SOURCE_ATOMIC:'||s.source_memo_id||':'||s.seed_key
);

insert into public.expression (
  display_pronunciation,japanese_original,status,verification_status,
  speaking_enabled,listening_enabled,edge_flag,created_at,updated_at
)
select s.display_pronunciation,s.japanese_original,'ACTIVE','VERIFIED',true,true,false,now(),now()
from _kimtokki_skin_seed s
where not exists (
  select 1 from public.expression e
  join public.expression_meaning em on em.expression_id=e.id and em.is_primary
  where e.status <> 'EXCLUDED'
    and regexp_replace(lower(e.display_pronunciation),'[^0-9a-z가-힣]+','','g')=
        regexp_replace(lower(s.display_pronunciation),'[^0-9a-z가-힣]+','','g')
    and regexp_replace(lower(em.meaning_text),'[^0-9a-z가-힣]+','','g')=
        regexp_replace(lower(s.meaning_text),'[^0-9a-z가-힣]+','','g')
);

with resolved as (
  select distinct on (s.seed_key) s.*,e.id expression_id
  from _kimtokki_skin_seed s
  join public.expression e
    on e.status='ACTIVE'
   and regexp_replace(lower(e.display_pronunciation),'[^0-9a-z가-힣]+','','g')=
       regexp_replace(lower(s.display_pronunciation),'[^0-9a-z가-힣]+','','g')
  order by s.seed_key,
           case when e.japanese_original is not distinct from s.japanese_original then 0 else 1 end,
           e.id
)
insert into public.expression_meaning
  (expression_id,meaning_text,meaning_norm,meaning_order,is_primary,usage_note,created_at)
select r.expression_id,r.meaning_text,lower(btrim(r.meaning_text)),1,true,null,now()
from resolved r
where not exists (
  select 1 from public.expression_meaning em
  where em.expression_id=r.expression_id and em.is_primary
);

with resolved as (
  select distinct on (s.seed_key) s.*,e.id expression_id
  from _kimtokki_skin_seed s
  join public.expression e
    on e.status='ACTIVE'
   and regexp_replace(lower(e.display_pronunciation),'[^0-9a-z가-힣]+','','g')=
       regexp_replace(lower(s.display_pronunciation),'[^0-9a-z가-힣]+','','g')
  order by s.seed_key,
           case when e.japanese_original is not distinct from s.japanese_original then 0 else 1 end,
           e.id
)
insert into public.search_alias
  (expression_id,alias_text,alias_norm,alias_type,origin,created_at)
select r.expression_id,r.display_pronunciation,lower(btrim(r.display_pronunciation)),
       'NORMALIZED','SOURCE',now()
from resolved r
on conflict (expression_id,alias_type,alias_norm) do nothing;

with resolved as (
  select distinct on (s.seed_key) s.*,e.id expression_id,cu.id candidate_unit_id
  from _kimtokki_skin_seed s
  join public.expression e
    on e.status='ACTIVE'
   and regexp_replace(lower(e.display_pronunciation),'[^0-9a-z가-힣]+','','g')=
       regexp_replace(lower(s.display_pronunciation),'[^0-9a-z가-힣]+','','g')
  join public.candidate_unit cu
    on cu.legacy_candidate_key='SOURCE_ATOMIC:'||s.source_memo_id||':'||s.seed_key
  order by s.seed_key,
           case when e.japanese_original is not distinct from s.japanese_original then 0 else 1 end,
           e.id
)
insert into public.expression_source (expression_id,candidate_unit_id,created_at)
select expression_id,candidate_unit_id,now() from resolved
on conflict (candidate_unit_id) do nothing;

-- Explicit concept group: everyday 肌 and medical 皮膚 stay distinct but navigable.
insert into public.learning_association_group
  (group_key,label,group_type,status,display_order)
values ('SEMANTIC:SKIN_TERMS','피부 표현','SEMANTIC','ACTIVE',35)
on conflict (group_key) do update
set label=excluded.label,status=excluded.status,display_order=excluded.display_order,updated_at=now();

with members as (
  select distinct e.id expression_id,
    row_number() over (order by
      case regexp_replace(lower(e.display_pronunciation),'[^0-9a-z가-힣]+','','g')
        when '하다' then 1 when '히후' then 2 when '스하다' then 3 else 10 end,
      e.id)::integer display_order
  from public.expression e
  join public.expression_meaning em on em.expression_id=e.id and em.is_primary
  where e.status='ACTIVE'
    and (
      regexp_replace(lower(e.display_pronunciation),'[^0-9a-z가-힣]+','','g')
        in ('하다','히후','히후카','히후엔','스하다','모치하다','비하다','하다가키레이다네','하다가요와이','하다니아와나이','하다가스베스베다나','하다데칸지루','하다오요세아이')
      or em.meaning_text in ('피부·살갗','피부(의학·해부학)','피부과','피부염')
    )
)
insert into public.learning_association_member
  (group_id,expression_id,member_role,association_level,display_order)
select g.id,m.expression_id,
       case when m.display_order<=2 then 'CORE' else 'RELATED' end,
       case when m.display_order<=2 then 1 else 2 end,
       m.display_order
from members m
join public.learning_association_group g on g.group_key='SEMANTIC:SKIN_TERMS'
on conflict (group_id,expression_id) do update
set member_role=excluded.member_role,
    association_level=excluded.association_level,
    display_order=excluded.display_order;

-- Controlled source fallback. It returns only a short excerpt, requires two
-- normalized characters, excludes edge-story memos, and caps every request.
create or replace function public.search_source_memos(p_query text,p_limit integer default 8)
returns table(
  source_memo_id bigint,
  source_excerpt text,
  linked_expression_ids bigint[],
  match_type text,
  score real
)
language sql
stable
security definer
set search_path=''
as $$
with q as (
  select lower(btrim(coalesce(p_query,''))) query_text,
         regexp_replace(lower(btrim(coalesce(p_query,''))),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g') query_norm
), matched as (
  select sm.id,
         regexp_replace(sm.original_text,'[[:space:]]+',' ','g') clean_text,
         strpos(lower(regexp_replace(sm.original_text,'[[:space:]]+',' ','g')),q.query_text) hit_pos,
         q.query_text,q.query_norm
  from public.source_memo sm
  cross join q
  where char_length(q.query_norm)>=2
    and strpos(lower(sm.original_text),q.query_text)>0
    and sm.original_text !~* '(^|[[:space:]])#?[[:space:]]*엣지([[:space:]]|$)'
), ranked as (
  select m.*,
         row_number() over(order by
           case when m.clean_text ilike m.query_text||'%' then 0 else 1 end,
           char_length(m.clean_text),m.id) result_order
  from matched m
)
select r.id,
       btrim(substring(r.clean_text from greatest(r.hit_pos-70,1) for 300)),
       coalesce((
         select array_agg(distinct e.id order by e.id)
         from public.candidate_unit cu
         join public.expression_source es on es.candidate_unit_id=cu.id
         join public.expression e on e.id=es.expression_id and e.status='ACTIVE'
         where cu.source_memo_id=r.id
       ),array[]::bigint[]),
       'SOURCE_MEMO'::text,
       0.70::real
from ranked r
where r.result_order<=least(greatest(coalesce(p_limit,8),1),12)
order by r.result_order;
$$;

revoke all on function public.search_source_memos(text,integer) from public;
grant execute on function public.search_source_memos(text,integer) to anon,authenticated;

-- Expanded list search for the learning app. The legacy compact function stays
-- unchanged for established regression contracts, while this function keeps
-- meaningful partial matches visible after an exact short match is found.
create or replace function public.search_expressions_expanded(p_query text,p_limit integer default 50)
returns table(
  expression_id bigint,
  meaning_text text,
  display_pronunciation text,
  match_type text,
  score real
)
language sql
stable
security invoker
set search_path=public,pg_temp
as $$
with q0 as (
  select regexp_replace(
           regexp_replace(lower(btrim(coalesce(p_query,''))),'[↗↘~]','','g'),
           '\s+',' ','g'
         ) q
), q as (
  select regexp_replace(q0.q,'[?？!！。．.]+$','','g') q from q0
), ranked as (
  select e.id expression_id,em.meaning_text,e.display_pronunciation,q.q,
         (lower(em.meaning_norm)=q.q) meaning_exact,
         (strpos(lower(em.meaning_norm),q.q)>0) meaning_partial,
         similarity(lower(em.meaning_norm),q.q) meaning_sim,
         coalesce(a.alias_exact,false) alias_exact,
         coalesce(a.alias_partial,false) alias_partial,
         coalesce(a.alias_sim,0::real) alias_sim
  from public.expression e
  join public.expression_meaning em on em.expression_id=e.id and em.is_primary
  cross join q
  left join lateral (
    select bool_or(lower(sa.alias_norm)=q.q) alias_exact,
           bool_or(strpos(lower(sa.alias_norm),q.q)>0) alias_partial,
           max(similarity(lower(sa.alias_norm),q.q)) alias_sim
    from public.search_alias sa where sa.expression_id=e.id
  ) a on true
  where e.status='ACTIVE' and q.q<>''
), scored as (
  select expression_id,meaning_text,display_pronunciation,
         case when meaning_exact then 'MEANING_EXACT'
              when alias_exact then 'PRON_EXACT'
              when meaning_partial then 'MEANING_PARTIAL'
              when alias_partial then 'PRON_PARTIAL'
              else 'FUZZY' end match_type,
         case when meaning_exact then 1.00::real
              when alias_exact then 0.99::real
              when meaning_partial then 0.90::real
              when alias_partial then 0.88::real
              else greatest(meaning_sim,alias_sim)*0.75 end score,
         greatest(meaning_sim,alias_sim) raw_similarity,
         char_length(q) q_len,
         regexp_replace(q,'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g') query_norm
  from ranked
)
select expression_id,meaning_text,display_pronunciation,match_type,score
from scored
where not (
        q_len<=2
        and query_norm in ('하다','있다','없다','되다','가다','오다')
        and match_type='MEANING_PARTIAL'
      )
  and (
    match_type<>'FUZZY'
    or raw_similarity>=case when q_len<=2 then 0.35 when q_len<=4 then 0.30 else 0.20 end
  )
order by score desc,char_length(meaning_text),expression_id
limit least(greatest(coalesce(p_limit,50),1),100);
$$;

revoke all on function public.search_expressions_expanded(text,integer) from public;
grant execute on function public.search_expressions_expanded(text,integer) to anon,authenticated;

-- Keep curated relationships and add low-cost dynamic expansion for source,
-- pronunciation, and meaning. No persistent bulk relation rows are generated.
do $$
begin
  if to_regprocedure('public.get_learning_associations_curated(bigint[],integer)') is null then
    alter function public.get_learning_associations(bigint[],integer)
      rename to get_learning_associations_curated;
  end if;
end $$;

revoke all on function public.get_learning_associations_curated(bigint[],integer) from public;

create or replace function public.get_learning_associations(
  p_expression_ids bigint[],p_limit_per_group integer default 24
)
returns table(
  anchor_expression_id bigint,group_id bigint,group_label text,group_type text,
  group_member_count bigint,target_expression_id bigint,meaning_text text,
  display_pronunciation text,member_role text,association_level smallint,display_order integer
)
language sql
stable
security invoker
set search_path=public,pg_temp
as $$
with curated as materialized (
  select * from public.get_learning_associations_curated(p_expression_ids,p_limit_per_group)
), input_ids as (
  select distinct x expression_id
  from unnest(coalesce(p_expression_ids,array[]::bigint[])) x
  where x is not null
), anchors as (
  select e.id,em.meaning_text,em.meaning_norm,e.display_pronunciation,
         regexp_replace(lower(e.display_pronunciation),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g') pron_norm
  from input_ids i
  join public.expression e on e.id=i.expression_id and e.status='ACTIVE'
  join public.expression_meaning em on em.expression_id=e.id and em.is_primary
), pronunciation_candidates as (
  select a.id anchor_expression_id,e.id target_expression_id,
         em.meaning_text,e.display_pronunciation,2 priority
  from anchors a
  cross join lateral (
    select e2.id,e2.display_pronunciation
    from public.expression e2
    where e2.status='ACTIVE' and e2.id<>a.id and char_length(a.pron_norm)>=2
      and similarity(
        regexp_replace(lower(e2.display_pronunciation),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g'),
        a.pron_norm
      )>=0.48
    order by similarity(
      regexp_replace(lower(e2.display_pronunciation),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g'),
      a.pron_norm
    ) desc,char_length(e2.display_pronunciation),e2.id
    limit 10
  ) e
  join public.expression_meaning em on em.expression_id=e.id and em.is_primary
), meaning_candidates as (
  select a.id anchor_expression_id,e.id target_expression_id,
         em.meaning_text,e.display_pronunciation,3 priority
  from anchors a
  cross join lateral (
    select e2.id,e2.display_pronunciation,em2.meaning_text,em2.meaning_norm
    from public.expression e2
    join public.expression_meaning em2 on em2.expression_id=e2.id and em2.is_primary
    where e2.status='ACTIVE' and e2.id<>a.id and char_length(a.meaning_norm)>=2
      and similarity(em2.meaning_norm,a.meaning_norm)>=0.52
    order by similarity(em2.meaning_norm,a.meaning_norm) desc,
             char_length(em2.meaning_text),e2.id
    limit 10
  ) e
  join public.expression_meaning em on em.expression_id=e.id and em.is_primary
), dynamic_raw as (
  select * from pronunciation_candidates
  union all select * from meaning_candidates
), dynamic_unique as (
  select d.*,
         row_number() over(partition by d.anchor_expression_id,d.target_expression_id order by d.priority) target_order
  from dynamic_raw d
  where not exists (
    select 1 from curated c
    where c.anchor_expression_id=d.anchor_expression_id
      and c.target_expression_id=d.target_expression_id
  )
), dynamic_ranked as (
  select d.*,
         count(*) over(partition by d.anchor_expression_id,d.priority) member_count,
         row_number() over(partition by d.anchor_expression_id,d.priority
           order by char_length(d.display_pronunciation),d.target_expression_id) result_order
  from dynamic_unique d
  where d.target_order=1
), dynamic_rows as (
  select d.anchor_expression_id,
         -(d.priority::bigint*1000000000+d.anchor_expression_id) group_id,
         case d.priority when 2 then '비슷한 발음' else '비슷한 뜻' end group_label,
         case d.priority when 2 then 'PRONUNCIATION' else 'SEMANTIC_AUTO' end group_type,
         d.member_count group_member_count,d.target_expression_id,d.meaning_text,d.display_pronunciation,
         'RELATED'::text,3::smallint,d.result_order::integer
  from dynamic_ranked d
  where d.result_order<=least(greatest(coalesce(p_limit_per_group,24),1),10)
)
select u.*
from (
  select * from curated
  union all
  select * from dynamic_rows
) u
order by u.anchor_expression_id,
  case u.group_type when 'SEMANTIC' then 1 when 'PRONUNCIATION' then 2 when 'SEMANTIC_AUTO' then 3 when 'CATEGORY' then 4 else 5 end,
  u.group_id,u.display_order;
$$;

revoke all on function public.get_learning_associations(bigint[],integer) from public;
grant execute on function public.get_learning_associations(bigint[],integer) to anon,authenticated;
