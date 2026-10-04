# Math Production activation candidate — 2026-10-04

APP release0570099 is the current deletion/erasure integration authority; the prior five Flutter failures are fixed,936 tests PASS. This task changes no Flutter/Payment implementation and does not repeat the full release audit.

[Exact activation package](../supabase/verification/math_essay/activation/README.md) contains ordered hash allowlist, read-only Production preflight, postflight/ACL inventory, private Storage, account erasure binding, worker roles, kill switch/recovery and rollback boundaries. Existing MATH-2C/D/E SQL bytes remain unchanged. A new separately applied activation migration extends the current fenced account-deletion worker. Actual byte removal and empty re-list precede Math rows; failure remains retryable.

[LAB candidate](https://github.com/LC3808/legendstudy-lab/blob/codex/math-production-activation-1/docs/architecture/MATH-PRODUCTION-ACTIVATION-1.md) reuses Claude consumer6dec4f and adds default-OFF student route and physical SQL adapters. Real PG17→LAB adapter→PG finalize verifies initial -1/included reevaluation0. No separate wallet or fee-policy change. Deno57 checks PASS; local PG Math/legacy/erasure/ACL/recovery checks PASS. Local fixture evidence is not Hosted gateway or byte-service acceptance.

MATH_CONSUMER: COMPLETE. MATH_BACKEND_ACTIVATION_PACKAGE: COMPLETE (code/local evidence). MATH_STUDENT_ROUTE: COMPLETE (local synthetic integration). PRODUCTION_APPLIED: NO. LIVE_PROVIDER: NO. MATH_RELEASE_CANDIDATE: NO until fresh Production preflight, actual role admission/private Storage/account erasure, model selection/cost approval and controlled end-user E2E pass. Current deployment remains OFF. Production writes0; live calls0; student dataNO; Payment codeNO.

Next: Owner/ChatGPT review → separately approved exact activation → provider secret/cost/model gate → synthetic smoke and actual private bytes/credit checks → route enable/release. No owner/ACL normalization, broad push, migration repair, signing change or Store work is bundled here.

## Hosted execution — 2026-10-04 (supersedes PREP deployment status)

Production preflight PASS; approved ADR + Math C/D/E + Storage activation exact5/5 installed and tracked (ledger23→28). Ownership/ACL preserved, private bucket installed, Math rows/objects0, admission OFF; Hosted SQL kill switch PASS. Actual worker/byte/model E2E BLOCKED at Owner runtime credential gate; RC NO. No provider calls or Payment code changes. [Hosted evidence and continuation](../supabase/verification/math_essay/activation/hosted-2026-10-04/README.md). Do not replay installed files.
