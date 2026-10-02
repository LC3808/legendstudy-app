# MATH-2C ownership-sensitive audit

Owner authorizations #1–#3. Static pre-implementation inventory, not migration or behavior PASS.

## Complete function allowlist

All functions use empty `search_path`. EXECUTE lists include the owner. PUBLIC, anon and service_role receive none. Existing owner/ACL/security/config remain unchanged. Any additional function requires inventory reconciliation before bridge execution; another owner/privilege category triggers Owner STOP.

### math_executor

| Exact signature | Mode | EXECUTE roles | Change |
|---|---|---|---|
| `public.math_submit_attempt(jsonb)` | DEFINER | math_executor, authenticated | new |
| `public.math_register_artifact(uuid,jsonb)` | DEFINER | math_executor, authenticated | new |
| `public.math_confirm_extraction(uuid,uuid,jsonb)` | DEFINER | math_executor, authenticated | new |
| `public.math_request_evaluation(uuid,uuid)` | DEFINER | math_executor, authenticated | new |
| `public.math_attempt_detail(uuid)` | DEFINER | math_executor, authenticated | new |
| `public.math_evaluation_detail(uuid)` | DEFINER | math_executor, authenticated | new |
| `public.math_reveal_hint(uuid,uuid)` | DEFINER | math_executor, authenticated | new |
| `public.math_claim_extraction(uuid)` | DEFINER | math_executor, math_extraction_worker | new |
| `public.math_finalize_extraction(uuid,uuid,jsonb)` | DEFINER | math_executor, math_extraction_worker | new |
| `public.math_fail_extraction(uuid,uuid,text)` | DEFINER | math_executor, math_extraction_worker | new |
| `public.math_claim_evaluation(uuid)` | DEFINER | math_executor, math_evaluation_worker | new |
| `public.math_finalize_evaluation(uuid,uuid,jsonb)` | DEFINER | math_executor, math_evaluation_worker | new |
| `public.math_fail_evaluation(uuid,uuid,text)` | DEFINER | math_executor, math_evaluation_worker | new |
| `math_private.resolve_profile(uuid)` | DEFINER | math_executor | new |
| `math_private.lock_evaluation(uuid)` | DEFINER | math_executor | new |
| `math_private.evaluation_projection(uuid,boolean)` | DEFINER | math_executor, postgres | new |
| `math_private.validate_output(uuid,jsonb)` | DEFINER | math_executor | new |

### essay_executor

| Exact signature | Mode | EXECUTE roles | Change |
|---|---|---|---|
| `math_private.authorize_billing(uuid)` | DEFINER | essay_executor, math_executor | new |
| `math_private.settle_billing(uuid)` | DEFINER | essay_executor, math_executor | new |
| `math_private.release_billing(uuid)` | DEFINER | essay_executor, math_executor | new |
| `math_private.lock_account_attempt(uuid)` | DEFINER | essay_executor, math_executor | new |

### postgres

| Exact signature | Mode | EXECUTE roles | Change |
|---|---|---|---|
| `math_private.current_subject()` | DEFINER | postgres, math_executor | new |
| `math_private.require_active(uuid[])` | DEFINER | postgres, math_executor, essay_executor | new |
| `math_private.content_immutable()` | INVOKER | postgres | new |
| `math_private.personal_immutable()` | INVOKER | postgres | new |
| `math_private.artifact_guard()` | DEFINER | postgres | new |
| `math_private.binding_guard()` | DEFINER | postgres | new |
| `math_private.activate_profile(uuid)` | DEFINER | postgres | new |
| `math_private.hq_parent_guard()` | DEFINER | postgres | new |
| `math_private.hq_finding_guard()` | DEFINER | postgres | new |
| `math_private.hq_rubric_valid(jsonb)` | INVOKER | postgres | new |
| `math_private.hq_finding_valid(jsonb)` | INVOKER | postgres | new |
| `math_private.hq_validate_context(uuid,jsonb,jsonb)` | DEFINER | postgres | new |
| `math_private.hq_require_operator(uuid)` | DEFINER | postgres | new |
| `public.qlm_submit_human_judgment(jsonb)` | DEFINER | postgres, authenticated | new |
| `public.qlm_review_state(uuid[])` | DEFINER | postgres, authenticated | new |
| `public.qlm_list_human_judgments(uuid,integer,timestamp with time zone,uuid)` | DEFINER | postgres, authenticated | new |
| `public.qlm_list_cases(integer,timestamp with time zone,uuid)` | DEFINER | postgres, authenticated | new |
| `public.qlm_case_detail(uuid)` | DEFINER | postgres, authenticated | new |
| `public.ql_submit_human_judgment(jsonb)` | DEFINER | postgres, authenticated | replace bounded body |
| `public.ql_list_human_judgments(uuid,integer,timestamp with time zone,uuid)` | DEFINER | postgres, authenticated | replace bounded body |

## Temporary ownership bootstrap

