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

Initial credential check was incomplete: the installed Supabase CLI supports
`db query --linked --project-ref stlhijzpjfgwwdgunlsd --file ...` using existing
authentication. This private read path succeeded on2026-09-27; no new credential
requested, printed or saved. Legacy ingestion/verifiers prompt for passwords;
public runtime configs and client JWTs do not expose private canonical tables.

Prepared exact read-only SQL at:
`.local/materials-wave1/2026-09-27/implementation/private-preflight.sql`.
Run in the Owner's **LegendStudy stlhijzpjfgwwdgunlsd** SQL session. It starts a
READ ONLY transaction, inspects5692 planned canonical/quarantine keys against
existing IDs/natural keys/alternate identities, reports potential inserts/key
no-ops, inactive/active matches and collisions, then ROLLBACK. It also queries1710
canonical publication shape. **Executed successfully / read-only preflight PASS on2026-09-27.**
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
Next gate: review the private preflight results and exact bounded delta
→ Owner Production publication approval. **No Production mutation in this task.**


### Wave1 private Production preflight — 2026-09-27

Fetch confirmed local/origin `3b92439` on `codex/day-7-school-neis` before this
verification. Entire SQL and5692 payload keys were read and compared exactly to
saved217 resolved plans; frozen52 registry matches/exclusion PASS;1710 excluded.
BEGIN TRANSACTION READ ONLY / final ROLLBACK; no DML/DDL, CALL/DO/COPY, dynamic SQL
or side-effect functions. Production execution also confirmed SQL/schema validity.
SQL was minimally corrected to count any inactive match even alongside active
matches, return only parser/hash presence for1710, and combine both reports into
one JSON result (CLI returns the final SELECT result). Payload keys unchanged.

| Table | Planned | Potential inserts | Key no-ops | Collisions | Inactive | Active | Updates |
|---|---:|---:|---:|---:|---:|---:|---:|
| source_posts |217|217|0|0|0|0|0|
| content_items |217|217|0|0|0|0|0|
| exams |63|63|0|0|0|0|0|
| exam_subjects |1039|1039|0|0|0|0|0|
| resources |3874|3874|0|0|0|0|0|
| ingestion_quarantine |282|282|0|0|0|0|0|

Snapshot delta:5410 canonical +282 quarantine =5692 potential insert rows across
217 posts; no existing keys, collisions or unexpected inactive matches. Active
flags are not applicable to source_posts/exams/quarantine; zero means no match,
not an assertion that those tables have is_active. This is a key preflight, not
proof of full-row equivalence or authorization to write. Recheck at publication.

1710 canonical ID `c968af3c-768c-5a0f-8eed-c14a9e83322c`: parser_version and
content_hash present, active=true, exams1, occurrences33, resources67.
A1 remains NOT READY: original observation body fingerprint/length missing from
redacted snapshot. No recrawl, republish or accepted-state change.

Recommended publication after Owner approval: first4 posts covering each supported
content type, then at most20 posts /500 resources per reviewed batch; keep each
post atomic, isolate a larger post for review. Before each batch use existing fresh
source validation and private preflight; apply inactive, verify exact counts and
relationships, then separately approve activation and verify app visibility.
Stop on collisions, unexpected existing/inactive rows or changed source/delta.
The217 candidates are the upper scope, never blanket publication permission.
No Production content/schema mutation or activation. CLI emitted its standard
“Initialising login role” authentication message; this is not publication evidence.
Owner iOS files and accepted-state hashes unchanged; untracked files preserved.


## Wave1 Production publication pilot — 2026-09-27

Owner explicitly approved exactly one post per supported type, existing controlled
apply/activation only, then STOP. Starting local/origin HEAD3b92439. No app/parser/
writer/schema changes; Owner and concurrent personalization work preserved.

| ID | Type | Original published_at (KST) | Short title | Resources | Exam/occurrences | Advisory quarantine |
|---|---|---|---|---:|---|---|
|1474|exam|2020-12-13 00:17:00|2020 고3 3월 국영수 모의고사|10|1/4|none|
|1593|university_essay|2023-11-21 17:27:28|부산대 2024 논술가이드북|1|0/0|resource_kind_unknown, resource_url_expiring|
|1527|study_material|2023-09-11 12:38:24|영어 문장 넣기 유형문제|2|0/0|resource_kind_unknown, resource_url_expiring|
|1478|education_column|2021-04-13 10:52:10|2021 모의고사 일정|0|0/0|attachment_none|

