-- Read-only postflight, safe before or after activation.
select mode from payment_private.configuration where singleton;
select p.proname,pg_get_userbyid(p.proowner) as owner,p.prosecdef,p.proconfig,p.proacl
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where (n.nspname='payment_private' and p.proname='current_order_mode')
 or (n.nspname='public' and p.proname in ('payment_order','payment_process'));
select id,email,email_confirmed_at is not null as confirmed from auth.users
where id='ddc5ae63-acbb-490b-a423-c996b811dea8';
select mode,state,grant_state,count(*) as orders,count(grant_id) as grants
from public.payment_orders group by 1,2,3 order by 1,2,3;
select count(*) as invalid_test_grants from public.payment_orders where mode='TEST' and grant_id is not null;
select count(*) as duplicate_purchase_grants from (
 select external_reference from public.credit_grants where external_reference like 'payment/%'
 group by external_reference having count(*)>1
) x;
