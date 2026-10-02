-- Read-only; no lifecycle or financial RPC invocation.
select p.oid::regprocedure,pg_get_userbyid(p.proowner) owner,p.prosecdef,p.proconfig,p.proacl from pg_proc p join pg_namespace n on n.oid=p.pronamespace where (n.nspname='payment_private' or n.nspname='public' and p.proname in ('payment_order','payment_process')) order by 1;
select c.oid::regclass,pg_get_userbyid(relowner),relrowsecurity,relacl from pg_class c where c.oid in ('public.payment_orders'::regclass,'public.payment_operations'::regclass,'public.payment_events'::regclass,'payment_private.configuration'::regclass);
select role,relation,has_table_privilege(role,relation,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE') as must_be_false from unnest(array['anon','authenticated','service_role']) role cross join unnest(array['public.payment_orders','public.payment_operations','public.payment_events','payment_private.configuration']) relation;
select role,fn,has_function_privilege(role,fn,'EXECUTE') from unnest(array['anon','authenticated','service_role','essay_finance']) role cross join unnest(array['public.payment_order(jsonb)','public.payment_process(jsonb)']) fn;
select pg_get_userbyid(roleid),pg_get_userbyid(member),pg_get_userbyid(grantor),admin_option,inherit_option,set_option from pg_auth_members where roleid='essay_executor'::regrole;
select has_schema_privilege('essay_executor','public','CREATE') as must_be_false;
select mode from payment_private.configuration;
select (select count(*) from public.payment_orders) orders,(select count(*) from public.payment_operations) operations,(select count(*) from public.payment_events) events;
select count(*) as must_be_zero from public.payment_orders where mode='TEST' and (grant_id is not null or grant_state='POSTED');
select tgname,pg_get_triggerdef(oid) from pg_trigger where tgname='payment_purchase_spend_guard';
-- Operational aggregate, no identifiers or content.
select kind,state,error_code,count(*),min(created_at) oldest from public.payment_operations group by kind,state,error_code;
select count(*) pending_over_five_minutes from public.payment_operations where state='PENDING' and created_at<clock_timestamp()-interval '5 minutes';
