# Essay LAB 2025 Pilot Phase1 — Production mapping

2026-09-27 · continuation starting HEAD `9cd7c9f` · branch `codex/day-7-school-neis`.
**CURRENT: APPLIED — 3 universities / 19 active verified exams / 121 active official verified mappings.**
38 existing resources reused. Owner closed both optional answer-subtype reviews,
keeping existing roles; THREE-UNIVERSITY PILOT PASS. This supersedes historical states below.

## Owner continuation policy

CLEAR → apply with scoped preflight. Individual ambiguity/conflict → hold only the affected
resource/role/exam in REVIEW_QUEUE, continue independent mappings, submit one batch for Owner
review. Only schema blockers, destructive changes, security/RLS faults, systematic mapping
errors, unexpected Production mutations/collisions/orphans or major new Product decisions
stop the whole run. Do not redesign the schema or reopen Materials audits.

Owner released the three Kyung Hee answer year conflicts: admission_year=2025, based on
Owner comparison against actual2024 papers. The original2024 headers remain visible in
evidence_note; administration/admission-year mixing or original notation error is possible,
**not a confirmed university typo**. No PDF or source publication date was changed.
Exam dates remain NULL where an exact calendar date was not independently established.

## Exact Production checkpoints

| University | University rows planned/actual | Exam rows planned/actual | Role mappings planned/actual | Reused PDFs | Checkpoint |
|---|---:|---:|---:|---:|---|
| Yonsei | 1/1 | 4/4 | 14/14 | 11 | PASS |
| Sungkyunkwan | 1/1 | 7/7 | 41/41 | 9 | PASS |
| Kyung Hee | 1/1 | 8/8 | 66/66 | 18 | PASS |
| TOTAL | 3/3 | 19/19 | 121/121 | 38 | PASS |

All121 persisted mappings are official+verified; review mapping rows0. Review items below
are **unapplied candidate roles**, not unverified database rows. All19 exams are active.
No extra university/year, schema/migration, existing Materials/resource update, AI grading
or UI work. source_posts/content_items/resources/exams/exam_subjects/ingestion_quarantine
row-count and full-row fingerprints stayed unchanged at every university checkpoint.
Canonical rows outside each university scope also stayed unchanged.

Artifacts: [exact plan / IDs / locators / queue](../tool/essay_lab/pilot_2025_phase1_plan.json),
[committed runtime receipts](../tool/essay_lab/pilot_2025_phase1_result.json),
[bounded INSERT-only helper](../tool/essay_lab/pilot_2025.py). No credentials or PDF binaries.
UUIDs derive deterministically from platform university slug and year/stable exam_key;
campus/track/field/session remain context only. Never use this receipt as authorization to
rerun seed: existing rows make preflight abort, and the helper never commits by itself.

## Actual exam set

Question_count is top-level question groups when explicit; no inferred counts/durations.
Unconfirmed dates/campus/answer length remain NULL. Existing source publication dates remain
on Materials. A NULL value is not a claim that the university publishes no such fact.

