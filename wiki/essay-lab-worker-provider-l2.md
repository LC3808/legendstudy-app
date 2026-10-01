# Essay LAB — worker/provider and reviewer architecture

## LSA-2C Production gateway verification — 2026-10-01

**LSA_2_PRODUCTION_AUTHORIZATION = VERIFIED.** Owner applied/tracked the exact LSA-2C
migration and registered the operator. Actual Production JWT/PostgREST authorization is now
verified using existing operator and normal non-operator accounts, not service_role.
[Sanitized result](../supabase/verification/quality_authorization/gateway_verification.json),
[read-only verification runner](../tool/verify_quality_gateway.py),
[offline safety tests](../tool/test_quality_gateway.py).

| Gate | Actual result |
|---|---|
| LSA_2_PRODUCTION_SQL / LSA_2_MIGRATION_TRACKING | APPLIED / APPLIED;22 remote versions, only LSA-2C added |
| QUALITY_OPERATOR_REGISTERED | YES; real JWT helper returns true |
| ADMIN_ALLOW | PASS; bounded list200 |
| STUDENT_DENY | PASS; helper200/false; list/detail403 |
| ANON_DENY | PASS; helper/list/detail401 |
| FULL_ANSWER_OPERATOR_ACCESS | NOT_ASSESSABLE: list contains no evaluation cases |
| Forged identity | Subject-tampered JWT401; caller-supplied user_id RPC argument404 |
| profile/school/admin_users | Not authorization sources: deployed canonical function bodies match; no profile/admin/allowlist writes tested |
| Existing Essay student RLS/ACL | PASS; all17 Essay table +44 function catalog records unchanged against pre-apply capture |
| provider005 / day_targets tracking | PRESERVED_NOT_APPLIED / PRESERVED_SEPARATE |

No Production fixture/evaluation/user was created to force detail coverage. Full-answer
projection remains proven by the isolated canonical finalize tests, but **real operator detail
and full-answer retrieval were not exercised**. Recheck that read when a legitimate case exists
under separate authorization; do not reinterpret NOT_ASSESSABLE as PASS or create data now.

Quality table PK/FK auth.users CASCADE, owner postgres, two columns and RLS/no policies match.
Client table rights remain NONE; service_role S/I/D only. All three deployed function bodies
match the reviewed migration; SECURITY DEFINER, empty search_path, owner postgres; EXECUTE
only authenticated (PUBLIC/anon/service_role absent). Forged-token checks use only the two
Owner-authorized test identities; no arbitrary account lookup or data mutation.

Credentials were read from Owner-owned repository-external0600 files; JWTs, account identifiers,
response bodies and any answer text are never written to output/artifacts. Password sign-in
necessarily creates Auth sessions/logs; no app/profile/allowlist DML, SDK profile sync, SQL apply,
ledger repair, provider call or service-role client test occurred. Existing private history104
hashes remain intact. Six synthetic safety tests cover redaction, full-answer branch without
real data, route restrictions, redirect refusal and file safety.

This closes authorization only. No Quality UI, LAB adapter, Human Quality persistence or Wiki
reorganization implemented. The global recent-list index candidate remains a separate launch
performance decision; it is not resolved by an empty list. Owner decides the next task.

## LSA-2C shared Quality authorization — 2026-10-01

**Historical preparation checkpoint: MIGRATION_READY_NOT_APPLIED; superseded by the Production verification above.** Quality Console is a future **WEB operator surface** at
`lab.legendstudy.com/ql`; authorization is the **shared Supabase backend**, canonically owned
by App migrations. No Flutter/LAB UI or adapter, Production SQL/ledger write, provider005,
provider call, model selection, Round2, Human Quality persistence or live student traffic.
[Owner application/security/rollback package](../supabase/verification/quality_authorization/README.md),
[canonical SQL](../supabase/migrations/20261001000100_quality_read_authorization.sql),
[isolated T1–T15](../tool/test_quality_authorization.py),
[sanitized evidence](../supabase/verification/quality_authorization/validation.json).

### Canonical reconciliation and cross-review

The development checkout `~/development/legendstudy-app` was old `main` at d07671e with only
one initial migration. Canonical `codex/essay-scaffolding-vnext` worktree at
`~/.codex/worktrees/essay-scaffolding-vnext/레전드스터디 앱` had **23 local / 21 remote** before
this task; **24 local / 21 remote** after preparing this migration. All21 remote statement
ASTs match their local SQL (parser source positions ignored). This checkout difference
explains Claude's one-file observation; no migration restoration/replay was necessary.
Provider005 remains local-only, not applied. `20260930000100_day_targets_least_privilege`
remains SQL-effect verified (anon NONE/auth CRUD/RLS preserved) but ledger-untracked;
LSA-2C does not repair it. New `20261001000100` conflicts with neither pending version.

Read-only LAB sources at `claude/intelligence-school-architecture`/7bd9f2d:
`docs/architecture/ARCHITECTURE_BASELINE_V1.md`, `LSA-1_SERVER_AUTHORIZATION.md`,
`LSA-2_SERVER_AUTH_IMPLEMENTATION.md`, and `lsa2/01…04`, shim and test harness.
No LAB file/branch merge. Draft differences resolved:

- timestamp-only pagination could skip equal-time cases: use a paired timestamp/UUID cursor;
- explicit projection adds canonical sentence/CORE/history mapping, full answer retained;
- list result changes from rows to a versioned envelope; LAB must adopt the final DTO below;
- inherited default grants cleared on each **new** object, including service_role excess;
- authorization checks the real auth.uid allowlist, matching authenticated request subject
  and numeric future expiry; gateway still verifies JWT signature/revocation;
- bounded session navigation and distinct selected/latest processing, not an unbounded history aggregate;
- actual App migrations + strict finalize replace draft Essay-table stubs in isolated PG17.

### Authority and operating policy

`quality_operators(user_id PK/FK auth.users ON DELETE CASCADE, created_at)` means **Quality
LAB access only**. No admin_users, profile/school, organization, reviewer assignment or generic
RBAC authority. No client table rights/policies/self-enrollment. Operator membership deletion
revokes future RPC access; this minimal allowlist is current authorization, not a human-review
or historical audit store. Offline registration is Owner-controlled, exact UUID only.
Functions are postgres-owned SECURITY DEFINER, empty search_path, qualified relations;
PUBLIC/anon/service_role EXECUTE revoked, authenticated EXECUTE only, with an internal gate.
Service_role table S/I/D exists for offline administration, **not web runtime**.

