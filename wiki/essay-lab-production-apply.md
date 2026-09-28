# Essay LAB Production apply — APPLIED_WITH_BLOCKER

2026-09-28. Owner explicitly authorized exactly the three promoted Product migrations at
`fbe4783`. **Migration execution PASS; post-apply validation FAIL; security contract CHANGE_REQUIRED.**
The schema exists, but Product/student writes remain NOT_ENABLED. No further Production mutation is authorized
by this completed task. No automatic repair, retry, rollback or correction was performed.

## Applied scope and preflight

Linked LegendStudy Production identity verified. Remote baseline contained exactly13 approved versions;
only the three Product versions were pending. All16 repository migration files were byte-identical to the
approved commit. Canonical counts/fingerprints matched the accepted baseline. All19 target tables,
28 function names and private schema were absent; prerequisite/catalog checks passed.
Fresh `supabase db push --linked --skip-vault --dry-run` showed exactly the three files, no seeds/role bundle.
Then **one** `supabase db push --linked --skip-vault` completed successfully:

- 20260928000100_student_essay_product.sql
- 20260928000200_essay_entitlements.sql
- 20260928000300_essay_server_operations.sql

No include-all/include-seed/include-roles, old SQL replay, Owner SQL Editor, student seed or provider call.
The migrations themselves create the approved narrow roles; no separate CLI role bundle or credentials deployed.
Actual history readback and migration list show16 local/remote matches, no pending/unexpected migrations.

## Read-only post-apply results

[Sanitized actual catalog/result](../supabase/validation/essay_lab_product/production_apply_result.json).
Prepared READ ONLY/ROLLBACK inspection SQL was used, plus one narrowly scoped membership-options/orphan query.
Only catalog/aggregate results were retained; no student rows, personal identifiers, secrets or DSNs.

| Contract | Actual result |
|---|---|
| New tables / additive columns / operation RPCs |19 /4 /12 |
| Full definition fingerprints |47/47 match:19 tables +28 functions |
| FK / UNIQUE / CHECK / indexes / triggers / policies |PASS, matching definition fingerprints |
| RLS |All19 enabled |
| New rows |All19 tables empty; total0 |
| New FK orphans / canonical orphans |0 /0 |
| Function signatures / ownership / fixed search_path |PASS |
|12 operation RPC EXECUTE allowlist |PASS |
| Client direct fact/result/ledger writes |DENIED at catalog/grant boundary |
| Worker/finance direct table access |DENIED |
| Executor temporary schema CREATE |Revoked on public and essay_private |
| Helper EXECUTE allowlist |FAIL:9 unexpected service_role privileges |
| Membership contract |FAIL:3 unexpected ADMIN-only postgres memberships |

Authenticated direct writes to mutable drafts/target universities remain the approved exceptions.
No fresh Production JWT/negative-write fixture test was performed; prior disposable/JWT evidence is historical.

## Exact blockers — no automatic correction

**B1: helper EXECUTE permissions.** service_role retains EXECUTE on nine public trigger helpers:
`essay_product_reject_update`, `essay_product_terminal_guard`, `essay_product_child_guard`,
`essay_question_identity_guard`, `essay_product_progress_guard`, `essay_product_processing_guard`,
`essay_product_draft_guard`, `essay_credit_account_guard`, `essay_billing_history_guard`.
All are postgres-owned, invoker-security trigger functions with fixed empty search_path; their definitions
match the promoted contract. This is a privilege mismatch, not evidence of a successful arbitrary trigger
invocation or a broken client RPC boundary. All12 operation RPC grants match. A reviewed forward correction
should explicitly revoke unintended helper EXECUTE grants from service_role; do not edit applied migrations.

**B2: bootstrap membership expectation.** Three memberships remain: postgres is a member of
essay_executor, essay_worker and essay_finance. All three have grantor=supabase_admin,
ADMIN=true, INHERIT=false, SET=false. Therefore this does not show runtime inheritance/SET ROLE access;
it does retain role-administration authority and violates the prepared zero-membership expectation.
The migration's temporary CREATE privileges are revoked. These grantor/options differ from a simple
inheritable bootstrap membership. Review managed-role creation/administration semantics before choosing
a grantor-aware forward correction or explicitly revising the accepted administrative boundary.
Do not blindly revoke/CASCADE platform-managed memberships. No such change was made.

The cause of the managed grantor entries was not asserted from catalog alone. Exact observations are saved.
Because the acceptance contract has not passed, **PRODUCT_SCHEMA_STATUS=APPLIED_WITH_BLOCKER**.
Applied migration history is left intact; no repair, repeat push, DROP/TRUNCATE or rollback.

## Canonical preservation

| Relation | Before | After | Fingerprint |
|---|---:|---:|---|
| universities |5|5|UNCHANGED|
| essay_exams |21|21|UNCHANGED|
| essay_exam_resources |134|134|UNCHANGED|
| resources |10556|10556|UNCHANGED|

Existing Pilot/evidence mappings were not changed. Production mutation was limited to authorized migration
schema, roles/grants and migration history. Canonical/student data mutation:NO.

## Deployment versus activation

MIGRATION_BASELINE:ADOPTED. PRODUCT_MIGRATIONS:APPLIED. PRODUCT_SCHEMA:APPLIED_WITH_BLOCKER.
STUDENT_DATA:NOT_ENABLED. AI_PROVIDER:NOT_ENABLED. WORKER:NOT_DEPLOYED. UI:NOT_CONNECTED.
READY_FOR_PRODUCT_IMPLEMENTATION:NO pending security-contract resolution.
READY_FOR_REAL_STUDENT_TRAFFIC:NO. Owner SQL required:NO.

After the security blocker, remaining rollout gates are privacy/retention policy, AI adapter/provider data
retention, backup/storage deletion, worker credentials, reconciler/scheduler, telemetry/cost ingestion and
actual product UI/E2E. Shared identity acceptance does not close these gates.

## Validation and handoff

10 existing offline promotion/preflight tests PASS. Actual readback assertions confirm exact migrations,
47 definitions,19 empty tables,4 columns, canonical preservation, all table grants, function owners/search
paths and the exact nine EXECUTE discrepancies/three membership discrepancies. A passing offline suite
is not a passing Production security review. Wiki handoff, diff/secret scan and Owner iOS hashes checked.

STOP. Next: Owner/ChatGPT reviews these two concrete discrepancies and authorizes a narrowly reviewed
forward correction/contract resolution. No student activation, worker credential deployment or UI connection.
