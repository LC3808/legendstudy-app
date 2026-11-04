-- Read only. Execute after separate deployment approval and application.
select p.proname,p.provolatile='s' as stable,p.prosecdef,p.proconfig,
 has_function_privilege('authenticated',p.oid,'execute') as authenticated_allowed,
 has_function_privilege('anon',p.oid,'execute') as anon_allowed,
 has_function_privilege('service_role',p.oid,'execute') as service_role_allowed
from pg_proc p where p.oid=to_regprocedure('public.admin_dashboard_study(timestamptz,timestamptz)');
select count(*) records,md5(string_agg(row_to_json(s)::text,'' order by id)) fingerprint from public.study_sessions s;
-- Authenticated acceptance uses the actual administrator browser session;
-- do not fabricate production JWT claims or call grant/consume/evaluation RPCs.
