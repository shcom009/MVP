-- General search/read-policy changes only. Chat source text is never stored here.
-- Existing active-expression RLS policy restricts alias rows to public expressions.
grant select on public.search_alias to anon, authenticated;
revoke insert, update, delete, truncate, references, trigger
  on public.learning_note, public.learning_note_expression
  from public, anon, authenticated;

create or replace function public.search_learning_notes(p_query text, p_limit integer default 30)
returns table(id bigint,title text,summary text,topic text,source_order integer,content_text text)
language sql stable security invoker set search_path = public, pg_temp
as $$
with input as (
 select btrim(coalesce(p_query,'')) q,
 regexp_replace(lower(coalesce(p_query,'')),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g') compact,
 greatest(1,least(coalesce(p_limit,30),100)) row_limit
), scored as (
 select n.*,i.compact,
 case when i.compact<>'' and regexp_replace(lower(n.title),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g')=i.compact then 0
 when i.compact<>'' and strpos(regexp_replace(lower(n.title),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g'),i.compact)>0 then 1
 when exists (
  select 1 from public.learning_note_expression l
  join public.expression e on e.id=l.expression_id and e.status='ACTIVE'
  left join public.expression_meaning em on em.expression_id=e.id
  where l.learning_note_id=n.id and (
   regexp_replace(lower(e.display_pronunciation),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g')=i.compact
   or regexp_replace(lower(coalesce(e.japanese_original,'')),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g')=i.compact
   or regexp_replace(lower(em.meaning_text),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g')=i.compact
   or exists(select 1 from public.search_alias sa where sa.expression_id=e.id and regexp_replace(lower(sa.alias_norm),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g')=i.compact)
  )
 ) then 2 else 3 end match_rank
 from public.learning_note n cross join input i
 where n.status='ACTIVE' and (
  i.q='' or (i.compact<>'' and (
   strpos(regexp_replace(lower(n.title||' '||coalesce(n.summary,'')||' '||coalesce(n.topic,'')||' '||n.content_text),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g'),i.compact)>0
   or exists(
    select 1 from public.learning_note_expression l
    join public.expression e on e.id=l.expression_id and e.status='ACTIVE'
    left join public.expression_meaning em on em.expression_id=e.id
    where l.learning_note_id=n.id and (
     strpos(regexp_replace(lower(coalesce(e.japanese_original,'')||' '||e.display_pronunciation||' '||coalesce(em.meaning_text,'')),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g'),i.compact)>0
     or exists(select 1 from public.search_alias sa where sa.expression_id=e.id and strpos(regexp_replace(lower(sa.alias_norm),'[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]','','g'),i.compact)>0)
    )
   )
  ))
 )
)
select s.id,s.title,s.summary,s.topic,s.source_order,s.content_text
from scored s order by s.match_rank,s.source_order,s.id limit(select row_limit from input);
$$;
revoke all on function public.search_learning_notes(text,integer) from public;
grant execute on function public.search_learning_notes(text,integer) to anon,authenticated;
