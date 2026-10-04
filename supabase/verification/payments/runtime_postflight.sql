-- Read only; no synthetic operations. Run after separately approved runtime apply.
select p.oid::regprocedure,pg_get_userbyid(p.proowner) as owner,p.prosecdef,p.proconfig,p.proacl
from pg_proc p where p.oid in ('public.credit_summary()'::regprocedure,'public.payment_support(jsonb)'::regprocedure,'public.payment_compensate(jsonb)'::regprocedure);
select r.role, has_function_privilege(r.role,'public.credit_summary()','EXECUTE') as balance,
 has_function_privilege(r.role,'public.payment_support(jsonb)','EXECUTE') as support,
 has_function_privilege(r.role,'public.payment_compensate(jsonb)','EXECUTE') as compensate
from (values('anon'),('authenticated'),('service_role'),('essay_finance')) r(role);
select relrowsecurity,relacl from pg_class where oid='payment_private.support_audit'::regclass;
select count(*) as support_audit_rows from payment_private.support_audit;
select mode,count(*) as orders,count(grant_id) as grants from public.payment_orders group by mode;
select mode from payment_private.configuration;
