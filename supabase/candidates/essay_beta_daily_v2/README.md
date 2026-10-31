# Daily beta v2 — Owner application candidate

**NOT installed or activated in Production.** Owner confirmed use through 2026-11-10; exclusive cutoff is `2026-11-11T00:00:00+09:00` (`2026-11-10T15:00:00Z`). One humanities exam credit/account/KST date, no rollover. Canonical policy and evidence: [Unified Wiki](../../../wiki/essay-beta-daily-v2.md).

## Verified baseline and change

Production read-only catalog inspection on 2026-10-31 found the old beta functions installed, no campaigns and no daily grants. `baseline.json` contains the eight actual definitions, owner and ACL, not secrets. File presence is not proof of deployment. Existing exam reserve/finish and append-only credit transactions are reused; no parallel monetary ledger. `credit_summary` excludes beta so signup/purchased balances remain separate. Worker/Provider code is unchanged.

## Apply only after Owner approval

1. Review `precheck.sql` read-only checks against current Production. Any definition/ACL/history mismatch stops this candidate; do not bypass it. Capture deployment baseline and ledger/run hashes read-only before applying.
2. Apply `install.sql` once. It is a transaction guarded by the same baseline checks. It installs v2 RPCs and cutoff-aware quote/history/reserve but creates **no active campaign and no grant**. Re-running is not idempotent: new definitions deliberately fail the old-baseline guard.
3. Run `verify.sql` (read-only). Compare all 15 function definitions/owners/ACLs to the reviewed manifest. Confirm fixed search paths and SECURITY DEFINER as expected. New public RPCs are authenticated-only, auth.uid-bound; anonymous/service_role cannot invoke them. Direct private tables/helpers have no client grants.
4. Prepare APP/WEB versions using `essay_beta_daily_claim_v2` and the new policy. Old v1 RPC is a compatibility adapter, NOT proof that old 2/day copy is updated. Resolve supported-client rollout before activation. TASK 01 notices SQL must be approved/applied separately; publish the reviewed `beta-notice.md` via the existing admin UI, both channels/public, covering the beta period. Do not insert a second notice store.
5. Review actual humanities runtime policies and canonical question IDs. Fill **all** placeholders in `activate.sql`: Owner admin UUID, published beta notice UUID, approval reference, explicit starts_on, approved exam/question scope. The script rejects blanks, non-admin actors, unpublished/expired/wrong-channel notices, prior campaigns and unsupported/non-humanities/math scopes. It verifies the real runtime question set; the placeholder fixture IDs are not Production targets.
6. Owner applies reviewed `activate.sql` only after those checks. It configures a campaign/scope; it does not mint credits or submit an evaluation. Then run `verify.sql` and read-only campaign/scope checks. A signed-in user's subsequent LAB visit claims that day's allowance. **Do not call the claim RPC in Production merely to verify installation**: that is a grant write.
7. Verify one approved real-user journey only under separate execution authorization; none was performed here. Production activation is not inferred from unit tests.

## Recovery/rollback

`rollback.sql` is an emergency **disable** transaction, not an install step. It stops new beta issuance/selection; preserve functions, binding/cutoff, ledger, runs, completed checkpoints and pending accepted revisions. Existing accepted evaluations may finish via the existing finish contract. Never delete grants/transactions or restore the old unscoped allocator after issuance. A fully failed exam releases its reservation once; a partially failed exam remains reserved for failed-question retry. A release after the original grant's midnight expiry does not become a new day's balance. No manual refund is part of this package. Backward schema/function restoration after issuance requires separate review.

## Local verification

`build.py` regenerates install/precheck/rollback from the verified baseline and exact substitutions; it asserts the finish and Provider contracts remain untouched. `verify.sql` uses canonical PostgreSQL definitions in `expected-functions.json` captured from the isolated install (before test clock replacement).

`test_runtime.py` is fixed to disposable PostgreSQL 17, 127.0.0.1:55439, database `beta_v2_test`. Start a dedicated temporary cluster yourself, create that disposable DB, then run `python3 supabase/candidates/essay_beta_daily_v2/test_runtime.py`. It resets fixture schemas in that DB, uses actual captured SQL functions plus synthetic identities/snapshots/preflight/runtime policies and a controlled clock, and does not connect to Production or call a Provider. Requires existing tracked admin-credit, old-beta and notices fixtures. Do not point it at another DB. 33 assertion groups passed, including 60 concurrent claims, 30 distinct reservations and 30 terminal-failure callbacks. This is DB-contract concurrency, not actual device/Provider integration.
