select to_regprocedure('public.admin_credit_member_list(text,integer,integer,text)') is null as new_function_absent,
 to_regprocedure('public.admin_credit_snapshot(uuid)') is not null as canonical_snapshot_exists,
 to_regprocedure('public.admin_operator()') is not null as existing_admin_gate,
 (select count(*) from public.credit_transactions) as ledger_rows,
 (select coalesce(sum(balance_delta),0) from public.credit_transactions) as ledger_balance,
 md5(pg_get_functiondef('public.admin_credit_snapshot(uuid)'::regprocedure)) as snapshot_md5,
 md5(pg_get_functiondef('public.admin_manual_credit_grant(uuid,text,integer,text,uuid)'::regprocedure)) as grant_md5;
