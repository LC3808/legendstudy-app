# MATH-2B — Canonical DB / security cross-review

2026-10-02. **COMPLETE / ACCEPT_WITH_CORRECTIONS. DESIGN REVIEW ONLY.**
Option C remains the product direction, but its claim of unchanged shared persistence is
**CORRECTION_REQUIRED**. Existing Human Quality is Essay-bound, not a polymorphic evaluation store.
No Math implementation, migration, provider call, content inspection or Production write occurred.
**READY_FOR_MATH_DB_IMPLEMENTATION: NO** for the proposal as supplied: first reconcile the bounded
shared-HQP extension below. This is an engineering contract gate, not a missing Owner policy.
Owner decisions required: **0**. Production apply: **NO**.

## Evidence and verification boundary

- APP starting ref: `codex/essay-scaffolding-vnext` at `59e14eb76e24dd178d042c8eddeca14bd670f1b5`;
  HEAD/origin/remote matched, ahead/behind 0/0; only pre-existing `supabase/.temp/` untracked.
- [MATH-1 at 47afbdc](https://github.com/LC3808/legendstudy-lab/blob/47afbdcc80845e7446495a3cdf5eac8dd5adab4b/docs/architecture/MATH-1_MATHEMATICAL_ESSAY_ARCHITECTURE.md).
- [MATH-2A at 1bd275b](https://github.com/LC3808/legendstudy-lab/blob/1bd275b059e6f42a1ccc8181e2c211d4dd4a5517/docs/architecture/MATH-2_CANONICAL_DATA_PERSISTENCE_CONTRACT.md).
  Remote `claude/math-essay-architecture-v1` equals 1bd275b; MATH-1 is its ancestor. LAB unchanged.
- [Content identity](../supabase/migrations/20260912000100_initial_content_schema.sql),
  [university/exam foundation](../supabase/migrations/20260927000200_essay_lab_foundation.sql),
  [Essay product](../supabase/migrations/20260928000100_student_essay_product.sql),
  [Credit schema](../supabase/migrations/20260928000200_essay_entitlements.sql),
  [Credit operations](../supabase/migrations/20260929000300_essay_credit_commercial_core.sql),
  [server transactions](../supabase/migrations/20260928000300_essay_server_operations.sql).
- [Quality authorization](../supabase/migrations/20261001000100_quality_read_authorization.sql),
  [HQP schema](../supabase/migrations/20261001000200_human_quality_persistence.sql),
  [HQP closeout](human-quality-persistence-implementation.md),
  [corrected ADR-2](../supabase/migrations/20261001000300_account_deletion_lifecycle.sql),
  [ADR-2D ownership](account-deletion-ownership-compatibility.md).
- Production metadata inspected in an explicit **BEGIN READ ONLY** transaction through existing
  linked CLI access: migration versions, pg_class/proc/type/namespace/roles/constraints, selected
  function owner/config/ACL, HQ table RLS/ACL, Storage bucket metadata and policies. No Auth login,
  credential-file access, student rows, object names, source content or provider calls.
  This proves catalog compatibility/collisions only, not Math behavior or runtime authorization.

### Production snapshot

PostgreSQL 17.6. Remote ledger **23**; latest `20261001000100` Quality and `20261001000200` HQP.
`20261001000300` ADR-2 absent; `account_private` absent. `20260929000500` provider005 absent;
`20260930000100` day_targets separately untracked. Existing ACL-effect verification is historical,
not rerun here. Local migration directory has 26 files. Never replay the three local-only entries.

**MATH_OBJECT_COLLISIONS: NONE** for `math_*` relations (including indexes), functions/types,
`math*` schemas/roles and `qlm_*` functions. No timestamp reserved. A future Math migration must
recheck the remote ledger and concurrent ADR-2 state; if it uses lifecycle helpers, require the exact
applied ADR-2 prerequisite or remain inactive until it exists. A later timestamp alone does not prove
prerequisites. No migration repair or ordering change in this review.

Only Storage bucket: private `profile-avatars`; four authenticated owner policies require
`<auth.uid()>/avatar.png`. No Math bucket/policy exists. No object inventory was read.

## Corrections required before implementation

| ID | Severity | Proposal | Canonical correction / implementation gate |
| --- | --- | --- | --- |
| M2B-01 | HIGH | §§29/41 HQP SET NULL leaves no identifying facts | **E1 evaluation FK CASCADE**, findings CASCADE; only **E2 reviewer FK SET NULL**. Output hash, notes and detached evaluation UUID are not an erasure substitute. |
| M2B-02 | HIGH | §26 HQP only adds rubric and target strings | Existing NOT NULL Essay FK, fixed rubric CHECK, validator, supersession composite FK and RPC queries need a reviewed typed Math extension; no pretend generic evaluation id. |
| M2B-03 | HIGH | §25 existing billing domain discriminator/request kinds | No such generic discriminator exists. Billing has an Essay FK; transactions point to those billing decisions. New Math binding/transactions must preserve the single ledger and existing guards. |
| M2B-04 | MEDIUM | §§6/46 exam_name/year reused as identities | Reuse universities.id and essay_exams.id; exam_name is display, year a scope attribute; exams is a different content/mock domain. |
| M2B-05 | HIGH | §31 owner readable/writable evaluated data | Owner must not author final evaluations, steps, errors, CORE or extraction confidence. Student inputs through bounded RPC; derived output only trusted finalize. Quality membership does not grant content-authoring authority. |
| M2B-06 | MEDIUM | §44 NOT NULL pins and nullable ACTIVE uniqueness suffice | Require exact version FKs, immutable bodies, typed scope null rules and serialized activation; reject ties across distinct matching applicability scopes too. |
| M2B-07 | MEDIUM | §§17/20/46 assumed private binding suffices | Define coverage, step-to-region and eval-to-selected-extraction bindings; enforce same attempt/version in addition to same evaluation. These supporting relations are absent from the headline count. |
| M2B-08 | MEDIUM | §21 propagation can tag any dependency; §30 traversal deferred | Root-to-consequence may be transitive, not a direct dependency. Persist a typed causal edge separately from logical dependencies; same-evaluation and reachability validation. Edge/FK traversal support is launch work. |
| M2B-09 | MEDIUM | §§12/41 retained alternative paths / deletion integration | Student novel paths remain private evaluation evidence. No automatic copying to retained content. New bytes/worker/finalize/cleanup gates are not covered by current avatar-only erasure. |
| M2B-10 | LOW | “20 entities” | Listed candidates = **21**; concept count is not a final physical-table count. Version/binding relations may add tables; merges below reduce redundant facts. |

No correction is implemented here; LAB proposal remains historical design evidence.

## Existing identity reuse: exact objects

| Layer / actual object | Exact PK/FK | Can reuse / minimum extension | Duplication risk |
| --- | --- | --- | --- |
| Student/operator auth.users | id; profiles.id FK auth.users.id CASCADE | REUSE; server auth.uid(), no new identity | Profile/school/admin_users are not Quality authority |
| University public.universities | id; slug UNIQUE | REUSE_EXISTING | No math_universities |
| Admission exam public.essay_exams | id; university_id → universities.id RESTRICT; UNIQUE(university_id,admission_year,exam_key) | REUSE_EXISTING for university Math admission/mock context | exam_name is not a key; no second exam/year master |
| Track/year/domain context | essay_exams.admission_track, admission_year, field_or_division, campus, session_label | Reuse present context; Math-only scoped applicability child/config if finer problem/leaf distinctions needed | No blanket new department master or student admission-eligibility authority |
| public.exams | content_item_id PK; (content_item_id,content_type) → content_items(id,content_type) RESTRICT | Existing general exam/content domain; **not** interchangeable with essay_exams.id | academic_year/calendar year not admission-year identity |
| public.subjects | id; UNIQUE(taxonomy_version,code); parent same-version FK | Optional verified taxonomy mapping, not admission eligibility | No parallel Math subject taxonomy; unknown mapping remains unmapped |
| public.exam_subjects | id; content_item_id → exams; (subject_id,taxonomy_version) → subjects MATCH FULL | Reuse only for an actual existing exams context | Never attach essay_exams.id to this FK |
| public.source_posts | id; UNIQUE(source,external_post_id); url UNIQUE | Reuse ingestion/source-post identity when present | Mutable post hash is not immutable PDF/version evidence |
| public.resources | id; content_item_id → content_items; source_post_id → source_posts; optional (exam_subject_id,content_item_id) composite FK | Reuse observed URL/file/source locator identity | No copied locator master; resource link may be landing page, not bytes |
| public.essay_exam_resources | PK(essay_exam_id,resource_id,role); FKs to essay_exams/resources | Reuse verified exam resource-role/provenance association | Citation is not a problem identity or versioned extraction |
| public.essay_questions | id; essay_exam_id → essay_exams; evidence binds (question_id,essay_exam_id) | Existing text Essay unit; do not retrofit Math steps/leaf facts into it | Math problem/leaf version is a new domain fact, shared exam remains reused |
| Math set/problem/leaf | Proposed Math version PKs; set → essay_exams.id | MATH_NEW subordinate content, not new exam identity | A set groups ordered problems/scope within an exam; no duplicate university/year truth |

Admission domain/eligibility here describes published exam applicability, not a verified student
qualification record. Prefer no new universal eligibility taxonomy. Reuse shared metadata without
claiming mutable exam labels are historical evaluation authority: pin the reviewed Math profile
context used for evaluation.

## Entity decisions — all 21 candidates

These are normalization decisions, not approved DDL or a commitment to 21 tables.
Every private row follows attempt/evaluation erasure; official content is retained separately.

| # | Candidate | Decision | Minimum fact / correction |
| --- | --- | --- | --- |
| 1 | math_problem_sets | ACCEPT | Exam-scoped ordered content container; FK essay_exams, not copied master. Version only meaningful membership/context changes. |
| 2 | math_problems | ACCEPT | Stable logical key + immutable version row; official conditions/statement pins. |
| 3 | math_subproblems | ACCEPT | Uniform leaf evaluation unit, including one unlabeled singleton leaf for a solo problem; avoid dual nullable problem/leaf authority. |
| 4 | math_source_artifacts | ACCEPT | Immutable source-byte/reference version; reuse optional resource/exam-resource locator FK, no second ingestion identity. Raw storage optional. |
| 5 | math_evaluation_profiles | ACCEPT | Typed scope/pins relational; exact bounded applicability JSONB, not arbitrary scope JSON. |
| 6 | math_scoring_criteria | ACCEPT | Criterion identity, source/version and official points relational; bounded irregular partial-credit payload JSONB. |
| 7 | math_canonical_solutions | ACCEPT | Versioned reference paths with origin/verification; approved alternate paths can use this same representation. |
| 8 | math_canonical_solution_steps | ACCEPT | Same solution-version ordered steps/criterion references; no student output mixed in. |
| 9 | math_alternative_paths | MERGE | Known/AI-proposed reference paths into solution versions with origin/verification; private novel student path stays evaluation output. No second solution authority. |
| 10 | math_attempts | ACCEPT | Immutable submitted input, server student ownership, exact problem version and kind; new attempt for corrections/re-solves. |
| 11 | math_attempt_artifacts | ACCEPT | Private owned object metadata/page/hash if used; lifecycle metadata may mark erasure, original submitted payload is not silently rewritten. |
| 12 | math_extraction_runs | ACCEPT | Append-only run identity/version/model provenance; selected run pinned by evaluation, not implicit latest. |
| 13 | math_extraction_regions | ACCEPT | Same-run/page/artifact region with coordinate convention, extracted text/math and uncertainty; bounded JSON for irregular geometry. |
| 14 | math_evaluations | ACCEPT | Immutable completed output with exact authority/run pins; bounded rubric/result envelope JSON validated by version. Lifecycle status distinct from frozen payload. |
| 15 | math_solution_steps | ACCEPT | Same evaluation/leaf, order per leaf, source-region bindings to selected extraction; steps need not equal handwriting lines. |
| 16 | math_step_dependencies | ACCEPT | Directed logical edges, composite same-evaluation endpoint FKs; no dependency arrays as second authority. |
| 17 | math_errors | ACCEPT | Persist root/propagated evaluation-time classification and reason; causal bindings same evaluation; do not recompute history. |
| 18 | math_core | ACCEPT | Ordered selected error/step membership only; no duplicated category/classification authority or numeric student score. Empty valid. |
| 19 | math_hints | ACCEPT | Stable eval/error-bound hint id and L0–L2 content; bounded body JSON allowed; separate from exposures. No hint generation charge. |
| 20 | math_hint_exposures | ACCEPT | Server-recorded delivered/accessed hint event with retry key and owner/attempt/eval binding; does not prove cognition. |
| 21 | math_resolve_links | MERGE | Single predecessor/kind on immutable new attempt + prior evaluation pin on reevaluation; target step for STEP_RETRY. No parallel link table unless a real multi-parent requirement appears. |

Supporting relational bindings still needed where arrays cannot provide FK integrity: attempt leaf
coverage, version-to-source/criteria references, step-to-region and causal error edges. Reuse existing
unique keys/parents; count these explicitly in a future DDL package rather than concealing them in
“20”. Rubric results and bounded irregular presentation need no table per JSON field. MIXED,
aggregate parent format and current history head are **DERIVE**, not mutable canonical columns.

## Version pins, profile authority and evaluation semantics

Use immutable version-row UUID PKs plus UNIQUE(logical_id,version) and exact FKs. This matches the
existing discipline of frozen Essay request/output evidence, while adding Math-specific content
versions; do not claim existing mutable resources/exams already supply them. A new extraction or
reevaluation is a new identity, not mutation of the prior output. Avoid redundant integer versions
on children if their immutable parent FK already fixes the version.

Completed evaluation pins: attempt/problem/leaf versions, selected extraction run (nullable for
pure typed input with explicit provenance), selected profile version, referenced source/criteria/
solution versions where available, code rubric version and processing/output contract version.
No official solution/criteria is a legitimate explicit absence: do not impose NOT NULL on an
optional authority and fabricate a reference. Existing pinned versions remain readable after
SUPERSEDED/RETIRED; ACTIVE is required at selection time, not retroactively on historical reads.
Published payloads are immutable; controlled activation metadata transitions are separate.

The scope uses typed exam/problem/leaf FKs with CHECKs requiring the exact shape for that scope.
Normalize any applicability selector used for matching; bounded JSONB is suitable for rubric
applicability, not an unvalidated arbitrary eligibility expression. Compute rank from scope kind
on the server. Partial uniqueness for ACTIVE uses NULLS NOT DISTINCT or disjoint scope-specific
unique indexes; ordinary nullable UNIQUE is insufficient. Serialize activation/resolution with
version selection. Reject all equal-rank multiple matches, including overlapping distinct domain
selectors. Precedence: leaf > problem > exam/track/year > explicitly enabled common fallback.
No match or ambiguity fails closed. Fallback is labeled non-official and must not silently turn on.

Leaf response_format is one of SHORT_ANSWER, SHORT_REASONING, FULL_SOLUTION, PROOF. A singleton
leaf removes a special case; MIXED is derived across leaves. Server loads profile/rubric, never
trusts client applicability. SHORT_ANSWER “12” can be complete; under FULL_SOLUTION answer CORRECT
can coexist with reasoning INSUFFICIENT_JUSTIFICATION. Missing coverage is NOT_ATTEMPTED;
unreadable evidence is NOT_DETERMINABLE/NOT_ASSESSABLE, not INCORRECT. Step/path/writing judgments
remain distinct from answer correctness. No university-name conditionals.

Official criteria carry points only where published, nullable otherwise. Keep source/page/region
and human structuring verification; rubric diagnostic verdicts do not invent scoring points.
Criterion↔dimension mapping binds criterion version and code rubric version/key; small normalized
mapping or validated bounded key set is sufficient. Rubric definitions stay versioned code/contract,
not a generic metric registry. Unknown keys/versions/applicability fail closed. Official provenance
alone does not verify AI-extracted solution steps or profile configuration.

Owner **D1 ACCEPTED**: reference + hash default; retrieve/hash exact bytes only in a separately
approved ingestion task. A URL hash is not a content hash. If bytes/hash not verified, retain a
pending reference and do not fabricate verified provenance. Raw official Storage requires later
copyright/storage gate. Public metadata publication still follows reviewed content visibility.
Owner **D2 ACCEPTED**: finite + erasable private evidence, exact duration before Production Math
activation. Support erase_due/status/purged-at semantics without hard-coding a duration now.
After evidence expiry, report unavailable evidence and preserve no bytes via logs/JSON copies.
Exact retention of derived private extraction must be included in that activation review; account
erasure always removes all personal operational descendants, irrespective of normal retention.

## Steps, DAG, causal errors and learning loop

Finalize one bounded evaluation graph atomically under an evaluation/attempt lock. Composite
FKs (evaluation_id,step_id) on both endpoints prevent cross-evaluation references; CHECK prevents
self-edge and UNIQUE prevents duplicate directed edges. Perform a whole-graph cycle/reachability
check before immutable publication in that same transaction. Application-only prechecks are not
sufficient under concurrent writes; no recursive trigger framework is necessary with a single
trusted finalize writer and restricted direct DML.

A dependency is not automatically an error-propagation edge. Persist causal attribution as typed
same-evaluation source-error/target-step edges, verifying logical reachability during finalize.
A transitive root→consequence edge must not be represented as a fabricated direct dependency.
Math correctness/counterfactual validity is evaluator judgment; DB graph validity does not prove it.
Freeze root/propagated outcomes with algorithm/contract provenance. Independent errors remain
independent, and downstream consequences are not counted as separate weaknesses.

CORE references same-evaluation error/step with unique rank; no inferred membership from category
or arbitrary priority threshold. Zero CORE is valid. Hints L0–L2 bind that exact evaluation/error;
future reveal RPC enforces progressive policy. If server enforces reveal, do not send all hidden
hint bodies in the initial DTO. Exposure records actual server delivery/acknowledgment only.

FULL_RESOLVE is a new whole-solution attempt. STEP_RETRY pins the earlier evaluated step and leaf;
it cannot silently stand in for a complete answer. Predecessor is same student and problem lineage,
with version compatibility explicit, earlier server sequence and no cycle. Store prior evaluation
once for reevaluation and typed bounded deltas; do not duplicate relationship truth in two stores.
Student re-solve is distinct from generated solution/hint. No charge for hints or a standalone
student-visible Vision extraction stage; economic policy/version remains server-owned.

## Credit/Billing: exact constraint and minimum reuse path

Live `credit_accounts.user_id → profiles.id SET NULL`; grants and transactions reference account.
`essay_billing_decisions.evaluation_id` is nullable UNIQUE FK to **essay_evaluations**, SET NULL.
`credit_transactions(decision_id,account_id)` FK targets **essay_billing_decisions(id,account_id)**;
reserve/consume/release require decision_id; posting-once unique index and reversal/account FKs
protect the single ledger. `essay_evaluations.request_kind` permits only `student` and
`operator_reevaluation`. There is no deployed generic request_kind/domain on billing decisions.
`essay_private.credit_request_v2`/release/finalize traverse Essay attempts/evaluations explicitly.

**CORRECTION:** Do not insert Math IDs into the Essay FK or append MATH_* strings to that Essay
request_kind CHECK. Conceptual MATH_INITIAL_EVALUATION/MATH_REEVALUATION belong to the Math
request contract. Prefer a typed **Math evaluation → existing billing decision** binding including
account_id, with the existing Essay evaluation_id NULL for Math decisions. This can avoid changing
Credit table shape: the existing table remains the one financial decision authority despite its
historical name. Enforce UNIQUE decision binding, same account and no Essay+Math double binding
in a locked trusted transaction. Nullable evaluation_id alone is not a valid domain discriminator.
Do not use a generic unvalidated reference string or a parallel Math balance/decision ledger.

New Math request/reserve/consume/release helpers must reuse account locking, grant eligibility,
posting-once/reversal invariants and preserved economic statuses. Existing release(evaluation_id)
cannot be called with a Math id. Add bounded Math reconciliation/erasure integration and include
billing policy/version, included-revision eligibility and retry keys; do not infer that re-solve
means free or set new prices in this review. Shared finance/admin readers must tolerate legitimately
detached and Math-bound decisions without guessing their domain. Existing price policy unchanged.
This is **new binding/helper work**, not a proven migration-free enum extension. If implementing
this path requires broadening an existing guard/ACL, enumerate and independently test that narrow
change before approval; do not silently rename the financial table or relax transaction checks.

## Human Quality: existing store cannot accept Math as-is

Live `human_quality_judgments.evaluation_id NOT NULL → essay_evaluations.id CASCADE`;
`rubric_version CHECK = hq-rubric-v1`; rubric result CHECK calls Essay-only hq_rubric_valid.
Findings call hq_finding_valid with OVERALL, GENERATED_REWRITE, DIMENSION, PROGRESS, ISSUE_KEY,
SENTENCE and EVIDENCE_LINK typed shapes. Writer validates targets against Essay; reads/projection
and frozen output/rewrite hash are Essay-specific. Supersession FK is (judgment_id,evaluation_id).

A rubric/enum addition alone is **BLOCKED**. For literal shared-store reuse, the narrow engineering
candidate is a typed second Math-evaluation FK with CASCADE, exclusive domain binding and
version-dispatched validation; preserve the existing Essay column/FK and old row meaning. Making
the Essay FK nullable requires replacing its NOT NULL guarantee with exact-one-binding enforcement.
Revise same-domain/same-evaluation supersession enforcement (nullable composite FK cannot alone
protect Math), hash generation, conditional dimensions, finding validation, E1 deletion, readers
and projection. All existing Essay RPCs must continue to expose Essay-only v1 semantics; Math gets
separate gated APIs. Never weaken v1 validators globally to arbitrary JSON or dangling UUID targets.

**Required next design artifact before DDL:** exact shared-table constraint/validator changes,
domain-safe corrections/idempotency/projection, and regression matrix proving old v1 input/output
and security unchanged. This is why implementation readiness is NO now. Do not replace shared
persistence with a duplicated Math reviewer system merely to claim fully additive tables.
No new Owner product/privacy decision is needed; implementation authorization must include the
bounded existing shared-HQP changes rather than claim “new Math tables only.”

Math targets: SOLUTION_STEP and ROOT_ERROR must join same Math evaluation; EXTRACTION_REGION must
belong to the evaluation's pinned run/attempt; ALTERNATIVE_PATH must resolve to a reference-solution
version actually considered by that evaluation, or a typed private evaluated-path fact. Never an
arbitrary content path id. Correction chains remain immutable single-successor; independent reviews
remain roots; server reviewer auth.uid(), retries recheck current authority; notes erase under E1.
**E1:** erased evaluation → its judgments/findings/hash/notes erased. **E2:** erased reviewer →
reviews of others survive with reviewer FK NULL and no identity snapshot. Both apply simultaneously
for a student who is also a reviewer. Invalidated/superseded evaluations retain their QA history.
`ql-read-v1` and `hq-read-v1` contract change required: **NO**; separate `qlm-read-v1`/Math HQ surface.

## ADR-2 and Storage extension boundary

ADR-2D is a corrected **local** candidate, not current Production account restriction. Preserve it
unchanged now. Future Math integration must explicitly extend:

1. Request/upload/hint-event/re-solve and privileged Math read/write gates with account lifecycle
   subject lock/predicate; pending Quality operator is denied despite allowlist membership.
2. Math claim/finalize/reconcile locks and deletion fencing; no new output after erasure, no provider
   retry to finish deletion, exactly-once reservation release, settled consumption not refunded.
3. `account_deletion_personal` currently explicitly loops Essay sessions and named personal domains;
   add Math reconciliation and parent erasure, with E1 QA cascade, before Auth-last completion.
4. Worker `storage.ts` currently enumerates only profile-avatars. Register private Math namespaces
   and resumable bounded Storage API list/delete/absence checks **before** deleting their metadata
   needed for cleanup. Keep subject linkage until byte cleanup verified; retry failure, not ERASED.
5. Verify Math absence in the actual erasure phases and final postconditions. Existing
   `account_deletion_postconditions` checks lifecycle phase/subject unlinking, not a future generic
   Math inventory. Do not advertise automatic future coverage. Preserve E2 Auth-last effects and
   30-day minimal receipt; no Math ids/hashes/notes in detached receipts/analytics.

Proposed future Storage strategy: one **private student-Math bucket** for current evidence and,
if needed, derived/generated bytes, under server-assigned owner/attempt/artifact paths. Separate
internal official raw bucket only if D1's later storage gate passes. DB text extraction remains
bounded private rows; not every conceptual namespace requires a bucket. Validate owner/attempt
binding, MIME/size/page limits and registration before upload; upload completion must be lifecycle-
gated and orphan cleanup resumable. Do not authorize solely by a caller-supplied path prefix.

Use short-lived authorized download or streaming access; signed URLs are bearer capabilities,
not permanent DTO fields. Revocation/TTL and pending-account behavior must be tested before launch.
Operators access original evidence through a gated projection/access endpoint, never a public bucket.
Finite raw-evidence expiry is separate from full account erasure; latter deletes extraction and all
personal derived content. Current avatar policies must not be widened to all buckets. No Storage
runtime tests/deletes occurred. No permanent student novel path promotion or analytics retention.

## RLS / owner / RPC topology

Observed Quality/HQP RPCs: postgres-owned SECURITY DEFINER, empty search_path; authenticated EXECUTE,
PUBLIC/anon/service_role absent. HQ tables RLS ON and no client CRUD. Quality allowlist has only
service_role SELECT/INSERT/DELETE in addition to owner. Essay request/signup RPCs are instead
**essay_executor-owned**; that role is NOLOGIN/BYPASSRLS. postgres is not superuser. Do not assume
uniform ownership, replay historical broad bootstrap grants, or reuse essay_worker credentials
for a new broad domain capability.

| Math fact group | Public SELECT | Auth owner SELECT | Direct client writes | Authority |
| --- | --- | --- | --- | --- |
| Published catalog/problem/leaf/public source metadata | Through bounded catalog projection (or explicitly safe published-only RLS relation) | Same public surface | NONE | Separate trusted content-ingestion/publish path |
| Draft source extraction/solutions/profiles/private scoring internals | NO | NO as a raw-table default | NONE | Reviewed publication/authorized projection; Quality membership alone cannot publish |
| Attempts / submitted artifact metadata | NO | Owner-only projection/RLS, lifecycle gated | NONE; own input RPC/upload only | auth.uid(), no caller owner override |
| Extractions/evaluations/steps/edges/errors/CORE/hints | NO | Sanitized own DTO; gated hints | NONE | Internal finalize, exact schema/version validation |
| Hint exposure / re-solve | NO | Own history | RPC-only; bound event/retry key | Owner gate + lifecycle |
| Human Quality / processing internals | NO | NO direct table | NONE | Gated Quality/worker RPC, domain-bound permissions |

All private tables RLS ON, grants explicitly revoked from PUBLIC/anon/authenticated/service_role
unless a specific read role is proven necessary. RLS is not protection against TRUNCATE. Function
EXECUTE is explicit, safe empty search_path and qualified relations. Owner/executor has only required
object capabilities; private helpers are not callable by browser. Existing auth identity/Quality
allowlist is reused. **NEW_ROLE_REQUIRED: not established** for catalog/student reads; trusted Math
worker needs an explicit least-privilege capability boundary before worker deployment, not speculative
generic RBAC. Decide exact worker role/grants in the approved implementation package. No roles now.

Launch-minimum conceptual APIs (names/signatures finalized later): bounded catalog list/detail;
submit immutable attempt; owner attempt/evaluation detail and history; request evaluation with retry
key; hint reveal/event; controlled evidence access; operator list/detail; separate Math judgment
submit/history/state; private claim/finalize/fail/reconcile. Re-solve is an attempt kind, not an RPC
per table. Public catalog anon read only; authenticated student/Quality endpoints gate internally;
internal worker endpoints never browser-executable or service-role browser paths.

Keep math-catalog-v1, math-attempt-v1, math-eval-v1, qlm-read-v1 additive. Cursor includes timestamp
and UUID tie-breaker, bounded page/input limits; no unbounded cross-user scans. Unknown contract
versions fail closed; changed required semantics require a declared supported version, not a silent
“minor” change inside unchanged v1. Explicit null/unavailable vs [] semantics, UTC timestamps,
selected-run provenance, missing cost != zero, CORE=[] != failure, uncertain extraction != weakness,
completed AI request != Human Quality PASS. List excludes full answers/evidence; authorized detail
preserves full relevant evidence while excluding unnecessary account direct identifiers.

## Index matrix — every MATH-2A §30/43 row

REQUIRED means a justified access/integrity pattern, not necessarily an additional index beyond
PK/UNIQUE. Verify final query plans on isolated representative fixtures before adding duplicates.

| # | Proposed query/index | Decision | Correction / reason |
| --- | --- | --- | --- |
| 1 | university/year/track catalog | CORRECT | Reuse essay_exams identity index for university/year; index Math set exam FK. Track is contextual metadata, not duplicate master key. |
| 2 | problem→leaves ordered | REQUIRED | UNIQUE(problem_version_id,order_index) can supply ordering; singleton leaf same route. |
| 3 | active profile | CORRECT | Typed scope + ACTIVE partial uniqueness with NULLS NOT DISTINCT/disjoint scopes; resolver matching index aligned. |
| 4 | problem-version→sources | CORRECT | Index/PK on binding relation by immutable problem-version id; source can serve multiple problems. |
| 5 | canonical solutions | REQUIRED | Exact problem/leaf-version lookup + verified activation/origin as needed; reuse unique version keys. |
| 6 | student's recent attempts | REQUIRED | (student_id,created_at DESC,id DESC) stable pagination and erasure lookup. |
| 7 | current extraction | REQUIRED | UNIQUE(attempt_id,version); selected run explicitly pinned, latest is only a discovery view. |
| 8 | attempt evaluations | REQUIRED | (attempt_id,created_at DESC,id DESC). |
| 9 | steps ordered | CORRECT | (evaluation_id,leaf_version_id,order_index); order is per leaf, not globally unique by assumption. |
| 10 | root errors | DEFER | Eval-leading FK/support index required; extra (evaluation_id,error_kind) only if bounded per-eval filtering needs it. |
| 11 | CORE ordered | REQUIRED | UNIQUE(evaluation_id,priority) plus same-evaluation membership key; don't duplicate identical index. |
| 12 | exposures | CORRECT | (evaluation_id,created_at,id) history; hint/attempt FK support as needed, not redundant isolated indexes by default. |
| 13 | re-solves | CORRECT | predecessor_attempt_id index on attempts after MERGE; prior-evaluation lookup if used. |
| 14 | Quality evidence | REDUNDANT | Detail uses existing eval/child keys; global recent evaluation discovery separately needs (created_at DESC,id DESC), not a mythical projection index. |
| 15 | issue frequency/model trends | DEFER | POST_LAUNCH analytics/query evidence only. |
| 16 | DAG traversal | CORRECT | Launch endpoint composite unique/FK indexes needed for integrity/cycle traversal; reverse endpoint support where not supplied. Extra graph-performance indexes defer. |

Additional launch constraints/indexes: content logical/version uniqueness, request idempotency,
source-region/coverage/causal-edge binding keys and FK erasure lookups. No speculative warehouse,
model-drift or voice-reporting indexes.

## Integrity matrix — every MATH-2A §44 invariant

| # | Invariant | Enforcement | Exact correction |
| --- | --- | --- | --- |
| 1 | One ACTIVE profile/exact scope | DB + TRANSACTION | Null-safe typed unique; serialize activation; reject equal-rank overlap at resolver. |
| 2 | Immutable authority pins | DB + TRANSACTION | Exact FKs/parent uniques + immutable payload guards; validate selected versions at finalize, NOT NULL alone insufficient. |
| 3 | Leaf belongs to problem | DB | Composite leaf/problem-version FK. |
| 4 | Solution correct problem/leaf/version | DB | Composite context FK; singleton leaf removes polymorphic nulls. |
| 5 | Criterion source authority/version | DB + TRANSACTION + APPLICATION | Exact source-version FK and scope binding; transactional bundle check; human verification of source meaning. |
| 6 | Step evaluation/attempt context | DB | Eval/leaf/attempt version composite context; no independent conflicting owner. |
| 7 | DAG endpoints same evaluation | DB | Two composite endpoint FKs; no self-edge CHECK and directed-edge UNIQUE. |
| 8 | DAG acyclic | TRANSACTION | Locked bounded whole-graph finalize validation before publication. |
| 9 | CORE same-evaluation step | DB | Composite error/step/eval binding, unique membership/rank. |
| 10 | Propagation same evaluation | DB + TRANSACTION | Composite causal endpoint FKs; verify root linkage/reachability in finalized graph. |
| 11 | Hint exposure correct eval/attempt | DB + TRANSACTION | Composite hint/context FK; server owner/delivery/retry validation. |
| 12 | Re-solve same student/problem lineage | DB + TRANSACTION | Same-owner/problem composite context and serialized predecessor/earlier sequence; version compatibility and STEP_RETRY target validated. |
| 13 | Evidence own attempt | DB + TRANSACTION | Owned artifact/attempt FK + RLS; Storage path/admission ownership separately validated, not solved by relational FK alone. |
| 14 | Official content not private evidence | DB + APPLICATION | Separate typed reference targets, no generic storage locator FK to private artifacts; publication/privacy review blocks copied private bodies. |
| 15 | Mathematical correctness | APPLICATION | Evaluator + Human Quality; no SQL CHECK can prove solution validity. |

UNNECESSARY/DERIVED: MIXED, parent format, active review head, and a copied core_focus flag when
CORE relation already defines membership. Root/propagated classification is **not** discarded as
derived: freeze the evaluation-time judgment. Human verification remains separate from DB validity.

## Exit decision and next gate

University identity reuse PASS with the exact map above; response format PASS. Evaluation profile,
versioning, DAG, privacy and security are feasible **with the specified corrections**, not runtime
verified. New canonical facts YES. Existing **shared HQ schema** change required YES for literal
store reuse; existing Humanities Essay payload/table redesign required NO. Credit ledger replacement
NO; bounded Math binding/operations required. ql-read-v1/hq-read-v1 breaking changes NO.
ADR2_CHANGE_REQUIRED_NOW NO; future lifecycle extension required before Math activation.

Before Math DDL authorization, reconcile M2B-01–09 into the implementation contract, especially
shared HQ exact binding/constraints/read isolation. No new Owner decisions; D1/D2 remain accepted.
Exact evidence duration, official raw storage rights, worker/provider/runtime/storage verification
are later activation gates, not reasons to reopen approved policy or start Vision work now.
VOICE-1 remains derived/ephemeral, no audio table; Science has no new tables. Production AI OFF.

Validation: read-only catalog review and documentation/static checks only. No isolated Math SQL,
behavioral tests, production authorization tests, migration or provider execution is claimed.
Next: **Owner/ChatGPT review → corrected shared integration contract → Math DB implementation
explicit authorization**. STOP; no automatic schema work.
