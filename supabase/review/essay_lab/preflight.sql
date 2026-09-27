-- OWNER PRE-APPLY ONLY. Select LegendStudy project stlhijzpjfgwwdgunlsd in Dashboard.
-- Expected: 3 new names NULL; resources PK UUID + clock function exist;
-- required Supabase roles present, service_role BYPASSRLS true.
-- Any pre-existing target table: STOP and compare definitions; do not overwrite.
begin transaction read only;
select current_database() as database_name, current_setting('server_version') as server_version;
select name, to_regclass('public.' || name) as must_be_null_before_first_apply
from (values ('universities'), ('essay_exams'), ('essay_exam_resources')) t(name);
select to_regclass('public.resources') as required_resources,
       to_regprocedure('public.set_updated_at()') as required_clock;
select column_name, data_type, is_nullable from information_schema.columns
where table_schema = 'public' and table_name = 'resources' and column_name = 'id';
select pg_get_constraintdef(oid) as resource_primary_key
from pg_constraint where conrelid = to_regclass('public.resources') and contype = 'p';
select rolname, rolbypassrls from pg_roles
where rolname in ('anon', 'authenticated', 'service_role') order by rolname;
rollback;
