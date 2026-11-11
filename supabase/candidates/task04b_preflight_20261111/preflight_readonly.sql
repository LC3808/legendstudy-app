-- READ ONLY. Run as the same migration owner (normally postgres). No user records returned.
select current_user,version();
select c.relname,c.relkind,c.relrowsecurity from pg_class c
join pg_namespace n on n.oid=c.relnamespace where n.nspname='public'
and c.relname in ('home_configuration_revisions','university_official_sources','university_news_revisions');
-- Expected BEFORE deployment: zero candidate relations and zero candidate functions.
select p.oid::regprocedure::text signature,md5(pg_get_functiondef(p.oid)) definition_md5,
 p.prosecdef,p.proconfig,p.proacl from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where (n.nspname='public' and p.proname in ('my_home_configuration','save_my_home_configuration','university_news_feed','task04_news_immutable','my_applications','my_application_save','my_application_event','my_application_events','my_application_delete','account_service_allowed'))
or (n.nspname='account_private' and p.proname in ('allowed','lock_subject')) order by signature;
select table_schema,table_name,column_name,data_type from information_schema.columns
where (table_schema='auth' and table_name='users' and column_name='id')
or (table_schema='public' and table_name='universities' and column_name in ('id','name'));
select r.rolname,n.nspname,d.defaclobjtype,d.defaclacl from pg_default_acl d
join pg_roles r on r.oid=d.defaclrole left join pg_namespace n on n.oid=d.defaclnamespace
where n.nspname='public' or d.defaclnamespace=0;
select schemaname,tablename,policyname,roles,cmd,qual,with_check from pg_policies
where schemaname='public' and tablename in ('student_applications','student_application_events','home_configuration_revisions','university_official_sources','university_news_revisions');
