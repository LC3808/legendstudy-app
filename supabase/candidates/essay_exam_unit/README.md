# Latest Oct14 status

The disabled API subset is now formal SQL20261014023133, tested under the verified
NOSUPERUSER+BYPASSRLS deployment context with actual lifecycle function bodies.
See [approval review](../../reviews/essay-exam-operating-api/README.md).
It is NOT applied or activated. Historical candidate notes below remain for context;
covered ownership/lifecycle-body gaps are superseded, not actual service E2E.

# Exam-unit atomic billing candidate — NOT DEPLOYABLE

Oct12 continuation of the existing LAB `exam-unit.ts` contract and storage
rehearsal. This is local implementation evidence, not approval-ready migration,
not Production SQL, and not an enabled service. Do not `db push` this directory.

## Implemented and locally exercised

- One existing `credit_accounts` lock serializes both retries and different keys.
- The original `essay_billing_decisions` / `credit_transactions` tables and
  triggers are reused unchanged. A nullable legacy evaluation link is left null;
  the private exam run links its decision. No fake per-question evaluation exists.
- One selected question bundle reserves one Credit; only a complete result settles
  it. A partial result cannot consume. Late persistence failure rolls back both
  the posting and decision. Confirmed failure releases the reservation once.
- Initial/independent submissions remain separate roots. One active/successful
  included rewrite per initial run, exact frozen subset and version pins, 14 days,
  no extra Credit. A failed rewrite remains in history and can be retried.
- Terminal runs cannot be edited. Idempotency payload conflicts are rejected.
- No exposed RPC or role grant. All API roles denied; forced RLS, no policies.

`tool/test_essay_exam_credit.py --pg-bin /opt/homebrew/opt/postgresql@17/bin`
creates a disposable local PostgreSQL17 Unix-socket instance and loads the actual
canonical legacy migration prerequisites. It accepts no remote DSN. Fixtures use
existing signup provisioning; concurrency uses separate database sessions.
The test owner is a local superuser: **this does not prove deployer ownership or
production lifecycle/authorization integration**. Validation JSON has no student
content or production identities.

## Runtime reuse

`tool/essay_lab/exam_runtime.py` feeds the existing `ReviewedRuntimeWorker` through
an exam question staging channel. Existing prompt, output validation, Provider
identity/permit and independent review remain. Child success never calls legacy
per-question settlement. Only a complete exam checkpoint reaches exam finalization.
Unknown outcomes remain reconciling; no automatic refund or second Provider call.
Completed child checkpoints can be restored with an exact frozen-claim hash;
pending/unknown children remain reconciling without another Provider call. The
trusted persistent store must supply these checkpoints; this is not an exposed API.
Whole-exam synthesis must be supplied by a reviewed implementation; no invented
summary fallback. Tests use fake transport, not real Provider acceptance.

## Remaining before promotion (development, not merely Owner approval)

1. Canonical source→exam/question mapping and reviewed initial Rubric/evidence
   authority, allowed assessment type and Provider-material rights. SQL membership
   validation does not replace these. Source registry keys are not DB UUIDs.
2. Auth/Allowlist/lifecycle locking, least-privilege execution roles, deployment
   topology, Worker lease fencing, durable per-question journal and interrupted
   child/synthesis recovery. Current helpers are private invokers, not a public API.
3. Shared server Draft, owner history and existing operator QA read adapters,
   review retention and account erasure of new answer snapshots. Never grant an
   API role access directly to this private storage as a shortcut.
4. Exam-wide reviewed synthesis and current result adapters; Native/Web submit
   routing. Native `exam_unit.dart` and WEB `exam-unit.ts` have matching synthetic
   snapshot/hash fixtures, but they are not mounted to Production submission.
5. Full existing-schema/lifecycle/Math installation regression under the real
   non-superuser owner model, production read-only fingerprint preflight, and a
   formally generated migration + exact apply/rollback review.
6. Separately authorized production apply, test-account Provider/Credit E2E.

## Impact and rollback

Candidate adds one private schema/table, three private functions and indexes;
changes no legacy function, table, role grant, evaluation, answer, History, RLS
policy, Payment/Toss/IAP or Math engine. It performs no initial seed/backfill.
If ever installed and used, new immutable private snapshots contain student
answers; retention/erasure integration is a release blocker, not optional cleanup.

`rollback.sql` removes only an empty installation and has no CASCADE. Nonempty
rollback is rejected. Once runs or postings exist, use a reviewed forward repair;
never delete runs or ledger rows to force rollback. Tests verify legacy function
fingerprints across installation/rollback and a rejected nonempty rollback.


