# MATH-PRODUCTION-ACTIVATION-1 — exact activation candidate

Current Hosted result: [2026-10-04 exact installation evidence](hosted-2026-10-04/README.md). SQL5/5 applied/tracked, runtime OFF, credential/E2E gate; do not replay.

Historical PREP record follows. 2026-10-04. Code/local verification only. **Production NOT APPLIED; live provider calls 0; RC NO pending actual gateway/Storage/model smoke.**

Authority: APP release `0570099c98929b27f8e484210efc14fe061e8476`, LAB Claude consumer `6dec4f98887cee2e7c661996e083289b853054b3`, latest release Wiki `8b6ba25`. APP's five stale tests are already fixed (936 Flutter PASS); they are not new Math debt. This change extends the current fenced deletion worker and preserves its reauth/account-switch work. Separate LAB deletion ref `e512974` is unchanged. Payment files/economics are unchanged.

## Exact installation order

[manifest.json](manifest.json) pins every filename/SHA-256. `python3 supabase/verification/math_essay/activation/verify_manifest.py` verifies bytes, never connects to a DB. Prerequisite inventory is inspect-only; do not replay the local test bootstrap against Production.

1. Confirm LegendStudy Production project identity in the Dashboard, then run [preflight.sql](preflight.sql) READ ONLY. No fresh Production connection was available in this task; previous absent migrations are historical, not a new PASS.
2. Compare the existing core/Essay/Credit/HQP/profile prerequisite chain with manifest. Missing prerequisite or catalog/owner/role mismatch is STOP for a separately reviewed delta. No broad push/repair.
3. If separately approved and still absent, apply `20261001000300_account_deletion_lifecycle.sql` (ADR-2D) first. This is necessary for current user lifecycle locking. Follow its own ownership package.
4. Apply unchanged `20261002000100_math_essay_persistence.sql`, then unchanged `20261002000200_math_runtime_surface.sql`, then unchanged `20261002000300_math_learning_runtime.sql`.
5. Apply additive `20261004000200_math_storage_erasure_activation.sql`. The entire file is one transaction. It creates private `math-private`, exact owner/worker policies, byte admission, fenced erasure, stale-work recovery and a default-OFF evaluation admission control. A bucket/name/function collision is STOP. First SQL error means STOP; never amend owners/ACLs to make it pass.
6. Run existing C/D/E catalog/postflight plus [postflight.sql](postflight.sql). Compare to each package's inventory with the single intended additive `postgres EXECUTE` grant on the Math-only `math_private.release_billing(uuid)` helper. The existing helper body/Ledger functions remain unchanged. [ownership.json](ownership.json) pins new helper owners/executors; membership snapshot must be identical before/after. New Storage grants are only schema USAGE and objects SELECT for extraction worker; no browser Math table grants.
7. Confirm no attempts/evaluations/private objects, admission OFF. Migration ledger tracking is separate from SQL execution and requires the Owner's existing exact tracking procedure, never repair/broad db push.

Hosted Storage table ownership/ACL/policies are **not reproduced by the local metadata fixture**. Preflight must confirm the actual executor can create policies on `storage.objects` and insert bucket metadata without changing ownership. If that is false, STOP for compatibility review; do not grant broad platform-role membership. Existing unrelated permissive policies are constrained for authenticated/anon Math access by restrictive policies.

## Runtime enable sequence (separate approval required)

1. Deploy the current account-deletion worker with `MATH_STORAGE_ENABLED=true` only after the new helper exists. Keep canonical gateway/Auth admin credentials server-only. Verify real owned Storage bytes → recursive delete → empty re-list → fenced Math row cleanup → existing ADR DB/Auth sequence. Fault injection must leave metadata and lease-retry possible. The flag defaults false for compatibility; Math must not launch while it is false.
2. Independently validate Hosted JWT admission for `math_extraction_worker` and `math_evaluation_worker`. Only separately approved `authenticator` memberships with SET=true, INHERIT=false, ADMIN=false and approved short-lived signed role tokens. This package performs **no enrollment or minting**. Browser/anon/authenticated must fail privileged helpers; owner RPC and wrong owner/erasing user checks must be exercised through the actual Data API.
3. Deploy LAB branch Pages Functions `/api/math/upload`, `/api/math/extract`, `/api/math/evaluate` together with `/math/` frontend. Keep `NEXT_PUBLIC_MATH_ENABLED=false`, server `MATH_ENABLED=false`, `MATH_PROVIDER_CALLS_ENABLED=false`, and SQL admission false initially. No model default is selected.
4. Owner configures bindings from LAB runbook. Run the controlled synthetic model gate; select model only from evidence. The OpenAI Responses adapter is a candidate implementing the existing MathEvaluatorAdapter, not a PRIMARY_MODEL decision.
5. Approve restricted synthetic smoke, then enable server flags + SQL admission for that smoke window. Verify file/MIME/hash admission, owner-only read, extraction/correction/finalization, initial Credit -1, one eligible reevaluation +0 within336h, history, duplicate finalize and malformed fail-closed. Do not import real students or grant a separate Math wallet.
6. Re-run private Storage byte deletion and account deletion against Hosted API, including failed remove and retry. Confirm same-account session restore and foreign owner denial through browser + gateway.
7. Only after smoke PASS and Owner release approval, rebuild with `NEXT_PUBLIC_MATH_ENABLED=true` to expose the existing Essay LAB link. Current branch defaults OFF. APP Store readiness and LAB account-deletion deployment remain their own gates.

