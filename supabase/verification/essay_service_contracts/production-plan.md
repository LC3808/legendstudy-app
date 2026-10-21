# Production preflight — 2026-10-21 (READ ONLY)

Baseline: APP8110492 / LAB29a8b2d / Wiki55343a6. Target project
`stlhijzpjfgwwdgunlsd` only. No Production migration/deploy/Provider/Credit action.
Existing tests (19 PG17 +235 WEB tests) reused, not repeated.

## Exact SQL and order

1. `supabase/migrations/20261021071701_essay_browse_metadata.sql`
   SHA256 `50ae2c213d75dd3da8d9635c6c2fd22031604bde9134f59bca4508c014b26b51`
2. `supabase/migrations/20261021071702_essay_confirmed_math_input.sql`
   SHA256 `18ee87678c4b0ed1639c2eb8deb34e05df1d606059c85319447adbb600784450`

Do not execute `db push` against the entire historical migration directory.
Use the reviewed canonical migration executor for ONLY these exact versions under
`postgres` (NOSUPERUSER/BYPASSRLS, as observed). Owner approval required first.
Run with session lock_timeout5s / statement_timeout60s; do not override a lock failure
by disabling RLS/triggers or killing unrelated sessions. Each file has BEGIN/COMMIT.

## Objects and impact

M1 creates `public.essay_browse_catalog(text)`, function comment and explicit ACL.
No table/column/index/data changes. SQL STABLE SECURITY DEFINER, empty search_path,
fixed42Catalog identity list, metadata whitelist. anon/authenticated EXECUTE; PUBLIC
and service_role revoked. **Definer owner postgres bypasses base-row RLS inside this
function**; this is a deliberate bounded metadata permission, not invoker-filtered
access. Existing table RLS is unchanged. Approval must include this metadata exposure.
All42 identity matches verified against live DB; unknown catalog ID returns empty.
Returned evaluationReady is conservative false, not a new evaluation approval source.

M2 adds nullable `math_subproblems.essay_question_id` UUID + FK to essay_questions(id),
partial unique index `math_leaf_essay_question`, trigger `essay_leaf_identity` and
INVOKER function `math_private.essay_leaf_identity_guard()`. Adds private INVOKER
`essay_exam_private.confirmed_answers(uuid,uuid,uuid,jsonb)`. Replaces two existing
DEFINER submit functions (normal/cycle), retaining owner and essay_worker-only ACL.
No new table, no IDs altered, no backfill, no source/question deletion. FK has no
cascade. One existing Math leaf,12 attempts: adding NULL does not map it; a used leaf
cannot be remapped under the guard. Future mapping requires separate reviewed content
work; migration is not image-service activation.

Existing submit/cycle live bodies are byte-equal after wrapper normalization to the
canonical rollback baseline. Their current MD5/ACL and reserve/finish/history hashes
are recorded. New private helpers have empty search_path; API roles have no direct
EXECUTE. Existing require_active, package/model readiness, authenticated Worker subject,
account lock, exact-key journal replay and Credit finalization remain in place.
Private data protection is unchanged; existing Math input upload/confirmation paths
remain necessary. No live submit was executed for preflight.

**Data impact:** none to existing business values; limited schema/API impact. Column
addition may briefly lock math_subproblems; FK/index locks also affect related access.
Existing leaf rows gain NULL in row shape, so compare old row hash excluding new column.
No full performance SLA inferred from the small current table.

## Observed live baseline

07:48–07:53UTC:53 universities,193 exams,616 questions,152 document rows/Storage
objects,98 reviews,3 exam journal runs,1 Math leaf,12 Math attempts,35 Credit rows.
The11-college cohort is97 NEEDS_REVIEW exams /382 questions /150distinctPDF hashes /
2484mappings; active exams0, published questions0. The152 total includes2 pre-existing
objects; do not confuse total counts with newly registered cohort.
Existing FK constraints inspected were validated. New functions/column/migration
versions absent. Whole-policy hash and data fingerprints are in baseline JSON;
this is a timestamped observation, not a backup or permanent expected production hash.
Refresh immediately before approved execution and investigate legitimate concurrent
activity rather than overwriting data to force a match.

