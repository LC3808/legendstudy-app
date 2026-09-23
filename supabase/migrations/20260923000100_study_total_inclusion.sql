-- Owner application required. Legacy sessions retain the existing included total.
-- No new table, UPDATE permission, public reads, or scoring contract change.
begin;
alter table public.study_sessions
  add column include_in_study_total boolean not null default true;
alter table public.study_sessions add constraint study_sessions_timer_included
  check (mode = 'mock_exam' or include_in_study_total);
grant insert (include_in_study_total) on public.study_sessions to authenticated;
notify pgrst, 'reload schema';
commit;
-- Rollback only after reverting clients and assessing excluded rows:
-- ALTER TABLE public.study_sessions DROP COLUMN include_in_study_total;
-- This loses inclusion choices, never raw durations/attempts. Do not run automatically.
