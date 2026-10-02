# MATH-2C Owner application package

**Canonical DB foundation implemented and isolated verified. Production NOT_APPLIED.**
Do not enable Math, deploy workers/Storage, replay pending migrations or repair a ledger from this package.

Migration: [`20261002000100_math_essay_persistence.sql`](../../migrations/20261002000100_math_essay_persistence.sql)
SHA-256: `73fae66a4a9198885c6bf505ac87d9a3abcc453dd1017e666a217bac486c7d51`
Owner apply review is the next gate; Production application is not authorized by this closeout.

## Evidence and limits

- PostgreSQL17, actual canonical Essay/Credit/Quality/HQP migrations. Installation and rollback execute as **NOSUPERUSER postgres**, CREATEROLE/BYPASSRLS matching the inspected platform topology. New Math roles never receive BYPASSRLS.
- 131 named Math behavioral checks; 102 unchanged legacy HQP/Humanities behavioral assertions; 14 whole-migration ownership/failure/rollback checks. Auth users/roles/claims are synthetic shims, not actual JWT gateway proof.
- [R01–R24 exact matrix](acceptance.md), [machine results](validation.json), [installation catalog](installation_validation.json), [behavior](behavior_validation.json), [legacy](legacy_validation.json).
- R21 **NOT_ASSESSABLE** for actual Math Storage API/list/delete/late-upload cleanup. Metadata/path/absence guards passed. Storage deployment and the ADR-2 Math erasure hook are separate mandatory activation gates; neither is falsely reported complete.
- No model/provider calls, real student fixtures, Production DML/DDL/ledger changes, Edge deploy or Storage bucket creation.

## Prerequisites and current remote snapshot

[Read-only catalog snapshot](production_preflight.json): 23 tracked migrations on 2026-10-02; no Math collisions. HQP `20261001000200` and Quality `20261001000100` tracked. ADR-2 `20261001000300` absent. Provider005 remains unapplied; day_targets tracking remains separately absent. Freshly repeat catalog/ledger checks immediately before any Owner application; this is a dated snapshot, not a permanent remote-state assertion.

Required existing objects: universities, essay_exams, resources, profiles, canonical Essay/Credit tables and guards, Quality allowlist/helper, HQP tables/validators/projection; exact canonical chain is loaded by the isolated tests. Existing Essay economic function bodies/owners/ACLs remain unchanged. No unrelated migration is a hidden installation dependency.

Schema installation **can be inactive without ADR-2**: tested non-superuser installation on the pre-ADR2 chain. All personal Math execution uses a fail-closed lifecycle helper. Math activation additionally requires corrected ADR-2 installed/verified **and** its reviewed Math prepare/release → Storage bytes → Math graph → Auth-last integration. Do not apply ADR-2 automatically.

## Objects and security

27 new public Math tables, grouped below. No university/Auth/wallet/financial ledger duplicate.

- Content: math_problem_sets, math_problems, math_subproblems, math_source_artifacts, math_evaluation_profiles, math_scoring_criteria, math_canonical_solutions, math_canonical_solution_steps.
- Personal: math_attempts, math_attempt_artifacts, math_extraction_runs, math_extraction_regions, math_evaluations, math_solution_steps, math_step_regions, math_step_dependencies, math_errors, math_error_propagations, math_core, math_hints, math_hint_exposures, math_considered_references, math_evaluated_paths, math_evaluation_sources, math_evaluation_criteria, math_solution_exposures.
- Financial binding: math_billing_bindings, pointing to existing essay_billing_decisions/credit_accounts, never a second balance.
- HQ-A: retain Essay evaluation_id/FK/CASCADE, add Math FK/CASCADE and exclusive binding; shared rubric/finding dispatch, parent/target guards. Original E2 reviewer SET NULL remains.
- Existing functions changed only: ql_submit_human_judgment's foreign-domain retry-key rejection; ql_list_human_judgments' explicit legacy serialization. Owner, ACL, security, volatility/search_path preserved. ql-read-v1 and legacy HQ wire fixtures preserved.
- 39 new functions, exact signatures/owners/EXECUTE: [ownership_inventory.json](ownership_inventory.json). 17 math_executor, four essay_executor private finance functions, 18 postgres helpers/QLM RPCs. No extra owner bridge.

| Role | New table direct privileges | New function EXECUTE |
|---|---|---|
| PUBLIC / anon / service_role | NONE | NONE |
| authenticated | NONE | Own Math submit/metadata/confirm/request/detail/hint; operator-gated QLM only |
| math_extraction_worker | NONE | extraction claim/finalize/fail only |
| math_evaluation_worker | NONE | evaluation claim/finalize/fail only |
| math_executor | scoped SELECT on content; SELECT/INSERT/UPDATE on new personal tables | Exact inventoried functions; no finance-table grants |
| essay_executor | SELECT/UPDATE on Math attempts/evaluations/bindings; INSERT binding | Four private Math finance helpers; existing economics unchanged |

All new tables postgres-owned, RLS ON; policies target only math_executor. SECURITY DEFINER only as inventoried, empty search_path throughout. No new runtime role membership or browser service role. Privileged content publication remains Owner-controlled; Quality membership does not publish content.

