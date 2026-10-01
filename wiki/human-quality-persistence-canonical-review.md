# Human Quality persistence — HQP-2 canonical review

Date: 2026-10-01. DOCUMENTATION ONLY. Review complete; implementation not authorized.

## 1. Executive decision

**ACCEPT_HQP1_WITH_NARROW_CORRECTIONS. READY_FOR_IMPLEMENTATION = NO** until Owner resolves the two retention decisions in §7. The small additive architecture is viable; no Essay redesign is needed. This is not unconditional design approval. CANONICAL_DB_REVIEW = COMPLETE_WITH_FINDINGS; Production remains NOT_APPLIED, implementation NOT_STARTED, lifecycle ACTIVE, primary status DESIGNED.

Owner D1–D5 are accepted. Two proposed relations and three gated RPCs suffice. Reuse existing evaluation identity, JSON observations and Quality authorization. Do not duplicate evaluation output, CORE or sentence feedback. There is no canonical-schema blocker requiring a redesign; there is an unresolved privacy/accountability policy gate.

Quality authorization remains PRODUCTION_VERIFIED. LAB Console/adapter remain IMPLEMENTED / LOCAL_VERIFIED; Production full-answer detail NOT_ASSESSABLE. AI OFF, model NOT_SELECTED, Pilot NOT_AUTHORIZED. No SQL, DB connection, login, credential access, provider call or runtime implementation occurred in HQP-2.

## 2. Actual canonical schema facts

### Evidence and preflight

