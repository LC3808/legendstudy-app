-- Read-only postflight. Counts below are actual totals, not inferred migration success.
select id,public,file_size_limit,allowed_mime_types from storage.buckets where id='essay-material-originals';
select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='essay_material_private' and c.relkind='r';
select p.proname,has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute,
 has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute,
 p.prosecdef,p.proconfig from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.proname like 'essay_material_%';
select pg_has_role('authenticator','essay_worker','MEMBER') as worker_membership;
select count(*) as exams from public.essay_exams;
select count(*) as questions from public.essay_questions;
select policyname,permissive,roles,cmd,qual,with_check from pg_policies where schemaname='storage' and tablename='objects' and policyname like 'essay_material_%';
