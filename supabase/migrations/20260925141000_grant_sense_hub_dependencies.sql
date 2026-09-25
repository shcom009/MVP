-- search_expression_sense_hub is SECURITY INVOKER. Its public callers need table grants;
-- existing RLS policies continue to expose only ACTIVE expressions and their meanings.
grant select on public.expression,public.expression_meaning to anon,authenticated;
