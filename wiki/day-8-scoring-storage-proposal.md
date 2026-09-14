# Day 8-D — Scoring storage / migration proposal

Status: **PROPOSAL ONLY / NOT APPLIED**. Reviewed2026-09-14.
This is a concrete relational/transaction contract, not copy-ready production SQL.
No new file in supabase/migrations and no applied migration edited. The approved
proposal will become a separate executable8-D1 migration with full function bodies,
preflight/postflight/rollback SQL and offline PostgreSQL tests before Owner execution.
Product/UX rationale: [Scoring v1](mock-exam-scoring-v1.md).

## Baseline and parent integrity

Actual initial migration: exams PK content_item_id; exam_subjects PK id,
UNIQUE(id,content_item_id), FK content_item_id -> exams; resources composite
(exam_subject_id,content_item_id) -> exam_subjects. Scoring's canonical parent is the
**occurrence**, not subjects taxonomy, free-text Study subject or resource UUID.
New key header uses that same composite FK ON DELETE RESTRICT. No copied exam table.

Current Study has id PK, user_id default auth.uid() -> auth.users ON DELETE CASCADE,
mode study/mock_exam, immutable client INSERT/SELECT/DELETE, generated duration.
New proposal adds only UNIQUE(id,user_id) to support an owner-safe composite FK;
no new Study column or change to duration/RLS/grants. This additive index and new
scoring objects still require a future approved migration. Profiles/NEIS/D-Day,
content/exams/resources and applied migrations remain unchanged.

## Five proposed tables

All identifiers UUID unless stated. All instants finite timestamptz in UTC; no KST
wall-clock strings. KST stays display/Study aggregate logic. Names below are proposed,
not existing production columns. Text bounds are product limits; use trimmed values.

### 1. answer_key_versions

| Column | Type/nullability | Constraint/meaning |
|---|---|---|
| id | uuid PK | generated UUID |
| exam_subject_id, content_item_id | uuid NOT NULL | composite FK -> exam_subjects(id,content_item_id), DELETE RESTRICT |
| paper_variant | text NOT NULL | trimmed1..80; reviewed stable booklet/elective code, never inferred |
| version | integer NOT NULL | >0; UNIQUE(exam_subject_id,paper_variant,version) |
| status | text NOT NULL | draft/published/withdrawn |
| is_current | boolean NOT NULL default false | implies status=published; partial UNIQUE(exam_subject_id,paper_variant) WHERE is_current |
| question_count | smallint NOT NULL | 1..100 |
| total_points | integer NOT NULL | 1..1000; must equal sum of child points at publication |
| source_name, source_url | text NOT NULL | name1..200, URL1..2048 HTTP(S), no credential/userinfo; operator-verified origin |
| source_digest | text NOT NULL | 64 lowercase hex SHA256 of source artifact |
| points_source_name, points_source_url, points_source_digest | text nullable triple | all NULL or all present, same limits; required when points come from a separate document |
| content_digest | text NULL until published | SHA256 of canonical typed question payload/header scope; server computes |
| fetched_at, created_at | timestamptz NOT NULL | observation and server create time respectively |
| verified_at, published_at | timestamptz NULL | required for published/withdrawn; verified<=published |
| corrected_at, correction_note | timestamptz/text NULL | both NULL or both present; note1..1000; source correction timestamp, not every new version |

Publish requires complete question set, validated scope/source and content hash.
Immutable after first published_at: parent/variant/version/questions/points/source/
hash/verification evidence. Only status/current may change via trusted publication
workflow. Current switch locks the family and atomically demotes old current before
promoting new. Superseded keys remain published but not current; withdrawn has no
new-public access. No deletion of any once-published header/questions. No mutable
`updated_at` substitute for answer version.

### 2. exam_questions

| Column | Type/nullability | Constraint/meaning |
|---|---|---|
| answer_key_version_id | uuid NOT NULL | FK header ON DELETE RESTRICT |
| question_number | smallint NOT NULL | 1..100; composite PK(answer_key_version_id,question_number) |
| question_type | text NOT NULL | v1 CHECK='single_choice' |
| correct_choice | smallint NOT NULL | 1..5 |
| points | smallint NOT NULL | 1..100, actual item points |

Numbering must exactly equal1..header.question_count on publication. No independent
mutable question identity shared across key versions; small versioned row sets avoid
an extra question-bank abstraction. Future numeric/multiple-answer types require
explicit typed columns/constraints/engine version, not arbitrary JSON answers.

### 3. grade_cutoff_versions

