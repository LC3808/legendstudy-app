-- READ ONLY / PRE-APPLY. Prepared only; Production execution requires separate authorization.
-- Any collision/missing prerequisite/unverified migration history means STOP, not IF NOT EXISTS.
begin read only;
set local search_path = pg_catalog, public;
set local timezone = 'UTC';
select current_setting('server_version_num')::int>=170000 as postgres17_required,
 current_setting('server_encoding')='UTF8' as utf8_required;
select name,to_regclass(name) is not null as prerequisite_present from (values
 ('auth.users'),('public.profiles'),('public.universities'),('public.resources'),('public.essay_exams'),('public.essay_exam_resources')) t(name);
-- Required foundation columns/types: inspect alongside original20260927000200 source/hash.
select table_name,column_name,data_type,udt_name,is_nullable from information_schema.columns
where table_schema='public' and table_name in ('profiles','universities','resources','essay_exams','essay_exam_resources') order by table_name,ordinal_position;
select conrelid::regclass::text as relation,conname,pg_get_constraintdef(oid) as definition
from pg_constraint where conrelid in (to_regclass('public.profiles'),to_regclass('public.essay_exams'),to_regclass('public.essay_exam_resources')) order by 1,2;
select name,to_regclass('public.'||name) is null as name_available from unnest(array['essay_questions','essay_question_evidence','essay_evaluation_criteria','student_target_universities','essay_practice_sessions','essay_drafts','essay_attempts','essay_evaluations','essay_evaluation_dimensions','essay_improvement_items','essay_improvement_progress','essay_evaluation_evidence','essay_generated_rewrites','essay_learning_events','essay_ai_processing_runs','credit_accounts','credit_grants','essay_billing_decisions','credit_transactions']) name;
select to_regnamespace('essay_private') is null as private_schema_available;
with wanted(schema,name) as (values ('public','essay_product_reject_update'),('public','essay_product_terminal_guard'),('public','essay_product_child_guard'),('public','essay_question_identity_guard'),('public','essay_product_progress_guard'),('public','essay_product_processing_guard'),('public','essay_product_draft_guard'),('public','essay_credit_account_guard'),('public','essay_billing_history_guard'),('essay_private','uid'),('essay_private','clock'),('essay_private','hash'),('essay_private','owner'),('essay_private','lock_job'),('essay_private','release'),('public','essay_open_session'),('public','essay_save_draft'),('public','essay_submit_attempt'),('public','essay_request_evaluation'),('public','essay_request_rewrite'),('public','essay_claim'),('essay_private','fence'),('public','essay_timeout'),('public','essay_finalize_success'),('public','essay_finalize_failure'),('public','essay_reconcile'),('public','essay_refund'),('public','essay_erase'))
select w.schema,w.name,not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname=w.schema and p.proname=w.name) as function_name_available from wanted w order by 1,2;
-- Policies on any colliding target relation are evidence of partial/previous apply.
select tablename,policyname,roles,cmd from pg_policies where schemaname='public' and tablename=any(array['essay_questions','essay_question_evidence','essay_evaluation_criteria','student_target_universities','essay_practice_sessions','essay_drafts','essay_attempts','essay_evaluations','essay_evaluation_dimensions','essay_improvement_items','essay_improvement_progress','essay_evaluation_evidence','essay_generated_rewrites','essay_learning_events','essay_ai_processing_runs','credit_accounts','credit_grants','essay_billing_decisions','credit_transactions']);
select rolname,rolcanlogin,rolsuper,rolcreaterole,rolbypassrls from pg_roles
where rolname in (current_user,'anon','authenticated','service_role','authenticator','essay_executor','essay_worker','essay_finance') order by rolname;
select parent.rolname as granted_role,member.rolname as member_role from pg_auth_members a join pg_roles parent on parent.oid=a.roleid join pg_roles member on member.oid=a.member where parent.rolname in ('essay_executor','essay_worker','essay_finance');
select to_regprocedure('auth.uid()') is not null as auth_uid_present,
 has_schema_privilege(current_user,'public','CREATE') as can_create_public_objects,
 has_schema_privilege(current_user,'auth','USAGE') as can_use_auth_schema,
 has_function_privilege(current_user,'auth.uid()','EXECUTE') as can_call_uid,
 (select rolcreaterole or rolsuper from pg_roles where rolname=current_user) as role_bootstrap_privilege;
-- History is an independent gate: absent catalog => NOT_VERIFIED, no inferred deployment.
select to_regclass('supabase_migrations.schema_migrations') is not null as history_available;
select case when to_regclass('supabase_migrations.schema_migrations') is not null then
 query_to_xml('select version from supabase_migrations.schema_migrations order by version',false,false,'') end as applied_versions;
-- Expected last repository version before this package:20260927000200. Reconcile all pending files,
-- not only that maximum. Approved next order:20260928000100,20260928000200,20260928000300.
select case when to_regclass('public.essay_evaluations') is not null then
 query_to_xml($q$select count(*) as total, count(*) filter(where status in ('requested','processing')) as queued from public.essay_evaluations$q$,false,false,'') end as legacy_evaluations;
-- Any existing evaluations imply name collision/partial deployment; never auto-backfill queued rows.
-- Snapshot aggregate-only canonical baseline; compare EXACTLY with post-apply result.
select name,
 (xpath('/table/row/n/text()',query_to_xml(format('select count(*) as n from public.%I',name),false,false,'')))[1]::text::bigint row_count,
 (xpath('/table/row/h/text()',query_to_xml(format('select md5(coalesce(string_agg(row_to_json(t)::text, chr(10) order by row_to_json(t)::text),'''')) as h from public.%I t',name),false,false,'')))[1]::text content_fingerprint
 from (values ('universities'),('essay_exams'),('essay_exam_resources'),('resources')) t(name) order by name;
rollback;
