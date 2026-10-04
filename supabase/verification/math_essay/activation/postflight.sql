-- READ ONLY after exact approved installation, before enrollment/traffic.
begin read only;
select id,public,file_size_limit,allowed_mime_types from storage.buckets where id='math-private';
select pg_get_userbyid(roleid) role_name,pg_get_userbyid(member) member_name,pg_get_userbyid(grantor) grantor_name,admin_option,inherit_option,set_option
 from pg_auth_members where roleid in(select oid from pg_roles where rolname in('essay_executor','account_lifecycle_worker','math_executor','math_extraction_worker','math_evaluation_worker'));
select n.nspname,p.oid::regprocedure signature,pg_get_userbyid(p.proowner) owner,p.prosecdef,p.proconfig,p.proacl
 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='math_private' or (n.nspname='public' and p.proname like 'math_%') order by 1,2;
select schemaname,tablename,policyname,permissive,roles,cmd,qual,with_check from pg_policies where policyname like 'math_%';
select count(*) as math_attempts from public.math_attempts;
select count(*) as math_evaluations from public.math_evaluations;
select count(*) as math_objects from storage.objects where bucket_id='math-private';
select * from math_private.runtime_control;
-- Expected no grant to browser roles for privileged helpers.
select role_name,signature,has_function_privilege(role_name,signature,'EXECUTE') unexpected_access
from (values('anon'),('authenticated'),('service_role')) roles(role_name)
cross join (values('public.math_artifact_storage(uuid,uuid,text,bigint,text)'),('public.math_account_erasure(uuid,uuid,text)'),('public.math_recover_evaluation(uuid)')) signatures(signature);
-- Legacy inventories have one intentional additive grant: postgres EXECUTE on
-- math_private.release_billing(uuid), exclusively through fenced erasure/recovery.
commit;