Temporary bootstrap: exact functions only, SET postgres→math_executor/essay_executor; CREATE math_executor→public/math_private and essay_executor→math_private. Reset/revoke in the same transaction. Final three automatically created postgres ADMIN-only memberships (grantor supabase_admin) are accepted: ADMIN=true, INHERIT=false, SET=false. Migration pre/postflight refuses drift. No permanent SET/CREATE expansion.

Indexes: 68 total on new Math tables plus Math HQ history, including PK/UNIQUE/composite-FK integrity indexes. [Exact definitions](installation_validation.json). Non-integrity launch indexes are student/lineage attempt traversal, evaluation-by-attempt/case cursor, and Math HQ history. Profile active-scope unique index is NULLS NOT DISTINCT. No analytics/reporting indexes. POST_LAUNCH: only measured-query-driven additions.

## Owner execution sequence — do not execute as part of MATH-2C

1. Freeze reviewed commit and verify SHA-256 above. Inspect `catalog.sql`, remote ledger, ownership/ACL, collision absence and unrelated pending versions. STOP on drift, collisions or an unapproved privilege need.
2. Preserve the pre-install function/catalog output and **installation-time financial counts** below in the Owner's private execution record. They are conservative rollback safety inputs; never recompute them to bypass a later rollback refusal.
3. In a reviewed postgres SQL session, apply **only this exact migration file**, including its transaction. No broad db push/migration-up. On any exception stop; PostgreSQL must roll back the whole transaction.
4. Run `postflight.sql`: exact owners/ACL/RLS, helpers, constraints, final membership/options, no temporary CREATE/SET, empty new Math tables. Verify legacy ql/HQ fixtures/security against the saved baseline. STOP on any mismatch; do not activate.
5. Owner records **only** version `20261002000100` using the approved narrow tracking procedure for this repository, after exact SQL success. Do not manually insert ledger rows, replay provider005/day_targets/ADR2 or perform unrelated repair. Verify version/hash and actual ledger delta independently.
6. Keep all Math worker/client/Storage/provider activation OFF. Separately review ADR-2 Math hook, private namespace/byte cleanup, publisher/reference verification, trusted worker admission and production JWT authorization. No live Math evaluation in this package.

Installation-time counts (Owner read-only execution, no student content):

```sql
select jsonb_build_array(
 (select count(*) from public.credit_accounts),
 (select count(*) from public.credit_grants),
 (select count(*) from public.credit_transactions),
 (select count(*) from public.essay_billing_decisions)) as installation_credit_counts;
```

## Rollback and abort

`rollback.sql` is **empty-install only**, tested as non-superuser. It refuses any Math content/personal/binding/HQ data, refuses changed financial counts, and uses no DROP CASCADE. Unexpected dependencies abort the transaction. Restore exact two legacy definitions/checks/FK nullability and owners/ACL, then drop only known Math objects/roles. Constraint OIDs may be recreated; restored definitions/security are compared.

Before separately authorized rollback, set session `math.rollback_credit_counts` to the saved **pre-install** JSON array, then run rollback.sql in the same session. Missing/different counts intentionally refuse rollback. Do not reset counts to current values. Real Math use or later financial activity normally requires forward correction/Owner review, not destructive rollback. Ledger handling is a separate Owner action, never automatic rollback SQL.

## Semantics and activation gates

Immutable versions/leaf authority; four persisted response formats, MIXED derived only. Four immutable attempt kinds. Confirming extraction or revealing a hint/solution is not re-solve. STEP_RETRY preserves downstream NOT_REASSESSED. Ordered CORE can be empty; no synthetic score/official points. MATH-4 evaluation rubric differs from MATH-7 human QA rubric.

One existing Credit unit funds an initial evaluation and one eligible same-lineage reevaluation before valid initial completion + **336 hours**; exact expiry is excluded. Vision/confirmation/hints consume no separate Credit. Request+binding+reserve and graph+settlement are atomic; stale/invalid output fails closed, timeout release is once, deletion does not refund settled consumption. No Commerce pricing/refund policy is hardcoded.

Actual current input admission exposes metadata only (`upload_available=false`). Only future trusted Storage admission may establish PRESENT; erasure metadata cannot disappear before ABSENT_VERIFIED. Source reference+hash is metadata, not official-byte Storage. Official content is retained when personal graph erases. Future solution-reveal consumer must record actual delivery through a separately reviewed bounded writer; no page-load learning progress is inferred.

## Reproduce locally

Requires PostgreSQL17 binaries and psycopg3 in an external Python environment. Each runner creates a fresh Unix-socket-only throwaway cluster; no Production DSN accepted.

```sh
python tool/test_math_installation.py --pg-bin /path/to/postgresql17/bin
python tool/test_math_persistence.py --pg-bin /path/to/postgresql17/bin
python tool/test_math_legacy.py --pg-bin /path/to/postgresql17/bin
python3 tool/check_wiki_handoff.py
```

No Flutter, LAB, provider, Cloudflare, scheduler or unrelated migration implementation changed.
