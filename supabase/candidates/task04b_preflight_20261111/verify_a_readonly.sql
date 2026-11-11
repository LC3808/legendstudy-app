-- READ ONLY after approved A rollout. No auth.uid spoofing and no test writes in production.
select count(*) as rows,count(distinct user_id) as owners from public.home_configuration_revisions;
-- Immediately after first installation and before real app use: both zero.
select count(*) as invalid_rows from public.home_configuration_revisions h
where revision<1 or config_version<>1 or jsonb_typeof(cards)<>'array'
or not exists(select 1 from auth.users u where u.id=h.user_id);
select count(*) as duplicate_versions from (
 select user_id,revision from public.home_configuration_revisions group by 1,2 having count(*)>1
) d;
select c.relrowsecurity,c.relforcerowsecurity,pg_get_userbyid(c.relowner) owner
from pg_class c where c.oid='public.home_configuration_revisions'::regclass;
select policyname,roles,cmd,qual from pg_policies where schemaname='public' and tablename='home_configuration_revisions';
select role_name,has_table_privilege(role_name,'public.home_configuration_revisions','SELECT') can_select,
has_table_privilege(role_name,'public.home_configuration_revisions','INSERT') can_insert,
has_table_privilege(role_name,'public.home_configuration_revisions','UPDATE') can_update,
has_table_privilege(role_name,'public.home_configuration_revisions','DELETE') can_delete,
has_table_privilege(role_name,'public.home_configuration_revisions','TRUNCATE') can_truncate,
has_function_privilege(role_name,'public.my_home_configuration()','EXECUTE') can_read_rpc,
has_function_privilege(role_name,'public.save_my_home_configuration(jsonb,bigint)','EXECUTE') can_save_rpc
from (values('anon'),('authenticated')) r(role_name);
-- Expected direct privileges all false; RPC anon false / authenticated true (false during soft rollback).
select p.oid::regprocedure::text signature,p.prosecdef,p.proconfig,md5(pg_get_functiondef(p.oid)) definition_md5
from pg_proc p where p.oid in ('public.my_home_configuration()'::regprocedure,'public.save_my_home_configuration(jsonb,bigint)'::regprocedure);
-- Confirm existing application RPCs/ACL/policies still match preflight_readonly.sql output.
