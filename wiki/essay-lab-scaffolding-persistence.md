# Essay LAB Scaffolding Persistence — 1.3

2026-09-29 · IMPLEMENTED / ISOLATED RUNTIME VALIDATED / **PRODUCTION NOT APPLIED**.
Owner approved the [product contract](essay-lab-product-v1.md) and1.3-review.1 direction.
KEEP19; one new nullable column; no AI call, real student data, UI change or new table.
[Sanitized verification](../supabase/validation/essay_lab_product/scaffolding_result.json).
The pre-existing submit timing issue below remains OPEN and outside this extension.

## Migration and server boundary

[20260929000100](../supabase/migrations/20260929000100_essay_scaffolding_persistence.sql)
adds only `essay_improvement_progress.scaffolding_observation jsonb NULL` and its strict CHECK.
No backfill or change to existing PK/FK/RLS/ledger. Shape:
`{"version":1,"core_focus":true,"sentences":[]}`.
SQL NULL=legacy/not provided; supported empty array=no sentence observations on this task.
No root rows in a1.3 evaluation is a supported zero, not legacy missing output.

CHECK enforces exact envelope/sentence keys, types, version1, boolean focus, four categories,
four priority classes, integer offsets, nonblank text, optional nonblank example, array<=5 and
unique observation IDs/spans within the root. Finalize additionally enforces evaluation-wide
<=5 sentence observations, <=3 distinct active core tasks and exact core ordering via priority.
Same root may contain multiple different spans; never duplicate root per sentence.

Same public RPC signatures and caller grants. Explicit regimes `essay-v1.3` and
`essay-v1.3-next-model` select contract1.3/prompt `scaffolding-1.3-v1`. Default remains
`essay-v1.2`. The three original request/claim/finalize bodies are preserved byte-for-byte
under private legacy functions. Completed/in-flight1.2 jobs are not converted; their observation
column stays NULL. New private helpers have executor ownership/fixed empty search_path and
no EXECUTE for PUBLIC/anon/authenticated/service_role/worker/finance. No new public endpoint.
Worker direct table writes remain denied; existing fencing/lock/billing paths are retained.

## Snapshot and prior-task review

Request holds existing account→session→sorted grant locks, selects compatible completed earlier
attempts in the same session/question/regime with matching criterion/evidence versions, and freezes
`input_snapshot.scaffolding_context` plus its hash. It stores the selected previous evaluation,
latest compatible observations per root, original evaluation/attempt/hash, official references,
core/resolved IDs and previous title/diagnosis/action. Previously unassessed core tasks remain in
scope via their last actual observation. Legacy/incompatible/same-attempt assessments never become
invented rewrite growth. Later completion cannot move an already-requested snapshot.

Before recording new tasks, finalize requires a review of every snapshotted prior core. Assessed
outcomes append linked progress on the same root; recurrence requires a resolved predecessor.
Wrong owner/session/regime, unselected/newer/invalidated references and duplicate roots are rejected.
A fresh regime can independently observe the same root without pretending there was growth.

`not_assessable` writes **no progress status**. The immutable required-ID list minus assessed links
identifies unknown tasks; existing uncertainty_note preserves narrative reasons. Unknown is not
OPEN/UNCHANGED/RESOLVED. Neither progress nor input snapshot is retrospectively rewritten.

## Source validation and trusted local review

Source is evaluation→submitted attempt, not a client-provided answer or mutable draft. Finalize
checks body SHA256, input manifest hash and output source binding, then compares the exact UTF8
PostgreSQL character slice using Unicode code points [start,end). No trim, NFC or UTF16 conversion.
Emoji, decomposed Hangul and whitespace are preserved. A quote cannot be fabricated or borrowed
from a different source; matching text proves source presence, not the correctness of a critique.

Official criterion judgments retain allowed question evidence IDs and existing mapping rows.
Local sentence observations have no fake official reference. They require independent trusted
review of the exact issue/sentence payload. [Server-only adapter](../tool/essay_lab/scaffolding_adapter.py)
rejects a provider-supplied `local_reviews` field and requires separate review input; SQL checks
that approval matches the exact root and quotations. Wrong/absent approval fails closed.