## RLS / access result

PASS for current scope: anon Storage originals0; a real active non-operator authenticated
subject sees1 previously Owner-approved Hanyang QUESTION-only PDF, other originals0.
That existing Oct14 exception is preserved (LAB docs/reviews/hanyang-question-access).
It is not one of the11-college internal evaluation PDFs. Both buckets remain private.
Direct access to essay_material_private is denied at schema privilege level; anon/auth
have no SELECT on private documents/reviews. Submit/cycle only essay_worker, not anon,
authenticated or service_role. Existing Math Storage owner restrictions remain.
Do not claim all authenticated users see zero PDFs; do not revoke the prior exception.
Post-migration ACL and role checks are planned, not executed against nonexistent RPCs.

## Backup / recovery gate

Before apply: confirm recent successful Supabase backup/PITR recovery point and exact
restore procedure in project dashboard; keep identifier/time in private operations
record. **NOT_ASSESSABLE here: available read-only tools did not expose backup state.**
Do not claim a restore point exists. Back up exact live pg_get_functiondef output and
ACL/owners for two replaced functions, schema/constraints/policies and migration ledger
versions in restricted local operations storage. No student rows/raw files in GitHub.
Current function bodies already match rollback source; hashes are not data backups.
Storage files are not modified and must not be deleted/re-uploaded for this deployment.
A whole DB/PITR restore can discard concurrent legitimate work: incident-only, separately
approved, not the ordinary rollback procedure.

## Failure and rollback

- Preflight drift, missing backup confirmation, wrong project/owner/ACL, ID mismatch,
  unexpected existing objects, lock timeout or SQL error: STOP. No broader migration.
- M1 committed/M2 failed: M2 transaction rolls back. Keep M1 only if explicitly accepted;
  otherwise drop only the newly created metadata function (verify it did not preexist).
  Do NOT run the combined rollback while M2 column/helpers are absent.
- Both applied but unused: run reviewed `rollback.sql`. It restores exact previous
  submit/cycle bodies and removes only new mapping/helper/projection objects. No CASCADE.
- Any non-null mapping or journal input snapshot: rollback guard aborts; preserve data,
  stop activation and review forward fix. Never delete mapping/history to bypass guard.
- M1 CREATE OR REPLACE is repeatable but version ledger remains authority. M2 rerun is
  not a successful no-op: duplicate column aborts transaction. Inspect versions/objects
  and resume only missing version. Do not turn failures into blanket IF NOT EXISTS.

## Postflight / service expectation

Run `production-readonly-checks.sql` before/after; compare row/policy/FK fingerprints,
counts and source file hashes. Run `production-postflight.sql` after both applied:
new column nullable, mappings0, same-exam violations0, unique index/FK/trigger present,
metadata ACL true only anon/auth, submit ACL true only essay_worker, helper ACL false
for all API roles, active/published cohort still0, unknown ID empty, no private storage.
Validate whitelisted response keys, all42 catalog identities and11cohort counts with
read-only per-university RPC calls; metadata order and identity must match base records.
No submit/reserve/finish/Provider calls as a deployment smoke test. No Credit transactions.
Recheck active non-operator Storage using transaction-local identity, never print user ID
or claims. Existing private evidence denial must remain. Refresh unchanged legacy
reserve/finish/history definition hashes. Verify new function bodies against exact SQL.

WEB changes are not deployed here. DB migration alone exposes metadata RPC but does
not activate AI or complete UI handoff. Production WEB deployment, mapping/rights/model
approval, safe Provider E2E and public release each remain separate approvals.

## Decision

SQL compatibility / current RLS / identity / rollback baseline: PASS.
Production application readiness: PARTIAL until backup recovery point is confirmed and
Owner approves the exact two migrations including bounded DEFINER metadata exposure.
No confirmed SQL compatibility failure found. Existing operating service remains HOLD.