## Kill switch / recovery / rollback

Owner-approved emergency SQL: `update math_private.runtime_control set evaluations_enabled=false where singleton;`. It blocks new evaluation inserts before billing reservation; history/results remain readable. Then set server `MATH_PROVIDER_CALLS_ENABLED=false` to stop further provider work and rebuild frontend flag false if hiding entry is desired. Do not delete objects/results or manually edit Credit.

An abandoned REQUESTED request older than5minutes or PROCESSING lease past expiry is recovered by exact worker RPC `math_recover_evaluation(p_id)`; it calls the existing canonical reservation release and sets FAILED/TIMEOUT, never debits or changes completed results. Enumerate overdue IDs through authorized operator access; run bounded batches, retry safely. No scheduled remote job was configured here. In-flight response timeout is ambiguous: first re-read canonical state, never compensate a possibly committed finalize. A FAILED evaluation is retried with a new request ID; completed duplicate requests reuse canonical results. Recovery works while new admission is OFF. Erasing-owner work is handled by fenced account cleanup, not a bypass of lifecycle checks.

Before traffic, a failed migration transaction rolls itself back (tested injected failure before COMMIT with exact prior function/schema/membership restoration). After use, operational rollback means **OFF + drain/recover + forward fix**, not DROP/CASCADE or metadata deletion. Canonical empty C/D/E rollback files remain available only for a separately approved verified-empty install, in reverse order after reviewing new dependent objects. This package does not authorize Production destructive rollback.

## Storage and erasure contract

Private bucket:20MiB PNG/JPEG/WebP/PDF. The server obtains artifact path from the canonical DB using verified subject; browser cannot nominate foreign path or subject. Storage POST uses owner JWT, no upsert. Owner SELECT needs PRESENT state; extraction worker can read registered/present owned evidence only while its account is active. Admission requires a complete byte reread, size/MIME magic/SHA verification before metadata becomes PRESENT. No public fallback or persistent signed public URL. Browser local previews use revoked blob URLs; private reads require finite Auth tokens.

The deletion worker recurses the subject UUID prefix, including orphan files, with depth/request bounds and page-zero relisting after each remove. Only after actual Storage absence does SQL mark ABSENT_VERIFIED, release any outstanding Math reservations and cascade attempt/extraction/evaluation/artifact/learning/hint/solution/resolve/quality relationships under ADR-2D. Foreign bytes remain untouched. Active-account incomplete uploads remain retryable evidence, not silently purged by a speculative retention rule. A public orphan/retention policy has not been invented.

## Verification and limitations

`MATH_LAB_WORKTREE=/path/to/legendstudy-lab python3 tool/test_math_activation.py --pg-bin /path/to/postgresql17/bin`: real canonical PG17 chain, non-superuser migration execution, exact prior memberships, injected rollback, helper ACL/owner/search_path, owner/foreign/erasing denial, byte-before-row ordering, populated graph erasure, switch before billing, stale recovery. Actual SQL claim → LAB physical adapter → canonical SQL finalize proves initial -1 / included reevaluation0. Existing131 Math +37 runtime +63 learning checks are retained; unchanged102 Humanities/HQP assertions also PASS after the full activation migration (`tool/test_math_activation_legacy.py`); see generated artifacts. Deno worker/deletion suite57 PASS (synthetic Storage HTTP ports). LAB complete tests, handlers, build and responsive evidence are recorded in its closeout doc.

Local Storage catalog is a **fixture**, not real Hosted byte service. Browser route verification used synthetic transport. No actual Hosted Math gateway, provider quality/accuracy, physical mobile keyboard or real student E2E PASS is claimed. Production preflight, private credential provisioning, deployment, cost approval, controlled model bake-off, content/profile activation and Hosted end-user smoke remain Owner/external gates. No Production writes, Toss calls, payment changes, Store upload or main merge.

## Seven preservation answers

1. Existing attempt/extraction/evaluation/reveal timestamps and correction lineage remain canonical.
2. Frozen evaluation pins and confirmed input are preserved; new model execution cannot rewrite completed facts.
3. Re-solve appends a new attempt; current UI state does not replace historical records.
4. Owner identity is verified Supabase Auth subject, never a browser-supplied account id.
5. Input, evaluation interpretation and learning actions remain distinct; quality review is operator-only.
6. Private evidence stays owner-scoped; ADR erasure removes actual bytes before metadata. No real student fixtures or unapproved retention change.
7. Model assessment/progression remain derived versioned output; canonical validation and Credit eligibility stay server-owned. No fake official score or client-made eligibility.
