# Phase 1-A2 — Production preflight reconciliation

2026-09-20; starting HEAD `78f8144`, branch `codex/day-7-school-neis`.
Initial tracked tree clean; existing four untracked directories preserved.
**Evidence review recorded; full exact-key preflight INCOMPLETE / UNVERIFIED.**
Phase 1-A1 remains COMPLETE. **2024 PUBLICATION READY: NO.**

## Owner evidence, not a new Codex DB inspection

Owner reports executing `2024-validation.sql` in Production: 2025 15 exams /
246 occurrences / 507 resources; 2026 8 / 117 / 232; total **23 / 363 / 739**.
No 2024 exam rows returned. The 23 returned open quarantine rows were
resource_url_expiring for existing 2025/2026 content. Their source-to-exam
cardinality is not supplied; do not equate 23 cases with 23 exams.
The task supplies summaries, not the first four SELECTs' row-level exports.

2024 local candidate remains **15 / 246 / 489** (grades 1/2/3: 4/4/7).
Grade 3: **7 / 151 / 299** (149 question, 146 answer_explanation, 4 scripts).
Only if all candidates are eventually accepted with no replacement would the
arithmetic sum be **38 / 609 / 1,228**. This is neither a Production target nor
publication readiness. No future/unpublished 2026 combination is marked missing.

## Exact meaning of the empty result

The final (seventh top-level) SELECT in `2024-validation.sql` is the batch
clock/visibility query. Its FROM is content_items INNER JOIN source_posts,
filtered by source='legendstudy' and external_post_id IN
(1614,1617,1618,1621,1634,1646,1649). It has NO year, grade, source_content_key
or active-state filter. Clock equality and active child counts are selected
values, NOT WHERE conditions.

Under the Owner's reported Production SQL Editor visibility, zero rows proves
there is no content item of ANY key/type/year/active state attached to these
seven source identities. Consequently there is no exact `main` content parent,
exam extension or occurrence/resource descendant under those absent parents.
This is stronger than just 'no active grade-3 exams' and narrower than 'no
source or deterministic collision anywhere'. It does NOT prove:

- absence of bare source_posts for those IDs (INNER JOIN hides them);
- absence for the other eight grade-1/2 candidates;
- absence of a global slug or source URL collision attached to another identity;
- absence of resource provenance using a bare source under another content item;
- absence of semantic duplicates under different source identities;
- passing clock/active-value checks (there are no returned values to inspect).

No credential or signed locator is needed to close these gaps.

## Layer-by-layer evidence

| Layer | Candidate count | Exact Production overlap | Status |
|---|---:|---|---|
| source_posts | 15 | unknown, including the seven bare-source possibilities | UNVERIFIED |
| content_items | 15 | 0 for seven grade-3 source parents; remaining eight unknown | PARTIAL / UNVERIFIED overall |
| exams | 15 | 0 descendants under those seven parents; all 2024-year exams absent; other candidate keys under wrong years not excluded | PARTIAL / UNVERIFIED exact overall |
| exam_occurrences (exam_subjects) | 246 | 0 under seven absent parents (151 local candidate occurrences); remaining 95 unknown | PARTIAL / UNVERIFIED overall |
| resources | 489 | 0 under seven absent parents (299 local resources); remaining 190 and cross-parent provenance unknown | PARTIAL / UNVERIFIED overall |

Local compound-key collisions and merge candidates remain zero. Production
MATCH / CANDIDATE_ONLY / INSERT / UPDATE / NOOP / CONFLICT per full layer are
not assigned from aggregates. Repeated resource keys under different content
parents are not automatically a compound-key collision or semantic equality.
Candidate CSV production_key_status remains UNVERIFIED to avoid overstating the
full-layer result; this report records the narrower newly established absence.

## Publication gates

| Gate | Status | Evidence / remaining condition |
|---|---|---|
| 1 deterministic identity collision | UNVERIFIED | local checks PASS; seven content parents absent; bare sources, other eight and global guards outstanding |
| 2 semantic mapping | HOLD | exam/file meaning and semantic duplicate review incomplete; metadata is not linked-file verification |
| 3 quarantine resolution | HOLD | grade-3 candidate 7 expiration + 3 subject-unknown cases unresolved; separate from Production 23 |
| 4 URL/file availability | UNVERIFIED | unsigned identity locators, NULL file_url, unknown/unchecked; no payload inspected |
| 5 subject mapping | HOLD | all provisional; raw labels retained; 생화활과윤리 / 사회문화1 / 수학(미정) remain unscoped |
| 6 idempotency | PASS (offline contract only) | deterministic IDs, repeat NOOP tests pass; 2024 DB rerun not verified |
| 7 rollback/fail-closed | PASS (offline contract only) | canonical transaction rollback/partial-state refusal tests pass; quarantine separate; no Production rollback performed |
| 8 is_active policy | PASS (candidate only) | all candidate rows false; no authority to activate |
| 9 Owner publication approval | HOLD | this task authorizes SELECT/offline work only |

Existing apply code is INSERT-only, not a merge/re-parent/update mechanism.
Nothing in this task modified existing 2025/2026 data. A future controlled batch
must preserve existing IDs, values, mappings, parents and active states. Those
future effects cannot be guaranteed by these SELECT summaries: all collisions
must fail closed, with exact before/after snapshots and a reviewed 2024 scope.
Current Pilot C scope is not authorization to write 2024 rows.

## Exact next action

Owner runs `2024-preflight-probe.sql` and supplies all 15 result rows. It uses
LEFT JOINs so bare sources and absent content remain visible; it also checks
canonical source-URL and global slug guards, including other source identities,
and cross-parent resource provenance. No URL response bodies or secrets selected.

If any source/content/provenance row exists, provide the relevant first four
SELECT outputs from `2024-validation.sql` for natural-key/value comparison;
do not repair/update it. A clean probe can establish key absence, but semantic,
file, quarantine and approval gates still remain. No publication command now.
Viewer/Mock Exam priority remains recent grade-3 materials; metadata expansion
and Viewer migration are separate. No mirror/Storage/outbound-link/viewer/rights
work performed.

## Validation and scope

Existing ingestion + historical tests **150 PASS**, including deterministic-key,
semantic-clock and CSV-consistency regression. `git diff --check` PASS.
SELECT probes were statically inspected against repository column contracts;
not executed by Codex, and no new live DB/schema claim is made.
Production mutation **0**; no push. No parser, candidate fixture or app changes.

HISTORICAL PHASE 1-A2 PREFLIGHT COMPLETE: NO
2024 PUBLICATION READY: NO
