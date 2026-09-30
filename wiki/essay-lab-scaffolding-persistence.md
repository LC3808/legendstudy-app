# Essay LAB Scaffolding Persistence — 1.3

[L2-C2A resume](essay-lab-model-bakeoff-l2-b.md#l2-c2a-private-protection-repair-and-resume--2026-09-30):
repository private protection repaired; same v3/Contract1.3/C1 Evidence used for two attempts.
Historical C2 Hanyang remains UNKNOWN_CONSUMED. Later C3 Hanyang and C2 Sookmyung now have
Owner human PASS; [Gate D preparation](essay-lab-model-bakeoff-l2-b.md#l2-c3-gate-c-owner-pass-and-gate-d-preflight--2026-09-30) now has one structural PASS/CORE0 result; calibration Owner review pending. No model selection.


## L2-C2 positive learning guard — 2026-09-30

[Owner Product principle](essay-lab-product-v1.md#l2-c2-positive-learning-reinforcement--2026-09-30)
is implemented in new immutable [scaffolding-1.3-v3](../tool/essay_lab/prompts/scaffolding-1.3-v3.txt).
v2 already allowed zero CORE/preserving strengths, but did not explicitly teach criterion-linked
WHY and transferable successful reasoning. v3 adds that material requirement and removes the
summary's presumption of a remaining problem. v2 and historical prompts are unchanged.
Wire1.3/schema/parser/root invariant/SQL remain unchanged; strengths, dimensions, summary and
checklist already express positive instruction. Existing local reviewer gate is not bypassed.

[HQ1–HQ10](../tool/essay_lab/fixtures/positive_learning_quality.json) are curated semantic
examples/anti-examples; [tests](../tool/test_positive_learning.py) also prove zero-core/real
non-core roots and positive text remain wire-valid. Generic praise/forced criticism/optional
polish as CORE can be structurally valid yet educationally rejected. No Korean keyword
classifier or SQL semantic-quality claim. The initial C2 authorization used examples only offline. Owner now separately authorizes one
blind Gate D source-example answer calibration, without a quality label or perfect-answer
guarantee; the one authorized execution returned CORE0/three strengths and structural PASS.
Real educational quality remains pending Owner review.

Seven preservation answers: (1) new timestamped private evaluation regime; (2) frozen input,
prompt, request/raw/normalized/terminal retain provenance; (3) no historical overwrite;
(4) same representative submission, new private attempt identity, no Production student link;
(5) learning evaluation distinct from model choice/outcomes/billing; (6) private local access,
no analytics/body publication; (7) synthetic verdicts and model judgments are derivatives,
never official criteria or observed human-review facts.


L2-C1: [Evidence vNext representative packages](essay-lab-data-foundation.md#l2-c1-official-evidence-vnext--2026-09-30)
prepared offline; [CORE-first overview](essay-lab-ui-ux-v1.md#l2-c1-core-first-overview--2026-09-30)
now preserves detail/history while selecting only current priorities at the top. Historical
frozen artifacts remain unchanged; GPT candidate only, new provider calls0.

## L2-B4 Option A implementation — 2026-09-30

**Owner Option A APPROVED; offline prompt/contract regression PASS.** This supersedes
L2-B3's pending choice below: nullable links are NOT introduced. Wire Contract1.3,
parser, adapter, SQL finalize and KEEP19 remain unchanged. Every sentence observation
must reference a real active improvement; a genuine local problem can be NON-CORE.
Do not repair old GPT output, drop observations or fabricate roots. Existing independent
local semantic review is still mandatory before finalization.

Implementation: [versioned prompt](../tool/essay_lab/prompts/scaffolding-1.3-v2.txt),
[offline prompt descriptor](../tool/essay_lab/scaffolding_vnext.py),
[evidence sidecar preparation](../tool/essay_lab/evidence_vnext.py),
[regression tests](../tool/test_scaffolding_vnext.py),
[curated quality examples](../tool/essay_lab/fixtures/scaffolding_vnext_quality.json).
Prompt **scaffolding-1.3-v2**, same output schema1.3; no change to v1/bakeoff1 or deployed
policy registry. Descriptor is opt-in and intentionally NOT connected to live_worker or
Round1 dispatch. Future authorized package preparation must pin this prompt hash and a
new policy/regime; same wire does not establish comparable regimes automatically.

### Implemented semantics and validation boundary

improvements are supported historical roots (existing max30), CORE is the next-rewrite
subset (default1–2, hard max3, supported zero). One coherent repair can consolidate multiple
spans; minor local roots retain quote and review provenance without becoming priority tasks.
explanation expresses location/WHAT/WHY; action expresses HOW; checklist is next-attempt
checks. Existing450/240 core text limits remain. No student-anchor field or new DB column.
Prompt checks directed logic and official criteria, avoids forced examples/conclusion form,
preserves strengths/stance, reviews prior cores before new tasks and allows zero sentences.

**ABSTRACT_FEEDBACK_GATE=PROMPT_AND_FIXTURE.**23 curated semantic examples/anti-examples
record expected human verdicts, context and rationale, not automatic model scoring. Unit tests
validate those fixtures and demonstrate that structurally valid abstract/overloaded guidance
can still be semantically unacceptable. No Korean keyword classifier or fake signed reviewer.
Real educational quality, priority necessity and subtle false criticism require human review.

| L2-B4 acceptance | Implemented verification |
|---|---|
| T1–T4 | CORE/non-core real roots PASS; absent/null roots rejected; independent local review required |
| T5–T7 | 1/2/3 core structural PASS;3 justification in synthetic fixture;4 rejected; real necessity remains semantic |
| T8 | Minor-core overload structurally valid but curated quality REJECT |
| T9–T11 | Unicode/codepoint exact spans; normalized/fabricated/draft quote reject; allowed official grounding + local segregation |
| T12 | Explicit non-criterion→mandatory conclusion anti-example quality REJECT |
| T13 | Separate question/scoring source role/hash; wrong source rejects, no invented numeric penalty |
| T14–T15 | Explicit OPEN→IMPROVED→RESOLVED→RECURRED; non-core history; not_assessable preserved, false transition rejects |
| T16 | Added stance/value judgment quality REJECT |
| Q1–Q8 | Abstract action/evidence anti-examples; concrete diagnosis, alternate-valid reasoning, stance, non-core provenance, zero sentence, consolidated root |
| Pilot regression | Synthetic S2/H1 missing local roots reject; actual-root variants PASS, no historical artifact repair |
| Direction review | actor/object, cause/effect, necessary/sufficient, comparison axis, evidence/claim, criticism/judgment, concept/application anti-examples |

### UI compatibility finding

No Flutter change. Existing sentence quote/diagnosis/direction/optional-example mapping is
compatible. `essay_live_gateway.dart` filters first priorities by core_focus, so NON-CORE does
not become “가장 먼저 고칠 것”. Core title is not a separate mapped card; explanation appears
in general improvements and action in priorities. Stronger per-core grouping is DESIGN_ONLY.
**Remaining mapping limitation:** gateway maps ALL active improvement explanations into
`EssayEvaluation.improvements`; `essay_pages.dart` overview uses its first two. Thus a non-core
root can appear in top summary when fewer than two core roots exist. UI_MAPPING_COMPATIBLE=
DESIGN_ONLY for the full desired focus, not an unconditional PASS. No silent UI change here;
future narrow UI review should choose summary items using core metadata without deleting detail.
UI_SCHEMA_CHANGE_REQUIRED=NO for persistence/wire; a typed presentation association may help.

### Validation and preservation

New vNext20 PASS; existing worker15 + bakeoff15 + provider binding8 + scaffolding Pilot9 =47
PASS; SQL static validation50 and review55 PASS; Wiki handoff PASS. Initial worktree run lacked
private fixtures (one error/one skip), resolved by read-only fixture path injection; initial
pglast import failures resolved in a disposable venv. No unrelated code repaired. No Flutter
build/analyze (Flutter unchanged), no DB runtime/Production connection claimed.

Private46 files hash-identical before/after; no answer bodies/raw output/images added to Git.
New tiny Hanyang transcription fixture uses the Owner-provided fragment, not full benchmark
text. SQL/migrations/parser/historical prompt bytes unchanged. New provider calls0, DB writes0.
Seven preservation answers: (1) no new student fact generated; (2) roots/quotes retain original
attempt/evaluation identity; (3) no historical UPDATE; (4) student identity unchanged;
(5) learning history stays distinct from billing/telemetry; (6) private inputs/retention/review
boundary unchanged; (7) synthetic quality labels are review examples, not observed model facts.

Next: Owner review, including UI summary limitation → separately authorized Evidence vNext
and tiny frozen provider validation. GPT remains candidate, not selected. No Production AI,
worker, Round2, student traffic, billing/security changes, migration or archive ingestion.

2026-09-29 · IMPLEMENTED / ISOLATED RUNTIME VALIDATED / **PRODUCTION DEPLOYED** — [apply evidence](essay-lab-scaffolding-production-apply.md).
Owner approved the [product contract](essay-lab-product-v1.md) and1.3-review.1 direction.
KEEP19; one new nullable column; no AI call, real student data, UI change or new table.
[Sanitized verification](../supabase/validation/essay_lab_product/scaffolding_result.json).
Scaffolding result is Owner ACCEPTED. The timing issue below was outside this extension;
[separately authorized forward correction](essay-lab-submit-timing-correction.md) now addresses it.

## L2-B3 vNext contract design — no implementation

**Recommended minimum: retain non-null sentence→real improvement links, distinguish
non-core roots from CORE selection, strengthen prompt/semantic review.** Owner review and
[concrete Product contract](essay-lab-product-v1.md#l2-b3-concrete-feedback-contract--design)
are inputs. No parser/schema/SQL/RPC/UI implementation or provider run in L2-B3.
Nullable independent observations need Owner review before any implementation path is chosen.

### Verified current contract and nullable-link blocker

`live_worker.py` output_schema requires string linked_issue_key; validate_output requires a
matching active improvement (`SENTENCE_ROOT`). Supplemental GPT failed with2 missing links
in Sookmyung and1 in Hanyang. Do not rewrite these outputs to pass, infer missing roots, strip
observations or reclassify them automatically as minor. Claude's historical valid output is
also retained; contracts must be model-neutral.

**improvements != core_improvement_keys.** Up to30 actual roots can exist, only0–3 are selected
cores. Current `claim_scope=local_sentence`, empty official evidence, exact quote and independent
local review already allow a genuine minor non-core root. It is an evaluation-local observation,
not a permanent student weakness and not a fabricated core task. One real issue can own several
spans; don't create duplicate roots just to satisfy a quota. Content/official issues retain
`official_criterion` evidence and appropriate core priority; local category cannot hide them.

The suggested nullable path is NOT a parser-only change:
- migration20260929000100 scaffold validation rejects NULL with INVALID_SENTENCE_LINK;
- sentences are grouped by issue into `essay_improvement_progress.scaffolding_observation`;
- progress requires an issue parent, and finalize iterates improvements to persist observations;
- independent local-review binding and Flutter mapping also follow that parent envelope.
Allowing null only in Python would either fail SQL or lose the observation. No silent carrier
root, synthetic issue, body-JSON dumping or dropping data is acceptable.

If Owner requires truly rootless observations, **STOP that implementation path**: separately
review an evaluation-owned observation storage location (existing evaluation payload capacity
must be verified before proposing a nullable column), versioned RPC validation/write mapping,
review authorization, erasure and UI mapping. No new sentence table is proposed now, no exact
migration is drafted. New storage/version dispatch likely requires forward migration; retain
1.3/in-flight/historical behavior and replay/atomicity/RLS tests. This is a blocker report,
not a declaration that current JSONB can store orphan observations safely.

### Single recommended no-DB handoff

For L2-B4 recommend prompt-only semantic refinement with existing wire Contract1.3 and
new explicit prompt/package/policy regime identity. Non-null link → existing non-resolved
real issue. Independent minor grammar/wording → real local non-core issue, no official-evidence
claim, reviewed exact span; linked issue omitted from core_improvement_keys. Null → reject.
Do not enforce that every sentence belongs to a CORE; it belongs to an improvement.
Do not generate a root solely to force an unnecessary minor correction into the output.
This resolves the Product concern (no fake CORE) without weakening graph/provenance checks.
**Owner must confirm this recommendation versus nullable storage expansion before L2-B4.**

Wire contract/schema/DB/RPC/migration changes: **NO for recommended path**. Prompt changes:
YES. Parser algorithm changes: NO required; deterministic regression/diagnostic coverage and
semantic quality fixtures are required. Nullable alternative: wire/parser YES and storage/RPC/
forward migration review required, not authorized. Current enum/count/quote/evidence/security/
billing invariants remain. Do not register a Production model or alter the policy resolver here.

Reuse mappings:

| Product meaning | Existing field(s) / limitation |
|---|---|
| Student location + WHAT/WHY | improvement.explanation; exact quote/span in linked sentence_feedback only where warranted |
| HOW / missing logical B | improvement.action; sentence.direction; optional minimal example, never a completed answer |
| Next attempt check | checklist with explicit task wording; no new structured checklist→issue FK claimed |
| Normative grounding | dimension/improvement evidence_ids in frozen allowed official package |
| Preserve strengths | strengths + keep-good-parts instruction |
| Core selection | core_improvement_keys only; priorities1..N;0 valid,1–2 default,3 justified |
| Changed substeps | previous_improvement_reviews.reason + progress explanation/action; substeps are not separate states |

Retain existing core text limits (explanation450/action240); concrete does not mean verbose.
WHAT/WHY/HOW completeness and task consolidation are semantic judgments. Nonblank fields,
exact spans and graph membership are deterministic; a keyword blacklist cannot prove useful
advice or that an official case is necessary. An abstract-only action can be flagged in fixtures
but cannot be universally certified by SQL or JSON Schema. Existing signed-review boundary is
not bypassed; strengthen future human/semantic quality criteria without inventing receipts.

### Offline acceptance design T1–T16 (not implemented fixtures)

| Test | Fixture / expected gate |
|---|---|
| T1 | Linked active real root → structural PASS, even if non-core; semantic review separate |
| T2 | Independent minor grammar/wording: null rejected in recommended path; genuine non-core local root + exact quote + review accepted; nullable alternative blocked pending storage review |
| T3 | Nonexistent link → reject for every provider; no auto-repair |
| T4 | Official/logic issue mislabeled local/minor to evade grounding: scope/evidence inconsistency rejects structurally; plausible dishonest label requires semantic review, cannot be proven by category alone |
| T5 | Core1/2 correct roots/order → structure PASS; priority/actionability human review |
| T6 | Core3 → within hard cap, exceptional independent necessity must be justified in review artifact (no extra wire key) |
| T7 | Core4+ rejects; redundant three or minor-priority overload → quality FAIL despite structurally valid count |
| T8 | Exact submitted-answer quote/codepoint/hash including emoji/decomposed Hangul/whitespace → PASS |
| T9 | Normalized/fabricated quote, draft quote or wrong owner/source → reject |
| T10 | Official evidence IDs/version/scope membership → structural gate; claim actually supported → semantic gate |
| T11 | Explicit no-form criterion plus missing conclusion paragraph → false-criticism FAIL; distinguish missing required judgment |
| T12 | Question1200 versus actual verified scoring rule, manuscript numbering/deletions/count method → separate evidence; invented1201 automatic penalty FAIL |
| T13 | OPEN→IMPROVED→RESOLVED→RECURRED via explicit previous links preserved; reason names actual changed/remaining substeps |
| T14 | not_assessable retains reason, no inferred status/root transition; absent observation not resolution |
| T15 | Minimal wording correction must preserve stance/argument; introduced policy preference → semantic FAIL |
| T16 | Only abstract action such as “논리를 강화하세요” → quality FAIL; structural nonblank may PASS, no claim SQL proves pedagogy |

Fixtures should be synthetic/minimal, model-neutral; include both accepted historical Claude
shapes and rejected GPT graph shapes without mutating originals. Holdout good-answer fixture
must allow0 core/0 sentence and preserve strengths. Causal-chain fixture must identify A,
missing B and directed repair, not enumerate unconnected concepts. All16 designs include
where/why/how/independent rewrite/improvement checks. No real provider needed for fixtures.

### Versioning and gates

Do not change old1.3 result meaning or append corrected fields to frozen outputs. A next
prompt/evidence experiment uses new immutable identities, verified corrected transcription
and reviewed evidence version; never claim it is the old fair comparison. Compatible previous
context is explicitly selected/frozen under existing regime rules; no moving latest lookup
or cross-regime growth assertion. Same underlying wire1.3 does not imply same evaluation regime.
Any later provider test needs separate Owner approval, narrow question, frozen new package,
acceptance rubric and small explicit budget; no broad bake-off repeated automatically.

Design READY for Owner review; **SENTENCE_ROOT_RESOLUTION=NEEDS_OWNER_REVIEW** and
**READY_FOR_L2_B4_IMPLEMENTATION=NO** until the no-DB recommendation is accepted or nullable
storage scope separately authorized. No Production policy/worker/model-selection/AI/traffic,
Round2 or evidence ingestion implementation readiness is implied.

## Migration and server boundary

[20260929000100](../supabase/migrations/20260929000100_essay_scaffolding_persistence.sql)
adds only `essay_improvement_progress.scaffolding_observation jsonb NULL` and its strict CHECK.
No backfill or change to existing PK/FK/RLS/ledger. Shape:
`{"version":1,"core_focus":true,"sentences":[]}`.
SQL NULL=legacy/not provided; supported empty array=no sentence observations on this task.
No root rows in a1.3 evaluation is a supported zero, not legacy missing output.

CHECK enforces exact envelope/sentence keys, types, version1, boolean focus, four categories,
four priority classes, integer offsets, nonblank text, optional nonblank example, array<=5 and
unique observation IDs/spans within the root. Finalize additionally enforces evaluation-wide
<=5 sentence observations, <=3 distinct active core tasks and exact core ordering via priority.
Same root may contain multiple different spans; never duplicate root per sentence.

Same public RPC signatures and caller grants. Explicit regimes `essay-v1.3` and
`essay-v1.3-next-model` select contract1.3/prompt `scaffolding-1.3-v1`. Default remains
`essay-v1.2`. The three original request/claim/finalize bodies are preserved byte-for-byte
under private legacy functions. Completed/in-flight1.2 jobs are not converted; their observation
column stays NULL. New private helpers have executor ownership/fixed empty search_path and
no EXECUTE for PUBLIC/anon/authenticated/service_role/worker/finance. No new public endpoint.
Worker direct table writes remain denied; existing fencing/lock/billing paths are retained.

## Snapshot and prior-task review

Request holds existing account→session→sorted grant locks, selects compatible completed earlier
attempts in the same session/question/regime with matching criterion/evidence versions, and freezes
`input_snapshot.scaffolding_context` plus its hash. It stores the selected previous evaluation,
latest compatible observations per root, original evaluation/attempt/hash, official references,
core/resolved IDs and previous title/diagnosis/action. Previously unassessed core tasks remain in
scope via their last actual observation. Legacy/incompatible/same-attempt assessments never become
invented rewrite growth. Later completion cannot move an already-requested snapshot.

Before recording new tasks, finalize requires a review of every snapshotted prior core. Assessed
outcomes append linked progress on the same root; recurrence requires a resolved predecessor.
Wrong owner/session/regime, unselected/newer/invalidated references and duplicate roots are rejected.
A fresh regime can independently observe the same root without pretending there was growth.

`not_assessable` writes **no progress status**. The immutable required-ID list minus assessed links
identifies unknown tasks; existing uncertainty_note preserves narrative reasons. Unknown is not
OPEN/UNCHANGED/RESOLVED. Neither progress nor input snapshot is retrospectively rewritten.

## Source validation and trusted local review

Source is evaluation→submitted attempt, not a client-provided answer or mutable draft. Finalize
checks body SHA256, input manifest hash and output source binding, then compares the exact UTF8
PostgreSQL character slice using Unicode code points [start,end). No trim, NFC or UTF16 conversion.
Emoji, decomposed Hangul and whitespace are preserved. A quote cannot be fabricated or borrowed
from a different source; matching text proves source presence, not the correctness of a critique.

Official criterion judgments retain allowed question evidence IDs and existing mapping rows.
Local sentence observations have no fake official reference. They require independent trusted
review of the exact issue/sentence payload. [Server-only adapter](../tool/essay_lab/scaffolding_adapter.py)
rejects a provider-supplied `local_reviews` field and requires separate review input; SQL checks
that approval matches the exact root and quotations. Wrong/absent approval fails closed.

This is an explicit **trusted worker/reviewer boundary**, not a SQL semantic classifier or a
cryptographic proof that a critique is true. The hosting worker must authenticate its review
source; it must never copy provider claim_scope into an approval automatically. That production
review workflow and pedagogic accuracy remain gates before real AI traffic. No credential,
provider call or reviewer UI was added. Normalized keys do not create permanent student weaknesses.
A resolved prior local issue may have no new sentence finding: require verified predecessor,
current immutable source and explicit review, never invent an error sentence to show resolution.

## Atomicity and deletion

The1.3 validator runs within the existing fenced finalization transaction. It prepares server-owned
observation envelopes, records progress/official evidence, completes the evaluation, and settles
billing together. Invalid fragments roll back all results; a settlement fault after result writes
also rolls back progress/dimensions and consume. Same run/payload retries remain idempotent.
All completion immutability and erasure guards apply to the new column. Learning erasure removes
observations; financial history survives under its existing retention rules.

## Actual validation and reproduction

| Executed check | Result |
|---|---|
| New scaffolding native matrix |80 PASS |
| New scaffolding actual JWT/PostgREST matrix |79 PASS |
| Existing native reference / server transactions |77 /55 PASS after migration |
| Existing JWT regression |37 PASS before and37 PASS after migration |
| Review / migration-security-adapter static tests |55 /27 PASS |
| Existing Flutter sentence/Workspace + analyze |27 PASS /PASS |



[Native runner](../supabase/validation/essay_lab_product/scaffolding_runtime.py) uses the existing
explicit-consent/numeric-loopback/empty `essay_review_*` PostgreSQL17 guard. It clean-applies the
forward migration, runs legacy77+55 checks, then the scaffolding matrix including concurrency.
[Supabase runner](../supabase/validation/essay_lab_product/scaffolding_supabase.py) first verifies a
new isolated local Docker project/port and empty public schema, runs37 JWT checks, creates and
claims a real1.2 job **before** the new migration, applies it, completes that in-flight result,
then repeats37 checks and the1.3 matrix through Auth-issued JWT/PostgREST. SQL role checks are
not reported as JWT tests. Worker JWTs are synthetic local role credentials, never client tokens.

Use a fresh dedicated environment, never the linked repository project:

- Native: private `ESSAY_REVIEW_TEST_DSN`, `ESSAY_REVIEW_DISPOSABLE=YES`; execute `scaffolding_runtime.py --native`.
- Supabase: new project ID `essay-review-*`, private chmod600 CLI status file; set
  `ESSAY_REVIEW_LOCAL_PROJECT_ID`, `ESSAY_REVIEW_SUPABASE_STATUS_FILE`, consent; run `scaffolding_supabase.py`.
- Python dependencies: psycopg[binary], pglast in a temporary venv. Native runner includes baseline setup;
  Supabase runner includes guarded preparation. Neither resets an existing database.
- Offline: `python -B -m unittest discover -s supabase/validation/essay_lab_product -p 'test_*.py'`.
- Shut down only these disposable environments afterward. No DSN/JWT/email/private answer in reports.

UI remains unchanged. Existing sentence/Workspace27 tests (including360px/200%) and analyze PASS;
this is regression evidence, not a new live UI persistence adapter. The review fragment contract
is preserved; [runtime contract](../tool/essay_lab/evidence/evaluation_contract_v1_3.json) specifies
RPC field mapping. Independent AI/pedagogy validation remains NOT_RUN.

## Existing submit timing issue — historical discovery, not a scaffolding regression

Runtime exposed migration003's existing expression:
`least(d.active_writing_seconds, greatest(0, extract(epoch from now()-d.started_at)::int))`.
PostgreSQL LEAST ignores NULL; casting numeric to int rounds. At0.7s elapsed with unspecified
active time, this can produce1s and violate essay_attempts_check1 (`active <= elapsed`). No
scaffolding function changes this expression. Synthetic scaffolding fixtures explicitly report
0 active seconds; they do not simulate writing time. This limitation is not hidden as a full
unknown-time submission PASS.

A narrowly proposed NULL-preserving/floor correction was **rejected by automatic approval review**
as outside the approved scaffolding scope and conflicting with preserving1.2 behavior. No such
change was made. Owner was asked whether to authorize a separate fix. Until separately authorized,
retain the issue as a rollout prerequisite; do not weaken the CHECK or alter history to pass tests.

Owner subsequently accepted this result and separately authorized the linked timing correction.
This report and its original validation artifacts retain their historical scope.

Subsequent Production apply is verified in the linked deployment report.
Next: Owner reviews Production results → separately authorizes Scaffolding AI Pilot.
Real student/provider traffic remains disabled.
