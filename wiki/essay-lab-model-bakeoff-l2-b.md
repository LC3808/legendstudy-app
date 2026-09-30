# Essay LAB L2-B — model bake-off preparation

Owner Human Review update2026-09-30: [Official evidence archive strategy](essay-lab-data-foundation.md#official-evidence-archive-strategy--owner-decision-2026-09-30) records Hanyang source/transcription/non-criteria findings and next-version prompt guidance. It does not rescore frozen runs or select a model. Any separately authorized GPT Supplemental must preserve Claude’s frozen conditions; improvements belong to a different version/experiment.

## L2-B2 Round1 execution — 2026-09-30 (current)

Owner accepted L2-B1 and explicitly authorized four sequential private provider requests.
**All four slots terminal; total requests4, retries0, fallback0, repair0, UNKNOWN0.**
[Sanitized execution evidence](../tool/essay_lab/evidence/l2_b2_execution_result.json).
Model comparison is **PARTIAL**: both OpenAI calls returned HTTP429 `insufficient_quota`;
no GPT evaluation was produced. Both Claude responses passed strict Contract1.3 parsing.
**QUALITY_REVIEW=PENDING_OWNER_REVIEW; PRIMARY_MODEL_SELECTED=NO.**

| Slot (execution order) | HTTP / parser | Returned model | Input / output tokens | Latency ms |
|---|---|---|---|---|
| Sookmyung / OpenAI | 429 insufficient_quota / NOT_RUN | NULL | NULL / NULL | 1942 |
| Sookmyung / Anthropic | 200 / PASS | claude-sonnet-5-5 | 12908 / 6641 | 54214 |
| Hanyang / OpenAI | 429 insufficient_quota / NOT_RUN | NULL | NULL / NULL | 4821 |
| Hanyang / Anthropic | 200 / PASS | claude-sonnet-5-5 | 23019 / 9277 | 197740 |

Claude completion state `end_turn`; cache-read/write counters0 for both responses.
Provider-reported total tokens and actual cost/currency are NULL for all four; no estimate
was calculated, no billing/model probe or account/credit adjustment was made. Each failed
OpenAI slot is consumed too. No re-run/reset is authorized by this record.

Preflight: latest HEAD retained, accepted dispatcher hash matched052d595; all frozen inputs,
endpoints/model bindings and outside-repository regular/non-symlink0400/0600 non-empty
credential files validated locally without printing contents or copying credentials.
67 synthetic regressions and secret scan passed before any call. Immediately before execution,
STARTED metadata was enriched with explicit case/policy/prompt/schema/ordered-image hashes;
transport/prompt/parser/settings did not change. The executed source hash is in the report.
Activation used process-local named Owner authorization and approved file references only;
checked-in `EXECUTION_AUTHORIZATION=None` still prevents accidental CLI real execution.
No behavioral source change occurred between calls. Test-only post-run correction compares
private slot states before/after a disabled call rather than assuming no real receipts exist.

Each real raw response was frozen before parse; normalized files exist only for Claude PASS.
Private hashes, restrictive permissions and credential exclusion verified. Separate STARTED
markers and terminal records are preserved for all four. Inputs were never changed based on
another provider's output. No comparative quality review occurred before all four froze.

**Private Owner artifact:** `.local/essay-bakeoff-l2b/round1-owner-comparison.md`.
Contains originals, frozen official references, complete available evaluations, all core/sentence
observations, parser/telemetry and human rubric. Missing GPT outputs are explicitly marked.
No answers/raw/normalized output or credentials are committed. Sookmyung content-vs-clarity/
over-editing and Hanyang recall/stance/length/verbosity checks are **PENDING_HUMAN_REVIEW**;
parser PASS never establishes educational quality. No automatic winner or signed reviewer receipt.

Post-run synthetic67 + Wiki/diff checks PASS; actual provider calls remain exactly4.
Production DB writes0; no migration/RPC/apply/worker/traffic activation, no Round2.
Pilot4/2 call caps remain unrelated to unlimited Product revision cycles.
**NEXT:** Owner reads private results → resolves OpenAI quota outside this task if desired →
explicitly decides any bounded follow-up/model selection. No automatic retry or Round2.

All L2-B1/L2-B sections below are accepted historical checkpoints; their real-call0 statements
refer to preparation time, not this executed Round1.

## L2-B1 private Round1 dispatcher — 2026-09-30

**Dispatcher technically READY; real AI/provider requests 0. Real execution DISABLED.**
[Dispatcher](../tool/essay_lab/round1_dispatcher.py),
[synthetic tests](../tool/test_essay_round1_dispatcher.py),
[frozen input pins](../tool/essay_lab/evidence/l2_b1_frozen_files.json),
[sanitized validation](../tool/essay_lab/evidence/l2_b1_result.json).
No credential was inspected or provisioned. No DB connection/write, migration, RPC,
Production reviewer activation, real student traffic or Round2 implementation.

Readiness vocabulary: **READY_FOR_ROUND1_EXECUTION=YES only in Owner L2-B1 §35's
technical sense** (dispatcher safety/isolated tests passed). **EXECUTION_AUTHORIZED=NO**;
credential/account/model access and live API compatibility are **NOT_VERIFIED**.
L2-B2 still requires separate Owner authorization, secure provisioning and a reviewed
activation change. No environment variable or credential can enable L2-B1 real mode.
No quality, real latency or actual cost conclusion follows from synthetic tests.

### Pilot call caps are not Product revision limits — Owner addendum

`ROUND1_CALL_LIMIT=4` and `ROUND2_PLANNED_CALLS=2` bound only external provider
requests in this model-selection Pilot. **Pilot call cap ≠ student revision cap ≠
Product evaluation lifetime cap.** Students may continue rewriting/re-evaluating the
same question as needed under the authoritative server entitlement policy.
[Product essay_cycle/v2](essay-lab-product-v1.md#credits--g1-commercial-policy-2026-09-29)
repeats paid → included → paid → included indefinitely; it is not an attempt-number
parity rule or a four/six-evaluation ceiling. Required credits and existing validation,
idempotency/concurrency/security boundaries still apply. Historical v1 sessions retain
their pinned policy; this clarification does not rewrite past entitlements.

Scaffolding also has no revision-count cap: review previous core tasks → assess
improvement/resolution/recurrence → choose the next priority when resolved or provide
more specific help when unresolved → student rewrites → re-evaluation. Unknown or
not_assessable is not inferred resolution. Per-evaluation core/sentence limits stay intact.

Narrow source cross-check: deployed G1 migration003 selects an unclaimed settled paid
v2 decision in the same session, otherwise starts another paid decision; there is no
lifetime count condition. Existing G1 runtime fixture covers six successful alternating
charges. Pending L2-A2 migration005 retains that selection. Scaffolding adapter has no
round counter; dispatcher caps are private Pilot-only and have no DB/RPC path.
**CONFLICT: NONE.** No code/DB/RPC/migration change, Production re-audit or AI execution.

### Fixed inputs and actual HTTP boundary

Only these slot IDs, in future operator execution order: `sookmyung-openai`,
`sookmyung-anthropic`, `hanyang-openai`, `hanyang-anthropic`. One request per slot,
maximum4, no runner loop/queue/scheduler/job scan or arbitrary model/prompt/answer/endpoint.
The existing L2-B policy/model bindings, prompt, schema, packages and image order are unchanged.
Before any send, all22 frozen files are hash-checked against committed pins and the accepted
preparation result, including manifests/context, answer/package, evidence/locator data,
ordered images, policy/regime, prompt/schema and contract-source hashes. Drift fails closed;
no regeneration/repair. Synthetic tests copy the frozen inputs into disposable0700 directories.

`OfficialHTTP` makes one bounded TLS HTTPS POST using stdlib `http.client`,300s timeout:
`https://api.openai.com/v1/responses` or `https://api.anthropic.com/v1/messages` only.
No caller URL, proxy-env routing, redirects, retries, fallback, repair or continuation.
3xx is terminal failure, never follow Location. Prepared OpenAI `store:false`, exact
Structured Outputs/no tools and equivalent Anthropic request are reused unchanged.
Unexpected returned model identity rejects the slot; no alias/version substitution.
Both still use the same strict Contract1.3 parser; provider envelope/thinking is not product data.
Actual HTTP serialization/read path is tested using injected fake HTTPS connections;
real socket construction is blocked in the test fixture. `dispatch()` and a non-fake
`OfficialHTTP` both require the compiled-closed execution gate before credentials/network.

Safe offline command (no credential lookup or writes):

```sh
python3 -B -m tool.essay_lab.round1_dispatcher --slot sookmyung-openai
```

`--execute` always refuses in this version. There are no model/provider/case/prompt/answer/
endpoint/root CLI overrides. The synthetic entry requires an explicitly fake connection and
an isolated `/private/tmp/essay-l2b1-test*` root, never the real private artifact root.

### Credential and immutable artifact protocol

Exactly one existing L2-B env or `_FILE` source per provider; even an empty second source
is ambiguous. File must be a current-operator-owned regular0400/0600 file, no symlink,
hardlink or FIFO; missing/unsafe input fails before STARTED/send. Never log values, headers,
paths containing credentials or exception strings. No CLI-session/service_role substitution.

1. Validate mode, slot, all frozen inputs, credentials and request binding.
2. Exclusively create+fsync immutable0400 `round1-started/<slot>.json` **before send**.
   O_EXCL decides concurrent same-slot claims. Marker contains hashes/policy/time, no credential.
3. Send once. Freeze private `round1/<slot>/raw-response.bin` before JSON/contract parsing.
4. On strict success freeze separate `normalized.json`; then sanitized `terminal.json`.
5. Every sent request consumes the slot, including refusal/schema/model/HTTP errors.
   Timeout/reset/interruption/local persistence failure is `UNKNOWN_CONSUMED_FOR_ROUND1`.
   A marker without terminal is UNKNOWN too; it never unlocks. No automatic second call.

The permanent marker is separate from results: deleting the result directory cannot enable
retry. No reset/delete command exists. Operator filesystem tampering cannot be prevented by
application code; marker retention and a new explicit Owner decision are required for any
exception. Never delete a marker to obtain another Round1 call. Files0400, directories0700,
no symlinks, exclusive creation/fsync, ignored `.local/essay-bakeoff-l2b/`; tracked private
files or missing Git exclusion stop dispatch. Private normalized/body/image artifacts never
enter Git. Raw capture is bounded at256KiB+1; oversize is rejected with a truncated-capture flag.
If a response echoes a credential/Authorization pattern (including JSON ASCII escapes),
withhold raw, preserve only hash+notice, reject without parsing; secret safety takes precedence
over byte-for-byte raw retention. No raw headers are persisted. No ordinary exception log.

### Telemetry and full human review

Private terminal includes pinned provider/requested model, exact matched returned model,
latency, provider-reported input/output/total/cache counters, outcome/parser status.
Unexpected model strings stay in private raw, not sanitized metadata. Missing/invalid counters
remain NULL. Anthropic native input and cache-read/write counters are separate here; the earlier
adapter's aggregate is not mislabeled as a provider-supplied total. Latency is dispatch elapsed
through persistence/parsing, not a quality score. Current official envelopes have no trusted
billed-cost field: actual_cost/currency remain NULL; any later list-rate calculation must be
separate and ESTIMATE. No GA4/Firebase/DB telemetry.

After all four terminal artifacts exist, `build_review()` freezes private
`round1-owner-review.md`: original answer, frozen criterion labels/official references,
both complete evaluations (all dimensions/core tasks/sentences/quotes/directions/examples,
priorities/checklist/evidence), parser status, telemetry and an unfilled human rubric.
Rejected/unknown output is shown honestly, never repaired. Raw/normalized hashes are checked;
provider text is fenced against Markdown/HTML execution. No automated score/winner or signed
review receipt. Sookmyung content-vs-clarity and zero-sentence gate, Hanyang official-issue/
stance/verified-length gates below remain **human checks, not synthetic quality PASS**.

### L2-B1 validation and next step

20 dispatcher tests +47 existing L2-B/L2-A/L2-A2/Scaffolding unit regressions PASS;
50 canonical +55 review static tests PASS. Matrix A–AJ is mapped in the sanitized report.
Frozen22 inputs/prompt/schema/policy and accepted005 migration bytes unchanged.
No new native DB run: this task changes no SQL/RPC/DB integration; accepted L2-B native802
assertions remain historical evidence, not a new test count. No Flutter/build change.
Seven preservation answers below still apply: started/raw/normalized/terminal are distinct
immutable private operational facts; no student master/history/marketing fact is created.

**NEXT:** Owner reviews L2-B1 → securely provision credentials → explicitly authorize L2-B2
and reviewed gate activation → revalidate frozen inputs → exactly four slots, sequentially,
one request each → freeze all outcomes → private full Owner review → select primary model.
Only then consider separately authorized Round2. Production AI/traffic remains OFF.

## Accepted L2-B preparation checkpoint (historical)

2026-09-30. **PREPARATION ONLY / real AI calls 0.** GPT-5.6 Sol and Claude Sonnet5.5
are the two Owner-selected Pilot candidates, not Production defaults. Round1 is four
calls, followed by human review; Round2 is a **plan only**, at most two evaluations
of human rewrites after the primary model is selected. This supersedes L2-A3's earlier
2+2 call plan without changing its reviewer architecture or accepted historical results.

Preparation **READY**. **READY_FOR_ROUND1_EXECUTION: NO** until separate execution
approval and secure credential provisioning. No credentials were requested, provisioned,
or inspected. Live account/model access, actual latency, output quality and actual cost
are **NOT_RUN**. The adapters deliberately permit only injected synthetic transports;
there is no live dispatch command, DB claim/finalize or background worker activation.
After execution approval, a narrow reviewed dispatcher must connect the prepared
request/response adapters to the provider once per frozen slot. It must preserve the
one-shot artifact protocol below; changing `synthetic_only` is not an authorization flow.

[Preparation/result](../tool/essay_lab/evidence/l2_b_preparation_result.json),
[adapter](../tool/essay_lab/bakeoff.py), [offline assembler](../tool/essay_lab/prepare_bakeoff.py),
[tests](../tool/test_essay_bakeoff.py). Existing
[L2-A2 binding/telemetry](essay-lab-provider-provenance-l2-a2.md) and
[L2-A3 reviewer gates](essay-lab-worker-provider-l2.md#l2-a3-reviewer-architecture) remain intact.

## Candidate policies and identical contract

| Pilot policy | API model / returned-model binding | Transport |
|---|---|---|
| `pilot-openai-gpt56-sol-v1` | `gpt-5.6-sol` | Responses; `text.format`, strict JSON Schema |
| `pilot-anthropic-sonnet55-v1` | `claude-sonnet-5-5` | Messages; `output_config.format`, JSON Schema |

Six L2-A2 binding fields are preserved: policy_version/provider/model/model_version/
prompt_version/contract_version. Prompt is `scaffolding-1.3-v1-bakeoff1`; Contract **1.3**.
The committed report contains regimes computed by **PostgreSQL `jsonb::text`**, tested
against the existing `provider_binding_valid` helper in a disposable DB. Compact Python
JSON hashes are used only for private package/content hashes, never as SQL regime hashes.
No candidate entry was installed in a DB resolver; 005 and its empty shipped registry
are unchanged, Production NOT_APPLIED. This Pilot's multimodal prompt/alias IDs are not
a claim that the current production Worker can dispatch it. Existing Worker remains closed.

The API names currently published are aliases/model IDs, not verified immutable weight
revisions. `model_version` records the exact expected response model identifier; a different
response is rejected, not silently substituted. Hidden provider weight revision remains
unknown. Later dated API snapshots or prompt/settings changes require a new reviewed
policy/package. Freeze actual returned model and response envelope privately during execution.

Both transports use **exactly the existing `live_worker.output_schema()`**; no removed
constraints, alternate fields, SDK schema transformation or permissive fallback. Both
normalize through the unchanged `parse_provider` + `validate_output`: counts, enums,
all dimensions, answer hash, exact Unicode quote, root/evidence links, previous history,
stance/minimal-edit review gates stay unchanged. Nullable `example` is the existing sole
wire adaptation. Unknown fields (including old Pilot `uncertainty_note` or provider-supplied
`local_reviews`) fail. Model-specific envelopes/think blocks never become product fields.

Both receive identical product/system text, JSON data, images in the same order and byte
content, official sources, criterion labels and frozen empty previous context. High effort
is explicit for both (`reasoning.effort` vs adaptive thinking/output effort); it is **not**
an assertion that their internal reasoning budgets are identical. Output token cap12000,
private Pilot network timeout300s, no tools/web, no automatic retry, no batch or explicit prompt cache.
The longer private timeout avoids imposing the production lease on a human-reviewed artifact
Pilot; existing live Worker75s timeout/120s DB lease are unchanged. Timeout consumes its slot.
OpenAI `store:false` is not a promise of zero provider retention. Image tokenization and
provider-added schema instructions may differ; record actual usage rather than equalizing
or guessing it. A timeout or token limit consumes the original execution slot.

## Exactly two frozen cases

| Case | Original accepted inputs | Current context |
|---|---|---|
| Sookmyung2025 mock Q1-1 | Original3 images, reviewed reading transcription, Q/P/E1/E2 | Seven reporting axes, not seven invented official weights |
| Hanyang2024 humanities Afternoon2 | Original6 images, reviewed reading transcription, Q/P/E1/E2 | Five official criteria; existing handwriting uncertainty preserved |

Assembler reuses the original RunA **input-only** verification functions and accepted source
hashes. It does not read old output, ground truth, rewritten answer or Owner quality judgment.
The university-published answer remains the blind target answer with unchanged provenance;
no separate high-scoring/reference answer or quality label is supplied. IDs in this private
Pilot are explicit aliases, not student/attempt UUIDs. No Production row is created.

The same new provider-neutral JSON is used twice per university. Its hash includes ordered
image hashes; each original image is copied once into the private package, unchanged. All
transport image bytes are rehashed before request construction. The existing image-checked
transcription remains the exact quote coordinate system, not new OCR or a rewritten answer.

Existing official images were visually checked, without new collection: Sookmyung question
page2/Q1-1 **300±30자**; Hanyang question page1/problem header **1,200자**. Source image hash
and index accompany the rule. Hanyang's old Rewrite Pilot1150–1250 target is **not imported
as an official tolerance**. Neither transcription count nor `[판독 어려움]` justifies an
invented grid-length deduction. Rules are identical for both candidates.

Private root: `.local/essay-bakeoff-l2b/` (git-ignored, directory0700, new files0400).
Each case contains package/validation context/prompt/schema/manifest and original images.
Manifest hashes are committed; bodies, prompts with answers, provider payloads and images
are not. `prepare_bakeoff --freeze` is exclusive and refuses overwrite; default command
only recomputes input manifests. Historical Pilot artifacts remain untouched.

## Round1 execution contract — not authorized or implemented as a live launcher

Ordered slots: Sookmyung/OpenAI, Sookmyung/Anthropic, Hanyang/OpenAI, Hanyang/Anthropic.
Exactly **4 maximum calls**, one each. These are finite explicit slots, not queue jobs.

1. Before execution, verify approval, secure credential presence, all frozen package/prompt/
   schema/policy hashes and API endpoint allowlist. No key/model probing inference call.
2. Atomically create the private slot directory (case + policy); write an exclusive started
   receipt containing input/policy hashes and time **before** the one outbound request.
3. Freeze raw envelope privately before parsing. Preserve malformed/refused/truncated output
   as failure. Record transport failures even without a response. A crash/unknown slot must
   be reconciled as consumed; never delete/reset marker or send the request again.
4. Strict parse and freeze normalized output separately only if valid; no repair prompt,
   second call, fallback model or silent field stripping. Exact artifacts and hashes are
   immutable; quality annotations are separate human documents. Private HTTP failure bodies,
   if retained by the future dispatcher, must never enter ordinary logs/sanitized errors.
5. All four slots freeze before cross-candidate/ground-truth comparison. Schema PASS means
   **UNREVIEWED**. Human review never fabricates a runtime signed receipt or bypasses a lease.
   No one candidate judges the other; no `winner` field or automatic promotion.

`offline_slot` tests this protocol using synthetic transport only, including failed/unknown
slot non-retry and raw-before-parse preservation. Real started/completed timestamps and the
live HTTP dispatcher were pending at L2-B (now implemented but disabled above); there are no fake real run receipts.
Private human review may take days: no DB reservation,120s lease or HMAC receipt is held.
Later RPC E2E and production reviewer hosting/broker remain separate gates.

## Human review sheet

Copy this sheet separately for each of the four frozen outputs. Evaluate content before
considering provider price. Mark **PASS / PARTIAL / FAIL / NOT_ASSESSABLE**, cite exact output
field/issue/quote and relevant official source. No weighted automatic winner. A human chooses
and records the later primary model only after reviewing both cases and tradeoffs.

| Dimension | Evidence reviewer must record |
|---|---|
| Official criterion grounding | Each major claim linked to the actual university requirement |
| Major issue recall | Important official issues found/missed; review ground truth only after freeze |
| False criticism | Unsupported/invented problem or preference framed as error |
| Core-focus priority | Most consequential roots first;0–3, no quota filling or repeated root |
| Sentence diagnosis | Actual learning value, correct category and explanation;0–5 |
| Content vs clarity | Missing content does not make a clear sentence ambiguous |
| Stance preservation | No new policy preference/conclusion/value judgment inserted |
| Minimal editing | Optional example only when useful, smallest change preserving argument/style |
| Excessive feedback | Good text/strengths retained, no correction flood or duplicated criticism |
| Actionability | A student can act on the specific concise direction |
| Korean clarity | Friendly, precise Korean; no student-facing internal IDs/jargon |
| Evidence correctness | Official source vs target-answer quote separate, exact spans/provenance |
| Schema compliance | Strict parser outcome; quote/hash/core/sentence/history limits |
| Latency | Measured elapsed milliseconds; first-schema cold compilation noted |
| Input/output/total tokens | Actual returned counters; distinguish absent and calculated values |
| Provider cost | Actual billed/reported amount only, otherwise NULL; list rate separate |

Per output also record core_count/sentence_count, why selected, omitted important issues,
overemphasized/invented issues, duplication, stance change and unknown evidence. Include
full original answer and all evaluation fields privately for Owner reading: summary,
strengths, every dimension, all core tasks/sentences (quote/diagnosis/direction/example),
priorities/checklist/evidence. Template is prepared privately alongside the two cases.

**Sookmyung mandatory gate:** Never label intelligible sentences `unclear_meaning` merely
because an official content point could be added. Zero sentence observations is valid.
**Hanyang mandatory gate:** Retain substantive official-issue recall, keep each core action
concise, include relevant verified length checking without invented tolerance/deductions.
The four historical recall checks remain human ground truth, not extra provider hints.
Review all proposed local-sentence observations independently before any future publication.
Round1 contains no previous evaluation, so it cannot establish Scaffolding progression.

## Credentials, telemetry and list pricing

Server-only names: `ESSAY_PILOT_OPENAI_API_KEY`, `ESSAY_PILOT_ANTHROPIC_API_KEY` or the
corresponding `_FILE` containing an operator-owned0400/0600 regular file, no symlink.
One source only; missing/ambiguous/unsafe credential fails closed. No Flutter configuration,
CLI argument secret, shared review key, DB service_role, credential check call or chat secret.
Secure production provisioning and provider retention approval remain separate rollout tasks.

Provider counters are preserved; `cost_amount/currency` remain NULL when the response does
not report actual cost. Anthropic total is NULL if not reported; input includes returned
cache-read/cache-write input counters when present, original breakdown stays in raw private
usage. A computed sum must be labelled derived separately, never reported as supplied total.
Refusal/incomplete response usage is retained where valid. Malformed unknown usage stays
unknown. No model-generated cost, list-rate estimate or historical CLI tokens are actual cost.

Public USD list rates checked **2026-09-30**, per million tokens, standard API (not batch):

| Candidate | Input | Cached input/read | Output | Source |
|---|---:|---:|---:|---|
| GPT-5.6 Sol | $4 | $0.40 | $20 | [Official model/pricing](https://developers.openai.com/api/docs/models/gpt-5.6-sol) |
| Claude Sonnet5.5 | $2 | $0.20 | $10 | [Official model/pricing](https://platform.claude.com/docs/en/models/sonnet-5-5/overview) |

OpenAI page lists this promotional rate through at least2026-11-21; >272K input changes
full-request multipliers (2× input/1.5× output), cache write1.25× input. Claude cache writes
$2.50/5m or $4/1h per million. These prices are planning references, not billed receipts;
unknown actual Pilot cost is NULL. No candidate is selected based on list price alone.

Request references: [OpenAI structured outputs](https://developers.openai.com/api/docs/guides/structured-outputs),
[Anthropic structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs).
Provider schema subsets/refusals do not waive application validation. Existing transport schema
already avoids unsupported min/max/array bounds; identical strict application validation
continues enforcing them for both providers. Live API compatibility remains execution evidence.

## Round2 — plan only

After human review selects the primary model and separate approval is given: one **human-written**
revision evaluation per university, max2 additional calls. Freeze prior evaluation/core progress
with compatible regime and bind each actual rewritten answer. Assess previous cores before new
ones; OPEN/IMPROVED/RESOLVED/RECURRED and not_assessable remain evidence-bound. No invented
rewrites, automated winner, Round2 runner or call is implemented now.

## History/privacy review and validation

Seven preservation answers: (1) immutable preparation/dispatch/outcome records retain time and
version context; (2) original answer/evidence/output hashes allow exact tracing; (3) no historical
output overwrite or regenerating failed slot; (4) no new identity/student master—private aliases
only; (5) operational Pilot judgments are not Learning/Decision/Admissions Outcome facts or
marketing events; (6) answer/raw files private, provider/backup/deletion retention needs review;
(7) human quality conclusions remain versioned judgments, not permanent student traits.

No new DB column/table/migration/RPC. Existing KEEP19/history/billing/security unchanged.
Tests: both adapter request/parity/strict parser/error/credential/telemetry/privacy/no-retry;
existing worker/binding tests; static backend/review suites; actual isolated PostgreSQL L2-A2
fencing with prerequisite timing/G1/status/history regressions. See machine report for counts.
No new JWT/PostgREST execution claim: accepted L2-A2 local JWT evidence remains historical.
No Flutter changes/build, AI run, production connection or student traffic. Owner iOS/parallel
Analytics/Coupon/School files preserved. Next: Owner reviews preparation → separately authorizes
four-call Round1 and secure execution wiring → freeze → human review → STOP before Round2.
