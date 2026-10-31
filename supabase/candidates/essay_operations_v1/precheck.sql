-- Read-only. Run against exact target immediately before approval/application.
select current_database(),current_user,version();
select to_regnamespace('essay_ops_private') must_be_null;
select p.oid::regprocedure,pg_get_functiondef(p.oid) from pg_proc p where p.oid in ('public.admin_operator()'::regprocedure,'account_private.allowed(uuid)'::regprocedure);
select table_schema,table_name,column_name,data_type from information_schema.columns where (table_schema='essay_exam_private' and table_name in ('runs','checkpoints','retry_requests')) or (table_schema='public' and table_name in ('credit_transactions','credit_grants','essay_ai_processing_runs','essay_exams','universities')) order by 1,2,ordinal_position;
-- Live counters are observations, not proof of immutability while unrelated jobs run.
select state,count(*) from essay_exam_private.runs group by state;
select transaction_type,count(*),sum(balance_delta),sum(reserved_delta) from public.credit_transactions group by transaction_type;
