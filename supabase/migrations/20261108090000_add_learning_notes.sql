create table if not exists public.learning_note (
  id bigint generated always as identity primary key,
  source_memo_id bigint not null references public.source_memo(id) on delete restrict,
  source_key text not null unique,
  title text not null,
  summary text,
  content_text text not null,
  topic text,
  source_order integer not null,
  status text not null default 'ACTIVE'
    check (status in ('ACTIVE', 'HOLD', 'EXCLUDED')),
  content_sha256 text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.learning_note_expression (
  learning_note_id bigint not null references public.learning_note(id) on delete cascade,
  expression_id bigint not null references public.expression(id) on delete cascade,
  relation_type text not null default 'RELATED'
    check (relation_type in ('CORE', 'COMPARE', 'EXAMPLE', 'RELATED')),
  anchor_text text,
  display_order integer,
  created_at timestamptz not null default now(),
  primary key (learning_note_id, expression_id)
);

create index if not exists learning_note_status_order_idx
  on public.learning_note(status, source_order, id);

create index if not exists learning_note_expression_expression_idx
  on public.learning_note_expression(expression_id, display_order, learning_note_id);

alter table public.learning_note enable row level security;
alter table public.learning_note_expression enable row level security;

grant select on table public.learning_note to anon, authenticated;
grant select on table public.learning_note_expression to anon, authenticated;

drop policy if exists app_read_active_learning_note on public.learning_note;
create policy app_read_active_learning_note
on public.learning_note
for select
to anon, authenticated
using (status = 'ACTIVE');

drop policy if exists app_read_active_learning_note_expression on public.learning_note_expression;
create policy app_read_active_learning_note_expression
on public.learning_note_expression
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.learning_note n
    where n.id = learning_note_id
      and n.status = 'ACTIVE'
  )
  and exists (
    select 1
    from public.expression e
    where e.id = expression_id
      and e.status = 'ACTIVE'
  )
);

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
    )
  order by
    case when i.q <> '' and n.title ilike '%' || i.q || '%' then 0 else 1 end,
    n.source_order,
    n.id
  limit (select row_limit from input);
$$;

revoke all on function public.search_learning_notes(text, integer) from public;
grant execute on function public.search_learning_notes(text, integer) to anon, authenticated;

comment on table public.learning_note is
  'Long-form explanations and multi-example learning notes preserved from study chats.';

comment on table public.learning_note_expression is
  'Links long-form learning notes to searchable expressions without expanding short note popovers.';
