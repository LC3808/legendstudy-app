# MATH-2E — Learning runtime / consumer handoff

2026-10-02: implemented and isolated verified; **Production NOT_APPLIED**. Base MATH-2D is unchanged. [Owner package](../supabase/verification/math_essay/learning/README.md), [exact consumer contract](../supabase/verification/math_essay/learning/contract.md), [L01–L40 evidence](../supabase/verification/math_essay/learning/validation.json).

`math_learning(p_request jsonb)` / `math-learning-v1` provides read_learning_state, reveal_hint, reveal_solution, create_resolve_attempt, request_reevaluation and read_learning_history. MATH-5B/6B can bind without direct table writes, client-computed eligibility or hidden hint preloading. No LAB/UI implementation here.

## Authority and behavior

MATH-4 remains evaluation/correctness authority; MATH-5 owns CORE/hint/reveal semantics; MATH-6 owns immutable resolve/delta interpretation; MATH-7 reviews AI quality. Runtime projects/enforces frozen facts, never generates hints, recomputes CORE or alters old evaluations.

- Actual L0–L2 availability only. L2 requires delivered L1 for the same CORE. Hint bodies delivered only by authorized reveal; exposure records delivery, not cognition.
- HYBRID early reference reveal preserves OFFICIAL / VERIFIED_INTERNAL / AI reference provenance. It creates no attempt and charges no Credit. Reference/generated bindings erase with evaluation; no detached hash archive.
- STEP_RETRY / FULL_RESOLVE / SHORT_ANSWER_RESOLVE create new immutable submitted work. STEP_RETRY requires a prior step and preserves downstream NOT_REASSESSED. Extraction confirmation and solution viewing are not resolves; same-lineage does not require identical answer bytes.
- One included reevaluation uses existing account/Math billing authority. Deadline is valid initial server completion +336h, exact boundary expired for paid and signup Credits alike. Reservation prevents concurrent double-free authorization; failed processing releases it; valid completion consumes it, including an explicitly valid HUMAN_REVIEW_REQUIRED output.
- Learning request is included-only: paid fallback rolls back, never silently charges. Later non-included work uses the separately explicit existing math_input request route. No Commerce pricing/refund policy is added.
- Optional MATH-4 review_status/delta are strictly validated, not inferred. History is bounded immutable attempt order with latest evaluation summary per attempt and prior-evaluation links; not an exhaustive processing-retry log. No answer bodies or finance/Quality internals in list DTO.

## Security, preservation and limits

Lifecycle restriction precedes every call/replay. Student authority derives from authenticated subject; direct private CRUD denied. Public RPC is postgres-owned DEFINER with authenticated EXECUTE and empty search_path; two internal INVOKER projections are postgres-only. Existing math_executor validator owner/ACL preserved using the already approved temporary bootstrap, restored before commit. No new role, permanent SET/INHERIT or finance helper change.

Preservation review: (1) canonical university/exam identity reused; (2) student ownership/foreign reads denied; (3) Humanities and ql-read-v1/hq-read-v1 unchanged; (4) one existing Credit Ledger/no second wallet; (5) E1 cascade and E2 reviewer semantics retained; (6) public guest content unaffected; (7) lifecycle/Storage activation still gated, no Production claim. MATH-2C/D hashes unchanged.

## Validation and next gate

Actual isolated PG17: L01–L40 plus additional rejection, free-credit parity, E1/delta/rollback tests; concurrent hint/solution retries, resolve retries, included entitlement and lifecycle races; injected insert/billing failures roll back. Existing131 Math + C01–C30 +102 Humanities/HQP rerun. Non-superuser C14/D8/E10 install/topology/failure/rollback checks pass. Exact evidence and function allowlist are linked in the Owner package. Synthetic auth roles/claims do not prove live JWT/provider behavior.

Migration `20261002000300_math_learning_runtime.sql` and SHA file are canonical application artifacts, not deployed state. R21 remains **PRODUCTION_ACTIVATION_GATE**; Storage runtime, trusted worker gateway/deployment and ADR-2 Math erasure/cleanup integration are not fabricated as complete. No Production writes, providers, scheduler, Edge deploy, secret provisioning or LAB changes.

Next: Owner/ChatGPT review → Claude MATH-5B physical binding → MATH-6B consumer implementation → separately governed model bake-off. No phase starts automatically.
