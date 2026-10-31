-- Disable WEB monitor first; preserve audit/rate/alert history. No CASCADE.
begin;
drop function public.admin_essay_operations(timestamptz,timestamptz,jsonb,integer,uuid);
drop function public.admin_essay_operations_check_alerts();
drop function public.admin_essay_operations_estimate();
-- Private objects remain revoked + RLS. Owner may archive them after export/retention review.
commit;