Full submitted answer is necessary Quality evidence; account name/email/phone/OAuth identifiers
are excluded by default. Free-text answers can themselves contain identifying content: this is
privileged personal-data access, not anonymization. Presentation pseudonym is
`left(md5(session.user_id::text),12)` (48bits), stable and linkable with a small nonzero collision
risk; sufficient for small v0 presentation, never a lookup key, identity or authorization fact.
Use evaluation/attempt UUIDs for case navigation, not the pseudonym.

Owner policy: early/Pilot **detailed near-census** review; mature **problem-focused + sample-based**.
Privileged READ audit is POST_LAUNCH. Privileged WRITE audit is required when such UI/API
operations are introduced; preserve Owner registration approval/execution records now. No new
audit framework here. Quality membership alone does not grant existing invalidate/re-evaluate
RPC permissions; their independent current write gate remains unchanged.

### LAB public read DTO — ql-read-v1

Only these documented RPCs/DTOs are a LAB dependency. Do not query underlying tables, rely on
ownership/private helper schemas, use service_role or infer undocumented JSON fields.
This DTO is now deployed with Production gateway authorization VERIFIED above.
Real operator full-answer retrieval remains untested because there are no evaluation cases.

`is_quality_operator() → boolean`: caller only, no user-id parameter. False for missing,
malformed, expired or nonmember authenticated context; anon lacks EXECUTE. Other RPCs raise
42501 before any case lookup if unauthorized. SQL role/context tests do not replace real
signed-token gateway verification after Owner application.

`ql_list_cases(p_limit integer=50,p_before timestamptz=NULL,p_before_id uuid=NULL) → jsonb`:

- envelope `{dto_version, cases:[], next_cursor:null|{requested_at,evaluation_id}}`;
- p_limit NULL→50, clamp1…100; both cursor values absent or both supplied, otherwise22023;
- order `(requested_at DESC,id DESC)`, strict tuple `<` cursor; next cursor is last returned
  case only when an additional row exists. Equal timestamps never skip. Concurrent new cases
  appear on refresh, not earlier pages of an existing traversal; no snapshot-isolation promise;
- case keys: evaluation_id, attempt_id, question_id, university_name, exam_name, admission_year,
  question_label; requested_at/completed_at/submitted_at; status, request_kind, invalidated_at;
  model_provider/model_name/prompt_version/contract_version/evaluation_version/regime_key/
  evidence_manifest_sha256; core_count, has_generated_rewrite, has_subsequent_student_attempt,
  processing_outcome, student_pseudonym. **No answer body.**
- core_count NULL when not completed, legacy or observation-incomplete; 0 is valid completed1.3.
  Rewrite booleans express row/attempt existence, not completed content or human quality.
- future filters may be explicit optional inputs or a versioned RPC, preserving the paired
  cursor and filtered traversal; no generic query DSL, offset pagination or silent overload.

`ql_case_detail(p_evaluation_id uuid) → jsonb`: null input22004; authorized missing caseP0002.
The answer at student_submission is the immutable submitted attempt, never the current draft.

| Field group | Canonical mapping / meaning |
|---|---|
| dto_version/evaluation_id/student_pseudonym | envelope and presentation identity |
| question_context | question/exam/university catalog; submitted question_metadata_version and conditions snapshot separately preserved |
| student_submission | attempt id/no/time, character_count/count_rule_version, input_method, body_sha256, **answer_full_text** |
| evaluation | status/request_kind/supersedes/correction/invalidation; summary, strengths[], rewrite_checklist[], uncertainty/error_code; request/completion time |
| dimensions[] | dimension_id/criterion_id/key/label/description/definition version/source evidence/origin/weight, level1…5, explanation/uncertainty |
| improvements[] | progress id/previous id, previous_progress, issue key/category/status/title/explanation/next_action/priority, is_core, versioned observation |
| scaffolding_availability | available / not_completed / legacy_not_available / incomplete |
| core_improvement_keys | selected active issue keys ordered by canonical priority; [] valid; NULL if unavailable |
| sentence_feedback | version1 sentence objects + restored linked_issue_key and progress_id; [] vs NULL preserved |
| history_context | frozen input_snapshot.scaffolding_context; prior selected evaluation/progress bindings and availability |
| previous_review_representation | explicitly states progress links + uncertainty; original review array is not stored |
| official_evidence[] | current question_evidence resource/role/location/mapping/source hash and source URL |
| evaluation_evidence_links[] | evidence id linked to dimension_id or progress_id |
| frozen_evidence_bindings / frozen_criterion_bindings | exact input_snapshot ID/version/hash bindings used for this evaluation; not full PDF text |
| reference_metadata_scope | current_catalog; frozen bindings identify evaluated versions |
| student_attempts[] / attempt_window | immutable same-session attempt_no ±10 (max21), body/hash/time, explicit truncated flag |
| generated_rewrite | latest generated row's origin/status/body/completion; NULL absent; **not student rewrite** |
| provenance | provider/model/version/prompt/contract/evaluation/regime/evidence completeness/manifest and input/output hashes |
| processing | selected evaluation run only; run id/no, provider/model/status/start/completion/latency/token/cost/error/timeout metadata, NULL absent |
| latest_processing | most recent evaluation run (may be unknown/nonselected), explicitly separate from selected result |
| session_evaluations[] / session_evaluations_truncated | at most100 recent id/attempt/status/supersession/invalidation/time for navigation, explicit truncation |

Arrays of available relational facts are []; missing optional scalar/object facts are NULL.
Scaffolding NULL is deliberately not an empty list. Timestamps are timestamptz instants, not
academic years. Evaluation lifecycle uses requested/processing/completed/failed/cancelled;
processing uses processing/completed/failed/unknown; improvement uses
open/improved/resolved/unchanged/recurred. Preserve vocabulary, not generic Quality PASS.
NULL tokens/cost means unknown/not provided, never zero. `cost_basis=estimate` is not actual
cost; only provider_reported is provider-reported. No cached/total-token fields are invented
from pending provider005. Completed processing is not Human Quality PASS.

Criterion labels/description, question context and official resource projections are current
catalog metadata. Frozen evidence/criterion bindings identify the evaluated versions; do not
claim a silently changed current source is the historical source. Full PDF/transcription bodies,
original previous-review reason array, independent human judgments, and complete pagination of
sessions beyond the stated history windows are **NOT_AVAILABLE_YET** through this DTO.
Truncation must be visible, never presented as a complete history. Prior links remain addressable
via ql_case_detail(evaluation_id), without a parallel Quality history store.

### Canonical Contract 1.3 mapping

