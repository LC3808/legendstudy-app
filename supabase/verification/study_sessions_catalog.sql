-- READ ONLY; only after approved owner deployment. Not JWT/RLS acceptance.
begin transaction read only;
set local timezone = 'UTC';
select column_name, data_type, is_nullable, column_default, is_generated, generation_expression
from information_schema.columns where table_schema='public' and table_name='study_sessions'
order by ordinal_position;
select conname, contype, convalidated, pg_get_constraintdef(oid)
from pg_constraint where conrelid='public.study_sessions'::regclass order by conname;
select indexname, indexdef from pg_indexes
where schemaname='public' and tablename='study_sessions';
select relrowsecurity, relforcerowsecurity from pg_class
where oid='public.study_sessions'::regclass;
select policyname, roles, cmd, qual, with_check from pg_policies
where schemaname='public' and tablename='study_sessions' order by policyname;
select grantee, column_name, privilege_type from information_schema.column_privileges
where table_schema='public' and table_name='study_sessions' order by 1,2,3;
select r, has_table_privilege(r, 'public.study_sessions','SELECT') as can_select,
 has_table_privilege(r, 'public.study_sessions','UPDATE') as can_update,
 has_table_privilege(r, 'public.study_sessions','DELETE') as can_delete,
 has_column_privilege(r, 'public.study_sessions','id','INSERT') as can_insert_id,
 has_column_privilege(r, 'public.study_sessions','duration_seconds','INSERT') as can_insert_duration,
 has_column_privilege(r, 'public.study_sessions','user_id','INSERT') as can_insert_owner,
 has_column_privilege(r, 'public.study_sessions','created_at','INSERT') as can_insert_created,
 has_function_privilege(r, 'public.study_active_milliseconds(jsonb,numeric)','EXECUTE') as can_derive
from unnest(array['anon','authenticated','service_role']) r;
select proname, provolatile, prosecdef, proconfig from pg_proc
where oid='public.study_active_milliseconds(jsonb,numeric)'::regprocedure;
select count(*) as study_rows from public.study_sessions; -- expected 0 before acceptance
select count(*) as profile_rows,
 md5(coalesce(string_agg(to_jsonb(p)::text, '' order by id), '')) as profile_digest
from public.profiles p; -- must match preflight; repeat preflight profile catalog queries too
-- Pure calculation example: 60 s active, 60 s paused, 60 s active = 120000 ms.
select public.study_active_milliseconds('[[0,60000],[120000,180000]]'::jsonb,180000)
 = 120000 as interval_example_pass;

select column_name, data_type, is_nullable from information_schema.columns
where table_schema='public' and table_name='profiles'
order by ordinal_position;
select conname, convalidated, pg_get_constraintdef(oid)
from pg_constraint where conrelid='public.profiles'::regclass order by conname;
select grantee, column_name, privilege_type from information_schema.column_privileges
where table_schema='public' and table_name='profiles' order by 1,2,3;
select policyname, roles, cmd, qual, with_check from pg_policies
where schemaname='public' and tablename='profiles' order by policyname;
-- Baseline for all existing public tables: compare the same ordered metadata after.
select c.relname, c.relrowsecurity, c.relforcerowsecurity,
 (select md5(coalesce(string_agg(pg_get_constraintdef(k.oid), '|' order by k.conname), ''))
  from pg_constraint k where k.conrelid=c.oid) as constraint_digest
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
 and c.relname in ('source_posts','content_items','exams','subjects','exam_subjects',
 'resources','profiles','bookmarks','recent_views','ingestion_quarantine')
order by c.relname;
commit;
