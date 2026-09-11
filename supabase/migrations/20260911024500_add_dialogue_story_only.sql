alter table public.dialogue
  add column if not exists story_only boolean not null default false;

comment on column public.dialogue.story_only is
  'When true, expose only as a complete Story and never through expression search links.';