| University | exam_key | Field / session | PDFs | Role rows | Duration / question groups |
|---|---|---|---:|---:|---|
| 연세대학교 | `mock-natural` | 자연계열(수학) / — | 2 | 4 | NULL / 6 |
| 연세대학교 | `regular-humanities` | 인문계열 / — | 3 | 4 | NULL / NULL |
| 연세대학교 | `regular-natural` | 자연계열(수학) / — | 3 | 3 | NULL / NULL |
| 연세대학교 | `regular-natural-additional` | 자연계열(수학) / 추가시험 | 3 | 3 | NULL / NULL |
| 성균관대학교 | `mock-humanities` | 언어 논술 / — | 2 | 5 | 100 / 3 |
| 성균관대학교 | `mock-natural` | 수리 논술 / — | 2 | 6 | 100 / 3 |
| 성균관대학교 | `regular-humanities-1` | 언어형 / 1교시 | 1 | 6 | NULL / 3 |
| 성균관대학교 | `regular-humanities-2` | 언어형 / 2교시 | 1 | 6 | NULL / 3 |
| 성균관대학교 | `regular-natural-1` | 수리형 / 1교시 | 1 | 6 | NULL / 3 |
| 성균관대학교 | `regular-natural-2` | 수리형 / 2교시 | 1 | 6 | NULL / 3 |
| 성균관대학교 | `regular-natural-3` | 수리형 / 3교시 | 1 | 6 | NULL / 3 |
| 경희대학교 | `mock-humanities-sports` | 인문·체육계 / 온라인 | 2 | 6 | NULL / NULL |
| 경희대학교 | `mock-medicine-pharmacy` | 의·약학계 / 온라인 | 8 | 24 | NULL / NULL |
| 경희대학교 | `mock-natural` | 자연계 / 온라인 | 2 | 6 | NULL / NULL |
| 경희대학교 | `mock-social` | 사회계 / 온라인 | 2 | 6 | NULL / NULL |
| 경희대학교 | `regular-humanities-sports` | 인문·체육계 / 11월 16일 오전 | 1 | 6 | NULL / NULL |
| 경희대학교 | `regular-medicine-pharmacy` | 의·약학계 / 11월 16일 오후 | 1 | 6 | NULL / NULL |
| 경희대학교 | `regular-natural` | 자연계 / 11월 17일 오전 | 1 | 6 | NULL / NULL |
| 경희대학교 | `regular-social` | 사회계 / 11월 17일 오후 | 1 | 6 | NULL / NULL |

Kyung Hee medicine/pharmacy regular is one sitting: PDF p1 says math required and one of
physics/chemistry/biology chosen. Its combined resource retains all alternatives. Mock
medicine/pharmacy is one official 의약학계 archive set with8 split question/answer resources;
component labels are retained in resource titles/locators. No four independent exams were
invented from four subjects. Future question-level selection is not implemented here.

## Evidence verification

- Kyung Hee18, Yonsei mock2, SKKU mock4:24 existing PDF hashes match official downloads exactly.
- SKKU regular5 excerpts: inspected document headers/cards and matched the official2025
  선행학습 report. Normalized15-character text samples of all82 excerpt pages matched
  official page content (not claimed as byte-identical PDFs).
- Yonsei regular9: question papers correspond to the official2025 report annex;
  intent/solution excerpts correspond to the same named questions and discussion in the
  official report, with different layout and extraction quality. These are content/context
  comparisons, not byte identity. Role headings and actual content were inspected.
- Multi-role is content-based: combined question/passage/intent/criteria/example/solution
  mappings use PDF page/section locators. A mention of 출제의도 in a template footnote is
  not evidence for intent; KHU mock intent points to actual evaluation objectives in 문항 해설.
- Original2024/2025 discrepancies are preserved in all mappings of the three affected
  answers. The official2025 mock zip itself has the identical files. Owner identity
  resolution is recorded separately from document provenance.
- No model_answer or high_scoring_answer role is inferred. These roles have zero rows.

