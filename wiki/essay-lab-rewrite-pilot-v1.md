# Essay LAB — 첨삭을 반영한 예시 답안 Pilot v1

2026-09-28. Scope: one Hanyang2024 humanities-afternoon-2 rewrite, then one independent
Sookmyung2025 mock-humanities question1-1 rewrite. Reuse frozen diagnoses; no evaluation
rerun, generated-answer scoring, model comparison, Production changes or UI implementation.
Starting HEAD2341b2a, branch codex/day-7-school-neis, origin matched.

## Canonical product decision

Student first: write → diagnosis → strengths → improvements → priorities → **직접 다시 써보기**
→ own revision → later re-evaluation. An optional **첨삭을 반영한 예시 답안 보기** must not
replace or precede the default invitation to revise independently.

Suggested explanation: “위에서 안내한 보완점을 반영하면 다음과 같이 고쳐 쓸 수 있습니다.
이 답안은 하나의 예시입니다. 정답처럼 외우기보다는, 자신의 답안을 다시 작성할 때 참고해 보세요.”
Generated sample has `origin=ai_generated`, label **첨삭을 반영한 예시 답안**.
Never assign official/model_answer/university_example_answer/high_scoring_answer provenance.
Future presentation must visibly distinguish university documents from AI-generated samples.
This is a product-design direction, not implementation approval.

