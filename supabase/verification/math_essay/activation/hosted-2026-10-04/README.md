# MATH-HOSTED-ACTIVATION-1 — 2026-10-04

## Result and authority

**BLOCKED at Owner-controlled runtime credential setup; SQL installation COMPLETE.**
Approved APP a9fec5e / LAB80bcd25 / Wiki f979486. Actual project was independently verified as LegendStudy Production `stlhijzpjfgwwdgunlsd`, PostgreSQL17.6. This is neither Payment TEST nor Muselry. Production schema **was changed** in this task; previous PREP NOT_APPLIED statements are historical.

## Exact execution

Preflight found ledger23, no ADR/Math collisions, canonical prerequisite tables/roles/function ACLs, actual Hosted Storage policy delegation via supautils, bucket INSERT and narrow grant options. `public` remained owned by `pg_database_owner`; Storage tables remained owned by `supabase_storage_admin`. No ownership workaround was used.

Each file below was hash-verified, executed alone, then checked before proceeding:

| File | SHA-256 | Result |
|---|---|---|
|20261001000300_account_deletion_lifecycle.sql|38c86fd79554225fbc6a5a30be791c860e6c89dcaa64ad7e229e3710b9a29d94|PASS|
|20261002000100_math_essay_persistence.sql|73fae66a4a9198885c6bf505ac87d9a3abcc453dd1017e666a217bac486c7d51|PASS|
|20261002000200_math_runtime_surface.sql|b40bf7224a84658308ff1640b639acb857e379998211131d97a688a9711fe049|PASS|
|20261002000300_math_learning_runtime.sql|fa0fbb507dd650d2e684f7dc9bc9375c6c5db09eac64405a438ad63206933f7d|PASS|
|20261004000200_math_storage_erasure_activation.sql|fa5718c586a6affb5ffabbedbccf4f1a6d43c21c7fc91dec1c5e1c4daa654489|PASS|

No SQL bytes changed. First failed migration: NONE. Canonical explicit-version tracking procedure was used only for these five verified files (`migration repair … --status applied`, repairAll=false); ledger23→28 and exact set delta verified. No broad db push, manual ledger insertion, unrelated repair, provider005/day_targets replay or Payment migration.

C:27 empty tables and41 exact function security checks PASS. D:22 public function definitions/metadata match physical catalog; temporary CREATE absent and original memberships restored. E:4 function/security checks,2 exposure tables,3 constraints,2 indexes PASS. Activation:6 new public functions exact owner/ACL/search_path,8 Math Storage policies, private20MiB bucket, worker-only read grant and no browser privileged-helper EXECUTE PASS. Supabase-generated postgres admin-only memberships retain SET=false/INHERIT=false. Authenticator worker enrollment has not been performed.

Math attempts/evaluations/Storage objects=0. ADR dispatch OFF, deletion requests/benefit claims=0. Actual Hosted evaluation INSERT was rejected by MATH_EVALUATIONS_PAUSED before billing/constraints in a rolled-back transaction; evaluations remained0. Nine prerequisite Credit/HQP/account function definitions and security exactly match the post-ADR snapshot. Existing non-Math Storage policies and ownership were retained; intended ADR/avatar restriction is present.

Evidence: adjacent sanitized JSON/SQL snapshots and summary.json. Multi-statement CLI returns only its final SELECT, so consolidated JSON postflights preserve all inspected checks. No actual user rows, credentials, key material or tokens are recorded.

## Runtime boundary — not a Hosted E2E PASS

Production Edge inventory contains neis, process-feedback-notifications and resource-resolver; account-deletion-worker is not deployed. Name-only inspection confirms ACCOUNT_WORKER_JWT, ACCOUNT_RESTORE_KEY and ACCOUNT_DISPATCH_SECRET are absent from Production Edge secrets. No secret values were read. LAB Math worker/provider bindings were not inspected or configured; their presence/readiness is not assumed.

No worker deploy, role enrollment, signing change, JWT mint, Cloudflare change, synthetic account/file creation, provider call, student data or Payment code change. No Math Credit debit/grant occurred. Hosted Storage upload/read/foreign-deny/byte deletion, erasing-user gateway denial, actual model results and Credit -1/0 remain NOT_RUN. Prior local tests remain valid evidence only for local implementation (Math131+37+63+activation37; HQP102; Deno57; LAB424), not remote acceptance.

