-- REVIEW CANDIDATE ONLY. NOT APPLIED. Existing finance/order/ledger contracts retained.
-- Apply only with explicit Owner approval, a saved current function/ACL and PAUSED verified.
-- Creation-only boundary: payment_order calls this helper only for action=create.
-- Existing get/confirmation/reconciliation/refund functions are not replaced.
begin;
do $$begin
 if (select mode from payment_private.configuration where singleton) is distinct from 'LIVE' then
  raise exception 'EXPECTED_LIVE_CONFIGURATION';
 end if;
 if not exists(select 1 from auth.users where id='d5eab102-da92-4c4c-9adb-16d2c9d20e4c' and email='admin@legendstudy.com' and email_confirmed_at is not null)
 or not exists(select 1 from auth.users where id='ddc5ae63-acbb-490b-a423-c996b811dea8' and email='review@legendstudy.com' and email_confirmed_at is not null) then
  raise exception 'QA_IDENTITY_CHANGED';
 end if;
end$$;
create or replace function payment_private.current_order_mode()
returns text language plpgsql stable security definer set search_path=''
as $function$
declare u uuid=essay_private.uid();m text;
begin
 if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED';end if;
 select mode into m from payment_private.configuration where singleton;
 if m is distinct from 'LIVE' then raise sqlstate 'PT503' using message='MODE_UNAVAILABLE';end if;
 if exists(select 1 from auth.users where id=u and id='ddc5ae63-acbb-490b-a423-c996b811dea8' and email='review@legendstudy.com' and email_confirmed_at is not null) then return 'TEST';end if;
 if exists(select 1 from auth.users where id=u and id='d5eab102-da92-4c4c-9adb-16d2c9d20e4c' and email='admin@legendstudy.com' and email_confirmed_at is not null) then return 'LIVE';end if;
 raise sqlstate 'PT403' using message='PAYMENT_QA_REQUIRED';
end$function$;
-- CREATE OR REPLACE retains existing owner and ACL. Verify against saved preflight before COMMIT.
-- Not a new migration history entry; candidate requires isolated DB validation before application.
commit;
