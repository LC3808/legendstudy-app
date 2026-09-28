# Hanyang2024 / Evaluation Contract v1.1 — preparation, target mismatch

Historical afternoon1 record preserved. Owner stopped this target; see the later
[afternoon2 frozen Run A](essay-lab-hanyang-2024-afternoon2-run-a.md): execution PASS, benchmark PARTIAL.

2026-09-28 · **BLOCKED BEFORE MODEL RUN; NOT A BENCHMARK RESULT**.
Starting HEAD60ab454, branch codex/day-7-school-neis, local=origin. Owner scope is
one2024 admission humanities-afternoon-1 benchmark, not historical expansion.
Sookmyung first Run A/output/contract remain immutable. Hanyang2025 REVIEW unchanged.

## Source inspection and decisive mismatch

Owner Downloads supplied all7 named PDFs; the additional unsuffixed business-answer
copy is byte-identical to `(1)`. All7 named files match the existing post1659
Materials resources byte-for-byte. No resource/source insertion or upload.
[Sanitized source manifest](../tool/essay_lab/evidence/hanyang_2024_benchmark_source.json)
records UUIDs, hashes, page counts, preview locators and review reasons.

The file named **인문계열(오후1) 합격자 예시답안** is not an answer to that exam:

| Evidence | Finding |
|---|---|
| Expected humanities afternoon1 question | 노자 / 슬견설 / 캠든 벤치,1200 characters |
| Answer PDF page1 | Business question1: SNS, political affective polarization, bonding/bridging groups |
| Answer PDF page2 | Business question2: mathematics calculations |
| Mislabeled resource | `75dd05ef-dda7-55c7-a5cf-92e1001bbbda` |
| Business answer resource | `c30fa960-1186-5242-ad00-506bce75f57d` |
| Embedded page images | Both two image SHA256 values equal despite different PDF container hashes |

Page1 image SHA256 `a42fbc1be17cfd382a8f3d8d909cd60a7ad571bc45c660ded6c7e3ab5ec53757`;
page2 `f7dfac9f7e761a529f89f4b14d49080d43651ccf0977a32eacd0c0b61bfe4e9e`.
Visual reading confirms the wrong subject/session; this is not a filename-only finding.
Do not map this resource as afternoon1 example_answer. Do not evaluate it against
노자/캠든 벤치, relabel it silently, overwrite/delete the Materials row, substitute
another exam, or manufacture an answer. Existing source remains preserved.

Afternoon2 remains a separate identity. Its answer content (future generations,
social contract, utilitarianism) matches its question; it was not evaluated or used
as a replacement for the approved afternoon1 target. Role candidate stays
example_answer, not high_scoring_answer. Official answer URL remains unresolved.

## Official source / mapping preview

