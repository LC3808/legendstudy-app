-- READ ONLY; only after approved owner deployment. Not JWT/RLS acceptance.
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
