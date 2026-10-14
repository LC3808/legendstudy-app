# Hanyang first-exam execution policy — applied 2026-10-14

Owner confirmed transmission rights for the two reviewed PDFs to OpenAI for evaluation and independent review. This is **not** authorization for operating SQL application, Provider calls, Credit transactions or public activation.

## Application record

Owner approved the exact rights/model-policy scope. Applied migration `20261014064346_essay_hanyang_reviewed_execution_policy`; do not reapply. Operating Worker role read returned Package17; preflight pinned its digest; Registry234. Hash/content preservation true, both function ACLs unchanged (`postgres` only). Runs0/checkpoints0.

Digest: `40ef4e7bbe5295facf146946b7f1924f086ff6e540108a3def8efb22e37ba4ae`.

Worker disabled deployment `f27efa26-42ef-4102-ad87-3d048d4363d6`: independent review mode and model bindings configured; prior Secrets preserved. Worker execution false, Pages flag unset/off. Still missing Owner-entered `ESSAY_PROVIDER_KEY` and `ESSAY_REVIEW_VERIFY_KEYS`. No Provider/Credit call.

## Original approved application instructions

In LegendStudy Supabase (`stlhijzpjfgwwdgunlsd`) SQL Editor, run `install.sql` once after approval.

Scope:
- Exact Hanyang 2024 admission humanities afternoon2 exam `345d3caa-3438-58c3-8f80-62a6242179ec` only.
- Preserve reviewed v16 and all content. Append v17 changing only two document transmission-right records, version and digest.
- Replace the two existing null-returning private policy functions with one exact-exam/digest policy and one exact-regime Provider binding.
- Reuse the existing pilot model `gpt-5.6-sol`, prompt `scaffolding-1.3-v3`, contract1.3. Runtime verifies Provider response metadata; actual project model access has NOT been tested.
- No new tables, grants, deletion, Registry edits, Ledger mutations, Provider calls or execution flag changes.
- This removes the DB policy barrier for this exam. Worker/Pages execution flags must remain false and allowlists unchanged until separately authorized E2E.

Guardrails: exact revision16/digest/documents, verified review/approval request, no existing exam runs, and both existing policies still null. Reapplication or later Owner edits abort the transaction.

## Verification

`python3 tool/test_hanyang_policy_candidate.py` uses a disposable local PostgreSQL17 instance and synthetic content, under a non-superuser role. PASS: rights-only v17, exact exam restriction, binding hash, preserved revisions/content, repeat refusal, rollback v18, zero runs. This is not operating DB evidence.

After application, run `verify.sql`; it returns state/hash/rights booleans and policy metadata only, never PDF contents or secrets. Do not submit an evaluation during verification.

## Rollback

Turn Worker and Pages execution flags OFF. Run `rollback.sql` only if current revision is the candidate v17 with its pinned hash. It appends v18 with transmission status revoked and restores both policy functions to null. Retains every previous revision, Registry, runs, History and Ledger. Later edits intentionally require manual review; rollback never overwrites them.

## Worker configuration (prepare only)

Existing JWT/service secrets and Queue bindings remain unchanged. The independent review path uses the same Cloudflare host, a separate Responses request and the existing SignedReview contract. No automatic passing or extra service is needed.

Non-secret variables after policy approval:
- `ESSAY_REVIEW_MODE=independent_model`
- `ESSAY_REVIEW_BINDING={"reviewer_id":"openai-independent-v1","model":"gpt-5.6-sol","model_version":"gpt-5.6-sol"}`
- `ESSAY_PROVIDER_BINDING`: exact six-field binding returned by `verify.sql`.
- `ESSAY_EXECUTION_ENABLED=false` (keep HOLD).

Owner-entered Secrets in `legendstudy-essay-reviewed` only:
- `ESSAY_PROVIDER_KEY`: existing authorized OpenAI project API key.
- `ESSAY_REVIEW_VERIFY_KEYS`: JSON map with `openai-independent-v1` mapped to a newly generated random secret of at least32 bytes. This signs/verifies review receipts server-side, never enters model requests, client code or Git.

Do not paste secret values into chat. Actual evaluation + independent review means two Provider requests per single-question attempt; initial + free reevaluation therefore normally four requests, with no automatic model retry. Costs and operating Credit test authorization will be proposed separately before enabling anything. Same-model independent review is a separate request, not a claim of human quality certification.

Official model reference: https://developers.openai.com/api/docs/models/gpt-5.6-sol
Structured response contract: https://developers.openai.com/api/docs/guides/structured-outputs?api-mode=responses
