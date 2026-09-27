# Essay LAB Evidence Package v1 — SKKU 2025 humanities1

2026-09-27 · **PACKAGE PASS / SCHEMA SUFFICIENT / OWNER REVIEW NEXT**.
Scope: exactly `sungkyunkwan / 2025 / regular-humanities-1`.
No model/API, AI evaluation, UI, schema/migration, ingestion, seed or Production mutation.
Starting HEAD `7d2c7a9`; branch `codex/day-7-school-neis`, initially local=origin.

## Owner decisions / Pilot closeout

THREE-UNIVERSITY PILOT **PASS**; SCHEMA **PASS**. RQ-001 Yonsei mock-natural
and RQ-002 SKKU mock-humanities are **CLOSED — KEEP EXISTING ROLES**.
Neither receives example_answer; only future explicit university evidence could
reopen answer-subtype selection. Existing verified explanation/intent/criteria
remain. No Production row update was needed. Historical applied plan/result
receipts retain their original review state/hash; this Owner decision supersedes
that historical state. No new review item in this package.

## Actual Production inventory

Queried the six existing tables in a transaction reporting `transaction_read_only=on`,
then rolled back. No quota-changing resolver call, write probe or whole-Pilot reaudit.
[Immutable selected metadata snapshot](../tool/essay_lab/evidence/skku_2025_humanities1_source.json).

