# Materials Data Rollout and Historical Backfill Plan

Status: **OWNER-APPROVED ROADMAP / IMPLEMENTATION GATED — 2026-09-26**

This document records the canonical rollout order for LegendStudy Materials data.
It does not authorize Production mutation by itself. Reuse the existing ingestion
pipeline and prove each boundary before expanding scope.

## Product objective

Finish a useful Materials foundation quickly and accurately, then begin App
release work without waiting for the entire historical archive.

The governing implementation rule is: minimum cost, easiest viable solution,
lightweight structure, concise implementation, reuse existing assets, expand only
on demonstrated need.

Do not build separate crawlers or publication systems for Daily Sync, historical
backfill, and essay discovery when the existing ingestion contracts can be reused.

## Current baseline

As of the 2026-09-25 EOD closeout:

- Daily Sync Phase 1 discovery/delta foundation: COMPLETE.
- Bounded source validation: PASS.
- Sitemap inventory observed: 1,676 posts.
- Production Phase-0/Pilot-C baseline reported by Owner: 23 source posts,
  23 active content items, 23 exams, 363 active exam subjects, 739 active
  resources; integrity checks zero.
- The Phase-1 source run used an empty accepted local state. Old IDs such as
  2/4/6/7/8 therefore classified as NEW. This is the
  **COLD_START_BASELINE_GAP**, not evidence that they are new Production posts.
- Daily Sync Phase 2: NOT STARTED / OWNER GATED.
- Materials direct PDF: OWNER DEVICE PASS.
- Existing ingestion code already separates discovery, parsing, normalization,
  delta/state, apply/writer and taxonomy.
- Existing taxonomy already recognizes the essay-source category as
  university_essay; essay material does not need a second crawler merely because
  its later LAB data model is richer.

## Immediate Track A — restore trustworthy latest-post updates

### A1. Bootstrap accepted state from canonical Production

Before any general Phase-2 publication, create a reviewed bootstrap/reconciliation
path that represents the already-published canonical Production baseline in the
Daily Sync accepted state.

Requirements:

- Production canonical rows are the baseline authority; do not mark the full
  1,676-post sitemap as accepted merely because it exists.
- Preserve stable source/content/resource identities and accepted projection/
  resource descriptors required by the existing delta engine.
- Do not rewrite canonical content as part of bootstrap.
- Do not fabricate unavailable historical observations.
- If an accepted-state field cannot be reconstructed safely from canonical
  evidence, stop/fail closed or explicitly re-observe that bounded source post.
- Bootstrap must be idempotent and inspectable.
- First implementation should be an explicit operator action, not a scheduler.

Acceptance: rerunning bounded discovery after bootstrap must no longer classify
already-published baseline posts as NEW solely because local state was empty.

### A2. Re-run recent discovery/delta

After A1, re-run bounded recent discovery against the accepted baseline.

Expected semantics:

- existing unchanged canonical post → UNCHANGED;
- actual source revision → MODIFIED;
- actual post newer/not represented in canonical baseline → NEW;
- malformed/ambiguous/fetch failure → existing safe state/quarantine behavior.

Do not infer latest from numeric ID alone when source evidence disagrees.

### A3. Controlled latest-post publication

Use the existing parser → normalizer → delta → reviewed apply/publication path for
a very small set of actual NEW/MODIFIED recent posts.

Initial rollout is manual/controlled. Do not add Cron merely to prove that latest
content can flow into the App.

Acceptance:

1. new/revised source post is discovered correctly;
2. normalized canonical data passes existing publication invariants;
3. Owner reviews bounded change;
4. controlled Production apply;
5. App search/detail shows the new material;
6. PDF direct-open remains valid where applicable;
7. no unrelated rows are changed.

Only after repeated controlled success should scheduler/automatic staging be
considered.

## Track B — Historical Materials backfill

Historical expansion is deliberately phased so App release is not blocked by the
entire archive.

### Wave 1 — 2020 through current

**Release data gate:** complete and validate 2020→current Materials coverage, then
begin initial App deployment/release work.

Use the existing ingestion pipeline. Historical backfill differs mainly in
discovery/scope and operator batching; it is not a new canonical data model.

