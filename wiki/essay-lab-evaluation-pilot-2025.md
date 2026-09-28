# 2025 Essay Evaluation Pilot preparation

2026-09-27 Owner scope: Sookmyung/Hanyang only, admission year2025. AI evaluation
was **not run**. Existing [SKKU package v1](essay-lab-evidence-package-v1.md) remains
PASS and unchanged. No new schema, UI, model comparison, OCR pipeline or broad
university/year research. Normal official material proceeds; individual exceptions
are reported together rather than stopping the batch.

## Applied canonical mapping

Existing controlled Pilot functions were reused with an explicit two-university
validator; the original three-university validator/default remains unchanged.
Source PDFs and Materials rows are reused, not inserted or duplicated.

| Scope | New universities | New exams | New official verified mappings | Reused resources |
|---|---:|---:|---:|---:|
| 숙명여자대학교 / sookmyung | 1 | 1 | 7 | 3 |
| 한양대학교 / hanyang | 1 | 1 | 6 | 3 |
| Total | 2 | 2 | 13 | 6 |

Production canonical totals: **5 universities /21 essay exams /134 mappings**.
Both exams use `2025 / mock-humanities`; their university IDs distinguish identity.
Exam source/header identity, not filename, establishes mock vs regular admission.
No metadata is filled from an inferred publication year. Official publication dates
are2024-07-31 and2024-08-28; admission year is2025.

Preflight collisions0; planned=actual; exact row/FK/provenance/locator checks PASS.
SQL `anon` and `authenticated` read and INSERT/UPDATE/DELETE denial probes PASS
(zero-row probes rolled back). Actual guest HTTP resource/mapping reads PASS;
this is not an authenticated user JWT session test. Orphans0/duplicates0.
Full-row fingerprints of existing canonical rows and all six Materials tables
matched before/after. Materials counts unchanged:443 source_posts /443 content_items
/298 exams /5112 exam_subjects /10556 resources /560 ingestion_quarantine.
No Materials activation/deactivation/deletion, accepted-state change or migration.

Inspect exact UUIDs, resource keys, locators, source hashes and scope in
[plan](../tool/essay_lab/quality_pilot_2025_plan.json) and
[result](../tool/essay_lab/quality_pilot_2025_result.json). No PDF/extracted body is
stored in these Git artifacts. Existing university master remains platform-wide.

## Sookmyung: READY

Selected exam:2025 mock humanities; package covers **계열문항1 (1-1/1-2)**.
It does not split item1 into a separate artificial exam, and does not claim item2
is packaged. Tomorrow's blind target is **문항1-1**.

- Existing source post1697;3 resources reused.
- Question/passages: `ed10de4d-3a33-5fbc-94f3-27ad7521f3cc`, PDF1–2.
- Official card: `ba072916-f610-515f-96e9-251ff3fc8745`: intent p4,
  explanation p5, criteria p6–7, example answers p7.
- Respondent answers: `55b745da-a297-5797-b855-678f8e744506`, PDF p1.
  Upper block=1-1; lower=1-2. Two answer blocks, **not two asserted students**.
  Student identity/count across blocks, exact individual score and university
  comments are not available. No model_answer is asserted.

