# Essay LAB Final Schema Review — history first

2026-09-28 · review of5497498 · **RECOMMENDED: KEEP 19 MVP / move0 of19 to Future**.
No MERGE/REMOVE. History and Student Analytics: **PASS at design level**. Billing: **PASS at
architecture level**, actual transaction safety unverified. Runtime: package prepared / environment
unavailable / NOT_RUN. Production: **NOT_APPLIED**. Owner approval is still required.

[Architecture](student-analytics-data-architecture.md), [product](essay-lab-product-v1.md),
[final SQL package](../supabase/review/essay_lab_product/README.md),
[12 concrete queries](../supabase/review/essay_lab_product/history_queries.sql),
[runtime package and18 gates](../supabase/review/essay_lab_product/runtime/README.md).

## Recommendation and actual findings

Keep all19 because none is solely a cache, and merging the apparent candidates loses identity,
zero-charge decisions, many provider attempts, question-specific source selection or issue history.
Table count was not a target. No new table was needed to close these gaps:

1. **Completed AI run** could previously be overwritten. Freeze terminal runs; preserve timed_out_at
   when an unknown run later resolves. A retry gets a new run_no, never overwrites failed-run telemetry.
2. **Billing terms/grant expiry** could be silently changed. Freeze grant terms and decision policy/
   reason/amount; preserve reservation/settlement/release/rejection timestamps. Add policy_key.
3. **Different request UUIDs** for one student attempt could create duplicate live assessments.
   Add live/completed student-request UNIQUE by attempt+regime; preserve explicit operator re-evaluation.
4. **Arbitrary new posting key** could double consume one allocation. Add partial UNIQUE for
   decision+grant+reserve/consume/release, in addition to unique posting idempotency key.
5. **Progress predecessor** was implicit. Add previous_progress_id, same issue FK and chronology
   guard; normalize `recurred`, allow `unchanged`, retain every evaluation-specific observation.
6. **Cross-session recurrence** needed a safe link, not a permanent student weakness master.
   Optional reviewed normalized_issue_key+normalization_version; candidate labels are not auto-joined.
7. **Example-view clicks** were unnecessarily repeated. Keep first actual display per example,
   meaningful stage and stage-attempt. Rewrite start is once per source attempt. No autosave events.
8. **Correction/erasure** differed. Add one-time invalidation annotation and optional same-attempt
   superseding evaluation reference; frozen result body/hash stays unchanged. Deleting a predecessor
   detaches the pointer, not later progress records. Logical evaluation terminal time is retained.

9. **Operational retention** could remove the only copy of a historical result's selected model.
   Keep a small frozen provider/model/version/prompt snapshot on completed evaluation as judgment
   context, while per-run telemetry remains independently retained. This intentional metadata
   snapshot is not duplicated binary/body storage. Finalizer must verify it matches the selected run.

Old5497498 static validation remains historical evidence, not proof that these runtime gaps were
already solved. [Final validation](../supabase/review/essay_lab_product/final-review-validation.json)
records this review separately. No prior Pilot/result/contract is changed.

## 19-table decision matrix

`H` means historical fact **as observed/decided then**, not an objective truth about student ability.
`R` = exactly reconstructable from OTHER retained immutable sources; PARTIAL is not enough for
removal. `L/S/T` compare lifecycle/security/transaction boundary with the nearest merge candidate;
NO is honest and does not imply a merge when cardinality or independent FK identity differs.
All MERGE_TARGET values are **NONE**. Reconstruction cost is in the reason/loss column.

