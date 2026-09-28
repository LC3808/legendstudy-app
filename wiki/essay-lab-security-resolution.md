# Essay LAB security resolution — PASS / DEPLOYED

2026-09-28. Owner authorized narrow B1/B2 resolution and one corrective Production migration after
isolated verification. **SECURITY_CONTRACT:PASS · POST_APPLY:PASS · PRODUCT_SCHEMA:DEPLOYED.**
READY_FOR_PRODUCT_IMPLEMENTATION:YES. READY_FOR_REAL_STUDENT_TRAFFIC:NO.
The prior [applied-with-blocker report](essay-lab-production-apply.md) remains historical evidence.

## B1 — nine trigger helpers

Observed Production default ACL for postgres-created functions in public grants service_role EXECUTE.
The original helper revokes removed PUBLIC/anon/authenticated but omitted service_role. No product
client/worker operation directly calls these trigger-returning helpers; only attached triggers need them.
This explains the nine residual permissions. The approved correction is exactly nine explicit function
REVOKE EXECUTE statements, enclosed in BEGIN/COMMIT; no default ACL alteration, new features or data writes.

[20260928000400_essay_helper_execute_boundary.sql](../supabase/migrations/20260928000400_essay_helper_execute_boundary.sql)
was applied once with `supabase db push --linked --skip-vault`. Applied001/002/003 and all older migration
files were preserved byte-for-byte. Functions, triggers, owners and definitions were not replaced.
After correction, all nine helpers deny service_role EXECUTE; PUBLIC/anon/authenticated/worker/finance
exposure remains denied. Trigger behavior and actual RPC execution passed isolated regressions.

## B2 — CONTRACT_REVISION, not a runtime sandbox

[PostgreSQL17 role attributes](https://www.postgresql.org/docs/17/role-attributes.html) documents the
non-superuser CREATEROLE automatic bootstrap-superuser ADMIN-only grant. The Production catalog records
postgres as non-superuser/CREATEROLE and supabase_admin as grantor, exactly matching this mechanism and
migration003's role creation. The temporary ordinary self-grant is revoked; the automatic administrative
one remains. A genuine non-superuser connection reproduced this locally.

INHERIT=false prevents immediate privilege inheritance; SET=false prevents direct SET ROLE. ADMIN permits
role administration and membership grants, including an explicit self-grant of runtime access. Thus these
flags prevent accidental role use; they do **not** protect against a malicious administrator. PostgreSQL
also specifies that the creating non-superuser cannot remove the bootstrap-superuser grant; a superuser can.
Local tests confirmed self-revoke leaves it, while superuser removal eliminates management authority.

Decision: preserve the managed administration relationship for the trusted postgres migration role.
Removing it offers no new client/worker isolation here, would remove normal role-management capability,
and is not an operation the non-superuser can perform against that grantor. No superuser credential or
platform-role workaround was used. The product runtime identities never receive ADMIN membership.
This is a scoped contract correction based on semantics, not a general acceptance of memberships.

### Exact managed membership contract

Exactly three rows, one for each essay_executor / essay_worker / essay_finance:

- member=postgres; grantor=supabase_admin; ADMIN=true.
- INHERIT=false; SET=false; effective pg_has_role USAGE=false and SET=false.
- No extra members/roles/grantors, missing rows or alternate privilege paths accepted.
- No new direct table privileges; full client/worker/finance table and RPC allowlists still enforced.
- Executor/worker/finance remain NOLOGIN; only executor BYPASSRLS; no role becomes SUPERUSER.
- Executor CREATE on public/essay_private remains revoked. No runtime worker receives executor membership.

A disposable superuser-created role environment legitimately has zero automatic rows; that is a separate
explicit test mode, never a permissive fallback for Production. ADMIN authority stays inside the trusted
migration/operations boundary. Worker credentials remain a separate rollout gate.

## Isolated verification before Production

[Reproducible native harness](../supabase/validation/essay_lab_product/run_security.py) retains the original
numeric-loopback/empty-db/explicit-consent guards. It reproduces the service_role default ACL before helper
creation, applies the promoted package plus correction, then executes:

- Phase2A:77 assertions PASS.
- Phase2B:55 RPC/concurrency/fencing/rollback checks PASS.
- Security:17 checks PASS, including9 revokes, denied direct table inheritance/SET ROLE, retained ADMIN
  management, failed self-removal of bootstrap grant, explicit self-grant capability, and superuser removal.
- Fresh isolated Supabase:37 actual Auth JWT/PostgREST checks PASS after correction; real client, worker and
  finance requests exercise submission, result settlement, refund and erasure. Synthetic local users only.
- Static:16 promotion/security tests +36 existing review tests PASS. Original promotion-order assertion
  was extended to include the new fourth migration, without weakening original executable equivalence checks.

Native PostgreSQL17 and this task's local Supabase stack were stopped. Local test credentials stay outside
Git; no real student/provider data were used. No Production student fixture or new App/LAB login test.

## Production preflight and result

Preflight read-only comparison found exactly the reported B1/B2, no new drift:47 definitions unchanged,
19 empty tables, same canonical fingerprints, ledger16. Fresh dry-run showed only20260928000400, no seeds
or role bundle, vault skipped. One correction push succeeded; no repair/retry/rollback/direct history write.

Post-apply full read-only contract:

| Gate | Result |
|---|---|
| Helper unexpected EXECUTE |0 |
| Managed membership contract |PASS |
| Tables / additive columns / public RPCs |19 /4 /12 |
| FK/UNIQUE/CHECK/index/trigger/policy/definition fingerprints |47/47 match |
| RLS |19/19 enabled |
| Function ownership / fixed search_path / RPC EXECUTE |PASS |
| Client direct fact writes / worker-finance direct table writes |DENIED |
| Bootstrap schema CREATE |Revoked |
| Ledger / local-remote / pending |17 /MATCH /NONE |
| New product rows / FK orphans / canonical orphans |0 /0 /0 |
| Canonical counts |universities5 /essay_exams21 /essay_exam_resources134 /resources10556 |
| Canonical fingerprints |UNCHANGED |

[Sanitized current result](../supabase/validation/essay_lab_product/security_resolution_result.json) preserves
actual catalog rows, cause evidence and isolated results. [Offline contract validator](../supabase/validation/essay_lab_product/security_contract.py)
rejects even one unexpected privilege/member/option. Prior apply_result remains the historical failing snapshot.

## Next boundary

Student data NOT_ENABLED; AI/provider NOT_ENABLED; worker NOT_DEPLOYED; UI NOT_CONNECTED.
Remaining gates: privacy/retention, actual AI adapter, provider retention, backup/storage deletion,
worker credentials, reconciler/scheduler, telemetry/cost and UI/E2E. No Owner SQL action required.
STOP after correction/verification/documentation/commit/push. DB/schema security review is complete;
next is Owner/ChatGPT review → Essay LAB Product Implementation, not another schema redesign.
