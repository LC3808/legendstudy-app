# In-App Exam — pre-implementation architecture gate

Recorded 2026-09-20 from the Owner-provided RED TEAM synthesis. Architecture
policy only, not a claim of an independently rerun review or implementation.
**EXAM ENGINE: CONDITIONAL. VIEWER: independent CONDITIONAL track.
PDF MIRROR / STORAGE: HOLD.** Existing Study/scoring acceptance is preserved.
This document owns the new integrated In-App Exam contract; linked documents
remain authoritative for their existing implementations and product roadmaps.

## Product refinement — paper-first / answer-first

This 2026-09-20 refinement supersedes the mandatory FIND → VIEW → START ATTEMPT
ordering and the combined seven-gate implementation hold recorded in `79af28a`.
It preserves the original safety/scoring contracts; it does not erase that decision.

Product value loop: **SOLVE → ANSWER → SUBMIT → SCORE → GRADE → RECORD →
ANALYZE → IMPROVE**. The paid value is personalized learning after the exam,
not ownership of a collection of question PDFs. Users may already have printed
papers, school/academy handouts or legitimately obtained official files.

Primary smartphone flow: search material → permitted original/download/print
access → solve on paper → select the exact exam in LegendStudy → create Attempt
→ OMR/answer entry/autosave → unanswered review → submit → server score → raw
score/grade → Academic Record → basic history/comparison. Long-term analytics
and study strategy extend this flow; advanced/AI analysis is not a V1 promise.
Users with papers can enter directly at exam selection without any resource action.
**Attempt creation never requires opening a Viewer or owning a mirrored PDF.**
Viewer failure cannot block answer entry, scoring or recording.

PAPER-FIRST / ANSWER-FIRST / ANALYTICS-CENTERED describes the product direction.
Simultaneous PDF+OMR manipulation on a phone is not V1's defining value.
Optional tablet flow remains Exam → Viewer → Answer UI → Submission, using the
same independent Exam Engine and durable state; closing/failing Viewer cannot
terminate the Attempt.

## Resource layer versus Exam Engine

| Resource access / convenience layer | Exam Engine |
|---|---|
| metadata, source, permitted official/original URL, external/open/download actions | exam/question identities, answer schema, selected subjects |
| preview, individual-question reference, optional tablet viewing | scoring key/version, grade/cutoff data, attempt, answers, submission |
| optional future mirror only after rights approval | server score, Academic Record, basic comparison; future analytics |

Viewer is a RESOURCE ACCESS / CONVENIENCE LAYER, not CORE EXAM ENGINE.
Keep basic search/access/original links/basic Viewer as free-value candidates;
Viewer is not the primary paywall. PDF rights/mirroring/storage uncertainty does
not by itself block independent Exam Engine development. This does NOT authorize
use of unvalidated answer keys, ambiguous mappings or improperly sourced data.
Original Historical rights policy remains intact; mirrors and PDF Storage HOLD.

## V1 core and grade-3 pilot

V1 core: (1) exam selection, (2) Attempt creation, (3) objective OMR/answer entry,
(4) unanswered review, (5) submission, (6) server scoring, (7) raw score,
(8) basic grade/cutoff display, (9) Academic Record persistence,
(10) previous-result retrieval, (11) basic score-change comparison.
Confirmed/estimated/unavailable grade semantics remain explicit: missing cutoffs
must show unavailable, not invented grades. Compare like-for-like subjects,
versions and score scales; basic trends are not cross-paper equivalence claims.

Pilot stays recent three years' grade-3 June/September evaluation mocks and CSAT.
Success criterion: **Exam identity → Answer entry → Submission → Server scoring
→ Grade → Academic Record**, without mandatory Viewer. Exact dataset/year freeze,
common/major-elective coverage, deterministic mapping and scoring validation
remain required. Non-MCQ portions need explicitly scoped support or exclusion;
never present a partial supported score as a whole-paper score. Viewer quality
and media rights are separate acceptance tracks, not the Pilot's engine criterion.

Paper-first answer-entry after solving must not invent a timed exam start/duration
or retroactive server anchor. A future in-app timed execution, when offered,
retains the uninterrupted timer contract below. Specify mode and provenance in
Attempt/Record design; elapsed answer-entry time is not study/solve time.

## Existing evidence versus new requirements

