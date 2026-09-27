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
- `model_answer=NONE`, **high_scoring_answer=NONE in inspected set**.

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
   Current inspected set contains only an example answer. Manus/Owner can supply
   the exact missing document/question/locator; do not repeat broad research.
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
