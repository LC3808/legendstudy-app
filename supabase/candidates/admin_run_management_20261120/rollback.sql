-- Disable additive API only; never discard audit/evidence or reverse real actions.
begin;
revoke all on function public.admin_lab_run_capabilities(uuid),public.admin_lab_manage_run(uuid,text,uuid),public.admin_lab_operation_stats(timestamptz,timestamptz) from public,anon,authenticated,service_role,essay_worker;
commit;
-- Restore previous WEB/Worker deployment separately. Audit and all learning/ledger data retained.