| Repository evidence | What it does NOT establish |
|---|---|
| [Study v1](study-v1.md): native atomic envelope and continuous monotonic anchors; [store](../lib/features/study/data/study_local.dart) | new viewer-page/elective envelope, server start anchor or single-device server execution ownership |
| [Scoring contract](mock-exam-scoring-v1.md), D1–D3 accepted | integrated viewer flow or unified Academic Record implementation |
| [RPC migration](../supabase/migrations/20260914000200_mock_exam_scoring.sql), [repository](../lib/features/study/scoring/scoring_repository.dart) | a function named calculate_mock_score; actual endpoints are submit_mock_attempt / fetch_own_mock_attempt |
| [Historical A2](../reports/historical-exam/2024-production-preflight.md): scoped natural-key/provenance preflight complete | semantic correctness, working files, rights or publication readiness |

Current Mock supports pause/resume and Guest Dart scoring. Those accepted
behaviors remain untouched. The new integrated Exam V1 contract below is stricter:
no pause for an in-app timed exam and server-authoritative final score. Guest local preview must not
be presented as a final server score or durable Academic Record. Auth/start and
Guest promotion policy must be settled before implementing that new path.

## Viewer memory and resource access

**HARD BLOCKER: whole-PDF eager rendering as Production architecture.**
Use page-level lazy rendering, focus on current page, limited adjacent prefetch,
and a bounded byte/pixel-aware page cache. Evict offscreen pages and cancel stale
render jobs under memory pressure/background transitions. Bound disk PDF/audio
cache separately and invalidate by stable resource version/hash. Do not assume
page virtualization means the engine itself avoids whole-document allocation.

Engine/library selection is deliberately OPEN. Before selection, benchmark
representative authorized large/scanned/vector papers, zoom, rapid navigation,
rotation, cold/warm opens, prolonged use, interruptions and low-memory recovery
on low-end Android and iPhone. Record peak/resident memory, page latency, cache
size/evictions and crash/OOM behavior. Set device-specific budgets and pass/fail
thresholds before comparing engines; simulated tests alone do not close this gate.

Rights decide whether a durable official URL, approved mirror or original source
page is permissible. No automatic mirror. Preserve original provenance/fallback;
a fallback link may allow reading but does not qualify an unready exam to start.
No downloads, Storage or viewer package selection in this documentation task.

## Atomic local attempt envelope

Minimum conceptual fields: attempt_id, immutable owner namespace, exam_id,
exam_version/reference, started_at, elapsed_time, answers, selected_subjects,
current_page, last_saved_at, submission_state, local_revision. Also record schema
version, pinned scoring provenance, monotonic/boot anchors, server anchor and
submission idempotency key. Names are proposals, not a schema migration.

Reuse/extend the existing serialized atomic-replacement principle: answer changes
and associated revision/state form one commit; preserve previous valid data if a
write fails. Commit before showing a transition as saved. Define bounded autosave
latency, write ordering and crash injection tests before implementation; never
rely solely on dispose/background/final callbacks. Freeze answer snapshot and
pending submission/outbox atomically before sending. Recovery validates owner,
version and last committed revision; never silently create a replacement attempt
or overwrite a newer submission on stale callback/retry/account switch.

Crash, OS kill and background eviction must recover the last acknowledged durable
state. Disk-full/corrupt data requires visible recovery, not false 'saved' feedback.
Local storage is NOT durable cloud backup: uninstall/device loss can lose an
unsubmitted attempt. Communicate that limitation. Full offline mode is excluded;
local answer preservation during disconnection is still mandatory.

## Timer and interruptions

**HARD BLOCKER: wall-clock-only DateTime.now subtraction.** Use continuous
monotonic/elapsed time while clock continuity holds, with a server-issued or
server-confirmed start anchor and background/re-entry reconciliation. Store the
anchor/recovery context atomically. Server-confirmed time and elapsed checkpoints
must not silently trust a changed device wall clock. Across reboot/anchor loss,
require explicit reconciliation or recovery-required state; do not grant time or
invent elapsed duration. Resolve offline-start eligibility and server-anchor
protocol before implementation. This is integrity engineering, not full anti-cheat.

When in-app timed execution is used, it continues through calls, notifications, lock, background and app exit;
no pause and no automatic extension. Audio/UI interruptions do not pause time.
At time-up, atomically freeze answers/submission intent; if disconnected, retain
pending submission and retry safely on reconnection. Server deadline validation
and outage/recovery exceptions must be specified before enabling this flow.
Existing Study/Mock pause and physical acceptance are not retroactively changed.

