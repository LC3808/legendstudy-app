-- Read only. All should be true; authenticated UI checks separately.
select p.oid::regprocedure as function, p.prosecdef and p.proconfig @> array['search_path=""'] as secured,
 has_function_privilege('authenticated',p.oid,'execute') as admin_caller_grant,
 not has_function_privilege('anon',p.oid,'execute') and not has_function_privilege('service_role',p.oid,'execute') and not has_function_privilege('essay_worker',p.oid,'execute') as unprivileged_denied
from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('admin_lab_run_capabilities','admin_lab_manage_run','admin_lab_operation_stats');
select count(*) as action_count from essay_ops_private.run_actions;
select count(*) as verified_test_count from essay_ops_private.verified_test_runs;
-- Existing stuck request remains unchanged immediately after install.
select id,state,created_at,completed_at,lease_until,(select count(*) from public.credit_transactions where decision_id=r.decision_id) ledger_count,
(select count(*) from essay_exam_private.retry_requests where run_id=r.id) retry_count
from essay_exam_private.runs r where id='e7af7e52-eba9-46c3-aba4-0961ea516b48';
