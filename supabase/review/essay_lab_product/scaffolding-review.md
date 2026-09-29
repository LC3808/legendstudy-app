# Scaffolding / sentence persistence review — 1.3-review.1

2026-09-29 · REVIEW ONLY, NOT IMPLEMENTED / NOT APPLIED. No executable migration or RPC
replacement here. Canonical pedagogy: [Product](../../../wiki/essay-lab-product-v1.md).
[Machine review contract](../../../tool/essay_lab/evidence/evaluation_contract_v1_3.review.json).

## Recommendation and exact scope

**Reuse PARTIAL; KEEP19. Add one nullable JSONB column to existing
`public.essay_improvement_progress`: `scaffolding_observation`.**
No new table/index by default, no changes to existing PK/FK/history/grants, no backfill.
This is the refined version of yesterday's nullable sentence observation proposal.

Fixed v1 envelope: `{"version":1,"core_focus":true,"sentences":[]}`.
`core_focus` records the actual pedagogic selection, not a guess from priority or a label.
`sentences` supports multiple locations of one root without violating UNIQUE(issue,evaluation).
Each contains observation_key, category, priority class, start, end, quote, diagnosis, direction,
optional example. Parent issue_id/evaluation_id → attempt_id supplies the persisted relation;
provider linked_issue_key must resolve to that parent, never another student's issue.
The source text is a short exact excerpt, not another answer-body store.

Why not only quote/span/example? New requirements also need reconstructable **previous CORE**
selection; existing positive priority gives order, not whether a task was selected as core.
One bounded envelope carries this small fact without a second column/table or JSON in text.
Why not one object per sentence? One root can need two sentence examples; progress is1:1 per
issue/evaluation. Root explanation/action and sentence-local diagnosis/direction have different
meaning. Preserve both without copying identical prose. Structured category remains queryable
via `jsonb_array_elements`; no speculative index or taxonomy master now.

Required future CHECK/helper validation: NULL or exact allowed envelope keys/version;
boolean core_focus; array0..5; each item has exactly allowed keys, strict enum/string/integer types,
nonblank quote/diagnosis/direction, valid optional nonblank example and unique observation_key.
Cross-row checks belong in the atomic finalize operation: evaluation total<=5, focus<=3,
linked issue membership, span uniqueness, answer hash/body slice and evidence provenance.
NULL means legacy/not provided; `sentences:[]` means supported but no sentence observation for
that root. Evaluation contract version also distinguishes supported zero-improvement output.
Existing terminal-parent/history guards cover the new field: freeze on completion; erasure
uses existing learning cascade and separate financial retention. No direct client/worker writes.

## Verified baseline and narrow blockers

Compared current repository migration001/003 and accepted deployed
[security result](../../validation/essay_lab_product/security_resolution_result.json), which records
47/47 definition match,19 tables,4 additive columns,12 RPCs and current security acceptance.
**This task did not query Production again.** Historical runtime/security acceptance is evidence
of the deployed baseline, not proof that this unimplemented extension already works.

| Existing boundary | Exact blocker | Minimum next-phase change |
|---|---|---|
| attempts/evaluations | None for immutable source binding | Resolve source from trusted job, reuse hash, contract/regime and input_snapshot |
| progress | No structured span/subcategory/example or explicit core selection | One envelope above; preserve existing root/category/status/priority |
| request_evaluation snapshot | Fixed1.2, no selected previous-core history | Explicitly approved new regime branch; snapshot scaffold context and its hash |
| worker_claim | Prior improvements returned only for whole-example generation; normal evaluation lacks them | For new regime only, assemble selected predecessor history before provider work |
| finalize_success | Drops unknown sentence data, requires nonempty official evidence for every improvement | Version-dispatched strict validator; store envelope; narrow quote-only exception below |
| previous_progress check | Accepts a valid earlier link but does not require review of all previous core tasks | Validate exact selected predecessors; record assessed links, unknown reasons separately |

No changes to submit/draft, leases, locks, account/grant order, settlement, refund or rewrite billing.
Provider network call stays outside DB transaction. A future invalid output must roll back the
entire result and settlement; no partial sentence save. Old in-flight v1.2 requests retain old
rules; no silent new fields ignored or new regime assigned by the client/provider.

## Input / output and history

Proposed contract **1.3-review.1**, not activated1.3. v1.2 hash is frozen in the review artifact.
It inherits all old rules/outputs and proposes core_improvement_keys, previous_improvement_reviews
and sentence_feedback. This review notation is not a drop-in RPC/provider JSON Schema; next
phase must explicitly map legacy overall_feedback/criterion_feedback to RPC summary/dimensions.
The current Flutter DTO also lacks linked_issue_key; its future adapter must add/resolve that
binding. Existing UI display safety alone is not persistence validation.

At request time choose one compatible completed earlier evaluation in the same session, owner,
question and regime, not a moving latest lookup. Snapshot selected evaluation/attempt/hash,
core progress IDs and reviewed resolved candidates, compatibility reason, contract/prompt/evidence
versions and history manifest hash inside existing input_snapshot.scaffolding_context.
A regenerated assessment of the same answer is not a rewrite. Legacy rows have unknown core
selection: do not infer past focus retroactively. Allow an explicit unavailable/incompatible
context; assess current answer without claiming longitudinal progression.

Every previous core gets exactly one review before choosing current focus. Assessed reviews
create new progress with previous_progress_id on the same root. Existing OPEN, UNCHANGED,
IMPROVED, RESOLVED, RECURRED meanings remain; no update of previous status or silent new root.
For not_assessable, do not write a false progress status. Preserve the reason in existing
uncertainty_note; the snapshotted required ID list minus linked assessed rows identifies the
unassessed tasks exactly. Reasons are narrative (no JSON hidden in text), not a new analytic status.
No missing row is interpreted as resolved. Preserve findings even if not selected as one of the
current1–3 focus tasks; their envelope core_focus=false and priority still orders detail.