| Table | Domain / purpose | H | R | L distinct | RLS distinct | Tx distinct | Decision | Loss if removed / reason |
|---|---|---|---|---|---|---|---|---|
| essay_questions | Canonical selectable question | NO, identity/current metadata | PARTIAL | YES | NO | YES | KEEP | Exam locator cannot reliably reconstruct assigned question identity/limits; parsing is not stable identity. Attempt snapshots preserve used limits |
| essay_question_evidence | Versioned question↔segment selection | YES | NO | YES | NO | YES | KEEP | Exam mapping only gives broad exam/resource/role; exact segment version/hash/selection disappears; no body duplication |
| essay_evaluation_criteria | Verified criterion definition/version/weight | YES | PARTIAL | YES | NO | YES | KEEP | PDF reparsing can recover words but not historical assigned ID/structured version; criterion identity required for dimensions |
| student_target_universities | Current student preference | NO | NO | YES | YES | YES | KEEP | Current intent cannot be inferred from practice behavior; target history explicitly Future, not invented from updated_at |
| essay_practice_sessions | Stable learning cycle | YES, start/relationship | PARTIAL | YES | NO | YES | KEEP | An empty/abandoned cycle and entitlement grouping cannot be reconstructed from attempts alone |
| essay_drafts | Mutable current editor state | NO | NO | YES | YES | YES | KEEP | Unsaved/submission-free editing state lost; attempts have different immutability; no autosave history table |
| essay_attempts | Submitted answer snapshot | YES | NO | YES | YES | YES | KEEP | Original writing, time/mode/count/order disappear; new attempt for revision, never diff-only storage |
| essay_evaluations | Logical request and frozen judgment | YES | NO | YES | YES | YES | KEEP | Stochastic rerun is not reconstruction of an old judgment/contract/hash; attempt1 can havev1.2/v2 |
| essay_evaluation_dimensions | Judgment by criterion at that evaluation | YES | NO | NO | NO | NO | KEEP | N child criteria with identity/level/reason, not always1:1; parent prose does not encode exact historical result |
| essay_improvement_items | Session-local root issue identity | YES, identity | PARTIAL | YES | NO | YES | KEEP | Observation wording cannot reconstruct stable grouping; one issue spans evaluations; no student-global diagnosis |
| essay_improvement_progress | Evaluation-specific issue state/action | YES | NO | NO | NO | NO | KEEP | OPEN→IMPROVED→RESOLVED→RECURRED and explicit assessed evaluation lost if merged into current item.status |
| essay_evaluation_evidence | Exact result/criterion/issue citations | YES | NO | NO | NO | NO | KEEP | Candidate question evidence set does not show what this judgment actually cited; N:M FK-backed membership |
| essay_generated_rewrites | Optional frozen AI example | YES | NO | YES | NO | YES | KEEP | Generated later/on demand, absent for many evaluations, not reproducible by rerun; no extra version table |
| essay_learning_events | First meaningful stage actions | YES | NO | YES | NO | YES | KEEP_MINIMAL (KEEP) | Actual display/rewrite start is not generation/submission timestamp; shorter retention than learning history |
| essay_ai_processing_runs | Provider attempt telemetry | YES | NO | YES | YES | YES | KEEP | One logical evaluation can timeout+retry; per-run model/tokens/latency/cost cannot fit one overwritten result row |
| credit_accounts | Entitlement principal/lock root | NO, stable identity | PARTIAL | YES | YES | YES | KEEP | Zero-balance identity, locking and profile detachment; no balance column/cache |
| credit_grants | Grant origin/expiry/allocation identity | YES | PARTIAL | YES | NO | YES | KEEP | Ledger movement alone lacks frozen expiry/receipt terms; balances per grant derive from ledger |
| essay_billing_decisions | Policy authorization incl zero-charge/failure | YES | NO | YES | NO | YES | KEEP | Free/rejected/failed request may have no consume; decision≠movement. Policy key/version never reinterpreted |
| credit_transactions | Committed credit movements | YES | NO | YES | YES (append) | YES | KEEP | Consume/refund/reserve/release audit lost by balance-only model; append adjustment instead of changing consume |

