# Owner A: Cloudflare Python Worker + Supabase

Supersedes the persistent Linux host request in `../essay_lab/deployment/README.md`.
No Linux/Container, new evaluator, separate Registry or UI. Implementation is NOT
production deployed or E2E complete.

## Reuse and async boundary

`live_worker.py`: unchanged Prompt/Schema/parser/SignedReview validation; one
execution generator driven either synchronously or asynchronously. Network and
persistence operations yield to Cloudflare fetch/Supabase RPC. Provider request
builder/parser is shared, including store:false, no tools and no retry.
`material_runtime.prepare_claimed_material`: shared canonical IDs, evidence pins,
previous improvement context. Existing WEB/Native result contract unchanged.
`cloudflare_runtime.py`: existing Worker + async question channel + DB journal.
Initial consumer gates multi-question synthesis until the existing reviewed exam
summary service is connected. It does not fabricate summary or exclude Registry.

## Scheduling and persistent state

Pages `/api/essay/exam` already reserves once through existing idempotent Ledger
RPC. `/exam-evaluate` now enqueues identity-only {subject_id,run_id}, returns202.
No JWT, answer text, Package or Provider configuration in queue messages.
Consumer rechecks allowlist, account lifecycle and canonical owned run/lease.
Batch1, bounded retry3, dead-letter queue. Queue delivery is at least once and
consumer wall time is15 minutes. Provider request deadline remains75 seconds.
Do not use Pages waitUntil as a durable long-running executor.

New DB checkpoint begin serializes and grants dispatch once. Duplicate or ambiguous
pending jobs do not redispatch Provider. Reviewed/final checkpoints replay without
Provider. Unknown requests retain reservations for reconciliation, never guessed
refund. DLQ/pending reservation automatic operator recovery is still incomplete;
queue delivery itself is not evidence of evaluation completion.

## Build from canonical sources

`python3 tool/cloudflare_essay/stage.py /private/tmp/legendstudy-cf-build-UNIQUE`

Staging copies only transitive runtime modules, approved prompt and canonical
registration metadata from the existing manifest. No PDFs/private Package bodies.
Maintained data/engine have a single source; generated copies are not committed.

In staged directory: install pinned Wrangler4.150.0, then
`UV_PYTHON=3.13 uv run pywrangler dev --local --port 8798`.
workers-py1.17.7 / workers-runtime-sdk1.9.3. Compatibility2026-10-13 is the latest
supported by the tested workerd binary (2026-10-14 was rejected). No remote flag.

## Verified, separately

- Python sync/async same success/invalid/timeout/lost-finalization effects,16
  targeted unit checks PASS.
- Real disposable PostgreSQL canonical Ledger + new checkpoints: concurrent first
  begin, writer/owner/ACL, immutable result, first1Credit/free rewrite, async
  Package→existing Worker(fake Provider)→History, interrupted finalization resumed
  with one Provider request, deletion cascade, empty/nonempty rollback PASS.
- Actual LOCAL workerd startup imports the runtime, binds local queue, and POST
  without service credential returns503 before network. This is Cloudflare local
  execution, NOT operating Provider/HTTP E2E.
- Actual LOCAL queue smoke (fixture Auth/consumer only): POST202 → queue1/1 ACK.
  Found/fixed native binding positional send and SDK handler context arguments.
  No production Auth/DB/Provider/Credit in this check.
- No production SQL/Provider/Credit/Cloudflare setting changed in this phase.

## Operating prerequisites / exact Owner actions

1. DB checkpoint candidate: `supabase/candidates/essay_cloudflare_execution/README.md`.
   Separate Owner approval pending; do not bulk push migrations.
2. Cloudflare CLI currently has Pages scope only. Owner runs `wrangler login` on the
   existing account and approves Worker/Queue deployment scopes; do not send token.
   Alternatively use an account-scoped deployment token with Workers Scripts/Queues
   Edit; keep it in the approved secret mechanism, never chat/Git.
3. Create `legendstudy-essay-exams` queue and `legendstudy-essay-exams-dlq`, deploy
   staged `legendstudy-essay-reviewed` with execution false. No public workers.dev.
   Bind Pages `ESSAY_REVIEWED_WORKER` to this Worker (keep Pages evaluation OFF).
4. Worker Secrets: ESSAY_REGISTRY_WORKER_JWT (existing role),
   ESSAY_WORKER_SERVICE_TOKEN (same value in Pages and Worker, including service binding),
   ESSAY_PROVIDER_KEY, ESSAY_REVIEW_VERIFY_KEYS. Nonsecret config:
   SUPABASE_PUBLISHABLE_KEY, ESSAY_ALLOWED_SUBJECTS (existing allowlist),
   ESSAY_PROVIDER_BINDING (exact separately reviewed model/prompt policy).
   Do not change Math secrets/allowlist or substitute user/service_role JWTs.
5. Independent `ESSAY_REVIEWER` service binding must implement existing SignedReview
   semantics. It is NOT currently provisioned. No synthetic receipt/self-signing
   fallback is provided. This is a remaining implementation dependency, not merely
   a Secret that Owner can invent. Provider/material policies currently null or
   unapproved; review/activate exact bounded test policy separately.
6. Only after prerequisites: authenticated /exam-admission without Provider/Credit;
   actual Provider/Credit E2E still requires Owner's separate bounded approval.

The entry rejects unconfigured prerequisites. Local staging is not operating
connection. Do not turn flags on to make a green readiness response.

## Rollback

Keep Pages evaluation OFF, disable consumer, retain DB checkpoints and Ledger.
Empty-only DB rollback is supplied; never purge pending markers to force replay.

References:
https://developers.cloudflare.com/workers/languages/python/
https://developers.cloudflare.com/workers/languages/python/stdlib/
https://developers.cloudflare.com/queues/platform/limits/
https://developers.cloudflare.com/queues/configuration/batching-retries/
