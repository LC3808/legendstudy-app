> Superseded by Owner A decision (2026-10-14): no Linux/container host. See `tool/cloudflare_essay/README.md`. Historical host notes below are not the current execution plan.

# Existing ReviewedRuntimeWorker host connection

Status: NOT DEPLOYED. Cloudflare Pages production inspection on 2026-10-14:
Registry JWT present; service binding, ESSAY_WORKER_ORIGIN and
ESSAY_WORKER_SERVICE_TOKEN absent. ESSAY_EXAM_RUNTIME_ENABLED absent/OFF.
No secret values read back or logged. No Provider/Credit call.

## Minimum host prerequisite

Reuse a LegendStudy-only Python/Linux host with persistent, private POSIX storage.
`DurableJournal` requires fcntl/flock, atomic rename and fsync. Do not mount it on
an ephemeral Workers/Container filesystem, or assume R2 FUSE preserves these
locking/durability guarantees. The current code does not implement a distributed
journal. Use a single host until that contract is explicitly implemented/verified.

Cloudflare Pages continues to be the existing authenticated gateway. Supabase
continues to be the Registry/Package/Ledger/History backend. No new evaluator.

## Host composition

Mount the WSGI callable returned by `operating_host.compose_host` behind the
host's existing production WSGI server/TLS ingress. No development WSGI server
is approved as production. Supply the existing canonical registry, exact approved
Provider binding, independent SignedReview verifier and actual review/receipt
services; do not substitute fixture callbacks or self-sign output.

- `OperatingTransport`: fixed LegendStudy origin, publishable key, essay_worker JWT,
  existing allowed test subject list. Worker JWT is distinct from user JWT.
- `journal_path`: private persistent directory (owner-only 0700).
- `service_token`: host secret shared only with the Pages secret below.
- `provider_key`: host-only Provider credential; never a NEXT_PUBLIC value.
- `enabled=True, admission_only=True`: service-authenticated admission checks only.
  Both execution paths reject before claim/provider/finalization. Default composition
  has `enabled=False, admission_only=True`.

The host currently requires independently reviewed binding/rights and configured
review services even for admission. These prerequisites are not provisioned by
this document. DB model/runtime policies are null; approved Package currently
lacks Provider transmission approval. Do not call these ready merely because a
callable was constructed.

## Owner configuration after a real host exists

Cloudflare → Workers & Pages → legendstudy-lab → Settings → Variables and Secrets
→ Production:

1. `ESSAY_WORKER_ORIGIN`: deployed HTTPS origin only, no path/query/credentials.
2. `ESSAY_WORKER_SERVICE_TOKEN`: Secret; exactly the same value as host service_token.
3. Preserve `ESSAY_REGISTRY_WORKER_JWT`, Math settings and current allowlist.
4. Keep `ESSAY_EXAM_RUNTIME_ENABLED` absent/OFF. Do not enable submissions to test
   connectivity. No proposed configuration should make Credit reservations.

Alternative existing service binding: `ESSAY_REVIEWED_WORKER`; only use it when
an actually deployed compatible host exists. A binding name alone is not a host.

## Acceptance before a separate Provider/Credit approval

- Real Cloudflare gateway → service-authenticated host → online user Auth/allowlist.
- Host `/exam-admission` → Supabase preflight and exact Package → existing Worker
  authorize; no reservation, claim or Provider generation.
- Wrong service token/user denied. `/exam-evaluate` and `/evaluate` return
  EVALUATION_EXECUTION_HELD in admission-only mode.
- Verify persisted checkpoint survives host restart without redispatch.
- Report local synthetic checks separately from actual operating HTTP proof.

Current local evidence:13 focused host/transport tests PASS. Actual host admission
HTTP remains NOT_RUN. No operating configuration changed. Additional DB/model/
rights changes need a concrete separately approved scope.

Rollback: remove Pages origin/binding (leave evaluation flag OFF), stop host;
retain private journal for recovery. No Ledger or Registry deletion.

References:
https://developers.cloudflare.com/workers/languages/python/stdlib/
https://developers.cloudflare.com/containers/faq/
