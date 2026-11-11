-- READ ONLY: only temporary staging writes, rolled back. No persistent data changes.
begin;
\ir payload.sql
\ir check_staged.sql
\ir check_complete.sql
select count(*) as published_ready_keys from public.answer_key_versions r join task03b_keys s using(id) where r.status='published' and r.is_current and r.verification_status='READY';
select count(*) as published_reference_rows from public.grade_cutoff_references r join task03b_refs s using(id) where r.status='published' and r.is_current;
select relname,relrowsecurity from pg_class where oid in ('public.mock_exam_attempts'::regclass,'public.mock_exam_answers'::regclass,'public.grade_cutoff_references'::regclass);
rollback;
