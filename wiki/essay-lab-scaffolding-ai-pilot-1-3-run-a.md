# Scaffolding AI Pilot 1.3 / Run A

2026-09-29 · **EXECUTION PASS / QUALITY PARTIAL / OWNER REVIEW PENDING**.
Owner authorized exactly one Sookmyung2025 mock Q1-1 and one Hanyang2024 humanities
Afternoon2 run. Both first outputs frozen, no retries. Production DB was not accessed;
no Production AI, student rows, worker enabling, schema/UI change or new evidence collection.
[Machine result](../tool/essay_lab/evidence/scaffolding_run_a_1_3_result.json).

## Method and privacy

Reused accepted source images/evidence and image-checked frozen reading transcriptions.
Hanyang's existing uncertain handwriting marker is unchanged; no guessed characters.
Only question/passages/intent/criteria/answer supplied. No quality labels, reference-answer
body, prior evaluation, rewrite output or ground truth supplied to the isolated generator.
Official source answer remains the blind target answer; it is not a second reference answer.
Codex CLI0.157.1, gpt-6-astra/high, ephemeral empty workspace; tools/web/memories/plugins
and project instructions disabled. Event log checked for tool activity. One exclusive
attempt marker per case; no retry after failed or successful execution.
Prompt `scaffolding-1.3-v1-blind-pilot-a`; version/hash/input/model/usage/latency receipts
and raw JSON frozen before ground-truth reveal. Server model revision/cost UNKNOWN;
CLI tokens are not a product API cost estimate.

Private `.local/essay-scaffolding-1.3-run-a/owner-review.md` contains both full original
answers and every generated evaluation, root/action, sentence diagnosis/direction,
checklist and evidence mapping. Git contains no original, prompt body, model feedback
body, sentence quote, reference answer, token or credential. Frozen source provenance
remains university-published high-scoring answer; individual official scores unknown.

## Results and post-freeze review

| Item | Sookmyung | Hanyang |
|---|---|---|
| Runs |1|1|
| Core / sentences |2 / 2|3 / 4|
| Dimensions |7 reporting axes, not seven official weighted criteria|5 official criteria|
| Exact code-point spans |2/2 PASS|4/4 PASS|
| Latency |77.132s|120.981s|
| Input / output tokens |18859 / 2402|29015 / 3760|
| Priority / strengths |PASS / PASS|PASS / PASS|
| Scaffolding discipline |PASS|PARTIAL|
| Sentence feedback |PARTIAL|PASS|
| Criteria / stance / hallucination / Korean |PASS|PASS|
| Overall |PARTIAL|PARTIAL|

Sookmyung correctly recognizes mean/cohort reasoning and selects two actual official
content omissions. Earlier teacher-responsibility repetition across5/7 dimensions falls
to2/7, though some reporting-axis overlap remains. Neither omission is a fabricated
criterion. However both otherwise intelligible sentences receive `unclear_meaning`:
content supplementation is not necessarily an unclear sentence. This is an observed
classification/overcorrection risk, not evidence of a wrong official grade.

Hanyang independently selects the four prior substantive issues: B's premise, sanction
direction, current/future aggregate welfare and the minority-rights criticism. Two
aggregate-welfare applications share one root, without duplicate spans. Student opposition
is preserved; explaining the required utilitarian justification is not a new personal
policy endorsement. First core action is dense and combines two tasks. Compression is
mentioned in a dimension, but explicit official-length checking is absent from the
checklist. Not guessing deductions from transcription length is appropriate; omitting
all guidance to check the original grid length is a remaining limitation.

No fabricated quote/new criterion or stance change detected in post-freeze self-review.
No optional sentence examples generated. Hanyang has one short grammar example within
its expression dimension. Quote accuracy does not establish diagnosis correctness.
All roots use official criteria plus separate student quotes: quote-only local_sentence
review path NOT_EXERCISED. No previous evaluation was supplied, so no growth/resolution
or previous-core history quality claim. Two positive fixtures do not calibrate scores,
weak-answer discrimination or real-student outcomes. Human Owner acceptance still pending.

## Contract gap — keep visible

Educational1.3 scaffolding fields were exercised, **not exact Production transport**.
Pilot `uncertainty_note` is an extra reporting field rejected by the deployed1.3 provider
output whitelist. Pilot attempt/criterion/evidence IDs are explicit non-DB aliases.
Current adapter does not strip that field. Thus **RAW RPC COMPATIBILITY: NOT_COMPATIBLE_AS_IS**;
Production ingestion NOT_RUN. The custom deterministic shape/quote PASS is not RPC PASS.
No frozen output, accepted contract, adapter or migration was changed to hide the mismatch.
Before any future provider-to-RPC use, separate reporting metadata and explicitly resolve
bound input identities; test that boundary. Do not reuse this Pilot schema as Production
provider schema. This task does not implement or authorize that integration change.

## Validation and stop

Pilot tests cover supported empty output, emoji/decomposed Hangul/whitespace offsets,
fabricated quote, duplicate spans, limits, answer/history binding, reporting-field gap,
accepted input-only assembly and exclusive no-retry marker. No tests invoke AI.
Focused historical runner/rewrite tests and Wiki handoff/diff/privacy checks are recorded
in the machine result. No database/runtime suite rerun: no persistence changes.

Next: Owner reads private full report → separate approval for rewritten-answer/second
Scaffolding Pilot. No additional model call, Production AI activation or student traffic.
