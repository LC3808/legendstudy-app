# Worker JWT role switching — READY FOR OWNER REVIEW, NOT APPLIED

Scope: `20261014011329_essay_worker_gateway_role.sql` grants existing essay_worker
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
