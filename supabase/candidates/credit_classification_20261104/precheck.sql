-- Verify the approved read-function baseline; stop on drift before any DDL.
do $$ begin
 if md5(pg_get_functiondef('public.admin_member_credit(uuid,integer,integer)'::regprocedure)) <> '5d23c4ab6c7f94f764175cce6187b7e1' then
  raise exception 'MEMBER_READ_BASELINE_DRIFT';
 end if;
 if to_regprocedure('public.admin_credit_report(jsonb)') is not null then raise exception 'REPORT_ALREADY_EXISTS';end if;
end $$;

select g.origin,t.transaction_type,t.reason_code,count(*) records,sum(t.balance_delta) balance_delta,sum(t.reserved_delta) reserved_delta from public.credit_transactions t join public.credit_grants g on g.id=t.grant_id group by 1,2,3 order by 1,2,3;
