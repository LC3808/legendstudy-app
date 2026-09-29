# Essay LAB L2-A — worker/provider boundary

> Current follow-up: [L2-A2](essay-lab-provider-provenance-l2-a2.md) resolves the binding/telemetry
> contract in isolated runtime. Its forward migration is NOT_APPLIED; no model selected or real AI
> enabled. The L2-A results and blockers below are the accepted historical baseline.


2026-09-29 · **PARTIAL / NOT PRODUCTION READY**. L1 and Production G1/status/Scaffolding
acceptance remain preserved. This package implements and tests worker orchestration, strict
parsing and an independently authenticated review boundary. It does **not** claim the requested
real-provider Original→Rewrite loop or educational quality PASS. Actual AI calls: **0**, cost: **0**.

## Blocking facts and next bounded correction

1. No approved product API provider/model/credential was available to this task. Earlier Pilot
   Codex CLI execution is not a product API integration. A missing credential location/model
   question was sent to Owner; no secret requested in chat. Do not reuse Codex login credentials.
2. Deployed `essay_private.scaffold_claim_v13` inserts `provider='unconfigured'`, model name equal
   to regime and no selected model version. Processing identity is immutable from insertion.
   `essay_finalize_success` copies that identity into the completed evaluation. Calling a real
   provider now would create misleading historical metadata. The worker therefore refuses the
   real path **before claim**; only the guarded synthetic local runner is enabled.
3. Token/cost/latency columns exist, but no narrow public operation can ingest them. Worker cannot
   UPDATE the processing table, and service_role is not an acceptable workaround.
4. Signed review verification is implemented, but an independent semantic reviewer/service and
   its secret provisioning are not deployed. A valid quote or provider `claim_scope` is not
   proof of correct diagnosis. A test signer is explicitly synthetic, not an Owner quality review.
5. Official cache assembly validates frozen mapping identity and extraction bytes. A reviewed
   representative official package/criterion mapping and student-authored rewrite still need to
   be bound for the real loop. Synthetic criterion text is never labeled real official evidence.

**Minimum proposed forward correction**, after exact model policy is selected (not applied here):

- Retain KEEP19 and existing columns. Preserve existing v1.2/in-flight code exactly.
- For newly enabled1.3 regimes, claim resolves a **server-owned versioned provider/model/prompt
  policy** and inserts it with the run, returning the same binding to worker. Do not allow clients
  or provider output to select it. A model change needs a new regime policy; do not silently
  change the meaning of previous comparisons. Existing unconfigured runs are not rewritten.
- Add a narrow fenced worker telemetry operation using evaluation/run/token, existing lock order,
  current run/lease checks, allowlisted nonnegative usage/latency and nullable actual cost.
  Preserve idempotent identical retry; changed telemetry under the same run conflicts. Write once
  before terminal transition; record available timeout/failure usage too. No raw provider error,
  prompt/body, arbitrary JSON or direct table GRANT. Actual cost remains NULL when unavailable.
- Success remains existing atomic result+settlement; telemetry is operational, not a prerequisite
  for changing credit policy. Validate model binding, stale/terminal denial, erasure, retry and
  existing RLS/ACL/search_path/history with an isolated forward migration before review.

No migration was fabricated around an unselected model. **DB table/column changes: NO;
RPC/forward migration correction required: YES (proposal, not implemented/applied).**

## Implemented boundary

[Worker/parser/provider adapter](../tool/essay_lab/live_worker.py) uses existing Python tooling,
no new backend framework or dependency. One explicitly dispatched evaluation per invocation;
no unrestricted queue scanning, scheduled automation, auto-generation retry or Production launcher.

1. Narrow `essay_claim` supplies submitted answer + frozen input/history. Never read mutable draft.
2. Read-only server cache must match every allowed evidence ID/role/hash/version/locator and
   criterion ID/version. Verify extraction SHA separately from original source SHA. Reference
   answers and extra cache contents are not sent; no provider-supplied URL fetching.