A previous resolved issue recurs only with explicit same-branch resolved reference and current
evidence. Similar wording/normalized key alone cannot auto-link another session or establish a
permanent student weakness. Root matching uncertainty requires review, not forced consolidation.

Synthetic walkthrough: Attempt1 issue X OPEN/core; Attempt2 X RESOLVED plus Y OPEN/core;
Attempt3 Y IMPROVED/core; Attempt4 X RECURRED with explicit resolved predecessor. Query progress
with evaluation→attempt/regime and envelope core_focus shows what was taught at each step.
Previous-core snapshots and linked progress show which tasks were actually revisited. Level
changes alone do not prove that X resolved. Missing/uncertain observations stay unknown.

Longitudinal categories/counts compare compatible assessed evaluations and distinguish
not-observed from not-provided. Zero sentence observations is not proof every sentence is correct;
selection budgets limit observed coverage. No fabricated “decreased” claim from fewer selected items.
No-growth snapshot/AI narrative table; analytics remain derived from facts with sample/time scope.

## Two provenance paths, not fake official evidence

| Claim | Official mapping | Own answer span |
|---|---|---|
| University criterion / passage application | Required, existing allowed question evidence | Required for sentence observation; optional for nonsentence root |
| Local grammar / expression / structure / internal contradiction only | May be empty after trusted scope review | Required exact verified span for an active finding |
| Logical contradiction involving criterion/passage | Required | Required |

Proposed validator claim_scope=`official_criterion` or `local_sentence` is a **review classification**,
not a provider-controlled permission switch. Category alone cannot authorize the exception:
internal sentence contradiction can be local, while passage/theory interpretation needs official
evidence even if tagged “expression”. A trusted adapter must confirm that
the diagnosis makes no university/passage claim. If uncertain, reject/hold; never invent an ID.
Keep dimensions' official evidence requirement unchanged. An official root with local grammar
examples retains official evidence for the root; the grammar example does not claim that the
university authored a grammar rule. Mapping and own quote locations stay distinct.

For a **resolved prior local sentence issue**, current sentence_feedback may be empty: the server
requires its explicit verified predecessor plus current immutable answer/hash and a reviewed
resolution explanation. This disposition uses the existing progress link and text, not a fabricated
“problem sentence” or fake official reference. Uncertain absence remains not_assessable. The
absence of an old quote alone cannot establish resolution; the whole current relevant argument
must be reviewed. Runtime tests must cover this separate branch.

Storage provenance is reconstructable: existing official mapping rows plus own-span observations;
no duplicated PDF, fake resource or quote-as-resource. Server derives attempt/hash from evaluation
FK and frozen input, validates Unicode code points [start,end), no trim/NFC/UTF16 substitution.
Exact quote equality proves source existence only. Truth of diagnosis, stance preservation,
minimality, useful progression and nonrepetitive instruction require human/independent quality
review in the later separately authorized AI Pilot.

## Next-phase runtime validation plan — NOT_RUN

Use disposable PostgreSQL and local Supabase with synthetic users/short answers only. Preserve
existing19-table security suite,77 reference assertions,55 operation checks and37 JWT checks.
Do not execute fixtures in Production or reuse private Pilot answers.

| Gate | Required assertions |
|---|---|
| Minimal DDL | One column only; old NULL rows/readers unaffected; explicit envelopes reject unknown keys/types/counts; no privilege changes |
| Version dispatch | Old1.2 jobs remain old; new snapshot contract/prompt/regime match; same attempt coexisting results; no retroactive stars/focus |
| Quote binding | Exact owner/evaluation/attempt/hash; emoji/code-point vs UTF16, decomposed Hangul, whitespace, repeated sentence positions; cross-user/draft/fabricated quote rejection |
| Input history | Frozen predecessor selection; cross-session/regime/newer/invalidation rejection; missing/unavailable history explicitly unknown |
| Focus/roots |0/1/3 focus;0/1/5 sentences accepted; excess/duplicate roots/spans rejected; two sentences of same root accepted; missing linked issue rejected |
| Progress | OPEN→IMPROVED→RESOLVED→RECURRED appended; all rows/versions retained; review all prior cores before new focus; unassessable leaves no fake status |
| Provenance | Allowed official IDs only; pure local grammar without official IDs accepted; unapproved local scope/cross-question IDs/fake university attribution rejected; resolved local issue needs no invented current sentence; dimension requirements unchanged |
| Atomicity | Invalid observation after result write causes full rollback including consume; duplicate retries do not duplicate progress; stale workers denied |
| RLS/JWT | Owner read; other/anon denied; client/direct worker cannot modify observations; server-only finalize and immutable-completed guard remain |
| Erasure | Envelope removed with learning progress; no new external copies; financial ledger survives existing policy |
| UI adapter | Trusted linked issue + source binding; counts/optional example/empty vs missing;360px200%; preserve current placement/collapse behavior |
| Growth queries | Recover selected focus and status timeline; exclude unknown/incompatible comparisons; cross-session normalized candidates never treated as confirmed permanent weakness |

Offline tests in `test_scaffolding_contract.py` check review invariants using synthetic fragments.
They do **not** validate PostgreSQL, provider behavior, semantic diagnosis or Production.
Next: Owner/ChatGPT review → implement minimal persistence + versioned adapter → isolated runtime
and regression → separate Scaffolding AI Pilot approval. No migration/apply or AI permission implied.
