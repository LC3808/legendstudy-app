begin read only;
select p.oid::regprocedure::text function,p.prosecdef security_definer,p.proconfig,has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated,not has_function_privilege('anon',p.oid,'EXECUTE') anon_denied,not has_function_privilege('service_role',p.oid,'EXECUTE') service_role_denied from pg_proc p where p.oid in ('public.admin_lab_runs(uuid,uuid,uuid,text,text,integer)'::regprocedure,'public.admin_lab_run_detail(uuid)'::regprocedure,'public.admin_credit_member_list(text,integer,integer,text)'::regprocedure);
rollback;
