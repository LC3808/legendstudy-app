# Essay LAB migration validation — SECURITY PASS / DEPLOYED

> Current canonical result: `security_resolution_result.json`; [B1/B2 resolution](../../../wiki/essay-lab-security-resolution.md). B1 forward REVOKE applied, B2 exact ADMIN-only contract. Historical preparation below is retained.


> Current: [Production apply](../../../wiki/essay-lab-production-apply.md), `production_apply_result.json`:3 applied, ledger16/no pending; security discrepancies9 helper grants/3 ADMIN-only memberships. No further mutation authorized. Below preserves historical preparation.


Owner approved KEEP19, four additive columns and server RPCs. Promotion is complete; Production access,
preflight execution and apply require the next explicit authorization. **Do not run a deploy/db push now.**
Canonical report: [Migration promotion](../../../wiki/essay-lab-migration-promotion.md).

## Exact order and equivalence

Observed repository predecessor:20260927000200_essay_lab_foundation.sql. Next date-based slots were absent
before promotion, verified unique. Existing three review subsystem boundaries are preserved:

1.20260928000100_student_essay_product.sql (15 canonical/learning/operational tables)
2.20260928000200_essay_entitlements.sql (4 commercial tables)
3.20260928000300_essay_server_operations.sql (4 additive columns,12 client/worker/finance RPCs)

All executable SQL/transactions match the corresponding001/002/003 review files. Only first-line status
comments change. No flattening, reordering, new policy or seed. Three files retain the already-tested
transaction/subsystem boundaries rather than combining DDL into a new atomicity model. Apply all three
before enabling any server/client path. Never enable writes after only the table migrations.

## Future read-only preflight (prepared, NOT executed in Production)

Run preflight.readonly.sql only after authorization. It uses BEGIN READ ONLY/ROLLBACK, local UTC/catalog-first search_path, and aggregate or
catalog output, never bodies/UUIDs. Review every result; it is a checklist, not an automatic apply gate.
STOP on missing prerequisites, object/policy/function/schema collisions, partial deployment, unexpected
roles/memberships, absent/unreconciled history, legacy queued evaluations or differing foundation shape.

- Required: PG17+, UTF8, auth.users/auth.uid(), profiles, universities, resources, essay_exams,
  essay_exam_resources and existing initial content/foundation dependencies.
- Inspect profiles.id→auth.users.id, exam→university, evidence→exam/resource FK definitions and expected
  existing foundation columns against20260927000200 (source hash in result.json). Extra prior profile
  extensions are expected, not a reason to overwrite existing schema.
- Reconcile remote schema_migrations versions with **all** repository history. Expected predecessor is
 20260927000200; files alone do not prove remote apply. Missing history is NOT_VERIFIED, never auto-PASS.
- All19 target names and function names/private schema must be available on a first apply. Existing queued
  evaluations cannot be silently backfilled with invented hashes/leases. STOP and review deployment drift.
- Migration role needs public CREATE, auth schema USAGE/auth.uid EXECUTE and role-management privilege
  sufficient to create NOLOGIN/BYPASSRLS executor and transfer function ownership. Supabase local bootstrap
  already passed Phase2B; never assume another environment has identical privileges.
- Review any existing essay_executor/worker/finance roles and memberships; no client/worker may inherit
  executor or service_role. No worker credential or authenticator membership is deployed by this package.
- Save only aggregate canonical counts/fingerprints (universities/exams/mappings/resources). Serialize
  canonical ingestion/admin changes during the future apply/validation window, or investigate any drift.
  No fixed Production counts are assumed and no Production catalog was read in this task.

## Future post-apply verification

post_apply.readonly.sql runs no writes/negative inserts. It compares47 object definitions against the
validated catalog (19 tables +28 public/private functions including12 operation RPCs). Per-table hash covers
columns, FK/UNIQUE/CHECK, indexes, triggers, RLS and policies. All definition_matches must be true;4 columns
present;19 tables/RLS true; all initial new-table counts0; orphan counts0; canonical counts/fingerprints
identical to preflight. Nonzero initial rows mean an unexpected writer/seed: STOP before enabling data.
Catalog formatting differences across PostgreSQL versions require inspection, not blind hash acceptance.