Not added: dimension-history table, draft revision-history, rewrite-version graph, credit-balance
source table, global timeline, growth snapshots. Common competency mappings, target-preference
history, private image/OCR derivatives and institutional memberships remain FUTURE outside the19.
Their later creation does not require rewriting immutable attempts/evaluations. Target history is
an explicit exception: past unrecorded preferences cannot be reconstructed; Owner accepts lower
MVP priority. This is not claimed to be recoverable later.

## Historical fact versus derived analytics

| Data | Historical fact | Derived | Preservation |
|---|---|---|---|
| Submitted answer | YES | NO | Full immutable attempt snapshot, not only diffs |
| Evaluation/model judgment | YES | NO | Evaluation + selected provider run + versions/hashes |
| Criterion level | YES, AI's judgment | NO | Dimension attached to evaluation and criterion version |
| Issue state observation | YES, assessment | NO | Progress + explicit predecessor + evaluation/attempt/time |
| First meaningful example view | YES | NO | Event with source evaluation and actual learning stage |
| AI timeout/tokens/latency | YES | NO | Per-run record; timeout timestamp survives reconciliation |
| Authorization/free-revision reason | YES | NO | Frozen decision terms + milestone timestamps |
| Grant/consume/refund | YES | NO | Grant terms + transaction ledger |
| Current issue state | NO | YES | Latest valid comparable observation, not permanent truth |
| Recent trend/current strength | NO | YES | Scoped history, sample_count/time span/criteria/regime |
| Total evaluations/revisions | NO | YES | Domain facts; exclude provider retries and distinguish re-evaluations |
| Available credits | NO | YES/cache | Grant-aware ledger sums minus reservation; no cache now |
| Event retention coverage | YES, operational contract | NO | Retention boundary; absent expired events never imply “never viewed” |
| AI growth sentence | NO | YES | Not stored as student truth; future version/input scope if persisted |

## Improvement history and recurrence

A local issue is “what this session is trying to improve”; its progress is “what this assessment
found.” `previous_progress_id` explicitly refers to the earlier completed observation of the SAME
issue. It records assessed attempt through evaluation FK; created_at is recording time, attempt
submitted_at/evaluation.completed_at are separate event times. Never interpret a missing progress
row as resolved. `unchanged` means an unresolved issue persists without material improvement. A still-resolved
issue is explicitly assessed as resolved again, not unchanged. `recurred` requires an explicit
previous resolved observation, meaning reappeared after resolution.

Across tests/sessions, a reviewed normalized key+version provides a semantic grouping candidate.
Q11 finds resolved→open/recurred across sessions for the same student and reviewed key. It does
not automatically mutate the student's old issue or certify a permanent weakness. If normalization
is absent/candidate, exact cross-session recurrence is **UNKNOWN**, while category-level frequency
remains available. Later reviewed mapping can attach to stable issue/criterion IDs without rewriting
past results. No free-text label joins, automatic universal issue master or unreviewed global graph.
MVP normalization is fixed at issue creation; later reclassification uses a future reviewed mapping
to the stable issue ID, not a silent edit of the original assignment.

Current state derives from the selected valid evaluation regime. Explicit invalidation excludes an
erroneous result from growth queries while preserving its history. An original `RESOLVED` is not a
promise of lifelong mastery. One sample cannot establish a stable weakness or upward trend.

## Minimal event contract

Domain timestamps already reconstruct session start, submission/rewrite submission, requested/
completed assessment. Do NOT duplicate them as events. Keep:
- **example_rewrite_viewed (MVP):** actual successful display, first per source evaluation + stage
  + current stage-attempt; same button10 times in one stage records1 meaningful fact.
- **rewrite_started (MVP):** first editor engagement for revision of a source attempt, once per source
  attempt; draft may later be replaced/deleted, so current draft is not sufficient history.
- **official_source_opened (OPTIONAL):** product usability only; not student-growth prerequisite.
  Leave collection off until purpose/retention agreed; schema permits it, no body/URL payload.