This is an explicit **trusted worker/reviewer boundary**, not a SQL semantic classifier or a
cryptographic proof that a critique is true. The hosting worker must authenticate its review
source; it must never copy provider claim_scope into an approval automatically. That production
review workflow and pedagogic accuracy remain gates before real AI traffic. No credential,
provider call or reviewer UI was added. Normalized keys do not create permanent student weaknesses.
A resolved prior local issue may have no new sentence finding: require verified predecessor,
current immutable source and explicit review, never invent an error sentence to show resolution.

## Atomicity and deletion

The1.3 validator runs within the existing fenced finalization transaction. It prepares server-owned
observation envelopes, records progress/official evidence, completes the evaluation, and settles
billing together. Invalid fragments roll back all results; a settlement fault after result writes
also rolls back progress/dimensions and consume. Same run/payload retries remain idempotent.
All completion immutability and erasure guards apply to the new column. Learning erasure removes
observations; financial history survives under its existing retention rules.

## Actual validation and reproduction

| Executed check | Result |
|---|---|
| New scaffolding native matrix |80 PASS |
| New scaffolding actual JWT/PostgREST matrix |79 PASS |
| Existing native reference / server transactions |77 /55 PASS after migration |
| Existing JWT regression |37 PASS before and37 PASS after migration |
| Review / migration-security-adapter static tests |55 /27 PASS |
| Existing Flutter sentence/Workspace + analyze |27 PASS /PASS |



[Native runner](../supabase/validation/essay_lab_product/scaffolding_runtime.py) uses the existing
explicit-consent/numeric-loopback/empty `essay_review_*` PostgreSQL17 guard. It clean-applies the
forward migration, runs legacy77+55 checks, then the scaffolding matrix including concurrency.
[Supabase runner](../supabase/validation/essay_lab_product/scaffolding_supabase.py) first verifies a
new isolated local Docker project/port and empty public schema, runs37 JWT checks, creates and
claims a real1.2 job **before** the new migration, applies it, completes that in-flight result,
then repeats37 checks and the1.3 matrix through Auth-issued JWT/PostgREST. SQL role checks are
not reported as JWT tests. Worker JWTs are synthetic local role credentials, never client tokens.

Use a fresh dedicated environment, never the linked repository project:

- Native: private `ESSAY_REVIEW_TEST_DSN`, `ESSAY_REVIEW_DISPOSABLE=YES`; execute `scaffolding_runtime.py --native`.
- Supabase: new project ID `essay-review-*`, private chmod600 CLI status file; set
  `ESSAY_REVIEW_LOCAL_PROJECT_ID`, `ESSAY_REVIEW_SUPABASE_STATUS_FILE`, consent; run `scaffolding_supabase.py`.
- Python dependencies: psycopg[binary], pglast in a temporary venv. Native runner includes baseline setup;
  Supabase runner includes guarded preparation. Neither resets an existing database.
- Offline: `python -B -m unittest discover -s supabase/validation/essay_lab_product -p 'test_*.py'`.
- Shut down only these disposable environments afterward. No DSN/JWT/email/private answer in reports.

UI remains unchanged. Existing sentence/Workspace27 tests (including360px/200%) and analyze PASS;
this is regression evidence, not a new live UI persistence adapter. The review fragment contract
is preserved; [runtime contract](../tool/essay_lab/evidence/evaluation_contract_v1_3.json) specifies
RPC field mapping. Independent AI/pedagogy validation remains NOT_RUN.

## Existing submit timing issue — OPEN, not a scaffolding regression

Runtime exposed migration003's existing expression:
`least(d.active_writing_seconds, greatest(0, extract(epoch from now()-d.started_at)::int))`.
PostgreSQL LEAST ignores NULL; casting numeric to int rounds. At0.7s elapsed with unspecified
active time, this can produce1s and violate essay_attempts_check1 (`active <= elapsed`). No
scaffolding function changes this expression. Synthetic scaffolding fixtures explicitly report
0 active seconds; they do not simulate writing time. This limitation is not hidden as a full
unknown-time submission PASS.

A narrowly proposed NULL-preserving/floor correction was **rejected by automatic approval review**
as outside the approved scaffolding scope and conflicting with preserving1.2 behavior. No such
change was made. Owner was asked whether to authorize a separate fix. Until separately authorized,
retain the issue as a rollout prerequisite; do not weaken the CHECK or alter history to pass tests.

Next: Owner reviews runtime results and this open baseline issue → separately decides Production
persistence apply → separately authorizes Scaffolding AI Pilot. This task neither applies Production
nor enables real student/provider traffic.
