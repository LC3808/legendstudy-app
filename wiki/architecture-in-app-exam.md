# In-App Exam — pre-implementation architecture gate

Recorded 2026-09-20 from the Owner-provided RED TEAM synthesis. Architecture
policy only, not a claim of an independently rerun review or implementation.
**IMPLEMENTATION START: HOLD.** Existing Study/scoring acceptance is preserved.
This document owns the new integrated In-App Exam contract; linked documents
remain authoritative for their existing implementations and product roadmaps.

## V1 closed learning loop and pilot

**FIND → VIEW → START ATTEMPT → SOLVE → AUTOSAVE → SUBMIT → SERVER SCORE
→ RESULT → ACADEMIC RECORD**

The product is taking an exam, preserving answers, obtaining server scoring and
accumulating a learning record inside the app. A PDF renderer alone is insufficient.
Pilot: recent three years, grade 3, June/September evaluation mocks and CSAT.
Exact years/resources must be frozen after source validation; unpublished future
sessions are not missing. Common sections and major electives are candidate
support, conditional on deterministic question/variant mapping.

V1 requires PDF viewing, objective-choice answer entry/OMR UX, exam timer,
local autosave, crash/re-entry recovery, submission, server raw score/basic result,
attempt history, Academic Record persistence and basic score-history retrieval.
Non-MCQ questions present in real papers must be explicitly unsupported or
separately approved; never silently claim a whole-paper score for partial coverage.
Historical semantic validation and PDF/audio redistribution/storage rights remain
hard dependencies. Metadata coverage is independent of viewer coverage.

## Existing evidence versus new requirements

| Repository evidence | What it does NOT establish |
|---|---|
| [Study v1](study-v1.md): native atomic envelope and continuous monotonic anchors; [store](../lib/features/study/data/study_local.dart) | new viewer-page/elective envelope, server start anchor or single-device server execution ownership |
| [Scoring contract](mock-exam-scoring-v1.md), D1–D3 accepted | integrated viewer flow or unified Academic Record implementation |
| [RPC migration](../supabase/migrations/20260914000200_mock_exam_scoring.sql), [repository](../lib/features/study/scoring/scoring_repository.dart) | a function named calculate_mock_score; actual endpoints are submit_mock_attempt / fetch_own_mock_attempt |
| [Historical A2](../reports/historical-exam/2024-production-preflight.md): scoped natural-key/provenance preflight complete | semantic correctness, working files, rights or publication readiness |

Current Mock supports pause/resume and Guest Dart scoring. Those accepted
behaviors remain untouched. The new integrated Exam V1 contract below is stricter:
no exam pause and server-authoritative final score. Guest local preview must not
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

New Exam V1 continues through calls, notifications, lock, background and app exit;
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

Do not rely exclusively on after-start streaming. Before an audio-required pilot,
design authorized preflight availability, download/cache eligibility, enough local
capacity, media readiness, playback position/recovery and background/interruption
behavior. Avoid starting a listening-dependent exam with unavailable audio; if a
mid-exam failure occurs, preserve answers and timer and present an explicit
recovery/incomplete status. No silent full-exam success or audio-less substitution.
A listening-excluded practice mode, if separately offered, must be labeled as such.
Audio rights are as binding as PDF rights; no current download/mirror approval.

## Academic Record, entitlement and cost

V1 REQUIRED: attempt history, raw score, basic result, Academic Record foundation
and basic score-history retrieval. Academic Record is currently NOT IMPLEMENTED;
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

GO means accepted direction, not permission to start implementation/publication.

| Area | Decision | Condition |
|---|---|---|
| Question mapping / server scoring | GO | deterministic variant mapping; validated dataset; server authority |
| PDF viewer | CONDITIONAL | rights decision + physical memory benchmark; engine open |
| Attempt lifecycle | CONDITIONAL | atomic recovery, timer, ownership and idempotency validation |
| Basic Academic Record | CONDITIONAL, V1 REQUIRED | durable idempotent link/history design; not implemented |
| Advanced Analytics | DEFERRED V2 | separate research/implementation |
| AI subjective/essay scoring | DEFERRED V2+ | separate LS LAB/cost/validation workstream |
| Realtime cross-device attempt sync | DEFERRED | one execution owner in V1 |
| Monetization implementation | DEFERRED / separate workstream | pricing/payment not required together |
| Entitlement-compatible boundary | REQUIRED NOW | reserve/settle/release and retry semantics |

Also excluded from V1 core: advanced percentile prediction, full offline mode,
admissions prediction, sophisticated anti-cheat and unlimited AI analysis.
Existing rights-gated access, metadata-only expansion and independent LS LAB
architecture remain unchanged; [monetization roadmap](roadmap-monetization-and-in-app-learning.md)
retains strategy ownership.

## IN-APP EXAM PRE-IMPLEMENTATION GATE

All seven require review evidence before Codex begins integrated implementation.
This document specifies direction; recording a contract is not validating it.

| Gate | Current state / required evidence |
|---|---|
| 1 PDF rights/storage decision | OPEN: Owner resource-specific permitted access/storage decision |
| 2 Viewer memory benchmark strategy | strategy above recorded; device corpus/budgets/harness review pending; engine selection requires benchmark results |
| 3 Attempt persistence contract | direction recorded; envelope migration, autosave failure budget and crash/recovery test plan pending |
| 4 Timer contract | direction recorded; server anchor, reboot/offline/deadline and interruption protocol pending |
| 5 Submission idempotency contract | existing RPC baseline; new execution ownership and entitlement/result-record retry contract pending |
| 6 Scoring provenance/version contract | existing pinned-version baseline; mixed-paper mappings and stale in-flight recovery review pending |
| 7 Grade-3 pilot dataset validation | HOLD: Historical semantic/quarantine/file gates unresolved; A2 identity preflight alone insufficient |

Hard blockers remain whole-PDF eager rendering, client-only final scoring,
wall-clock-only timing, silent historical regrading, non-atomic acknowledged saves
and enabling access/mirroring without rights authorization. Production mutation=0.