Stages: first_evaluated / rewrite_started / rewrite_submitted / rewrite_evaluated. Source evaluation
identifies WHICH example; stage_attempt_id identifies current progress (may differ). Both stay in
the same session by FK. Server validates that the rewrite exists/completed and derives current stage;
client cannot claim stage or timestamp to make itself look independent. Stage records are immutable.
After shorter event retention, core attempts/evaluations remain; viewing analysis must restrict to
known covered windows. No record is not proof of no viewing, including off-platform viewing.

## Evaluation, processing, billing history

Client-generated UUID persists per logical request across taps/retries; server validates owner,
attempt, immutable payload hash, regime and request_kind. Reused UUID + changed payload =409.
Partial UNIQUE also catches different UUIDs for the same active/completed student attempt/regime.
An operator re-evaluation is explicit and has a fresh UUID/version; it is not a transport retry.
Definitively failed/cancelled requests stay frozen and may be retried with a new UUID. Timeout
is not definitive failure. Completed evaluation records additionally have terminated_at; failure/
cancellation timing isn't inferred from request time.

Provider run1 can be unknown/timeout; run2 can succeed. Keep run1 timed_out_at even if it later
resolves, and preserve terminal tokens/model/latency/status. Only one selected result exists; evaluation also freezes its selected provider/model/prompt context
so operational retention cannot silently destroy version comparability. Provider
retry count is not the student's charge count. Cost at completion may be NULL or an explicitly
labeled estimate. Do not overwrite a completed run when a later bill arrives. Estimate from retained
usage under a versioned pricing calculation; actual invoice reconciliation is a future separate
operational record, not a mutation of the original telemetry fact. Unknown stays unknown.

Decision keeps policy_key+policy_version, reason, required units, included parent, milestones.
Zero-charge included revision exists without a fake consume. Grant expiry/origin is immutable;
changing entitlement terms requires a new grant and explicit movements, not UPDATE expiry.
Refund = new positive ledger row referencing original consume; original consume stays.

Ledger unique idempotency key plus per-decision/per-grant movement uniqueness prevents a duplicate
consume under a random new key. Basic1-credit policy uses one grant/unit. Future multi-grant decisions
can have one consume per allocation, not necessarily one physical row overall. Account lock and
cross-row amount/eligibility/refund checks remain mandatory; a UNIQUE alone cannot prevent two
DIFFERENT decisions spending the final unit. Reference concurrency fixture makes this distinction.

## Corrections, deletion and retention

Completed result content remains immutable. A one-time invalidated_at + reason annotation can be
added without altering body/level/hash; cannot be overwritten/cleared. Corrected result is a NEW
evaluation with optional supersedes_evaluation_id and reason, same attempt. Coarse whole-evaluation
invalidation is MVP; per-issue correction workflow/administrator UI deferred. This prevents treating
known erroneous issue matching as permanent truth without a temporal/event-sourcing framework.

Reference detachment on authorized erasure is a narrow UPDATE exception: previous_progress_id /
supersedes_evaluation_id can become NULL, with all other historical content unchanged. Later
observations must not cascade away just because a predecessor was erased. Financial evaluation
link can similarly detach. These permissions are not student direct-write grants. Server erasure must
fence jobs and preserve audit; service-role arbitrary DELETE remains a deployment security concern,
not something RLS solves. No claim of immutability against a malicious database owner.

| History domain | Retention concern / erase boundary |
|---|---|
| Content | Core submitted snapshots, private; user answer/session/account erasure; future private images independently purged, OCR doesn't replace source |
| Evaluation / dimensions / progress | Core learning history, versioned; erase with authorized source scope, detach predecessor references; preserve correction annotations until erasure |
| Learning behavior | Purpose-limited first meaningful events, potentially shorter retention; no click/autosave history; cannot use absence after expiry as evidence |
| AI processing | Operational purpose, tokens/model/errors not prompts/PII; no indefinite retention assumption; account-learning erasure currently cascades; anonymous aggregates future separately reviewed |
| Financial | Separate retention review; no answer/profile body; user/evaluation links nullable on erasure, ledger/grants/decisions retained under policy, not universal learning cascade |
| Canonical evidence | Reuse source resource; stable IDs/version/hash/locator, no binary copy per evaluation. Hash proves identity, not perpetual availability of external content |

