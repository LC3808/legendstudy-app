# Phase 1-A2 — Production preflight reconciliation

2026-09-20; initial review HEAD `78f8144`; Owner-probe closeout starting HEAD
`74c7872`, branch `codex/day-7-school-neis`.
Initial tracked tree clean; existing four untracked directories preserved.
**Phase 1-A2 structural preflight COMPLETE within the Owner probe scope.**
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

## Owner 15-candidate probe closeout

Owner subsequently executed `2024-preflight-probe.sql` in Production SQL Editor
and explicitly reported all 15 rows for post IDs:
1614, 1615, 1616, 1617, 1618, 1619, 1620, 1621, 1634, 1635, 1636,
1646, 1647, 1648, 1649. These exactly match the probe and candidate manifest.
For EVERY row, Owner reported:

| Probe field | Value |
|---|---|
| existing_source_id | NULL |
| existing_content_id | NULL |
| existing_occurrences | 0 |
| existing_resources | 0 |
| all_content_keys_on_source | 0 |
| resources_using_source_provenance | 0 |
| foreign_identity_url_conflicts | 0 |
| foreign_identity_slug_conflicts | 0 |

This is Owner-reported evidence, not a new Codex DB query or raw export.
The preceding seven-post empty query retains its narrower meaning; the NEW
15-row LEFT JOIN probe closes the bare-source/remaining-eight/global-guard gaps.

## Layer-by-layer evidence

| Layer | Candidate count | Exact Production overlap | Status |
|---|---:|---|---|
| source_posts | 15 | 0 for (legendstudy, candidate external_post_id) | PASS — Owner probe |
| content_items | 15 | 0 for resolved source identity + main; no other content on these absent sources | PASS — parent absence |
| exams | 15 | 0 under these absent content parents | PASS — parent absence |
| exam_occurrences (exam_subjects) | 246 | 0 compound-key overlaps under these absent parents | PASS — parent absence |
| resources | 489 | 0 compound-key overlaps under these absent parents; no provenance via those sources | PASS — parent absence |

Child zero counts with NULL parent IDs are consequences of parent absence, not
independent scans for matching resource keys anywhere in Production. Required FK
contracts mean those exact natural-key children cannot exist without the parents.
Foreign URL guards compare EXACT canonical `https://legendstudy.com/<post>`
strings; slug guards compare EXACT `legendstudy-<post>-main` strings across
identities. Both returned zero for all candidates. No URL-alias/redirect/byte-level
file-duplicate/global semantic equivalence check is implied. Deterministic UUID
PK collisions against unrelated identities are not tested by this probe either;
future writer/preflight must fail closed on any such conflict.

Local compound-key collisions and merge candidates remain zero. Within the
probe's natural-key and exact URL/slug scope: candidates are CANDIDATE_ONLY,
MATCH=0 and observed CONFLICT=0. Production-only content elsewhere is outside
this candidate probe, not zero. No insertion or publication is authorized.
The Phase 1-A1 CSVs retain their original UNVERIFIED snapshot fields; this dated
A2 report supersedes them for current probe-scoped Production overlap status.

## Publication gates

| Gate | Status | Evidence / remaining condition |
|---|---|---|
| 1 deterministic identity collision | PASS (probe scope) | all 15 natural source/content/provenance identities absent; exact canonical URL/slug guards zero; not semantic/file/UUID-global verification |
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

## Exact next action — semantic/quarantine/file validation, NOT publication

Owner reviews the raw resource evidence for 1618 (생화활과윤리), 1646
(사회문화1), 1649 (수학(미정)) and records confirmed meaning or continued HOLD.
Do not infer corrected subject labels. Use `2024-grade3-subject-pairing.csv`
for the 141 observed question/answer pairs, 7 question-only and 3 review-required
occurrences, and `2024-grade3-batch.csv` for exact resource identities/labels.

Next separately scoped work should record per-resource source evidence, actual
availability, file/type/subject agreement and quarantine disposition. Current
299 grade-3 resources have no verified downloadable file targets. No case is
closed by identity absence: 7 expiration + 3 subject-unknown cases remain open
in the candidate plan (not new Production rows). Keep provisional mappings,
NULL/unscoped ambiguous files and is_active=false until the relevant decisions.
Owner final publication approval is still absent. No automatic remapping,
publication SQL, active-state change, downloads/mirrors or link replacement now.

Before a future authorized write, refresh time-sensitive preflight and validate
the exact write manifest/PK guards and preservation snapshots; this result is
not a perpetual guarantee that Production cannot change. Existing 2025/2026
rows must never be updated, merged, replaced or re-parented by the new batch.
Viewer/Mock Exam priority remains recent grade-3 materials; metadata expansion
and Viewer migration are separate. This closeout stops before Owner semantic
judgement or any Production mutation is required.

## Validation and scope

Existing ingestion + historical tests **150 PASS**, including deterministic-key,
semantic-clock and CSV-consistency regression. `git diff --check` PASS.
SELECT probes were statically inspected against repository column contracts;
not executed by Codex, and no new live DB/schema claim is made.
Production mutation **0**; no push. No parser, candidate fixture or app changes.

HISTORICAL PHASE 1-A2 PREFLIGHT COMPLETE: YES
2024 PUBLICATION READY: NO
