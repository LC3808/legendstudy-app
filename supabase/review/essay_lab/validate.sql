-- OWNER POST-APPLY: read-only catalog/empty-state checks. NOT an RLS behavior test.
-- All three tables stay empty (no Pilot seed); public authenticated reads require
-- actual JWT follow-up when fixtures are separately authorized.
begin transaction read only;
-- Expected: 3 rows, RLS true.
select c.relname, c.relrowsecurity as rls_enabled
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname in ('universities','essay_exams','essay_exam_resources')
order by c.relname;
-- Expected: 0 / 0 / 0 immediately after this no-seed migration.
select 'universities' as table_name, count(*) as expected_zero from public.universities
union all select 'essay_exams', count(*) from public.essay_exams
union all select 'essay_exam_resources', count(*) from public.essay_exam_resources;
-- Expected PKs: UUID university/exam; (essay_exam_id,resource_id,role) mapping.
-- UNIQUE: university slug; essay university_id/admission_year/exam_key only.
-- FKs: 4, all DELETE RESTRICT; all CHECK/FK constraints validated.
select c.conrelid::regclass as table_name, c.conname, c.contype, c.convalidated,
       pg_get_constraintdef(c.oid) as definition
from pg_constraint c
where c.conrelid in ('public.universities'::regclass,'public.essay_exams'::regclass,
                    'public.essay_exam_resources'::regclass)
order by table_name, c.conname;
-- Expected 0: no context uniqueness introduced.
select count(*) as must_be_zero from pg_indexes
where schemaname = 'public' and tablename = 'essay_exams'
  and indexdef like 'CREATE UNIQUE%' and indexdef ~ '(campus|admission_track|field_or_division|session_label)';
-- Expected 3 SELECT policies; anon/authenticated; active/verified parent checks.
select tablename, policyname, roles, cmd, qual, with_check
from pg_policies where schemaname = 'public'
  and tablename in ('universities','essay_exams','essay_exam_resources')
order by tablename, policyname;
-- Expected SELECT true; every client write capability false (including column grants).
select r.role_name, t.table_name,
       has_table_privilege(r.role_name, 'public.' || t.table_name, 'SELECT') as select_allowed,
       has_any_column_privilege(r.role_name, 'public.' || t.table_name, 'INSERT') as insert_forbidden_false,
       has_any_column_privilege(r.role_name, 'public.' || t.table_name, 'UPDATE') as update_forbidden_false,
       has_table_privilege(r.role_name, 'public.' || t.table_name, 'DELETE') as delete_forbidden_false,
       has_table_privilege(r.role_name, 'public.' || t.table_name, 'TRUNCATE') as truncate_forbidden_false
from (values ('anon'),('authenticated')) r(role_name)
cross join (values ('universities'),('essay_exams'),('essay_exam_resources')) t(table_name)
order by r.role_name,t.table_name;
-- Expected all true for service-role CRUD, used only under separate authorization.
select name, has_table_privilege('service_role','public.' || name,'SELECT') as can_select,
       has_table_privilege('service_role','public.' || name,'INSERT') as can_insert,
       has_table_privilege('service_role','public.' || name,'UPDATE') as can_update,
       has_table_privilege('service_role','public.' || name,'DELETE') as can_delete
from (values ('universities'),('essay_exams'),('essay_exam_resources')) t(name);
-- Expected 3 triggers referencing the existing set_updated_at function.
select tgrelid::regclass as table_name, tgname, pg_get_triggerdef(oid) as definition
from pg_trigger where not tgisinternal
  and tgrelid in ('public.universities'::regclass,'public.essay_exams'::regclass,
                 'public.essay_exam_resources'::regclass)
order by table_name;
-- Existing text locator can describe PDF page/section/question; no Question table.
select data_type as expected_text from information_schema.columns
where table_schema='public' and table_name='essay_exam_resources' and column_name='source_locator';
rollback;