Include supported LegendStudy source categories, especially:

- CSAT;
- KICE mock assessments;
- education-office academic assessments;
- other currently supported exam material;
- university essay source material that maps safely to university_essay.

Preserve historical taxonomy safeguards. Never auto-map an old curriculum/subject
label to a modern elective merely to increase coverage.

Backfill should be bounded/batched, resumable and idempotent. Inspect counts and
quarantine/ambiguity between batches rather than attempting one huge Production
mutation.

### Wave 2 — 2015 through 2019

Begin after initial App release path is underway and Wave 1 is stable. Reuse the
same contracts and historical-taxonomy protections. This is a content expansion,
not a release blocker for the first App version.

### Wave 3 — 2010 through 2014

Final planned five-year historical expansion. Same pipeline and safety rules.
Do not redesign the App or ingestion architecture solely for this oldest wave;
handle genuinely unsupported historical formats explicitly.

## Track C — Essay material bridge

Historical Materials ingestion and Essay LAB DB are related but not identical.

### Materials layer

The existing ingestion taxonomy recognizes university_essay. The Materials
backfill should first inventory/publish safely supported essay posts and their
source-linked resources with provenance.

This gives the App useful essay discovery without waiting for the AI Essay engine.

### Essay LAB layer

A later dedicated Essay DB enrichment follows the canonical Essay roadmap:

university → year → track/type → question/passages → official explanation /
example answer / intended reasoning / rubric → evaluation package.

Reuse existing LegendStudy essay assets and the prior Manus research before doing
new research. Do not infer missing official materials. AI feedback is downstream
of the inventory/evaluation package, not the first step.

## Relationship to the wider roadmap

Current priority sequence:

1. **Materials foundation**
   - accepted-state bootstrap;
   - latest-post controlled update;
   - 2020→current backfill;
   - essay Materials inventory/connection;
   - App Materials/PDF validation.
2. **Initial App deployment/release work** after Wave-1 data gate.
3. **Essay DB + Essay LAB** using existing research/assets.
4. **Mock Exam score/grade history expansion**, including official grade data.
5. **Admissions engine / acceptance-estimation evidence foundation** — deterministic
   rules and outcome data first; probability remains model/evidence gated.
6. **Internal-grade input and university/department exploration/estimation** using
   verified university formulas/rules.
7. Continue historical Materials: 2015–2019, then 2010–2014.
8. Multi D-Day/Home customization/Analytics continue as planned tracks and may be
   scheduled around the above according to product need.

This ordering is a priority guide, not permission to collapse evidence/privacy/
model gates for admissions predictions.

## Research reuse rule

Before commissioning new research:

1. check Wiki Task Routing and research-registry.md;
2. inspect imported Manus synthesis/package;
3. locate the original Manus report/export when the synthesis is insufficient;
4. reuse existing source inventory and decisions;
5. research only the missing evidence.

Known state: the A–D synthesis and Daily Sync Phase-1 package are SOURCE ACQUIRED.
Individual A–D full reports are not all independently inspected in Wiki. Do not
pretend they are absent, and do not pretend their unseen details are known.

## Implementation handoff

A1/A2/A3 code already exists;1712/1711/1710 publication is complete per Owner
and public Production verification. Wave1 inventory and minimal writer/parser extension are complete/tested. Private
Production preflight and publication remain Owner-gated. Historical checkpoints below retain their dated evidence but do not
reinstate1710 HOLD. See the current Wave1 checkpoint at the end of this document.


## Recent publication ordering and 1710 HOLD — 2026-09-26

**SUPERSEDED historical checkpoint:** Owner subsequently authorized and completed
1710 publication/activation; current code makes subject_taxonomy_gap advisory.
Do not execute the obsolete HOLD/approval instructions below as current policy.

Owner definition: Recent Updates is **all active content**, ordered by original
`content_items.published_at DESC NULLS LAST`, then existing `id DESC` only for
equal timestamps. Full timestamp precision is preserved. Home's
`homeRecentContentProvider` (limit 6) and `recentContentProvider` share
`SupabaseContentRepository.fetchRecentContent`. Previously this used
`feed_updated_at DESC`. Search ordering, relevance, filters, saved/recent-view
semantics are unchanged. No content/exam type restriction is introduced.
`source_updated_at`, `feed_updated_at`, sitemap lastmod and last_checked_at are
not Recent Updates ordering evidence; delta discovery remains unchanged.

