\set ON_ERROR_STOP on
begin;
do $$begin assert current_database()='beta_v2_test' and inet_server_addr()='127.0.0.1'::inet, 'ISOLATED_FIXTURE_ONLY';end$$;
update essay_beta_private.campaigns set enabled=true;
set test.actor='00000000-0000-4000-8000-000000000002';
set test.clock='2026-11-09T12:00:00+09';
create temp table before_counts as select (select count(*) from public.credit_transactions) t,(select count(*) from public.credit_grants) g,(select count(*) from public.credit_accounts) a;
select public.essay_beta_daily_status_v2();
do $$declare j jsonb;begin
 j:=public.essay_beta_daily_status_v2();
 assert j->>'active'='true';
 assert (select t=(select count(*) from public.credit_transactions) and g=(select count(*) from public.credit_grants) and a=(select count(*) from public.credit_accounts) from before_counts),'READ_MUTATED_LEDGER';
end$$;
set test.actor='00000000-0000-4000-8000-999999999999';
do $$declare j jsonb;begin j:=public.essay_beta_daily_status_v2();assert j->>'grant_id'='' and (j->>'available')::integer=1; assert not exists(select 1 from public.credit_accounts where user_id='00000000-0000-4000-8000-999999999999');end$$;
set test.clock='2026-11-10T00:00:00+09';
do $$begin assert public.essay_beta_daily_status_v2()->>'day'='2026-11-10';end$$;
set test.clock='2026-11-10T23:59:00+09';
select public.essay_beta_daily_status_v2();
set test.clock='2026-11-11T00:00:00+09';
do $$begin assert public.essay_beta_daily_status_v2()->>'status'='ended';end$$;
rollback;
begin read only;
set test.actor='00000000-0000-4000-8000-000000000002';
set role authenticated;
select public.essay_beta_daily_status_v2();
rollback;
