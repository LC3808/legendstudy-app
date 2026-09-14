# Day 8-D1 — Scoring storage / validation contract

**Day 8-D1 = COMPLETE. Production migration/Postflight and actual A/B JWT/RPC: Owner-reported PASS.**
Owner approved MCQ-first, confirmed/estimated/unavailable grade meanings, and independent
Study/result deletion. This contract supersedes the Day 8-D proposed Study-delete cascade
and key-owned cutoff family. Day 8-D is NOT COMPLETE. No Flutter scoring implementation.

## Execution package and baseline

[Complete SQL package](day-8-scoring-migration-package.md) contains byte-identical
Preflight, migration, Postflight and guarded rollback blocks.
Migration: `supabase/migrations/20260914000200_mock_exam_scoring.sql`.
The four previously applied migration files are unchanged (hash checked).
Production Study/Postflight/JWT and 8-C runtime results remain Owner-reported;
this task made no production connection or request.

Five tables remain appropriate: public immutable definitions and private user answers
are separate; header/question completeness requires a header relation; cutoff version
has its own lifecycle; attempt is the owner/idempotency/result record. Nine grade bands
fit one constrained array, avoiding a sixth table solely for nine fixed row positions.

## Final schema

| Table | Identity / integrity |
|---|---|
| answer_key_versions | UUID PK; occurrence/content composite FK to exam_subjects(id,content_item_id), RESTRICT; family UNIQUE(occurrence,variant,version); draft/published/withdrawn + is_current; question_count 1..100, max_score 1..1000 |
| exam_questions | PK(key_version,question_number); question_number 1..100; answer_type=multiple_choice; correct_answer 1..5; points 1..100; key RESTRICT |
| grade_cutoff_versions | Independent occurrence/content composite FK; family UNIQUE(occurrence,variant,version); max_score and exactly nine ordered thresholds; own publication/version/source lifecycle |
| mock_exam_attempts | Client UUID for idempotency; server auth.uid owner; key and optional cutoff composite scope FKs; immutable calculated totals/counts/grade; optional Study link |
| mock_exam_answers | PK(attempt,question_number); same-key composite FKs to attempt/question; submitted_answer NULL or 1..5; server snapshots; stored generated is_correct/awarded_points |

No new exam copy. Canonical parent is exam_subjects.id; exams itself uses
content_item_id as its PK. The same-content parent FK preserves existing resources'
cross-exam pattern. Attempt scope is (occurrence, paper_variant, max_score), constrained
against BOTH the pinned key and optional cutoff, not inferred from Study title.

Source name/URL/SHA256/fetched_at/verified_at/version are required for publication.
Separate points source is an all-null/all-present triple. Optional correction timestamp
and note form a pair. Finite timestamps, trimmed bounded text and HTTP(S) URL without
userinfo/whitespace are checked. URL validation cannot certify source authenticity:
operator review must exclude credential-bearing URLs and verify complete official evidence.
No raw private ingestion evidence is exposed through public column grants.

Published answers/points/scope/source/evidence cannot change or be deleted. Correction
creates a new version. Superseded means published with is_current=false. New submissions
require status=published AND is_current=true for both key and any selected cutoff.
Non-current/withdrawn versions remain valid references for historical results and identical
existing-attempt retries, but cannot create a new attempt. A partial UNIQUE permits at most one current version
per occurrence/variant; version switch demotes old current and promotes new in one
backend transaction. Conflicts fail atomically, never choose an arbitrary version.

## Publication and completeness

Service-role/backend DML starts with draft headers only. After reviewed questions are
loaded, update verified_at/status='published'/is_current=true in a transaction.
No callable public publish RPC or client write grant exists. Publication trigger checks
active occurrence/content, contiguous 1..N, exact count and sum(points)=max_score.
Unsupported question types cannot be stored; omitted unsupported items cannot be inferred
from SQL alone, so complete-paper human review is a mandatory publication prerequisite.
Any paper not wholly representable stays timer_only; no partial score rescaling.

