-- Read-only Owner pre/postflight. No student rows or secrets.
begin read only;
select version,name from supabase_migrations.schema_migrations order by version;
select c.relname,c.relowner::regrole as owner,c.relrowsecurity,c.relacl
from pg_class c where c.oid=to_regclass('public.quality_operators');
select * from pg_policies where schemaname='public' and tablename='quality_operators';
select p.proname,pg_get_function_identity_arguments(p.oid) as arguments,
 p.proowner::regrole as owner,p.prosecdef,p.proconfig,p.proacl
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in ('is_quality_operator','ql_list_cases','ql_case_detail');
select c.relname,c.relrowsecurity,c.relacl from pg_class c
where c.relnamespace='public'::regnamespace and c.relname like 'essay_%' order by c.relname;
select tablename,policyname,roles,cmd,qual,with_check from pg_policies
where schemaname='public' and tablename like 'essay_%' order by tablename,policyname;
rollback;
