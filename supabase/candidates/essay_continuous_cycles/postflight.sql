-- Read-only. Does NOT call quote/submit/Provider or reserve Credit.
select p.proname,p.prosecdef,p.proconfig,p.proacl::text,
 has_function_privilege('essay_worker',p.oid,'execute') as worker_execute,
 has_function_privilege('anon',p.oid,'execute') as anon_execute,
 has_function_privilege('authenticated',p.oid,'execute') as student_execute,
 has_function_privilege('service_role',p.oid,'execute') as service_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in ('essay_exam_quote','essay_exam_submit_cycle');
-- Expected two rows: worker true, other three false; security definer true, empty search_path.
select column_name,is_nullable from information_schema.columns
where table_schema='essay_exam_private' and table_name='runs'
and column_name in ('previous_paid_run_id','submission_index');
select indexname,indexdef from pg_indexes where schemaname='essay_exam_private' and indexname='exam_paid_successor_once';
select tgname,tgenabled from pg_trigger where tgrelid='essay_exam_private.runs'::regclass and tgname='exam_cycle_insert';
select count(*) as new_cycle_rows from essay_exam_private.runs where submission_index is not null or previous_paid_run_id is not null;
-- Expected zero until separately authorized execution. Repeat preservation.sql: all digests equal.