Expected after eventual 1710 publication, subject to actual Production published
values: 1712 → 1711 → 1710. Edited post1649 returns to its original published
position. This task did not query Production or verify the actual device order.

Fresh bounded source dry-runs observed only 1710 (plus sitemap, no attachments).
Before: 18 `resource_subject_unknown` cases (9 subjects × question/answer).
After: unknown **0**, **9 subject_taxonomy_gap**, and the existing one expiring-URL
advisory. Metadata: exam / evaluation_mock / calendar2026 / academic2027 /
month9 / grade3. Plan rows: source_posts1, content_items1, exams1,
exam_subjects33 (24 provisional, 9 unmapped), resources67.
These are **held plan counts, not approved inserts or Production counts**.

Recognition now includes observed raw labels 독일어, 프랑스어, 스페인어, 중국어,
일본어, 러시아어, 아랍어, 베트남어, 한문 in the existing parser vocabulary.
No post-ID exception, invented subject ID, seed/schema change or publication-gate
bypass. Canonical v1 still has23 subjects and apply preflight expects23.
Owner confirmed no additional Production subjects and explicitly chose
**taxonomy approval before publication; HOLD**. Confidence remains **medium**,
publishable **false**. Existing `assert_in_scope` rejects this plan before DB
connection. Live DB preflight/apply/activation were not executed.

The local ignored A1 state contains26 entries; its stored occurrence projections
contain none of these9 labels. Focused before/after fingerprint tests prove
ordinary subject input unchanged and newly recognized-label input changed.
This is not a fresh observation of every accepted page. No accepted state was
rewritten and no26-page re-observation was performed. A later approved taxonomy
change must assess affected entries only;1710 is not accepted by this task.

Owner next step: separately approve canonical taxonomy support and its existing
seed/preflight contract. Until then, **do not apply or activate1710**. The safe
repeat command is:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 tool/ingest_legendstudy.py \
  --source network --post-ids 1710 --out /tmp/legendstudy-1710-review
