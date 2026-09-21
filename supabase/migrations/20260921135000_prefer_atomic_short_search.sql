-- When a one- or two-syllable exact card exists, keep the result list compact.
-- Broader phrases remain available through learning-association popovers.

create or replace function public.search_expressions(p_query text, p_limit integer default 20)
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
set search_path = public, pg_temp
as $$
with q0 as (
  select regexp_replace(
           regexp_replace(lower(btrim(coalesce(p_query, ''))), '[↗↘~]', '', 'g'),
           '\s+', ' ', 'g'
         ) as q
), q as (
  select regexp_replace(q0.q, '[?？!！。．.]+$', '', 'g') as q
  from q0
), ranked as (
  select
    e.id as expression_id,
    em.meaning_text,
    e.display_pronunciation,
    q.q,
    (lower(em.meaning_norm) = q.q) as meaning_exact,
    (strpos(lower(em.meaning_norm), q.q) > 0) as meaning_partial,
    similarity(lower(em.meaning_norm), q.q) as meaning_sim,
    coalesce(a.alias_exact, false) as alias_exact,
    coalesce(a.alias_partial, false) as alias_partial,
    coalesce(a.alias_sim, 0::real) as alias_sim
  from public.expression e
  join public.expression_meaning em
    on em.expression_id = e.id and em.is_primary = true
  cross join q
  left join lateral (
    select
      bool_or(lower(sa.alias_norm) = q.q) as alias_exact,
      bool_or(strpos(lower(sa.alias_norm), q.q) > 0) as alias_partial,
      max(similarity(lower(sa.alias_norm), q.q)) as alias_sim
    from public.search_alias sa
    where sa.expression_id = e.id
  ) a on true
  where e.status = 'ACTIVE'
    and q.q <> ''
), scored as (
  select
    expression_id,
    meaning_text,
    display_pronunciation,
    case
      when meaning_exact then 'MEANING_EXACT'
      when alias_exact then 'PRON_EXACT'
      when meaning_partial then 'MEANING_PARTIAL'
      when alias_partial then 'PRON_PARTIAL'
      else 'FUZZY'
    end as match_type,
    case
      when meaning_exact then 1.00::real
      when alias_exact then 0.99::real
      when meaning_partial then 0.90::real
      when alias_partial then 0.88::real
      else (greatest(meaning_sim, alias_sim) * 0.75)::real
    end as score,
    greatest(meaning_sim, alias_sim) as raw_similarity,
    char_length(q) as q_len,
    bool_or(meaning_exact or alias_exact) over () as has_exact
  from ranked
)
select
  expression_id,
  meaning_text,
  display_pronunciation,
  match_type,
  score
from scored
where (
    not (has_exact and q_len <= 2 and match_type in ('MEANING_PARTIAL', 'PRON_PARTIAL'))
  )
  and (
    match_type <> 'FUZZY'
    or raw_similarity >= case
         when q_len <= 2 then 0.35
         when q_len <= 4 then 0.30
         else 0.20
       end
  )
order by score desc, char_length(meaning_text), expression_id
limit least(greatest(coalesce(p_limit, 20), 1), 50);
$$;

revoke all on function public.search_expressions(text, integer) from public;
grant execute on function public.search_expressions(text, integer) to anon, authenticated;
