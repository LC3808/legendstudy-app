-- Runtime rollback leaves canonical payment and Ledger history untouched.
begin;
do $$begin if exists(select 1 from payment_private.support_audit) or exists(select 1 from public.payment_orders where mode='LIVE' and grant_id is null and paid_at is not null) then raise exception 'SUPPORT_HISTORY_PRESENT_FORWARD_FIX_ONLY';end if;end$$;
drop function public.payment_compensate(jsonb);
drop function public.payment_support(jsonb);
drop function public.credit_summary();
drop table payment_private.support_audit;
notify pgrst,'reload schema';
commit;
