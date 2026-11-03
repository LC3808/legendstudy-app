-- Read-only; no policy activation or student/credit queries.
select n.nspname,p.proname,pg_get_userbyid(p.proowner) owner,p.proacl::text acl,p.prosecdef,p.proconfig,
 md5(pg_get_functiondef(p.oid)) definition_md5
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where p.oid in('public.app_update_policy(text)'::regprocedure,'app_release_private.version_key(text,integer)'::regprocedure);
select platform,enabled,update_type,latest_version,latest_build,minimum_supported_version,minimum_supported_build,
 store_release_verified,required_approved from app_release_private.platform_policy order by platform;
select public.app_update_policy('ios') ios,public.app_update_policy('android') android;
select relrowsecurity,relforcerowsecurity,relacl::text from pg_class where oid='app_release_private.platform_policy'::regclass;
select r,
 has_function_privilege(r,'public.app_update_policy(text)','EXECUTE') public_rpc,
 has_schema_privilege(r,'app_release_private','USAGE') private_schema,
 has_table_privilege(r,'app_release_private.platform_policy','SELECT') private_read,
 has_table_privilege(r,'app_release_private.platform_policy','UPDATE') private_write
from unnest(array['anon','authenticated','service_role'])r;
