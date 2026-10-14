# Worker JWT role switching — OWNER APPROVED / APPLIED 20261014020622

Scope: `20261014020622_essay_worker_gateway_role.sql` grants existing essay_worker
role to the PostgREST authenticator with SET true, INHERIT false, ADMIN false.
No JWT/key issuance, table/function grants, Provider activation, Credit transaction,
RLS bypass, data mutation, or student/anon role change. No essay_executor membership.

Production baseline Oct14: authenticator cannot assume essay_worker; worker is
NOLOGIN/NOSUPERUSER/NOBYPASSRLS and has no executor membership. Existing SECURITY
DEFINER endpoints available to worker are claim, finalize_success, finalize_failure,
timeout, reconcile, registered_questions, material_runtime_package. Enabling role
switching makes these existing worker permissions reachable using a valid signed
essay_worker JWT; it is NOT restricted to Registry reads alone. Student tokens,
anon/API keys cannot assume this role. Secret contents were not read or logged.

Local PG17: gateway SET ROLE, no inherited/admin privilege, anon/authenticated deny,
worker→executor deny, rerun, rollback all PASS via `tool/verify_essay_worker_role.py`.
Actual JWT gateway check remains after authorized application; no Provider/Credit
call is required for a Registry-only check. Run `verify.sql`, then the existing
allowlisted `/api/essay/catalog` read and compare canonical IDs. Do not enable AI.

Rollback: `rollback.sql` removes only the added role membership; first-apply
baseline membership was absent. Existing migrations, policies, records and keys
remain. Active PostgREST transaction behavior must be allowed to drain; retest the
Registry call. Do not rotate unrelated signing keys.

Owner application is separate from Provider005, model selection, transmission
rights, exam settlement API, real Provider/Credit tests or public release.

## Production verification — Oct14

Owner explicitly approved existing Worker role switching only. Applied migration
20261014020622; local proposal timestamp20261014011329 renamed to match returned
Production history (no migration-history repair or duplicate apply). Verified
SET=true, INHERIT=false, ADMIN=false; worker remains NOLOGIN/NOSUPERUSER/NOBYPASSRLS.
Anon/student membership and worker→executor membership remain false. In a rollback
read-only transaction, authenticator→essay_worker succeeded and existing Registry
RPC returned234 questions for the existing active admin account. No Provider or
Credit request occurred. This proves SQL role/RPC access, not a fresh Cloudflare
Secret/JWT HTTP E2E. No Secret was read, output, rotated or replaced.
