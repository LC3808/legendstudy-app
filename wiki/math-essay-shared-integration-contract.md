# MATH-2R — Shared integration contract

2026-10-02. **COMPLETE / MATH-2B integration corrections RESOLVED at design level.**
**OPTION_C_FINAL: PASS. READY_FOR_MATH_DB_IMPLEMENTATION: YES**, subject to separate MATH-2C
implementation authorization and the mandatory isolated regression contract below. No migration,
role, function, code, Production connection, student-data inspection or provider call in this task.
This is implementation-ready architecture, not implemented or runtime-verified Math persistence.
Owner product/privacy decisions required: **0**. Production apply readiness: **NO**.

## Authority and bounded reconciliation

APP `codex/essay-scaffolding-vnext` starting HEAD/origin/actual remote:
`a6a696fe1f8990b2c36746377731c5814b968bb9`; clean except preserved `supabase/.temp/`.
[MATH-2B](math-essay-canonical-db-security-review.md) remains historical cross-review, including its
then-NO readiness. This successor resolves its shared integration blockers, not its 21-entity design.

LAB authorities (read only):
[MATH-2A](https://github.com/LC3808/legendstudy-lab/blob/1bd275b059e6f42a1ccc8181e2c211d4dd4a5517/docs/architecture/MATH-2_CANONICAL_DATA_PERSISTENCE_CONTRACT.md),
[MATH-3A](https://github.com/LC3808/legendstudy-lab/blob/0d8068e883d3eed742b7963f0778af356a3b8800/docs/architecture/MATH-3_VISION_INPUT_ARCHITECTURE.md).
MATH-3A is the verified remote Math branch tip. Its confirmed-extraction version, provisional
candidate steps, page/region provenance and input-readiness boundary are preserved.

Actual existing contracts reviewed:
[HQP migration](../supabase/migrations/20261001000200_human_quality_persistence.sql),
[Quality read](../supabase/migrations/20261001000100_quality_read_authorization.sql),
[Credit schema/guards](../supabase/migrations/20260928000200_essay_entitlements.sql),
[server locking/release](../supabase/migrations/20260928000300_essay_server_operations.sql),
[G1 policy](../supabase/migrations/20260929000300_essay_credit_commercial_core.sql),
[corrected ADR-2](../supabase/migrations/20261001000300_account_deletion_lifecycle.sql),
[Storage cleanup](../supabase/functions/account-deletion-worker/storage.ts),
[worker phases](../supabase/functions/account-deletion-worker/worker.ts),
[ownership constraints](account-deletion-ownership-compatibility.md).
MATH-2B's ledger23/ADR-2 absent snapshot is historical metadata evidence, **not reverified here**.
Future implementation/apply must inspect its then-current prerequisites; no unrelated migration replay.

| Blocker | Final decision |
| --- | --- |
| HQ Essay-only binding / E1 error | HQ-A: preserve Essay FK name, add typed Math FK, exclusive binding; both evaluation FKs CASCADE, reviewer SET NULL |
| HQ validator/DTO coupling | Version-dispatched table validation, parent-bound finding checks, separate Math APIs; explicit legacy history field projection |
| Generic billing discriminator assumption | New typed Math binding to existing financial decision; no wallet, historical table rename or request_kind alteration |
| Lifecycle / private bytes | Future fenced Math preparation + Storage verification + DB graph erasure; final Auth-last and E1/E2 retained |
| Worker authority | Separate extraction/evaluation runtime capabilities, one narrow Math executor, existing financial authority via private helpers |

## A. Shared Human Quality — select HQ-A

| Option | Benefit | Cost / decision |
| --- | --- | --- |
| HQ-A: two typed evaluation FKs, exactly one | Keeps existing judgments/findings, correction and operational workflow; no historical data rewrite | **SELECTED**. Narrow constraints/validation/history-body edits required; existing Essay column stays `evaluation_id`. |
| HQ-B: abstract evaluation identity | Uniform future domains | Reject now: new global identity/registry and historical migration/backfill not needed for two domains. |
| HQ-C: separate Math HQ tables | Existing table shape untouched | Reject: duplicates correction, idempotency, review-state and privacy authority; not the accepted shared-store direction. |

### Exact binding and correction constraints

Existing `human_quality_judgments.evaluation_id` keeps its name, type and Essay FK/CASCADE.
Make only its NOT NULL requirement conditional. Add `math_evaluation_id`, nullable UUID FK to
Math evaluation PK **ON DELETE CASCADE**. Exactly one of these two references is non-null.
No generic evaluation UUID and no writable domain discriminator. Domain is derived:
`evaluation_id present → ESSAY`, `math_evaluation_id present → MATH`.

Keep UNIQUE(id,evaluation_id) and its existing composite supersession FK. Add
UNIQUE(id,math_evaluation_id) and a second composite FK from
(supersedes_judgment_id,math_evaluation_id) to (id,math_evaluation_id).
Both use normal MATCH SIMPLE semantics: the inactive domain branch is null/skipped, but the
exactly-one constraint guarantees that the active domain FK is enforced for every correction.
Thus a Math correction cannot target an Essay parent, even if evaluation UUID values coincide.
Retain UNIQUE(supersedes_judgment_id), self-reference rejection and immutable binding fields.

A narrow shared BEFORE INSERT parent guard and the writer lock the selected parent and accept only an existing active head of the same evaluation;
new judgment id is server-generated, never caller supplied. The parent guard requires the parent
to exist before that row insertion (not a later row in a multi-row insert); immutable bindings prevent
back-link updates. This closes the cycle hole that ordinary non-deferrable FKs alone would leave
for cyclic multi-row inserts. Validate both API and direct privileged constraint fixtures. Independent reviews have null supersedes; never silently select a
previous review as their parent. Any currently authorized reviewer can correct another review,
recording the correcting auth.uid(). Global client_submission_id uniqueness remains across domains.

E1 deletes the bound evaluation's entire QA graph, including hashes, findings and notes. Invalidated,
superseded or reevaluated output remains reviewable history, not erasure. E2 auth.users deletion
nulls reviewer_user_id on others' surviving judgments; immutable guard permits only that existing
RI exception. No reviewer snapshot or detached student hash. A reviewer/student account exercises
both rules independently. Domain binding cannot be SET NULL: deletion is CASCADE.

### Rubric and finding validation dispatch

Do not edit `essay_private.hq_rubric_valid(jsonb)` or the meaning of hq-rubric-v1. Replace the shared
table's fixed-version/result checks with a strict two-branch dispatcher:

- Essay binding → exact `hq-rubric-v1` and the existing validator, unchanged.
- Math binding → exact `hq-math-rubric-v1` and a new private Math validator.
- Anything else → reject, including null/unknown versions or a rubric of the other domain.
  The constraint requires a true validation result; SQL NULL must not pass a CHECK accidentally.

This review defines the **human QA** Math rubric shape below; it is not the AI `math-rubric-v1`
student-evaluation rubric and assigns no scoring weights or new mathematical product behavior.
It maps existing QA purposes onto the evidence already required by MATH-1/2A/3A.

| hq-math-rubric-v1 keys (all keys required, no extras) | Verdicts / context |
| --- | --- |
| diagnosis, core_priority, actionability, evidence_adherence, valid_path_preservation, hallucination_absence | OK / CONCERN / FAIL. `valid_path_preservation` asks whether valid alternative student reasoning was preserved, not whether it matches the official solution. |
| extraction_fidelity | OK / CONCERN / FAIL when image/PDF extraction was required; NA for pure typed input without extraction |
| step_reasoning | OK / CONCERN / FAIL when the selected leaf profile requires reasoning/path evaluation; otherwise NA |
| hint_quality | OK / CONCERN / FAIL when the frozen output has hints; otherwise NA |
| progression | OK / CONCERN / FAIL when the frozen evaluation has a prior-evaluation comparison; otherwise NA |
| generated_solution | OK / CONCERN / FAIL when the frozen evaluation output includes a generated solution; otherwise NA |

Presence/context comes from frozen server data, not client booleans. Required evidence erased,
missing or unavailable is **UNASSESSABLE**, never coerced to NA; preserve an existing judgment
but reject a new supposedly fully evidenced submission. Response-format applicability remains
server profile authority; brevity is not an error. Keep overall PASS/PASS_WITH_NOTES/NEEDS_REVIEW/FAIL,
no FAIL dimension under either PASS bucket, no CONCERN under PASS; PASS has no findings,
PASS_WITH_NOTES findings are MINOR only. No numeric quality score or automatic FAIL action.
Bounds: 32 KiB canonical submit payload, ≤20 findings, summary ≤2000 characters, finding note ≤1000.

Existing finding-shape validator stays unchanged. Shared findings table accepts **either** exact
legacy shape or exact Math shape, plus a required insert-time private validation trigger joining
its judgment: apply only that parent's domain validator and target checks. Shape union alone is
not authorization or domain integrity. The parent must already exist and is immutable. The new
trigger enforces Math target membership; legacy branch retains current writer target validation
and does not impose a new existence check on historical rows whose source was legitimately erased.
Do not use a CHECK that queries other tables. No new finding domain column/backfill is needed.

Math finding shape retains issue_category/severity/target_kind/target_ref/note; unknown keys reject.
Severity stays MINOR/MATERIAL/CRITICAL. Math categories are the existing generic categories
FALSE_CORRECTION, INVENTED_ERROR, EVIDENCE_MISREAD, UNSUPPORTED_CLAIM, CORE_PRIORITY_ERROR,
PROGRESSION_ERROR, UNDER_SPECIFIED_GUIDANCE, MISSING_IMPORTANT_ISSUE, OTHER, plus explicit
EXTRACTION_MISREAD, ROOT_PROPAGATION_ERROR, ALTERNATIVE_PATH_REJECTION. These label human QA
observations only; they do not change mathematical error classification or trigger actions.

| Math target | Exact target_ref shape | Server proof |
| --- | --- | --- |
| OVERALL | null | Bound Math evaluation exists and is reviewable |
| SOLUTION_STEP | {step_id: UUID} | Step.evaluation_id equals judgment.math_evaluation_id; published step, not extraction candidate |
| ROOT_ERROR | {error_id: UUID} | Same evaluation; error classification ROOT; its step also same evaluation |
| EXTRACTION_REGION | {extraction_run_id: UUID, region_id: UUID} | Run equals evaluation's pinned selected/confirmed run; region belongs to that run and its artifact/page/attempt; base candidate lineage alone is insufficient |
| ALTERNATIVE_PATH / REFERENCE | {path_kind: REFERENCE, solution_version_id: UUID} | Exact version in the evaluation's immutable considered-reference set, not merely a known alternative in the catalog |
| ALTERNATIVE_PATH / STUDENT | {path_kind: STUDENT, evaluated_path_key: bounded string} | Exact key in bound evaluation's validated private path result; unique within its versioned output, never a global arbitrary UUID |

The two ALTERNATIVE_PATH shapes are disjoint and exhaustive. Reference alternatives follow MATH-2B's
merge into solution versions. No new reference-path master. Evidence for a base extraction error
can be shown through pinned provenance, but the target region is in the evaluated selected version;
its lineage identifies the originating candidate. Do not retarget a finding to the latest run.

### Hashes, retries, projections and legacy byte compatibility

Keep shared reviewed_output_sha256, submission_payload_sha256, rubric fields, notes, timestamps,
reviewer, selection/action and correction fields. `reviewed_generated_rewrite_id` remains Essay-only
nullable with its existing FK/RI behavior; enforce null for Math. Do not introduce an arbitrary
Math-generated-artifact UUID into that column. The existing Essay submission hash includes the
selected rewrite id; HQP has no separate stored rewrite-body hash to silently generalize.

Math finalizer computes output_sha256 from a versioned normalized canonical output envelope:
exact input/profile/source/solution/run/confirmation pins; rubric result; ordered steps and edges;
causal/errors/CORE/hints/private evaluated paths; considered references; reevaluation deltas; optional
generated solution if included in that frozen output. Arrays have specified deterministic ordering;
object serialization uses the server's versioned canonical JSON representation, UTF-8 and SHA-256.
Exclude changing lease/status, wall-clock polling fields and download URLs. Provider payload/hash
is never accepted as the canonical digest. Store hash version with Math output, not shared HQ.
A generated solution created later is not silently attached to an already reviewed hash; it needs
an explicit later review-context contract, not mutable v1 evidence.

Math submit payload has exactly these allowed keys: dto_version (`hq-math-write-v1`),
math_evaluation_id, expected_output_sha256, client_submission_id, rubric_version,
overall_disposition, rubric_result, findings, reference_context_reviewed (required true), and optional
supersedes_judgment_id, summary_note, selection_reason, recommended_action. Defaults match the
existing operational vocabulary (EARLY_CENSUS/NONE); unknown keys and caller reviewer/account fields
reject. The reference acknowledgment covers the actual frozen official or explicitly non-official
context; do not require a fabricated official source when approved fallback applies.

Math writer compares caller expected hash with stored output hash under evaluation lock and stores
that hash. It computes submission hash itself over normalized Math payload, explicit domain/DTO
version, evaluated subject, reviewer identity and frozen defaults. No raw payload copy in HQ.
Same global submission key + same reviewer/domain/payload returns same judgment; any changed payload,
other subject/domain or different reviewer conflicts. Authorization and pending-account restriction
are checked before any retry lookup. Essay normalization/hash bytes remain **exactly unchanged**;
add only an early foreign-domain key-conflict check, never recompute old row hashes.

**Found in actual code:** ql_list_human_judgments uses `to_jsonb(j)` minus two columns. Adding even a
nullable Math column would leak new fields into hq-read-v1. Therefore future migration must replace
that expression with an explicit legacy field projection. Exact legacy judgment fields:
id, evaluation_id, reviewed_output_sha256, reviewed_generated_rewrite_id, reviewer_user_id,
rubric_version, overall_disposition, rubric_result, selection_reason, recommended_action,
summary_note, supersedes_judgment_id, created_at; plus existing reviewer_state, is_active, findings.
Finding fields remain id, issue_category, severity, target_kind, target_ref, note. Preserve DTO names,
nulls, arrays, cursor fields/order, limits and error codes; no math_evaluation_id/domain leakage.
Semantic JSON equality is required; incidental JSON object key order is not a wire guarantee.

Existing Essay reads filter evaluation_id, naturally excluding Math. Keep explicit Essay branch
checks in writer/read review; mixed-domain UUID collision tests are mandatory. Existing
hq_projection can be reused unchanged only on the **domain-filtered** active-head summary with the
same disposition vocabulary. Version mismatch remains MULTIPLE_REVIEWS + NOT_COMPARABLE and null
consensus; never compare AI math-rubric with human hq-math-rubric or infer numerical consensus.
Math gets separate qlm_submit_human_judgment / qlm_review_state / qlm_list_human_judgments contracts,
hq-math-write-v1 and hq-math-read-v1, same bounded retry/history discipline. No version switch in
existing ql/hq RPC arguments. Existing ql-read-v1 functions need no edits.

## B. Math ↔ existing financial decision authority

Select **math_billing_bindings**: Math evaluation id (PK/FK CASCADE), billing_decision_id (NOT NULL
UNIQUE), account_id (NOT NULL). Composite (billing_decision_id,account_id) FK references existing
essay_billing_decisions(id,account_id), RESTRICT. A same-account evaluation key/context is enforced
relationally where available, with request-time locked proof that credit_accounts.user_id equals
the attempt's student. Account ownership is not caller supplied. No balance/price/status copy here.
Existing decision.evaluation_id remains NULL for Math; never a Math id in the Essay FK.

Create new Math evaluation, new financial decision and binding in the **same transaction**. Never
attach a new binding to a pre-existing unbound decision: a NULL Essay FK may be an erased Essay
history, not a reusable vacancy. Only retry of the already existing matching binding is permitted.
New decision creation uses a server-generated id and canonical retry key. Existing Essay financial
history and transaction rows are not rewritten.

Every binding INSERT locks the decision, requires its Essay FK NULL, and checks same student/account;
binding updates reject. Existing essay_billing_history_guard already rejects NULL→Essay-id
reattachment and changes to fixed terms. A decision cannot therefore be simultaneously Essay/Math:
Essay-bound decision fails the Math binding gate; existing Math decision cannot later acquire an
Essay FK; concurrent INSERT of the same decision id fails its PK. Preserve this guard, verify actual
body in isolated baseline, and test both write orders/concurrent callers. Do not add redundant domain
columns to existing decisions. No ordinary client can insert binding or financial rows.

Binding is operational linkage: deleting the Math evaluation removes it; financial decision/grants/
transactions survive with no Math UUID/hash/answer snapshot. Account detaches under existing privacy
path; opaque financial IDs/policy remain. CASCADE removal cannot release credit by itself: erasure
must release eligible reservations **before** deleting evaluation/binding. Finance policy/retention
review remains separate. Do not infer deletion domain from absence of a binding after erasure.

### Request and posting contract

MATH_INITIAL_EVALUATION / MATH_REEVALUATION belong to the Math request envelope only. No change to
Essay request_kind CHECK. A Math learning lineage pins the existing commercial policy/version; new
Math helpers map approved shared initial/revision semantics to existing decision reason/policy and
quantity. G1 v2 currently implements paid-cycle and first eligible included revision logic using
Essay-specific joins: replace only those joins in the Math helper with Math lineage, preserving the
existing grant-selection/posting policy. Never use raw attempt_no as price, or treat all reevaluation
as free. No cross-domain included-revision parent; same Math student/lineage and eligible settled
parent required. No Math price introduced here.

Financial posting authority remains existing Credit tables and executor, via new narrow **private**
Math-aware financial helpers. Existing Essay helper bodies/signatures and price/grant selection stay
unchanged. New helpers validate typed binding before accepting a decision id. Preserve account lock,
valid/non-expired grant selection (expiry,created_at,id), grant locks ordered by id, existing
balance/reserved deltas, (decision,grant,transaction_type) posting-once unique, reversal account FK,
terminal-decision guards, and idempotency key construction. No worker-supplied credit quantity,
account, price or arbitrary refund. Finance-only explicit refund/reversal remains a separate route.

| Stage / failure | Financial state and permitted transition |
| --- | --- |
| Upload/cheap input admission | No evaluation consumption; rejected unsupported input creates no billable job |
| Normalization/extraction/confirmation | Preferred launch order: complete READY_FOR_EVALUATION input gate before reservation; no separate Vision/confirmation/hint charge |
| Accepted evaluation request | Atomically pin ready input, policy and retry hash; create decision/binding; reserve canonical grant or authorize included zero-charge work; no consume |
| Optional earlier reservation already exists | Still never consume for input processing; failure/abandonment releases exactly once, not a new fee |
| Worker claim / provider dispatch | Valid lease + active subject + authorized/reserved decision required; no financial state transition to settled |
| Successful valid finalization | One transaction publishes complete graph and posts consume for each reserved grant, then settles decision; zero-charge authorization settles without fabricated debit |
| Invalid output/input failure/provider timeout | Persist sanitized failed/unknown processing status, release authorized/reserved decision once via canonical transitions; no success or consume merely because provider responded |
| Reconcile unknown completion | Inspect fenced canonical completion, not provider billing guess: completed+settled is stable; expired uncompleted job releases; late output cannot reopen released decision |
| Retry / duplicate request | Exact request repeats return same evaluation/decision; new attempt to process a terminally released job needs explicit new request/policy decision, no automatic provider retry |
| Account erasure | Freeze jobs; reconcile/release outstanding reservations exactly once; keep settled consumption, no deletion-triggered refund; then erase binding/personal data |

A crash either commits graph+settlement together or neither. Existing unique posting constraints
are the final duplicate barrier. Reconcile functions are explicitly permitted during erasure under
worker/fence authority; they must not call a normal-service gate that prevents privacy cleanup.

## C. Future ADR-2 Math integration (no ADR-2 change now)

Prerequisite before Math activation: exact corrected lifecycle helpers installed/verified, plus the
bounded Math hooks below. MATH-2R does not assume ADR-2 is already live. Schema preparation may be
staged inactive; no Math client/worker activation with missing lifecycle gate.

All student Math request/upload-complete/confirmation/hint/re-solve and internal extraction/evaluation
claim/dispatch/finalize paths acquire account_private.lock_subject and require allowed state. Pending
operator denied via lifecycle-aware is_quality_operator, independently of membership. Quality Math
write also locks/rechecks the bound student's state: do not add new QA to an erasing subject.
For actor+student operations obtain both subject locks in deterministic UUID order **before** calling
any helper that takes one subject lock; perform a non-locking initial membership check, then the
full locked gate. Unauthorized callers receive no existence information.

Lock order for normal Math financial work: lifecycle subject → credit account → Math attempt/lineage
→ grants in id order → evaluation → billing decision → run/children. Account-wide deletion takes
lifecycle/fenced request first, then the same account/Math order, processing bounded evaluations in
id order. Existing Essay order remains lifecycle→account→session→grants→evaluation. Never invert
account and evaluation locks in the new Math helper. HQ submission uses lifecycle locks → global
submission-key advisory lock → evaluation SHARE → correction parent; no finance locks. Test mixed
Essay/Math/HQ/delete races on one subject, including self-review and two reviewers.

### Ordered resumable erasure contract

The existing PERSONAL→STORAGE→PROVIDER→FINANCE→AUTH→VERIFY driver cannot simply delete all new
Math rows during PERSONAL: artifact metadata is needed to verify byte cleanup. Extend phases as:

1. **PERSONAL / Math prepare:** fence request, stop future dispatch/finalize and expire jobs, reconcile
   reservations. Keep Math attempt/artifact inventory and ownership while service is denied. Existing
   non-Math cleanup may proceed. No copied answer backup/deletion archive.
2. **STORAGE / Math bytes:** delete every registered Math raw/render/crop/derived/generated object;
   verify absence including in-flight upload handling below. Persist only bounded cleanup checkpoints
   on existing owned metadata/request phase; retry returns here on uncertainty.
3. **STORAGE / Math DB completion:** after byte verification, delete private Math attempt graph in
   bounded transactions. This cascades extraction, confirmation provenance, evaluation children,
   exposures/re-solves/bindings and Math HQ via E1. Resume while parents remain; do not advance early.
4. **PROVIDER/FINANCE:** preserve ADR-2 external-provider status policy and finance privacy detachment;
   unsupported revoke is not a false PASS or indefinite personal-retention justification.
5. **AUTH last / VERIFY:** require no Math private rows/bytes/jobs/bindings requiring release; then Auth
   deletion applies E2 on surviving reviews of others. Verify postconditions and remove subject
   linkage only on valid finish. ERASED receipt never carries Math UUID/hash/answer; expiry remains30d.

Hook names/locations: future Math prepare/erase helpers called by account_deletion_personal and
Storage-stage orchestration; storageEraseAndVerify in worker Ports; server verifyErasure and
account_deletion_postconditions must cover Math absence, not merely subject-null/VERIFY phase.
Official/public problem/source/profile/solution rows survive student erasure. No default analytics
copy, no detached HQ data, no global signup-benefit hold, no change to fixed336h deadline.

## D. Bounded Storage obligation registration

Use a server-owned static namespace registration in the deletion worker deployment manifest, not
an arbitrary caller-provided bucket/path RPC. Launch private Math bucket concept: `math-private`;
allowed categories raw, render, crop, derived, generated under a server-derived subject/attempt/
artifact path. Exact deployment bucket identifier is pinned once and catalog-verified before use.
Official raw artifacts, if later approved, use a separate content bucket and are never in a student
cleanup registry. D1 reference+hash remains default; D2 ordinary duration remains deferred.

Before issuing upload permission, create the owned attempt/artifact registration and expected
object identity. Ownership/path/category/MIME/size come from server admission; no arbitrary URL.
Metadata binds exact attempt/artifact/page versions; transformations register their own obligation.
Student correction creates a new confirmed extraction version preserving candidate provenance, not
an overwritten image or re-solve. Artifacts/confirmation text are operational personal data.

List/delete via supported Storage APIs only, bounded batches (at most100 objects/call,20 batches
per invocation, then resumable retry). Registry enumerates only allowed categories and this subject;
validate every returned key remains inside that prefix, reject traversal/unknown namespace. Check
registered metadata and owner-prefix inventory for unfinalized uploads; a missing object is success,
unknown listing/deletion result is retry, never proof of absence. Metadata survives until bytes are
verified absent; cascade cleanup alone is insufficient. Finite-retention purge follows the same
bytes-before-metadata rule, independent of later whole-account erasure.

**In-flight uploads:** direct authenticated upload policy must check active lifecycle. Do not mint
long-lived signed upload URLs bypassing that gate. If a transport requires a bearer upload grant,
its bounded expiry/in-flight completion is a registered obligation and activation test: deny renewal
at PENDING, wait/drain its bounded validity, sweep after expiry and verify no late recreation before
Auth-last/ERASED. No unbounded provider callback may upload after deletion. Downloads are short-lived
controlled references with explicit expiry/revocation behavior; never permanent public URLs.
Provider temp files/job references and worker caches must have bounded cleanup/expiry contracts;
unknown provider revocation stays an external status, not fabricated verified erasure.

## E. Minimum authority topology

These names describe the future migration/deployment contract; no roles created now.

| Authority | Runtime capability | Function ownership/data boundary |
| --- | --- | --- |
| Student request | authenticated JWT; own-subject RPCs only | Derive auth.uid(), lifecycle gate; submit input/confirm extraction, never authoritative confidence/evaluation/content |
| Content publish | Owner-controlled offline publisher at launch | Explicit reviewed content transaction; no Quality-membership or student-based publish RPC |
| Vision/extraction | new math_extraction_worker, NOLOGIN/NOBYPASSRLS runtime role | EXECUTE only extraction claim/finalize/fail + bounded job evidence access; cannot evaluate, bill, publish or erase |
| Math evaluation | new math_evaluation_worker, NOLOGIN/NOBYPASSRLS runtime role | EXECUTE evaluation claim/finalize/fail only; cannot rewrite extraction/content or direct-charge |
| Math SQL execution | new math_executor NOLOGIN, never JWT/membership to runtime roles | Own narrow Math definer functions; bounded Math table grants, BYPASSRLS only with those grants like existing executor pattern; no grant authority/CREATE at runtime |
| Human Quality | authenticated + existing quality_operators gate | postgres-owned gated HQ Math RPC; no direct HQ CRUD or content publication |
| Finance/reconcile | existing financial authority + narrow Math binding-validated helpers | New private finance helpers owned by essay_executor; explicit Math binding read and EXECUTE grants, no changes to existing Essay helper bodies or grants to browser/workers |
| Account erasure | existing account_worker fenced API | Existing owner-mediated erasure hook gains explicit Math cleanup capability; Math workers never obtain arbitrary-user erase permission |

Math executor may call only the new private financial helpers; helper derives/validates account,
policy and posting from locked binding. Finance helper receives no untrusted pricing parameter.
Trusted reconciliation can release but cannot publish evaluation; erasure bypasses ordinary allowed()
only after valid lifecycle fence. Reuse existing financial operator refund authority, not Quality.

Split runtime roles are justified by distinct extraction and financial-finalize powers and later
provider deployments. Extending essay_worker would silently broaden an existing credential; one
combined Math role would give extraction callers evaluation/consumption powers. Neither selected.
PostgREST role admission/authenticator membership and worker credential provisioning are separately
reviewed deployment tasks; no browser role inherits executors. No service_role browser. Storage/Auth
Admin transport remains existing server-only deletion boundary, not a general Math worker secret.

RLS ON for new private relations, no direct PUBLIC/anon/authenticated/service_role DML; explicit
owner-read projection only. Definer functions empty search_path, fully qualified relations, explicit
EXECUTE revokes; internal validators not browser callable. Math workers get function EXECUTE only.
Privileged content publish and QA never reuse financial permission. No new generic RBAC table.

## F. Transaction and publication boundary

Extraction and evaluation are **separate** transactions/runs: external OCR/Vision calls cannot be
inside a long DB transaction. Persist immutable candidate extraction/version, confirm selected
uncertainty through owner RPC, freeze confirmed version and gate READY_FOR_EVALUATION. A provisional
solution_step_candidate is not a canonical evaluated solution step. Pure typed input follows the
same ready-input contract without fabricated provider run. These steps never consume credit.

Evaluation request atomically pins ready input, authority versions, confirmation provenance and
financial binding. Worker claim issues fresh opaque run fence/lease with fixed selected input.
Provider dispatch authorization rechecks current subject/job immediately before sending; already
in-flight external work may finish remotely, but no stale result can be persisted or consumed.
Do not claim DB gating can recall bytes already sent to an external provider.

Success finalize is one bounded transaction:

1. Check caller role/authorization; acquire ordered lifecycle/account/attempt/grant/evaluation/decision
   locks; reread all bindings. Require active account, valid run token/lease and nonterminal job.
2. Exact previously completed run+token+server-normalized payload hash returns prior result only;
   changed payload/fence or retry after account restriction rejects. Never re-consume.
3. Validate exact envelope version/bounds, selected immutable run/confirmation and authority pins;
   rubric applicability, all same-evaluation/leaf/region bindings, steps, DAG/self/duplicate/cycle
   rules, causal reachability, ROOT vs propagated, ordered CORE and hints. Client/provider cannot
   choose a new profile, credit quantity or authority. Unknown/malformed output rejects atomically.
4. Insert complete evaluation children and considered-path/causal bindings, compute canonical hash,
   persist selected processing provenance (known provider/model/version, latency/tokens nullable;
   unknown cost is null). No provider raw payload/chain-of-thought copied into public DTO/HQ.
5. Post canonical consumption for reserved grants or settle included authorization; mark completed
   evaluation and run together. All changes commit or none. Student/Quality reads publish only a
   completed, fully committed graph; no partially inserted graph is visible as a result.

Failure recording is a separate bounded fenced transaction after rollback, with sanitized codes;
release/reconcile follows section B. Never commit invalid graph then clean it up. Expired lease,
released billing or deletion wins over late finalize. A simultaneous finalize and timeout serialize
on the same locks: completed/settled or released/no-public-output, never both. No DB implementation,
provider retry, model selection or production verification is claimed by this contract.

## G. Additive qlm-read-v1 and Math HQ surfaces

Keep existing ql-read-v1 and hq-read-v1 signatures/DTO behavior unchanged. Proposed Math list/detail
concepts: qlm_list_cases(limit default20/max100, before timestamp+UUID), qlm_case_detail(evaluation id).
Math HQ submit takes one bounded versioned JSON payload; state accepts at most100 UUIDs; history
one Math evaluation with limit20/max100 and paired descending(created_at,id) cursor. Unsupported
versions fail closed. Lists never carry original answers/images/account direct identifiers.

Authorized Math detail returns explicit groups:

- canonical problem/leaf versions and per-leaf response_format; official references/criteria/verified
  solution versions and applicability; no fabricated university points;
- original student typed answer/evidence metadata plus gated short-lived evidence access; availability
  state distinguishes absent/not-applicable/erased/unavailable, no public object keys as authority;
- selected extraction run/version, normalized regions and uncertainty, base candidate lineage and
  student confirmation provenance/timestamp (no mutation of original image); page dimensions,
  orientation and normalized bounding boxes;
- evaluated solution steps and source-region bindings, logical DAG and separate causal edges,
  root/propagated classifications, ordered CORE and hints; generated solution only if applicable in
  the frozen output, distinct from student re-solve;
- exact considered reference/private path results; rubric/output version/hash, model/provider/run
  provenance; prior attempt/evaluation linkage and versioned deltas;
- separately bounded domain-filtered human QA history/state with deleted-reviewer representation.

No name/email/phone/OAuth identity by default. Reviewer identity is server-derived; public-facing
Math DTO may expose non-identifying reviewer state/id as specifically authorized, never account
profile joins. Quality operator can inspect full relevant evidence, including hint content, through
this operator surface; student reveal gating remains separate. Missing raw evidence is not proof
of no issue. CORE=[] is valid, completed evaluation is not Human Quality PASS. No UI/adapter here.

## H. Migration compatibility and regression contract

Future migration prerequisites: actual live catalog/owners/ACL fingerprints and applied ledger,
exact Math domain keys and ADR-2 dependency state; no broad db push/provider005/day_targets repair.
Use one atomic forward change where practical; check no unvalidated intermediate constraint window
is exposed. Add nullable Math FK and supporting unique first; install exclusive binding and both
strict rubric branches before dropping old global Essay-only checks/NOT NULL. Existing rows already
satisfy Essay branch: **no UPDATE/backfill of historical judgments/financial transactions**. Snapshot
row/hash invariance in isolated tests. Existing Essay composite FK stays, new Math composite FK
validated. Install Math finding trigger and legacy field projection in same transaction.

New findings do not receive relaxed universal JSON validation; old findings stay valid unchanged.
The immutable trigger's reviewer/rewrite exceptions remain narrow; new Math binding is never mutable.
New Math lookup index (math_evaluation_id,created_at DESC,id DESC) supports history; existing Essay
history index remains. Add binding PK/decision UNIQUE/composite FK support, not analytics indexes.

**Expected existing-object edits:** HQ judgments conditional NOT NULL, two rubric CHECKs, Math FK/
unique/supersession FK, shared finding shape CHECK + domain-bound insert validation and judgment parent guard; legacy history
RPC explicit projection and writer foreign-domain retry rejection. Existing ql read bodies, pure
Essay validators, projection helper, table RLS/ACL and financial table columns/guards stay unchanged.
New private Math financial helper grants/binding are shared-Credit schema additions, not a second
ledger. Future ADR-2 hooks are a separately enumerated activation dependency; no change now.

postgres is non-superuser in the observed topology; Essay finance functions belong to essay_executor.
Future isolated harness must reproduce ownership, membership, search_path, default ACL and delegated
schema privileges, not just use a superuser. Reuse no global ownership/CREATE bridge. If new finance
functions require ownership initialization, use an exact function allowlist, transaction-local
membership/CREATE restoration and fail on unexpected topology, as learned in ADR-2D. Any unapproved
owner reassignment or extra dependency is STOP, not a reason to weaken privileges.

Once Math HQ/financial bindings exist, rollback must refuse deletion of real history/obligations;
forward correction is preferred. Empty-install rollback may remove only new objects and restore
captured legacy definitions/constraints. Never drop mixed HQ tables or cascade financial history.

### Required implementation tests — not executed in this design phase

| ID | Regression / proof required |
| --- | --- |
| R01 | Existing Essay rows/hash/notes unchanged across migration; new Essay rows still use identical validation and defaults |
| R02 | Exact-one HQ binding rejects neither/both; dangling FK; foreign rubric; identical UUID in two domains remains distinct |
| R03 | Both composite supersession branches: same-eval correction allowed, cross-domain/eval/self/cycle/second successor denied; independent roots survive |
| R04 | Legacy Essay submit/correction response, normalization/hash bytes, findings and all conditional NA behavior match baseline fixtures |
| R05 | hq-read-v1 explicit legacy field set/null/cursor/errors/limits semantically identical; no Math key/row leakage; ql-read-v1 body/signature/ACL fingerprint unchanged |
| R06 | Global submission key: exact retry, changed payload, cross-domain/subject/reviewer collision; revoked operator retry denied; real concurrent duplicate submit one row |
| R07 | Math rubric exact keys/version/verdicts, content-based NA, missing evidence unassessable, disposition/finding consistency, size/note limits |
| R08 | Each Math target positive/negative; wrong eval, propagated-as-root, wrong extraction candidate/run/attempt, unconsidered reference/private path rejected |
| R09 | Shared finding insert gate cannot accept Math shape under Essay or vice versa, even through privileged constraint fixture |
| R10 | E1 on each domain removes QA hash/notes/findings; invalidation does not; E2 reviewer deletion preserves others; combined student/reviewer behavior |
| R11 | Math/Essay projections remain separate; independent disagreement, superseded heads, incompatible rubric NOT_COMPARABLE and deleted-reviewer rendering |
| R12 | Table CRUD/EXECUTE/RLS/search_path/owners matrix; anon/student/forged authority denied; pending operator denied; no browser service-role/executor secret |
| R13 | Fresh Math decision+binding atomic; student/account mismatch, existing detached decision reuse and Essay-bound decision rejected |
| R14 | Concurrent both-domain binding attempts in both orders; billing guard disallows reassignment; binding immutable; no dangling transaction decision |
| R15 | Existing Essay reserve/consume/release/refund/reversal, signup/manual grants and detachment fixtures unchanged; no historical economic update |
| R16 | Math initial/revision policy mapping parity, grant order/expiry, included-parent eligibility, same-policy lineage and no cross-domain inclusion |
| R17 | Input/Vision failure causes no consume; reservation releases once; confirmation/hints uncharged; retry/timeout/unknown completion/settled deletion behavior |
| R18 | Graph+consume atomic rollback on every validation/posting failure; duplicate finalize/reconcile concurrency yields one completed graph and posting |
| R19 | Old fence, lease expiry, changed output retry, unselected extraction, malformed DAG/causal/CORE/rubric rejected; no partial publication |
| R20 | Pending/ERASING gates at request/upload/dispatch/claim/finalize; lifecycle/account/grants lock-order stress with Essay/Math/HQ/delete shows no tested deadlock |
| R21 | Storage namespace traversal/foreign ownership/orphan/list error/delete timeout/late upload: never false ERASED; supported API only, resumable batches |
| R22 | Metadata held through bytes verification; Math DB/HQ cascade then Auth-last; public content retained; reviewer E2; receipts no private Math ids/hashes |
| R23 | Non-superuser Production-equivalent apply/empty rollback restores grants/owners; unexpected dependencies reject; unrelated migration files untouched |
| R24 | Math DTO bounds, full authorized evidence, no direct PII, unavailable vs NA, confirmation not re-solve, generated solution not student solution |

Static reconciliation confirms the constraints can represent the required behavior; these R01–R24
are future acceptance criteria, **not PASS test results**. Real JWT gateway, Storage late-upload
behavior, provider cleanup, secret provisioning and finite ordinary evidence duration remain later
activation gates; they do not require a new Owner product policy to implement the DB foundation.

## Decision output

MATH_2R_RECONCILIATION: COMPLETE; MATH_2B_CORRECTIONS_RESOLVED: YES (contract).
OPTION_C_FINAL: PASS — shared HQ schema extension plus typed billing binding, not “all old objects unchanged.”
HQ_EXACT_ONE_DOMAIN_BINDING: PASS (design); HQ_ESSAY_V1_PRESERVED: YES (required compatibility).
HQ_MATH_RUBRIC_DISPATCH: strict domain+version; HQ_MATH_TARGET_VALIDATION: typed, evaluation-bound.
HQ_E1: both evaluation FKs CASCADE; HQ_E2: reviewer SET NULL. QL_READ_V1_CHANGED: NO;
HQ_READ_V1_CHANGED: NO now / future wire contract unchanged, legacy serializer body must be corrected.
CREDIT_LEDGER_REUSED: YES; SECOND_WALLET: NO; VISION_SEPARATE_CHARGE: NO; HINT_L0_L2_CHARGE: NO.
ADR2_CHANGED_NOW: NO; SERVICE_ROLE_BROWSER: NO; HUMANITIES_SCHEMA_REDESIGN: NO.
SHARED_HQ_SCHEMA_EXTENSION_EXPECTED: YES; SHARED_CREDIT_SCHEMA_EXTENSION_EXPECTED: YES
(new binding/private operations, no existing financial column or economic-history rewrite).
NEW_CANONICAL_FACTS: typed Math financial binding and shared HQ Math subject; existing planned
Math evidence/confirmation/fence facts supply integration, no abstract identity registry/new ledger.
OWNER_DECISIONS_REQUIRED: 0. READY_FOR_MATH_DB_IMPLEMENTATION: YES; READY_FOR_PRODUCTION_APPLY: NO.

STOP after documentation/validation/publication. Next: **Owner/ChatGPT review → MATH-2C DB
implementation authorization**. No Math migration, ADR-2 edit, LAB implementation or provider work.
