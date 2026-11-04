# Unified support deployment package

**NOT APPLIED / NO PRODUCTION SEND.** Canonical status and decisions live in
[Wiki](../../../wiki/feedback-admin-integration-20261104.md).

1. Owner confirms `stlhijzpjfgwwdgunlsd` and captures `preflight.sql` privately.
   Compare the inquiry RPC definitions with `live_functions_baseline.sql`; abort on drift.
   `support_private` must not exist. Preserve exact worker/Web versions for rollback.
   Inspect any pending reply notifications; deployment may deliver that backlog. No test
   reply may be written to a real customer. Check no separate inquiry sender is active.
2. Owner applies **only** `../../migrations/20261104002306_unified_support_inquiries.sql`.
   The transaction adds nullable feedback FKs with XOR constraints, private status projection,
   9 public RPCs, 3 private helpers and one private view. No original inquiry INSERT/UPDATE.
   Existing Auth/Credit/Ledger/payment functions/tables are not changed.
3. Re-run preflight (source/child digests must match, excluding concurrent real traffic),
   then `postflight.sql`. All original IDs, member links and timestamps remain.
4. Deploy the updated existing `process-feedback-notifications` function after separate
   approval. Keep the existing cron and existing secret names/values; no extra scheduler.
   New reply queue shares the established Resend adapter. Provider failures only update
   the queue. Confirm actual configured sender and controlled TEST mailbox before a real
   provider E2E; synthetic tests intercept HTTP and never send email.
5. Apply [web.patch](web.patch) (commit `82a4aea6a0f604bfef5c5a853921d361ac8e9b02`) to the intended current WEB base and rerun tests/build.
   Deploy only after Owner approval. Do not use a stale whole build to replace concurrent work.
6. Integrate Native commit with current APP58 via review; run current APP checks and device QA.
   Native MY → 문의·건의사항 now shows 내 문의·답변. This requires an app release for existing
   installed clients; no automatic store deployment is included.
7. Operator real JWT: list/detail original feedback, verify APP/기능제안/original time and
   no reply, integrated total/open3 at audit baseline. Never use that customer as a fixture.
   Synthetic TEST: APP+WEB submit → admin reply → owner detail → email adapter → pending count.

## Rollback / failure containment

Do not delete, copy, or backfill originals. If frontend fails, restore only its previous
approved version while keeping additive DB and answers. `pause_writes.sql` is an exact,
non-destructive stop for new support writes (approval required). Reads remain available.
If email delivery must stop, restore the previous feedback-only worker; original intake
emails continue and reply queue rows remain for reconciliation. Re-enable with same reply
IDs/idempotency keys; Resend's finite deduplication retention means late uncertain sends
require review, not blind replay. Never delete outbox/replies to clear an error.

## Local validation

`bootstrap.sql` is **synthetic local-only** prerequisite schema; it is NOT a migration.
Use PostgreSQL17 on loopback port55441, fresh disposable DB. Apply bootstrap, existing
feedback migration20260917000100, live inquiry function baseline, admin_operator baseline,
and new migration. Create local roles anon/authenticated/service_role once (see bootstrap).
`python3 test_upgrade.py` recreates ONLY `legendstudy_support_upgrade_20261104`, applies
those prerequisites and checks 7 preservation assertions. Then `python3 test_local.py`
runs 34 checks and truncates synthetic inquiry fixtures in that hard-coded local DB. Do not point this harness at another server.
It tests actual SQL roles and production admin predicate with synthetic request claims;
it is not a real Supabase gateway JWT test. No auth/financial production changes are authorized.
