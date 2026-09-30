# Essay LAB — worker/provider and reviewer architecture

L2-B4: [Option A / prompt v2 offline implementation](essay-lab-scaffolding-persistence.md#l2-b4-option-a-implementation--2026-09-30)
retains wire1.3 and strict parser. Worker/dispatch still use their historical prompt; no live
binding or policy registration is activated. Real provider calls0; GPT candidate only.

L2-B3: Owner Human Review is now recorded; GPT is PRIMARY_CANDIDATE, not selected. Existing signed-review/security boundary remains. Concrete/logic semantics and nullable-link storage blocker are design-only. [vNext contract design](essay-lab-scaffolding-persistence.md#l2-b3-vnext-contract-design--no-implementation).

Owner2026-09-30: [Official evidence archive strategy](essay-lab-data-foundation.md#official-evidence-archive-strategy--owner-decision-2026-09-30) governs future packages: raw PDF truth, separate scoring rules/non-criteria and reviewed transcription. Current L2-B2 prompt/evidence/outputs stay frozen; no worker change.

> Current follow-up: [L2-B2S supplemental](essay-lab-model-bakeoff-l2-b.md): new GPT2 HTTP200,
> both SENTENCE_ROOT parser failures. Owner review now prefers GPT as candidate; Claude2 PASS and original429 history preserved.
> No retries/fallback/repair or Round2. Checked-in execution gate remains closed.
> Production worker/reviewer/AI/traffic remain inactive. Historical L2-A3 plan below is superseded.

## L2-A3 reviewer architecture

2026-09-30 · **ARCHITECTURE REVIEW COMPLETE / recommendation, NOT ACTIVATED.**
Starting HEAD `7274e49`; latest branch retained. L2-A2 accepted runtime evidence and migration
bytes match. No source/contract/SQL changes, DB connection, AI call, credential provisioning or
scheduler. Analytics, School/Coupon work and Owner iOS edits preserved.

**Recommendation: Option B — one evaluator, deterministic validation for every result, and
independent review of a bounded set of sentence/progression claims.** Do not require a second
full LLM evaluation by default. Independent review means a separate qualified decision source,
not necessarily another model. First Pilot: human Owner/qualified Korean essay reviewer reads
all frozen output privately. Production: conditional review boundary remains **PARTIAL** as a
design and **not deployed**. Current code still requires a full signed receipt on every result.

Immediate next: approve this review scope → choose/pin an API model and Pilot budget → prepare
private representative packages + human rewrite → authorize staged Pilot. Applying L2-A2 is
separate and **CONDITIONAL**, not a prerequisite for an artifact-only quality Pilot. No new
schema/RPC is required for this recommendation; do not introduce an asynchronous review queue.

### What is deterministic, what is judgment?

A means executable validation, B means fallible educational judgment, C means a proposed
independent pre-publication decision. These layers overlap; passing A never proves B.

| Requirement | Class | Existing enforcement / remaining boundary |
|---|---|---|
| Owner/session/question/attempt, immutable answer hash | A | Auth/RPC/FK + worker hash; no client identity trust |
| Exact Unicode codepoint span, emoji/decomposed Hangul/whitespace | A | Parser + Scaffolding SQL; no normalization, fabricated quotes rejected |
| Criterion identity/version, evidence IDs/role/locator/hash/mapping | A | Frozen snapshot + trusted cache/allowlist; not proof of interpretation |
| Shape, enums, duplicate JSON keys, root/span IDs, core<=3/sentences<=5 | A | Strict worker parser + SQL; semantic duplicate roots still B |
| Explicit previous-progress link, compatible regime, all prior core reviewed | A | Frozen context and SQL transition/link checks; not proof of actual improvement |
| Billing/lease/fencing/idempotency/result+settlement | A | Existing RPC transaction boundaries, unchanged |
| Diagnosis, strengths, priority, useful concise action, minimal edit | B | Prompt, bounded contract, Pilot rubric; cannot be certified by type checks |
| Stance, correct passage/criterion interpretation, non-repetition | B | Human Pilot review; independent review when a material conflict is identified |
| Every sentence observation, regardless of provider category or claim_scope | B+C | Independent review before publishing sentence-level error/correction claims |
| Quote-only local root, including resolved-local without a current error quote | B+C | Existing adapter/SQL require trusted exact `local_reviews`; retain this requirement |
| Assessed previous-task outcomes: open/unchanged/improved/resolved/recurred | B+C | Narrow review of progression reason, current answer and frozen predecessor; no whole-answer regrading |
| not_assessable | A+B | Required reason/coverage checked; no positive/negative progress assertion created |
| Official criterion diagnosis without sentence/progression claims | A+B | Single-model judgment can publish only after the proposed policy and model quality are approved |
| Missing mandatory evidence, fabricated official weight/length, invalid source IDs | A failure or B/C defect | Reject unverifiable output; do not use a reviewer to waive missing source/ownership checks |

C is deliberately keyed to **all sentence entries and explicit prior-task claims**, not merely
`claim_scope=local_sentence`, a provider confidence number, a keyword blacklist or an invented
risk score. A provider cannot evade review by attaching an official evidence ID to a sentence
criticism. There is no claim that deterministic routing discovers every semantic error hidden in
ordinary prose. Routine university feedback retains single-model error risk; Pilot QA, clear
non-official-score language and later sampled/dispute review address that residual risk.

### Alternatives and choice

Comparisons below are architecture estimates, not measured API benchmarks.

| Option | Educational safety / false correction risk | Latency and provider cost | Operational complexity / availability |
|---|---|---|---|
| A: evaluator + deterministic checks only | Grounding structure protected; local diagnosis/progress can still be false. Does not satisfy current quote-only trusted-review rule | One generation; lowest incremental review cost | Simplest, but unacceptable as a blanket bypass of existing local review |
| **B: evaluator + narrow independent review** | Covers sentence false positives and unsupported progression; residual ordinary criterion risk explicitly retained | One generation plus bounded review only when flagged; human review has labor/latency, rules or models have separate costs | Small explicit router/reviewer boundary; unavailable required review must not publish flagged claims |
| C: full second LLM on every result | May find more errors but can share the generator's mistakes or introduce its own; not ground truth | Additional full-context/model output cost and serial latency on every request | Two model dependencies, versions, monitoring and failure modes; cannot assume 120s feasibility |
| D: sampled/risk review with ordinary publication | Useful for monitoring; sampling alone cannot prevent the first false local correction | Lower average review spend, variable latency | Selection/calibration/coverage needed; cannot sample away mandatory C claims |

| Option | Mid-October feasibility | Auditability | Scaling |
|---|---|---|---|
| A | Fastest code path, but local contract violation unless those claims are absent | Source/result history retained, no independent decision | Simple; quality risk scales with volume |
| B | Best bounded scope; still conditional on model/Pilot and a timely reviewer or honest omission path | Exact flagged claims + review reason + signed payload/version | Review load follows sentence/progression frequency; measure it, do not assume it is rare |
| C | Highest implementation and latency risk | Two outputs to reconcile, no automatic correctness proof | Full extra inference for all results |
| D | Appropriate later as supplemental QA, not a launch substitute for B | Must preserve selection scope and sampled verdict | Efficient monitoring after calibration; coverage blind spots remain |

**Choose B.** D-style post-publication sampling is a later supplementary control, not a second
recommended launch architecture. No second model is selected or made mandatory by this decision.
If narrow review cannot meet quality/latency, report that gate rather than silently enabling A.
Omitting every progress judgment would undermine the learning-loop product; successful, meaningful
second-attempt guidance is a launch gate, not an acceptable permanent `not_assessable` fallback.

### Sentence and official-evidence publication policy

| Sentence kind | Production recommendation |
|---|---|
| Grammar/formal | A future narrowly validated rule/checker may independently verify a truly formal error with an auditable rule ID; none is currently implemented. Prompt + quote alone is insufficient |
| Awkward expression | Treat as optional suggestion, never style preference asserted as error. Independent review or omit |
| Sentence structure / unclear meaning | Reviewer must explain actual ambiguity/broken relation; missing content alone is not ambiguity. Independent review or omit |
| Local logical contradiction | Reviewer reads sufficient surrounding text and both propositions; retain local provenance, no fake official source. Independent review or omit |
| Criterion/passage application | Keep official evidence and student quote separate. If a sentence observation is emitted, review it regardless of official scope; ordinary criterion-level diagnosis follows A+B |

For an optional new sentence finding: prefer **omission** if no reliable judgment is possible.
Do not delete just the quote while retaining the same unsupported error claim in an improvement.
Omit its purely local new root/core reference too, or reject the result if it is material or linked
to required prior history. Do not hide an important official content problem to shorten output:
retain a separately justified criterion-level diagnosis without inventing a sentence defect.

These are proposed trusted adaptation rules, **not implemented filtering**. Any accepted-payload
change must retain the frozen original, record an explicit disposition/reason, revalidate all
relations, recompute hashes and obtain approval for the final payload. The existing exact-match
`local_reviews` must refer to that exact final issue/sentence array. No silent sanitizing, raw output
mutation, automatic retry or false approval. A future narrow application implementation must test
this transformation before normal publication; this review changes no current behavior.

Official allowlist proves **which** approved source was used, not that it says what the model
claims. Never allow a quote-only label to authorize passage interpretation. Reference/example
answers remain excluded from generator inputs; blind target answer provenance is retained privately.
Conflicting/missing required evidence blocks output. An identified material interpretation/stance
conflict needs independent decision or rejection. Routine grounded diagnosis does not require a
second full evaluation. A verified length rule must carry its original source/context; current
`cache.length_requirement` is a trusted optional cache field, not independently certified by its
presence. Package review must verify it; unknown length stays unknown, never guessed/deducted.

### Progression rule

Review old core tasks **before** choosing new ones. Evaluate the current immutable answer against
the prior action and criterion, with explicit compatible predecessor and concrete current support.
A disappearing sentence, score increase, fewer observations or provider omission is never evidence
of resolution. `resolved` means the specific task was addressed in this answer, not permanent mastery.
`recurred` requires the exact previously resolved root plus new demonstrated occurrence, not a
free-text similarity merge. `improved` requires a defensible partial change; unchanged/open require
current supporting grounds too. Reviewer scope is these assertions, not rescoring the entire essay.

If source/reading/context is insufficient, use existing `not_assessable` + reason: no progress row,
no inference of resolved or unresolved, old history unchanged. Missing mandatory prior reviews is
an error, not implicit unknown. Frozen previous progress includes prior observation/quote/context;
if the reviewer needs a previous full answer that the package cannot safely provide, do not fetch
unapproved data or guess. Request a later approved package improvement or mark not assessable.
All OPEN→IMPROVED→RESOLVED→RECURRED facts remain append-only evaluation-local judgments.

### Signed boundary: current facts and proposed refinement

`SignedReview.verify` currently requires **all eight full-output quality flags true**, matching
package/output hashes, evaluation ID, reviewer-key membership, expiry and complete local-key list.
`Worker.execute` calls it on **every** result. The adapter checks exact local objects; SQL checks
trusted `local_reviews` structure and local/official separation. **SQL does not verify the HMAC or
judge prose.** The narrow worker is part of the trusted computing boundary; its credential must
never be given to the generator/provider or Flutter.

Retain this mechanism for Pilot QA, full audits, disputed outputs and model/prompt regressions.
Do not issue an all-true full-review receipt after merely checking three local claims. Conditional
production B needs a separately versioned **application review receipt/routing policy** with exact
covered claim IDs, verdict/reason and final payload binding; the existing full-review verifier is
preserved for old receipts. No schema or RPC change is needed: a trusted adapter can still emit
existing exact `local_reviews`. No receipt format/route has been changed in this task.

Minimum trust contract for that follow-up:

- Reviewer type: named qualified human for first Pilot; production may use a validated narrow
  checker or independently instructed model/service after explicit approval. A second call by the
  same generator auto-signing its own output is not independent review.
- Auth: private server-to-server authenticated reviewer request; no public signing endpoint. The
  operator authenticates to controlled tooling for human QA. Provider output is data, never approval.
- Secrets: versioned reviewer identity/key in server secret storage, outside Git/client/prompts.
  HMAC implies both signer **and verifier** hold the shared secret and are trusted; it does not
  cryptographically isolate a compromised worker. Provider transport is not given that secret.
  Public-key verification is a possible later refinement, not a new mandatory service this phase.
- Binding: exact evaluation + answer/package/output hashes; retrieve immutable model/regime/prompt
  binding from trusted job. Future conditional receipts must also bind review policy/version and
  coverage. Preserve separate raw vs final-payload hashes if a disposition changed the payload.
- Replay/expiry: current MAC receipt has an expiry no more than 900s ahead; it is not one-time.
  Same-result finalize retry is permitted by existing DB idempotency. Cross-output/evaluation
  approval fails; lease/fencing always wins. A receipt does **not** extend the 120s run lease.
- Rotation/revocation: remove revoked versioned reviewer key from trust map, stop publishing affected
  pending jobs, retain prior audit evidence. Keep signed decisions in private durable audit/checkpoint
  storage with access/deletion controls, not a public telemetry property. Hosting is not deployed.

### Pilot quality review versus live runtime

**First recommendation: private artifact-only human-reviewed API quality Pilot.** This deliberately
separates educational validation from DB transaction validation already exercised synthetically.
It does not call `Worker.execute` as though real execution were enabled, hold a reservation during
human review, finalize an expired run, or relabel a later claim as the original provider call.
The private Pilot runner/config remains to be prepared after model selection/authorization; it is
not implemented by this document. Human verdicts are dated private QA artifacts, not runtime
publish receipts; do not manufacture a 900s receipt to bypass a days-long review. Stable private
fixture IDs/history snapshots must be distinguished from DB-issued records. Model-bound production
RPC E2E remains a separate gate afterward.

Proposed total cap **4 generation calls**, staged: first one original answer per university (2),
freeze → Owner review/explicit continuation → one genuinely human-authored rewrite per university
(2). Reviewer model calls **0** in this first design. This task authorizes **0** calls. A smaller
one-university pair may be explicitly authorized first; never silently enlarge the cap.
Each timeout/refusal/malformed result consumes its attempt slot. No automatic retries, extra
"repair" calls, hidden best-of selection or replacement of old Run A outputs.

Use existing reviewed Sookmyung2025 mock1-1 / Hanyang2024 afternoon2 sources only after manifest,
transcription, criterion and length provenance review. No recollection required. Existing official
high-scoring answers remain **official published answers**, not relabeled real student submissions.
The person rewriting is identified by role/consent privately; no model-written rewrite presented
as student-authored. Original evaluator input excludes quality labels, other reference answers,
previous Pilot verdicts and ground truth. Evaluation2 receives only the compatible frozen prior
feedback/context, not post-freeze ground-truth coaching hidden as evidence.

Private retention: exact original/rewrite bytes + provenance, input/evidence/extraction/history
hashes, request/model/prompt/contract/schema/settings, raw response, parsed/final payload hashes,
start/end/latency, provided input/output/total tokens and nullable actual cost, errors as safe codes,
reviewer verdict/reasons and accepted/omitted claims. Freeze first response **before** reference
comparison; separate later annotations, never overwrite it. Git only sanitized counts/hashes/gates;
no answer/quote/prompt/raw feedback, PII, token, credential or full reviewer receipt. No chain-of-
thought collection. Private access/retention/deletion and provider handling must be approved first.

Rubric: PASS/PARTIAL/FAIL for priority, strengths, discipline, diagnosis/actionability, minimal edit,
stance, duplication, official/local provenance, honest progression and useful Korean. Exact spans,
source identity, invented-error absence and stance preservation are hard gates; any invented source,
stance change or unsupported RESOLVED/RECURRED blocks acceptance. Core and sentence lists may be
empty where justified. All critical gates must PASS for each retained case; priority, useful guidance and previous-core
assessment must also be acceptable to the qualified reviewer. A noncritical PARTIAL remains named
and needs explicit Owner acceptance of the limited next step, not an automatic quality PASS.
No growth trend from two samples; report per-case findings and limitations.

- **Sookmyung gate:** clear sentence with missing content is not `unclear_meaning`; good-answer
  core/sentence count is not a quota. Preserve valid content criticism at the proper level.
- **Hanyang gate:** retain substantive issue discovery while each core action is short and focused;
  verify official length rule and include relevant checking guidance, never invent a threshold.
- **Rewrite gate:** every previous core gets evidence-backed assessment or explicit not_assessable;
  changed/removed text alone is insufficient. Compare compatible regimes and preserve strengths.
- Capture actual measured API latency/counters; prior CLI77.132s/120.981s and tokens are historical
  evidence only, not product API SLA/cost. Unknown actual cost remains NULL; any rate calculation is
  a separately labeled estimate. No paid credits/real student rows are involved in this quality Pilot.

Production B must fit reviewer + generator + parsing/finalize inside the existing120s lease (current
candidate generator timeout75s). Proposed planning budget: generator<=75s, reviewer<=25s, validation/
finalize<=10s, >=10s safety margin; these are targets, not observed capability. A slow human is not
this synchronous production reviewer. Required review unavailable/expired → no flagged publication,
existing failure/unknown/reconciliation behavior, no blind re-generation. Async hold/renewal or a
new waiting state would be **beyond L2-A2**: report the exact blocker and STOP for separate approval,
not silently extend a lease. This task selects no such schema/RPC extension.

### Model-selection decision packet

**READY_FOR_MODEL_SELECTION YES; no selected model or quality winner.** OpenAI Docs skill used for
official OpenAI capability checking; provider docs were read2026-09-30, no inference calls. These
are API families to screen, not a claim all variants support the same schema/context or a shortlist
approved to run:

| Candidate surface | Verified documented capability | Repository evidence / decision gap |
|---|---|---|
| OpenAI Responses | Strict structured output supports a JSON Schema subset, but content can still be wrong. [Official guide](https://developers.openai.com/api/docs/guides/structured-outputs) | Transport candidate + mock tests only; no approved API model or measured Korean/API quality |
| Claude API | Structured JSON output via `output_config.format`; schema limitations and first-schema compilation latency. [Official guide](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) | No adapter/runtime evidence here; must test the same strict contract, not assume interchangeability |
| Gemini API | Schema-driven structured output documented. [Official guide](https://ai.google.dev/gemini-api/docs/structured-output) | No adapter/runtime evidence here; validate selected model/schema subset and usage identity |

For **each exact candidate**, Owner/ChatGPT decision packet must specify immutable model/version
availability in the intended account, endpoint, prompt/reasoning settings, supported output schema,
context/output limits, privacy/retention/region constraints and current dated input/output/cache/
reasoning token rates. No prices or model quality ranking are invented here. Select on measured
capability, not which adapter happens to exist. Historical Codex CLI model results are not API
availability, quality or billing proof.

| Capability | Required evidence before acceptance |
|---|---|
| Strict structure / deterministic compliance | Exact1.3 transport, nullable example handling, enums/caps, refusal/truncation behavior; server checks remain mandatory |
| Korean reasoning and writing | Blind paired fixtures, strengths/priority/clear actions; qualified human assessment, not provider benchmarks |
| Long context | Actual evidence + answer + frozen prior context + output allowance fits selected tokenizer/limits without silent truncation |
| Latency | Measured end-to-end and review timing vs120s; four calls cannot establish production p95/SLA |
| Cost | Project spend cap + max output/call; measured counters; estimate input*rate + output*rate + relevant cache/reasoning charges, separately from actual invoice |
| Evidence adherence | No extra references/ground-truth leakage; exact source/criterion binding and correct interpretation |
| Stance / minimal editing | No added policy preference or wholesale AI rewrite; optional example only where needed |

Missing decision inputs now: exact API candidate approval, maximum total Pilot spend, reviewer
person/availability, private package/rewrite approval and secure credential **location/provisioning
plan**. No secret in chat, and no provider/worker secret is provisioned this phase. Automated narrow
review model selection, if later needed, is a separate cost/quality comparison, not automatic reuse
of the evaluator. First Pilot human review avoids requiring that second model decision now.

### History preservation check for this review

The seven canonical questions apply: (1) a review verdict/omission is a timestamped operational
Decision, not a new student fact; (2) it cannot be inferred from parser PASS, so retain its private
payload/version binding; (3) never overwrite frozen provider output or prior progress; (4) existing
attempt/evaluation identity stays authoritative; (5) review decisions are distinct from Learning
observations and Admissions Outcomes; (6) private access/consent/erasure/retention applies to review
artifacts too, no marketing export; (7) confidence/trend is derived and uncertain, never permanent
student truth. No storage or collection was added in this architecture-only task.

### L2-A2 migration and final gates

Reviewed005 bytes match accepted hash
`6c0d5a2a40fe5129ff8b9a718fae53bf60d3cd5226c2b9b440d30932f1c9ed3b`.
KEEP19, nullable total_tokens/no backfill; empty server resolver, frozen claim identity; telemetry
worker-only ACL, fixed path/ownership, existing fence and immutable history retained. v1.2/legacy
unconfigured runs are untouched. No premature model, reviewer or real-worker activation.

**L2_A2_PRODUCTION_APPLY_RECOMMENDATION: CONDITIONAL.** Technically useful to deploy dormant
provenance/telemetry infrastructure independently of reviewer selection; not necessary for the
artifact-only Pilot. Before any separately authorized apply: confirm linked LegendStudy project,
ledger/local chain/hash and exactly intended pending migrations, canonical/Product row baselines,
ACL/RLS/security contract, dry-run scope and post-apply read-only preservation. Those fresh
Production preflight checks were **NOT_RUN** here. No unexpected drift or extra migration may be
bundled. An apply does not make the empty model registry or production reviewer ready.

Validation this task: existing worker/binding unit23, backend static50, review static55 and Wiki/
diff/hash checks. Prior temporary venv was absent; recreated a disposable static-parser environment.
No changes warrant another DB runtime/Flutter build; their accepted L2-A2 PG/JWT/L1 results are
referenced, **not reported as rerun**. No Production catalog assertion was newly executed.

| Requested gate | Result |
|---|---|
| REVIEWER_PRODUCTION_PATH | PARTIAL — bounded architecture specified; live path still absent |
| READY_FOR_MODEL_SELECTION | YES — requirements ready, no model chosen |
| READY_FOR_L2_A2_PRODUCTION_APPLY | NO today — conditional recommendation, fresh preflight/authorization outstanding |
| REAL_AI_PILOT_READY / READY_FOR_REAL_AI_PILOT | NO — model/budget/package/human rewrite/reviewer + explicit run approval outstanding |
| DB_CHANGE_REQUIRED / MIGRATION_REQUIRED / RPC_CHANGE_REQUIRED | NO additional change for selected design; accepted005 remains pending |
| SIGNED_REVIEW_BOUNDARY | Retained unchanged now; proposed conditional version + full Pilot/audit use |
| REAL_AI_RUNS / PRODUCTION_APPLY / PRODUCTION_AI / REAL_STUDENT_TRAFFIC | 0 / NO / NO / NO |

**NEXT, in order:** (1) Owner/ChatGPT review Option B + staged four-call ceiling; (2) approve exact
API model/budget and human reviewer, validate existing packages and private storage; (3) prepare
an explicit private artifact runner without enabling production Worker, synthetic smoke tests;
(4) separately authorize first2 calls → freeze/human QA; (5) approve genuine rewrites/next2 →
freeze/progression QA; (6) only after quality acceptance, implement/test the conditional application
review receipt/router and timely production reviewer, separately configure model policy and
authorize005 deployment/rollout as appropriate. No production credential deployment or traffic
is implied by any earlier step. If a required change reaches SQL/RPC beyond005, report and STOP.

---

## L2-A historical implementation record

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
