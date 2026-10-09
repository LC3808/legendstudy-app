-- Read-only; catalog verification is not authenticated runtime acceptance.
select jsonb_build_object(
 'migration',(select jsonb_agg(jsonb_build_object('version',version,'name',name)) from supabase_migrations.schema_migrations where version='20261008000900'),
 'rpc',(select jsonb_build_object('owner',pg_get_userbyid(proowner),'md5',md5(prosrc),'security_definer',prosecdef,'settings',proconfig,'anon_execute',has_function_privilege('anon',oid,'EXECUTE'),'authenticated_execute',has_function_privilege('authenticated',oid,'EXECUTE')) from pg_proc where oid=to_regprocedure('public.admin_member_list(text,integer,integer,text,text,text,integer,text,text,boolean)')),
 'cache',(select jsonb_build_object('rls',relrowsecurity,'owner',pg_get_userbyid(relowner),'direct_select',has_table_privilege('authenticated',oid,'SELECT'),'direct_insert',has_table_privilege('authenticated',oid,'INSERT'),'direct_update',has_table_privilege('authenticated',oid,'UPDATE'),'direct_delete',has_table_privilege('authenticated',oid,'DELETE')) from pg_class where oid=to_regclass('student_private.school_display_cache')),
 'resolved_schools',(select jsonb_agg(jsonb_build_object('school_name',school_name,'source',source)) from student_private.school_display_cache)
) as admin_directory_postflight;
