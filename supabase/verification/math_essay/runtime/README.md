# MATH-2D physical runtime consumer contract

Canonical APP implementation; **local/isolated only, Production NOT_APPLIED**.
MATH-3B may bind against this contract without writing Math tables. No LAB changes are included.

## Transport and authority

Use PostgREST `rpc(name, {p_request: envelope})`. All four new functions have **one named jsonb argument `p_request`**, return jsonb, are postgres-owned SECURITY DEFINER with empty search_path, and explicitly revoke PUBLIC/anon/service_role EXECUTE.

| RPC/signature | Request dto_version | Caller |
|---|---|---|
| `public.math_input(p_request jsonb)` | `math-input-v1` | authenticated student, server auth.uid() |
| `public.math_extraction(p_request jsonb)` | `math-extraction-v1` | trusted math_extraction_worker only |
| `public.math_evaluation(p_request jsonb)` | `math-worker-v1` | trusted math_evaluation_worker only |
| `public.qlm_quality(p_request jsonb)` | `qlm-runtime-v1` | authenticated, current Quality operator + lifecycle gate |

Envelope has exactly `{dto_version, action, payload}`; payload is an object. Unknown version/action/keys reject. Response has `{dto_version, action, result}`. No arbitrary user/reviewer/account/price/profile authority field is accepted. JWT establishes student subject; a client must never choose a worker role or receive an executor/service key. New runtime worker credential admission/deployment is a separate gate: SQL EXECUTE tests are not Production JWT proof.

Private helpers are not consumer APIs. Existing low-level Math RPCs remain compatible, but new browser/worker integrations should use the named-argument versioned surface. [Generated physical catalog](physical_catalog.json) records exact actual isolated signatures, return types, owners, ACL and relevant columns. No canonical Supabase TypeScript type-generation workflow exists in this Flutter repository; no Production type generation was used. The catalog is generated from the canonical isolated schema, not claimed as a generated TypeScript SDK.

## Student input actions

Fields listed without `?` are required. UUID strings must parse as UUID. Null is allowed only where indicated; do not send unknown placeholder fields.

| action | payload | result |
|---|---|---|
| create_attempt | client_submission_id, leaf_id, kind, input_kind; typed_answer?, predecessor_id?, prior_evaluation_id?, target_step_id? | attempt_id |
| register_evidence | attempt_id, metadata | artifact_id, storage_state, upload_available=false |
| confirm_extraction | attempt_id, run_id, regions | confirmed_run_id |
| read_input | attempt_id | attempt, input_state, can_request_evaluation, selected_extraction_id, candidate, artifacts, candidate_regions, confirmed_regions |
| request_evaluation | attempt_id, client_submission_id | evaluation_id |
| read_result | evaluation_id | existing owner Math result projection (`qlm-read-v1` nested DTO) |
| reveal_hint | hint_id, client_submission_id | existing bounded hint delivery result |
| history | limit? (default20,1–50), before_at?, before_id? | attempts, limit, evaluation_history_limit=20 |

`kind`: INITIAL / SHORT_ANSWER_RESOLVE / FULL_RESOLVE / STEP_RETRY. Re-solve requires own predecessor and completed prior evaluation of the same logical leaf; STEP_RETRY also requires target_step_id in that evaluation. INITIAL has no predecessor/prior/target. input_kind: TYPED / EVIDENCE / MIXED. TYPED requires nonblank typed_answer (≤30000 chars). SHORT_ANSWER_RESOLVE is restricted to SHORT_ANSWER leaf. Leaf response format is SHORT_ANSWER / SHORT_REASONING / FULL_SOLUTION / PROOF, never persisted MIXED.

`metadata`: position (positive integer), media_type (image/png,image/jpeg,image/webp,application/pdf), byte_size (1–20971520); optional content_sha256 (lowercase64hex), width/height (1–50000), orientation (0/90/180/270). Maximum20 artifacts per attempt. Same attempt+position with identical normalized metadata returns the existing artifact; changed metadata conflicts. Evidence inventory freezes at first extraction; no registration after evaluation. content_sha256 from client metadata is not a server-verified byte receipt.