## Oct13 persistent runtime connection — local verified

`tool/essay_lab/durable_exam.py` now composes the existing ReviewedRuntimeWorker,
ExamQuestionChannel and DurableJournal. A run lock serializes processes; immutable
owner/exam/question/claim digests prevent changed-input replay. Each child intent,
reviewed output, synthesis intent/result and whole-exam finalization are persisted.
Completed children and an ambiguous settlement replay without another Provider call.
Unknown child/synthesis stays reconciling; no guessed refund/retry. Existing review,
provider validation and final result schema remain unchanged.

Local actual PostgreSQL Ledger composition verifies settlement committed before a
lost response, exact retry without another debit/Provider dispatch, and included
rewrite with zero additional Credit.14 local database scenarios PASS. Durable
runtime tests include8 competing processes and restart between review/child success.
Synthetic Provider/reviewer only; this is NOT actual service E2E.

Host authorization is still a trusted required callback. The production owner/
lifecycle/lease checks, deployment, deletion/retention, approved synthesis/reviewer
and RPC composition remain release blockers. This single-host journal is not a
multi-host database lease. No SQL/grant/migration was added or applied by this step.

## Oct14 reviewed material execution — local only

`execute_reviewed_material_exam` in the existing material adapter now composes
reviewed Package loading with DurableExamRunner and ReviewedRuntimeWorker directly.
It requires server-owned frozen claims, exact Package version/evidence/criteria,
explicit activation and Provider rights. All selected questions are checked before
dispatch. Single-question summary is the reviewed existing summary; multi-question
synthesis remains an explicit required dependency. Canonical identity is sent with
the frozen evidence. No per-question financial finalizer is used.

Five targeted integration scenarios plus related worker/material/durability tests
passed (44 total). Provider transport and independent reviewer are synthetic test
fixtures, NOT operational E2E. The production deployment blockers above still apply.
No migration or grant is authorized by this local implementation.

## Oct14 shared operating API composition — LOCAL ONLY

New files: `provider-policy.sql` (only two existing Provider005 policy helpers;
no old request/claim override), `api.sql` (preflight/submit/claim/finish/History),
`api-rollback.sql` (full empty candidate removal). Install order on disposable DB:
existing Ledger prerequisites → install.sql → provider-policy.sql → api.sql.
The deployment-owned runtime/model policies are empty, so no exam is activated.

The verified gateway checks Auth online and the existing allowlist, then forwards
only its verified subject to worker-only RPCs. Account lifecycle lock precedes the
credit-account lock. A single immutable dispatch lease prevents another dispatch;
expired leases do not authorize Provider retry. Only a persisted reviewed final
checkpoint can settle using the original immutable lease after expiry. Lost/unknown
Provider work stays reconciliation-required, never automatic refund/redispatch.

WEB/Native use the same endpoint, server reservation, owner History and existing
result views. Selected question set is fixed by the existing reserve contract.
Rewrite revisions derive from the stored parent (platform Draft counters are not
server revision authority). Images are not silently dropped: this first text bundle
rejects image answers; the existing Math image path remains unchanged.

Existing durable per-question Provider telemetry is copied into the private stored
result at settlement; user History strips telemetry and independent-review receipts.
The legacy per-question telemetry RPC remains absent in Production and is not
invoked by this exam channel. No second billing event is created per question.
Account anonymization releases pending reservations and removes private answer/result
runs, retaining all canonical Ledger transactions. This trigger is NOT applied.

Local surface-only test uses actual canonical Ledger tables, candidate RPCs,
ReviewedRuntimeWorker and fake Provider transport. It checks one dispatch on replay,
one Credit, included rewrite with cross-platform revision0, owner isolation,
worker-only ACL, receipt redaction, nonempty rollback denial and empty rollback.
Lifecycle/Package lookups are explicit synthetic fixtures: this does not prove
Production deletion workflow, deployment ownership, actual Provider, or user E2E.

Remaining before production approval: full deployed lifecycle/ownership review,
admin Quality Console projection, immutable old Package availability for rewrite,
private host plus independent review service deployment, reviewed content rights and
approved model entry. Do not promote this directory by wholesale migration push.
Only the separate Worker gateway-role migration is currently approval-ready.

Rollback after real use must be forward repair; `api-rollback.sql` refuses nonempty
runs and never removes Ledger records. Provider helpers may only be removed by this
rollback when created from this candidate and unused by other deployed features.
