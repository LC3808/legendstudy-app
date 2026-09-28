# Essay LAB migration promotion — PROMOTED / NOT APPLIED

> Current status: [Product applied with security blocker](essay-lab-production-apply.md). All3 applied; ledger16/no pending. Historical checkpoint below is preserved; product remains disabled.


> Current follow-up: [Production read-only preflight](essay-lab-production-preflight.md) executed; APPLY BLOCKED by absent migration history. Below preserves the promotion-stage preparation record.


Owner/ChatGPT approved Phase2A/2B/2C, KEEP19, four additive columns and server RPCs.
**Formal migration package promoted; Production NOT APPLIED; real student data NOT ENABLED.**
Shared App/LAB identity PASS (Kakao actual UUID equality Owner PASS, Apple/Google historical PASS).
Email NOT_RUN does not block the Migration Gate. No login repetition or diagnostic phone build required.

## Package and ordering

Read actual repository history before selecting the next date-based slots. Previous latest file:
20260927000200_essay_lab_foundation.sql. The following three versions were absent and are unique:

| Order | Formal migration | Contents |
|---|---|---|
| 1 | [20260928000100_student_essay_product.sql](../supabase/migrations/20260928000100_student_essay_product.sql) | 15 canonical/learning/operational tables, constraints/RLS/history triggers |
| 2 | [20260928000200_essay_entitlements.sql](../supabase/migrations/20260928000200_essay_entitlements.sql) | 4 credit/decision tables, ledger constraints/RLS/history |
| 3 | [20260928000300_essay_server_operations.sql](../supabase/migrations/20260928000300_essay_server_operations.sql) | 4 additive columns,12 public operation RPCs, narrow roles/grants/revokes |

Three files retain the reviewed learning/commercial/operation boundaries and existing transaction scopes;
no new fragmentation or transaction consolidation. Existing universities/resources/Essay foundation reused.
The promoted SQL is exactly the corresponding001/002/003 review SQL except its first-line status comment.
Parsed ASTs, all function bodies and transaction boundaries MATCH. No redesign, policy change or seed.
Review drafts and prior Phase2A/2B results remain historical evidence.

Additive columns: attempts.submission_request_hash, evaluations.input_snapshot,
processing_runs.lease_token and lease_expires_at (under the existing essay_* table names).
12 public operation RPCs;28 public/private function definitions total, including prior invariant helpers.
No new provider credential, worker login, authenticator membership, AI service or UI is deployed.

## Prepared inspection package

[Operator instructions](../supabase/validation/essay_lab_product/README.md),
[read-only preflight](../supabase/validation/essay_lab_product/preflight.readonly.sql),
[read-only post-apply validation](../supabase/validation/essay_lab_product/post_apply.readonly.sql),
[expected catalog](../supabase/validation/essay_lab_product/catalog_contract.json),
[sanitized result](../supabase/validation/essay_lab_product/result.json).

Both inspection scripts run BEGIN READ ONLY/ROLLBACK. They are prepared for later authorized use,
**not executed against Production**. No Owner SQL action is requested now.

Preflight checks prerequisite presence/columns/FK relations, server version/encoding, all19 table names,
function/private-schema/policy collisions, migration history, roles/grants and legacy queued evaluations.
Missing history or ambiguous partial deployment means STOP. Repo files are not proof of remote deployment.
Compare existing foundation structure with the approved foundation migration and reconcile all pending
versions before apply. Save aggregate canonical counts/fingerprints, not row bodies/UUIDs.

Post-apply checks19 tables/RLS,4 columns,47 catalog definition fingerprints covering constraints/indexes/
policies/triggers/functions, explicit grants/definer/search-path boundaries, orphan counts, initial new-table
counts and canonical preservation. A fingerprint mismatch requires inspection; PostgreSQL formatting
version differences are not permission to skip validation. No real student test INSERT is included.

The SQL exposes role/privilege matrices for operator review. Authenticated direct writes remain limited
to mutable drafts/targets; fact/result/ledger manipulation denied. Worker/finance get only approved RPCs;
executor ownership does not become a worker credential. Temporary membership/CREATE grants are revoked.
Detailed allowlist and stop conditions are in the package README.

## Actual local validation

- New disposable PostgreSQL17.11 UTF8, numeric loopback only; no tunnel or Production config used.
- Promoted files themselves applied over actual initial-content/Essay-foundation baselines with local
  synthetic Auth/history fixtures. This is not a replay of unrelated full App migration history.
- Original Phase2A77 assertions + Phase2B55 RPC/concurrency/fencing/rollback checks PASS after promoted apply.
- Separate clean DB: preflight→all3 migrations→post-checks PASS;19 initial tables all0 rows; orphan counts0;
  nonempty synthetic canonical counts/fingerprints preserved;47 definitions matched; exact table/RPC grants
  and bootstrap revocation PASS. Re-running preflight after apply correctly reports target collisions.
- Static promotion tests6 + existing review tests36 PASS. Migration timestamps unique/ordered, SQL AST
  equivalence PASS. All migration statements parse and all function bodies compile in actual PostgreSQL.
- Prior actual Supabase JWT/PostgREST PASS reused from Phase2B because executable SQL is unchanged;
  no fresh Supabase/JWT or actual App/LAB login run is claimed here.

Test-environment correction: initial initdb defaulted to SQL_ASCII, making driver text observations bytes;
the string fixture failed. That isolated cluster was stopped and a NEW UTF8 cluster created, matching
Supabase. No assertion/SQL was weakened. pglast8.4 cannot JSON-decode some preexisting trigger PL/pgSQL ASTs;
SQL AST and RPC-body parsing pass, and real PostgreSQL compiles/executes all invariant functions. These are
tool/environment limitations, not a hidden semantic change to the promoted package.

## Apply boundary and roll-forward

Nothing in this promotion triggers deployment. No supabase db push, linked DB command, Production query,
seed, Auth mutation, provider call or product UI implementation was executed. Owner iOS edits preserved.

Future apply must keep Essay client writes/workers disabled until all3 migrations and validation finish.
Each file retains BEGIN/COMMIT; if a later file fails, earlier files can remain. Inspect actual catalog/history
before retry. Prefer a reviewed corrective forward migration; never automate DROP/TRUNCATE rollback,
overwrite retained attempts/evaluations/ledger or alter already-applied history. Corrective changes require
separate authorization. Existing public canonical sources/binaries must not be duplicated or replaced.

## Current gates / next action

| Gate | Status |
|---|---|
| KEEP19 +4 columns / RPC approval | APPROVED |
| Static / disposable apply / Phase2A/2B regressions | PASS |
| Review vs promoted executable SQL | MATCH |
| Shared identity | PASS |
| Migration | PROMOTED / NOT_APPLIED |
| Production preflight | READY / NOT_EXECUTED |
| Production apply + validation | NOT_EXECUTED |
| Real student data | NOT_ENABLED |

Remaining rollout gates: privacy/external provider/backup retention; actual AI provider adapter/telemetry;
scoped worker credential deployment/reconciler; separately approved Production preflight, apply and validation.
Identity acceptance does not close those gates. NEXT: Owner/ChatGPT final package review → separately
authorized Production preflight → separate Production APPLY approval. STOP at promotion in this task.
