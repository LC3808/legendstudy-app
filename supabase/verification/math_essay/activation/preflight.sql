-- Owner executes READ ONLY in the confirmed LegendStudy Production project.
-- Project identity must be checked in the Dashboard before execution. No repair/apply.
begin read only;
select current_user,version();
select version,name from supabase_migrations.schema_migrations order by version;
select nspname,pg_get_userbyid(nspowner) owner,nspacl from pg_namespace
 where nspname in ('public','storage','essay_private','account_private','math_private');
select rolname,rolsuper,rolcreaterole,rolinherit,rolbypassrls from pg_roles
 where rolname in ('postgres','supabase_admin','supabase_storage_admin','authenticator','essay_executor','account_lifecycle_worker','math_executor','math_extraction_worker','math_evaluation_worker');
select pg_get_userbyid(roleid) role_name,pg_get_userbyid(member) member_name,pg_get_userbyid(grantor) grantor_name,admin_option,inherit_option,set_option
 from pg_auth_members where roleid in(select oid from pg_roles where rolname in('essay_executor','account_lifecycle_worker','math_executor','math_extraction_worker','math_evaluation_worker'));
select n.nspname,c.relname,pg_get_userbyid(c.relowner) owner,c.relacl,c.relrowsecurity,
 pg_has_role(current_user,c.relowner,'USAGE') as executor_has_owner_privileges
 from pg_class c join pg_namespace n on n.oid=c.relnamespace where
 (n.nspname='storage' and c.relname in('buckets','objects')) or (n.nspname='public' and c.relname like 'math_%');
select schemaname,tablename,policyname,permissive,roles,cmd,qual,with_check from pg_policies where schemaname='storage';
select id,public,file_size_limit,allowed_mime_types from storage.buckets where id='math-private';
select n.nspname,p.oid::regprocedure signature,pg_get_userbyid(p.proowner) owner,p.prosecdef,p.proconfig,p.proacl
 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where
 n.nspname in('essay_private','account_private','math_private') or
 (n.nspname='public' and (p.proname like 'math_%' or p.proname like 'account_deletion%')) order by 1,2;
commit;