[Persistence mapping](essay-lab-scaffolding-persistence.md#lsa-2c-quality-read-mapping--2026-10-01):
`essay_improvement_progress.scaffolding_observation` is versioned JSON `{version:1,
core_focus:boolean,sentences:[]}`. Sentence root is its issue FK→improvement_items.issue_key.
Quote offsets are Unicode code points, zero-based half-open `[start,end)` in the submitted body;
no normalization/UTF16 conversion. Original sentence order within each root is retained.

CORE membership is active progress (`status <> resolved`) with core_focus=true. Priority is
**ordering, not membership**: strict finalize requires each CORE priority equal its 1-based
core_improvement_keys position. Thus selected keys sorted by priority recover original CORE
order for valid1.3 writes. NON-CORE includes remaining improvements, including useful local
polish; resolved history stays visible. No priority<=2/category heuristic. Zero roots/CORE/
sentence feedback is valid. Older/incomplete observations remain unavailable rather than
being misclassified. No duplicate sentence table or is_core column is created.

Progress chain is session→attempt_no→evaluation→issue/progress→previous_progress_id.
Assessed prior outcomes live in linked immutable progress/status, NOT a second Quality stream.
`not_assessable` reasons append to evaluation.uncertainty_note, not fake resolved progress;
original previous_improvement_reviews array/reasons are not losslessly stored separately.
Reevaluation supersession/invalidation and student vs generated rewrite remain distinct.

### Validation, performance and next gate

T1–T15 PASS on isolated PG17 with actual12 dependency migrations and strict1.3 finalization;
no Essay-table shim. Auth schema/roles only are emulated. The final Owner registration script
also runs there. Tests cover exact ACLs, expired/malformed subjects, forged identity, profile
non-authority, 108 cases including105 equal-time ties, full answer, Unicode/root mapping,
CORE order/zero/non-core, prior progress, original RLS/table/function ACL preservation and
bounded rollback with unexpected dependency rejection. Live21 migration AST matches, 210 column-type comparisons across15 referenced tables and
four canonical function-body matches confirm prerequisite compatibility. Actual JWT/PostgREST authorization has since passed; see the Production closeout above.

Performance **FINDING**: live EXPLAIN (no ANALYZE/load test) shows Limit→Sort→Seq Scan for
global recent order. Existing attempt_recent index is not a global ordering index. Candidate
`essay_evaluations(requested_at DESC,id DESC)` needs a separate launch decision/approval;
no speculative index added. Page+1 selection bounds expensive enrichment, not base scan.
PK/FKs, attempt(session,attempt_no), progress(evaluation), processing(evaluation,run_no) and
selected-run partial index support detail joins; session list sorts a bounded result over the
session population. JSON extraction is limited to selected cases' progress. No dashboard read
model or denormalization proposed. This is not a Production latency/SLA claim.

Seven preservation answers: (1) no new learning/evaluation fact; only current authorization
membership/time; (2) original immutable attempts/evaluations/progress and frozen bindings are
read directly; (3) no historical UPDATE, minimal allowlist removal is not an audit history;
(4) same auth.users identity, no LAB identity; (5) derived learning review projection, not an
admission outcome/human verdict; (6) explicit narrow operator access, full evidence with identity
minimization, same privacy/erasure policy, no anonymous-data claim; (7) DTO is a projection,
not a new canonical fact store or inferred score.

Architecture remains HEALTHY_WITH_DEBT. Owner application/tracking and Production
authorization verification are complete. The index decision remains separate; read audit/
sampling/statistics are post-launch. LAB mapping → web Quality v0 → Human Judgment design
remain future, separately authorized tasks. STOP here; no UI/live adapter or broader work.

## Quality Console boundary — Owner clarification 2026-09-30

**Quality Console v0 = NEXT DESIGN, READ-MOSTLY.** 기존 canonical evaluation,
dimensions, strengths, CORE/NON-CORE, sentence feedback, generated/student rewrite,
progress, processing telemetry를 읽어 시작한다. 새 evaluation store를 만들지 않고
기존 invalidation/operator reevaluation 경로를 보존한다. Model evaluation은 Human Quality Judgment가 아니며 owner lifecycle/status RPC도 human verdict가 아니다.

**HUMAN QUALITY PERSISTENCE = DESIGN BEFORE REAL-STUDENT PILOT.** 체계적 Human QA를 위해 evaluation-bound judgment/reviewer/history가 별도로 필요할 수 있으므로 실제 학생 Pilot 전에 설계한다. **GOLDEN SET DB = DEFER.** 이번 정합화로 console/reviewer/schema/authorization를 구현하지 않는다.

권고 후속 gate: LAB server authorization → LAB Essay canonical contract mapping →
Quality Console v0 design → Human Quality persistence design → real-student Pilot.
각각 별도 검토/승인 대상이며 Primary model selection, Production worker/AI, Round2 또는 real-student traffic 자동 승인이 아니다.

## L2-C3 Pilot latency review — 2026-09-30

New Hanyang validated structurally at87.079s: above the existing75s generator limit. With the
planned reviewer25s + validation/finalize10s + safety10s, the total would be132.079s, exceeding
120s lease. Therefore this private result does not establish Production fit. The600s Pilot
bound was not needed for this observed completion, and does not explain the earlier unknown.
Educational quality and operational feasibility remain independent Owner decision dimensions.

[Investigation / bounded validation](essay-lab-model-bakeoff-l2-b.md#l2-c3-hanyang-investigation-and-sequential-gate--2026-09-30)
is separate from Production. Pilot observations: Sookmyung GPT66.865s, older Hanyang GPT83.944s,
Claude197.740s, Hanyang C2 unknown300.071s. These are not an SLA or comparable latency benchmark.
HIGH operational risk against current generator<=75s and immutable120s lease including reviewer/
validation/finalize. Sookmyung fits the generator target once, not a reliability guarantee;
older Hanyang GPT exceeds75s, Claude exceeds120s. An unknown duration proves no server completion.

Student submission→accepted evaluation request→processing→status polling/result/reconciling
should reuse existing L1/L2 RPC/status flow, not hold a synchronous screen request for minutes.
An async UI does not itself solve lease expiry. Any background continuation, lease/reconciliation,
provider reliability and hosting changes require a separate deployment review. No worker/RPC/
lease/timeout/hosting implementation changed here; only private Pilot gets a600s total bound.


L2-B4: [Option A / prompt v2 offline implementation](essay-lab-scaffolding-persistence.md#l2-b4-option-a-implementation--2026-09-30)
retains wire1.3 and strict parser. Worker/dispatch still use their historical prompt; no live
binding or policy registration is activated. Real provider calls0; GPT candidate only.

L2-B3: Owner Human Review is now recorded; GPT is PRIMARY_CANDIDATE, not selected. Existing signed-review/security boundary remains. Concrete/logic semantics and nullable-link storage blocker are design-only. [vNext contract design](essay-lab-scaffolding-persistence.md#l2-b3-vnext-contract-design--no-implementation).

Owner2026-09-30: [Official evidence archive strategy](essay-lab-data-foundation.md#official-evidence-archive-strategy--owner-decision-2026-09-30) governs future packages: raw PDF truth, separate scoring rules/non-criteria and reviewed transcription. Current L2-B2 prompt/evidence/outputs stay frozen; no worker change.

> Current follow-up: [L2-B2S supplemental](essay-lab-model-bakeoff-l2-b.md): new GPT2 HTTP200,
> both SENTENCE_ROOT parser failures. Owner review now prefers GPT as candidate; Claude2 PASS and original429 history preserved.
> No retries/fallback/repair or Round2. Checked-in execution gate remains closed.
> Production worker/reviewer/AI/traffic remain inactive. Historical L2-A3 plan below is superseded.

## L2-A3 reviewer architecture

2026-09-30 · **ARCHITECTURE REVIEW COMPLETE / recommendation, NOT ACTIVATED.**
Starting HEAD `7274e49`; latest branch retained. L2-A2 accepted runtime evidence and migration
bytes match. No source/contract/SQL changes, DB connection, AI call, credential provisioning or
scheduler. Analytics, School/Coupon work and Owner iOS edits preserved.

**Recommendation: Option B — one evaluator, deterministic validation for every result, and
independent review of a bounded set of sentence/progression claims.** Do not require a second
full LLM evaluation by default. Independent review means a separate qualified decision source,
not necessarily another model. First Pilot: human Owner/qualified Korean essay reviewer reads
all frozen output privately. Production: conditional review boundary remains **PARTIAL** as a
design and **not deployed**. Current code still requires a full signed receipt on every result.

Immediate next: approve this review scope → choose/pin an API model and Pilot budget → prepare
private representative packages + human rewrite → authorize staged Pilot. Applying L2-A2 is
separate and **CONDITIONAL**, not a prerequisite for an artifact-only quality Pilot. No new
schema/RPC is required for this recommendation; do not introduce an asynchronous review queue.

### What is deterministic, what is judgment?

A means executable validation, B means fallible educational judgment, C means a proposed
independent pre-publication decision. These layers overlap; passing A never proves B.

| Requirement | Class | Existing enforcement / remaining boundary |
|---|---|---|
| Owner/session/question/attempt, immutable answer hash | A | Auth/RPC/FK + worker hash; no client identity trust |
| Exact Unicode codepoint span, emoji/decomposed Hangul/whitespace | A | Parser + Scaffolding SQL; no normalization, fabricated quotes rejected |
| Criterion identity/version, evidence IDs/role/locator/hash/mapping | A | Frozen snapshot + trusted cache/allowlist; not proof of interpretation |
| Shape, enums, duplicate JSON keys, root/span IDs, core<=3/sentences<=5 | A | Strict worker parser + SQL; semantic duplicate roots still B |
| Explicit previous-progress link, compatible regime, all prior core reviewed | A | Frozen context and SQL transition/link checks; not proof of actual improvement |
| Billing/lease/fencing/idempotency/result+settlement | A | Existing RPC transaction boundaries, unchanged |
| Diagnosis, strengths, priority, useful concise action, minimal edit | B | Prompt, bounded contract, Pilot rubric; cannot be certified by type checks |
| Stance, correct passage/criterion interpretation, non-repetition | B | Human Pilot review; independent review when a material conflict is identified |
| Every sentence observation, regardless of provider category or claim_scope | B+C | Independent review before publishing sentence-level error/correction claims |
| Quote-only local root, including resolved-local without a current error quote | B+C | Existing adapter/SQL require trusted exact `local_reviews`; retain this requirement |
| Assessed previous-task outcomes: open/unchanged/improved/resolved/recurred | B+C | Narrow review of progression reason, current answer and frozen predecessor; no whole-answer regrading |
| not_assessable | A+B | Required reason/coverage checked; no positive/negative progress assertion created |
| Official criterion diagnosis without sentence/progression claims | A+B | Single-model judgment can publish only after the proposed policy and model quality are approved |
| Missing mandatory evidence, fabricated official weight/length, invalid source IDs | A failure or B/C defect | Reject unverifiable output; do not use a reviewer to waive missing source/ownership checks |

C is deliberately keyed to **all sentence entries and explicit prior-task claims**, not merely
`claim_scope=local_sentence`, a provider confidence number, a keyword blacklist or an invented
risk score. A provider cannot evade review by attaching an official evidence ID to a sentence
criticism. There is no claim that deterministic routing discovers every semantic error hidden in
ordinary prose. Routine university feedback retains single-model error risk; Pilot QA, clear
non-official-score language and later sampled/dispute review address that residual risk.

### Alternatives and choice

Comparisons below are architecture estimates, not measured API benchmarks.

| Option | Educational safety / false correction risk | Latency and provider cost | Operational complexity / availability |
|---|---|---|---|
| A: evaluator + deterministic checks only | Grounding structure protected; local diagnosis/progress can still be false. Does not satisfy current quote-only trusted-review rule | One generation; lowest incremental review cost | Simplest, but unacceptable as a blanket bypass of existing local review |
| **B: evaluator + narrow independent review** | Covers sentence false positives and unsupported progression; residual ordinary criterion risk explicitly retained | One generation plus bounded review only when flagged; human review has labor/latency, rules or models have separate costs | Small explicit router/reviewer boundary; unavailable required review must not publish flagged claims |
| C: full second LLM on every result | May find more errors but can share the generator's mistakes or introduce its own; not ground truth | Additional full-context/model output cost and serial latency on every request | Two model dependencies, versions, monitoring and failure modes; cannot assume 120s feasibility |
| D: sampled/risk review with ordinary publication | Useful for monitoring; sampling alone cannot prevent the first false local correction | Lower average review spend, variable latency | Selection/calibration/coverage needed; cannot sample away mandatory C claims |

| Option | Mid-October feasibility | Auditability | Scaling |
|---|---|---|---|
| A | Fastest code path, but local contract violation unless those claims are absent | Source/result history retained, no independent decision | Simple; quality risk scales with volume |
| B | Best bounded scope; still conditional on model/Pilot and a timely reviewer or honest omission path | Exact flagged claims + review reason + signed payload/version | Review load follows sentence/progression frequency; measure it, do not assume it is rare |
| C | Highest implementation and latency risk | Two outputs to reconcile, no automatic correctness proof | Full extra inference for all results |
| D | Appropriate later as supplemental QA, not a launch substitute for B | Must preserve selection scope and sampled verdict | Efficient monitoring after calibration; coverage blind spots remain |

**Choose B.** D-style post-publication sampling is a later supplementary control, not a second
recommended launch architecture. No second model is selected or made mandatory by this decision.
If narrow review cannot meet quality/latency, report that gate rather than silently enabling A.
Omitting every progress judgment would undermine the learning-loop product; successful, meaningful
second-attempt guidance is a launch gate, not an acceptable permanent `not_assessable` fallback.

### Sentence and official-evidence publication policy

| Sentence kind | Production recommendation |
|---|---|
| Grammar/formal | A future narrowly validated rule/checker may independently verify a truly formal error with an auditable rule ID; none is currently implemented. Prompt + quote alone is insufficient |
| Awkward expression | Treat as optional suggestion, never style preference asserted as error. Independent review or omit |
| Sentence structure / unclear meaning | Reviewer must explain actual ambiguity/broken relation; missing content alone is not ambiguity. Independent review or omit |
| Local logical contradiction | Reviewer reads sufficient surrounding text and both propositions; retain local provenance, no fake official source. Independent review or omit |
| Criterion/passage application | Keep official evidence and student quote separate. If a sentence observation is emitted, review it regardless of official scope; ordinary criterion-level diagnosis follows A+B |

For an optional new sentence finding: prefer **omission** if no reliable judgment is possible.
Do not delete just the quote while retaining the same unsupported error claim in an improvement.
Omit its purely local new root/core reference too, or reject the result if it is material or linked
to required prior history. Do not hide an important official content problem to shorten output:
retain a separately justified criterion-level diagnosis without inventing a sentence defect.

These are proposed trusted adaptation rules, **not implemented filtering**. Any accepted-payload
change must retain the frozen original, record an explicit disposition/reason, revalidate all
relations, recompute hashes and obtain approval for the final payload. The existing exact-match
`local_reviews` must refer to that exact final issue/sentence array. No silent sanitizing, raw output
mutation, automatic retry or false approval. A future narrow application implementation must test
this transformation before normal publication; this review changes no current behavior.

Official allowlist proves **which** approved source was used, not that it says what the model
claims. Never allow a quote-only label to authorize passage interpretation. Reference/example
answers remain excluded from generator inputs; blind target answer provenance is retained privately.
Conflicting/missing required evidence blocks output. An identified material interpretation/stance
conflict needs independent decision or rejection. Routine grounded diagnosis does not require a
second full evaluation. A verified length rule must carry its original source/context; current
`cache.length_requirement` is a trusted optional cache field, not independently certified by its
presence. Package review must verify it; unknown length stays unknown, never guessed/deducted.

### Progression rule

Review old core tasks **before** choosing new ones. Evaluate the current immutable answer against
the prior action and criterion, with explicit compatible predecessor and concrete current support.
A disappearing sentence, score increase, fewer observations or provider omission is never evidence
of resolution. `resolved` means the specific task was addressed in this answer, not permanent mastery.
`recurred` requires the exact previously resolved root plus new demonstrated occurrence, not a
free-text similarity merge. `improved` requires a defensible partial change; unchanged/open require
current supporting grounds too. Reviewer scope is these assertions, not rescoring the entire essay.

If source/reading/context is insufficient, use existing `not_assessable` + reason: no progress row,
no inference of resolved or unresolved, old history unchanged. Missing mandatory prior reviews is
an error, not implicit unknown. Frozen previous progress includes prior observation/quote/context;
if the reviewer needs a previous full answer that the package cannot safely provide, do not fetch
unapproved data or guess. Request a later approved package improvement or mark not assessable.
All OPEN→IMPROVED→RESOLVED→RECURRED facts remain append-only evaluation-local judgments.

### Signed boundary: current facts and proposed refinement

`SignedReview.verify` currently requires **all eight full-output quality flags true**, matching
package/output hashes, evaluation ID, reviewer-key membership, expiry and complete local-key list.
`Worker.execute` calls it on **every** result. The adapter checks exact local objects; SQL checks
trusted `local_reviews` structure and local/official separation. **SQL does not verify the HMAC or
judge prose.** The narrow worker is part of the trusted computing boundary; its credential must
never be given to the generator/provider or Flutter.

Retain this mechanism for Pilot QA, full audits, disputed outputs and model/prompt regressions.
Do not issue an all-true full-review receipt after merely checking three local claims. Conditional
production B needs a separately versioned **application review receipt/routing policy** with exact
covered claim IDs, verdict/reason and final payload binding; the existing full-review verifier is
preserved for old receipts. No schema or RPC change is needed: a trusted adapter can still emit
existing exact `local_reviews`. No receipt format/route has been changed in this task.

Minimum trust contract for that follow-up:

- Reviewer type: named qualified human for first Pilot; production may use a validated narrow
  checker or independently instructed model/service after explicit approval. A second call by the
  same generator auto-signing its own output is not independent review.
- Auth: private server-to-server authenticated reviewer request; no public signing endpoint. The
  operator authenticates to controlled tooling for human QA. Provider output is data, never approval.
- Secrets: versioned reviewer identity/key in server secret storage, outside Git/client/prompts.
  HMAC implies both signer **and verifier** hold the shared secret and are trusted; it does not
  cryptographically isolate a compromised worker. Provider transport is not given that secret.
  Public-key verification is a possible later refinement, not a new mandatory service this phase.
- Binding: exact evaluation + answer/package/output hashes; retrieve immutable model/regime/prompt
  binding from trusted job. Future conditional receipts must also bind review policy/version and
  coverage. Preserve separate raw vs final-payload hashes if a disposition changed the payload.
- Replay/expiry: current MAC receipt has an expiry no more than 900s ahead; it is not one-time.
  Same-result finalize retry is permitted by existing DB idempotency. Cross-output/evaluation
  approval fails; lease/fencing always wins. A receipt does **not** extend the 120s run lease.
- Rotation/revocation: remove revoked versioned reviewer key from trust map, stop publishing affected
  pending jobs, retain prior audit evidence. Keep signed decisions in private durable audit/checkpoint
  storage with access/deletion controls, not a public telemetry property. Hosting is not deployed.

### Pilot quality review versus live runtime

**First recommendation: private artifact-only human-reviewed API quality Pilot.** This deliberately
separates educational validation from DB transaction validation already exercised synthetically.
It does not call `Worker.execute` as though real execution were enabled, hold a reservation during
human review, finalize an expired run, or relabel a later claim as the original provider call.
The private Pilot runner/config remains to be prepared after model selection/authorization; it is
not implemented by this document. Human verdicts are dated private QA artifacts, not runtime
publish receipts; do not manufacture a 900s receipt to bypass a days-long review. Stable private
fixture IDs/history snapshots must be distinguished from DB-issued records. Model-bound production
RPC E2E remains a separate gate afterward.

Proposed total cap **4 generation calls**, staged: first one original answer per university (2),
freeze → Owner review/explicit continuation → one genuinely human-authored rewrite per university
(2). Reviewer model calls **0** in this first design. This task authorizes **0** calls. A smaller
one-university pair may be explicitly authorized first; never silently enlarge the cap.
Each timeout/refusal/malformed result consumes its attempt slot. No automatic retries, extra
"repair" calls, hidden best-of selection or replacement of old Run A outputs.

Use existing reviewed Sookmyung2025 mock1-1 / Hanyang2024 afternoon2 sources only after manifest,
transcription, criterion and length provenance review. No recollection required. Existing official
high-scoring answers remain **official published answers**, not relabeled real student submissions.
The person rewriting is identified by role/consent privately; no model-written rewrite presented
as student-authored. Original evaluator input excludes quality labels, other reference answers,
previous Pilot verdicts and ground truth. Evaluation2 receives only the compatible frozen prior
feedback/context, not post-freeze ground-truth coaching hidden as evidence.

Private retention: exact original/rewrite bytes + provenance, input/evidence/extraction/history
hashes, request/model/prompt/contract/schema/settings, raw response, parsed/final payload hashes,
start/end/latency, provided input/output/total tokens and nullable actual cost, errors as safe codes,
reviewer verdict/reasons and accepted/omitted claims. Freeze first response **before** reference
comparison; separate later annotations, never overwrite it. Git only sanitized counts/hashes/gates;
no answer/quote/prompt/raw feedback, PII, token, credential or full reviewer receipt. No chain-of-
thought collection. Private access/retention/deletion and provider handling must be approved first.

Rubric: PASS/PARTIAL/FAIL for priority, strengths, discipline, diagnosis/actionability, minimal edit,
stance, duplication, official/local provenance, honest progression and useful Korean. Exact spans,
source identity, invented-error absence and stance preservation are hard gates; any invented source,
stance change or unsupported RESOLVED/RECURRED blocks acceptance. Core and sentence lists may be
empty where justified. All critical gates must PASS for each retained case; priority, useful guidance and previous-core
assessment must also be acceptable to the qualified reviewer. A noncritical PARTIAL remains named
and needs explicit Owner acceptance of the limited next step, not an automatic quality PASS.
No growth trend from two samples; report per-case findings and limitations.

- **Sookmyung gate:** clear sentence with missing content is not `unclear_meaning`; good-answer
  core/sentence count is not a quota. Preserve valid content criticism at the proper level.
- **Hanyang gate:** retain substantive issue discovery while each core action is short and focused;
  verify official length rule and include relevant checking guidance, never invent a threshold.
- **Rewrite gate:** every previous core gets evidence-backed assessment or explicit not_assessable;
  changed/removed text alone is insufficient. Compare compatible regimes and preserve strengths.
- Capture actual measured API latency/counters; prior CLI77.132s/120.981s and tokens are historical
  evidence only, not product API SLA/cost. Unknown actual cost remains NULL; any rate calculation is
  a separately labeled estimate. No paid credits/real student rows are involved in this quality Pilot.

Production B must fit reviewer + generator + parsing/finalize inside the existing120s lease (current
candidate generator timeout75s). Proposed planning budget: generator<=75s, reviewer<=25s, validation/
finalize<=10s, >=10s safety margin; these are targets, not observed capability. A slow human is not
this synchronous production reviewer. Required review unavailable/expired → no flagged publication,
existing failure/unknown/reconciliation behavior, no blind re-generation. Async hold/renewal or a
new waiting state would be **beyond L2-A2**: report the exact blocker and STOP for separate approval,
not silently extend a lease. This task selects no such schema/RPC extension.

### Model-selection decision packet

**READY_FOR_MODEL_SELECTION YES; no selected model or quality winner.** OpenAI Docs skill used for
official OpenAI capability checking; provider docs were read2026-09-30, no inference calls. These
are API families to screen, not a claim all variants support the same schema/context or a shortlist
approved to run:

| Candidate surface | Verified documented capability | Repository evidence / decision gap |
|---|---|---|
| OpenAI Responses | Strict structured output supports a JSON Schema subset, but content can still be wrong. [Official guide](https://developers.openai.com/api/docs/guides/structured-outputs) | Transport candidate + mock tests only; no approved API model or measured Korean/API quality |
| Claude API | Structured JSON output via `output_config.format`; schema limitations and first-schema compilation latency. [Official guide](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) | No adapter/runtime evidence here; must test the same strict contract, not assume interchangeability |
| Gemini API | Schema-driven structured output documented. [Official guide](https://ai.google.dev/gemini-api/docs/structured-output) | No adapter/runtime evidence here; validate selected model/schema subset and usage identity |

For **each exact candidate**, Owner/ChatGPT decision packet must specify immutable model/version
availability in the intended account, endpoint, prompt/reasoning settings, supported output schema,
context/output limits, privacy/retention/region constraints and current dated input/output/cache/
reasoning token rates. No prices or model quality ranking are invented here. Select on measured
capability, not which adapter happens to exist. Historical Codex CLI model results are not API
availability, quality or billing proof.

| Capability | Required evidence before acceptance |
|---|---|
| Strict structure / deterministic compliance | Exact1.3 transport, nullable example handling, enums/caps, refusal/truncation behavior; server checks remain mandatory |
| Korean reasoning and writing | Blind paired fixtures, strengths/priority/clear actions; qualified human assessment, not provider benchmarks |
| Long context | Actual evidence + answer + frozen prior context + output allowance fits selected tokenizer/limits without silent truncation |
| Latency | Measured end-to-end and review timing vs120s; four calls cannot establish production p95/SLA |
| Cost | Project spend cap + max output/call; measured counters; estimate input*rate + output*rate + relevant cache/reasoning charges, separately from actual invoice |
| Evidence adherence | No extra references/ground-truth leakage; exact source/criterion binding and correct interpretation |
| Stance / minimal editing | No added policy preference or wholesale AI rewrite; optional example only where needed |

Missing decision inputs now: exact API candidate approval, maximum total Pilot spend, reviewer
person/availability, private package/rewrite approval and secure credential **location/provisioning
plan**. No secret in chat, and no provider/worker secret is provisioned this phase. Automated narrow
review model selection, if later needed, is a separate cost/quality comparison, not automatic reuse
of the evaluator. First Pilot human review avoids requiring that second model decision now.

### History preservation check for this review

The seven canonical questions apply: (1) a review verdict/omission is a timestamped operational
Decision, not a new student fact; (2) it cannot be inferred from parser PASS, so retain its private
payload/version binding; (3) never overwrite frozen provider output or prior progress; (4) existing
attempt/evaluation identity stays authoritative; (5) review decisions are distinct from Learning
observations and Admissions Outcomes; (6) private access/consent/erasure/retention applies to review
artifacts too, no marketing export; (7) confidence/trend is derived and uncertain, never permanent
student truth. No storage or collection was added in this architecture-only task.

### L2-A2 migration and final gates

Reviewed005 bytes match accepted hash
`6c0d5a2a40fe5129ff8b9a718fae53bf60d3cd5226c2b9b440d30932f1c9ed3b`.
KEEP19, nullable total_tokens/no backfill; empty server resolver, frozen claim identity; telemetry
worker-only ACL, fixed path/ownership, existing fence and immutable history retained. v1.2/legacy
unconfigured runs are untouched. No premature model, reviewer or real-worker activation.

**L2_A2_PRODUCTION_APPLY_RECOMMENDATION: CONDITIONAL.** Technically useful to deploy dormant
provenance/telemetry infrastructure independently of reviewer selection; not necessary for the
artifact-only Pilot. Before any separately authorized apply: confirm linked LegendStudy project,
ledger/local chain/hash and exactly intended pending migrations, canonical/Product row baselines,
ACL/RLS/security contract, dry-run scope and post-apply read-only preservation. Those fresh
Production preflight checks were **NOT_RUN** here. No unexpected drift or extra migration may be
bundled. An apply does not make the empty model registry or production reviewer ready.

Validation this task: existing worker/binding unit23, backend static50, review static55 and Wiki/
diff/hash checks. Prior temporary venv was absent; recreated a disposable static-parser environment.
No changes warrant another DB runtime/Flutter build; their accepted L2-A2 PG/JWT/L1 results are
referenced, **not reported as rerun**. No Production catalog assertion was newly executed.

| Requested gate | Result |
|---|---|
| REVIEWER_PRODUCTION_PATH | PARTIAL — bounded architecture specified; live path still absent |
| READY_FOR_MODEL_SELECTION | YES — requirements ready, no model chosen |
| READY_FOR_L2_A2_PRODUCTION_APPLY | NO today — conditional recommendation, fresh preflight/authorization outstanding |
| REAL_AI_PILOT_READY / READY_FOR_REAL_AI_PILOT | NO — model/budget/package/human rewrite/reviewer + explicit run approval outstanding |
| DB_CHANGE_REQUIRED / MIGRATION_REQUIRED / RPC_CHANGE_REQUIRED | NO additional change for selected design; accepted005 remains pending |
| SIGNED_REVIEW_BOUNDARY | Retained unchanged now; proposed conditional version + full Pilot/audit use |
| REAL_AI_RUNS / PRODUCTION_APPLY / PRODUCTION_AI / REAL_STUDENT_TRAFFIC | 0 / NO / NO / NO |

**NEXT, in order:** (1) Owner/ChatGPT review Option B + staged four-call ceiling; (2) approve exact
API model/budget and human reviewer, validate existing packages and private storage; (3) prepare
an explicit private artifact runner without enabling production Worker, synthetic smoke tests;
(4) separately authorize first2 calls → freeze/human QA; (5) approve genuine rewrites/next2 →
freeze/progression QA; (6) only after quality acceptance, implement/test the conditional application
review receipt/router and timely production reviewer, separately configure model policy and
authorize005 deployment/rollout as appropriate. No production credential deployment or traffic
is implied by any earlier step. If a required change reaches SQL/RPC beyond005, report and STOP.

---

## L2-A historical implementation record

2026-09-29 · **PARTIAL / NOT PRODUCTION READY**. L1 and Production G1/status/Scaffolding
acceptance remain preserved. This package implements and tests worker orchestration, strict
parsing and an independently authenticated review boundary. It does **not** claim the requested
real-provider Original→Rewrite loop or educational quality PASS. Actual AI calls: **0**, cost: **0**.

## Blocking facts and next bounded correction

1. No approved product API provider/model/credential was available to this task. Earlier Pilot
   Codex CLI execution is not a product API integration. A missing credential location/model
   question was sent to Owner; no secret requested in chat. Do not reuse Codex login credentials.
2. Deployed `essay_private.scaffold_claim_v13` inserts `provider='unconfigured'`, model name equal
   to regime and no selected model version. Processing identity is immutable from insertion.
   `essay_finalize_success` copies that identity into the completed evaluation. Calling a real
   provider now would create misleading historical metadata. The worker therefore refuses the
   real path **before claim**; only the guarded synthetic local runner is enabled.
3. Token/cost/latency columns exist, but no narrow public operation can ingest them. Worker cannot
   UPDATE the processing table, and service_role is not an acceptable workaround.
4. Signed review verification is implemented, but an independent semantic reviewer/service and
   its secret provisioning are not deployed. A valid quote or provider `claim_scope` is not
   proof of correct diagnosis. A test signer is explicitly synthetic, not an Owner quality review.
5. Official cache assembly validates frozen mapping identity and extraction bytes. A reviewed
   representative official package/criterion mapping and student-authored rewrite still need to
   be bound for the real loop. Synthetic criterion text is never labeled real official evidence.

**Minimum proposed forward correction**, after exact model policy is selected (not applied here):

- Retain KEEP19 and existing columns. Preserve existing v1.2/in-flight code exactly.
- For newly enabled1.3 regimes, claim resolves a **server-owned versioned provider/model/prompt
  policy** and inserts it with the run, returning the same binding to worker. Do not allow clients
  or provider output to select it. A model change needs a new regime policy; do not silently
  change the meaning of previous comparisons. Existing unconfigured runs are not rewritten.
- Add a narrow fenced worker telemetry operation using evaluation/run/token, existing lock order,
  current run/lease checks, allowlisted nonnegative usage/latency and nullable actual cost.
  Preserve idempotent identical retry; changed telemetry under the same run conflicts. Write once
  before terminal transition; record available timeout/failure usage too. No raw provider error,
  prompt/body, arbitrary JSON or direct table GRANT. Actual cost remains NULL when unavailable.
- Success remains existing atomic result+settlement; telemetry is operational, not a prerequisite
  for changing credit policy. Validate model binding, stale/terminal denial, erasure, retry and
  existing RLS/ACL/search_path/history with an isolated forward migration before review.

No migration was fabricated around an unselected model. **DB table/column changes: NO;
RPC/forward migration correction required: YES (proposal, not implemented/applied).**

## Implemented boundary

[Worker/parser/provider adapter](../tool/essay_lab/live_worker.py) uses existing Python tooling,
no new backend framework or dependency. One explicitly dispatched evaluation per invocation;
no unrestricted queue scanning, scheduled automation, auto-generation retry or Production launcher.

1. Narrow `essay_claim` supplies submitted answer + frozen input/history. Never read mutable draft.
2. Read-only server cache must match every allowed evidence ID/role/hash/version/locator and
   criterion ID/version. Verify extraction SHA separately from original source SHA. Reference
   answers and extra cache contents are not sent; no provider-supplied URL fetching.
3. Provider-specific OpenAI Responses transport candidate is isolated from product contract.
   It requires explicit model/key; `store:false`, strict JSON Schema, no tools, bounded response
   and75-second network timeout. No provider is selected by this candidate. Its actual network
   behavior remains NOT_RUN. [Official structured output specification](https://developers.openai.com/api/docs/guides/structured-outputs)
   defines the transport shape; it does not certify educational correctness or zero retention.
4. Strict parser rejects duplicate JSON keys, unknown fields, Pilot `uncertainty_note`, malformed
   types, wrong answer/attempt, invalid criteria/evidence, duplicate roots/spans, oversized core/
   sentence lists, fabricated/normalized quotes and unsupported history transitions. Wire nullable
   `example` is the only explicit adaptation: null becomes absent before RPC validation.
5. Independent reviewer attests complete package/output hashes, evaluation binding, expiry,
   named quality checks and exact local-root coverage via HMAC. Provider cannot supply the receipt
   or access its key. Server constructs existing `local_reviews` only after verification. Changes
   to diagnosis/direction/root/quote invalidate the approval. This is authentication of a review,
   not an automated semantic classifier. Never auto-sign based on passing structural validation.
6. Existing Scaffolding adapter creates final RPC shape. Durable **private** checkpoint callback
   receives exact finalize args before RPC; retry that payload only after ambiguous finalization,
   never rerun AI. Lease token/output are not ordinary logs or telemetry. The caller must provide
   encrypted/access-controlled checkpoint persistence; no production store is installed here.
7. Provider ambiguity/reviewer timeout invokes `essay_timeout`, retaining reservation and exposing
   reconciling. Definitive rejection/invalid output invokes failure/release. Finalize transport or
   DB failure is not converted to provider failure; fence/atomicity remain server-authoritative.

Legacy1.2 worker dispatch is intentionally not converted; original adapter and DB contract stay
unchanged. New worker rejects legacy input before provider. Existing legacy tests remain applicable.

## Review, hosting and secrets

Recommended deployment is a small server-only process/container consuming authenticated explicit
job IDs. Credential broker supplies a short-lived `essay_worker` JWT; worker receives neither
service_role nor JWT signing key. Finance identity is separate. Provider project key and review
verification secret live in server secret storage, never Flutter/Git/reports. Reviewer identity
is independently provisioned; provider has no access to signer or receipt API.

The120-second immutable lease includes provider+review+finalization. Reviewer must finish inside
remaining lease time; otherwise timeout/reconciliation, not late publication. Asynchronous/manual
review taking longer needs a separately reviewed continuation design, not silent lease bypass or
another model call. Hosting, broker, durable checkpoints, reviewer availability and dispatch
recovery are **not deployed**. No real student queue is consumed.

## History and reliability

Seven preservation answers: (1) request/run/outcome/timing are operational historical facts;
(2) submitted text, fixed evidence/history and immutable result remain the learning basis;
(3) retries append new runs, never overwrite old evaluations/progress; (4) ownership stays with
existing Auth/session FKs; (5) learning and billing decisions remain separate from Admissions
Outcome/marketing telemetry; (6) private data only, no names/profiles in provider package, erasure
fences removed jobs; provider/backup/checkpoint retention remains a gate; (7) no growth prose,
analytics cache or permanent student weakness is invented from current observations.

Request/start/success/failure/unknown/completion/retry count and settlement/release can be derived
from existing evaluations/runs/ledger. End-to-end duration is derivable; **actual provider latency,
selected model identity and tokens cannot be truthfully ingested through the current worker RPC**.
Synthetic runtime writes sanitized receipts through a callback; this is not durable production DB
telemetry. Unknown provider charges remain unknown, never converted to an estimated actual cost.
No GA4/Crashlytics/Ads/IAP/Paywall or duplicated analytics events.

## Validation

[Unit tests](../tool/test_essay_live_worker.py), [guarded local runner](../tool/essay_lab/live_worker_runtime.py),
[sanitized report](../supabase/validation/essay_lab_product/l2_worker_result.json).

- New worker unit tests15 PASS, including adversarial subcases, signed review replay/tamper,
  Unicode, previous review/unknown, real-call fail-closed and ambiguous-finalize no-release.
- New worker actual local Auth JWT/PostgREST checks43 PASS: synthetic provider,
  OPEN→IMPROVED→RESOLVED→RECURRED, paid/included, invalid output/failure release, timeout/retry,
  idempotency, account isolation and erasure with financial preservation.
- Existing native77+55 / Scaffolding80 / timing306 / G1 84 / status55 / post-G1 Scaffolding80 PASS.
- Existing local JWT legacy37 before/37 after / Scaffolding79 / timing306 / G1 88 / status55 /
  post-G1 Scaffolding70 PASS. Includes stale/late success, rollback injection, local quote provenance,
  caps, previous-core snapshots, not_assessable, lease and v1.2 coexistence.
- Existing static46 + review55 PASS; Flutter56 + sentence5/analyze and actual Dart JWT PASS.
  System Python lacked pglast; reran review suite successfully in the existing disposable venv.
- Sookmyung content-vs-clarity and Hanyang concise-task/confirmed-length corrections are prompt and
  validation requirements only. **Real quality regression NOT_RUN**, not PASS from string assertions.

Reproduction: fresh guarded local Supabase → existing `submit_timing_runtime.py --supabase` →
`status_projection_runtime.py --supabase` → `python -B -m tool.essay_lab.live_worker_runtime`, with
existing disposable environment variables and private `ESSAY_L1_CLIENT_FIXTURE` path. Native uses
an empty loopback `essay_review_*` DB. Never run against linked Production. Shut down only these
owned disposable instances; preserve private credentials outside Git.

## Decision gate

WORKER_PROVIDER_INTEGRATION: **PARTIAL** (synthetic boundary PASS, real provider path blocked).
SCAFFOLDING_QUALITY: **PARTIAL / NOT_RUN for L2 real AI**.
READY_FOR_PRODUCTION_WORKER_DEPLOYMENT / IAP / REAL_STUDENT_TRAFFIC: **NO**.

Next: Owner supplies approved API model + secure credential location and independent reviewer path;
resolve the narrow metadata RPC correction in isolation; bind reviewed official fixture and actual
student rewrite; perform at most the authorized first two real evaluations, freeze outputs/cost,
then assess quality separately. Production activation still needs separate Owner/ChatGPT approval.