## Next Owner gate / exact continuation

1. Authorize/select **Production-project** signing/token provisioning for `math_extraction_worker`, `math_evaluation_worker` and the existing `account_lifecycle_worker` boundary. Use finite tokens, server-only; never reuse Payment TEST signing material or substitute a browser service-role key. Before minting, inspect current signing configuration and use the approved offline/Owner-controlled procedure. Verify authenticator SET=true/INHERIT=false/ADMIN=false through the actual gateway matrix.
2. Owner sets runtime secrets directly. LAB approved Math deployment → Settings → Variables and secrets: `MATH_EXTRACTION_WORKER_JWT`, `MATH_EVALUATION_WORKER_JWT`; approved provider candidate is OpenAI, secret `MATH_PROVIDER_API_KEY`. Provider/model (`MATH_PROVIDER=OPENAI`, `MATH_PRIMARY_MODEL`) and paid-call budget require explicit Owner choice. No PRIMARY_MODEL was selected here.
3. Production Supabase → Edge Functions → Secrets: complete the existing account worker configuration from the canonical activation README, including `ACCOUNT_WORKER_JWT`, `ACCOUNT_RESTORE_KEY`, `ACCOUNT_RESTORE_KEY_VERSION`, `ACCOUNT_DISPATCH_SECRET`, checkpoint/notification/operations bindings; review existing finance/lifecycle dependencies. Do not activate a partially configured deletion worker or widen unrelated APP closeout scope. Math cleanup needs `MATH_STORAGE_ENABLED=true` only after that worker is ready. Values stay out of chat/Git/logs.
4. Deploy reviewed worker/gateway default OFF; validate synthetic Auth and narrow role admission, then actual private bytes and fenced deletion. Prepare only reviewed synthetic content/credit state through canonical paths.
5. After explicit provider/model/cost approval, execute the8-case bounded bake-off and Hosted journey, initial Credit-1/included reeval0/new answer-1, foreign/erasing denial, retries and byte erasure. Verify desktop/360px. Enable route only after release approval.

Do not replay installed SQL. Keep SQL admission OFF and server/provider/frontend flags OFF until prerequisites pass. Existing kill-switch/recovery runbook applies; no destructive rollback performed.

## Final status

| Field | Status |
|---|---|
|MATH_HOSTED_ACTIVATION|BLOCKED|
|PRODUCTION_PREFLIGHT|PASS|
|MATH_MIGRATIONS|PASS — exact5/5 installed/tracked|
|R21_STORAGE_HOSTED|BLOCKED — bucket/policy catalog PASS; byte E2E NOT_RUN|
|ADR2_MATH_ERASURE_HOSTED|BLOCKED — SQL installed; worker/byte E2E NOT_RUN|
|WORKER_GATEWAY_HOSTED|BLOCKED — credential gate, not deployed|
|PROVIDER_CONFIG|OWNER_ACTION_REQUIRED|
|REAL_MODEL_BAKEOFF|NOT_RUN|
|STUDENT_HOSTED_E2E / IMAGE_PDF_HOSTED / EXTRACTION_HOSTED / EVALUATION_HOSTED|BLOCKED|
|CREDIT_INITIAL / CREDIT_REEVALUATION|NOT_RUN Hosted; local -1 /0 preserved|
|STORAGE_BYTE_ERASURE|BLOCKED|
|FOREIGN_OWNER_DENIAL|NOT_RUN Hosted gateway; catalog restrictions PASS|
|KILL_SWITCH|PASS — Hosted SQL admission only; server gateway not deployed|
|REGRESSION|PASS scoped Hosted catalog/security; full runtime regression NOT_RUN|
|REAL_STUDENT_DATA|NO|
|PAYMENT_CODE_CHANGED|NO|
|MATH_RELEASE_CANDIDATE|NO|

NOT_RUN/BLOCKED is used for unexecuted checks instead of falsely claiming PASS or asserting a functional FAIL. Unified Wiki Math/Daily updated with this boundary. NEXT: Owner credential/signing and provider cost gates, then actual Hosted smoke. APP deletion/Apple revoke closeout is not expanded in this task.
