-- Run after Owner-approved apply, not during implementation.
select p.proname,p.prosecdef,p.provolatile,p.proconfig from pg_proc p where p.oid='public.admin_credit_report(jsonb)'::regprocedure;
select has_function_privilege('authenticated','public.admin_credit_report(jsonb)','execute') authenticated,
 has_function_privilege('anon','public.admin_credit_report(jsonb)','execute') anon,
 has_function_privilege('service_role','public.admin_credit_report(jsonb)','execute') service_role;
select t.id,t.grant_id,t.transaction_type,t.reason_code,t.balance_delta,t.reserved_delta,
 essay_private.credit_display_grant(t.grant_id) source_kind,
 essay_private.credit_display_action(t.transaction_type,t.reason_code,t.balance_delta) action
from public.credit_transactions t where grant_id='02ee324f-f82f-49f0-9524-79d227a8425f' order by t.created_at,t.id;
-- Use a real operator session for admin_credit_report; never impersonate a hosted member.