Question edits bump the draft parent revision. This forces row-version conflicts with
concurrent publication even at repeatable-read isolation; released children reject edits.
Submission locks current published key/cutoff and active parent rows through commit.
If submission obtains the lock first, demotion waits for submission commit. If the
current switch wins, the waiting new request rechecks current and rejects the stale UUID.
Existing attempts return through the idempotency path before current-version checks.
Partial current indexes prevent simultaneous current promotions. Independent native
PostgreSQL17.6 READ COMMITTED sessions verified both lock orders, retries and publication
races; PGlite alone is not that concurrency evidence.

content_digest is server SHA256 of UTF-8 PostgreSQL JSONB text containing immutable
header evidence (excluding operational status/current/revision/create/publish fields) and
ordered question triples or cutoff array. It is an opaque server package fingerprint,
not a promise that Dart jsonEncode produces identical bytes. Future clients pin the digest
and validate typed completeness; cross-language scoring parity uses numeric test vectors.

## Grade contract

Publication status and grade certainty are separate columns. Supported basis/meaning:
- raw_absolute + confirmed: applicable officially verified absolute rule; UI `2등급`.
- raw_estimate + estimated: compatible raw estimate; UI `예상 2등급`.
- no selected cutoff: grade NULL, grade_status=unavailable; UI `등급 정보 준비 중`.

minimum_scores is smallint[9], one-dimensional with lower bound 1. Array index IS grade
1..9; duplicates/missing grade positions are impossible. Values must be non-NULL,
strictly descending, between 0 and max_score, last value 0. Minimum includes boundary;
choose first grade whose threshold <= raw score. Unsupported degenerate/duplicate bands
stay unavailable pending a separate contract, not silently normalized.
Standard-score tables cannot enter this raw-score storage. No raw-score reconstruction
of official Korean/math standard scores/percentiles/grades. English/history also need
reviewed year/occurrence-specific data; no hardcoded universal bands. Independent cutoff
versions can be reused across corrected keys of exactly matching scope/total, reducing
unnecessary duplication without creating an unversioned global rule.

## Trusted writes / reads

12 functions: five pure invoker helpers (text, URL, cutoff shape, answer normalization,
MCQ engine), five trigger functions, two authenticated RPCs.

`submit_mock_attempt(p_attempt_id, p_study_session_id, p_answer_key_version_id,
p_grade_cutoff_version_id, p_scoring_version, p_answers)`:
1. Requires auth.uid(); no arbitrary user_id/score/grade/time arguments.
2. Serializes same UUID with transaction advisory lock. Same owner/id/normalized input
   returns prior immutable result; different payload or foreign owner returns conflict.
3. For a NEW attempt: engine mcq5-v1, complete key with status=published AND
   is_current=true. Optional cutoff must also be current/published and match
   occurrence/variant/max_score. The INSERT guard repeats these requirements.
   Existing identical retries do not revalidate current/publication status.
4. Input is <=100 objects, each exactly {question_number,choice}; choice NULL or integer
   1..5. Missing questions normalize to blank. Unknown fields/numbers, duplicates, string
   numbers/fractions/unsupported input reject. Client scores cannot be smuggled in.
5. Recomputes points/grade, INSERTs attempt and all answer rows in one transaction.
6. Returns calculated result/answers and safe provenance via fetch_own_mock_attempt.

`fetch_own_mock_attempt(p_attempt_id)` checks owner first, returns NULL if not owned.
It permits private historic review after public withdrawal without making the old key
public. It excludes internal request_payload. Same-id retries work even after linked
Study deletion: original normalized request is retained privately for comparison.

Deferred constraints independently check complete answer snapshots, calculated totals,
counts, grade and normalized request. A partial trusted result insert fails at commit.
Generated correctness/points cannot be supplied as arbitrary client values. Direct
attempt UPDATE and independent answer UPDATE/DELETE fail; delete whole attempt instead.

Pure functions IMMUTABLE/SECURITY INVOKER; fetch STABLE and submit/trigger functions
VOLATILE. All fixed search_path=''; all table/function references schema-qualified.
Definer routines are owned by the trusted migration executor (normally postgres), not
app roles. Their elevated capability is intentionally limited to reviewed fixed bodies,
no dynamic SQL and explicit owner checks; no new login/BYPASSRLS role is introduced.
PUBLIC/anon/authenticated/service_role default function EXECUTE is explicitly revoked.
Only submit/fetch granted to authenticated; three CHECK helpers granted to content backend.
This is not a claim that the postgres function owner itself has reduced global privileges.