## Lifecycle, concurrency and submission

Conceptual states: DRAFT, IN_PROGRESS, SUBMITTING, SUBMITTED, SCORING, SCORED,
FAILED. Actual schema enums remain undecided; existing transactional scoring may
collapse some states. Define valid transitions and retryable failure reasons.
FAILED must not implicitly unlock a server-accepted answer snapshot.

One attempt's active execution has one canonical device/session owner. No realtime
multi-device editing in V1. Server must reject competing mutation ownership;
lease/re-entry/expiry/transfer behavior requires design, not a client-only flag.
History reading on another device is separate from active execution ownership.

Idempotency key belongs to the immutable attempt/submission payload, reused across
double taps, timeout retries and replay. Same key+same payload returns the same
result; same key+different answers is rejected. Server owns final submission.
After SUBMITTED, answers cannot be edited; a retake creates a new Attempt.
On ambiguous network failure, reconcile server state before releasing locks,
reserving new credit or claiming failure. Preserve auditable submission/result;
future admin correction creates a revision/audit trail, never overwrites original.

## Server scoring, provenance and subject identity

**HARD BLOCKER: client-only authoritative scoring.** Existing Auth implementation
calls submit_mock_attempt, which computes/validates score transactionally from
server questions and persists attempt/answer results; fetch_own_mock_attempt
restores owner-scoped results. Client-supplied score/grade is not authority.
Objective scoring needs no AI. Existing Guest/preview Dart scoring stays a local
preview, not a substitute for the new loop's final server result.

Pin immutable answer_key_version_id, optional grade_cutoff_version_id and
scoring_version (or equivalent immutable snapshot references). Existing D3 keeps
historical grade/source snapshots and retry semantics after current-version
switches. Preserve that contract. Never fetch current keys/cutoffs and silently
reinterpret an old result; explicit correction/regrading is separately audited.
Current stale-version rejection at new submission remains in force; a long-running
attempt whose pinned version is superseded needs a reviewed recovery policy,
not an automatic upgrade. Source provenance (paper origin/version/page) and
scoring provenance (key/rule/engine/cutoff) are distinct.

Question identity must deterministically bind exam version, paper variant,
selected subject and scoring key. Display number is not a globally unique question
identity: common/elective numbering collisions must map explicitly to canonical
identities. Raw subject labels survive mapping. Existing per-key question_number
scope must be assessed against mixed-section papers; do not claim coverage by
coercing historical aliases or ambiguous subject files.

## Listening audio gate

Do not rely exclusively on after-start streaming. Before an audio-required in-app listening session,
design authorized preflight availability, download/cache eligibility, enough local
capacity, media readiness, playback position/recovery and background/interruption
behavior. Avoid starting a listening-dependent exam with unavailable audio; if a
mid-exam failure occurs, preserve answers and timer and present an explicit
recovery/incomplete status. No silent full-exam success or audio-less substitution.
A listening-excluded practice mode, if separately offered, must be labeled as such.
Audio rights are as binding as PDF rights; no current download/mirror approval.
Paper-first users who solved with external audio may still enter answers; audio
playback availability is not a dependency of their answer-only Attempt.

## Academic Record, entitlement and cost

V1 REQUIRED: attempt history, raw score, basic result, Academic Record foundation
and basic score-history retrieval/comparison. Academic Record is currently NOT IMPLEMENTED;
existing immutable mock results are inputs, not proof of a unified record layer.
Design an idempotent submission/result-to-record link so retries do not duplicate
history. A record write failure after scoring must remain recoverable without
rescoring or charging again; persistence transaction/outbox boundary is a gate.

V2+: deep Academic Analytics, study-time × score analysis, weakness diagnosis,
target-university gap analysis, admission prediction and AI academic coaching.
Do not label all Analytics/Record as BLOCKED together. Preserve the existing
[analytics roadmap](roadmap-academic-analytics.md) distinction between correlation,
growth and admission probability, and keep LS LAB scores off the school-score scale.

Entitlement-compatible boundary is REQUIRED NOW; payment implementation is not.
Use the Entitlement layer, never scattered isPro checks. Model CHECK → RESERVE →
EXECUTE/SCORE → SETTLE, compatible with LS LAB CHECK → RESERVE → EVALUATE → SETTLE.
Submit initiation reserves once; confirmed scoring success settles once; definitive
scoring failure releases/refunds. Timeout is not proof of failure: reconcile before
release to avoid double spending or duplicate charges. Reservation/settlement
idempotency must survive retries and scoring-success/record-pending recovery.
Free path can authorize without paid reservation. Quotas, tiers and exact free
counts remain undecided; no entitlement/credit/payment code is implied.