| Column | Type/nullability | Constraint/meaning |
|---|---|---|
| id | uuid PK | generated UUID |
| answer_key_version_id | uuid NOT NULL | FK header ON DELETE RESTRICT; exact paper/cohort/total scope |
| version | integer NOT NULL | >0; UNIQUE(answer_key_version_id,version) |
| status, is_current | text/boolean NOT NULL | draft/published/withdrawn; current implies published; partial UNIQUE(key_id) WHERE is_current |
| basis | text NOT NULL | raw_absolute or raw_estimate |
| certainty | text NOT NULL | confirmed or estimated; CHECK matches basis as below |
| minimum_scores | smallint[] NOT NULL | exactly9 non-NULL integer thresholds, array lower bound1 |
| source_name, source_url, source_digest | text NOT NULL | same shape/limits as key provenance |
| content_digest | text NULL until published | server-computed canonical grade-package SHA256 |
| fetched_at, created_at | timestamptz NOT NULL | observation/server time |
| verified_at, published_at | timestamptz NULL | required for published/withdrawn |
| corrected_at, correction_note | nullable pair | same correction semantics/limits as keys |

One ordered array stores the nine grade rows to avoid a sixth table. Index1 is
minimum raw score for grade1, through index9 for grade9. Pure immutable array helper
CHECK: one dimension/lower1/length9/noNULL/nonnegative/strictly descending/last0.
Publication additionally checks every threshold<=key.total_points and9 full bands.
Grade = smallest grade whose minimum <= rawScore; intervals include lower endpoint.
No division/rounding/percentile approximation. Grade0 invalid; scores0..total covered.

CHECK (basis='raw_absolute' AND certainty='confirmed') OR
(basis='raw_estimate' AND certainty='estimated'). This v1 projection cannot store a
standard-score threshold as if it were raw. Confirmed source data requiring unknown
score transformations stays private review evidence, not a usable confirmed grade.
Absolute rules are explicitly verified for this exam/subject/year. One current rule
per key; selecting competing estimates requires operator review, not random source
priority. Published values/source immutable, same correction/withdrawal protocol.
Also UNIQUE(id,answer_key_version_id) for attempt's same-key FK.

### 4. mock_exam_attempts

| Column | Type/nullability | Constraint/meaning |
|---|---|---|
| id | uuid PK | client-generated idempotency token validated by submission RPC |
| user_id | uuid NOT NULL | RPC derives auth.uid(); FK auth.users ON DELETE CASCADE |
| study_session_id | uuid NULL | composite FK(study_session_id,user_id) -> study_sessions(id,user_id), MATCH SIMPLE, ON DELETE CASCADE |
| answer_key_version_id | uuid NOT NULL | FK key ON DELETE RESTRICT |
| grade_cutoff_version_id | uuid NULL | composite FK(cutoff_id,key_id) -> grade_cutoff_versions(id,answer_key_version_id), DELETE RESTRICT |
| scoring_version | text NOT NULL | initial allowlist mcq5-v1; computed via versioned server engine dispatch |
| submitted_at | timestamptz NOT NULL | server receipt time; not proof of real timed completion |
| raw_score, total_possible | integer NOT NULL | 0<=raw<=total; total1..1000; server-derived |
| question_count, correct_count, unanswered_count | smallint NOT NULL | question1..100; counts>=0; correct+unanswered<=question |
| grade | smallint NULL | 1..9 when present |
| grade_status | text NOT NULL | none/estimated/confirmed |
| request_digest | text NOT NULL | server SHA256 of normalized input incl pinned versions/session/answers |

CHECK grade NULL iff grade_status=none iff cutoff_id NULL. If present, grade status
must equal the referenced cutoff certainty (transaction validator, not a cross-table
CHECK). All fields immutable after insertion. UNIQUE(study_session_id) allows multiple
NULLs and one result per linked Study session. UNIQUE(id,answer_key_version_id) for
answer FK. Linked session must be same owner's mode=mock_exam (write trigger/RPC
check under lock). Null link permitted for <1s time with no Study record; it does not
create artificial time. Study subject/title cannot prove an exam identity; the pinned
key selected at setup is the authoritative scoring scope, not anti-cheat evidence.

### 5. mock_exam_answers

| Column | Type/nullability | Constraint/meaning |
|---|---|---|
| attempt_id, question_number | uuid/smallint NOT NULL | composite PK; question1..100 |
| answer_key_version_id | uuid NOT NULL | (attempt_id,key_id) FK -> attempts(id,key_id) DELETE CASCADE; (key_id,question_number) FK -> exam_questions DELETE RESTRICT |
| submitted_choice | smallint NULL | NULL=unanswered; otherwise1..5 |
| correct_choice_snapshot | smallint NOT NULL | 1..5; copied only by trusted scorer |
| points_snapshot | smallint NOT NULL | 1..100; copied only by trusted scorer |
| is_correct | boolean GENERATED STORED | coalesce(submitted_choice=correct_choice_snapshot,false) |
| awarded_points | integer GENERATED STORED | CASE WHEN matching THEN points_snapshot ELSE0 END |