- [Official afternoon1 posting](https://go.hanyang.ac.kr/web/pds/pds_view.do?bn=13536&m_type=SUSI)
  attachment file_no2185 byte-matches Owner/existing resource
  `3e2a4997-8673-5dff-ab26-c2342b0b6bf0`.
- [Official afternoon2 posting](https://go.hanyang.ac.kr/web/pds/pds_view.do?bn=13537&m_type=SUSI)
  attachment file_no2186 byte-matches `91d95b4b-de81-53a9-a2f8-314aac218c2b`.
- These postings contain question PDFs only. They do not independently verify the
  answer/criteria files. Do not claim a question URL proves all roles.
- Shared criteria resource `b5d0d455-1f31-5372-af49-b1d24e190b6d`: afternoon1 intent p1,
  criteria/weights/bands/deductions/cautions pp2–4; afternoon2 pp5–8.
  University heading/content match is established; exact official criteria URL REVIEW.
- Schema sufficient: existing university identity, admission_year2024, distinct stable
  exam_key and session_label, existing resource UUIDs + multi-role locators.
  **Canonical mapping preview only; Production apply0**, no partial ready-exam claim.

Private `.local/hanyang-2024-v1.1/partial_package.private.json` holds the actual
question/passages and afternoon1 criteria. It is explicitly PARTIAL and not model
input; student_answer is NULL. Source JSON text removes no answer text because no
answer is assembled. No full body/image enters Git. No blind fixture, provider call,
output, output freeze or ground-truth reveal was generated. No university answer
quality label was sent to a model.

## Contract v1.1 prepared, not empirically validated

[Contract v1.1](../tool/essay_lab/evidence/evaluation_contract_v1_1.json) references
immutable v1 by hash and retains its output keys. Existing v1's SKKU-only scope and
40/40/20 weights must not transfer to other exams; current exam evidence controls.

Minimal change: merge the same root weakness into one improvement. Criterion-level
relationships may be explained briefly; final improvements and priorities must not
restate the same criticism with different wording. Priorities order concrete actions,
not duplicate paragraphs. First explain core achievements; do not let one small
limitation make the entire answer appear weak. Do not invent weaknesses.

Afternoon1 source shows10/20/20/40/10% domains and official A/B/C/F descriptors with
numeric bands. These are source criteria, not this student's known score. An eventual
model may cautiously compare to official bands; never claim an exact actual score
or a known admission outcome. No scoring has been performed.

**No result sample is fabricated.** Duplicate-feedback control, level calibration,
reference correctness and student-language quality of generated output are NOT_RUN.
Sookmyung v1 remains execution PASS/benchmark PARTIAL (E10 repetition5/7 criteria).
Hanyang v1.1 comparison = NOT_CONFIRMED. Different exams could not establish causal
performance improvement even after one future successful run.

## Student-facing language and evaluation philosophy — canonical Owner policy

Explain reasons before numbers. Recognize what the student accomplished first.
Explain limitations using actual university criteria; combine repeated weaknesses,
prioritize concrete improvements, and tell the student what to change next time.
Respect university-specific expectations. Do not invent criteria or confidently judge
unreadable/uncertain evidence. Treat the student as a learner who can develop.

Tone: a considerate essay teacher explaining specific strengths, then the next useful
change. Friendly, precise, brief and cautious; avoid intimidating or mechanical wording.
Keep 논제/제시문/논거/논증/반론/비교/분석/평가/추론 where useful, with short explanation
if needed. Remove unnecessary English, AI and implementation jargon from student prose.

| Internal identifier | Student presentation |
|---|---|
| overall_feedback | 종합 평가 |
| strengths | 잘한 점 |
| criterion_feedback | 평가 항목별 진단 |
| improvements | 보완할 점 |
| revision_priorities | 먼저 고쳐야 할 부분 |
| evidence_references | 평가 근거 |
| exam_intent / scoring_criteria | 출제 의도 / 평가 기준 |
| example_answer / model_answer / high_scoring_answer | 예시답안 / 모범답안 / 우수답안 |
| uncertainty | 판단이 어려운 부분 (필요할 때) |

Suggested presentation order: 종합 평가 → 잘한 점 → 평가 항목별 진단 → 보완할 점 →
먼저 고쳐야 할 부분 → 다시 쓸 때 확인할 것 → 평가 근거. This is not UI implementation
or a new mandatory output entity. Internal keys/enums remain stable. UUID/locator
stay traceable internally; student labels use e.g. “한양대학교 평가 기준 — 관점 적용”.
Do not expose rubric/criterion/PASS/PARTIAL/FAIL/ground truth/benchmark/calibration/
hallucination; especially do not call an AI error “환각” in student guidance.

## Business second benchmark candidate

Existing business question resource `b9674fd0-41ae-5713-afa4-66d367040027`, question1
PDFp2; question2 pp3–4. Existing criteria `41e3ee39-bb56-572b-a2b3-038d0ca40196`:
question1 intent/rubric pp1–2, math question2 p3. Respondent images in business answer
PDFp1/p2 match both subject matters. Source identifies2024 business admission.
[Official business question posting](https://go.hanyang.ac.kr/web/pds/pds_view.do?bn=13535&m_type=SUSI)
was located in the official list; attachment binary not independently downloaded here.
Official respondent designation/answer URL and criteria publication need confirmation.
**SECOND_BENCHMARK_CANDIDATE: REVIEW**, content relationship YES, official verified
high_scoring designation not claimed. No second AI run, no inferred student grade.

## Review queue, validation and next gate

- H24-R01: correct humanities-afternoon1 respondent answer is absent from the supplied
  file under that name. Need a source-matched answer, not manual transcription.
- H24-R02: official exact criteria/respondent publication references unresolved.
  A relevant official archive fallback may describe provenance, but does not turn an
  unverified answer into verified evidence. No broad research launched.

48 focused tests PASS: new7 real-data/contract guards + prior41. Actual PDF hash and
embedded-image regression exercised, no skips in bundled runtime. Partial package
rebuild is deterministic; official questions byte-match; source resource UUIDs unique.
No output-schema/AI-output/semantic-dedup performance PASS claim: evaluation NOT_RUN.
Flutter NOT_RUN (no Flutter change). Private exclusion, protected hashes, secret scan,
Wiki handoff and diff check are closeout checks. All evaluation cost/latency/tokens
NOT_APPLICABLE because run_count0; no product API estimate from CLI usage.

Production writes0, new resource0, schema/migration NONE. Owner iOS files and accepted
state preserved. Source/rights review remains required before public expansion.
Next: resolve these bounded evidence issues, then the already requested one-shot
v1.1 benchmark can proceed. No afternoon2/business/SKKU substitution or Sookmyung rerun.
Productization readiness from this attempted benchmark: **NOT_ASSESSED**.
