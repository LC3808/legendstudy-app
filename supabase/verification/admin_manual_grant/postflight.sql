select jsonb_build_object(
 'rpc',(select jsonb_build_object('md5',md5(prosrc),'owner',pg_get_userbyid(proowner),'security_definer',prosecdef,'settings',proconfig,'anon_execute',has_function_privilege('anon',oid,'execute'),'authenticated_execute',has_function_privilege('authenticated',oid,'execute'),'service_execute',has_function_privilege('service_role',oid,'execute')) from pg_proc where oid='public.admin_manual_credit_grant(uuid,text,integer,text,uuid)'::regprocedure),
 'ledger',(select jsonb_agg(jsonb_build_object('table',relname,'rls',relrowsecurity,'direct_write',has_table_privilege('authenticated',oid,'INSERT,UPDATE,DELETE'))) from pg_class where oid in ('public.credit_grants'::regclass,'public.credit_transactions'::regclass)),
 'finance_not_exposed',not has_function_privilege('authenticated','public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz)','execute'),
 'migration',(select jsonb_agg(jsonb_build_object('version',version,'name',name)) from supabase_migrations.schema_migrations where version='20261009000100')
) as admin_manual_grant_postflight;