Periods/rights/minor/provider/legal conclusions remain review items, not invented policy.
No ranking/percentile between students. Same university/criterion/regime first; different university
stars are not equal absolute ability. Common competency mapping is a later reviewed derived layer.

## Query verification and growth claims

[history_queries.sql](../supabase/review/essay_lab_product/history_queries.sql) has concrete PostgreSQL
queries, all parsed/reviewed statically; no query was executed against student/Production rows.
Disposable fixture expectations are executable in the runtime runner but **NOT_RUN** here.

| Query | Evidence extracted |
|---|---|
| Q1 | Hanyang submitted snapshots and dates/durations/counts across attempts |
| Q2 | Each evaluation's criterion IDs/levels, contract/regime and frozen selected-model snapshot; includes invalidation for audit |
| Q3 | Issue discovery/improvement/resolution/recurrence, predecessor, assessed attempt/evaluation/recording time |
| Q4 | Last5 same-criterion same-regime selected results; fixture2→3→3→4→4 |
| Q5 | University-specific reviewed normalized issue/category observations; no label matching |
| Q6 | Included first revision linked to prior billing/evaluation; dimension and issue change |
| Q7 | First meaningful example-view stage and source result vs submission/assessment times |
| Q8 | Model/contract changes and per-run failures/retries distinguishable from writing change |
| Q9 | Charge/free decision/consume/refund history with original policy and milestones |
| Q10 | Failed requests whose reservation is released and consume0 |
| Q11 | Reviewed cross-session recurrence candidates after earlier resolution |
| Q12 | University writing/revision counts/time/known-limit compliance |

Execution context: Q8 reads operator-only per-run telemetry through an authorized, owner-scoped
server path; it is not a direct client SQL permission. Q2 uses frozen evaluation model context and
remains available when operational runs have expired. Never accept an arbitrary user filter from
a client without authentication/authorization.

No N+1: set joins/CTEs over owner-scoped roots. Existing indexes cover FK/unique identities and
session recency; add attempt(session_id,submitted_at) for timeline and progress(issue_id,created_at)
for observation chronology where required. No global timeline table; UNION domain timestamps when
needed. Per-user recent30days filters actual submitted/evaluated dates, not profile state.

Growth sentences must cite input rows/scope and include sample count/time range. “Recently absent”
requires explicit resolved/negative observations, not missing item rows. “Overall improving but a
previously resolved connection problem returned” requires both comparable Q4 levels and Q3/Q11
observations. No invented trend from one sample or mixed evaluation versions. Exact recurrence
without reviewed normalization remains unknown, not an AI guess.

## Identity and next gate

`profiles.id → auth.users.id` and shared Supabase architecture are verified schema facts. Historical
Owner acceptance: Apple/Google shared identity PASS; Kakao shared identity NOT_VERIFIED in
[auth record](auth-native-owner-acceptance.md). This review did not log in to App/LAB or compare
live UUIDs. **APP_LAB_SHARED_IDENTITY: NOT_VERIFIED for the full real-student rollout gate.**
Preserve prior provider-specific PASS; don't equate login success with equality across every path.
**REAL_STUDENT_DATA_ROLLOUT: BLOCKED_UNTIL_VERIFIED** with same account UUID E2E + A/B isolation.

Runtime package prepared with synthetic UserA/UserB, real local transaction tests, and no destructive
cleanup/Production connection. Environment NOT_READY. Full production RPC integration tests remain
pending even after fixture tests. No table reduction or design restart needed: next Owner approval →
disposable PostgreSQL/Supabase validation → fix observed defects → reviewed migration promotion →
separate authorized apply/validation → Workspace implementation. All latter steps unexecuted here.
