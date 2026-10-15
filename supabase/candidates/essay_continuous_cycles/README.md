# Continuous essay cycles — CANDIDATE / NOT APPLIED

Owner Oct15 authorizes code and local tests only. No Provider, production Credit,
DDL or execution-flag action is included. Apply only after separate approval.

## Exact change

`install.sql` adds two nullable columns to existing private runs:
`previous_paid_run_id` (self FK) and `submission_index`, one partial unique index,
and one insert trigger. Existing rows/answers/results are not updated. Adds two
worker-only RPCs: `essay_exam_submit_cycle` and `essay_exam_quote`. Replaces existing
`essay_exam_submit` only to preserve the cycle snapshot marker in a free child;
replaces `essay_exam_history` to expose cycle/sequence capability metadata.
No Ledger function, balance table, Math, Payment, IAP, RLS, source Package or
Provider contract changes. No additional table. Existing account erasure removes
runs; Ledger survives, checked in local lifecycle test.

Each additional paid run references its completed paid predecessor, same account,
exam and exact question set. Free child still references its own paid parent.
Existing reserve/finalize owns 1/0 Credit, 14 days from completion, idempotency,
lease fencing and refund behavior. Account row locking serializes sequence and
successor checks; failed paid successors release the slot. Submission index counts
real inserted submissions (including failures), independently of credit cycles.
Legacy records have no invented ordinal. History grouping is presentation only.

## Local verification

```
ESSAY_TEST_CONTINUOUS_CYCLES=1 PYTHONPATH=. python3 tool/test_essay_exam_credit.py --surface-only --pg-bin /opt/homebrew/opt/postgresql@17/bin
```

PASS: non-superuser deployment, worker-only APIs, initial1/free0 preserved,
additional1/free0, four simultaneous identical keys produce one reservation,
second distinct paid successor denied, failed reservation release/retry, free
reuse rejection, server quote, immutable sequence, account erasure, install
replay refusal, rollback after empty lifecycle. Synthetic PostgreSQL/Provider
transport only. This is NOT an operating E2E or quality approval.

## Before any authorized operation

Compare current production submit/history definitions with the baseline in
`rollback.sql` and this candidate. Stop on unreviewed drift. Capture function
ACLs, table counts and run IDs; review final diff. Execute install once in a
transaction; verify columns/index/trigger and worker-only EXECUTE. Existing rows
must retain original values and null new metadata. Keep all execution flags OFF.
No test Credit purchase/reservation is needed to verify installation.

LAB additional path also requires `ESSAY_CONTINUOUS_CYCLES_ENABLED=true`; default
is OFF. General execution gate and existing account/test restrictions remain.
Quote is read-only but requires the existing authenticated worker gateway.
APP/WEB fail closed if quote RPC is absent. Deployment must be coordinated with
approved DB installation; do not deploy this client change as live activation.

## Rollback

`rollback.sql` restores exact baseline submit/history and drops ONLY new objects
and columns. It refuses when any indexed submission exists, preventing loss of
lineage. Once used, turn execution OFF and prepare a reviewed forward repair;
do not delete runs, Ledger, answer or evaluation history to force rollback.
