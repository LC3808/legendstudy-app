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

Next implementation task is **A1 only: accepted-state bootstrap/reconciliation**.

Do not combine A1 with scheduler, broad Phase-2 automation, 2020 backfill, Essay
schema, Mock scoring, Admissions, or UI polish.

After A1 passes, proceed A2 then A3. Only then begin Wave-1 backfill dry-run.

Codex resource status at planning time is low; implementation may wait for reset.
Luna/other lower-cost work may inspect/read/prepare fixtures, but a partial
implementation should not be started merely to consume remaining quota.


## Recent publication ordering and 1710 HOLD — 2026-09-26

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
