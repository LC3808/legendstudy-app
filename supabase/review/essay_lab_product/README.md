# Essay LAB Product Phase 1 review package

**REVIEW SOURCES PRESERVED / PROMOTED COPIES / NOT APPLIED.**
Owner approved promotion after Phase2A/2B/2C. [Formal package and current gates](../../../wiki/essay-lab-migration-promotion.md).
Historical review notes below do not override that approval; Production apply remains separately gated.

Final history review recommendation: **KEEP19**,0 moved/merged. See
[full matrix and rationale](../../../wiki/essay-lab-final-schema-review.md).
`final-review-validation.json` supersedes current check counts, while the original
`validation-report.json` is preserved as the5497498 Phase1 review record.
`history_queries.sql` provides12 SELECT templates; [runtime package](runtime/README.md)
contains an executable disposable-PostgreSQL fixture and18 required validation gates.
Phase2A actual PostgreSQL17.11 runtime PASS: [result](runtime/runtime-result.json).
One PL/pgSQL variable-name correction; KEEP19, no invariant weakened. Earlier static reports remain historical.


- [Product spec](../../../wiki/essay-lab-product-v1.md)
- [Recommended architecture, ERD, table decisions, Q1–Q20, 15 cases](../../../wiki/student-analytics-data-architecture.md)
- `001_student_essay_product.draft.sql`: 15 tables; canonical questions/evidence/criteria,
  private targets/learning/results/events/operational AI runs; explicit RLS/grants.
- `002_entitlements.draft.sql`: 4 tables; logically separate commercial subsystem; depends on001.
- `preflight.readonly.sql`: exact catalog-only Production read; no mutation statements.
- `current_schema_inventory.json`: sanitized catalog snapshot, no private rows/secrets.
- `validation-report.json`: precise checks, limitations and 15-case disposition.
- `test_validate_drafts.py` + `test_history_review.py`:30 offline positive/negative checks.
- `validate_drafts.py`: PostgreSQL AST/static structural checks; no DB connection.

Review sources remain here; matching promoted copies now exist in `supabase/migrations`. Do not apply without separate approval.
No replay guards: existing names should fail rather than hide drift. All new tables have PK,
FK/CHECK/UNIQUE where relevant, timestamps and RLS. Existing canonical mappings use a composite
PK; SQL references that actual key, not an invented mapping UUID. Phase2B003 adds four identity/lease columns to three proposed tables; no existing Production table changes.

**Phase2B:** [server transaction report](../../../wiki/essay-lab-server-transactions.md),
[results](runtime/server-result.json), `003_server_operations.draft.sql` (12 RPCs, KEEP19).
Actual local Supabase Auth/PostgREST and Owner shared identity PASS; deployment/retention gates remain.

**Historical pre-promotion checklist (technical gates accepted):** Owner review; local PostgreSQL17 with Supabase roles/auth.uid fixtures;
validated server submit/finalize/billing/erasure RPCs and worker authorization; concurrency/timeout
reconciliation; fixture tests for cross-owner, cross-question and cross-account forgery;
RLS anon/owner/other/service tests; source/rights/privacy release review. Current SQL is a schema
proposal, not a complete deployable billing engine. Required cross-row transaction invariants
are explicitly in architecture; CHECK constraints do not implement account locking or policy.

**Local-only runtime strategy (executed in Phase2A):** isolated PostgreSQL/Supabase DB, synthetic auth users
A/B and public resource fixtures, apply both drafts, verify grants/constraints/state paths, rollback
fixture transaction or discard only the disposable DB. Never load Owner/private Pilot answers.
Do not run this DDL in Production even within rollback. Dedicated disposable PostgreSQL17.11 now verified; schema/reference protocol PASS.
Phase2B review RPC and actual local Supabase JWT/PostgREST verification now PASS; deployment remains pending.

Static invocation (pglast8.4 used in a temporary venv; parser success does not establish PostgreSQL17/Supabase runtime behavior):
`python3 supabase/review/essay_lab_product/validate_drafts.py`
Also run `python3 tool/check_wiki_handoff.py` and `git diff --check`.

Rollback approach after future approval: don't destructively roll back retained student data.
Stop new writes, preserve private/financial records, review a forward fix. No DROP/TRUNCATE
rollback SQL is supplied. Migration promotion, actual apply and runtime verification are separate
Owner-authorized work, not implied by commit/push of this review package.
