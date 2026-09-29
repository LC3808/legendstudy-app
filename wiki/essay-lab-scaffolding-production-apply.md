# Essay LAB — Scaffolding / submit timing Production apply

2026-09-29 · **PRODUCTION_DEPLOYED / POST-APPLY PASS**. Owner explicitly authorized
both forward migrations at approved commit `6816642`; isolated validation ACCEPTED.
[Sanitized evidence](../supabase/validation/essay_lab_product/scaffolding_production_result.json).
No student data or AI execution. Owner SQL Editor action was not required.

## Preflight and exact apply

Linked project matched LegendStudy Production. All19 local migration files matched
approved commit bytes;17 remote versions matched, exactly two pending. Existing
47 catalog definitions and full [security contract](essay-lab-security-resolution.md)
passed. All19 Product tables were empty. Canonical counts/fingerprints matched the
accepted security-resolution baseline; orphan counts0. No unexpected drift.

`supabase db push --linked --skip-vault --dry-run` listed only:

- `20260929000100_essay_scaffolding_persistence.sql`
- `20260929000200_essay_submit_timing_correction.sql`

Seed list and role-bundle list were empty. One normal
`supabase db push --linked --skip-vault --yes` succeeded for exactly those files.
No repair, replay, old migration edit, direct ledger write, seed or role bundle.
Both files retain their approved hashes. Their original NOT APPLIED comments are
historical preparation metadata; this readback report establishes deployment.

## Read-only post-apply

| Check | Result |
|---|---|
| Migration ledger / local-remote / pending |19 /MATCH /0 |
| Product tables / RLS |KEEP19 /19 enabled |
| New column |`essay_improvement_progress.scaffolding_observation jsonb NULL`, no default |
| Strict envelope CHECK |Exact validated runtime catalog match |
| Submit timing |Approved function source exact; NULL-preserving CASE + floor |
| Existing object definitions |47/47 match updated validated disposable catalog |
| New private functions |9/9 approved source exact; total functions37/public RPCs12 |
| Old function signatures / owners / ACL / search_path |Unchanged |
| Existing policies / table privileges / helper correction |Unchanged |
| New helper EXECUTE |Denied to anon/authenticated/service_role/worker/finance |
| Managed membership / schema CREATE boundary |Exact accepted contract /revoked |
| v1.2 |Original request/claim/finalize bodies byte-exact under private legacy names |
| Existing Product rows |All19 counts0, before=after |
| Backfill/evaluation/observation/student creation |None |
| Canonical and Product FK orphans |0 |

All100 named catalog/preservation checks passed. Static32+55, Wiki links/budget,
diff and secret/UUID checks also passed. Production validation was
READ ONLY: no synthetic/Owner/student submission, negative-write probe, new
login test or AI request. The accepted isolated PostgreSQL and actual local
JWT/PostgREST results remain behavioral evidence; catalog comparison is not
reported as a new Production runtime test.

The updated47-object expected catalog was read from the previously validated
local disposable DB. Its server was stopped afterward. Private helper sources
were also compared directly with the approved migration; unchanged24 function
bodies and all existing function privilege/signature metadata were preserved.

## Canonical preservation

| Relation | Before | After | Full-row aggregate fingerprint |
|---|---:|---:|---|
| universities |5|5|UNCHANGED |
| essay_exams |21|21|UNCHANGED |
| essay_exam_resources |134|134|UNCHANGED |
| resources |10556|10556|UNCHANGED |

Existing canonical/Pilot mappings were not changed. No private row contents,
user UUIDs, credentials or tokens are in the committed artifact.

## Decision and next boundary

SCAFFOLDING_PERSISTENCE: **PRODUCTION_DEPLOYED**.
SUBMIT_TIMING_CORRECTION: **PRODUCTION_DEPLOYED**.
PRODUCT_SCHEMA: **DEPLOYED**.
READY_FOR_SCAFFOLDING_AI_PILOT: **YES — only after separate Owner authorization**.
SCAFFOLDING_AI / REAL_STUDENT_TRAFFIC: **NOT_ENABLED**.

Privacy/provider/retention, independent trusted review workflow, worker deployment,
backup/storage erasure, actual UI connection and real-student release gates remain.
No activation is implied by schema deployment. STOP after Wiki/commit/push.