[Official posting](https://admission.sookmyung.ac.kr/admission/html/rolling/previousView.asp?p_board_idx=52111&p_mode=modify)
explicitly identifies attachment4 as **모의논술 응시자 우수답안** and the attachment
as 선정된 우수답안. Existing question/card pages match official PDFs' extracted text;
answer page1's embedded image bytes match the official selected-answer PDF page1.
The builder repeats these comparisons and fails on source hash drift.

Evidence package v1: PASS for selected item1; seven roles available:
question, passage, exam_intent, scoring_criteria, example_answer,
high_scoring_answer, explanation. Missing model_answer is explicit NONE.

## Hanyang: PARTIAL

Selected exam:2025 mock humanities, one question; source post1660,3 resources.
All three PDFs are byte-identical to attachments from the
[official posting](https://go.hanyang.ac.kr/web/pds/pds_view.do?bn=14860&m_type=SUSI&ct02=ns02).

- Question/passages: `f35237a4-6d92-56da-9032-83d4e98c2db4`, p1.
- Example answer: `2aecab13-e0ae-50f6-9ba6-ba04f2306354`, p1.
- Intent/explanation/criteria: `fe18e74e-1fcf-52fa-818a-2df96104be65`, p1–2.
  Includes analytic scoring20/20/25/25/10, holistic criteria and formal deductions.
- `model_answer=NONE`, **high_scoring_answer=UNVERIFIED / REVIEW** (bounded recheck below).

Six official verified roles mapped; private source evidence package generated.
This is useful for a normal student-answer evaluation, but **not ready for the
requested official high-scoring respondent blind test**. A university example
answer cannot silently become a student answer. This is not a claim that no
2025 high-scoring answer exists anywhere on the university website.

## Private packages and blind boundary

[Offline builder](../tool/essay_lab/quality_pilot_2025.py) requires hash-pinned local
PDFs and outputs only below ignored repository `.local/`. It makes no network,
AI or DB call. Installed PDF tooling: pdfplumber/pypdf/Pillow/pypdfium2.
Rebuild command from repository root (bundled Python has dependencies):

```sh
PYTHONPATH=.:tool /Users/woojinchang/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  -m tool.essay_lab.quality_pilot_2025 \
  --source-dir .local/essay-quality-2025 \
  --output-dir .local/essay-quality-2025/packages
```

Private outputs:
- `packages/sookmyung/evidence_package.json`: full provenance/role references and
  extracted official evidence; operator-only, **do not send wholesale to AI**.
- `packages/sookmyung/blind_input.json`: allowlisted question1-1, required 가/나,
  official intent E1, criteria E2 and neutral asset references.
- `answer_1.png`: original source image crop `[0,0,2260,620]`, no resizing,
  rewriting or OCR. First answer is entirely included; second excluded.
- `question_page_1.png`, `question_page_2.png`: original question renders retain
  underlining lost in text extraction. Evaluate1-1 only; other printed questions
  on the source pages are not evaluation targets.
- `ground_truth.json`: source/resource/locator + `high_scoring`, separate from
  AI input; open **only after** evaluation.
- `packages/hanyang/evidence_package.json`: source package only; no invented
  blind answer/input or ground truth fixture.

The selected Sookmyung response is image-only. Tomorrow's runner must support
image input and attach the three explicitly listed image assets. No text-only
readiness is claimed. AI input omits high_scoring label, university selection fact,
reference/example/model answers, expected score and Owner prior judgement.
Official rubric bands remain visible as legitimate criteria, not ground truth.
Do not give the evaluator repository access or the parent package/ground-truth file.
Evaluation result must be finalized before revealing ground truth. No grading call
or prompt tuning has been performed today.

## Batch review queue / next gate

1. **Hanyang source supplement**: official actual respondent high-scoring answer
   tied to this2025 mock question; alternatively, a2025 regular exam with both its
   question and verified respondent answer in reusable Materials resources.
   2026-09-28 recheck covers every attachment of1660; retain REVIEW without asking
   Owner for manual data entry. Metadata of1659 identifies2024 exams, not2025.
   Resume only on a concrete2025 respondent-answer source; no broad re-research.
2. **Sookmyung filename conflict isolated**: first question/explanation pair in1697
   is named mock but document headers say regular admission. Not mapped here.
   Selected later mock PDFs are independently verified; no blocker for1-1.
3. Sookmyung image response needs image-capable evaluation input tomorrow; no
   automatic transcription or fabricated text. Exact student identity/score unknown.

Tomorrow: (1) Sookmyung2025/mock-humanities/1-1 blind response1;
(2) Hanyang only after respondent evidence supplement, otherwise keep PARTIAL;
(3) unchanged SKKU regular-humanities-1 문제1 with a separately supplied general
student answer. That student answer is not invented by this task.
Review question fulfilment, passage understanding, reasoning, evidence usage,
expression, official criteria, specific strengths/improvements and traceability.
No claim of admission-score prediction. No UI/schema/analytics follow-on today.

## Validation

Flutter focused41 PASS; live public search PASS; analyze PASS. Python quality12 +
existing Pilot13 + unchanged SKKU package17 =42 PASS. Full private PDF hash/page/
image proof checks PASS; repeated build artifact hashes identical. Answer crop
visually checked: entire1-1 response, no1-2/quality label. Actual public HTTP mapping
reads and SQL-role write denial PASS. Diff/secret/Wiki checks recorded at closeout.
Full Flutter suite NOT_RUN (focused search/Home repository tests cover changed paths).
SKKU production rows/package code/source metadata preserved; no SKKU rebuild.

## 2026-09-28 — Sookmyung Run A, frozen first benchmark

**EXECUTION PASS / BENCHMARK PARTIAL / EVIDENCE ARCHITECTURE PASS.**
Exactly one model run: Sookmyung2025 `mock-humanities` 문항1-1. No SKKU/Hanyang
run, Run B, prompt tuning, DB call/mutation, migration, UI or package rebuild.
Prior accepted schema/5–21–134 mappings/search/package states were not re-audited.
Starting HEAD `e83648c`, local/origin matched; protected Owner files unchanged.

### Execution and blind boundary

Existing ChatGPT-authenticated Codex CLI0.157.1, requested `gpt-6-astra`, high
reasoning. Available local model catalog lists text/image support and frontier
capability; this is a practical single-model choice, not a comparative benchmark.
Server-specific model snapshot/version was not reported: **UNKNOWN**.
[Official CLI documentation](https://learn.chatgpt.com/docs/developer-commands?surface=cli)
describes fresh `exec`, image attachment, JSON output and ephemeral runs.

[Small one-shot adapter](../tool/essay_lab/sookmyung_run_a.py) uses a neutral temporary
working directory, fresh session without conversation history, user config ignored,
project instruction loading disabled, tools/apps/plugins/memory/web/multi-agent
features disabled. No security-policy bypass flag. Model tool calls observed:0.
Only original accepted blind JSON plus three hash-verified original image assets
and allowlisted Q/P/E1/E2 reference metadata were supplied. No full package,
reference/example answer, response subtype, Owner judgement or ground truth.
Original answer image was neither OCR-transcribed nor rewritten/resized by runner.
Provider-internal image preprocessing is not asserted to be pixel-identical.

The existing contract file is **unchanged**. Adapter preserves its output_draft
fields, adds uncertainty, and substitutes this question/image input for its original
SKKU-only/string-input example. It does not carry SKKU40/40/20 scoring into Sookmyung.
No numerical student score or assigned grade was generated.

Private directory: `.local/essay-evaluation/sookmyung-2025-q1-1-run-a/`.
`attempt.json` is exclusive-create: rerunning the adapter refuses another attempt.
`prompt.txt`, `input_manifest.json`, `events.jsonl`, `stderr.log`, `raw_output.json`
and `frozen_receipt.json` are preserved read-only. After exit0, hashes were frozen
**before** opening `ground_truth.json`; reveal has a separate timestamp/receipt.
Do not delete/overwrite these files to obtain a better first result.

- Started2026-09-28T00:09:41.506776+00:00; frozen00:10:54.977 UTC.
- Ground truth file opened/reveal recorded00:19:31.580 UTC.
- Model process latency73.469s; output7509 bytes.
- Input artifacts466616 bytes, assembled prompt10824 bytes, images3.
- CLI usage: input16576, cached0, output2171, reasoning_output230.
  Values are reported fields; do not sum reasoning into output without provider
  accounting evidence. CLI usage includes its system/runtime context.
- API cost **UNKNOWN** (existing ChatGPT auth, not metered product API observation).
- Input bundle hash `2807f333c06e51c5a30442bebe6e3ce77dc26b9862165254ec7ec30f25b63a4b`.
- Raw output hash `d5dcba9a8fb2e39b5ef03366b0a42793f94ce2d6d2fe71efc85553154a101ed2`.

Initial postprocessor classified two CLI startup feature notices as tool activity.
The model itself exited0 with one completed turn. Log-only validation was corrected
for those exact notices; original prompt/input/output remained identical and **no
model retry** occurred. Notices describe skip-host-skill-discovery and disabled code
mode. Full record: private validated_receipt; no hidden replacement result.

### First result, sanitized

[Immutable v1 summary/scorecard/metadata](../tool/essay_lab/evidence/sookmyung_run_a_benchmark_v1.json).
This is a sanitized report, not the private raw evaluation body or student answer.

AI overall assessment:

> 평균 점수 하락과 학생들의 실제 학력 저하를 구분하고, 취약계층 응시자의 유입으로 평균이 달라졌다는 핵심 원인을 설득력 있게 설명한 답안입니다. 분량과 전체 전개도 적절합니다. 다만 공식 기준에 더 충실하려면 교육위원회의 교사 책임론을 명시하고, 취약계층의 응시 증가를 낳은 대학의 수용 확대까지 인과관계에 포함해야 합니다.

| Criterion | AI's concrete finding, paraphrased |
|---|---|
| 논제 충족 | 가를 나의 오류 설명에 활용; 표시된324자는 허용 분량. 교사 책임론 명시 부족 |
| 제시문 이해 | 평균 해석의 주의와 응시 집단 구성 변화 이해; 대학 수용 확대 배경 미명시 |
| 비교/분석 | 개념→사례 적용 적절; 수치 산출 대상 구성이라는 연결을 더 명료하게 권고 |
| 논리 구성 | 오류→사례→실제 원인→비판 흐름 인정; 반복 압축 권고 |
| 근거 활용 | 취약계층 응시 증가를 공식③ 핵심으로 인정; 배경과 비판 대상 보충 |
| 표현 | 의미/연결어 명확; 첫 문장의 추상적 표현 구체화 |
| 공식 rubric | ① 충족,② 부분 반영,③ 핵심 반영하나 대학 수용 확대 배경 미명시 |

Strengths: numerical change vs causal interpretation distinction; population
composition explanation; application of passage principle in the student's own
reasoning. Revision priorities: clarify teacher-blame interpretation; connect
university access expansion→candidate composition→average; compress repetition
within300±30 characters. No generic praise-only response.

Exact internal citations:
- Q/P → existing resource `ed10de4d-3a33-5fbc-94f3-27ad7521f3cc`;
  Q p2 question1-1, P p1 가/나.
- E1/E2 → `ba072916-f610-515f-96e9-251ff3fc8745`;
  E1 p4 section3, E2 p6 section6 question1-1.
All four output IDs/UUIDs/locators exactly match the supplied reference catalog.
No invented criteria, mismatched reference or image reading error was detected in
this case.324 is the image's printed count, not an independently recomputed count.

### Ground-truth comparison and scorecard

Ground truth: university-published respondent high-scoring answer. It is a strong
positive example, not an absolute perfect-answer score. The model independently
recognized its substantive strengths. Teacher blame/access expansion are actually
present in official②③ and not explicit in the answer; requesting precision is
therefore evidence-based, not an invented deduction. There was no student score.

| Benchmark dimension | Verdict |
|---|---|
| Task fulfilment recognition | PASS |
| Passage understanding recognition | PASS |
| Reasoning quality recognition | PASS |
| Official rubric alignment | PASS |
| Strength identification | PASS |
| Weakness calibration | PARTIAL |
| Evidence grounding | PASS |
| Hallucination control | PASS |
| Actionability | PASS |
| Overall benchmark recognition | PARTIAL |

Observed issue1: **E10 / MINOR**, same teacher-related omission appears in5 of7
criterion_feedback sections. This can amplify one weakness in the perceived overall
judgement. Future contract/presentation should distinguish core achievement from
one consolidated improvement issue. **E03/E06 are not established**: no numerical
penalty/grade exists, and a university-selected answer can have valid improvements.
Do not relabel supported critique as hallucination merely because ground truth is
positive. Scorecard is post-reveal Codex review, not independent human gold scoring.
One positive case cannot establish separation from weak answers or admission prediction.

### Validation and next gate

16 focused checks PASS: input/label/reference-answer exclusion, exact source-image
hashes, deterministic assembly, output schema/reference membership, no tools,
first-write protection, frozen output hashes and reveal-after-freeze ordering.
Private fixture tests explicitly skip when a clean checkout lacks ignored bodies.
Private artifacts excluded by Git; no raw answer/image/evaluation body committed.
No Flutter changes/suite; no accepted-state or other university artifact changes.
Wiki/diff/secret/protected-file checks completed before commit.

Decision: execution **PASS**, benchmark **PARTIAL**, evidence architecture **PASS**,
contract **MINOR_REVISION** (deduplicate critique, no new schema/framework).
SKKU general-answer next pilot **YES after Owner gate**; Essay LAB v1
**CONDITIONAL**, not proven product readiness from one positive answer.
Owner/ChatGPT chooses v1.1, SKKU, or contract revision. **STOP; no next evaluation.**


## 2026-09-28 — Hanyang bounded recheck / Owner official-source decision

Sookmyung Run A remains frozen and was not rerun. Follow-up starting HEAD733b83d.
Read-only Production inventory plus current source1660 attachment list were compared.
Expired delivery links were refreshed from the same post; existing resource UUIDs
and cached PDFs reused. No PDF/resource duplication in DB, mapping write or AI call.

**HANYANG_HIGH_SCORING_RECHECK: REVIEW — not found in this bounded scope.**
This supersedes the earlier apparent final NONE; it is not a university-wide absence
claim. All10 attachments /105 PDF pages were text searched for 우수답안, 응시자/학생
우수답안, 답안 사례, 우수 사례 and 합격자 with whitespace normalization. All22 pages
of the9 exam PDFs were visually checked, including diagrams/images. The83-page
admission guide had no answer-section hit; its embedded-image pages1/53/55/56 were
also visually checked. Acceptance-related hits in that guide are admission rules,
not respondent-answer evidence. No empty extracted-text page in the guide.

| Source1660 resource | PDF pages checked | Finding |
|---|---:|---|
| 인문 문제 | 1 | Question/passages |
| 인문 예시답안 | 1 | Official example; no student provenance |
| 인문 출제의도 | 1–2 | Intent/criteria/explanation |
| 자연 문제 | 1–2 | Questions |
| 자연 예시답안 | 1–5 | Example solutions |
| 자연 출제의도 | 1–2 | Intent/criteria |
| 상경 문제 | 1–2 | Questions |
| 상경 예시답안 | 1–3 | Example solutions |
| 상경 출제의도 | 1–4 | Intent/criteria |
| 신입학 수시 모집요강 | 1–83 text; image pages noted above | Admission information |

[Exact resource UUIDs, hashes and page scope](../tool/essay_lab/evidence/hanyang_2025_recheck.json)
are public metadata only. Original PDFs/text/renders stay in ignored
`.local/hanyang-recheck-2026-09-28/`; no student body copied to Git.
Production metadata for post1659 does list 합격자/우수답안 attachments, but its source
exam title is **2024학년도 수시**;2025 refers to competition information. Those files
were not relabelled as2025 or mapped. This is a possible year-context explanation,
not a conclusion about which document Owner remembers.

New verified high-scoring mappings:0; verified2025 respondent answers found:0;
answer locator:UNRESOLVED; blind fixture:NOT_READY. Existing6 official mappings and
Hanyang source package remain unchanged. No fabricated blind answer or ground truth.
Review queue: obtain a concrete2025 respondent-answer/question match when available;
retain the existing official example role in the meantime. No Owner manual entry request.

[Official-source policy](essay-lab-data-foundation.md#official-source-policy--owner-decision-2026-09-28)
is now canonical. Existing exam/mapping official_source_url + provenance + locator
columns are sufficient; migration NONE. This follow-up records the display contract;
App/LAB UI was not changed. Rights review remains required before full public release.

Follow-up validation: quality Pilot12 + existing Pilot13 + Run A16 =41 PASS using
bundled Python. Initial system-Python attempt lacked pypdf; dependency-runtime retry
passed, no code regression. Resource UUID uniqueness/page-range/hash manifest checks,
protected iOS/accepted-state/plan hashes, private exclusion, scoped secret scan,
Wiki handoff and diff checks PASS. No Flutter change/test, no new evaluation run.


## 2026-09-28 — Hanyang2024 v1.1 benchmark exception

[Bounded2024 preparation](essay-lab-hanyang-2024-benchmark.md): Owner PDFs match
Materials, but afternoon1 answer has the same embedded images as business answer.
Correct afternoon1 answer unresolved; AI runs0. v1.1 contract and Korean student
language policy prepared; no empirical improvement claim. Sookmyung Run A preserved.

## 2026-09-28 — Owner redirected Hanyang2024 to afternoon2

[Afternoon2 Run A](essay-lab-hanyang-2024-afternoon2-run-a.md): official guide verifies
selected answer/criteria; one v1.1 run frozen before reveal. Execution PASS, benchmark
PARTIAL: final issue dedup PASS, level recognition/teacher balance PARTIAL. Original
contract/Sookmyung untouched. No Production writes. Afternoon1 H24-R01 stopped and
preserved; business REVIEW. Owner result review next; no further evaluation.

## 2026-09-28 — Rewrite generation, no re-evaluation

[Two-case rewrite Pilot](essay-lab-rewrite-pilot-v1.md): one independent generation per
university, both frozen; original evaluations unchanged. Hanyang PARTIAL (unsupported
policy-agreement insertion), Sookmyung PASS; both length ranges met. Optional AI example
follows student-first revision UX. Full texts private; product-design gate CONDITIONAL.
No Production/UI/schema change or further generation; Owner comparison next.