- math_executor: temporary SET plus CREATE on exactly public and math_private.
- essay_executor: temporary SET plus CREATE on exactly math_private; no CREATE on essay_private.
- postgres: no ownership bridge. No fourth owner.
- Capture memberships/options/grantor and schema ACL after intended new-role/runtime USAGE setup, before bootstrap. Restore the temporary changes exactly. Check existing-schema ACL deltas against only explicitly listed new-role USAGE.
- New functions are created under their final owner; no existing financial ownership transfer. No wildcard ownership or function grants.
- Owner #3 accepts only postgres ADMIN=true/INHERIT=false/SET=false, grantor supabase_admin, on each of math_executor, math_extraction_worker, math_evaluation_worker. These three management memberships remain; temporary self-granted SET edges do not.
- New roles: NOLOGIN, NOBYPASSRLS, NOSUPERUSER, NOCREATEDB, NOCREATEROLE, NOREPLICATION. No browser or worker membership in an executor.

## Runtime capability and RLS plan

- math_extraction_worker: EXECUTE only claim/finalize/fail extraction signatures above; no table rights, evaluation, finance, content or HQ authority.
- math_evaluation_worker: EXECUTE only claim/finalize/fail evaluation signatures above; no table rights, extraction mutation or direct financial calls.
- math_executor: explicit SELECT on new content tables; only required SELECT/INSERT/UPDATE on new personal Math tables. RLS policies scoped to this role on those new tables; no global BYPASSRLS. No DELETE/ TRUNCATE/REFERENCES/TRIGGER/MAINTAIN grant.
- essay_executor: explicit new Math reads and evaluation/binding operations needed by finance helpers. Existing Credit/Essay table ACL and policies remain unchanged. Existing executor BYPASSRLS is not expanded to another role.
- postgres owns new relations, private content/HQ guards and gated Math HQ RPCs. Content activation has no client EXECUTE.
- Existing Credit locks/postings remain inside essay_executor-owned helpers. Math executor obtains no new direct Credit table access.
- auth.uid and lifecycle access use bounded postgres-owned helpers, not new Auth grants. Lifecycle helper fails closed when ADR-2 prerequisites are absent; Math activation requires the separately reviewed deletion/Storage integration.

## Existing function preservation

Only ql_submit_human_judgment(jsonb) and ql_list_human_judgments(uuid,integer,timestamptz,uuid) body edits are planned. Both retain postgres owner, SECURITY DEFINER, empty search_path and exact postgres/authenticated EXECUTE. Submit stays VOLATILE; history stays STABLE; both PARALLEL UNSAFE. No ql-read-v1 function changes, no Essay finance replacements. Historical HQ validators, immutable guard and projection are unchanged.

## Seven preservation questions

1. Immutable submitted attempts, version pins, extraction confirmation and completed output record historical facts; mutable lease status is separate.
2. Exact profile/source/solution/extraction FKs preserve historical interpretation.
3. Corrections insert new attempts/judgments; no historical backfill.
4. Existing auth.users/profile/university/exam authority is reused.
5. Math learning/evaluation and Human Quality remain distinct from financial decisions and admission outcomes.
6. Student operational graph is private and erasable; byte obligations precede metadata removal; no analytics copy.
7. CORE/profile resolution/review state are derived or explicitly bound judgments, not invented raw student facts.

## Historical pre-implementation gates (superseded below)

Production-equivalent whole-migration apply, A–F failure injection, exact restoration, R01–R24, Humanities regression, empty-install rollback, final hash and Owner apply package have NOT RUN. This document authorizes no Production action.


## Ownership-only verification result

`tool/test_math_ownership_bootstrap.py` loaded 15 actual canonical prerequisite migrations
in disposable PostgreSQL 17, then demoted the migration login to NOSUPERUSER/CREATEROLE.
The 39 new signatures used explicitly inert typed bodies, never business implementations.
17 named checks PASS: successful fixture restoration; 13 injected-failure checkpoints;
committed ADMIN-only topology; unexpected dependency rejection; committed empty-fixture rollback.
Before/after fingerprints cover existing functions, owners, ACL, security/config, relations,
constraints and policies. Final temporary SET/CREATE absent; worker/executor inheritance absent.
See `ownership_bootstrap_validation.json`. This is NOT full Math migration validation,
NOT R01–R24, NOT Humanities behavioral regression and NOT the Owner apply package.
No additional privilege bridge was found necessary by this ownership fixture.

At that ownership-only checkpoint, implementation remained incomplete and no migration existed. No commit/push or Unified
Wiki completion update is appropriate until the complete implementation and acceptance gates pass.

## Full implementation successor — 2026-10-02

The historical ownership-only fixture above is now superseded by the actual migration and
[Owner package](README.md). Full non-superuser installation, 11 transaction failure injections,
final owner/ACL/config/membership checks, unexpected dependency refusal and empty-install
rollback passed (14 named installation checks). Existing legacy behavior passed 102 assertions;
Math behavior passed 131 named assertions. Exact counts/hash are in validation.json.
All approved function signatures remain within the original 41-entry inventory. No new privilege
category, fourth role, permanent SET/CREATE or worker/executor membership was introduced.
Production NOT_APPLIED; actual Math Storage runtime remains an explicit activation gate.
