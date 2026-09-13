-- READ ONLY. Owner: confirm Dashboard project stlhijzpjfgwwdgunlsd first.
-- Expected: no proposed objects; three auth roles; auth.users/auth.uid exist.
select current_database(), current_user, version();
select to_regclass('public.study_sessions') as must_be_null,
       to_regprocedure('public.study_active_milliseconds(jsonb,numeric)') as must_be_null_function,
       to_regclass('auth.users') as auth_users,
       to_regprocedure('auth.uid()') as auth_uid;
select rolname, rolbypassrls from pg_roles
where rolname in ('anon','authenticated','service_role') order by rolname;
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