Selected simple, small representative structures from217 ready; frozen52 and1710
excluded. Four live source observations matched saved canonical plans exactly;
all publishable, existing type-specific advisory policy PASS. No full inventory
or217-post preflight rerun. Scoped private preflight planned=potential inserts:
source4/content4/exam1/occurrence4/resources13/quarantine5; no-ops0/collisions0/
existing inactive0/active0/planned updates0.229 existing/focused regressions PASS.

Reused CLI authenticated temporary login credentials in process memory only,
with its existing postgres role membership, through existing PsycopgSession.
Initial default-role SELECT was refused; no write occurred before role selection
and successful preflight. No credential printed or persisted. The local operator
calls existing assert_apply_allowed/scope gates, apply_pilot, apply_quarantine,
and publish_scope; no alternate writer, hand-written mutation SQL or schema change.
Each post ran sequentially: atomic canonical insert → separate advisory transaction
(existing contract) → exact inactive read-back → scoped activation → exact active
read-back. Failure stops further posts; no force/repair path was used.

Actual inserts: source_posts4, content_items4, exams1, exam_subjects4, resources13,
ingestion_quarantine5 = **31 total**. Activation: content4/occurrences4/resources13.
All projected canonical columns, deterministic IDs, source/resource relationships,
original dates/types and active flags matched the live plans. General materials
have zero exam/occurrence children; exam invariants preserved. Duplicate/mismatch0.
Before/after count+row-digest comparison of all six canonical/quarantine tables
outside the four-post scope was unchanged; no unrelated data mutation.

