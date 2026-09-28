-- Used to regenerate/inspect catalog contract ONLY in disposable validation.
begin read only;
set local search_path = pg_catalog, public;
set local timezone = 'UTC';
with target(name) as (values ('essay_questions'),('essay_question_evidence'),('essay_evaluation_criteria'),('student_target_universities'),('essay_practice_sessions'),('essay_drafts'),('essay_attempts'),('essay_evaluations'),('essay_evaluation_dimensions'),('essay_improvement_items'),('essay_improvement_progress'),('essay_evaluation_evidence'),('essay_generated_rewrites'),('essay_learning_events'),('essay_ai_processing_runs'),('credit_accounts'),('credit_grants'),('essay_billing_decisions'),('credit_transactions')),
 table_objects as (
 select 'table'::text kind,t.name,
 jsonb_build_object(
 'rls',c.relrowsecurity,
 'columns',(select jsonb_agg(jsonb_build_array(a.attname,format_type(a.atttypid,a.atttypmod),a.attnotnull,pg_get_expr(ad.adbin,ad.adrelid)) order by a.attnum) from pg_attribute a left join pg_attrdef ad on ad.adrelid=a.attrelid and ad.adnum=a.attnum where a.attrelid=c.oid and a.attnum>0 and not a.attisdropped),
 'constraints',(select jsonb_agg(jsonb_build_array(k.conname,k.contype,pg_get_constraintdef(k.oid)) order by k.conname) from pg_constraint k where k.conrelid=c.oid),
 'indexes',(select jsonb_agg(pg_get_indexdef(i.indexrelid) order by i.indexrelid::regclass::text) from pg_index i where i.indrelid=c.oid),
 'triggers',(select jsonb_agg(pg_get_triggerdef(tr.oid) order by tr.tgname) from pg_trigger tr where tr.tgrelid=c.oid and not tr.tgisinternal),
 'policies',(select jsonb_agg(jsonb_build_array(p.policyname,p.permissive,p.roles,p.cmd,p.qual,p.with_check) order by p.policyname) from pg_policies p where p.schemaname='public' and p.tablename=t.name)
 )::text definition
 from target t join pg_class c on c.oid=to_regclass('public.'||t.name)
 ), wanted_functions(schema,name) as (values ('public','essay_product_reject_update'),('public','essay_product_terminal_guard'),('public','essay_product_child_guard'),('public','essay_question_identity_guard'),('public','essay_product_progress_guard'),('public','essay_product_processing_guard'),('public','essay_product_draft_guard'),('public','essay_credit_account_guard'),('public','essay_billing_history_guard'),('essay_private','uid'),('essay_private','clock'),('essay_private','hash'),('essay_private','owner'),('essay_private','lock_job'),('essay_private','release'),('public','essay_open_session'),('public','essay_save_draft'),('public','essay_submit_attempt'),('public','essay_request_evaluation'),('public','essay_request_rewrite'),('public','essay_claim'),('essay_private','fence'),('public','essay_timeout'),('public','essay_finalize_success'),('public','essay_finalize_failure'),('public','essay_reconcile'),('public','essay_refund'),('public','essay_erase')),
 function_objects as (select 'function'::text kind,n.nspname||'.'||p.proname||'('||pg_get_function_identity_arguments(p.oid)||')' name,pg_get_functiondef(p.oid) definition from pg_proc p join pg_namespace n on n.oid=p.pronamespace join wanted_functions f on (f.schema,f.name)=(n.nspname,p.proname)),
 objects as (select * from table_objects union all select * from function_objects)
 select kind,name,md5(definition) definition_hash from objects order by kind,name;
rollback;
