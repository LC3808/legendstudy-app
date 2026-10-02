# math-learning-v1 — physical consumer handoff

MATH-5B/6B call Supabase `rpc('math_learning', {p_request: envelope})` with authenticated JWT. Do not write tables or call private helpers. No change to MATH-2D v1. [Owner/validation package](README.md).

```json
{"dto_version":"math-learning-v1","action":"read_learning_state","payload":{"evaluation_id":"<uuid>"}}
```

Success: `{dto_version:"math-learning-v1", action:<same>, result:<below>}`. Unknown version/action/key rejects. UUIDs are opaque canonical IDs. Timestamps are server UTC instants; JSON timestamp offsets may be `+00:00`. Null is unavailable/not recorded, never fabricated zero/correctness. Request ≤70,000 serialized bytes; response ≤2MiB. Client-generated submission UUID is fresh per intended mutation, retained across network retries. Recheck active owner before any replay/read; no client-supplied owner/free/price/completion authority.

## Actions and exact payload keys

| Action | Required | Optional |
|---|---|---|
| read_learning_state | evaluation_id UUID | none |
| reveal_hint | evaluation_id UUID, hint_id UUID, level integer 0/1/2, client_submission_id UUID | none |
| reveal_solution | evaluation_id UUID, target REFERENCE/GENERATED, client_submission_id UUID | solution_id UUID (required REFERENCE; omitted/null GENERATED) |
| create_resolve_attempt | client_submission_id UUID, leaf_id UUID, kind STEP_RETRY/FULL_RESOLVE/SHORT_ANSWER_RESOLVE, predecessor_id UUID, prior_evaluation_id UUID, input_kind TYPED/EVIDENCE/MIXED | typed_answer string (actual TYPED/MIXED work), target_step_id UUID (required STEP_RETRY, otherwise null/omit) |
| request_reevaluation | attempt_id UUID, client_submission_id UUID | none |
| read_learning_history | evaluation_id UUID | limit integer default20,1–50; before_at timestamptz and before_id UUID both together |

Use immutable exact leaf version and valid prior attempt/evaluation lineage from backend. Input submission validates existing C/D bounds (typed answer ≤30,000 characters); EVIDENCE/MIXED evidence registration and extraction confirmation/readiness continue through **math_input/math_extraction**, not this API. Creating an image attempt alone does not assert evaluation readiness. No PARTIAL_RESOLVE. SHORT_ANSWER_RESOLVE requires SHORT_ANSWER. FULL_RESOLVE is whole-leaf work (including short leaves); STEP_RETRY requires an actual same-prior-evaluation step. Client never supplies downstream correctness; runtime scope is TARGET_STEP / NOT_REASSESSED.

## read_learning_state result

- Identity: `evaluation_id, attempt_id, lineage_id, problem_id, leaf_id` UUID; `response_format` SHORT_ANSWER/SHORT_REASONING/FULL_SOLUTION/PROOF; `resolve_kind` INITIAL or launch resolve kind; `prior_attempt_id,prior_evaluation_id,target_step_id` nullable UUID.
- `submitted_scope`: TARGET_STEP or WHOLE_LEAF; `downstream`: NOT_REASSESSED for STEP_RETRY, otherwise null.
- `evaluation_state`: existing canonical state; `completed_at`: nullable timestamp; `valid_evaluation_available`: boolean (COMPLETED or historical INVALIDATED). INVALIDATED is historical, not eligible for new reveal/resolve. `review_status`: NOT_RECORDED, NOT_REQUIRED or HUMAN_REVIEW_REQUIRED from frozen MATH-4 facts. HRR is not processing failure.
- `core`: ordered array `{core_id,position,error_id,step_id,title,diagnosis,why,next_action}` from frozen evaluation; may be empty, no new CORE computation.
- `hints`: array `{hint_id,core_id,level,available,revealed,can_reveal}`. **No body**. `hint_availability`: NOT_APPLICABLE when CORE empty; UNAVAILABLE when no hints; otherwise FROM_FROZEN_HINTS. Only real stored levels exist. L0/L1 may be requested explicitly; L2 requires L1 delivery for the same CORE. L0 display is delivered through reveal, never preloaded hidden L1/L2.
- `solutions`: array `{solution_id:UUID|null,target:REFERENCE|GENERATED,provenance,physical_origin,reveal_state, revealed}`; body absent. `reveal_state`: AVAILABLE_ON_EXPLICIT_REQUEST or UNAVAILABLE. Empty array means no available reference. HYBRID does not require hints first.
- `resolve_kinds`: allowed kind array, empty unless COMPLETED; STEP_RETRY offered only when steps exist. This describes learning eligibility, not free-credit entitlement.
- `included_reevaluation`: projection below.
- `reevaluation_delta`: frozen progression object or null, detailed below.
- `reference_solution_revealed_before_resolve`: boolean derived from prior evaluation delivery timestamp ≤ attempt creation.
- `hint_levels_before_resolve`: distinct numeric array from prior evaluation delivered before attempt creation. No inference about reading/understanding/copying.

## reveal_hint result

`{hint_id:UUID,level:0|1|2,body:string}`. Success transaction authorizes and records server delivery via existing `math_hint_exposures(hint_id,client_key,delivered_at)`; evaluation/attempt/owner derive by typed FKs. Exact same key/hint returns same frozen body without a second exposure. Changed key payload conflicts; foreign/unavailable level denies. Exposure is server-authorized delivery, not proof the network rendered it or that the student understood it. No Credit or correctness changes. A new key is a new delivery operation; clients must reuse the same key for retries.

## reveal_solution result

