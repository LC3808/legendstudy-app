# TASK16 final quality — Inha official solution candidate

NOT_APPLIED. Production requires Owner approval under the 2026-11-04 final-quality request §10.

The original PDF hash matches the stored official source. Pages 1–2 identify natural Q1 and its scoring criteria; page 3 contains the worked example. The body is a math-preserving display transcription with subsection headings, not AI-generated mathematics. No PDF/image is committed.

Scope: one new immutable canonical solution; a guarded replacement inside the existing `if disclosed` branch of `public.math_coaching`. Existing ownership, reveal event/idempotency, ACL, evaluation output, authority pins, considered references, tickets, Ledger and History are untouched. Previously completed assessments receive an explicitly supplementary official reference, not a claim that it was used at assessment time. No pre-reveal answer exposure is permitted.

Before approval: verify current function hash/source hash; run disposable PostgreSQL owner/anonymous/disclosure/ledger regression; inspect APP/WEB labels and source rendering. Disposable PostgreSQL validation passed: 23 disclosure/preservation/rollback checks plus 131 existing runtime regressions. Production is NOT_APPLIED. Do not apply merely because the file exists.

Rollback: reverse only the exact added `refs=refs||...` expression after verifying the deployed function hash; retire the new canonical solution through the existing content lifecycle. Never delete referenced solutions, assessments, exposure history or financial rows. The exact inverse is in `rollback.sql`; it restores the original function and retires (does not delete) the newly linked solution. Tested against the disposable fixture.

## Owner review / application order

1. Approve only `20261104004833_task16_final_inha_official_solution.sql` for Inha 2027 natural Q1. No other university, pricing, Auth, Ledger or evaluation backfill.
2. Re-read the live function hash and official artifact hash. The SQL aborts on drift.
3. Capture function owner/ACL and existing evaluation/reference/ledger fingerprints; apply the transaction.
4. Confirm one ACTIVE official solution. Compare fingerprints; explicitly revealed old results may show the supplemental label, undisclosed results must not contain full_solution.
5. If unsuccessful, use `rollback.sql`; it guards the exact inverse/baseline and preserves all existing IDs and disclosure events.

This does not activate learning-completeness grades. That generation/storage integration remains separate and unverified.