Official collection references (checked2026-09-27):
- [Yonsei mock](https://admission.yonsei.ac.kr/seoul/admission/html/rolling/noticeView.asp?BBS_NO=3236)
- [Yonsei2025 report](https://admission.yonsei.ac.kr/seoul/admission/html/counsel/dataView.asp?BBS_NO=3356)
- [SKKU2025 report](https://admission.skku.edu/admission/html/ipsi/noticeView.html?idx=59290)
- [SKKU mock](https://admission.skku.edu/admission/html/rolling/questionView.html?idx=59182)
- [KHU regular](https://iphak.khu.ac.kr/detail.do?board_seq=13928&menuurl=89BGs%2Bk748ajyySWoWlQPw%3D%3D)
- [KHU mock](https://iphak.khu.ac.kr/detail.do?board_seq=12260&menuurl=89BGs%2Bk748ajyySWoWlQPw%3D%3D)

## Owner decision — review queue CLOSED

RQ-001 and RQ-002: KEEP EXISTING ROLES; no example_answer addition without new
explicit official evidence. THREE-UNIVERSITY PILOT PASS, SCHEMA PASS. No DB change.
[One-exam Evidence Package v1](essay-lab-evidence-package-v1.md) is the next handoff.
The following table and applied plan are historical review evidence.

### Historical batch review queue — 2 items

YEAR_CONFLICT0 · ROLE_AMBIGUOUS2 · EXAM_IDENTITY/SESSION/FIELD/LOCATOR/SOURCE/OTHER0.
Both were RESOURCE_ONLY, status OWNER_REVIEW_REQUIRED at mapping time; now CLOSED. Only uncertain answer subtype is
excluded; already confirmed roles and other university mappings continued.

| ID | University / exam | Resource UUID / source | Issue / evidence | Candidate interpretations |
|---|---|---|---|---|
| RQ-001 | 연세대학교 / `mock-natural` | `1745ca8b-98a6-5404-b6be-a077c541fca0` / 1671 | ROLE_AMBIGUOUS: 2025학년도 연세대 모의논술_자연 해설,답안.pdf; PDF pages 1-12; explicit explanation/criteria but no answer-subtype heading | Keep current explanation/criteria roles only, OR Owner confirms example_answer interpretation. No subtype chosen by Codex. |
| RQ-002 | 성균관대학교 / `mock-humanities` | `2d1b1e0b-8773-5a8a-b166-d69f4caedf17` / 1689 | ROLE_AMBIGUOUS: 2025학년도 성균관대 모의논술_인문(언어) 해설,답안.pdf; PDF pages 2-13; explicit explanation/criteria but no answer-subtype heading | Keep current explanation/criteria roles only, OR Owner confirms example_answer interpretation. No subtype chosen by Codex. |

## Runtime validation and implementation checks

- University order: Yonsei → checkpoint → SKKU → checkpoint → KHU → final check.
- Preflight resource UUID/key/title/content/source identity, active parent, duplicate
  stable keys/mappings, FK targets and client grants passed; actual INSERT constraint
  enforcement and exact field readback passed. Each university was one atomic transaction.
- Actual SQL roles anon/authenticated SELECT returned exact planned rows. INSERT/UPDATE/
  DELETE probes on each new table returned42501; zero-row probes were savepoint-rolled back.
  Service-role INSERT path passed. These authenticated tests use SQL SET LOCAL ROLE,
  **not an end-user login/JWT transport test**. Real guest REST additionally returned3/19/121.
- [Existing evidence lookup](../supabase/review/essay_lab/evidence_lookup.sql) now explicitly
  returns exam ID/key and provenance/verification alongside role/resource/locator. Repeated
  queries for every exam under both roles matched and returned only official+verified rows.
- Duplicates0, orphans0; schema unchanged. No auto rights/reuse or AI-grading readiness claim.
- First Yonsei attempt fully rolled back: RESET ROLE restored cli_login_postgres (no SELECT)
  instead of postgres. READ ONLY confirmed0/0/0. Corrected only the operator to restore its
  explicit role; no grants/RLS/schema changes. Fresh preflight and all runtime checks passed.
- Foundation19 + Pilot13 focused tests PASS. Wiki/diff/secret checks PASS. Flutter NOT_RUN
  (no Flutter/UI changes). Owner iOS and accepted-state SHA256 unchanged; untracked preserved.

## Decision gate / next

- THREE-UNIVERSITY PILOT: **PASS; Owner retained existing roles for both optional decisions**; all3 universities,
  all19 exams and all38 source PDFs have normal verified mappings. No whole-Pilot failure.
- SCHEMA WORKED AS-IS: **PASS**, no schema change/new migration.
- Evidence prototype candidates (no AI run): SKKU `regular-humanities-1`, SKKU
  `regular-natural-1`, KHU `regular-social`. Each has question, passage, intent, criteria,
  example_answer and explanation. A complete resource-level set is not extracted questions
  or permission to grade; private evaluation package/rights gates remain future work.
- Owner/ChatGPT now reviews the scoped SKKU Evidence Package v1. Remaining Pilot
  supplementation and actual AI prototype execution remain separate gates.
**STOP after handoff. No expansion or AI/UI development follows automatically.**

---

# Historical checkpoint — initial STOP before apply

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