Privilege output allowlist:
- anon: SELECT only on questions/question_evidence/evaluation_criteria (published RLS); no private access.
- authenticated: private owner SELECT except processing runs; direct INSERT/UPDATE/DELETE only drafts
  and target universities. Facts/results/ledger remain server-only.
- worker/finance: no direct table rights. Public/client RPCs only authenticated; claim/timeout/finalize/
  reconcile only worker; refund only finance. PUBLIC/anon/service_role have no new RPC EXECUTE grants.
- private functions: no listed external role EXECUTE. UID bridge executor-only; other helpers executor-owned.
- public RPCs SECURITY DEFINER with fixed empty search_path, owned by NOLOGIN executor; UID bridge owned by
  migration role. Worker/finance NOLOGIN/NOBYPASSRLS; executor NOLOGIN/BYPASSRLS, function-ownership only.
- Temporary executor membership/schema CREATE must be revoked. Unexpected membership blocks rollout.

Review migration history for all three exact versions after apply. These queries inspect grants/RLS;
actual denied-write JWT tests remain Phase2B local evidence, not Production runtime tests. Any future
Production behavioral probe needs separately authorized controlled fixtures, never real student seeding.

## Local reproduction only

Python psycopg[binary]/pglast8.4; disposable PG17 UTF8 cluster, explicit ESSAY_REVIEW_DISPOSABLE=YES,
private ESSAY_REVIEW_TEST_DSN (numeric loopback, essay_review_* DB). Do not log a DSN.

- New EMPTY DB1: run `python3 supabase/validation/essay_lab_product/run_clean.py`. It refuses populated DB,
  applies real initial/foundation baselines with local Auth/migration-history fixtures, seeds invented public
  canonical records BEFORE promotion, executes preflight, applies promoted files, executes post-checks and
  proves canonical preservation/zero new-table rows/zero orphans/precise grants/bootstrap revocation.
- New EMPTY DB2: set ESSAY_REVIEW_PROMOTED=YES and run
  `python3 supabase/review/essay_lab_product/runtime/run_server.py`.
  Applies promoted files, then original77 assertions and55 server checks. Review-mode default is unchanged.
- Static: `python3 -m unittest discover -s supabase/validation/essay_lab_product -p 'test_*.py'` plus existing
  review suites. Comparison is parsed SQL AST, including PL/pgSQL function bodies, not filename equality.

These are initial-content/Essay-foundation baselines, not replay of unrelated full App migration history.
Actual Supabase JWT/PostgREST PASS is reused from Phase2B (executable SQL unchanged), not freshly rerun here.
Test data are synthetic and external to Git. Stop the dedicated test cluster afterward.

## Roll-forward, not destructive rollback

After any future partial/failing apply: leave Essay writers/workers disabled; capture sanitized migration
version/object inventory and transaction outcome; do not re-run blindly or drop/truncate tables. Review a
minimal corrective forward migration preserving attempts/evaluations/progress/ledger. Each promoted file
retains its own BEGIN/COMMIT: earlier files may remain if a later file fails. Reconcile actual history before
retry. A correction needs separate review/authorization; do not modify already-applied migration history.
Do not use a privileged service_role worker to work around failed grants or missing transactions.

## Current security verification

`security_contract.py` validates Production memberships: exactly3 postgres/supabase_admin ADMIN-only
rows, INHERIT/SET and effective USAGE/SET all false. No extra member or privilege path allowed.
ADMIN is trusted administrative power and can explicitly regrant runtime privileges; it is not a sandbox.
`run_security.py` runs77+55 regressions plus17 security probes on a new explicitly disposable PG17 DB.
Use the same ESSAY_REVIEW_DISPOSABLE / ESSAY_REVIEW_TEST_DSN guards as the existing native runner.
The one new migration only revokes service_role EXECUTE from9 helpers. Current Production17 versions
match local, pending none. No further Production operation is authorized by this package.