`regions`: array≤100; each item exactly region_id, raw_text, normalized_math (strings≤10000 chars). All references must belong to the exact completed latest candidate run of the owned attempt. Every uncertain region must be explicitly confirmed/corrected. The candidate and original evidence remain unchanged. Confirmation creates a new CONFIRMED run and copied region facts, preserving provider candidate provenance through predecessor_id; it neither creates an attempt nor posts Credit. Retry identity is candidate + exact ordered confirmation payload: exact retry returns the same confirmed_run_id, changed payload conflicts. One confirmation per candidate; no last-write-wins. To change a confirmed input, a new candidate/version workflow is needed before evaluation; submitted attempts remain immutable.

## Readiness and frozen input

READY_FOR_EVALUATION is a **server-derived projection**, not a writable client state. No separate mutable status authority is added to attempts.

- TYPED, including SHORT_ANSWER, uses the legitimate typed path without a fabricated Vision run.
- Evidence input requires registered PRESENT evidence, the latest completed candidate, a confirmation of that exact candidate and resolution of all uncertain regions.
- New extraction claim immediately makes an older confirmation ineligible. Confirmation/claim/finalize/request serialize on the attempt after the lifecycle lock.
- request_evaluation freezes selected_extraction_id plus authority/profile/source pins in the evaluation transaction with billing reservation. No later extraction is admitted after an evaluation exists.
- input_state: INPUT_REQUIRED / EXTRACTION_PROCESSING / CONFIRMATION_REQUIRED / READY_FOR_EVALUATION / INPUT_FROZEN. `can_request_evaluation` distinguishes a failed-evaluation retry from immutable input freezing; it is advisory until the server repeats checks at request commit.
- candidate and selected_extraction_id are null when unavailable; arrays are empty, not invented records. Candidate error_code is sanitized; leases are never returned by student input reads.

History: descending (created_at,id), strict tuple-before cursor with both fields supplied together; derive the next cursor from the last shown attempt, stop on an empty page. Each attempt contains at most20 latest evaluation summaries (requested_at/id); this is explicitly bounded, not a claim of unlimited evaluation history. Own result lookup remains available by known evaluation ID. Student owner DTO excludes account identifiers and Storage object keys. Hint L1/L2 remain hidden until explicit delivery; L2 requires L1. Revealing hints is not re-solve and has no Credit charge.

## Extraction worker

| action | payload | result |
|---|---|---|
| claim | attempt_id | run_id, lease_token, lease_until, artifacts, evidence |
| finalize | run_id, lease_token, output | run_id |
| fail | run_id, lease_token, error_code | failed=true |

Claim has a five-minute lease. Concurrent live claim conflicts; expired processing is marked TIMEOUT and a new fenced candidate is created. Claim evidence includes server-owned bucket/object_key plus metadata for a future trusted Storage broker; never pass that worker DTO to browser consumers. This is not a signed URL or an upload grant.

output keys exactly regions, provider, model, model_version. regions1–100 contain artifact_id,page,reading_order,raw_text,normalized_math,confidence?,uncertain,x,y,width,height. Coordinates normalized0–1; positive rectangle inside page, page/order positive, unique reading order. Nullable confidence is0–1 when supplied. Provider/model are nonempty; provenance is worker-authored. Max output262144 bytes. Same run/token/exact JSON output retries once without duplicate regions; changed output/stale token/expired lease rejects. error_code: INPUT_FAILED / TIMEOUT / INVALID_OUTPUT. Student confirmation cannot supply confidence/provider/model.

## Evaluation worker and financial boundary

Actions claim/finalize/fail use evaluation_id; finalize also lease_token/output, fail lease_token/error_code. Claim returns lease plus pinned attempt/leaf/problem/profile/extraction/criteria/sources/reference-solution context; it does not use a completed-result read as input. Finalize output remains strict `math-eval-v1` from MATH-2C: steps, edges, errors, causes, core, hints, references, paths, criteria, rubric, overall, provenance, progression and generated_solution, with selected extraction pin. See [foundation contract](../README.md).

Finalized result publication and canonical settlement are atomic. Worker never supplies account/quantity/price/refund. One initial plus one eligible same-lineage reevaluation before valid initial completion+336h; exact boundary expired. Vision/input/confirmation/hints have no separate charge. Failure releases an eligible reservation once; no automatic refund for settled work. error_code: TIMEOUT / INVALID_OUTPUT / PROCESSING_FAILED / ACCOUNT_ERASURE. Existing lifecycle restrictions take precedence at every privileged path.