Preserve stance, argumentative order, strengths and wording wherever correction is not
necessary. Fix only confirmed issues, compress repetition, supply minimal required links.
No unrelated philosophy, sophisticated vocabulary replacement or reference-answer copying.
Reuse [Korean teacher tone](essay-lab-hanyang-2024-benchmark.md#student-facing-language-and-evaluation-philosophy--canonical-owner-policy).

## Source and private boundary

Original evaluations: [Hanyang v1.1](essay-lab-hanyang-2024-afternoon2-run-a.md) and
[Sookmyung v1](essay-lab-evaluation-pilot-2025.md). Both remain immutable.
[Scoped runner](../tool/essay_lab/rewrite_pilot_v1.py) reuses their input/hash validators
and authenticated isolated execution pattern. It never calls either evaluation execute.
[CLI execution documentation](https://learn.chatgpt.com/docs/non-interactive-mode) was
checked; no new provider integration. Separate ephemeral contexts, neutral image names,
no tools/web/history, exclusive one-attempt marker per case, freeze before inspection.

Generation receives only that case's question/passages/official intent/criteria, original
student image + checked transcription, and frozen strengths/improvements. Hanyang's four
issues stay four; Sookmyung's repeated teacher issue is consolidated by using the frozen
final improvements. No other case output, quality label, prior band, or official reference
answer is passed. Important distinction: the original student answer happens to have been
published by the university; the excluded item is an additional reference-answer edition
or its quality/provenance metadata, not the authorized student input itself.

Bodies, original images, prompts, raw generation, full before/after diff and Owner report
stay under ignored `.local/essay-rewrite-v1/`. Git contains only tooling, tests, hashes,
metadata and sanitized findings. Full texts are supplied privately to Owner on request
(as explicitly requested here), not in Wiki/public JSON/App bundle.

## Transcription and length convention

Source images were visually checked; no unverified OCR result is called the original.
Reading transcription joins physical grid line wraps and retains original arguments/errors.
Hanyang's uncertain two-character verb fragment is marked `[판독 어려움]`, not silently
repaired. Transcription length1296 includes the8-character marker, so it is **not an exact
handwritten-character count**. Known transcribed characters excluding marker1288; exact
original count remains uncertain. Sookmyung source explicitly prints324/330; readable
transcription counts330 with its spaces/punctuation. Do not rewrite the old evaluation's
source-count statement or pretend the two counting methods are identical.

Automated generated-text check: Unicode NFC code points including spaces/punctuation,
excluding CR/LF and outer whitespace. This is not a certified 원고지 cell-count algorithm.
Ranges: Hanyang1150–1250; Sookmyung270–330. Report measured length; never silently trim,
regenerate or declare compliance if the first result misses the range.

## Results and Owner gate

Results are recorded below after both independent outputs are frozen. Semantic checks
are operator comparison against accepted diagnoses, not an AI regrading run or score.
Lexical matching is descriptive only; high character overlap does not prove good editing.

## Frozen results —2026-09-28

[Sanitized manifest/comparison](../tool/essay_lab/evidence/rewrite_pilot_v1_result.json)
records full hashes, references, usage, character counts and bounded operator findings.
Both runs use gpt-6-astra/high; exact model version and API cost UNKNOWN. Do not
convert ChatGPT-authenticated CLI tokens into product API billing.

| Item | Hanyang | Sookmyung |
|---|---|---|
| Generation count / evaluation reruns | 1 /0 | 1 /0 |
| Freeze UTC | 01:49:43.854204 | 01:50:44.831849 |
| Generated length | 1158 | 310 |
| Range / compliance |1150–1250 PASS |270–330 PASS |
| Input/output tokens |25833 /3560 |16360 /1220 |
| Latency |126.976s |42.824s |
| Argument preservation |PARTIAL |PASS |
| Confirmed improvement coverage |PASS, all4 |PASS, all4 |
| Over-editing |PARTIAL |PASS |
| Natural Korean / criteria alignment |PASS /PASS |PASS /PASS |
| Student learning value / overall |PARTIAL /PARTIAL |PASS /PASS |

Hanyang output SHA256 `2301b72f68d0ae7c8a84ad8d9eb940760470f3f8965e8a368d623799cdc75d84`.
Sookmyung output SHA256 `e111ddfd062989fbba0b05f3f6ff97770b6dc7e53578d5f4d94d37c9ce692b06`.

Hanyang fixes B's premise, sanction direction, aggregate utility/rights argument,
and compresses theory/repetition. But it additionally states agreement with the
necessity of resource conservation. The original rejects the utilitarian decision;
it does not explicitly establish this positive policy stance. This is **one unnecessary
stance insertion (E)**, not automatically a harmless clarification. Main sequence and
critique remain, so operator verdict PARTIAL rather than claiming wholesale destruction.
Owner must decide its significance. First result stays unchanged; no corrective rerun.

Sookmyung preserves the sequence: interpretive error → general caution/example →
participant composition → critique. It supplies university access expansion and teacher
blame while compressing the stall/repeated group explanation. No unrelated argument or
unsupported stance detected. PASS is a bounded operator comparison, not proof that an
AI rewrite is superior to an official answer or a new grading score.

Change units manually classified after automated character diff:
A required correction /B clarification /C compression /D necessary addition /E unnecessary.
Hanyang A3/B1/C2/D2/E1; Sookmyung A1/B1/C2/D1/E0. These are reviewer-chosen meaningful
units, not automated semantic truth. Full opcodes and source/rewrite excerpts are private.

Character matching: Hanyang568 matched /1296 transcribed (43.83%); Sookmyung193/330
(58.48%). SequenceMatcher ratios0.4610/0.6031. This suggests lighter editing in Sookmyung
within these two examples; different lengths/problems prevent a general adaptive-editing
claim. Do not equate lexical retention with preserved stance: Hanyang illustrates why.

No additional official reference edition was supplied. Original student text already
matches its published version; expected overlap from retaining student words cannot be
called reference-answer imitation. No comprehensive plagiarism metric is claimed.

**REWRITE_FEATURE_READY_FOR_PRODUCT_DESIGN: CONDITIONAL.** Optional example is useful,
but explicit stance preservation needs Owner review before unconditional adoption.
Students first rewrite for themselves. No new UI/schema/framework and no further run.

Private Owner report: `.local/essay-rewrite-v1/owner_report.md` (both originals and first
outputs in full). Both outputs frozen before cross-case inspection. All prior evaluation
outputs, contracts, accepted-state and Owner files preserved. Production writes0.

Validation:75 focused tests PASS (12 rewrite +63 prior), no skips in this environment.
Source/label/cross-case checks, frozen hashes, exact measured lengths, private exclusion,
student terminology, Wiki handoff and diff check PASS. No Flutter changes/suite.
Scoped credential-pattern scan is performed on staged files before commit.
