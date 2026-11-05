# TASK20 priority natural questions — Owner application candidate

2026-11-06: isolated contracts / 12 approved real-provider tests PASS.
Production NOT_APPLIED. APP65 unchanged. No store submission.

## Exact scope

- Existing 건국2026자연 Q1: retain its IDs, content, legacy binding and history.
- Add 건국 Q2–Q4 and 경희2026자연 Q1–Q3: **96 immutable content rows**, 6 sets/problems/leaves/profiles/solutions, 24 source references, 20 criteria, 22 solution steps. See `manifest.json` for per-question hashes/IDs.
- Existing 72 released leaves retained; proposed catalog 78. Modify only `math_private.release_catalog(uuid)` and `math_private.evaluation_admission()` allowlists; owners, grants, signatures, runtime switch and all financial functions unchanged.
- Shared WEB/APP API: append two exact Math exam entries in `web.patch`, append six IDs to `MATH_PUBLIC_LEAVES`, ensure the two exam IDs are in `ESSAY_PUBLIC_EXAMS` and `ESSAY_BETA_EXPANSION_EXAMS`. Preserve every existing value and deployed page/route. No APP rebuild required.
- Existing question-only PDFs retained: 건국 4-page asset `5e05b051e98861969409d99073e7bb535add2a530aa38204241d5445c02dba10`, 경희 2-page asset `0e3ec8d9cea7904c6e7416a92f47514307c6780f774c6ba9b2934ce256faf471`. Storage existence verified read-only. No rubric/answer PDF publication or new Storage upload.
- No changes to Registry publication flags, beta grant policy/eligibility, Credit, payment, refunds, Auth, RLS or existing evaluations.

## Private executable files

Official text must not be committed. Exact files under repository `.local/task20-priority-20261106/`:

1. `packages/register.private.sql`: 96 DRAFT rows, same-byte replay permitted; abort on different existing content/Registry identity or another leaf bound to any of the six questions.
2. `activate.private.sql`: assert all 96 DRAFT contents and both production function hashes, activate 24 state-bearing rows, add six allowlist entries in two functions, one transaction.
3. `rollback-release.sql`: guarded restoration of the two previous definitions. Keeps new content ACTIVE to support in-flight jobs, but removes new admission/catalog visibility. Never deletes results, attempts or ledger.

Hashes are in `private-artifact-sha256.json`. These files have been executed only in disposable PostgreSQL17.

## Apply sequence — requires separate Owner approval

1. Resolve overlapping TASK20-C work: inspect both current function hashes and all six question bindings. Reuse an already reviewed equivalent package; **do not apply two competing packages**. Candidate fails closed if another binding already exists.
2. Re-run `preflight.sql`; require current reviewed function hashes and all existing72 mappings unchanged. Save protected table counts/hashes and function ownership/ACL, current WEB manifest/environment/deployment.
3. Apply exact registration SQL, then activation SQL. Run `postflight.sql`: 건국4 / 경희3, total78, all six new profiles ACTIVE, existing72 tuples and protected hashes preserved.
4. Merge only `web.patch` into the latest production WEB checkout after checking concurrent changes. Re-run route tests/build and preserve existing deployment routes; append approved environment scope values, then deploy WEB.
5. Read-only ordinary-user WEB/APP65 verification: seven exact question→leaf mappings, question PDF open, drafting entry, all-four/all-three selection and availability. No real student evaluation/grant/charge/purchase/refund during these checks.
6. Runtime authenticated/physical-device acceptance remains NOT_VERIFIED until steps3–5. A TEST provider pass is not a production E2E pass.

## Rollback

Remove only the six new environment leaf IDs and two newly added expansion entries (restore exact previous values); restore the guarded SQL definitions. Do not revert another task's concurrent release. If hashes changed, stop and rebase rollback after review. Keep APP65, all 96 content rows, in-flight jobs, History and ledgers. Existing Q1 and other72 released bindings remain.

## Evidence

- `provider-quality-summary.json`: 12/12 real calls, good/wrong classification and domain contract PASS; 57,206 input /29,245 output tokens. No additional calls approved or executed.
- `isolated-contract-report.json`: seven question contracts, free rewrite0, replay/foreign access, duplicate binding rejection, exact apply/rollback; all12 actual outputs finalized/read in isolated SQL. Synthetic TEST credits only; production writes0.
- APP31 / existing WEB74 / new WEB candidate7 tests PASS; canonical Math regression suite PASS (local).
- Limits: normal reference-based answers and an obvious wrong answer per question; no new handwriting/OCR/alternate-solution/real-user production E2E claim.
