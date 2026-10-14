# Owner A: Cloudflare Python Worker + Supabase

Supersedes the persistent Linux host request in `../essay_lab/deployment/README.md`.
No Linux/Container, new evaluator, separate Registry or UI. Implementation is NOT
E2E complete. Worker/Queues are deployed disabled as recorded below.

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
   Owner approved and applied20261014044957; postflight PASS. Do not reapply.
2. Owner reauthenticated: Workers Scripts/Queues write scopes verified.
3. Both queues and Worker now created. Version6eec8e98-6040-4e71-8d12-6ae3a3953288,
   execution false, workers.dev and preview URL disabled. Pages Production services
   configuration binds ESSAY_REVIEWED_WORKER; existing env variables unchanged.
   Existing publishable key/one allowed subject reused, Math configuration unchanged.
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

## Owner JWT issuance (Oct14 actual screen checked)

Production current key is ECC P-256; Legacy HS256 is still PREVIOUS, not revoked.
Legacy tab explicitly shows "Legacy JWT secret (still used)". No Rotate/Revoke.
Public JWKS lists EC keys only; its absence of HS256 is not evidence of revocation.
Supabase-generated ECC private keys are not exportable; key ID/public key/API key
or ordinary user JWT cannot substitute for the essay_worker credential.

Owner opens https://supabase.com/dashboard/project/stlhijzpjfgwwdgunlsd/settings/jwt/legacy
and copies Legacy Secret using Reveal (agent never reveals it). On Mac terminal:

```sh
python3 /private/tmp/legendstudy-shared-app/tool/cloudflare_essay/issue_worker_jwt.py --config /private/tmp/legendstudy-cf-production-disabled/wrangler.jsonc
```

Prompt takes Legacy Secret with getpass (not Mac/Supabase login password). Fixed
essay_worker role,365-day expiry, HS256. It sends only the signed JWT to the exact
LegendStudy read-only Registry RPC using existing allowed account metadata; no
Provider/Credit/mutation. Only HTTP200 +234 rows copies JWT to clipboard. Failure
prints status only, never request/response/token/Secret. No private key written.
Owner pastes into Worker Settings → Variables and Secrets → Secret named
ESSAY_REGISTRY_WORKER_JWT. This is the JWT, NOT its signing Secret.

Then generate the separate host credential:

```sh
python3 /private/tmp/legendstudy-shared-app/tool/cloudflare_essay/issue_worker_jwt.py --service-token
```

Paste the SAME clipboard value into Secret ESSAY_WORKER_SERVICE_TOKEN in Worker
legendstudy-essay-reviewed and Pages legendstudy-lab Production. Do not send it to
chat; save/deploy and notify completion. Pages requires redeploy for settings to
apply. Keep both evaluation flags OFF. After Owner action verify actual private
connection separately; issuance alone is not Provider/Credit E2E.

Sources: https://supabase.com/docs/guides/auth/signing-keys
https://developers.cloudflare.com/pages/functions/bindings/#service-bindings

## Oct14 Owner Secret postflight (14:36 KST)

Worker0bab25ca / Pages3b6c4c0b reflect encrypted credentials. Real existing allowed
Chrome account: LAB Registry234 → private service auth PASS → Worker Auth PASS →
Worker Registry234. HOLD-only /connection-check sends one nonce-only probe; operating
queue received/ACKed matching nonce. This probe never constructs runtime or reserves
Credit. Package HTTP400=PROVIDER_RIGHTS_REQUIRED; exam preflight403=policy null,
not Worker EXECUTE denial. Four reviewer/provider bindings absent. Runs/checkpoints0.
Actual evaluation/Provider/Credit E2E NOT_RUN, public HOLD. Secret input complete;
no rotation/reset required. New queue boundary2 and Web7 tests, typecheck/lint/build
PASS. Diagnostic route only accepts existing authenticated allowlisted users and is
disabled when evaluation flag is on. No student/result UX changes.
