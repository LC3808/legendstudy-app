-- OWNER APPROVAL REQUIRED. psql -X -v ON_ERROR_STOP=1 -f <this-file>
begin;
set local lock_timeout='5s';
select pg_advisory_xact_lock(20261111,3);
lock table public.answer_key_versions,public.exam_questions,public.grade_cutoff_references in share row exclusive mode;
\ir payload.sql
\ir check_complete.sql
update public.answer_key_versions r set is_current=false,status=case when r.status='published' then 'withdrawn' else r.status end from task03b_keys s where r.id=s.id;
update public.grade_cutoff_references r set is_current=false,status=case when r.status='published' then 'withdrawn' else r.status end from task03b_refs s where r.id=s.id;
commit;
