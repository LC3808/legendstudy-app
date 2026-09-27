# Essay LAB 2025 Pilot Phase1 — stopped before apply

2026-09-27 · starting HEAD `4f27d9b` · branch `codex/day-7-school-neis`.
Scope: Yonsei/Sungkyunkwan/Kyung Hee only, admission_year2025.
**STATUS: STOP — unexpected document admission-year conflict. PRODUCTION WRITE:0.**

## Foundation deployment confirmed

Owner applied `20260927000200_essay_lab_foundation.sql` and reported empty tables.
Actual READ ONLY SQL confirmed universities/essay_exams/essay_exam_resources
exist and counts are **0 / 0 / 0**. Inspected essay constraints/indexes match UUID
PK + UNIQUE(university_id, admission_year, exam_key), resource/university FKs,
verification checks and non-unique context. This is not a full runtime JWT/RLS test.
Do not replay the migration or redesign the schema. [Approved foundation](essay-lab-data-foundation.md).

## Inspection and exact stop evidence

Reused existing source/resource IDs for posts1671,1689,1633,1682. Inspected the38
2025-labelled candidate PDFs locally; no Storage upload, resource duplication,
Production resource update or OCR framework. PDF text is inspection-only and is
not committed; repository stores compact metadata/hashes. It is not an extracted
question corpus or completed mapping. No official/verified mapping was created.

[Inspection manifest and stop evidence](../tool/essay_lab/pilot_2025_phase1_stop.json)
contains exact38 resource identities, PDF hashes/page counts and the3 conflicts.

All three conflicting files are on [source1633](https://legendstudy.com/1633).
Their filenames and first-page section title say **2025학년도**, while the first-page
running header says **2024학년도 모의논술고사**. Chemistry was additionally rendered
and visually checked; biology/physics text extraction shows the same conflict.

| Resource | UUID | PDF location | Conflicting identity |
|---|---|---|---|
| 의·약학계 화학 답안 | `64d5bb47-4d92-5cc4-81aa-bb755aa16ff2` | page1 header vs section1 | 2024 vs2025 |
| 의·약학계 생명과학 답안 | `071a9b7e-1ad6-5c6d-a45a-b44feb66fe60` | page1 header vs section1 | 2024 vs2025 |
| 의·약학계 물리학 답안 | `891c9dd8-c97d-51b7-961f-344bb6d168fe` | page1 header vs section1 | 2024 vs2025 |

A stale template header is plausible, **not established**. Do not silently prefer
the file title/section over the header or stamp official+verified. The conflict is
about admission year, not whether an answer is model/example/other.
Owner instruction §17 explicitly requires immediate STOP for unexpected identity
conflict; only ordinary role ambiguity may be retained in review while continuing.
The conflict was found before the first university apply, so all3 university writes
are stopped. No unapproved selective continuation is implied by a draft plan.

## University checkpoints

| University | Source PDF candidates read | Exam set finalized | Universities/exams/mappings inserted |
|---|---:|---|---|
| Yonsei /1671 | 11 | NO | 0/0/0 |
| Sungkyunkwan /1689 | 9 | NO | 0/0/0 |
| Kyung Hee /1633,1682 | 18 | NO — year conflict on3 PDFs | 0/0/0 |

No exam_keys, duration, question_count or prototype exams were finalized/seeded.
No claim that candidate files correspond one-to-one to exam identities. In
particular, Kyung Hee medicine components still need exam-set reconciliation.
No verified/review/unknown mapping rows were written: all row counts0.
Production preflight/apply/public-read/JWT write-denial/service-write/evidence-lookup
checks for new Pilot rows: **NOT_RUN**, not PASS. Duplicate/orphan rows introduced:0;
unexpected document identity conflicts:3. No existing data was edited/deleted.

## Validation and preservation

Existing foundation offline19 tests PASS. Manifest deterministic checks:38 unique
resource IDs, all PDF downloads parsed,3 exact page1 year conflicts,0 writes.
Wiki handoff/diff/secret checks PASS. Owner iOS and accepted-state SHA256 unchanged;
existing untracked files preserved. No schema/new migration, university seed,
Materials modification, Flutter/Web UI, AI evaluation, RAG or expanded pilot.
Applied migration SQL is immutable and remains unchanged.

## Decision gate

- SCHEMA WORKED AS-IS: **NOT_YET_VALIDATED_WITH_MAPPING**; no structural failure found.
- 3-UNIVERSITY PILOT COMPLETE: **NO**.
- READY FOR REMAINING PILOT: **NO**, current Pilot has not run.
- READY FOR EVIDENCE PROTOTYPE: **NO**, no exam selected.
- Exact data gap: establish which admission year these3 official answer documents
  actually serve. Compare an authoritative2025 distribution/original notice and
  question/answer content; if they are template-header errors, preserve that evidence
  rather than alter originals. Alternatively Owner may explicitly authorize holding
  these conflict resources while resuming only unambiguous mappings.

NEXT: Owner/ChatGPT resolution or scoped continuation decision. STOP.