```

After that separate correction, obtain a fresh high/publishable plan and use the
existing general `--post-ids` controlled apply and `tool/publish_pilot_c.py`
activation path with reviewed exact counts. No new writer is needed; no executable
write command is approved for the current held plan.1618 remains untouched.

Validation: Flutter analyze PASS; recent/repository/search51 tests PASS;
ingestion181 + focused subject/recent-delta/controlled-apply/activation/Pilot-C38
PASS. An initial broader Python discovery also encountered4 unrelated Mock
scoring import errors because system Python lacks psycopg; those tests are outside
this task. No full Flutter suite/build requested or run. Production writes0.


## Wave1 first checkpoint — 2026-09-27

Acceptance: inventory2020→current Materials across all supported content types,
reuse bounded/resumable/idempotent ingestion, publish safely supported posts only
after the Owner historical-mutation gate, and isolate actual blockers.
**Historical first checkpoint; superseded by the inventory-complete section below.**
At this checkpoint Wave1 inventory/publication was not complete.

Preflight: actual repo `/Users/woojinchang/development/legendstudy-app`, branch
`codex/day-7-school-neis`, starting local and freshly fetched origin both8009def.
The task's Documents directory is an old checkout, not the execution repository.
Owner modified iOS project/Info.plist and existing untracked files are preserved.
Operating principles, routing, scope/decisions and ingestion/rollout read.

Public Production REST read:27 active content items, first1712/1711/1710;
published timestamps agree with required ordering and code. Owner additionally
confirms1710 core resources/device PASS. This read does not inspect private
source_posts, inactive rows or database-wide integrity. Accepted-state has26
entries and omits1710; reconcile via existing A1 contract against canonical
publication evidence, never republish1710 or mark observations accepted.

Fresh sitemap:1676 numeric posts.781 have lastmod>=2020 (missing dates would also
be included). This is a discovery candidate set, **not781 Wave1 posts**; final
inclusion uses landing-page published_at, never lastmod or exam year.895 earlier
lastmod entries are provisionally outside discovery scope, relying on source
modification time not preceding publication; that is a scope assumption, not a
fresh read of those895 pages. Existing226-row survey retained as historical
metadata evidence, not a full current publication inventory.

First batch:50 unpublished pages, no attachment download, no DB write. Actual
publication years2024:24,2025:25,2026:1; types exam4, university_essay45,
education_column1. Existing pipeline normalization yields:

| Classification | Count | Meaning |
|---|---:|---|
| ALREADY_PUBLISHED |27|Public active baseline; local accepted26 +1710 gap|
| READY |0|Publishable with no advisory in this batch|
| ADVISORY |20|Publishable normalization;3 exam,17 general Materials|
| HELD / review |30|Current rules; not yet confirmed true blockers|
| UNKNOWN |704|Remaining discovery candidates, not yet observed|

Held reasons overlap: resource_kind_unknown28, resource_subject_unknown1,
attachment_none1; resource_url_expiring appears on29 held posts but is advisory.
Review these for safe general-resource representation before treating them as
real publication blockers. No force mapping or blanket gate bypass.

20 publishable plans contain20 sources,20 content items,3 exams,30 occurrences,
267 resources. These are **potential plan counts, not approved Production deltas**.
Existing controlled writer currently requires exam in both assert_in_scope and
resolve;17 non-exam candidates therefore require a small existing-path extension
and tests before apply. Only1636/1647/1648 pass today's apply scope; no approval or
apply has been requested/performed. Private canonical collision/inactive checks
and exact per-batch delta remain mandatory before writes.

Reused: PoliteFetcher/NetworkSource, parser, normalizer, pipeline.run,
write_artifacts, writer scope/collision checks and public Production baseline.
No crawler/publication system or CLI date option added. Operator glue only under
`/tmp/legendstudy-wave1/`; each page has a resumable redacted observation checkpoint.
Batch size50, serial1.5-second minimum spacing, timeout20s, at most2 retries/page.
Existing source parser strips signed queries; body excerpts and attachments are
not persisted/downloaded. Accepted state is unchanged.

Artifacts (local, not durable across machine cleanup):
`/tmp/legendstudy-wave1/summary.json`, `production-public-content.json`,
`sitemap.xml`, `observations/`, `dryrun/dryrun-posts.csv`,
`dryrun/dryrun-quarantine.csv`. Retain/move reviewed metadata into existing
repository sample conventions before a later publication handoff.

Validation: ingestion181 tests PASS, identical-input normalization rerun PASS,
no duplicate planned upsert keys. This is offline determinism, **not Production
apply idempotency**. No Flutter changes/analyze, migration, activation, source
attachment requests or accepted-state mutation.

Next read-only commands (resume next50, then regenerate cumulative artifacts):

```sh
cd /Users/woojinchang/development/legendstudy-app
PYTHONDONTWRITEBYTECODE=1 python3 /tmp/legendstudy-wave1/observe.py --batch 50
PYTHONDONTWRITEBYTECODE=1 python3 /tmp/legendstudy-wave1/summarize.py
```

Next gate: finish candidate inventory/dry-run and review false holds/non-exam
writer support, reconcile canonical/private state, then show exact READY/ADVISORY/
true-blocker counts and concrete bounded Production change for Owner approval.
The pasted task explicitly requires STOP before bulk historical mutation.


### Prior roadmap checkpoint moved from current status

**2026-09-26 Materials rollout priority override (historical roadmap)**

Owner sets the immediate product sequence to finish the Materials foundation
quickly and accurately before expanding major feature work. Canonical plan:
[Materials rollout and historical backfill](materials-data-rollout.md).

1. Bootstrap/reconcile the already-published Production baseline into Daily Sync
   accepted state; then re-run recent delta and controlled latest-post publication.
2. Historical Wave1 **2020→current**, including safely supported essay-source
   Materials, is the initial App-release data gate.
3. Begin initial App deployment/release work after Wave1 validation rather than
   waiting for the whole archive.
4. Later backfill **2015–2019**, then **2010–2014**.
5. Next major product tracks: Essay DB/LAB using existing Manus research/assets;
   Mock score/grade history; Admissions evidence/rules and later model-gated
   acceptance estimation; internal-grade input and university/department analysis.
6. Home customization/analytics.legendstudy.com remain planned and are scheduled
   around the higher-priority data/product tracks (Multi D-Day is implemented).

Do not commission duplicate research. Check Wiki/Research Registry/imported Manus
sources first and retrieve original Manus reports when synthesis detail is
insufficient. Current implementation handoff is the Wave1 first checkpoint in this document.
No scheduler, broad automation, backfill mutation or Essay schema is bundled.


## Wave1 inventory complete — 2026-09-27

**Historical inventory checkpoint:** read-only inventory complete. The subsequent
implementation checkpoint below supersedes its writer-change STOP; publication
remains unapplied/Owner-gated. No writer, parser, taxonomy, schema, App,
Production, accepted-state, commit or push change in this continuation. Preserve
all earlier local Wiki work and Owner modified/untracked files. Personalization
continuity already recorded; no additional expansion or implementation here.

### Coverage and source-time evidence

- Sitemap1676; discovery candidates781. All781 now have source published_at
  evidence:754 previously unpublished observations +27 published baseline pages
  read for complete resource diagnostics (always excluded from apply candidates).
- Actual Wave1:296 posts =27 already published +269 unpublished.485 candidates
  have published_at before2020 and are excluded even when lastmod is newer.
- Remaining earlier-lastmod895: no overlap with the saved modern survey. Bounded
  sanity sample13 = top5 numeric IDs + latest5 lastmods +7 numeric quantiles,
  deduplicated. All13 published before2020; no published_at>lastmod inversion
  among794 observed pages. No evidence of a realistic missed modern-post pattern;
  this is bounded assurance, not an exhaustive publication-date census of895.
- Sample IDs:2,240,453,677,895,1123,1177,1378,1400,1401,1402,1403,1404.
  Of the895,13 have direct pre2020 evidence and882 retain metadata-based exclusion.
- Unknown discovery candidates0; source fetch failures0, retries0, parse failures0,
  missing source publication timestamps0. The original50 observations were reused.
  The704 remaining candidates ran sequentially in14 batches of50 and one of4.
- Wave1 uses **source publication year**, not exam year: a2019 exam article first
  published2020 belongs in Wave1. No modification-date promotion.

| Source publication year | All Wave1 posts |
|---|---:|
|2020|62|
|2021|9|
|2022|16|
|2023|106|
|2024|51|
|2025|40|
|2026|12|
|Total|296|

| Existing content type | All Wave1 | Unpublished |
|---|---:|---:|
|exam|142|115|
|university_essay|135|135|
|study_material|14|14|
|admissions_info|0|0|
|education_column|5|5|
|other|0|0|

Types are the current category mapping, not a claim that no admissions-related
material exists: 교육 입시 관련 소식 maps to education_column. Unknown categories
were not force-mapped; none were observed in Wave1.

### Classification — unpublished269 only

| Metric | Count | Interpretation |
|---|---:|---|
|NORMALIZATION_PUBLISHABLE|123|Raw per-post result;15 also require cross-post identity review|
|EXISTING_WRITER_READY|30|Exam scope passes locally; not a DB preflight or apply approval|
|GENERAL_WRITER_GAP|78|72 essay +6 study; publishable but current writer insists on exam|
|READY without advisory|6|Among108 not held by cross-post identity review|
|ADVISORY publish candidates|102|Among108; signed locators remain unchecked|
|CURRENT_HELD|161|Includes15 per-post publishable plans in merge groups|
|TRUE_BLOCKER / identity reconciliation|52|23 canonical-exam groups; reviewed target/linkage required|
|FALSE_HOLD_CANDIDATES|109|33 exam filename rules +71 general filename rules +5 text columns|
|UNSUPPORTED|0|No confirmed unsupported post under current Materials content model|
|FETCH_PARSE_FAILURE|0|No missing observation or normalization exception|

These are overlapping diagnostics, not additive publication counts. Disjoint
new-post partition:30 ready +78 writer gaps +52 identity-review +109 false-hold
candidates =269. Across all296 including baseline, raw normalization-publishable
is150; the27 published posts must never be counted as new inserts. Potential
108 currently non-held new plans contain108 sources/content,30 exams,484
occurrences and2086 resources; this is not an approved/private-DB-verified delta.

### Actual identity review versus false holds

The52 identity-review posts normalize to23 repeated exam identities. Examples:
1421/1422 split2019 June grade1 core and inquiry papers;1445/1460/1461 split2019
July grade3 core/social/science papers;1437/1464 are all-subject versus core-only
2020 March grade1 coverage. Some groups reuse the same listening resource.
Source titles establish legitimate split/overlapping source content, not52 corrupt
posts. A reviewed canonical exam/content target and resource provenance strategy
is required before publishing all group members independently. **TRUE_BLOCKER
means unresolved publication identity/linkage gate, not unusable source content.**
Do not merge, delete, accept or publish these automatically. Exact23 groups/52 IDs
are retained in final-report.json and review-classification.csv.

False-hold candidates remain unapproved until fixtures/rules verify them:
-33 non-merge exam posts: Box listening labels append `(PC/스마트폰 실시간)`,
  `(실시간 & 다운)` etc; question/answer labels carry `(홀)`, `(풀이)` or
  elective decorations. Also `국어_공통`, `국어(+언매)`, `탐구영역`, and source
  typos `생화과윤리`/`사회문화1`. Preserve raw labels; uncertain/combined labels
  must not be forced into a canonical subject. A narrow parser/recognition fix
  is separate from allowing generic non-exam resources; exam invariants stay.
-63 essay +8 study posts: valid stable PDF identities, but names such as 문제지,
  출제문항, 가이드북 or 문제 모음-배포용 do not match the exam-like suffix rule.
  Existing resource_type `other` preserves the label; this does not require a new
  taxonomy/schema. Conditional non-exam advisory handling is the proposed fix.
-5 education columns (1478/1491/1575/1613/1701): schedules/competition-rate text
  posts, no observed attachments. Parent-only columns are already valid in the
  ingestion contract; attachment_none is an inappropriate whole-post hold here.

### Resource diagnostics — all296 Wave1 posts

Counts overlap. Cases, posts, occurrences and resources are distinct units.

| Reason | Posts | Affected resources | Extra unit |
|---|---:|---:|---|
|resource_kind_unknown|137|231|231 cases|
|resource_subject_unknown|70|97|97 cases|
|subject_taxonomy_gap|1|18|9 occurrences,1710 only|
|resource_url_expiring|230|4450|advisory, not a download verification|
|attachment_none|5|0|parent-only text columns|
|source/resource identity collision detected|0|0|planned stable keys; parser deduplicates repeated links|
|canonical exam identity review|52|N/A|23 source groups, not resource-level collisions|
|category ambiguity|0|0|no unknown/missing category|
|other normalization reasons|0|0|merge review reported separately above|

Any advisory occurs on230 total/203 unpublished posts, including held posts;
this must not be confused with102 non-held ADVISORY publication candidates.
5752 total planned resources include881 on published baseline and4871 on new posts.
No attachment bytes, full article body, signed query, file validation or mirroring.

### General Materials shapes and smallest follow-up

General Materials total154 posts:135 essays/1645 PDFs,14 study collections/133
PDFs,5 columns/no attachments. All1778 observed general resources are PDFs;
resource kinds already fit question/answer/explanation/answer_explanation/reference/
other, attached to content with no exam occurrence. Multi-year university essay
collections remain ordinary source-linked Materials, not Essay LAB data.

A writer extension is required but **not implemented**. The original Pilot C
exam-only scope was generalized only by post IDs/year window: `cmd_apply` still
uses exam-only approved_scope, `assert_in_scope` insists on plan.exam, `resolve`
requires and expands an exam dict, and `_rows_for('exams')` emits one per post.
Smallest follow-up within these existing functions:
1. Keep exam required identity/year/type/occurrence invariants unchanged.
2. Permit only explicitly scoped supported non-exam types; reject exam/occurrence
   children there, resolve optional exam=None, and skip absent exam rows.
3. Keep source/content/resource identities, unsigned/unchecked links, nullable
   exam_subject_id, inactive insertion, transaction/count/approval gates unchanged.
4. Separately make general resource-kind and valid parent-only-column confidence
   rules conditional; no global suppression of exam unknown-resource checks.
5. Test mixed/exam/non-exam/text-only counts, invalid cross-type children, rerun
   safety, exact activation and existing exam regressions before any DB action.
Existing parameterized activation supports0 exam/occurrence counts; reuse it,
verify it with focused tests, and add no new writer/publication subsystem.

### Baseline, validation and handoff

Production active baseline27; local accepted26, gap1710 only. Source reads for
baseline diagnostics do not advance accepted state. Reconcile1710 later via A1
against canonical publication evidence; no fabricated acceptance or republication.
Owner/accepted-state file SHA-256 unchanged. No production private/inactive-row
query was performed, so writer-ready is not proof of an all-new Production scope.

181 ingestion baseline tests run once after inventory: PASS. Existing cumulative
summarize rerun: deterministic plans and unique planned upsert keys PASS. Snapshot
integrity/redaction and Owner iOS/accepted-state preservation PASS. No Flutter
code changed; no Flutter analyze/full UI run. Wiki/diff checks required at handoff.

Durable local artifacts are ignored, **not committed**:
`.local/materials-wave1/2026-09-27/` contains sitemap-inventory.csv (1676 rows),
wave1-inventory.csv (296), review-classification.csv, final-report.json, original
observations, baseline observations, scope-sanity samples, diagnostics and logs.
The existing `/tmp/legendstudy-wave1/` operator scripts/results are also retained.
This inventory is a snapshot, not an accepted-state store or a new pipeline.

**WIKI_LOCAL_UPDATED: YES; WIKI_COMMITTED: NO; WIKI_PUSHED: NO.**
Next: Owner/ChatGPT review → minimal existing writer/parser changes → focused
tests → exact Production delta/private-state check → Owner Production gate.
No commit/push at this inventory STOP, following the explicit final report gate.


## Wave1 writer/parser extension — 2026-09-27

**INVENTORY COMPLETE; WRITER/PARSER IMPLEMENTED / TESTED; PRODUCTION WAVE1
PUBLICATION NOT YET APPLIED / OWNER GATED.** Owner explicitly authorizes this code/
Wiki checkpoint commit/push; does not authorize Production writes. D-Day final
Owner device PASS remains closed; no Flutter/D-Day/Personalization implementation.

### Implemented scope

- Existing approved_scope permits exam plus exactly university_essay,
  study_material and education_column. Pilot C remains exam-only. assert_in_scope,
  resolve and final write-shape guard reject non-exam exam/occurrence/scoped-resource
  children; exam without its extension still fails. resolve uses optional exam;
  existing row emitter skips absent exam rows. UUIDs, inactive insert-only behavior,
  exact transaction/count gates, approval/project gates and Safe Open stay intact.
- Resource-kind unknown is advisory **only** for the3 supported non-exam types,
  stored as existing `other` with original label; attachment_none is advisory
  **only** for education_column. Other empty materials and unknown exam kinds
  remain held. No schema or content/resource taxonomy added.
- Parser accepts observed trailing MP3 controls, 홀/풀이 decorations, explicit
  underscore/hyphen/plus elective labels. Known formatting aliases map to existing
  Korean/math areas while raw occurrence labels stay distinct. Broad 탐구영역,
  combined electives and observed typos 생화과윤리/사회문화1 are recognized but
  remain subject_id=NULL with taxonomy-gap advisory; no speculative typo mapping.
- Parser/mapping versions advance to0.2.0 so changed rules are visible to delta.
  Existing accepted26 entries are NOT rewritten or mass-reobserved. Follow-up
  reconciliation must distinguish parser-version change from source change.
-52 identity-review source IDs/23 groups are an explicit committed **publication
  hold registry**, not parser post-ID exceptions. All52 fail normalization,
  controlled scope/resolve/final-write guards and isolated activation before a
  transaction. New cross-post merge candidates also become nonpublishable.
  No merge, canonical-target choice, deletion, acceptance or publication occurred.
- Repeated same-kind quarantine cases now aggregate all details under the existing
  deterministic post/kind ID. This avoids losing later generic-resource diagnostics
  to ON CONFLICT DO NOTHING. Single-case payload shape remains unchanged.

### Saved-snapshot before / after

No network crawl or attachment request. All296 saved in-scope observations reused;
27 published baseline posts excluded from new candidate IDs, including1710.

| New269 partition | Before | After |
|---|---:|---:|
|Existing writer ready|30|217|
|General writer gap|78|0|
|False-hold candidates|109|0|
|Frozen identity-review|52|52|

After ready217 =10 without advisory +207 advisory. Exam63, essay135, study14,
column5. No other held/unsupported/unknown-category records. These are **local
candidate counts, not Production insertion/activation counts**.

| Planned table | Rows if the exact scope is absent |
|---|---:|
|source_posts|217|
|content_items|217|
|exams|63|
|exam_subjects|1039|
|resources|3874|
|ingestion_quarantine|282 unique post/kind rows|

Updates0 by insert-only contract. Actual inserts/no-ops/inactive rows/collisions
are **UNKNOWN until private Production preflight**; never interpret them as0.
The217 list is the maximum local candidate scope, not permission for one bulk
transaction. Owner publication must use reviewed bounded batches and fresh source
validation under the existing live-source gate; no cached-sample write bypass added.

### Private Production preflight and1710

No private Supabase connector is available; existing CLI uses hidden DB-password
input and no DB credential/environment is configured here. No credential was
printed, searched in unrelated apps, or embedded. Public27 baseline is not proof
that candidate keys are absent from private/inactive canonical tables.

Prepared exact read-only SQL at:
`.local/materials-wave1/2026-09-27/implementation/private-preflight.sql`.
Run in the Owner's **LegendStudy stlhijzpjfgwwdgunlsd** SQL session. It starts a
READ ONLY transaction, inspects5692 planned canonical/quarantine keys against
existing IDs/natural keys/alternate identities, reports potential inserts/key
no-ops, inactive/active matches and collisions, then ROLLBACK. It also queries1710
canonical publication shape. **Prepared, not executed or DB-syntax-validated.**
Any collision, mixed existing/new batch, or unexpected delta requires STOP/review;
this artifact does not replace existing runtime preflight or authorize repair.

1710 remains active per prior public/Owner evidence and absent from accepted26.
No recrawl, republish or accepted write. Existing A1 entry construction needs the
real observation body fingerprint/length as well as projection/resources. The
saved redacted snapshot deliberately has body_excerpt=None, so substituting an
empty body would fabricate evidence. The prepared canonical SELECT is a first
step, not a complete A1 acceptance package. Once a complete trusted original
observation is available, use existing bootstrap_accepted_state scoped only to1710,
review the proposed entry and merge with the preserved26; no executable state-write
command is approved from this incomplete snapshot. A fresh observation would need
separate Owner scope because this task forbids1710 recrawling.

### Validation and handoff

229 offline tests PASS:190 ingestion (181 existing +9 Wave1),10 controlled-scope,
9 general activation,12 Pilot C publication,4 subject recognition,4 recent delta.
Mixed exam/essay/study/parent-only exact rows, invalid cross-type children,
unsupported type, unknown exam safeguards, raw NULL mapping, all52 isolated holds,
zero-exam/occurrence activation, repeated advisory preservation and fake-DB rerun
no-ops covered. Saved full296 rerun deterministic; all canonical + quarantine IDs
unique; no signed resource URLs; Owner iOS and accepted-state hashes unchanged.
No actual Production idempotency/activation claim and no Flutter changes/analyze.

Committed review artifacts: `tool/ingestion/samples/wave1-identity-review.json`
and `wave1-publication-candidates.json`; no raw snapshot, credentials or signed
locators committed. Detailed redacted plans, summary and read-only SQL remain
under ignored `.local/materials-wave1/2026-09-27/implementation/`.
Next gate: Owner private read-only preflight results → review exact bounded delta
→ Owner Production publication approval. **No Production mutation in this task.**
