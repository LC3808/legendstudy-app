-- Read only. Availability is not authenticated runtime acceptance.
with routines as (
 select p.oid::regprocedure::text signature,md5(p.prosrc) body_md5,
 pg_get_userbyid(p.proowner) owner,p.prosecdef security_definer,p.proconfig settings,
 has_function_privilege('anon',p.oid,'EXECUTE') anon_execute,
 has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_execute
 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.proname in ('my_application_save','my_application_event','my_application_delete','my_applications','my_application_events','my_study_summary','my_essay_summary','admin_student360')
), tables as (
 select c.relname,c.relrowsecurity rls,
 has_table_privilege('authenticated',c.oid,'INSERT') direct_insert,
 has_table_privilege('authenticated',c.oid,'UPDATE') direct_update,
 has_table_privilege('authenticated',c.oid,'DELETE') direct_delete
 from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relname in ('student_applications','student_application_events')
), migrations as (
 select version,name from supabase_migrations.schema_migrations where version between '20261008000500' and '20261008000800'
), cascades as (
 select c.conrelid::regclass::text child,c.confrelid::regclass::text parent,c.confdeltype='c' cascade
 from pg_constraint c where c.contype='f' and c.conrelid in(to_regclass('public.student_applications'),to_regclass('public.student_application_events'))
)
select jsonb_build_object('migrations',coalesce((select jsonb_agg(m) from migrations m),'[]'::jsonb),
 'functions',coalesce((select jsonb_agg(r) from routines r),'[]'::jsonb),
 'tables',coalesce((select jsonb_agg(t) from tables t),'[]'::jsonb),
 'relations',coalesce((select jsonb_agg(c) from cascades c),'[]'::jsonb)) as my_foundation_postflight;