Canonical APP worktree: `codex/essay-scaffolding-vnext`, starting commit `2ebec8de5f1b055fc35efc3779d32a48f93e5440`; remote branch matches by read-only ls-remote. Tracked tree clean; pre-existing untracked `supabase/.temp/` left untouched. Older day7 checkout is not schema authority. Local migrations: 24. The [verified gateway closeout](essay-lab-worker-provider-l2.md#lsa-2c-production-gateway-verification--2026-10-01) records 22 remote versions; this review did not rerun Production introspection. provider005 remains unapplied; day_targets SQL/ACL effect verified, tracking separate/unregistered. Historical migration header “NOT APPLIED” is preparation history, not current deployment evidence.

LAB proposal: [HQP-1 at b9cff1b](https://github.com/LC3808/legendstudy-lab/blob/b9cff1b48cd4c5c664f07c69eb1ba6cc024c3152/docs/architecture/HQP-1_HUMAN_QUALITY_PERSISTENCE.md), branch `claude/quality-console-v0`, remote matches. Unified Wiki starting main `1d814d3f3ba33b89273f3cec7d0be2cd46183cd5`, remote matches. Read project AI_CONTEXT, CURRENT_STATUS, ARCHITECTURE, SOURCE_OF_TRUTH and Oct1 Daily. Current Status/LEC closeouts take precedence over older registry prose still calling Console NOT_STARTED; only the two authorized project closeout files are changed here.

### Exact sources

- [P: student product DDL](../supabase/migrations/20260928000100_student_essay_product.sql): relations, composite FKs, terminal/child guards, RLS.
- [S: server operations](../supabase/migrations/20260928000300_essay_server_operations.sql): executor role, finalize, owner erase.
- [C: scaffolding](../supabase/migrations/20260929000100_essay_scaffolding_persistence.sql): observation CHECK, exact-source validation, frozen context.
- [B: commercial core](../supabase/migrations/20260929000300_essay_credit_commercial_core.sql): subsequent finalize/billing definition; no HQP dependency.
- [O: owner status](../supabase/migrations/20260929000400_essay_owner_evaluation_status.sql): function `essay_evaluation_status(uuid)`, not a Human Quality table.
- [Q: Quality read authorization](../supabase/migrations/20261001000100_quality_read_authorization.sql): deployed read DTO and narrow operator gate.
- [Account privacy](account-deletion-privacy.md), [worker/reviewer boundary](essay-lab-worker-provider-l2.md), [architecture inventory](platform-architecture-health-review-a.md), [scaffolding mapping](essay-lab-scaffolding-persistence.md).

| Existing object | PK / relationship / deletion | Canonical meaning and boundary |
|---|---|---|
| profiles | id → auth.users CASCADE | identity extension; no Quality authority |
| essay_practice_sessions | id; user_id → profiles CASCADE; question RESTRICT | immutable owner/question identity |
| essay_attempts | id; session CASCADE; unique session/attempt_no | immutable body, body_sha256, submission conditions |
| essay_evaluations | id; composite attempt/session and session/question CASCADE | evaluation_version, contract_version, regime_key, model_provider/name/version, prompt_version, evidence_manifest_sha256, input/output_sha256; terminal result frozen |
| essay_evaluation_dimensions | id; evaluation/question CASCADE, criterion/question RESTRICT | per-result criterion observation |
| essay_improvement_items | id; session CASCADE; unique(session_id,issue_key) | root identity, not current CORE selection |
| essay_improvement_progress | id; issue/session and evaluation/session CASCADE; unique(issue_id,evaluation_id) | longitudinal observation; previous_progress composite FK SET NULL on predecessor deletion |
| essay_evaluation_evidence | id; evaluation CASCADE; official evidence RESTRICT; dimension/progress composite CASCADE | result-to-source links; not source text copy |
| essay_generated_rewrites | id; unique evaluation_id CASCADE | AI-generated text; never student rewrite |
| essay_ai_processing_runs | id; evaluation/rewrite CASCADE | selected run, model/prompt, telemetry; not Human Quality |
| quality_operators | user_id PK → auth.users CASCADE; created_at | narrow Quality LAB access only; owner postgres |

P enables RLS on Essay tables: authenticated owner SELECT, no direct canonical result writes; drafts are the deliberate owner CRUD exception. S grants executor the necessary server writes and owns server functions with `essay_executor`; privileged service_role also has Essay DML. Terminal/update guards, not RLS alone, freeze output. Explicit erasure uses DELETE and is allowed. Table ownership must not be inferred from an RPC's owner; last verified catalog/ACL baseline remains the source for deployed ownership, not a new live attestation here.

Q has RLS ON, zero allowlist policies, no PUBLIC/anon/authenticated table rights; service_role SELECT/INSERT/DELETE only. Three functions owned by postgres, SECURITY DEFINER, empty search_path, authenticated EXECUTE only. is_quality_operator checks auth.uid, matching authenticated JWT subject/role/expiry and allowlist membership; gateway verifies signature. It never trusts profile/school/admin_users/email.

Evaluation lifecycle includes operator_reevaluation request kind, supersedes_evaluation_id (same attempt, nullable predecessor on erase), invalidation annotation and correction reason. These are not new Quality write permissions. No standalone public invalidation/operator-reevaluation RPC implementation was found in the canonical migration set; do not infer a launch endpoint from lifecycle columns or an isolated fixture. Existing lifecycle/status/read surfaces remain unchanged.

## 3. HQP-1 reconciliation

NEW_CANONICAL_FACT = YES. Systematic human rubric/verdict/reviewer/history does not exist in these relations. Pilot prose, signed application receipts, local_reviews, owner status and processing status encode different facts. No automatic Pilot backfill.

| Proposed frozen field | Canonical source | Classification / recommendation |
|---|---|---|
| evaluation_id | essay_evaluations.id | DIRECT_CANONICAL_COLUMN; required FK |
| reviewed_evaluation_ref | same id copied without FK | REDUNDANT while linked; persistent erasure linkage risk; omit under recommended deletion policy |
| reviewed_evaluation_version | evaluation_version | DIRECT_CANONICAL_COLUMN; duplicate snapshot unnecessary |
| reviewed_prompt_version | prompt_version | DIRECT_CANONICAL_COLUMN; read immutable evaluation |
| reviewed_contract_version | contract_version | DIRECT_CANONICAL_COLUMN; read immutable evaluation |
| reviewed_model_provider | model_provider | DIRECT_CANONICAL_COLUMN; not dependent on pending provider005 |
| reviewed_model_name | model_name | DIRECT_CANONICAL_COLUMN; read immutable evaluation |
| reviewed_output_sha256 | output_sha256 | DIRECT_CANONICAL_COLUMN; retain server-copied review binding |
| reviewed_evidence_manifest_sha256 | evidence_manifest_sha256 | DIRECT_CANONICAL_COLUMN; read immutable evaluation |

Minimum subject binding: evaluation_id + server-copied reviewed_output_sha256, plus reviewer_user_id, rubric_version, server created_at as review provenance. Accept only completed result with non-null canonical hash; compare caller's expected output hash to server value, never accept a caller-authored provenance snapshot. Evaluation ID identifies the immutable result; hash detects stale client subject. No need to hash reconstructed ql JSON or add output copies. Full provenance remains accessible from the evaluation; deletion deliberately ends reproducibility if §7 CASCADE is approved. Generated-rewrite conditional assessment needs an additional server-captured nullable **reviewed_generated_rewrite_id** (validated as completed child of this evaluation), because it can complete after the main evaluation and is not covered by evaluation output hash.

## 4. Findings

| ID | Priority | Evidence / problem | Narrow resolution |
|---|---|---|---|
| HQP2-01 | LAUNCH_BLOCKER | HQP-1 §18 claims SET NULL leaves nothing identifying; P/S actually erase learning records. Retained UUID/hash/notes remain linkable; length limits do not prohibit copied content. | Owner choose deletion vs explicit retained-history policy (§7); do not implement automatic retention. |
| HQP2-02 | LAUNCH_BLOCKER | reviewer SET NULL weakens who/when audit and ordinary immutable UPDATE blocker would reject the FK action | Owner accept precise attribution loss or specify controlled retention; narrow FK exception, no alias registry by default |
| HQP2-03 | LAUNCH_REQUIRED | arbitrary target_ref; evidence link ID and generated rewrite ID not in ql-read-v1; sentence is JSON | typed references and evaluation-scoped resolution (§9), no fake sentence ID |
| HQP2-04 | LAUNCH_REQUIRED | two corrections can supersede same row; triplet idempotency permits key reuse across subjects | unique predecessor + serialized atomic submit; globally unique client key + exact payload comparison |
| HQP2-05 | LAUNCH_REQUIRED | projection ambiguity for mixed versions, material PASS_WITH_NOTES and lifecycle changes | deterministic active-head rules and rubric consistency (§9–10) |
| HQP2-06 | LAUNCH_REQUIRED | source references/current catalog do not guarantee original official text availability; generated rewrite can arrive later | assessability gate, frozen rewrite binding; unknown never NA/OK |
| HQP2-07 | POST_LAUNCH | reviewer/category analytics indexes before a supersession index | prioritize actual history/correction access; defer analytics |

## 5. Corrected launch architecture (conceptual, not DDL)

STORAGE_OPTION_D = PASS_WITH_CORRECTIONS. Two relations, no generic events/RBAC/reviewer registry, no mutable evaluation QA column. Versioned JSONB rubric avoids another dimension table; relational findings allow precise bounded targets. Use text + CHECK vocabulary, not open strings or new DB enums requiring needless type migrations.

**Judgments:** id; evaluation_id; reviewed_output_sha256; nullable reviewed_generated_rewrite_id; nullable-on-approved-erasure reviewer_user_id; rubric_version; overall_disposition; rubric_result; selection_reason (default EARLY_CENSUS); recommended_action (default NONE); nullable summary_note; nullable supersedes_judgment_id; client_submission_id; server submission_payload_sha256; server created_at. Immutable application data. No reviewed_evaluation_ref or duplicated model/prompt/version columns under the recommended cascade policy. Erasure decision must precede final DDL.

**Findings:** id; judgment_id; issue_category; severity; target_kind; **target_ref JSONB with an exact discriminated shape**; optional note. No second internal_note. created_at is inherited from atomic parent submission rather than duplicated per finding. Severity is useful operational triage, not a numeric score. No new canonical sentence relation.

FK recommendation subject to §7: evaluation CASCADE, reviewer SET NULL, findings → judgment CASCADE, same-evaluation supersession composite FK with non-deferrable NO ACTION (whole-evaluation cascade must pass isolated regression); one successor per predecessor. reviewed_generated_rewrite_id is same-evaluation checked and FK with SET NULL on authorized child erasure only; do not retain an orphan rewrite identifier. All FK-induced nulling exceptions must preserve every other column. Student erasure must win over operational retention. There is no direct operator DELETE/UPDATE.

Checks: bounded vocabulary, hash shape, exact rubric JSON, target shape, note/payload bounds, same-evaluation relationships, unique idempotency, unique predecessor, no self-supersession. Cross-row validation occurs within the submit transaction. Existing Essay/credit/ql-read-v1 schemas and signatures do not change.

## 6. Security / AUTH-A

AUTH_A = PASS_FOR_LAUNCH. Owner D2 explicitly authorizes narrow review submission; existing “Quality LAB access only” does not prohibit that additive gated capability. Do not reinterpret this as global admin, billing operator or evaluation invalidation authority.

New tables: postgres-owned, RLS ON, no client policies. Revoke inherited PUBLIC/anon/authenticated/service_role privileges explicitly. No direct client/service write path; minimal new definer functions owned by postgres, fully qualified references, search_path empty, authenticated EXECUTE only, no PUBLIC/anon/service_role EXECUTE. Every new RPC gates is_quality_operator **before** lookup/idempotency processing. Reviewer is auth.uid() only. No supplied reviewer/email, self-enrollment, browser service key or profile-based bypass. Signed-out/non-operator errors must not reveal subject/key existence. Revoked operator cannot replay a key to recover notes. No change to the existing helper or allowlist ACL.

For membership revocation vs submission race, serialize the submit membership check against deletion of that allowlist row; authorization is determined at the transaction's accepted gate. Keep lock ordering documented and test erasure/concurrent correction, not AI lease machinery.

Judgment/findings with reviewer/time/subject/rubric/correction are sufficient primary write audit for accepted review writes (subject to approved deletion policy). Failed requests and membership changes are separate operational audit concerns. No duplicate judgment audit table. Preserve Owner membership-change evidence now; automated membership management requires its own authorized write audit before introduction. Privileged READ audit is POST_LAUNCH.

## 7. Privacy / erasure — unresolved Owner gate

P/S exact graph: auth.users → profiles CASCADE → practice_sessions CASCADE → attempts/evaluations CASCADE → dimensions/progress/evidence links/rewrites/runs CASCADE. quality_operators independently cascades from auth.users. `essay_erase(session)` checks owner, locks account/session/grants, releases pending billing reservations, then DELETEs session. This is hard deletion, not pseudonymization. Account-deletion privacy prose predates later Essay/day_targets; use actual later DDL for their graph, not its historical “every row” generalization. Its retained free-text feedback policy itself has an unresolved scrubbing question; it does not authorize retaining new Human Quality notes.

| Model | Assessment |
|---|---|
| SET NULL + copied evaluation UUID/hash/notes | Does not anonymize; other exports/logs and note content can reconnect subject. Needs explicit purpose, retention, access and redaction policy. Not approved implicitly. |
| CASCADE evaluation → judgments → findings | **Recommended smallest launch policy**, consistent with learning erasure; deliberately loses QA history/coverage. Must label resulting metrics as retained-data-only. Owner must accept this loss. |
| RESTRICT | Reject as default: blocks student/session/account erasure for QA retention. |
| retained tombstone | Still linkable if ID/hash retained; adds explicit redaction/retention workflow. Defer unless Owner requires retained QA history. |

**Owner decision E1 required:** approve deletion of all linked HQ judgments/findings with evaluation/session/account erasure (recommended), or define exactly what may survive, for how long and how notes/targets/hashes are scrubbed. HQP-2 does not choose retention rights on the Owner's behalf. EVALUATION_ERASURE_MODEL = OWNER_POLICY_REQUIRED.

**Owner decision E2 required:** accept reviewer_user_id SET NULL when the reviewer auth account is deleted, preserving the other review facts only while their student subject exists, with visible attribution-unavailable state. This is pseudonymous/unattributed history, not guaranteed anonymity. No email/name/alias snapshot. RESTRICT blocks account deletion; CASCADE reviewer deletion would remove other students' QA evidence; a separate registry is unnecessary. House FK convention is compatible (quality_operators references auth.users), but that does not decide accountability policy. REVIEWER_IDENTITY_MODEL = OWNER_POLICY_REQUIRED. Existing admin deletion blocking uses admin_users; do not silently extend it to Quality operators.

Graph consequences: review self-FK must allow full subject cascade without a row-order RESTRICT failure; cycles/branching prevented (§8). Findings have no independent lifetime. Blanketing UPDATE/DELETE with reject triggers would break reviewer SET NULL and student cascades; keep these narrowly authorized exceptions. A privacy DELETE remains distinguishable from a review correction INSERT. No claim of absolute immutability against a DB owner who can alter triggers.

One summary note ≤2000 Unicode characters, optional; finding note ≤1000, at most20 findings, total canonical payload ≤32 KiB UTF-8 (recommendation, not existing limit). Internal-only, available only to current operators through gated history. Length bounds cannot semantically prevent answer/PII/secret/raw chain-of-thought copying: require UI guidance and operator policy, and apply erasure to notes too. No extra internal_note, student visibility, or student answer/feedback copy. Direct account identifiers never copied.

## 8. Append-only, correction and idempotency

APPEND_ONLY_MODEL / SUPERSESSION_MODEL = NEEDS_CORRECTION in HQP-1; the following recommendation resolves their technical gaps, pending erasure policy.

Use RLS+no direct rights+RPC-only atomic INSERT plus a small UPDATE guard matching the house pattern. No UPDATE/DELETE RPC. Guard allows only approved FK nulling of reviewer/rewrite and otherwise rejects edits; do not add a blanket DELETE blocker that prevents subject erasure. Privileged administrative deletion remains controlled policy, not a normal operator capability. Owner/postgres can bypass enforcement administratively; document that boundary.

Parent supersession must already exist, belong to same evaluation and be a current head. Unique non-null supersedes_judgment_id permits only one successor. Lock parent; concurrent losers get explicit conflict and must reread, not silently become independent reviews. New IDs server-generated, parent pre-existing, FK non-deferrable, edge immutable ⇒ cycles impossible through submit. DB same-evaluation composite FK/no-self constraints backstop the RPC. Independent submissions remain separate roots. Any current authorized reviewer may correct another, recording their own identity (D3).

Global unique client_submission_id. Server hashes canonical semantic payload (evaluation/hash, captured rewrite binding, rubric, ordered findings, notes, selection/action, predecessor); exclude server id/time. Same key+same reviewer+same payload returns existing result after current authorization, within one transaction; same key changed payload/subject returns conflict; another reviewer gets generic conflict without disclosure. Serialize unique-key races and reread winner. Erased-subject retry fails lookup; no forever idempotency tombstone. Canonical normalization/order rules are part of the new DTO version. No AI leases, retries or fencing imported.

## 9. Rubric and finding targets

RUBRIC_V1_STORAGE_CONTRACT = NEEDS_CORRECTION (assessability and consistency); RUBRIC_VALIDATION = versioned hybrid CHECK + private validator + writer cross-row checks. Exact nine keys, six required OK/CONCERN/FAIL; three conditional OK/CONCERN/FAIL/NA. Unknown keys, aliases, unsupported versions, missing dimensions, invalid types/values and oversize data rejected. JSONB object has one value per key; do not promise to detect lexical duplicate keys already collapsed by JSONB parsing. Semantic aliases are forbidden.

Required dimensions map to answer/summary/improvements, selected CORE, next_action/sentence direction, official evidence/criteria, stance/rewrite and claims respectively. ql detail exposes full answer, judgments and references; **does not archive original official PDF text**. Current catalog labels can differ from frozen versions. Evidence adherence cannot be auto-proven from URL/hash presence. For a full v1 submission the reviewer must have the matching official source and sufficient context; unavailable source/legacy scaffolding/truncated required history means defer full rubric submission, never fill OK or NA to get it accepted. Source access confirmation is an operator workflow requirement, not a server proof of correctness. No new false quality fact for unassessable cases.

Conditional NA rules: sentences NA only when completed1.3 available observations yield []; progress NA only when no canonical prior-review context/links exist; generated rewrite NA only if no completed rewrite was bound at submission. Pending/failed rewrite has no generated output to assess. NULL legacy/incomplete observation or missing required predecessor context is unknown, not empty. Validate these on server; retrieve prior evaluations through unchanged ql detail if navigation window is truncated. Completed rewrite existing at submission must be bound and assessed; later completion does not retroactively reinterpret NA. If bound rewrite later erased, show unavailable, not “never existed.”

Reject PASS/PASS_WITH_NOTES with diagnosis or hallucination FAIL. Recommended additional consistency: PASS requires all applicable OK and no findings; PASS_WITH_NOTES permits CONCERN/MINOR but no dimension FAIL or MATERIAL/CRITICAL finding. NEEDS_REVIEW/FAIL remain human dispositions; no numeric score or automatic escalation. Version rules are immutable; a future rubric adds a version, never changes v1 interpretation.

| target_kind | Exact proposed target_ref shape / same-evaluation validation |
|---|---|
| OVERALL | null; evaluation is subject |
| DIMENSION | {dimension_id: uuid}; lookup dimension.evaluation_id |
| PROGRESS | {progress_id: uuid}; lookup progress.evaluation_id |
| ISSUE_KEY | {issue_key: string}; session-scoped item must have progress on subject evaluation |
| SENTENCE | {progress_id: uuid, observation_key: string}; match progress.scaffolding_observation.sentences entry; no position-generated ID |
| EVIDENCE_LINK | {evidence_id: uuid, dimension_id: uuid-or-null, progress_id: uuid-or-null}; resolve actual evaluation_evidence row; require exactly one canonical match; never arbitrary source URL |
| GENERATED_REWRITE | null; resolve unique completed evaluation child server-side, require reviewed_generated_rewrite_id matches it |

Valid targets are the seven kinds with these corrected shapes. Invalid/unstable: bare polymorphic text/UUID, sentence array offset/span as identity, unbound issue key, caller-invented rewrite ID, source metadata mistaken for evaluation link. ql-read-v1 exposes evidence composite values and generated rewrite object (not IDs), so this design needs no read-v1 modification.

Sentence root is `essay_improvement_progress.scaffolding_observation` version1 JSON; observation_key persisted, finalizer rejects duplicate keys/spans evaluation-wide, parent progress gives stronger scoped identity. CORE = non-resolved progress with observation.core_focus true, ordered priority/issue_key/id, not priority threshold. NON-CORE retained. CORE=[] valid; missing observations NULL. Previous reviews are progress links/context, not a preserved original review array. Rubric must not claim more fidelity than ql detail exposes.

## 10. Additive RPC / projection contract

RPC_SURFACE = PASS_WITH_CORRECTIONS. Proposed, not implemented:

1. `ql_submit_human_judgment(p_payload jsonb)` — fixed versioned keys, bounds above; derives reviewer/time/provenance/targets, locks subject and parent, writes parent+children atomically. No supplied reviewer. Requires expected_output_sha256; stale/missing/ineligible subjects fail. Historical completed invalidated evaluations may be reviewed as historical, with lifecycle displayed separately.
2. `ql_review_state(p_evaluation_ids uuid[])` — operator gate first; max100 input elements before deduplication, reject NULL elements, []→[]; existing authorized subjects only. Missing IDs return explicit NOT_FOUND availability, not UNREVIEWED; operator existence visibility is already permitted, non-operators cannot probe.
3. `ql_list_human_judgments(p_evaluation_id uuid,p_limit integer,p_before timestamptz,p_before_id uuid)` — operator gate, default20/max100, paired `(created_at,id)` descending keyset cursor; complete internal rubric/findings/notes, reviewer UUID (no account profile lookup), null reviewer means erased attribution. Include derived current/superseded state; [] only for existing subject with no reviews. No new student read surface.

All new responses versioned (e.g. hq-read-v1); timestamps UTC timestamptz, nullable fields specified above. History not unbounded; list state is derived at read transaction snapshot. Keep all three existing Quality signatures/semantics unchanged; no mandatory ql-read-v2. Current operator receives internal notes under AUTH-A.

Projection on active heads only (rows without successor): zero→UNREVIEWED; one→ACCEPTABLE for PASS/PASS_WITH_NOTES, WITH_CONCERNS for NEEDS_REVIEW, FAILED for FAIL. Multiple heads: differing **exact rubric versions**→MULTIPLE_REVIEWS + comparison_status=NOT_COMPARABLE; same version/different disposition buckets→DISAGREEMENT (PASS vs NEEDS_REVIEW included); same bucket→MULTIPLE_REVIEWS + consensus_bucket. Buckets never hide material issues; has_material_issue, active_count, total_count and latest active created_at remain separate derived values. No latest-wins tie breaker. No claim of rubric-major compatibility without an explicit version mapping.

A judgment stays on evaluation A after invalidation or B reevaluation; A lifecycle is displayed at read time, A QA never approves B. Generated rewrite distinct from student attempt. NULL cost is not zero; request completion not Human Quality PASS. FAIL/PASS writes never call invalidation, AI, publish, progress or credit functions.

## 11. Index decisions

| Candidate | Decision / reason |
|---|---|
| judgments(evaluation_id,created_at DESC,id DESC) | LAUNCH_REQUIRED; bounded history/cursor and batch subject access |
| judgments(reviewer_user_id,created_at DESC) | POST_LAUNCH; no launch reviewer-history query; FK deletion volume to measure |
| unique(evaluation_id,reviewer_user_id,client_submission_id) | UNNECESSARY; replace with global unique client_submission_id |
| unique(client_submission_id) | LAUNCH_REQUIRED; atomic retry conflict |
| findings(judgment_id) | LAUNCH_REQUIRED; child loading/cascade |
| findings(issue_category) | POST_LAUNCH; analytics not launch read path |
| unique non-null supersedes_judgment_id | LAUNCH_REQUIRED; single successor and head lookup |
| unique(id,evaluation_id) | LAUNCH_REQUIRED constraint support for composite self-FK |

PK indexes implicit. No new Essay/global-list index in HQP; existing deferred list-performance decision remains separate. No Production query plan/load test claimed.

## 12. Launch / later scope

LAUNCH_BLOCKER: E1/E2 policy resolution before final migration specification; no implementation authorization yet.

LAUNCH_REQUIRED for later HQP implementation: two tables, gated writes, immutable correction, versioned validation, same-subject targets, bounded read state/history, idempotency, minimal indexes, erasure/concurrency regression, audit fields. Selection_reason KEEP_LAUNCH (EARLY_CENSUS default; bounded vocabulary, omit LEGACY_IMPORT until separate import contract). Recommended_action KEEP_LAUNCH optional/default NONE, non-executing only. Severity KEEP_LAUNCH; note optional. No action execution-state column.

POST_LAUNCH: reviewer display aliases/metrics, read audit, automated membership-change audit before introducing membership-write tooling, analytics indexes, expanded targets/filtering. Separate reviewer role revisited on team/read-only/external reviewer expansion. DEFERRED: sampling/anomaly engines, Golden Set, generic RBAC, analytics warehouse and curated Pilot import. None blocks Oct10 merely for completeness.

## 13. Owner decisions and preservation answers

D1 ACCEPT vocabulary; D2 ACCEPT AUTH-A; D3 ACCEPT cross-reviewer correction with single-successor constraint; D4 ACCEPT optional capped internal note; D5 ACCEPT no automation. E1/E2 are additional retention choices, not reopening D1–D5.

Seven preservation questions: (1) server submitted time and explicit correction edge distinguish original/correction; historical imports deferred. (2) evaluation/hash/rubric and rewrite binding reproduce retained review subject; official-source availability limits disclosed. (3) no verdict UPDATE; erasure deliberate and separately documented. (4) existing auth identity via evaluation/session; no copied school/student profile or new identity. (5) human operational judgment, not student Learning/Outcome or admission Decision truth. (6) operator-only, minimal notes, E1/E2 retention gate, pseudonymization not anonymity. (7) review-state/rates are derived from retained facts and version rules; no stored model-quality percentage.

## 14. Implementation handoff and validation

HQP-3 may start only after E1/E2 resolution and explicit Owner authorization. If E1 chooses cascade and E2 accepts nullable attribution, §5–11 are the concrete minimal implementation recommendation. If retention is chosen instead, define retained fields, deletion/redaction mechanism, retention duration and accountability before DDL; do not quietly keep HQP-1 UUID/hash/note retention.

Required isolated implementation tests: operator allow/non-operator/anon/forged deny; no direct table/service writes; no caller reviewer; existing Essay RLS and ql-read-v1 unchanged; payload/rubric/target validation; CORE0 and empty sentence; legacy/source-unknown guard; concurrent same-key and changed-payload retry; two correction race/same-evaluation/no cycles; rewrite completes after review; invalidation/B reevaluation stays separate; student/session/account erase including multi-row self-FK chain; reviewer FK-null exception; no note/hash orphan retention; no billing/AI side effects. These are future tests, **not executed DB tests in HQP-2**.

Review validation: targeted DDL/function and existing verified closeout inspection, remote-ref checks, documentation links, secret-pattern/manual content check, diff/scope validation. No migration SQL or implementation artifact generated. No Flutter/LAB build or Production test needed. Private directories and credentials were not read or modified.

## 15. Stop

HQP_2_CANONICAL_REVIEW = COMPLETE. NEW_CANONICAL_FACT = YES. STORAGE_OPTION_D = PASS_WITH_CORRECTIONS. AUTH_A = PASS_FOR_LAUNCH. WRITE_AUDIT = SUFFICIENT for retained submitted judgment history, with E2 attribution limitation. CREDIT_BILLING_ISOLATION = PASS; SIGNED_REVIEW_COMPATIBILITY = PASS (pre-publication trusted payload approval/local_reviews differs from post-output rubric QA; HQP never replaces a signer). EXISTING_OWNER_STATUS_REUSE = NO. QL_READ_V1_PRESERVATION = PASS. AI_EVALUATION_LIFECYCLE_COMPATIBILITY = PASS with per-evaluation binding.

READY_FOR_IMPLEMENTATION = NO. READY_FOR_PRODUCTION_APPLY = NO. NEW_SQL_FILES/NEW_MIGRATIONS/NEW_RPC_IMPLEMENTATION/NEW_TABLE_IMPLEMENTATION/PRODUCTION_WRITES/PROVIDER_CALLS = 0. Next: Owner/ChatGPT resolve E1/E2 → separately authorize HQP-3. No SQL, write UI, Pilot, provider or Production AI follows this review automatically.
