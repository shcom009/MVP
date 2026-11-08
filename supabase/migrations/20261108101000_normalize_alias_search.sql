create or replace function public.search_expressions_expanded(
  p_query text,
  p_limit integer default 50
)
returns table (
  expression_id bigint,
  meaning_text text,
  display_pronunciation text,
  match_type text,
  score real
)
language sql
stable
set search_path to 'public', 'pg_temp'
as $$
with q0 as (
  select regexp_replace(
           regexp_replace(lower(btrim(coalesce(p_query,''))),'[↗↘~]','','g'),
           '\s+',' ','g'
         ) q
), q1 as (
  select regexp_replace(q0.q,'[?？!！。．.]+$','','g') q from q0
), q as (
  select q1.q,
         regexp_replace(q1.q,'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g') q_compact
  from q1
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
    select
      bool_or(
        lower(sa.alias_norm)=q.q
        or regexp_replace(lower(sa.alias_norm),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g')=q.q_compact
      ) alias_exact,
      bool_or(
        strpos(lower(sa.alias_norm),q.q)>0
        or strpos(
          regexp_replace(lower(sa.alias_norm),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g'),
          q.q_compact
        )>0
      ) alias_partial,
      max(greatest(
        similarity(lower(sa.alias_norm),q.q),
        similarity(
          regexp_replace(lower(sa.alias_norm),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g'),
          q.q_compact
        )
      )) alias_sim
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
