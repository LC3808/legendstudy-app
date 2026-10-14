# Disabled exam submission API — Owner approval requested

Target: LegendStudy `stlhijzpjfgwwdgunlsd` only.
SQL: `supabase/migrations/20261014023133_essay_exam_operating_api.sql`.
Do not apply until Owner explicitly approves this migration.

## Exact impact

- One private schema/table (`essay_exam_private.runs`), forced RLS, no student
  table privileges. Existing Registry IDs and all existing student records stay.
- Four worker-only RPCs: `essay_exam_preflight`, `essay_exam_submit`,
  `essay_exam_claim`, `essay_exam_finish`. No role membership changes.
- One authenticated owner-only `essay_exam_history` RPC shared by WEB/Native.
- Two currently absent Provider policy helpers, with an empty model policy.
  Existing Provider005 request/claim wrappers are NOT replaced.
- Credit reservations/settlements use the existing canonical Ledger. The SQL
  installation itself does not seed, reserve, debit, refund or grant Credit.
- One account-anonymization trigger removes only this new table's answer/result
  snapshots when an account is deleted, releasing pending exam reservations and
  preserving Ledger transactions. No existing History/Registry deletion occurs.
- No DROP/DELETE statement is executed during installation. DELETE appears only
  inside that future account-erasure trigger. No cascade or legacy table alteration
  apart from attaching this trigger to credit_accounts.
- Model and exam policies are null. Public activation remains HOLD; all exam
  submissions reject EXAM_NOT_ACTIVATED. Runtime deployment/rights/model approval
  and real Provider/Credit test permission are separate requirements.

## Verification (2026-10-14)

Read-only production audit: postgres is NOSUPERUSER+BYPASSRLS, owns the private
schemas, has existing Ledger table access, but cannot execute essay_private.hash.
The new policy validator therefore computes the identical built-in SHA256 without
expanding old function ACLs. No existing Math configuration/role/ACL changed.

Local PG17 loads canonical Ledger migrations and real account allowed/lock and
Math require_active function bodies. A synthetic deletion-request table and
Package fixture remain; this is not an actual complete account-deletion E2E.
The deployer is demoted to NOSUPERUSER+BYPASSRLS before API installation/use.
Verified: Package→existing ReviewedRuntimeWorker(fake Provider)→Ledger→History,
first one Credit, free rewrite, replay no extra dispatch, worker-only RPCs,
foreign-owner denial, active deletion blocks, telemetry/receipt redaction,
account erasure preserves Ledger, exact formal SQL installation, duplicate SQL
fails before changes, empty rollback, nonempty rollback refusal. All PASS.

Run: `PYTHONPATH=. python3 tool/test_essay_exam_credit.py --surface-only --pg-bin /opt/homebrew/opt/postgresql@17/bin`.
No production Provider or Credit call was made.

## Apply and postflight

Apply ONLY the named SQL through the approved Supabase migration tool. Do not run
bulk db push. Record its actual deployment timestamp; do not repair migration history.
Verify function owners/ACL, private table RLS, zero rows, null runtime/model policies,
unchanged existing function definitions and Registry76/234. Anonymous/student direct
submit must remain denied. No API exercise should reserve a real Credit yet.

## Rollback

`supabase/candidates/essay_exam_unit/api-rollback.sql` removes only an empty new
installation, with no CASCADE and no Ledger deletion. It refuses any nonempty runs.
After use, turn off gateway activation and forward-repair; never delete Ledger
rows or completed runs to force rollback. Existing Provider helpers were confirmed
absent; do not remove them if subsequently adopted by another feature.

## Remaining service work

Private persistent runtime deployment and independent SignedReview service;
reviewed Provider transmission rights and exact model policy; immutable historical
Package retrieval for changed-version rewrites; admin QA projection; approved real
Provider/Credit E2E and WEB/APP cross-read. This migration alone is not COMPLETE.
