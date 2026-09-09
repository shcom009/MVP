grant select (id, expression_id, note_type, note_text, display_order)
on table public.note to anon;

drop policy if exists "anon_read_active_expression_notes" on public.note;

create policy "anon_read_active_expression_notes"
on public.note
for select
to anon
using (
  expression_id is not null
  and note_type in ('EXAMPLE', 'HINT', 'REFERENCE')
  and exists (
    select 1
    from public.expression e
    where e.id = note.expression_id
      and e.status = 'ACTIVE'
  )
);

notify pgrst, 'reload schema';
