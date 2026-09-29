# Essay LAB L2-A2 — provider provenance and telemetry

> 2026-09-30 follow-up: [L2-A3 reviewer architecture](essay-lab-worker-provider-l2.md#l2-a3-reviewer-architecture)
> recommends narrow conditional review and a separate human-reviewed private Pilot. Architecture
> PARTIAL, not deployed. The accepted L2-A2 implementation/results below remain unchanged.


2026-09-29. **IMPLEMENTED / isolated PostgreSQL + actual local JWT/PostgREST PASS.**
Production **NOT_APPLIED**. Real AI runs **0**. No provider/model selected. Production
reviewer **BLOCKED**; real AI Pilot and real student traffic **NOT_READY**.
Accepted predecessor: [L2-A](essay-lab-worker-provider-l2.md), starting commit `ed17021`.

## Recommendation and scope

Resolve the two server-contract blockers before selecting a model: an immutable provider binding
at request/claim and a narrow fenced telemetry write. KEEP19; **no new table**, one nullable
`essay_ai_processing_runs.total_tokens bigint CHECK >= 0` column. Existing provider/model,
input/output tokens, latency, image count and cost fields are reused. The supplied total is not
always reconstructable when component usage is absent; NULL preserves provider omission. No
separate event, provider master, cost table or mutable current-model alias.

[Forward migration](../supabase/migrations/20260929000500_essay_provider_provenance_telemetry.sql)
adds one public RPC, four private helpers and narrow request/claim dispatch + processing guard
corrections. It does not modify applied migrations, Flutter, AI activation, billing policy,
financial allocation, learning history or existing result/finalize contracts.

## Server-owned policy and claim

`essay_private.provider_policy(regime)` is a deployment-owned, **empty** resolver. No caller can
execute or mutate it; a later separately approved model-selection migration must install explicit
entries. This task only installs synthetic entries in guarded disposable fixtures.

Exact binding keys: `policy_version`, `provider`, `model`, `model_version`, `prompt_version`,
`contract_version`. All are bounded nonempty machine identifiers, contract `1.3`; unconfigured
provider/model is rejected. The new regime is:

`essay-v1.3/policy/<SHA256(binding::jsonb::text)>`

SQL is authoritative for the hash; callers do not recreate PostgreSQL JSON serialization. Changing
any model/version/prompt/policy field requires a new regime. A client may reference a known regime,
but cannot supply provider/model values. Request validates the deployment entry, freezes it inside
`input_snapshot.provider_binding`, and includes it in the existing evidence-manifest hash. Criteria,
evidence and previous compatible core-progress snapshot selection remain fixed at request time.

Claim verifies the frozen binding/hash and inserts provider, model_name, model_version and
prompt_version **on the first run INSERT**. The returned binding equals that row. A queued request
continues its frozen approved version even if a later registry entry changes; no moving-latest
lookup at claim. Retry appends a new run with the same frozen identity and a new lease/fence.
The worker compares deployment adapter configuration to the claim before calling a transport, then
rejects differing response identity; provider output never sets DB identity. Selected evaluation
inherits the existing immutable run identity through unchanged success finalize.

Activation is explicit: the new policy namespace requires a G1 `v2` session. Existing `essay-v1.2`,
`essay-v1.3` and legacy in-flight paths remain unchanged, including their historical `unconfigured`
synthetic records. They are **not eligible for actual provider execution**. No default regime switch
or live queue is enabled here. Bound example-rewrite jobs are not supported in this evaluation-only
contract. Model selection/rollout must configure the new regime and trusted adapter together.

## Narrow telemetry operation

`essay_record_provider_telemetry(evaluation, run, token, input_tokens, output_tokens, total_tokens,
latency_ms, image_count=NULL, cost_amount=NULL, currency=NULL)` → run UUID.

- SECURITY DEFINER, owner `essay_executor`, fixed empty search_path; EXECUTE only `essay_worker`.
  Private helpers have no PUBLIC/anon/authenticated/service_role/worker/finance execution rights.
- Existing account → session → sorted grants → evaluation locks and run/token/lease fencing apply
  **before** idempotency. Wrong, expired, unknown, stale, terminal or erased jobs cannot write.
- Integer counters are nullable/nonnegative. Supplied total must equal input+output when both are
  known. Latency is measured integer milliseconds, required 0..86,400,000; never fabricate zero.
- Actual cost is nullable. Known cost must be finite/nonnegative, <=1,000,000 and representable with
  eight decimals, with a three-letter uppercase currency. It is marked `provider_reported`.
  No estimate is persisted as actual cost; later invoice reconciliation is outside this contract.
- Non-null latency marks the single recorded telemetry tuple. Exact retry returns the existing run;
  different tuple returns `PT409 TELEMETRY_CONFLICT`. The guard freezes that tuple even while the
  run is processing. Identical **terminal** retry is denied, per the fencing contract.
- Record available usage **before** timeout/failure; it survives the status transition. Late usage
  after lease loss/terminal state is rejected. Unknown usage stays NULL. Recovery of such late
  provider invoices would require separately approved reconciliation, not bypassing the fence.
- Telemetry never settles credit. Existing atomic result/consume and failure/release remain separate.
  Ambiguous telemetry transport is not treated as provider failure or permission to regenerate.
  The caller may retry the same narrow payload while the lease remains valid; otherwise reconcile.

There are no provider/model input parameters, JSON payload, prompt/answer, raw response/error or
student profile fields. Internal evaluation/run IDs suffice for this phase; no external provider
request reference is stored. Private receipts contain counters/hash, not answer text. The signed
independent reviewer boundary is unchanged; the provider cannot approve itself. The production
launcher remains blocked before claim (`REAL_PROVIDER_NOT_AUTHORIZED`), even with a bound adapter.

## History/privacy preservation review

1. Run identity, actual supplied usage and failure timing are operational historical facts, not
   marketing events or current student traits.
2. Existing submitted answers, official/local evidence and versioned evaluations remain source data;
   no answer/prompt/raw output is duplicated into telemetry.
3. Retries append runs; completed/unconfigured history is never relabeled. Once-recorded telemetry
   cannot silently change; new model policy requires a new regime.
4. Existing Auth/session/attempt/evaluation ownership and parent relations are preserved. No new
   student master, public read, direct worker write or service-role bypass is introduced.
5. Learning/Decision/Outcome history remains distinct; telemetry does not imply payment settlement,
   academic growth, application outcome or an Analytics SDK event.
6. Existing Essay erasure removes processing metadata with learning data; financial history retains
   its existing separate boundary. Provider/checkpoint/backup retention remains a rollout gate.
7. Cost summaries/trends are derived later. Supplied tokens/latency cannot be reconstructed from
   evaluation prose; unknown cost stays unknown, no new aggregate or inferred weakness is stored.

## Validation and reproduction

[Sanitized result](../supabase/validation/essay_lab_product/l2_a2_result.json),
[DB/JWT runner](../supabase/validation/essay_lab_product/provider_runtime.py),
[bound worker JWT runner](../tool/essay_lab/provider_worker_runtime.py),
[adapter adversarial tests](../tool/test_essay_provider_binding.py).

- Native PostgreSQL: Phase2A77 + server55, Scaffolding80, timing306; G1 84, status55,
  provider/provenance65, post-migration legacy Scaffolding80 PASS.
- Actual local Supabase: legacy37 before/37 after, Scaffolding79, timing306; G1 88,
  status54, provider/provenance65, post-migration legacy Scaffolding70 PASS.
- Bound worker/JWT49 PASS: input injection, direct writes, adapter mismatch before call, response
  mismatch, success/timeout/failure usage, status projection and erasure. Old L2 worker/JWT43 PASS.
- Worker unit23 (with adversarial subcases), backend static50 and review55 PASS.
- Flutter existing widget61 + actual Dart local JWT1 PASS; analyze PASS. No Flutter edits/builds.

Start fresh consented loopback PG17 `essay_review_*` / dedicated Supabase `essay-review-*`.
Run `submit_timing_runtime.py --native|--supabase`, then `provider_runtime.py` in the same mode.
The latter runs G1 + status + new migration + post-migration legacy Scaffolding. In local mode run
`python -B -m tool.essay_lab.provider_worker_runtime` and existing `live_worker_runtime`, each with
an explicit private `/private/tmp` fixture path. Run the existing Dart `essay_live_local_test.dart`
with a fresh private fixture. Guards check numeric loopback, explicit consent and Docker project/
port before fixture writes. No linked project or Production fallback. Close owned instances after
verification. Reports omit DSNs, keys, JWTs, UUIDs, account details and bodies.

Native numeric-cost fixture initially used Python float, which could not resolve a numeric RPC;
changed to Decimal. Local privileged fixture initially lacked helper execute permission; fixed
only the disposable setup membership. No server permission/constraint was relaxed. Migration-order
static expectation was advanced by one forward version. Final listed runs PASS, new regressions NONE.

## Decision gates

| Gate | Result |
|---|---|
| Provider provenance / telemetry | PASS in isolated PostgreSQL + actual local JWT |
| v1.2 / in-flight / existing history | PRESERVED |
| Tables / columns / public RPCs added | 0 / 1 / 1 |
| Production migration/apply | NOT_APPLIED |
| Provider/model selection | NOT_SELECTED; READY_FOR_MODEL_SELECTION YES |
| Independent production reviewer | BLOCKED |
| Real AI Pilot | NOT_READY (approval/model/config/reviewer required) |
| Real student traffic | NO |

Next: Owner/ChatGPT reviews this contract and chooses provider/model separately. Then approved
policy/config and independent reviewer path can be prepared, followed by separately authorized
real AI Pilot. No credential request or Production apply is required for this completed phase.
