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
