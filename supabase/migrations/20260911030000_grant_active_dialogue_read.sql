alter table public.dialogue enable row level security;
alter table public.dialogue_line enable row level security;

grant select on table public.dialogue to anon, authenticated;
grant select on table public.dialogue_line to anon, authenticated;

drop policy if exists "app_read_active_dialogue" on public.dialogue;
create policy "app_read_active_dialogue"
on public.dialogue
for select
to anon, authenticated
using (status = 'ACTIVE');

drop policy if exists "app_read_active_dialogue_line" on public.dialogue_line;
create policy "app_read_active_dialogue_line"
on public.dialogue_line
for select
to anon, authenticated
using (
  dialogue_id in (
    select id
    from public.dialogue
    where status = 'ACTIVE'
  )
);
