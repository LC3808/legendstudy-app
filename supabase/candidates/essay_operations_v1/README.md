# Essay operations v1 — Owner approval candidate

**NOT APPLIED.** Only monitoring functions/configuration are new. No evaluation, Worker,
Credit, History or Auth function is replaced. Canonical design/testing record:
[Wiki](../../../wiki/essay-operations-monitoring.md).

## Apply gate

1. Verify target `stlhijzpjfgwwdgunlsd` (LegendStudy), branch/diff and obtain Owner SQL approval.
2. Run `precheck.sql` read-only. Stop if `essay_ops_private` exists, official admin gates
   differ, or source columns differ. This is a first-install script, not an upsert migration.
3. Capture existing deployment, run/checkpoint/ledger counts and selected-row hashes.
   Concurrent legitimate jobs can change global counts; do not interpret that as migration damage.
4. Run `install.sql` once, transactionally, then `postcheck.sql`. Never run local fixture scripts
   against production. Default prices: empty. Thresholds: NULL/disabled. No cron is installed.
5. With real JWTs verify official Owner/admin allowed, ordinary/blocked/guest denied;
   anon and service_role cannot execute. Verify safe report excludes answers/raw errors/secrets.
6. Run bounded EXPLAIN/latency checks on production-size data, inspect query timeout (8 seconds),
   compare readonly operational baseline. Deploy WEB only under separate Owner approval.
7. Verify `/admin/operations/` and existing admin links. No retry/evaluate/adjust-credit action.

## Server configuration

Prices are USD per million tokens with exact provider/model, effective interval,
cache rate and verified source. No invented current prices are seeded. Insert a new price
version after approval; UPDATE/DELETE is rejected. Overlapping matches do not auto-select.
New estimate capture requires call time, exact model, token counts and sufficient cache information.
Unknown cache is acceptable only for explicitly identical cached/noncached rates.
Capture stores call ID, immutable price ID, USD and recording time; repeated capture is idempotent.
Existing recorded estimates remain estimates, not invoice-confirmed actual charges.

Thresholds are server configuration, not client assertions. Units are stored per rule;
NULL disables the rule. Changes require the existing reviewed server configuration process.
`admin_essay_operations_check_alerts()` is an explicit administrator check; it evaluates
7 rules, serializes concurrent checks, creates one open alert per rule and records resolution.
There is **no unattended continuous monitoring** in this candidate. No external notifications.
Cost checks inspect known subtotal only; missing costs cannot prove the threshold is clear.

## Rollback

Disable/revert the WEB monitoring revision first, then run `rollback.sql` only if needed.
It drops the 3 new public RPCs, preserving all original operational data and new audit,
pricing, cost snapshots and alert history. No CASCADE; do not drop the private schema.
Reinstalling after rollback requires a reviewed function-only migration; do not rerun first install.

## Local verification (disposable PostgreSQL 17)

Create an empty database prefixed `task06_` on `127.0.0.1:55439`.
Run `local_fixture.sql`, `install.sql`, `local_test.sql` with psql `ON_ERROR_STOP=1`.
Then `python3 local_concurrency.py <database>` tests 8 concurrent alert checks and rollback.
The fixture's auth gates are synthetic. Real JWT acceptance remains a deployment gate.
Tests use invented model rates and synthetic rows; they are not pricing configuration.