## Study delete and field preservation

Add only `study_sessions_id_owner UNIQUE(id,user_id)` to existing Study.
Composite FK (study_session_id,user_id) references (id,user_id), with
**ON DELETE SET NULL (study_session_id)**. user_id remains NOT NULL and unchanged.
This PostgreSQL17-supported column-specific action preserves owner identity:
[PostgreSQL CREATE TABLE](https://www.postgresql.org/docs/17/sql-createtable.html).
Attempt trigger permits only this unlink after the referenced row is gone; all score
fields remain immutable. Attempt deletion cascades answers, never Study; Study deletion
retains attempt and answers. Auth account deletion cascades private records.
One non-NULL Study link per attempt result (UNIQUE) avoids duplicate linked submissions.
Owner/mode=mock_exam is checked under lock; NULL link is allowed and adds no study time.
Profiles, names/grades, NEIS, D-Day, content/resources and existing Study permissions,
duration and RLS are untouched. Request payload retains original Study UUID for retry,
but it is no longer a live relation after deletion and contains no auth token/credential.

## Availability, RLS and indexes

`mock_exam_scoring_availability` is a security_invoker view over existing public
occurrences/current published keys and compatible current cutoffs. No stored availability
boolean. It returns timer_only for an active occurrence without current key, or
scoring_available per variant, plus nullable cutoff and grade_status. Clients filter by
occurrence, paginate selection, and use keyset owner history (submitted_at,id), not
unbounded history downloads. Full key fetch is bounded by <=100 questions.

Five tables RLS enabled, six policies. Public SELECT uses explicit safe columns and
active parent/publication checks. Questions inherit parent visibility. Cutoffs are public
independent reviewed data, not dependent on whether an exact key version still exists.
Auth owner SELECT/DELETE attempts, SELECT answers; no direct INSERT/UPDATE. Anon has no
personal table privileges. Backend content DML is trigger-guarded; existing service_role
contracts are unchanged. No client grants on quarantine, no new ingestion/crawler.

Five explicit scoring indexes: key current, cutoff current, owner history, attempt key
reference, non-NULL cutoff reference. PK/UNIQUE indexes support numbering/families/scope
FKs and Study links; one additive Study composite UNIQUE. No GIN/leaderboard index.

## Guest, parity and acceptance

Guest remains planned pure Dart local engine; no cloud attempt or auto-upload on login.
Auth saves through server RPC; future outbox preserves original owner/version and retries.
`supabase/review/mock_scoring_vectors.json` contains 37 explicitly synthetic vectors,
including mixed points/blank, threshold neighbours, confirmed/estimated/unavailable.
Local PostgreSQL engine consumes them now; future Dart must consume exactly this file
and match every expected output before Flutter scoring is enabled. Dart parity is NOT
implemented or PASS yet. Pure output is wrapped with pinned key/cutoff/engine versions
by the RPC/repository; engine never chooses a newer version itself.

Production acceptance after Owner deploy (actual A/B JWT, never SET ROLE evidence):
1. Owner explicitly approved temporary synthetic fixture publication for this verifier
   only, plus narrowly scoped transactional cleanup of its UUIDs. See
   [executable procedure](day-8-scoring-jwt-acceptance.md). Ordinary published data
   remains immutable; this is not an application deletion capability.
2. Log in A/B with local getpass, verify distinct IDs and capture own attempt/Study and
   profile baselines. No password/token/key/raw error response logging. Anon GET must
   hide drafts/inactive keys and expose published question/points/source and cutoff basis.
3. A POST `/rest/v1/rpc/submit_mock_attempt` with six named p_* arguments above, own
   optionally linked completed mock Study, mixed right/wrong/blank answers. Compare actual
   stored rows/each awarded point and result, not HTTP alone. Test no-cutoff grade NULL,
   applicable boundaries and independent cutoff compatibility. Initial current key/cutoff
   v1 must successfully create an attempt; retain the exact response and request.
4. Reject malformed/duplicate/unsupported answers, unknown engine/key, unpublished key,
   foreign cutoff/variant/session and any raw_score/user_id/grade extra RPC parameter.
   Direct INSERT/UPDATE also denied. Fresh keys must be complete before publication.
5. B GET/DELETE A attempt: empty/no effect; B reads no A answers, cannot attach A Study.
   Re-read A intact. Same-id retry identical; changed input conflict. Run concurrent retry
   and publish/edit races with separate local database connections before release.
6. Switch key v1 -> v2: a NEW attempt using published/non-current v1 rejects; current
   v2 succeeds. Same old attempt ID + identical v1 request returns unchanged score,
   snapshots and pinned versions. Repeat independently for cutoff v1 -> v2 with a
   current key: non-current cutoff rejects new attempt, current cutoff succeeds, old
   retry preserves its original cutoff/grade. Changed-payload retry still conflicts.
   Withdrawn versions also reject new attempts while historical reads/retries survive.
   Use only this run's synthetic key/cutoff versions; never change existing content.
7. Delete run-created linked Study as A: attempt survives with NULL link, owner/answers/
   scores unchanged; identical retry works. Delete run-created attempt: answers cascade,
   unrelated Study/profile untouched. Delete only UUIDs registered by this run.
8. Restore own attempt/Study baselines, profile/school/D-Day digests unchanged; keep Auth
   users. Never purge unrelated content. The three-trigger cleanup exception applies
   exclusively to published fixture UUIDs registered by this verifier.

## Validation / remaining gates

SQL grammar/scope/unchanged migration hashes/package-copy consistency/credential
signature scan: automated checker. Local PostgreSQL17.5 (PGlite0.3.14) applies all prior
migrations, then new migration/pre/post; validates rollback/reapply, mixed scoring,
publication and immutability, role-simulated isolation, generated values, malformed inputs,
version pinning, Study unlink, preservation and shared vectors. Safe in-memory synthetic
fixtures disappear when the database closes. Production is reported PG17.6; this is a
same-major local engine, not Supabase/PostgREST/JWT evidence. The original 19 groups
plus two key/cutoff-current regression groups PASS (21 total); all 37 vectors PASS.
`tool/test_scoring_concurrency.mjs` additionally creates a private native PostgreSQL17.6
cluster with TCP disabled and independent connections. Seven groups PASS: overlapping
idempotent retries, key and cutoff switches in both lock orders, competing current
promotions and question/publication races in both orders. Cluster/fixtures removed after
execution. It accepts no production DSN; real Supabase JWT/RPC remains a separate gate.

Owner reports production application/Postflight PASS: five scoring tables empty,
constraints/indexes/RLS/grants/view/functions/triggers and synthetic engine verified;
prior row-count/digest baseline preserved. Owner subsequently reports the full actual
JWT/RPC verifier PASS; detailed evidence is recorded below. No Dart parity, scoring UI
or real key ingestion claim; Codex has not connected to production.
A key/cutoff becoming non-current before the first cloud submit now rejects the pending
result; future clients retain the local result and require explicit recovery. Never
automatically replace pinned versions or rewrite scores to make a retry succeed.
Day8-B/8-C physical-device gates remain pending. No Push/PR/Merge.

## Accepted production runtime result

Owner reports actual A/B JWT/RPC acceptance PASS: server-side scoring, own result
and snapshots, direct score/grade forgery denial, owner isolation, idempotent retry,
current version switch and stale key/cutoff rejection, invalid inputs, Study deletion
retaining attempts/answers with a NULL link, and owner attempt deletion/cascade.
Fixture scope/cleanup, cleanup trigger restoration, scoring baseline restoration,
existing data preservation and Auth user retention all PASS.

**Day 8-D1 = COMPLETE. Next: Day 8-D2 Flutter Answer Entry + Raw Score.**
Day 8 overall is not COMPLETE; Day 8-B/8-C physical-device gates remain pending.
Flutter scoring/Dart parity and real source ingestion are not verified by this result.
This is Owner-run production evidence; this documentation closeout made no DB requests.

Full stage markers: [JWT acceptance](day-8-scoring-jwt-acceptance.md).
