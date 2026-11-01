-- TEST-only compatibility with existing exact ACL-array pre/postchecks.
-- Effective grants are unchanged; PostgreSQL ACL arrays are order-sensitive text.
begin;
revoke execute on function public.essay_beta_daily_claim_v2(),public.essay_beta_notice_ack(uuid) from authenticated;
grant execute on function public.essay_beta_daily_claim_v2(),public.essay_beta_notice_ack(uuid) to authenticated;
commit;
