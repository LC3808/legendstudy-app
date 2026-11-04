-- Separate activation only after prepare, adapter deployment, keys and merchant gates pass.
-- No historical order mode updates. Direct buyer RPC creates LIVE after this commit.
begin;
do $$begin
 if to_regprocedure('payment_private.current_order_mode()') is null then raise exception 'LIVE_PREP_REQUIRED';end if;
 if not exists(select 1 from auth.users where id='ddc5ae63-acbb-490b-a423-c996b811dea8' and email='review@legendstudy.com' and email_confirmed_at is not null) then raise exception 'REVIEW_IDENTITY_CHANGED';end if;
 if (select mode from payment_private.configuration where singleton) is distinct from 'TEST' then raise exception 'EXPECTED_TEST';end if;
end$$;
update payment_private.configuration set mode='LIVE' where singleton;
commit;
