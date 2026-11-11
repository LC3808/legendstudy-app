select jsonb_build_object(
'checked_at_kst',to_char(clock_timestamp() at time zone 'Asia/Seoul','YYYY-MM-DD HH24:MI:SS'),
'migration',(select jsonb_agg(jsonb_build_object('version',version,'name',name)) from supabase_migrations.schema_migrations where name='task04c_home_configuration'),
'home_rows',(select count(*) from public.home_configuration_revisions),
'invalid_rows',(select count(*) from public.home_configuration_revisions where revision<1 or config_version<>1 or jsonb_typeof(cards)<>'array'),
'rls',(select relrowsecurity from pg_class where oid='public.home_configuration_revisions'::regclass),
'policy',(select jsonb_agg(to_jsonb(p)) from pg_policies p where schemaname='public' and tablename='home_configuration_revisions'),
'privileges',(select jsonb_agg(jsonb_build_object('role',r,'select',has_table_privilege(r,'public.home_configuration_revisions','SELECT'),'insert',has_table_privilege(r,'public.home_configuration_revisions','INSERT'),'update',has_table_privilege(r,'public.home_configuration_revisions','UPDATE'),'delete',has_table_privilege(r,'public.home_configuration_revisions','DELETE'),'truncate',has_table_privilege(r,'public.home_configuration_revisions','TRUNCATE'),'read_rpc',has_function_privilege(r,'public.my_home_configuration()','EXECUTE'),'save_rpc',has_function_privilege(r,'public.save_my_home_configuration(jsonb,bigint)','EXECUTE'))) from (values('anon'),('authenticated')) roles(r)),
'functions',(select jsonb_agg(jsonb_build_object('signature',p.oid::regprocedure::text,'hash',md5(pg_get_functiondef(p.oid)),'definition',pg_get_functiondef(p.oid),'definer',prosecdef,'config',proconfig,'acl',proacl::text)) from pg_proc p where oid in ('public.my_home_configuration()'::regprocedure,'public.save_my_home_configuration(jsonb,bigint)'::regprocedure)),
'news_absent',to_regclass('public.university_news_revisions') is null and to_regclass('public.university_official_sources') is null and to_regprocedure('public.university_news_feed(uuid[],integer,timestamptz)') is null
) as verification;
