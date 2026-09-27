# Exam Full-Set Canonical Policy

Status: OWNER SOURCE RULE supersedes the strict registry publication gate,
2026-09-27. **Current policy:** [Materials closeout/handoff](materials-closeout-essay-lab-handoff.md).
The coverage profiles and strict classifier below are retained as historical QA
methodology, not current publication blockers. Source-selected full-set material,
real exception handling and pre-launch partial cleanup govern the final closeout.
The parenthesized administered-month parser is corrected; the18 full-set
counterparts of the earlier52 hold are selectively released. Remaining34 partial
holds are preserved. Detailed history below is not a renewed freeze.
This supersedes treating every writer-ready blog post as an independent App exam.
[Rollout](materials-data-rollout.md), [ingestion](ingestion.md),
[source/identity contract](day-9-ingestion.md), [audit](exam-canonical-audit-2026-09-27.md).

## Product rule

**SOURCE ARCHIVE ≠ APP CATALOG. ONE EXAM → ONE CANONICAL FULL-SET EXPERIENCE.**
Blog SEO duplication is not the App content model. Students should find the most
complete useful representation quickly. Preserve every original source/provenance;
prefer one complete representative per exam rather than maximizing post count.
This applies to future Materials browse, search, recommendations, personalization,
grade-specific presentation and LAB linkage. It does not implement those systems.

## Canonical scope and evidence

- 고1: that exam's full subject set.
- 고2: that exam's full subject set, including additional areas where actually
  offered. Late-year vocational/foreign-language papers cannot be ignored.
- 고3: education-office national assessments, KICE June/September assessments and
  CSAT, each with all areas actually offered for that sitting/curriculum.
- Korean, mathematics, English, Korean history, social/science inquiries are common
  domains, not a universal fixed list. Preserve 가/나, common/elective bundles,
  I/II science, integrated social/science and historical names as evidenced.
- KICE/CSAT and some late national assessments include vocational inquiry and
  second foreign languages/Hanmun. Missing evidence for these is REVIEW, not an
  automatic “core six domains = full” exception. A non-offered domain is not a gap.

Full-set needs **identity + year/grade/nominal session + type/organizer context +
actual offered-area evidence + named resource/subject coverage**. Neither a
`전과목` title/category nor `subject >= N` is sufficient. A category is intent
only. Cross-check question and answer coverage, collective answer files, elective
bundles, unscoped attachments, missing occurrences, mismatched raw labels and
source revisions. Do not infer a missing paper merely from absent modern aliases.

The first audit uses bounded source profiles and resource labels, not PDF-content
extraction or proof of every download. “FULL_SET_CANONICAL” means a metadata-backed
representative candidate under the recorded profile; it still requires fresh
source/private preflight and explicit Owner publication approval. Unreviewed
historical profiles fail closed. Do not apply 2026 taxonomy to 2010s papers.