Anonymous Production REST checks reused actual App repository projections/joins/
filters for each search branch, detail and resource list: all4 PASS,13 resources
visible with preserved unsigned source locator/null unverified file_url contract.
Recent query uses published_at DESC,id DESC; active31, first1712→1711→1710 unchanged.
Historical pilot dates remain original; apply time does not promote Recent Updates.
These are App-equivalent backend read-path checks, not a Flutter/device run.
Subsequent Owner acceptance: **MATERIALS_WAVE1_PILOT_OWNER_DEVICE: PASS**.
iPhone exam detail/subject grouping, essay/study detail, attachment-free column,
PDF direct-open PASS; existing Home/D-Day normal, no evident Materials read-path
regression. Pilot cycle COMPLETE. Separate logged-in Home school-setting error is
[an open school bug](day-7-neis.md#home-school-setting-error--2026-09-27), not an
established Materials regression; no diagnosis/fix attempted here.

Accepted state remains26 unchanged; no accepted mutation required for this pilot.
1710 remains active and separately A1-pending (trusted body fingerprint/length
missing); no recrawl, republish or fabricated evidence. No auto acceptance claim.

Remaining **213**: exam62, essay134, study13, column4; identity-review52 still HOLD.
Remaining planned rows: source213/content213/exam62/occurrence1035/resource3861/
quarantine277 =5384 canonical +277 quarantine =5661 total (recheck before apply).
Recommend first next batch of small essay/study posts, then exam batches; each
must stop at20 posts or500 resources, whichever comes first, and never split a
post. Preserve per-post gates and stop on failure/source drift/unexpected state.
**No next batch executed: Owner/ChatGPT approval required. Pilot complete, STOP.**

Local ignored evidence: `.local/materials-wave1/2026-09-27/pilot/` contains selection,
redacted live resolved rows, scoped SQL/results, publication journal, App read report
and operator scripts. No secrets/signed locators or raw HTML committed.


## Wave1 next bounded batch preparation — 2026-09-27

READ-ONLY PREFLIGHT COMPLETE / APPLY AND ACTIVATION NOT AUTHORIZED.
Start local/origin94ab582. Reused saved observations and existing normalizer,
writer scope/invariants and private preflight; no inventory/network recrawl or code
change. Selection prioritizes high confidence, clear structures and few advisories;
four English study collections avoid broad exam-like general collections for this
batch. Each post remains whole. All20 high/publishable, no blockers.

| Type | Exact post IDs | Posts | Resources |
|---|---|---:|---:|
|exam|1447,1432,1453,1492,1493|5|128|
|university_essay|1645,1541,1542,1557,1560,1626,1642|7|20|
|study_material|1519,1521,1522,1518|4|9|
|education_column|1491,1575,1613,1701|4|0|

Limits:20 posts /157 resources (maximum20/500). All27 baseline and4 Pilot posts,
1710 and frozen52 excluded. Planned rows = potential inserts: source_posts20,
content_items20, exams5, exam_subjects60, resources157, ingestion_quarantine21;
**total283**. All six tables: key no-ops0, collisions0, existing inactive0,
existing active0, planned updates0. Existing linked CLI authentication reused;
connection transaction_read_only=on confirmed and SQL BEGIN READ ONLY/ROLLBACK.

Advisories: resource_url_expiring on9 posts, resource_kind_unknown plus expiring
on4 study posts, attachment_none on4 columns; first3 exams have none. They are
allowed by the existing content-type policy, retained as21 grouped quarantine
rows; no ignored blocker or forced taxonomy mapping. Non-exams have no exam/
occurrence children; exam invariants and unsigned attachment identity contract PASS.

Saved-observation deterministic rerun, exact canonical comparison, all source/
resource natural keys, UUID uniqueness and slug uniqueness PASS. Scoped DB lookup
confirms no live key/slug collision. Pilot31 rows exact-match their published
plans. Six canonical/quarantine tables' before/after row digests unchanged,
including1710; its active/exam1/occurrences33/resources67 evidence still matches.
229 ingestion/controlled writer/activation/bootstrap/idempotency regressions PASS.
Owner iOS and accepted-state hashes unchanged; no school fix/Flutter build.

Remaining writer-ready stays213 until publication;52 HOLD and1710 A1 remain pending.
Local ignored evidence: `.local/materials-wave1/2026-09-27/batch-01/` selection,
scoped SQL/results and summary. Cached preparation is not the live-source apply
gate: after explicit Owner approval, validate only this exact set live and repeat
scoped preflight; STOP on drift/unexpected state. **Production mutation NO.**
Next: Owner/ChatGPT approval → bounded Production apply + activation.


## Wave1 bounded batch 1 Production closeout — 2026-09-27

Owner approved exactly the20 IDs in the preparation table above; no added posts.
Starting local/origin130c241, branch codex/day-7-school-neis. Concurrent independent
personalization commit bf6fdc0 was preserved; this task changes no app/ingestion/
school/schema code and does not deploy its migration.

All20 source pages re-observed just before apply; source identity/type/title/dates,
canonical children, unsigned attachments and grouped advisories matched the saved
plans exactly. High/publishable, no blockers; deterministic rerun PASS. Scoped
READ ONLY preflight repeated: potential inserts283, key no-ops/collisions/existing
inactive/active/planned updates all0. Frozen52,1710 and Pilot4 excluded.

Existing apply_pilot/apply_quarantine/publish_scope functions ran sequentially per
post, preserving atomic canonical writes and separate advisory transaction.
Actual inserts: **source_posts20/content_items20/exams5/exam_subjects60/resources157/
ingestion_quarantine21 =283**. Activation: content20/occurrences60/resources157.
Every post had exact inactive and active read-back of all projected columns,
keys/linkages/type/original published_at. All15 non-exams have no exam/occurrence
children;5 exam invariants PASS. Duplicates0, unexpected inactive0. Outside-scope
six-table counts and complete row digests remained unchanged after every post;
no unrelated canonical mutation, including Pilot and1710.

Guest Production queries matching App projections, exam/non-exam search joins,
keyword search, detail, subject/resource embeddings PASS for all20. Resource URL
contract PASS: unsigned source identity retained, unverified file_url remains NULL;
this task does not claim20-post device PDF opening. Active contents51; recent
published_at DESC,id DESC still starts1712→1711→1710. Historical dates unchanged.
Pilot4 exact31-row regression and guest read-path checks PASS; prior Owner device
PASS remains recorded. No new school/Home bug fix or unrelated feature work.

229 ingestion/controlled writer/activation/bootstrap/idempotency regressions PASS;
Owner iOS and accepted-state hashes unchanged. Accepted26 untouched;1710 A1 pending.
Remaining **193**: exam57, university_essay127, study_material9, education_column0.
Identity-review52 still HOLD. No next batch selected or published. **STOP: a new
Owner/ChatGPT gate is required before next batch selection/apply/activation.**
Local ignored batch-01 evidence now includes live validation/plans, repeated scoped
preflight, per-post publication/exact journal, unrelated preservation and guest
read reports. No credentials or local artifacts committed.