Cost risks: PDF/audio egress, Storage, AI evaluation and analytics compute.
Objective V1 scoring remains deterministic and AI-free. Future permitted media
caching should avoid repeated downloads with bounded local caches and versioned
invalidation; rights precede caching/mirroring decisions. No unlimited AI promise.

## Architecture matrix and exclusions

GO means supported architectural direction/reusable foundation, not deployment
approval. PDF rendering or storage status cannot alone veto the engine track.

| Area | Decision | Current-code evidence / independent condition |
|---|---|---|
| Existing answer entry / server scoring | GO as reusable foundation | D2/D3 implementation and actual submit_mock_attempt / fetch_own_mock_attempt path; no new deployment |
| Paper-first integrated Exam Engine | CONDITIONAL | exact validated exam/key/subject/cutoff package, post-solve mode semantics and durable Record linkage pending |
| Attempt lifecycle | CONDITIONAL | atomic store exists; new ownership/mode/retry and crash contract review pending |
| Basic Academic Record / comparison | CONDITIONAL, V1 REQUIRED | mock_exam_attempts / mock_exam_answers exist; unified Record/history linkage remains NOT IMPLEMENTED |
| PDF Viewer | CONDITIONAL, independent track | rights + memory benchmark; engine/library open |
| PDF mirror / Storage | HOLD | explicit rights/storage decision still required |
| Advanced Analytics / strategy | DEFERRED V2+ | separate validation and implementation |
| AI subjective scoring | DEFERRED V2+ | separate LS LAB workstream |
| Realtime cross-device attempt sync | DEFERRED | one active execution owner |
| Monetization implementation | separate / DEFERRED | quota/price/payment undecided |
| Entitlement-compatible boundary | REQUIRED NOW in design | CHECK → RESERVE → EXECUTE/SCORE → SETTLE; no implementation here |

Evidence is repository code/migrations and prior Owner runtime records, not a
new live DB inspection. No academic-record table/feature is claimed from existing
mock result tables. Engine development can proceed independently of PDF rights
once its own contracts/data gates are approved; **full integrated implementation
readiness is currently NO**, for those engine dependencies, not for absent Viewer.

V1 still excludes AI essay/subjective scoring, advanced percentile prediction,
full offline mode, deep Analytics, admissions prediction, sophisticated anti-cheat,
realtime multi-device sync and unlimited AI analysis. Local offline answer safety
is required even though a full offline product is not.

## IN-APP EXAM PRE-IMPLEMENTATION GATE — separated tracks

This refines the original seven-gate list, not the safety requirements.

| Track / gate | State and evidence needed |
|---|---|
| Engine: persistence | atomic foundation exists; mode/envelope migrations, autosave/recovery and Record transaction/outbox review pending |
| Engine: timed execution | existing monotonic foundation; server anchor/reboot/deadline design pending only for in-app timed mode; no fabricated timing for post-solve entry |
| Engine: submission | idempotent RPC foundation; device ownership, immutable snapshot and entitlement/Record retry contract review pending |
| Engine: scoring provenance | pinned key/cutoff/engine foundation; common/elective identity and stale-version policy review pending |
| Engine: grade-3 dataset | HOLD pending semantic/answer-key/subject/cutoff validation; A2 identity absence alone insufficient |
| Viewer: rights/storage | independent HOLD for mirrors/storage and resource-specific access decisions; not prerequisite to answer-only engine |
| Viewer: memory | independent CONDITIONAL; benchmark corpus/budgets/devices before engine selection |

Historical URL-expiration cases stay unresolved until appropriate file/access
review; they need not block validated answer-only metadata/scoring solely because
PDF delivery is unavailable. Subject-unknown cases DO block those affected scoring
mappings until reviewed. No quarantine resolution or production publication occurs
by writing this refinement.

Hard blockers preserved: client-only final score, non-atomic acknowledged save,
non-idempotent submission, silent historical regrading and guessed subject identity.
Whole-PDF eager rendering remains a Viewer hard blocker; wall-clock-only timing
remains a timed-execution hard blocker. Rights gates continue to govern media
access/mirroring. Production mutation=0.