Persist one answer row per question, including unanswered, atomically with attempt.
Snapshots allow private result review even after public key withdrawal. Server-only
insert validates snapshots against the pinned immutable key. Clients cannot send
snapshots/correctness/awarded values. Deferred attempt-total validator checks answer
count, all question numbers, sum awarded/raw, sum points/total and counts at commit.
It also compares correct-choice/points snapshots against key rows and grade against
the pinned threshold function. Cascade deletion skips this aggregate check only
when the parent attempt no longer exists. This prevents partial or independently
inconsistent result rows. No generic response
JSON engine; RPC may transport a bounded list of typed question_number/choice pairs.

## Checks that require transactions/triggers

PostgreSQL CHECK cannot enforce child sums/publication completeness via table reads.
Executable8-D1 must include actual functions/triggers, not claim a prose rule is DB
integrity. Required:

1. Immutable pure threshold-shape function (IMMUTABLE, SECURITY INVOKER, fixed empty
   search_path). Checks array shape/order only, never queries another table.
2. Header publication guard locks parent/family and validates contiguous questions,
   count/sum/hash, provenance, supported type and active existing exam/occurrence.
   Published-child edits/deletes and published-header content changes are rejected,
   including trusted ordinary DML. Deferred triggers prevent publish/edit races.
3. Cutoff publication guard checks same key, score-scale limits and all9 bands;
   immutable-after-publication guard applies even to a superseded/withdrawn row.
4. Attempt insert guard checks session owner/mode, exact key/cutoff compatibility and
   lifecycle at submission. Deferred answer/header-total guard rejects partial data.
5. Completed attempt/answer UPDATE rejected; only approved owner DELETE path allowed.
   Child deletion happens via whole-attempt cascade, not a public single-answer DELETE.

RPC/publication functions that write are VOLATILE. Any SECURITY DEFINER routine must
use fixed search_path='', qualified object names, no dynamic SQL, explicit auth.uid()
checks, exact output projection and narrowly audited owner privileges. Revoke default
PUBLIC EXECUTE before granting. No service-role token in Flutter or SQL examples.

## Submission and reads (proposed interfaces)

- Public bounded SELECT manifest of current published key packages for active
  occurrence/content; exact selected version fetch of published key/questions/cutoff.
  All submitted typed payloads capped at100 entries; no arbitrary query/SQL fragments.
- `submit_mock_attempt(attempt_id, study_session_id?, answer_key_version_id,
  grade_cutoff_version_id?, scoring_version, answers)` authenticated-only atomic RPC.
  Derive user, validate engine/key/status and reject unknown/duplicate numbers or
  out-of-range choices. Missing listed question becomes explicit NULL row. Caller
  supplied score/grade/owner/time/result fields are forbidden, not ignored.
- Lock versions against withdrawal during recomputation. Superseded published pinned
  versions remain valid; no silent upgrade. A withdrawn pinned package returns safe
  KEY_WITHDRAWN/CUTOFF_WITHDRAWN, retaining local result/time and requiring explicit
  review/recovery. Old identical retry of an already committed attempt returns that
  same immutable result even after withdrawal; do idempotency lookup first.
- Retry: same owner+id+canonical request digest returns prior result; different
  payload/id collision fails. Server also compares canonical typed request fields,
  not client-supplied hash. Concurrent insert converges through UUID uniqueness and
  transaction retry; no UPDATE result on conflict. Cross-owner IDs return a generic
  conflict/not-found response without row details. Different id on same session fails.
- `fetch_own_mock_attempt(id)` derives owner first; returns own result/answers and
  narrowly selected source/version metadata even if public parent/key is hidden.
  It never grants public access to withdrawn keys. History SELECT is owner-only,
  bounded keyset(submitted_at,id), detail query max100 answers.

No scoring availability boolean is added to exams; it is derived from reviewed
published packages and app engine support. No user data in public projections.
Public key access is deliberate for offline/Guest practice, not an exam security flaw
we pretend to prevent. Running UI hides answers; backend secrecy is not promised.

## RLS, grants and indexes

ENABLE RLS on all five new tables; REVOKE ALL from PUBLIC/anon/authenticated before
explicit grants. Default deny. Existing table policies/service_role grants unchanged.

| Relation/function | anon | authenticated | trusted publisher/scorer |
|---|---|---|---|
| key headers/questions/cutoffs | SELECT explicit public columns, published + active occurrence/content only; questions/cutoffs also require a published parent key | same | reviewed publish path, no direct client writes |
| attempts | none | owner SELECT/DELETE only | RPC derives owner, server-computed INSERT |
| answers | none | SELECT only via EXISTS own attempt | atomic insert; cascade deletion only |
| submit/fetch-own RPC | no EXECUTE | EXECUTE with explicit session check | limited function owner privileges |
| publication routines | none | none | backend-only; no app role grant |
| quarantine/raw evidence | none | none | existing backend-only contract |

