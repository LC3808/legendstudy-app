# Hanyang2024 humanities-afternoon-2 — frozen Run A v1.1

2026-09-28. Starting HEAD `9fdccb8`, branch `codex/day-7-school-neis`, local=origin.
Owner changed target after the [afternoon1 mismatch](essay-lab-hanyang-2024-benchmark.md).
H24-R01 remains preserved; afternoon1 is no longer pursued. No correction/deletion.

**Execution PASS; benchmark PARTIAL. Exactly one run. No rerun.**
[Sanitized result](../tool/essay_lab/evidence/hanyang_afternoon2_benchmark_v1_1.json)
contains scorecard, student-facing condensation, hashes, usage and review limits.
This is not a claim that the university answer is poor or that the model knows its score.

## Verified official provenance and reused source

[University-hosted 2025 논술가이드북](https://go.hanyang.ac.kr/resources/upload_data/pdf/20240503114801523_.pdf)
contains the2024 exam; guide publication year is not admission year.
[Official guide archive](https://go.hanyang.ac.kr/web/guide/guidebook.do) is fallback only.
Official guide SHA256 `6de905abebcc25734b21abe4a939ebf1bb00ea605633195439b5e4c260a82a20`.
The exact university PDF was downloaded privately and visually inspected, not inferred
from a search snippet. No full PDF/body/image is added to Git.

| Evidence | Existing resource / source locator | Independent official reference |
|---|---|---|
| Question/passages | `91d95b4b-de81-53a9-a2f8-314aac218c2b`, PDF2–3 | [Question post](https://go.hanyang.ac.kr/web/pds/pds_view.do?bn=13537&m_type=SUSI), file_no2186 exact binary match reused |
| Intent | `b5d0d455-1f31-5372-af49-b1d24e190b6d`, PDF5 | Official guide PDF51 / printed49 |
| Criteria | same resource PDF5–8 | Guide PDF52–53 / printed50–51; five weights10/25/25/30/10%, A/B/C/F and formal rules |
| Selected answer | `2c82e2fa-096e-56ee-a310-eee6a7c12d76`, **PDF2 only** | Guide PDF54 / printed52 explicitly labels same response “합격자 우수답안” |

Full handwritten page2 response was visually compared with the official typeset answer:
argument sequence, wording and conclusion match. Layout differs; **not a binary match**
between handwritten answer and typeset guide. Original selected embedded image is used
without OCR/rewrite/correction. Page1 is not included or claimed verified by this match.
Existing role remains example_answer; no Production role change. The stronger guide
label belongs to operator provenance only. Actual university score is UNKNOWN.

Source facts and mapping preview are in the
[source manifest](../tool/essay_lab/evidence/hanyang_afternoon2_source.json).
The guide is an official evidence reference, not a new Materials resource/upload.
Exact URLs are distinct from resource delivery URLs. Attribution is not rights clearance;
source/rights review remains required before public expansion.

## Blind boundary and immutable execution

[Runner](../tool/essay_lab/hanyang_afternoon2_run.py) reuses the existing isolated CLI
adapter. Package: question2images + official intent1 + criteria2 + original student1.
Model sees neutral filenames and question/criteria references only, no answer subtype,
original answer filename, university selection label, Owner prior, expected band or
reference answer. Image headers visually checked. Assembly deterministic; source,
contract and every image hash verified before execution. No evaluator tool calls.

`evaluation_contract_v1_1.json` is **byte-identical** to approved prepared file:
SHA256 `92a84addc22045a62be66009a3d637f6f94344214f8cccd737384a0c69bb08cf`.
Its historical scope/status still records afternoon1 preparation. Latest Owner target
is explicitly recorded by the run manifest; only immutable rules/score policy are used,
not old scope/status. No hidden post-result prompt/contract revision.

- Model: gpt-6-astra, high reasoning, existing authenticated CLI; exact server version UNKNOWN.
- Input SHA256: `714bc8fa76d4f4f945e0f0e22a7f0ac571feae2c86eee02e09eb2a0b4d33dcd6`.
- Output SHA256: `c456184b9ad875aceebb910bbf0e8717ef49d4bfa5fc64aefdae3b8318b10457`.
- Freeze:2026-09-28T01:23:10.731012Z, before operator reveal/read of result.
- Private directory: `.local/essay-evaluation/hanyang-2024-afternoon2-run-a/`.
  raw_output.json, events, prompt, input/frozen/validated receipts and reveal.json.
- Exclusive attempt marker prevents another run. Frozen files read-only; no result replacement.
- Images6; input3,822,890bytes; output7,883bytes; latency96.961s.
- CLI tokens input25,183 / output3,024 (reasoning1,034). API cost UNKNOWN;
  authenticated CLI usage is not a product API billing estimate.

## First result — do not turn PARTIAL into PASS

The model recognized task coverage, the two social-contract conditions, welfare-based
reasoning and the minority-rights critique. But it emphasized shortcomings in all three
high-weight domains and explicitly said A-level fulfillment was difficult to recognize.
It did **not** strongly identify the answer's positive benchmark level.

Source-grounded review found the following critiques supportable:

- The answer denies B's life being better than nonexistence, whereas the passage assumes it.
- Intergenerational sanctions need clearer direction: future people cannot sanction current people.
- Official criteria expressly require comparing current+future net pleasure, not only future welfare.
- Minority rights can be violated despite their suffering entering the total, not necessarily exclusion.
- Writing continues beyond the1260 grid marker; official no-deduction range1150–1250.
  The model assigns no exact score/deduction and leaves an uncertain handwritten word unjudged.

These findings do not establish a known university score or prove undergrading.
University-published successful answers need not be perfect. Conversely, the model's
opening emphasis on three deficits and only “theoretical foundations” may undervalue
achievement for students. **K01 concern remains unconfirmed grading error; K11 minor
presentation imbalance/length.** No detected invented criterion or citation mismatch.

| Check | Result |
|---|---|
| Level recognition / weakness calibration | PARTIAL |
| Task, passage, reasoning, official criteria, concrete strengths | PASS |
| Final weakness deduplication | PASS —4 distinct action groups |
| Evidence grounding / hallucination control | PASS in this inspected case |
| Actionability / natural Korean | PASS |
| Teacher-like tone / achievement balance | PARTIAL |
| Overall | **PARTIAL** |

Review is operator source-grounded analysis, not an independent human grading panel.
Student summary in sanitized JSON faithfully retains the unfavorable A-level judgment;
it is a condensation of the frozen output, not a second model answer. Its rewrite checklist
is derived from original priorities. Full student-answer text is not reproduced.

## Sookmyung v1 comparison and next gate

Sookmyung v1: same teacher-responsibility omission in5/7 criteria, benchmark PARTIAL.
Hanyang v1.1: final improvements separate premise / sanction direction / utility reasoning /
compression-length; priorities are brief ordered actions. Related criterion-level mentions
remain, as permitted. No duplicate final issue inflation detected. Dedup improvement is
**observed**, not causal proof across different exams/answers.

Student presentation improvement PARTIAL: natural Korean and concrete next actions,
but long critical prose and achievement balance remain. Overall v1.1 improvement PARTIAL.
Productization readiness CONDITIONAL; no additional schema/framework needed.
Owner reviews this immutable first result before any next run, prompt change or product work.

## Preserved scope and validation

Production mutation0, new resource0, schema/migration NONE. Private artifacts ignored,
not public DB/bundle/Git. Sookmyung output/v1 unchanged; SKKU/Hanyang2025 accepted state
unchanged. Business provenance remains separate REVIEW, no business AI run.
H24-R02 resolved only for selected afternoon2 answer and criteria; H24-R01 preserved/stopped.

63 focused tests PASS (new15 + previous48), zero skips in the bundled runtime.
Wiki handoff/diff/private exclusion/protected hashes PASS. Tests cover contract identity, source/asset drift, blind assembly, locator/schema validation,
attempt guard, frozen chronology/hash, Korean output and duplicate checks. Exact string
checks supplement manual semantic review; they do not prove paraphrase or grading accuracy.
Flutter NOT_RUN (no Flutter changes). See closeout result for test count and Git checks.
