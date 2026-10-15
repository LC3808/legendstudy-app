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

## Oct15 final operating preparation

**LOCAL TEST PASS / production NOT_APPLIED; approval pending.** Hosted IAP TEST
was not modified. This verification uses disposable PostgreSQL17 with canonical
Ledger DDL, NOSUPERUSER deployment, synthetic accounts and fake Provider transport.
No real Provider call or real Credit transaction. No SQL body change in install.sql.

Final runs:
- `ESSAY_TEST_CONTINUOUS_CYCLES=1 ESSAY_ASYNC_TEST=1 PYTHONPATH=. python3 tool/test_essay_exam_credit.py --surface-only --pg-bin /opt/homebrew/opt/postgresql@17/bin`
- `PYTHONPATH=. python3 tool/test_essay_exam_credit.py --pg-bin /opt/homebrew/opt/postgresql@17/bin` (14 regression groups)
- Added distinct-key concurrent successor check (one winner; losers blocked by
  successor or available-balance guard), pre/postflight SQL execution, read-only
  quote and denied roles/duplicate question sets; existing run snapshots/results
  fingerprint unchanged on install. Async review fixture corrected to awaitable;
  no runtime or Prompt change. Lost-finalize recovery uses stored checkpoint.

Production read-only observation: Registry234, runs2, Ledger31, material revisions17.
Existing submit/history bodies exactly match rollback baseline hashes in preflight.
Private reserve/finish bodies remain the baseline. New two RPCs are absent.
These counts are observations, not permanent assertions against unrelated activity.

### Owner execution after separate approval

1. Keep essay execution and continuous-cycle flags OFF; no Provider/Credit tests.
2. Run `preflight.sql`; compare four body hashes and ACLs with the recorded baseline.
   Stop on drift. Submit: postgres+essay_worker; History: postgres+authenticated;
   private reserve/finish: postgres only. New RPCs/columns must be absent.
3. Save `preservation.sql` results (counts/digests only; no student text exported).
4. Run **only `install.sql`**, once, as SQL Editor deployer. It is transactional;
   rerun is rejected. No DELETE/DROP/TRUNCATE or existing-row UPDATE in install.
5. Run `postflight.sql` and repeat `preservation.sql`. All original fingerprints
   must match within the no-submission window. Two new columns nullable, new-cycle
   count0; two new RPCs execute only for essay_worker. No flags changed by SQL.
6. Keep HOLD; operating invocation needs separate restricted E2E approval.

Rollback before any new submission: `rollback.sql`, then `preflight.sql` and
`preservation.sql`. It drops only the new RPCs/trigger/index/columns and restores
old submit/history; it does not delete rows. After any new submission, rollback
intentionally refuses. Turn execution OFF and prepare forward repair instead.

Quote contract: version essay-exam-quote-v1, credits1/0, kind initial/included/additional,
canonical sorted question_ids. It performs no reserve/settle; it is not a guarantee
of later balance or free-slot availability. Submit revalidates atomically.
Additional submit requires completed owned paid predecessor with identical exam/set;
its free child uses existing submit with p_parent. Existing finish/lease/recovery and
Ledger functions are unchanged. History only adds metadata; old rows remain null.

Approval requested only for the described inactive DB installation, not flag
activation, hosted TEST credit postings, Provider calls or production Credit trades.
