-- Read only. Does not request evaluation or publish/activate content.
select jsonb_build_object(
 'migration',(select jsonb_agg(jsonb_build_object('version',version,'name',name)) from supabase_migrations.schema_migrations where version='20261008001000'),
 'function',(select jsonb_build_object('md5',md5(prosrc),'owner',pg_get_userbyid(proowner),'security_definer',prosecdef,'settings',proconfig,'anon_execute',has_function_privilege('anon',oid,'EXECUTE'),'authenticated_execute',has_function_privilege('authenticated',oid,'EXECUTE'),'service_role_execute',has_function_privilege('service_role',oid,'EXECUTE')) from pg_proc where oid=to_regprocedure('public.essay_web_runtime_status()')),
 'math_evaluations_enabled',(select evaluations_enabled from math_private.runtime_control where singleton)
) as essay_web_runtime_postflight;
