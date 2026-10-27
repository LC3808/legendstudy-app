# Beta clock access — NOT APPLIED

Production browser exposed `permission denied for function clock`; claim owner postgres lacks EXECUTE on essay_executor-owned read-only clock. Existing tests used a privileged isolated role and missed this production ACL difference. Other claim/source dependencies were checked and are executable by postgres.

Approval scope: EXECUTE on exactly essay_private.clock() to server role postgres. No client grants, function body/owner changes, campaign activation or credit writes. Temporary SET membership is granted and removed in the same transaction, retaining original membership from other grantors.

Run precheck.sql → apply.sql → postcheck.sql once after Owner approval. Prior beta/source SQL must not be rerun. Rollback requires the same temporary role mechanism and `revoke execute on function essay_private.clock() from postgres` as essay_executor; it restores the known claim error and is not a service recovery path. Campaign remains inactive throughout.

Validation: isolated PostgreSQL non-superuser postgres reproduction, 6 assertions PASS (before denied, after allowed, SET restored, authenticated/anon blocked, actual clock call). Fixture rolls back completely.
