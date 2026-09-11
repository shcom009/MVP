alter table public.dialogue
  add column if not exists story_order smallint,
  add column if not exists story_text text,
  add column if not exists content_sha256 text,
  add column if not exists content_source text;

comment on column public.dialogue.story_order is
  'Display order for a complete Story collection.';

comment on column public.dialogue.story_text is
  'Complete Story text independent of source_memo.';

comment on column public.dialogue.content_sha256 is
  'SHA-256 of story_text calculated before ingestion.';

comment on column public.dialogue.content_source is
  'Import batch identifier; not a source_memo relationship.';
