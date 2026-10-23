# Purchased Credit end-of-day amendment — OWNER APPLY, NOT APPLIED

`owner_apply.sql` is a complete, single-transaction review package for LegendStudy
Production stlhijzpjfgwwdgunlsd, to execute as postgres after Owner review. It
refuses a changed IAP RPC or any inventory other than the verified3 IAP grants.
Do not remove guards to force it through. It changes financial expiry terms, so
it is deliberately not automatically run as part of an app release/migration.
After Owner applies, promote the executed SQL into migration history.

Scope: existing3 purchases end23:59:59.999999KST on existing Jan22/Jan23 dates;
new verified purchases KST calendar date+3months end-of-day. Free credits remain
unchanged. Ledger rows/amounts and the Essay functions remain untouched. Original
expiry is stored in a restricted, immutable audit. Existing grant immutability is
restored in the same exclusive transaction. Lock timeout5s: retry only after
investigating concurrent work, never disable guards outside this transaction.

Post-apply read-only validation:
```sql
select count(*) amendments,
       bool_and(g.expires_at=a.new_expires_at and a.new_expires_at>a.old_expires_at) extended
from account_private.iap_expiry_amendments_20261023 a
join public.credit_grants g on g.id=a.grant_id;
-- Expected 3 / true.
select t.reason_code,count(*),sum(t.balance_delta)
from public.credit_transactions t join public.credit_grants g on g.id=t.grant_id
where g.external_reference like 'iap/%' group by t.reason_code;
-- Apple 2 rows/+4; Google 1 row/+1 at the reviewed snapshot. Recheck new sales.
select tgenabled from pg_trigger where tgrelid='public.credit_grants'::regclass
and tgname='credit_grant_terms_frozen'; -- O
```
Do not purchase again to test. Owner can reopen app with existing transactions;
verify no extra Ledger postings and date-only history after app release.

Rollback: any pre-commit exception rolls back DDL, terms, audit and trigger state.
After commit, do not restore the old RPC or shorten extended rights. Keep replay
compatibility and fix forward after review. No automatic destructive rollback.

Isolated test (no host port, no production credentials):
```sh
docker run --rm -d --name legendstudy-iap-expiry-check \
  -e POSTGRES_HOST_AUTH_METHOD=trust public.ecr.aws/supabase/postgres:17.6.1.158
# Wait until PostgreSQL is ready, then:
python3 tool/iap_recovery/expiry/check.py
docker stop legendstudy-iap-expiry-check
```
Minimal local identity/grant stubs test this SQL contract, not full Essay or RLS
regression. Test inputs are synthetic. Tests are dated for the Oct23 recovery.
