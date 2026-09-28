-- Security-only forward correction: B1. Applied 001/002/003 remain unchanged.
-- Trigger invocation does not require a service_role RPC use-case.
-- B2 ADMIN-only managed memberships are retained under the documented contract.
begin;
revoke execute on function public.essay_product_reject_update() from service_role;
revoke execute on function public.essay_product_terminal_guard() from service_role;
revoke execute on function public.essay_product_child_guard() from service_role;
revoke execute on function public.essay_question_identity_guard() from service_role;
revoke execute on function public.essay_product_progress_guard() from service_role;
revoke execute on function public.essay_product_processing_guard() from service_role;
revoke execute on function public.essay_product_draft_guard() from service_role;
revoke execute on function public.essay_credit_account_guard() from service_role;
revoke execute on function public.essay_billing_history_guard() from service_role;
commit;
