-- OWNER APPROVAL REQUIRED. psql -X -v ON_ERROR_STOP=1 -f <this-file>
begin;
set local lock_timeout='5s';
select pg_advisory_xact_lock(20261111,3);
lock table public.answer_key_versions,public.exam_questions,public.grade_cutoff_references in share row exclusive mode;
\ir payload.sql
\ir check_staged.sql
\ir check_complete.sql
do $$ begin if exists(select 1 from public.answer_key_versions r join task03b_keys s using(id) where r.status='withdrawn') or exists(select 1 from public.grade_cutoff_references r join task03b_refs s using(id) where r.status='withdrawn') then raise exception 'TASK03B_WITHDRAWN_REQUIRES_NEW_REVIEW'; end if; end $$;
update public.answer_key_versions r set status='published',is_current=true from task03b_keys s where r.id=s.id and (r.status,r.is_current) is distinct from ('published'::text,true);
update public.grade_cutoff_references r set status='published',is_current=true from task03b_refs s where r.id=s.id and (r.status,r.is_current) is distinct from ('published'::text,true);
commit;