3. Provider-specific OpenAI Responses transport candidate is isolated from product contract.
   It requires explicit model/key; `store:false`, strict JSON Schema, no tools, bounded response
   and75-second network timeout. No provider is selected by this candidate. Its actual network
   behavior remains NOT_RUN. [Official structured output specification](https://developers.openai.com/api/docs/guides/structured-outputs)
   defines the transport shape; it does not certify educational correctness or zero retention.
4. Strict parser rejects duplicate JSON keys, unknown fields, Pilot `uncertainty_note`, malformed
   types, wrong answer/attempt, invalid criteria/evidence, duplicate roots/spans, oversized core/
   sentence lists, fabricated/normalized quotes and unsupported history transitions. Wire nullable
   `example` is the only explicit adaptation: null becomes absent before RPC validation.
5. Independent reviewer attests complete package/output hashes, evaluation binding, expiry,
   named quality checks and exact local-root coverage via HMAC. Provider cannot supply the receipt
   or access its key. Server constructs existing `local_reviews` only after verification. Changes
   to diagnosis/direction/root/quote invalidate the approval. This is authentication of a review,
   not an automated semantic classifier. Never auto-sign based on passing structural validation.
6. Existing Scaffolding adapter creates final RPC shape. Durable **private** checkpoint callback
   receives exact finalize args before RPC; retry that payload only after ambiguous finalization,
   never rerun AI. Lease token/output are not ordinary logs or telemetry. The caller must provide
   encrypted/access-controlled checkpoint persistence; no production store is installed here.
7. Provider ambiguity/reviewer timeout invokes `essay_timeout`, retaining reservation and exposing
   reconciling. Definitive rejection/invalid output invokes failure/release. Finalize transport or
   DB failure is not converted to provider failure; fence/atomicity remain server-authoritative.

Legacy1.2 worker dispatch is intentionally not converted; original adapter and DB contract stay
unchanged. New worker rejects legacy input before provider. Existing legacy tests remain applicable.

## Review, hosting and secrets

Recommended deployment is a small server-only process/container consuming authenticated explicit
job IDs. Credential broker supplies a short-lived `essay_worker` JWT; worker receives neither
service_role nor JWT signing key. Finance identity is separate. Provider project key and review
verification secret live in server secret storage, never Flutter/Git/reports. Reviewer identity
is independently provisioned; provider has no access to signer or receipt API.

The120-second immutable lease includes provider+review+finalization. Reviewer must finish inside
remaining lease time; otherwise timeout/reconciliation, not late publication. Asynchronous/manual
review taking longer needs a separately reviewed continuation design, not silent lease bypass or
another model call. Hosting, broker, durable checkpoints, reviewer availability and dispatch
recovery are **not deployed**. No real student queue is consumed.

## History and reliability

Seven preservation answers: (1) request/run/outcome/timing are operational historical facts;
(2) submitted text, fixed evidence/history and immutable result remain the learning basis;
(3) retries append new runs, never overwrite old evaluations/progress; (4) ownership stays with
existing Auth/session FKs; (5) learning and billing decisions remain separate from Admissions
Outcome/marketing telemetry; (6) private data only, no names/profiles in provider package, erasure
fences removed jobs; provider/backup/checkpoint retention remains a gate; (7) no growth prose,
analytics cache or permanent student weakness is invented from current observations.

Request/start/success/failure/unknown/completion/retry count and settlement/release can be derived
from existing evaluations/runs/ledger. End-to-end duration is derivable; **actual provider latency,
selected model identity and tokens cannot be truthfully ingested through the current worker RPC**.
Synthetic runtime writes sanitized receipts through a callback; this is not durable production DB
telemetry. Unknown provider charges remain unknown, never converted to an estimated actual cost.
No GA4/Crashlytics/Ads/IAP/Paywall or duplicated analytics events.

## Validation

[Unit tests](../tool/test_essay_live_worker.py), [guarded local runner](../tool/essay_lab/live_worker_runtime.py),
[sanitized report](../supabase/validation/essay_lab_product/l2_worker_result.json).

- New worker unit tests15 PASS, including adversarial subcases, signed review replay/tamper,
  Unicode, previous review/unknown, real-call fail-closed and ambiguous-finalize no-release.
- New worker actual local Auth JWT/PostgREST checks43 PASS: synthetic provider,
  OPEN→IMPROVED→RESOLVED→RECURRED, paid/included, invalid output/failure release, timeout/retry,
  idempotency, account isolation and erasure with financial preservation.
- Existing native77+55 / Scaffolding80 / timing306 / G1 84 / status55 / post-G1 Scaffolding80 PASS.
- Existing local JWT legacy37 before/37 after / Scaffolding79 / timing306 / G1 88 / status55 /
  post-G1 Scaffolding70 PASS. Includes stale/late success, rollback injection, local quote provenance,
  caps, previous-core snapshots, not_assessable, lease and v1.2 coexistence.
- Existing static46 + review55 PASS; Flutter56 + sentence5/analyze and actual Dart JWT PASS.
  System Python lacked pglast; reran review suite successfully in the existing disposable venv.
- Sookmyung content-vs-clarity and Hanyang concise-task/confirmed-length corrections are prompt and
  validation requirements only. **Real quality regression NOT_RUN**, not PASS from string assertions.

Reproduction: fresh guarded local Supabase → existing `submit_timing_runtime.py --supabase` →
`status_projection_runtime.py --supabase` → `python -B -m tool.essay_lab.live_worker_runtime`, with
existing disposable environment variables and private `ESSAY_L1_CLIENT_FIXTURE` path. Native uses
an empty loopback `essay_review_*` DB. Never run against linked Production. Shut down only these
owned disposable instances; preserve private credentials outside Git.

## Decision gate

WORKER_PROVIDER_INTEGRATION: **PARTIAL** (synthetic boundary PASS, real provider path blocked).
SCAFFOLDING_QUALITY: **PARTIAL / NOT_RUN for L2 real AI**.
READY_FOR_PRODUCTION_WORKER_DEPLOYMENT / IAP / REAL_STUDENT_TRAFFIC: **NO**.

Next: Owner supplies approved API model + secure credential location and independent reviewer path;
resolve the narrow metadata RPC correction in isolation; bind reviewed official fixture and actual
student rewrite; perform at most the authorized first two real evaluations, freeze outputs/cost,
then assess quality separately. Production activation still needs separate Owner/ChatGPT approval.
