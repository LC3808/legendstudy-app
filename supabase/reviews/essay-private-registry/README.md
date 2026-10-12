# Private Registry read — Owner application gate

Production **APPLIED** with explicit Owner approval on 2026-10-13 KST.
Hosted migration version: `20261012215054`. Read-back confirms essay_worker-only
EXECUTE and 234 unpublished questions across 76 exams. Authenticated, anon and
service_role EXECUTE remain denied. End-to-end gateway JWT verification is pending
the existing server credential configuration.

SQL: `../../migrations/20261012215054_essay_private_registry_read.sql`
Rollback: `rollback.sql` (drops only the new RPC; no data deletion).

`essay_registered_questions(uuid)` returns only the exact approved 234 question IDs,
source keys, metadata versions, exam IDs, university IDs, academic years and kinds.
It returns no PDF/text, answers, identities, evaluations, credentials or Credit data.
The existing `essay_worker` role alone receives EXECUTE. Anonymous, authenticated,
service_role and Math worker roles cannot call it. No table grants or RLS changes.
The existing account lifecycle guard checks the gateway's verified subject.

WEB POST `/api/essay/catalog` verifies Auth online and the existing MATH allowlist
before the RPC. It accepts only bearer authentication and returns private/no-store.
Native calls the same endpoint. GET remains anonymous published-metadata only.
Neither metadata identity nor private registration grants Draft or evaluation access.

Deployment prerequisite: an existing, unexpired `essay_worker` credential held only
in the server's `ESSAY_REGISTRY_WORKER_JWT` secret. Do not use service_role, a Math
worker credential, a browser key, or generate credentials with unapproved signing access.
Missing configuration or RPC fails closed; existing source-only drafting continues.

Validation: `tool/test_essay_private_registry.py` uses disposable PostgreSQL17 with
actual canonical Math/account lifecycle migrations: exact234 IDs, minimal fields,
all other roles denied, missing/restricted account denied, RLS/Credit unchanged,
rollback/data preservation and reinstall. Seven checks PASS; existing Math setup
finalization/HQ read regression PASS. This is not live JWT or Provider E2E.

Apply only this exact SQL after approval. Read-back must confirm function ACL,
no anonymous/student EXECUTE, exact234 IDs via worker + approved Auth subject,
unpublished records unchanged. Re-run of an existing function intentionally aborts
rather than overwriting an operational definition. Inspect deployment history first.
