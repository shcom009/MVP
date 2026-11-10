create or replace function public.search_learning_notes(
  p_query text,
  p_limit integer default 30
)
returns table (
  id bigint,
  title text,
  summary text,
  topic text,
  source_order integer,
  content_text text
)
language sql
stable
security invoker
set search_path = public
as $$
  with input as (
    select trim(coalesce(p_query, '')) as q,
           greatest(1, least(coalesce(p_limit, 30), 100)) as row_limit
  )
  select n.id, n.title, n.summary, n.topic, n.source_order, n.content_text
  from public.learning_note n
  cross join input i
  where n.status = 'ACTIVE'
    and (
      i.q = ''
      or n.title ilike '%' || i.q || '%'
      or coalesce(n.summary, '') ilike '%' || i.q || '%'
      or n.content_text ilike '%' || i.q || '%'
      or exists (
        select 1
        from public.learning_note_expression lne
        join public.expression e
          on e.id = lne.expression_id
         and e.status = 'ACTIVE'
        left join public.expression_meaning em
          on em.expression_id = e.id
        where lne.learning_note_id = n.id
          and (
            coalesce(e.japanese_original, '') ilike '%' || i.q || '%'
            or e.display_pronunciation ilike '%' || i.q || '%'
            or coalesce(em.meaning_text, '') ilike '%' || i.q || '%'
          )
      )
    )
  order by
    case when i.q <> '' and n.title ilike '%' || i.q || '%' then 0 else 1 end,
    n.source_order,
    n.id
  limit (select row_limit from input);
$$;

revoke all on function public.search_learning_notes(text, integer) from public;
grant execute on function public.search_learning_notes(text, integer) to anon, authenticated;
