-- Read only. Approval candidate; compare live definitions before applying.
select to_regclass('feedback_private.essay_context') as context_table,
 to_regprocedure('public.essay_feedback_submit(jsonb)') as submit,
 to_regprocedure('public.admin_operator()') as admin_gate,
 to_regprocedure('account_private.allowed(uuid)') as account_gate;
select pg_get_functiondef('public.essay_feedback_submit(jsonb)'::regprocedure);
select column_name from information_schema.columns
 where table_schema='feedback_private' and table_name='essay_context' order by ordinal_position;
-- Existing rating columns/report RPC mean STOP: inspect version; do not reinstall blindly.
select to_regprocedure('public.admin_essay_satisfaction(timestamptz,timestamptz)');