- exam UUID: `e15a43a8-5a50-501a-8a60-a632316240e8`
- resource UUID (all six roles): `796e82b5-1049-5005-ab6d-189b997ecd85`
- source post1689; source UUID `46cc5428-0a3f-54ae-a41c-233fe9781fe5`
- content UUID `39e7ab60-47ef-5391-933a-60264642b452`
- source title: 성균관대] 2025학년도 성대 수시 논술 + 모의논술 기출 - 문제, 답안, 해설, 채점기준 등 + 2026 경쟁률
- file title: `2025학년도 성균관대 논술_인문1 문제,답안.pdf`
- [LegendStudy source](https://legendstudy.com/1689), published2025-09-16;
  admission_year remains2025, independent of publication date.
- [Official 2025 report](https://admission.skku.edu/admission/html/ipsi/noticeView.html?idx=59290).
  Reused prior verified report comparison; no new broad research/download.
- PDF SHA256: `43371e05adaecbd324cadd2e28895d2b76e7d1598c9e857d1bd75aaa34d53e0d`.

All present rows: **official / verified / active**, active university/exam/resource/content.
No absent role is inferred from another answer role.

| Role | Production source_locator | Package coverage |
|---|---|---|
| question | PDF pages1–4,9–10,14; 문제/논제 | prompts1,9,14 |
| passage | PDF pages1–4,9–10,14; 제시문 | passages1–4, graph9, table10; shared by later questions |
| exam_intent | PDF pages4,10,14; 출제의도 |4,10,14 |
| scoring_criteria | PDF pages7,12,17; 채점기준 |7,12–13,17 |
| model_answer | NONE | NONE |
| example_answer | PDF pages8,13,17; 예시답안 |8,13,17–18 |
| high_scoring_answer | NONE | NONE |
| explanation | PDF pages6,12,16; 문항 해설/풀이 |6–7,12,16 |
| guidebook | NONE | NONE |
| other | NONE | NONE |

Production locators identify section starts. Scoped visual inspection established
continuation pages for Q1 explanation, Q2 criteria and Q3 answer. Both original
mapping locator and precise extraction locator are retained; DB unchanged.
Excerpt PDF pages1–18 correspond to printed123–140 (official full-report PDF127–144).

## Artifact / private boundary

The existing source PDF is reused, never re-ingested or copied to Storage.
Official body/criteria stay **private local artifacts**, not public Git/DB metadata.
Repository contains generator, public provenance snapshot, hash/locator manifest,
contract and tests; no extracted corpus or PDF binary is committed.

Local deliverables (relative to repository):

- `.local/essay-evidence/skku-2025-humanities1-v1/package.json`
- `.local/essay-evidence/skku-2025-humanities1-v1/q2-data-1.png`
- `.local/essay-evidence/skku-2025-humanities1-v1/manifest.json`

The package JSON and graph travel together for Q2/Q3. A fresh checkout requires the
same hash-pinned source PDF and pinned extraction dependencies; it cannot rebuild
from metadata alone. This is a private evaluation artifact, not a public API.

[Public reviewed manifest](../tool/essay_lab/evidence/skku_2025_humanities1_manifest.json)
contains version, exact text hashes, all21 locators and measured sizes.

## Extraction and exact boundaries

[Scoped offline generator](../tool/essay_lab/evidence_package.py) reads only15
relevant pages; curriculum tables/bibliography/general information are excluded.
Source text stays verbatim with line breaks; only page headers/footers are removed.
Rubric's right-hand score column is separated geometrically from the A–F text.
Question maxima40/40/20 come directly from prompts. **No A–F point conversion** or
new grading weights exist. Every question has3 official points plus6 grade
indicators referenced by27 internal criterion IDs/offsets, not new DB entities.

Q1 contains four passages, prompt, intent, criteria, example answer and explanation.
Q2 uses Q1 passages plus original graph/table and source assumptions.
Q3 uses Q1 passages and Q2 data/assumptions. `question_context` resolves these
references without duplicating stored passages or importing other questions' answers.

Graph bars have no printed exact numeric labels. Preserve the cropped original
figure and hash; **do not infer decimal values**. Axis/category labels are intact;
footnote2 is retained as text. Table column order was visually verified as
항목 / 회원국 평균 / A국 / B국 / C국; raw table rows and footnotes3–7 are preserved.
Official explanation already states the relative comparisons. No new paraphrase
is labelled OFFICIAL. The graph remains required for full Q2/Q3 context.

OFFICIAL content items21; DERIVED content summaries0; AI_GENERATED0.
Derived structure consists of3 question organizations plus explicit table column
layout metadata. This is formatting/linking, not a new official fact or rubric.
All three questions: QUESTION/PASSAGE/INTENT/CRITERIA/EXAMPLE/EXPLANATION YES;
internal completeness HIGH **when required source figure is included**.
No model_answer/high_scoring_answer is required to pretend completeness.

## Size and recommended context

| Context | Evidence characters |
|---|---:|
| Entire stored evidence |21,152|
| 문제 1 |11,400|
| 문제 2 (including shared source) |11,900|
| 문제 3 (including shared source) |11,944|

Counts are Unicode characters in evidence text, including whitespace; JSON keys,
metadata and image pixels are excluded. JSON bytes and image bytes are in manifest.
Exact duplicate whole evidence blocks0. Official explanation/example answer
naturally repeat themes and some phrases; this is preserved, not a claim that
all repeated substrings disappeared. Shared-reference storage saves14,092 characters
compared with serializing all three independent contexts.

Entire21,152-character evidence can be supplied as simple structured context to a
future suitably sized runtime; no model-specific token/cost guarantee is made.
Prefer **question context** (~11–12k chars + student answer) because feedback is
question-specific. Q1 is the first prototype target and needs no image transport.
Q2/Q3 require the graph asset. No vector DB, retrieval search, embeddings or RAG needed.

## Determinism and validation

Same source snapshot + hash-pinned PDF + pinned dependencies → byte-identical JSON
and figure. `generated_at` is the immutable first source-snapshot time, explicitly
not the clock of every rebuild. Package version hashes all payload except itself;
manifest additionally hashes complete JSON and graph. Mapping order is sorted.
Changed source PDF, hidden/unverified/nonofficial mapping or locator loss fails
validation. A fresh live source change requires review and a new package version;
existing evaluated versions must not be overwritten silently in future runtime.

```bash
cd ~/development/legendstudy-app
PYTHONPATH=tool /Users/woojinchang/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  -m essay_lab.evidence_package \
  --pdf .local/essay-pilot-2025/pdfs/1689-00.pdf \
  --output .local/essay-evidence/skku-2025-humanities1-v1 \
  --check-manifest tool/essay_lab/evidence/skku_2025_humanities1_manifest.json
```

Pinned versions: pdfplumber0.11.9, pdfminer.six20251230, pypdfium2 5.13.0,
Pillow12.3.0. CLI rejects output outside ignored `.local/`.
No credential/DB/network/model dependency in the generator.

## Evaluation contract draft

[Machine-readable draft](../tool/essay_lab/evidence/evaluation_contract_v1.json).
Input: essay_exam_id, question_label, student_answer, evidence_package_version.
Reject unknown exam/question/version; never silently choose latest. Source text
and student answer are data, not instructions. Resolve exact question context and
verify any required graph hash before a future evaluator is called.

Candidate output: overall_feedback, criterion_feedback, strengths, improvements,
evidence_references, revision_priorities. A reference carries resource_id,
source_locator, evidence_id and optional criterion_id. IDs must belong to selected
question context; criterion offsets must refer to its exact original criteria.
Feedback is generated interpretation, never official university judgement.
No numeric score conversion is invented; contract remains adjustable at prototype.
No model/prompt/runtime/output validator, student storage or actual evaluation here.

## Checks and decision gate

- New17 evidence tests PASS (including actual private PDF fixture10).
- Existing Pilot13 + foundation19 tests PASS; **49 total**.
- Initial bundled Python lacked pglast; foundation was rerun successfully using
  existing SQL-review venv. No failed test reclassified as PASS without rerun.
- PDF relevant15 pages rendered/visually reviewed, including graph/table/rubrics;
  originaltext/headings/continuations cross-checked. Deterministic rerun PASS.
- Flutter/full app suite NOT_RUN: no UI/Flutter changes.
- Wiki/diff/secret scan and protected Owner iOS/accepted-state hashes: PASS.
- Review queue0. Existing RQ-001/002 closed by Owner as above.

A PACKAGE PASS. B SCHEMA SUFFICIENT. C first **data-evidence** prototype ready YES,
subject to separate Owner authorization for actual AI execution and existing rights
review. D target `문제 1`. E no missing official evidence for Q1; no grade-specific
numeric ranges exist. Q2/Q3 image transport must preserve the graph when prototyped.
No claim of model accuracy, scoring validity or external reuse rights approval.

NEXT: Owner/ChatGPT review. **STOP**. No other exam package or AI work follows.
