# MATH-2C — Canonical Math persistence implementation

Status: **IMPLEMENTED / ISOLATED_VERIFIED; Production NOT_APPLIED**. Owner migration review is next. Math AI, Storage, worker deployment and real-student execution remain inactive.

## Authority and scope

Implements the accepted [MATH-2R shared contract](math-essay-shared-integration-contract.md) and [MATH-2B review](math-essay-canonical-db-security-review.md). Earlier reviews remain historical design evidence. Shared spine plus Math-specific persistence reuses universities, essay_exams, Auth, Credit Ledger and Human Quality; no second identity, wallet or QA system.

Canonical migration: [20261002000100_math_essay_persistence.sql](../supabase/migrations/20261002000100_math_essay_persistence.sql).
SHA-256: `73fae66a4a9198885c6bf505ac87d9a3abcc453dd1017e666a217bac486c7d51`.

[Owner package](../supabase/verification/math_essay/README.md) contains exact object/security inventory, preflight/postflight, bounded rollback, hash history and [R01–R24 evidence](../supabase/verification/math_essay/acceptance.md).

## Implemented contract

27 Math tables cover immutable content/version authority, leaf response format, profile resolution, sources/criteria/reference solutions, private attempts/evidence/extraction, evaluated relational graphs, hints/exposures and typed billing binding. 39 new functions and two bounded legacy HQ replacements are enumerated in the [ownership manifest](../supabase/verification/math_essay/ownership_inventory.json).

- SHORT_ANSWER, SHORT_REASONING, FULL_SOLUTION and PROOF are persisted; MIXED is derived. Singleton leaves remove nullable evaluation authority. Short answers and empty CORE do not require invented reasoning/error rows.
- Immutable attempts distinguish INITIAL, SHORT_ANSWER_RESOLVE, FULL_RESOLVE and STEP_RETRY. STEP_RETRY preserves downstream NOT_REASSESSED. Extraction confirmation and solution/hint exposure are not re-solve.
- Profiles resolve leaf > problem > exam context > explicit common fallback; equal-rank ambiguity fails closed. Version pins preserve historical sources, extraction, criteria and solution authority.
- Atomic finalize validates selected extraction, steps, logical DAG, causal errors, ordered CORE, hints, considered paths and student rubric before graph publication and settlement. Invalid output, expired lease and stale fence fail closed. Canonical output hashes exclude temporary URLs/provider payload/polling state.
- HQ-A retains Essay evaluation_id and adds an exclusive Math FK. Typed supersession stays within domain/evaluation; independent roots remain. Math rubric/finding targets are strictly dispatched. MATH-7 reviews AI quality, not student score. E1 cascades by evaluation; E2 removes reviewer linkage on surviving reviews.
- Legacy ql-read-v1 remains unchanged. Legacy HQ history uses explicit existing fields, preventing new Math columns from leaking. Essay submit only adds foreign-domain idempotency-key denial; Essay wire/hash/validation behavior is preserved.
- Existing Credit economic authority is reused. A fresh Math decision/binding/reservation is atomic; one initial plus one eligible same-lineage reevaluation uses one Credit before initial valid completion +336 hours. No Vision or hint charge. Release is idempotent; settled consumption is not automatically refunded by deletion. No Commerce-page price/refund policy is embedded.

## Security and ownership

All new tables have RLS enabled; PUBLIC/anon/authenticated/service_role have no direct table privileges. Authenticated users receive bounded student RPCs and operator-gated Math Quality RPCs. Extraction and evaluation workers receive only their respective function EXECUTE capabilities. No worker inherits math_executor; no browser service-role path exists.

Definers use empty search_path and qualified relations. Exact approved bootstrap initializes 17 math_executor and four essay_executor functions with transaction-local SET/schema CREATE, then restores privileges. Three platform-created postgres memberships remain ADMIN=true / INHERIT=false / SET=false, as explicitly accepted by Owner. New roles are NOLOGIN/NOBYPASSRLS/NOSUPERUSER/NOCREATEDB/NOCREATEROLE. No unexpected membership, temporary SET or schema CREATE remains.

## Executed isolated validation

Final migration bytes passed PostgreSQL17 full installation as Production-equivalent **non-superuser postgres**, including platform ownership/membership/ACL topology. Auth role/claim fixtures are synthetic; this is not Production JWT verification.

| Suite | Executed result |
|---|---|
| Math behavioral/security/graph/finance/HQ | 131 named checks PASS |
| Existing HQP/Humanities assertions after Math | 102 PASS |
| Installation/topology/failure/rollback | 14 named checks PASS |
| R01–R20, R22–R24 | PASS with individual evidence |
| R21 actual Storage API cleanup | NOT_ASSESSABLE; metadata guards PASS |

Failure injection covers bootstrap SET/CREATE/role/owner boundaries and later migration rollback, graph validation and financial posting. Real isolated concurrent requests/finalize/reconcile/HQ/financial paths exercise posting-once, fences and lock ordering. Empty-install rollback restores legacy definitions/security and rejects data or unexpected dependencies; it is not authorization to remove real obligations.

## Production snapshot and activation gates

2026-10-02 read-only catalog snapshot: ledger23, no Math collision; HQP/Quality tracked, ADR-2 absent, provider005 unapplied, day_targets tracking separate. This task performed **zero Production writes and zero provider calls**. No remote ledger, Edge, scheduler, Storage bucket, Flutter or LAB changes.

Schema installs inactive without ADR-2; personal Math paths fail closed until lifecycle authority exists. Activation still requires separately approved ADR-2 Math reservation release/graph cleanup integration, private Storage namespace/admission/byte cleanup, trusted worker admission and actual JWT verification. ADR-2 is not applied automatically.

R21 cannot certify list/delete timeout, late-upload or resumable Storage API behavior because this foundation exposes metadata only (`upload_available=false`). Metadata remains until ABSENT_VERIFIED; isolated Auth-last/E1/E2 tests pass. Do not interpret those tests as a deployed Math erasure worker. Ordinary evidence retention duration remains deferred, finite and erasable by policy.

Future solution reveal must use a separately reviewed bounded delivery writer. No actual Math feature, provider, content publishing or student-data activation is authorized by this package.

## Next gate

Owner/ChatGPT review → Owner migration review → separate Production apply authorization. Keep Production apply readiness **NO** until those gates are explicitly satisfied.