Public column lists include version, scope, question/points and safe provenance;
exclude internal reviewer notes/raw evidence. Attempts RLS uses auth.uid()=user_id;
answers RLS uses EXISTS attempt with matching key and owner. No recursive policy
from attempts back into answers. Public key policy depends only on existing public
occurrence/content, never on private attempts; special own-result metadata retrieval
uses the narrow owner RPC. No new profile grants, no anon personal data access.

Indexes beyond PK/UNIQUE:
- attempts(user_id,submitted_at DESC,id DESC): owner history page.
- attempts(answer_key_version_id) and attempts(grade_cutoff_version_id) WHERE NOT NULL:
  FK/reference checks and correction-impact lookup; do not expose that lookup publicly.
- Unique indexes already cover key family/current, questions by version/number,
  cutoff by key/current, answers by attempt/number. Add answers(key_id,question_number)
  only if FK maintenance plans demonstrate need; immutable key rows aren't deleted.
- Study UNIQUE(id,user_id) supports the owner-safe FK; redundant to id for uniqueness
  but required for the composite reference. No GIN/JSON/full-text/score leaderboard index.

## Migration, rollback and acceptance gate

New executable migration is required for five tables, functions/triggers/RPC,
policies/grants/indexes and the additive Study unique constraint. Timestamp follows
existing naming convention when8-D1 package is prepared. **No runnable migration
filename assigned or production DDL executed in this design task.**

Preflight read-only plan: catalog-check exact existing PK/FK/RLS/grants and absence
of proposed object names; baseline counts/digests for profiles/content/Study and
all existing contract checks. Do not assume DB equals Git; current production facts
are Owner reports. No service-role credentials printed. Empty content is not a
scoring-ready dataset. Owner reviews migration/rollback before applying it.

Postflight: five table columns/constraints/function properties, RLS/grants, published
visibility, expected indexes and unchanged existing row digests. Test validators
inside disposable local PostgreSQL transactions first; no malformed production keys.

Rollback plan (future exact SQL accompanies final object names):
1. Disable new scoring client entry/worker first; retain 8-C timer-only behavior.
2. If any attempts exist, obtain approved export/retention plan before dropping
   personal data; preferably withdraw current packages and leave immutable history.
3. For empty/test-only migration rollback: revoke new RPC access; drop submit/read/
   publication entry points, drop their triggers before dependent trigger functions,
   then answers -> attempts -> cutoffs ->
   questions -> key headers; drop helper and only the new Study composite unique.
4. Use explicit objects, no DROP CASCADE against existing schema. Leave quarantine,
   all existing Study rows, profiles, content/resources and applied migrations intact.
   Never rewrite applied migration history to pretend rollback was not needed.

Offline/engine fixtures: full correct/incorrect/blank, mixed points, malformed/duplicate/
missing questions, invalid choices/types, wrong total,80/40 display labels, withdrawn/
corrected versions, stale engine, no cutoff, estimated/confirmed, every threshold±1,
maximum/zero score. Dart and server must agree byte-for-byte on normalized outcomes.

Real A/B JWT acceptance after Owner deployment and authorized small reviewed fixture:
- Guest reads published active packages only; draft/withdrawn/raw evidence denied;
  inactive content/occurrence hides package; own old result remains readable.
- A submits -> recomputed result and every answer row verified, not just HTTP200;
  spoofed score/grade/user fields and direct INSERT/UPDATE denied.
- Foreign exam/variant/cutoff/question/session-owner/mode rejects; immutable mutation
  rejects; incomplete answer transaction rolls back; identical concurrent retry
  returns one result, changed-payload retry fails.
- B cannot SELECT/DELETE A attempt/answers or submit linked to A Study session.
- Key/cutoff correction leaves A old score/version unchanged; withdrawn cached
  submission fails safely. No automatic key or grade upgrade.
- Owner attempt deletion cascades answers but preserves Study; linked Study deletion
  cascades attempt/answers only as documented. Auth users retained during testing.
- Run-owned fixture cleanup/baseline restoration and profile/NEIS/D-Day preservation.
  SQL Editor SET ROLE is not real JWT ownership evidence.

Flutter later tests: Guest no upload, Auth dependency-order pending/retry, local
v2 migration, stale owner callbacks, timeUp answer-lock races/dialog cancellation,
KST aggregate not doubled,360×640/2× input/results/semantics, actual simulator and
physical lifecycle gates. No tests for an unimplemented scoring engine claimed now.

Static validation now: local schema/code/proposal naming cross-check, relation/delete/
trust consistency, document links and git diff --check; prior migrations unchanged.
SQL syntax/runtime/RLS tests **NOT RUN** because executable SQL and scoring code are
not part of this task. This is ready for Owner design review, not SQL Editor paste.