Supporting scope evidence: the [EBS assessment scope tables](https://www.ebsi.co.kr/ebs/ent/enta/retrieveExmSchedRng.ebs?tab=3)
separate sitting/grade domains and offered/not-offered areas. The archived
[2021 grade2 scope sheet](https://file.megastudy.net/FileServer/entinfo/exam/2021/go2.pdf)
includes extra domains for November (reproduced schedule, not a live source for
all years). The [education-office KICE notice](https://www.jbe.go.kr/office/board/view.jbe?boardId=BBS_0000002&categoryCode1=A03&dataSid=449080&menuCd=DOM_000000709002000000&paging=ok&searchOperation=AND&startPage=6)
also lists those areas for the 2024-academic-year September assessment. These
references constrain the conservative review rules; individual source evidence
and the audit input retain the exact year/month/labels.

## Identity and classification

Reuse `normalizer.exam_identity`: `(year, exam_month, grade_level, exam_type)`.
Calendar year differs from academic year. Check academic_year, actual date,
organizer and source wording for contradictions. `sort_date` is not a historical
fact; attachment filenames never define identity. Unknown organizer is recorded
as unknown, not guessed by month. Existing row IDs/slugs/source_content_key stay.

Post1431/1432 expose a parser exception: `(4월 시행) 2020년 3월 ...` and
`(5월 시행) 2020년 4월 ...` select the administered prefix as nominal month.
The audit keeps existing identity and a separate title-backed nominal comparison;
no parser/DB correction, merge or52-HOLD release is made. Correcting this requires
a reviewed bounded follow-up, including affected identity groups and user links.

| Classification | Rule and action |
|---|---|
| FULL_SET_CANONICAL | One evidence-complete representative; candidate for Owner gate, never automatic publication |
| PARTIAL_DUPLICATE | Same-exam subject subset with a evidenced broader sibling; preserve source, publication HOLD; broader sibling may itself still need review |
| AMBIGUOUS | Uncertain identity, offered domains, file coverage, occurrence associations or competing full sources; review queue, no guessed exclusion/publication |
| UNIQUE_NON_DUPLICATE | Proven distinct/specialized nonduplicate; does not itself satisfy full-set exam browse eligibility |

If no full sibling is found: inspect sibling discovery coverage, union of partial
resources, identity and provenance; then propose a multi-source representation or
keep AMBIGUOUS. Never delete a partial simply because no full sibling was found.
No source/resource merge is authorized here. Lack of a sibling in this bounded
snapshot is not proof none exists anywhere on the blog.

## Gate for current and historical ingestion

SOURCE DISCOVERY → existing PARSE → existing EXAM IDENTITY GROUP → offered-area
and SUBJECT/RESOURCE COVERAGE evidence → FULL-SET CANONICAL SELECTION → partial
HOLD / ambiguous REVIEW → Owner exact-ID gate → existing private preflight →
existing controlled apply/activation → exact DB/App verification.

Persist a reviewed evidence manifest containing input fingerprint, parser/profile
version, group and candidate/sibling IDs, raw coverage, reasons, protected holds
and decision/approver. Recompute after source/parser/profile changes; stale or
incomplete manifests fail closed. The publication scope must be the intersection
of explicit Owner IDs, full-set decisions and existing writer safeguards. Refuse
partial/ambiguous/52-HOLD/1710 reconciliation leakage. Do not add a second writer.

**Implementation boundary:** `tool/audit_exam_canonical.py` is an offline report
only, has no network/DB/write/activation integration, and sets automatic authority
false for every row. The existing writer is NOT claimed to enforce this new
coverage gate yet. Its old publishable flag is no longer sufficient operational
approval. Until a reviewed enforcement increment exists, no next batch selection
or publication; an operator must present the audit and exact intersection first.

Historical expansion follows the same gate; unknown old curriculum profiles stay
review. The measured185-post sample is not the size of the entire historical
catalogue. Do not extrapolate a “2–4× reduction” without a representative crawl.

## Browse, search and archive

Primary structured Materials: grade-specific canonical exams, university essays
(including guidebooks), 수업자료실 and 요청자료실. 적성/면접/사관학교/경찰대 and other
old special materials are retained as archive/search content, not promoted as
front-page categories. This records IA policy, not a navigation rewrite or new
content_type migration. Exact request-room taxonomy mapping remains a later gate.

Browse is curated/canonical. Search can span a wider historical archive, but
partial posts should not repeatedly outrank the representative. Proposed order:
canonical full-set > unique nonduplicate > specialized/archive > partial duplicate.
No ranking engine or hidden-content RLS change is implemented. Current is_active
cannot distinguish search-only from browse-only; future exposure semantics need
review before claiming archive-search availability for inactive duplicates.

## Provenance and minimal schema assessment

Read-only Production confirms existing source_posts → content_items → exams and
resources; content_items has `is_active` and `merged_into_content_item_id`.
The latter rejects self-reference and active merged duplicates. Quarantine has
free-form kind/payload/status; raw_metadata can retain group decisions. Therefore
source preservation, inactive duplicate pointer and review evidence need **no new
schema now**. Long-cycle validation and personal-reference handling remain trusted
workflow responsibilities, not automatic FK behavior.

Resources independently reference source_post_id and content_item_id. Their
exam_subject_id/content_item_id composite FK protects occurrence ownership. This
can retain attachment-level provenance across source posts in a future controlled
multi-source representation, but the current writer is single-source and no merge
is implemented. Non-resource supporting-source relationships may later need a
small junction table only if a concrete case requires them; no speculative
canonical_content_item_id/duplicate_reason/publication_status migration now.

Current audit proves no required multi-source union under its reviewed profiles.
MULTI_SOURCE_CANONICAL_REQUIRED: NO confirmed case; unknown extra-area coverage
could change this. No fabrication of absent papers, no source deletion.

## Active replacement gate and stop boundary

Keep active partials unchanged in this audit. A separate controlled replacement
must verify current bookmark/recent/attempt references and resource FKs, preserve
old content IDs, keep stable routes or reviewed redirects, avoid automatic personal
row rewrites, and prove canonical-active/partial-suppressed target state. Never
hard-delete a referenced content item. Counts must be rechecked at execution.

Stop unsafe selection on missing full-set evidence, required Production/schema
change, accepted-state work,1710/52-HOLD conflict, same-file conflict or unexpected
inventory drift. An AMBIGUOUS report is a stopped decision, not permission to
force a full-set classification. Owner/ChatGPT review precedes any next batch.

## Phase2 strict evidence rule (2026-09-27)

[Phase2 audit and replacement plans](exam-canonical-audit-phase2-2026-09-27.md)
implement the Owner's conservative rule in an **offline-only** classifier.
The Phase1 label FULL_SET_CANONICAL describes a provisional metadata candidate;
it must not bypass the stronger Phase2 requirement for an independently evidenced
exam-specific complete expected profile and organizer. Previous30 are retained
as provisional candidates but all30 need strict revalidation; original27 remain
REVIEW. At the Phase2 checkpoint strict verified ready was0, not30. No source/Production rows
or writer-ready inventory were reclassified in place.

Profiles are exact year/grade/nominal session/family/organizer evidence, with
actual date consistency and historical curriculum context. Unknown profiles,
optional-domain applicability, raw occurrence splits and ambiguous bundles fail
closed. Social/science domain membership is a named-paper set, not a count.
Original labels and source provenance are retained; no modern taxonomy is forced
onto2010s files. Partial needs a proven same-exam subset; a broader sibling can
still be REVIEW and cannot become a replacement target automatically. Ranking
uses identity, completeness, evidenced usability and metadata quality; ties REVIEW.
No per-post FULL_SET bypass, production writer integration or automatic gate.

The existing merged_into_content_item_id is sufficient for a future single-target
supersede relation, but the App currently cannot follow inactive old links.
Keep bookmarks/recent/history intact; recent_views content identity is immutable
and its trigger overwrites timestamps. Both replacement cases remain unsafe until
separate target/identity/scope and redirect/reference-preservation Owner gates.
No migration, source deletion,52-HOLD release or1710 A1 action in Phase2.


## Phase3 independent expected coverage (2026-09-27)

[Registry contract](exam-expected-coverage-registry.md) and [Phase3 audit](exam-canonical-audit-phase3-2026-09-27.md)
supersede current pool counts:57→22 FULL_SET /0 partial /35 REVIEW. Source titles
and counts never define expected coverage. Exact official year/grade/session
inventories, conditional domains and field-scoped provenance are required;
unknown profiles do not inherit adjacent years. Planned and actual dates remain
separate; conflicting source assertions stay REVIEW without DB identity edits.
Phase3 strengthens partial classification: only a strict subset of a unique
verified FULL_SET sibling qualifies; broader REVIEW siblings and complete ties
remain REVIEW. Phase2's weaker diagnostic subset output remains historical only.
1431 passes coverage but52-HOLD remains;1474 is partial;1447/1404 remain REVIEW.
This is offline reference tooling only. No writer/gate integration, Production
mutation, target activation or next-batch selection. Owner/ChatGPT review next.