## QLM and Human Quality

qlm_quality actions: list(limit?,before_at?,before_id?), detail(evaluation_id), submit_judgment(judgment), review_state(evaluation_ids array≤100), history(evaluation_id,limit?,before_at?,before_id?). List/history page size is clamped1–100, paired timestamp/UUID cursors required. Existing nested `qlm-read-v1`, `hq-math-read-v1`, `hq-math-write-v1` semantics remain unchanged. History's next_cursor is explicit; case list uses completed_at/evaluation_id of last shown case.

Judgment retains `dto_version=hq-math-write-v1`, math_evaluation_id, expected_output_sha256, client_submission_id, rubric_version=hq-math-rubric-v1, overall_disposition, rubric_result, findings, reference_context_reviewed, optional selection_reason/recommended_action/summary_note/supersedes_judgment_id. Reviewer derives from auth.uid(). Exact typed OVERALL/SOLUTION_STEP/ROOT_ERROR/EXTRACTION_REGION/ALTERNATIVE_PATH membership proofs, hash checks, append-only correction/idempotency, E1 and E2 are reused. This reviews AI quality, not student score. No Humanities ql-read-v1 or hq-read-v1 change.

## Physical relation mapping — no direct client DML

| Workflow fact | Canonical relation / relevant integrity |
|---|---|
| Submitted identity/version/lineage | math_attempts; global client_submission_id unique, immutable, owner/profile FK, typed predecessor/evaluation/step FKs |
| Evidence inventory | math_attempt_artifacts; unique(attempt_id,position), server-owned path, bytes-before-metadata guard |
| Candidate/confirmation | math_extraction_runs; typed predecessor same attempt; new unique confirmed predecessor index |
| Extraction regions | math_extraction_regions; composite run/attempt and artifact/attempt FKs, unique(run_id,reading_order) |
| Frozen input/output | math_evaluations; selected run/attempt FK, idempotency key, exact authority pins |
| Result graph | math_solution_steps, math_step_dependencies, math_errors, math_error_propagations, math_core |
| Delivery | math_hints / math_hint_exposures; immutable delivery facts |
| QA | human_quality_judgments / human_quality_findings; exclusive Essay/Math FK, correction single-successor |
| Economics | math_billing_bindings → essay_billing_decisions → credit_transactions; existing accounts/grants only |

No new table, role or direct browser DML is introduced. Extraction/evaluation worker capabilities remain split. Exact bounded six replaced functions and internal postgres EXECUTE delegation are recorded in [ownership.json](ownership.json); temporary SET/CREATE is restored within the transaction.

## Storage / R21

Owned namespace is math-private/{server subject}/{attempt}/raw/{artifact}; future render/crop/derived/generated namespaces need reviewed server registration. Browser cannot supply a bucket/path, set PRESENT or attest absence. Registration returns upload_available=false. Future trusted Storage admission verifies bytes against registered ownership; erasure inventories remain ERASURE_PENDING until supported Storage API delete/list confirms ABSENT_VERIFIED. Retry batches must keep metadata until absence is verified and reject late admission while lifecycle is pending/erasing. No arbitrary path deletion RPC, bucket, signed URL or cleanup worker is implemented here. Actual R21 Storage runtime remains NOT_ASSESSABLE / PRODUCTION_ACTIVATION_GATE.

## Validation and deployment boundary

[C01–C30](validation.json), [Math regression](regression.json), [legacy Humanities/HQP](legacy_validation.json), [ownership/failure/rollback](ownership_validation.json). Synthetic fixtures and local PG17 only. Max response2MiB (oversized response aborts transaction); input envelope300000 bytes, evaluation envelope600000, Quality65536, stricter nested limits still apply. Errors include42501 denial,22023 invalid/stale contract,23505 retry conflict,P0002 unavailable,54000 response bound; consumers must not interpret transport success as Human Quality approval.

Migrations apply in order: MATH-2C then this separate MATH-2D file. ADR-2 is not auto-applied; absent lifecycle authority fails closed. See [application notes](application.md). Production apply, worker credentials/deployment, Storage and Math activation remain separately authorized. No generated app client is deployed.
