-- Owner-only READ ONLY pre/postflight. No row content, subject IDs, tokens or emails.
select version,name from supabase_migrations.schema_migrations order by version;
select n.nspname,c.relname,pg_get_userbyid(c.relowner) owner,c.relrowsecurity,c.relacl
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where (n.nspname='account_private' or c.relname='account_deletion_requests') and c.relkind='r';
select schemaname,tablename,policyname,roles,cmd,qual,with_check from pg_policies
where policyname='account_lifecycle_restriction' or schemaname='account_private' or tablename='account_deletion_requests';
select p.oid::regprocedure,pg_get_userbyid(p.proowner),p.prosecdef,p.provolatile,p.proconfig,p.proacl,md5(pg_get_functiondef(p.oid)) body_fingerprint
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='account_private' or n.nspname='public' and (p.proname like 'account_%' or p.proname like 'ql_%' or p.proname='is_quality_operator')
order by 1;
select n.nspname,c.relname,con.conname,pg_get_constraintdef(con.oid) from pg_constraint con join pg_class c on c.oid=con.conrelid join pg_namespace n on n.oid=c.relnamespace
where n.nspname='account_private' or c.relname='account_deletion_requests';
select schemaname,tablename,indexname,indexdef from pg_indexes where schemaname='account_private' or tablename='account_deletion_requests';
-- After application, using the reviewed owner role only:
-- select public.account_deletion_health(); -- enabled must be false before activation.

-- Prerequisite Auth field, metadata only:
select column_name,data_type from information_schema.columns where table_schema='auth' and table_name='users' and column_name='email_confirmed_at';
