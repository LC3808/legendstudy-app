-- READ ONLY. Owner: confirm Dashboard project stlhijzpjfgwwdgunlsd first.
-- Expected: no proposed objects; three auth roles; auth.users/auth.uid exist.
begin transaction read only;
set local timezone = 'UTC';
select current_database(), current_user, version();
select to_regclass('public.study_sessions') as must_be_null,
       to_regprocedure('public.study_active_milliseconds(jsonb,numeric)') as must_be_null_function,
       to_regclass('auth.users') as auth_users,
       to_regprocedure('auth.uid()') as auth_uid;
select rolname, rolbypassrls from pg_roles
where rolname in ('anon','authenticated','service_role') order by rolname;
select has_schema_privilege(current_user, 'public', 'CREATE') as can_create,
 has_table_privilege(current_user, 'auth.users', 'REFERENCES') as can_reference_users;
-- Generated expression primitives must be immutable (provolatile = i).
select oid::regprocedure as function, provolatile from pg_proc
where oid in ('pg_catalog.timestamptz_mi(timestamptz,timestamptz)'::regprocedure,
              'pg_catalog.extract(text,interval)'::regprocedure);
-- Capture privately, then repeat exactly after deployment. No profile contents printed.
select count(*) as profile_rows,
       md5(coalesce(string_agg(to_jsonb(p)::text, '' order by id), '')) as profile_digest
from public.profiles p;
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
