select to_regprocedure('public.admin_credit_member_list(text,integer,integer,text)') is not null as installed,
 not has_function_privilege('anon','public.admin_credit_member_list(text,integer,integer,text)','execute') as anonymous_denied,
 not has_function_privilege('service_role','public.admin_credit_member_list(text,integer,integer,text)','execute') as service_role_denied,
 has_function_privilege('authenticated','public.admin_credit_member_list(text,integer,integer,text)','execute') as authenticated_gate,
 md5(pg_get_functiondef('public.admin_credit_snapshot(uuid)'::regprocedure))='0704946d9d378da925478c39be741795' as snapshot_preserved,
 md5(pg_get_functiondef('public.admin_manual_credit_grant(uuid,text,integer,text,uuid)'::regprocedure))='f9d760b2f810c57aa18d7097e5e7f5b3' as grant_preserved,
 (select count(*)=90 and coalesce(sum(balance_delta),0)=338 from public.credit_transactions) as ledger_unchanged;
