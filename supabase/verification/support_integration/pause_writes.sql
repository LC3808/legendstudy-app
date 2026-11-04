-- OWNER APPROVAL REQUIRED. Non-destructive emergency write stop.
-- Keep schema, stored replies, source data and read APIs. Review in-flight requests first.
begin;
revoke execute on function public.support_admin_reply(jsonb),public.support_admin_status(jsonb) from authenticated;
commit;
-- To resume after review:
-- grant execute on function public.support_admin_reply(jsonb),public.support_admin_status(jsonb) to authenticated;
-- Do not DROP the additive schema/columns after any reply has been recorded.
