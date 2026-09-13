-- OWNER APPROVAL REQUIRED. DESTRUCTIVE to Study history; never run automatically.
-- Stop Study writes/retries on clients first; export/back up study_sessions.
-- Confirm no downstream dependencies. Intentionally no CASCADE.
begin;
drop table public.study_sessions;
drop function public.study_active_milliseconds(jsonb, numeric);
notify pgrst, 'reload schema';
commit;
-- No auth users, profiles, existing policies, migrations or Day 7 data touched.
