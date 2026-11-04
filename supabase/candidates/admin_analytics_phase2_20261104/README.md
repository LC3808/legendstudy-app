# Phase 2 deployment package

Owner authorized implementation, isolated TEST and production SQL/RPC + WEB on 2026-11-04. APP58/builds and actual financial transactions excluded.

Apply in order: migrations `20261104085951_admin_analytics_phase2_quality.sql`, `20261104090610_admin_analytics_phase2_learning.sql`. Never replay once hosted. Existing cost function baseline MD5 must equal `ec592182a7d0a87c685b0b58c12ad8c7` before replacement. Existing HQP source constraints inspected in production; new domain retains all original FKs, RLS, immutability and correction uniqueness.

Seven preservation answers: retain event timestamps; reference run/question originals; never backfill results; reuse credit account owner identity; distinguish human quality from learning levels; existing Q/admin + account lifecycle gates; version derived read projections with explicit missing/coverage and minimum cohorts. See canonical Phase 1 preservation review.

HQ exam rubric v1 reuses six named HQ dimensions with OK (supported), CONCERN (requires checking), FAIL (evidence demonstrates failure). Sentence/progression/generated rewrite are NA because this form does not perform those three reviews. This is a separate version from legacy/Math rubrics, not a numerical score; no inter-reviewer agreement metric is claimed. Missing output/frozen version/criteria forces NEEDS_REVIEW. Findings target the original whole question; detailed target taxonomy remains the original bounded HQP vocabulary. Optional issue/regression URLs are links, not proof of policy deployment. No issue is sent externally.

TEST: `python3 tool/test_admin_phase2.py` creates disposable local PostgreSQL with synthetic identities. Checks actual validators and HQ tables/trigger, new RPCs, role denial, lifecycle denial, replay/conflict, hash mismatch, correction conflict, original preservation, erasure cascade, cohort protection, cost retry base 0/1 and unknown values. It does not claim hosted gateway or Provider E2E.

Rollback: restore previous Pages deployment; revoke new RPC access with rollback.sql; optionally restore cost-before.sql after checking no newer definition. Keep new HQP columns and all review records. No ledger reversal or original result mutation is required.
