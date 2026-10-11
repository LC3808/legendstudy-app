# Oct11 runtime activation impact / rollback review — NOT APPLIED

This packet is for the Owner's explicit pre-production review, not authorization.
The runtime/catalog implementation makes no production data or permission changes.
Existing QA metadata and Math recovery migrations remain separate, pending changes.
Do not run bulk `supabase db push` or the isolated content importer on Production.

## Read-only preflight observed in this task

LegendStudy project `stlhijzpjfgwwdgunlsd`: general questions0/evaluations0; canonical
claim/success/failure RPCs present. Math COMPLETED8/FAILED1, no other evaluation
state observed. This is not a full Credit-ledger reconciliation or new E2E.
Cloudflare project `legendstudy-lab`, current production deployment
`a2e09fea-6472-407b-b0f9-036642a6ed69`, source `501d272100b78032400bb82a8da0bfa963c10e31`.
MATH_ENABLED=false, MATH_PROVIDER_CALLS_ENABLED=false; ESSAY_REVIEWED_RUNTIME_ENABLED,
MATH_RECOVERY_ENABLED and MATH_RECOVERY_BATCH_ENABLED unset. Existing allowlist
present, worker secret configured but opaque: JWT validity/expiry NOT verified.
These observations are snapshots, not permanent guarantees. No environment updated.

## Required decisions / implementation before activation

1. Content owner verifies permitted private Provider processing vs student display
   separately for the retained SKKU2025 humanities1 package hash
   `v1-sha256:bac7afbcbc2d11c18360d464d687065abf32a242d2a8545ad8fb3b1935576fd4`.
   Official source links alone do not prove that the retained package's existing
   rights HOLD can be released. Q1 supports text; Q2/Q3 still require graph handling.
2. Approve exact **unpublished** controlled content import after production SQL is
   prepared/reviewed. Current plan contains3 questions,9 criteria and34 evidence
   relations from21 excerpts. Existing university/exam/resource IDs stay fixed.
   No production SQL for content is approved or executed by this packet. The current
   importer intentionally only accepts temporary Unix-socket test databases.
3. Compose private host callbacks: online caller Auth + existing allowlist, owned
   RLS evaluation/snapshot/answer read, caller RPC, narrow worker RPC, current
   provider-policy binding, independent SignedReview source and receipts, durable
   per-evaluation lock/checkpoint journal. RuntimeHost + Pages binding are implemented;
   this deployment composition and isolated Auth/PostgREST proof remain incomplete.
   `preflight` must verify these dependencies before admission, not just flags.
   Use existing provider/model policy and current prompt; do not invent credentials,
   allowlist members, reviewer keys or ready=true. No new evaluation engine.
4. Renew/verify existing narrow Worker JWT through its established operations path;
   read API masks the secret, so configured does not establish a valid token.
5. Only after these pass, seek a bounded live test: existing approved review account,
   SKKU Q1 initial + one first same-answer rewrite within14 days; maximum1 Credit
   on initial success, zero additional Credit for included reevaluation. No automatic
   new charge on timeout. Capture baseline, reservations/settlement, request identity,
   stored feedback, WEB/MY + APP shared read contracts and admin review evidence.
   This packet proposes that scope; it does not claim the transaction is approved.

## Impact / rollback

- Public42-university metadata is now authorized by the Oct11 catalog request;
  this does not publish question bodies or activate any evaluator.
- Catalog deployment can be rolled back to the prior Pages deployment without DB
  rollback. However current branch includes earlier QA metadata consumers awaiting
  their paired migration approval; do not silently deploy the entire branch around
  that pending review. No production deployment was made in this task.
- Future content import must be transactionally preflighted, conflict-aborting and
  initially unpublished; a rollback before usage may remove only newly inserted
  manifest IDs after reference checks. Once any attempt exists, retain source and
  History: stop admissions/unpublish approved new questions, never delete evaluations.
- For a future runtime stop: disable new admission/provider calls, keep owned status
  and existing canonical reconciliation available; replay trusted durable finalize
  checkpoints only. Never guess completion, double-reserve or synthesize a release.
- Credit Ledger, Math engine, Payment/Toss/IAP, RLS and student data are unchanged.
  General public activation HOLD and existing allowlist remain mandatory.

Local tests:26 Python contract tests (synthetic transport),1014 WEB tests +1 optional
private-source fixture skip; lint/typecheck/boundary/build pass. No actual Provider,
new Credit transaction, real Auth/PostgREST host test or production permission PASS
is inferred from these tests. See canonical Wiki for UI mapping and browser proof.
