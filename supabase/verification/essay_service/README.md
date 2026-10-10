# Essay service verification / SQL review packet

Status: LOCAL CONTRACT VERIFIED / PRODUCTION NOT_APPLIED / PUBLIC HOLD.
Owner final SQL approval is required; none is requested during overnight execution.

## Scope, backup, dependencies

`original-recovery.sql` is a read-only backup of the deployed single-job function,
retrieved before changes from LegendStudy project `stlhijzpjfgwwdgunlsd`.
Function definition MD5: `5cc017fbbd0ba9ca4602827dd0fbeeeb`.
Backup also records execute ACL: postgres + math_evaluation_worker; no anon,
authenticated, service_role execute. It is loaded ONLY into disposable fixtures.
Do NOT reapply this backup to production: the proposed migration leaves it intact.

The new migration adds one narrow batch function over existing math_attempts,
math_evaluations, canonical lifecycle check and single-job recovery. No tables,
RLS, billing formula, history or existing function replacements. Caller prepared
in LAB `runScheduledRecovery`; not scheduled/deployed. Browser recovery endpoint
uses the existing single-job RPC after authenticated owner state read.

Migration `20261010150837_essay_math_recovery_batch.sql` was created using the
existing Supabase migration path. It aborts if the single-job fingerprint differs
or the batch already exists. No automatic replacement. Transactional DDL; only
math_evaluation_worker receives EXECUTE (besides function owner). Default20/max50.
No output includes student identifiers/answers. Lifecycle-denied jobs remain denied.

## Apply review / rollback

Before eventual approved apply: fetch latest remote, reread deployed function+ACL,
check worker lifecycle/expiry and confirm no overlapping batch definition. Review
migration and below hashes, local tests and operational skip monitoring. Existing
CLI migration history contains other HELD changes: do not bulk `db push` pending
migrations. Use the established Owner-approved selective migration/tracking path.
No CLI apply or production SQL command has run in this task.

Rollback `recovery-rollback.sql` removes ONLY the batch function. First disable any
future scheduler and wait for in-flight recovery, if one was later activated.
Rollback does not undo already valid canonical Credit release transactions or
alter the single-job function. Run within the normal privileged migration session.
A later modified batch must be reviewed before dropping, not blindly rolled back.

Postflight (read-only): `pg_get_functiondef`, function owner/search_path/ACL,
anon/authenticated/service_role EXECUTE denial and unchanged single-job MD5.
Execute recovery acceptance in isolated tests; do not manufacture production jobs
or billing to prove this migration. Schedule activation needs separate approval.

## Reproduce

Use existing Python+psycopg and PostgreSQL17 (no install):

```sh
ESSAY_PRIVATE_PACKAGE=/absolute/private/skku-package python tool/test_essay_service_content.py --pg-bin /opt/homebrew/opt/postgresql@17/bin
python tool/test_essay_recovery_batch.py --pg-bin /opt/homebrew/opt/postgresql@17/bin
```

Tests start disposable Unix-socket PG and reuse canonical prior migrations/RPCs.
They require the retained private package; no committed body or internet re-fetch.
Content import function itself refuses non-temporary Unix hosts and never publishes.
Generated private plan must remain under ignored `.local/`, mode0600.

Evidence: content-validation.json19 checks; recovery-validation.json21 checks.
recovery-baseline-validation.json is the existing Math harness's baseline migration
fingerprint plus this test's checks (not extra independent21 tests). No Auth HTTP/
Storage/live Provider E2E claimed. Test rollback and direct unauthorized-role calls
PASS. Production reads before task confirmed general questions/evidence/criteria0.

QA metadata migration and existing8 evaluations/4 pairs untouched. No student PII,
keys or real answers in this packet.

## File SHA256

- `20261010150837_essay_math_recovery_batch.sql`: `0bd1a9a208a6fa38fa1138dc6524841be7a2385bbd09e06b859dbcb086b4dfdc`
- `original-recovery.sql`: `11511745cb0d5e697e8270a3704e0a3d245b579ce41cddbb005473d007a01e67`
- `recovery-rollback.sql`: `da3c4315ee686f3150c86eb2ed9b10cb6f4321591e2ef9e96d0052222e0f6c57`
