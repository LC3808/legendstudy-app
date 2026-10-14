# Private materials review — application candidate (2026-10-13)

**APPLIED after explicit Owner approval (Oct13).** This candidate enables administrator
review only, not student PDF delivery or evaluation. Target: LegendStudy
`stlhijzpjfgwwdgunlsd`. Do not rerun the already-applied Registry migrations.

## Impact

- Existing canonical `essay_exams`, `essay_questions`, `resources` IDs are reused.
- New private schema `essay_material_private`: documents, current review, immutable
  revision snapshots. Existing resources require content/source-post linkage and
  cannot represent private multi-exam review revisions without changing their contract.
- Five authenticated RPCs check the existing `is_quality_operator()` on every call.
  No new administrator membership, Worker grant, public question or Credit change.
- One **private**, immutable SHA256-keyed original PDF bucket
  `essay-material-originals`, maximum32MiB. SELECT/INSERT only for quality operators.
  No student policy, overwrite or delete permission is added.
- Reviewer UID is set by `auth.uid()`; deletion sets reviewer references to null.
  Review notes must contain source/review observations, not student personal data.
- Existing Registry76/234, Math, Ledger, payments and History are not mutated.

## Local validation / production read-only comparison

`PYTHONDONTWRITEBYTECODE=1 python3 tool/test_material_review_sql.py`
passed: repeat install, anonymous/nonoperator/table denial, immutable object
registration, concurrent revision conflict, foreign-question/page guards, unfinished
mapping drafts, checklist enforcement, ACTIVE denial, revisions and retained-data rollback.
This is an isolated PostgreSQL17 test with minimal canonical fixtures, not a
Supabase API E2E or complete production-schema clone.

Oct13 production read-only comparison: `is_quality_operator()` already validates
JWT/account lifecycle; existing Storage permissive policies are avatar/Math-bucket
scoped. `math_storage_owner` rejects other buckets; lifecycle/Math restrictions are
RESTRICTIVE. The approved schema was subsequently applied and read back.

## Apply and verify (Owner)

1. Supabase project above → SQL Editor. Review `install.sql`, run it as one transaction
   only after explicit approval. It uses no secrets and does not grant operator roles.
2. Run `verify.sql` (read-only). Confirm private bucket, RLS, RPC ACLs, original
   Registry/publication counts and no `authenticator → essay_worker` change.
3. Deploy the reviewed LAB branch to an approved environment with its existing
   Auth configuration. `/admin/materials/` requires a signed-in quality operator.
4. Verify anonymous and ordinary account denial using real Auth. Operator can select
   an existing exam, upload/select a PDF, analyze, save, reload and compare revision.
   A second editor with an old revision must get a conflict and retain its text.
5. Confirm Storage download denial for ordinary users and no overwrite/delete access.
   Record actual API/browser results separately from local SQL tests.

## Owner workflow after installation

Existing LAB login → `/admin/materials/` → search university/year/type/track/status
→ select exam → choose existing source or upload a PDF → analyze draft → map each
candidate to an actual question and PDF page range → inspect source → set independent
rights statuses and review checklist → save → verify → request Package approval.
Saving does not publish. `VERIFIED` does not mean `PACKAGE_READY`, `E2E_PASSED` or `ACTIVE`.
Evaluation Package 생성 builds a server-versioned evidence package (canonical IDs,
reviewed text/page references, rights, SHA256 digest) and records an approval request.
It remains runtime_ready=false; actual evaluation activation is separate.
Empty extracted text/scans require visual review; heuristic analysis is not verification.

## Rollback

Run `rollback.sql` to revoke all five client RPCs and remove bucket policies.
Retain all private documents, review revisions and source objects. Existing exams,
Credit and student History remain intact. Revert the LAB/APP UI commit if required.
Do not DROP tables/bucket or delete source PDFs as part of rollback.

## Remaining before service activation

Server-verified PDF ingestion, full identity/region/image analysis, safe student
question derivation + delivery policies, approved package→existing Runtime adapter,
Owner review, actual Provider/Credit scope approval and WEB/Native service E2E.
The conditional student viewer expects an approved `student_question` DTO; no such
asset is published by this candidate. Original/evaluation PDFs cannot be used there.
Worker Secret is configured, but authenticator membership remains false; this
candidate deliberately does not resolve or expand Worker execution permissions.

## Applied release

Migrations20261013032726/20261013033132 are recorded in production. CLI-created files
were aligned to the actual server-returned migration versions, not invented timestamps.
The second migration only adds server Package generation to the existing save RPC.
No role grant, Registry write, Credit or publication change.

Production WEB: https://lab.legendstudy.com/admin/materials/
LAB e4644774732e56c0f603a2a612b8a73173c58b95; Pages
5987e864-8cbf-413b-806d-9fa497d9d3f8. Rollback WEB point
aec0f8af-8a01-4b62-b690-f2c71e007816. Production Auth configuration preserved.

Read-back:3 RLS tables,private32MiB bucket,5 RPCs deny anon; Registry234 questions
unchanged; worker membershipfalse. Browser confirms real-domain login gate. Operator
PDF/save/reload validation awaits an existing administrator login; no claim of E2E.
Security advisor's no-policy INFO on these private tables is intentional direct-access
denial; authenticated definer endpoints rely on existing server operator checks.
[Advisor background](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).

## Oct13 reviewed Package Worker read — NOT APPLIED

`worker_read.sql` adds exactly one SECURITY DEFINER RPC:
`essay_material_runtime_package(uuid,text)`, executable only by existing essay_worker.
Reads current VERIFIED/approval-requested package with exact pinned digest,
recomputed integrity, canonical question source key, nonempty question text and
per-document Provider transmission approval. No direct table grant, role membership,
activation, Provider request, Credit or student-data mutation. No DROP/DELETE.
`worker_read_rollback.sql` revokes that one grant and retains every record.

Local verification: `python3 tool/test_material_worker_read.py` uses disposable PG17.
PASS: repeated installation, anon/authenticated denial, missing-rights denial,
pinned Worker read, stale-digest denial, empty-question denial, rollback retaining rows.
Runtime `fetch_reviewed_material` uses this RPC and existing HostedQuestion loader;
activation flag defaults false. Adapter7 tests PASS.

Production permission remains pending Owner approval. Existing authenticator→
essay_worker membership is separately absent; this SQL deliberately does not alter
it. Provider telemetry/policy, hosted Worker composition and exam Credit deployment
are still missing; applying this RPC alone does NOT complete E2E.

Hanyang Package v16 was generated through the existing approved admin workflow:
question binding now succeeds,13 existing-runtime evidence inputs/5criteria;
no question/content identity blockers. Provider rights remain unset, no calls made.


## Applied Oct13 — Owner approved Package read RPC only

Migration20261013115731 APPLIED. Catalog read-back: essay_worker EXECUTE=true,
anon/authenticated=false; authenticator membership remains false; Registry234
unchanged. No Credit/activation/data update. SQL-admin connection cannot SET ROLE
essay_worker; do not bypass by granting membership. Therefore external Worker JWT
read remains unverified. Rollback is worker_read_rollback.sql (revoke only).

### Oct14 historical Package reader — candidate only
`worker_read_history.sql` reuses existing immutable review revisions for exact pinned
digest lookup, keeping current VERIFIED/approval and current rights checks. New
rights are never inferred from old approval. No table/grant expansion. Local test:
`python3 tool/test_material_worker_read.py --history` PASS (historical reuse, hash
tamper, current revocation/blocked state, caller denial). This does not yet change
submit/preflight parent policy selection. Operational application requires Owner
approval; restore `worker_read.sql` for rollback, retaining all review data.