`{exposure_id,evaluation_id,solution_id:UUID|null,target,delivered_at,provenance,physical_origin,body,learning_context:"REFERENCE_SOLUTION_REVEALED"}`.

| Physical source | provenance |
|---|---|
| considered canonical solution OFFICIAL | OFFICIAL_SOLUTION |
| considered canonical solution VERIFIED_INTERNAL | VERIFIED_INTERNAL_SOLUTION |
| considered canonical solution AI_PROPOSED | AI_GENERATED_REFERENCE |
| frozen evaluation generated_solution.origin AI_GENERATED | AI_GENERATED_REFERENCE |

REFERENCE must be in the immutable considered-reference set, never latest mutable source. GENERATED binds evaluation plus its canonical output hash; no copied answer/hash survives E1. Exact retry returns same event/time/body; changed source/evaluation under key conflicts. Early reveal is allowed. No automatic attempt, Credit, included-entitlement use, score adjustment or invalidation. Subsequent resolve context records timing only.

## Resolve and commercial requests

`create_resolve_attempt` returns `{attempt_id:UUID}`. Exact payload retry returns existing immutable attempt; changed payload conflicts. Submitted text may differ from previous work: same-lineage is canonical student/leaf/prior binding, not byte equality. Extraction confirmation and solution reveal do not create resolve attempts.

`request_reevaluation` returns `{evaluation_id:UUID,commercial_context:"INCLUDED_REEVALUATION",additional_credit:0}`. It is an **included-only** request. Server reuses existing Math request/account/financial locks, readiness and idempotency. Any normal paid fallback is rejected and the whole transaction rolls back. Do not automatically retry through the ordinary route after denial.

For later non-included evaluations, the separately explicit existing **math_input / math-input-v1 / request_evaluation** route remains the commercial authority. This runtime chooses no price/refund policy and creates no wallet. Consumers must separately present/authorize that ordinary request; a denied included request is not consent to debit.

Included projection shape:
`{status,eligible:boolean,included_count:1,initial_evaluation_id:UUID|null,expires_at:timestamp|null,as_of:timestamp,request_route:string}`.
Status: AVAILABLE, AUTHORIZED_PENDING, CONSUMED, EXPIRED, UNAVAILABLE. Only AVAILABLE is eligible. Deadline is initial valid canonical completion + exactly336hours; at deadline expired. Free-credit source has identical window. Reservation excludes simultaneous free requests; only settled valid completion consumes entitlement; timeout/malformed output/release does not. A valid HRR output may settle normally. The projection is advisory; the request locks and rechecks. `request_route` names included route when AVAILABLE, otherwise ordinary route **as a capability reference, not approval to charge**. Retries of an already accepted exact request reconcile the same evaluation even after projection changes; lifecycle checks still apply.

## read_learning_history result

`{lineage_id,attempts:[...],included_reevaluation:<above>,next_cursor:{created_at,attempt_id}|null}`.
Newest first, stable `(created_at,id)` descending. Feed next_cursor fields as before_at/before_id. Full last page may return a cursor followed by an empty terminating page. Each entry:
`{attempt_id,created_at,resolve_kind,prior_attempt_id,prior_evaluation_id,target_step_id,submitted_scope,evaluation_id,evaluation_state,completed_at,reevaluation_delta,core_ids:[UUID],exposed_hint_levels:[integer],solution_revealed:boolean,reference_solution_revealed_before_resolve:boolean}`.

One entry per immutable attempt, with its **latest evaluation summary** (requested_at,id descending), nullable if none. This is not an exhaustive list of every processing retry; prior evaluation links preserve immutable history. No typed answer, image body, permanent URL, worker lease, account/financial decision ID or Quality internals. Detail/evidence use existing authorized C/D surfaces, R21 availability remains gated.

## MATH-4 worker delta extension (not student-authored)

Existing finalize envelope and `math-eval-v1` remain. Optional `overall.review_status` is NOT_REQUIRED or HUMAN_REVIEW_REQUIRED; missing maps NOT_RECORDED. For noninitial outputs, existing progression `{prior_evaluation_id,target_step_id,downstream,summary}` can additionally include `delta` array≤20. Exact item keys: `kind,explanation` required; `prior_error_id,current_error_id` optional UUID. Explanation1–2000chars. Error references must belong to prior evaluation/current validated output respectively. Kind:
CORE_CORRECTED, ROOT_ERROR_REMOVED, ROOT_ERROR_REMAINS, PROPAGATED_ERROR_REMOVED, NEW_INDEPENDENT_ERROR, ANSWER_CHANGED, ANSWER_NOW_CORRECT, JUSTIFICATION_IMPROVED, NO_MATERIAL_CHANGE, PATH_VALIDITY_CHANGED.
No numeric score-difference authority. STEP_RETRY requires NOT_REASSESSED downstream. Old outputs remain interpretable; runtime only projects worker-authored facts.

## Error handling and security

SQLSTATE 42501: authentication/ownership-capability/lifecycle denial; P0002: missing or unowned resource (do not distinguish identities); 22023: shape/version/action/readiness/availability/lineage/expired-or-used included request; 23505: changed idempotency key collision; 22P02/22007/22008: malformed identifier/time; PT402: canonical ordinary credit availability rejected before included fallback; 54000: response bound. Do not parse raw database error detail into UI or log user payloads. Refresh safe state on stale availability; never retry a mutation with a new key after an ambiguous network result.

PENDING/ERASING denies reads and new writes/replays through shared lifecycle gate. Ownership is auth.uid, never payload. Direct table CRUD/private helper EXECUTE denied. Workers alone finalize; ordinary student cannot supply completion/review authority. Backend function installation is not Production gateway proof. R21 and trusted runtime/ADR-2 erasure activation remain external gates.
