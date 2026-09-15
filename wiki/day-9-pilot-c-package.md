# Day 9-B2 — Production Pilot C apply package

Status: **prepared, NOT executed.** Nothing in this document has been run
against Supabase. `--apply` still refuses in code. Owner runs the steps below
in order and stops at the first mismatch.

Scope: **Pilot C — 2025–2026 exam posts, all grades.** 23 source posts.
Post ids (authoritative list, from `tool/ingestion/samples/pilot-c-2026-09-15/`):
1709, 1708, 1707, 1706, 1705, 1704, 1703, 1702, 1700, 1695, 1694, 1693, 1686,
1685, 1684, 1668, 1667, 1666, 1665, 1664, 1663, 1662, 1661.
Grades 고1 6 / 고2 6 / 고3 11; years 2025 15 / 2026 8; 수능 1, 모의평가 3, 학력평가 19.
Target project ref `stlhijzpjfgwwdgunlsd` (LegendStudy). Never Muselry.

## Expected rows

Measured from the dry-run, not estimated.

| table | delta | note |
|---|---|---|
| `subjects` | **+23** | taxonomy v1 seed, `is_active=true` |
| `source_posts` | **+23** | private provenance |
| `content_items` | **+23** | all `exam`, `is_active=false` |
| `exams` | **+23** | shared PK with `content_items` |
| `exam_subjects` | **+363** | all `provisional`, `is_active=false` |
| `resources` | **+739** | 360 `question` + 356 `answer_explanation` + 23 `listening_audio`, `is_active=false` |
| `ingestion_quarantine` | **+23** | advisory `resource_url_expiring`, one per post |

If the live dry-run in step 3 differs from these numbers, **stop and update the
expectation before applying** — do not reconcile afterwards.

## 1. Preflight (read-only SQL, Owner runs in the Supabase SQL editor)

```sql
-- 1a. Target project. Must print the LegendStudy database.
select current_database(), current_user, version();

-- 1b. Baseline row counts. Expected: all zero except quarantine, which may
--     hold earlier cases. Record the exact numbers before applying.
select 'source_posts' as t, count(*) from public.source_posts
union all select 'content_items', count(*) from public.content_items
union all select 'exams',         count(*) from public.exams
union all select 'subjects',      count(*) from public.subjects
union all select 'exam_subjects', count(*) from public.exam_subjects
union all select 'resources',     count(*) from public.resources
union all select 'ingestion_quarantine', count(*) from public.ingestion_quarantine
order by 1;

-- 1c. Reconfirm the "subjects is empty" finding that the seed assumes.
select count(*) as any_subject, count(*) filter (where taxonomy_version = 'v1') as v1
from public.subjects;

-- 1d. No verified mapping may exist that this run could disturb.
select count(*) as verified_occurrences
from public.exam_subjects where mapping_status = 'verified';

-- 1e. Collision check: none of the pilot's post ids may already exist.
select external_post_id from public.source_posts
where source = 'legendstudy' and external_post_id in (
  '1709','1708','1707','1706','1705','1704','1703','1702','1700','1695',
  '1694','1693','1686','1685','1684','1668','1667','1666','1665','1664',
  '1663','1662','1661');

-- 1f. Slugs must be free.
select slug from public.content_items
where slug like 'legendstudy-%-main'
  and slug in (select 'legendstudy-' || x || '-main' from unnest(array[
    '1709','1708','1707','1706','1705','1704','1703','1702','1700','1695',
    '1694','1693','1686','1685','1684','1668','1667','1666','1665','1664',
    '1663','1662','1661']) as x);

-- 1g. Constraints, policies and grants are the applied initial schema.
select conname, conrelid::regclass from pg_catalog.pg_constraint
where connamespace = 'public'::regnamespace
  and conrelid in ('public.subjects'::regclass, 'public.exam_subjects'::regclass,
                   'public.resources'::regclass) order by 2, 1;
select tablename, policyname, cmd, roles from pg_catalog.pg_policies
where schemaname = 'public'
  and tablename in ('subjects','exam_subjects','resources','content_items','exams')
order by 1, 2;
```

**STOP conditions:** 1b differs from the recorded Day 9-A baseline; 1c returns
any row; 1d returns anything other than 0; 1e or 1f returns any row; 1g shows a
constraint, policy or grant that is not the applied initial schema.

The post-id list in 1e/1f is the pilot scope and is reproduced from
`build/pilot-c/dryrun-posts.csv`; regenerate it from the live dry-run in step 3
before running these queries, because step 3 is the authoritative scope.

## 2. Live network smoke — Owner Mac PASS

Owner-reported result: sitemap 1,673 ids, newest `[1709, 1708, 1707]`; posts
1709–1705 PASS; final `5/5`, requests 6, retries 0, failures 0.

```
cd ~/development/legendstudy-app && python3 tool/ingest_legendstudy.py --network-smoke 5
```

Expected: `sitemap ok: 1673 post ids, newest [1709, 1708, 1707]` and five
`PASS` lines with non-zero attachment counts, ending `smoke: 5/5 posts parsed`.

Any `FETCH FAIL`, a post id count far from 1,673, or a `PASS` with zero
attachments on an exam post means the site changed — **do not apply.**

## 3. Live dry-run over the pilot scope

```
cd ~/development/legendstudy-app && python3 tool/ingest_legendstudy.py \
  --source network --pilot c --out build/pilot-c-live
```

The command fetches only the authoritative 23 ids listed above. It prints and
flushes sitemap and per-post fetch/done progress, including safe retry diagnostics,
so the current post remains visible during a timeout. One request has a 20-second
timeout and at most two retries; crawling stays serial at the 1.5-second minimum
interval. The 72-request run budget includes the maximum retry allowance.

Then diff against the committed offline artifact:

```
diff <(cut -d, -f1,4,6,7,8,9,10 build/pilot-c-live/dryrun-posts.csv) \
     <(cut -d, -f1,4,6,7,8,9,10 tool/ingestion/samples/pilot-c-2026-09-15/dryrun-posts.csv)
```

Compare, field by field: post count, title, category, attachment count,
`source_resource_key`, resource kind, exam mapping (year/month/grade/type),
subject mapping. The signed query is stripped before anything is written, so a
rotated `expires`/`signature` must **not** appear as a diff — if it does, the
stripping regressed and applying would persist an expiring credential.

**Any structural difference stops the apply.**

## 4. Subjects seed

```
psql "$LEGENDSTUDY_DB_URL" -f supabase/seed/subjects_taxonomy_v1.sql
```

or paste `supabase/seed/subjects_taxonomy_v1.sql` into the SQL editor. One
transaction, one `INSERT … ON CONFLICT (taxonomy_version, code) DO NOTHING`, no
`UPDATE`, no `DELETE`. Expected: 23 inserted, the trailing `select` returns 23.
Rerunning inserts 0 and edits nothing.

Verify:

```sql
select code, name, category, taxonomy_version, is_active, sort_order
from public.subjects where taxonomy_version = 'v1' order by sort_order;
```

## 5. Ingestion apply — IMPLEMENTED (Day 9-B3), not yet executed

`tool/ingestion/apply.py` now carries the write path. It is reached only when
every gate in `assert_apply_allowed` and `assert_in_scope` passes.

### Owner verification already completed

| step | result |
|---|---|
| Live network smoke | PASS, 5/5, requests 6, retries 0, failures 0 |
| Live Pilot C dry-run | PASS — 23 posts, 0 parse errors, 363 occurrences all provisional, 739 resources, 23 publish candidates, 0 blocking quarantine |
| Preflight 1–9 | PASS on PostgreSQL 17.6; all six content tables 0, 0 verified occurrences, 0 post-id and 0 slug collisions, constraints/RLS/grants as applied |
| Subjects taxonomy v1 seed | APPLIED — 23 rows, 23 active, 23 unique codes, 23 unique ids |

Current production baseline: `subjects = 23`, every other content table `0`.

### Design decisions taken against the schema

- **One transaction for all 23 posts, not one per post.** The earlier draft of
  this document suggested per-post transactions. For a bounded pilot that is
  the weaker choice: a failure at post 15 would commit 14 posts, the expected
  delta below would then fail against a partial database, and rollback would
  have to discover which posts landed. 1,148 rows is trivial for one
  transaction, and the inserted counts are compared to the expectation
  **inside** the transaction, before COMMIT. Per-post transactions remain the
  right shape for a long unattended crawl; this is not one.
- **Quarantine commits separately, after the pilot commits.** `ingestion.md`
  requires that a rollback of the normalized transaction cannot erase the
  evidence.
- **Deterministic ids.** Every id is `uuid5` over its canonical identity
  (`source_post:legendstudy:<id>`, `content_item:<slug>`,
  `exam_subject:<content_id>:<subject_key>`,
  `resource:<content_id>:<post_id>:<resource_key>`,
  `quarantine:<kind>:<post_id>`). A re-run produces the same ids, so
  `ON CONFLICT DO NOTHING` degenerates to a no-op, advisory quarantine rows
  cannot accumulate, and rollback can name an exact id set. `exams` reuses the
  content item id, which is its shared primary key. No schema change: all five
  ids are ordinary insertable columns.
- **INSERT-only, fail closed.** No `UPDATE` and no `DELETE` is issued
  anywhere — a test asserts the writer never emits either. A row that already
  exists is never rewritten, so a manual correction, an activated row and a
  `verified` mapping are all structurally safe. A *partial* pilot state stops
  the run rather than being "repaired" by an upsert.

### Runtime gates, in order

1. project ref equals `stlhijzpjfgwwdgunlsd` exactly — checked **before** a
   password is requested or a connection opened, so a Muselry run cannot reach
   the database;
2. `--i-have-owner-approval`;
3. `--source network`, so the plan comes from a live dry-run of the current
   site rather than a committed sample;
4. `--pilot c`;
5. `assert_in_scope` — year 2025–2026, `exam` only, publish candidates only, no
   `is_active=true` row, no `verified` mapping;
6. `assert_no_collisions` — duplicate upsert key at any of the five levels;
7. `assert_write_shape` and `assert_no_signing_material` — publication and
   mapping invariants, and no `credential=` / `signature=` / `expires=` in any
   stored locator;
8. live preflight — `subjects` v1 = 23, every mapped `subject_id` present in
   the v1 taxonomy, 0 verified occurrences on these content items, and the
   pilot either wholly absent (apply) or wholly present (no-op);
9. inserted counts equal the expectation, or the transaction rolls back.

### Write order

`source_posts` → `content_items` → `exams` → `exam_subjects` → `resources`,
then `ingestion_quarantine` in its own transaction. Conflict targets are the
schema's own uniqueness; no new identity was invented.

### The command

```
cd ~/development/legendstudy-app && python3 tool/ingest_legendstudy.py \
  --source network --pilot c --out build/pilot-c-apply \
  --apply --project-ref stlhijzpjfgwwdgunlsd --i-have-owner-approval
```

Requires `psycopg` (`python3 -m pip install -r tool/requirements-scoring-verifier.txt`).
The session pooler host is read from `config/development.json`
(`SUPABASE_SESSION_POOLER_HOST`), else `--db-host`, else prompted. The database
password is hidden terminal input and is never written to the repository, the
wiki, an artifact, stdout or shell history.

Read-only verification on its own:

```
python3 tool/ingest_legendstudy.py --postflight --project-ref stlhijzpjfgwwdgunlsd
```

## 6. Postflight (read-only SQL)

```sql
-- 6a. Deltas must equal the expectation table exactly.
select 'source_posts' as t, count(*) from public.source_posts where source='legendstudy'
union all select 'content_items', count(*) from public.content_items
         where slug like 'legendstudy-%-main'
union all select 'exams', count(*) from public.exams
union all select 'exam_subjects', count(*) from public.exam_subjects
union all select 'resources', count(*) from public.resources
order by 1;

-- 6b. Nothing is published yet.
select count(*) filter (where is_active) as active_content from public.content_items;
select count(*) filter (where is_active) as active_occurrences from public.exam_subjects;
select count(*) filter (where is_active) as active_resources from public.resources;
-- all three must be 0.

-- 6c. Mapping: 363 provisional, 0 verified, every pair valid.
select mapping_status, count(*), min(mapping_confidence), max(mapping_confidence)
from public.exam_subjects group by 1 order by 1;
select count(*) as broken_pairs from public.exam_subjects
where (subject_id is null) <> (taxonomy_version is null);

-- 6d. Duplicates must be zero at every upsert level.
select count(*) from (select source, external_post_id from public.source_posts
                      group by 1,2 having count(*) > 1) d;
select count(*) from (select content_item_id, source_subject_key from public.exam_subjects
                      group by 1,2 having count(*) > 1) d;
select count(*) from (select content_item_id, source_post_id, source_resource_key
                      from public.resources group by 1,2,3 having count(*) > 1) d;

-- 6e. sort_date is derived, never created_at or a UUID.
select year, exam_month, sort_date, grade_level, exam_type
from public.exams order by sort_date desc nulls last limit 10;

-- 6f. Resource aggregation per exam subject.
select r.resource_type, count(*) from public.resources r group by 1 order by 1;

-- 6g. No signing material was persisted anywhere.
select count(*) as signed_urls from public.resources
where source_url ilike '%credential=%' or source_url ilike '%signature=%'
   or source_url ilike '%expires=%';
-- must be 0.

-- 6h. Public projection still hides private columns: anon must see nothing yet.
set local role anon;
select count(*) from public.content_items;  -- 0 while is_active=false
reset role;
```

## 7. Publication gate — separate Owner approval

Ingestion success and public publication are separate. All pilot rows land
`is_active=false` and **the crawler never publishes**.

Before `is_active=true` may be set on `resources`, one UI change is required,
and it is the concrete form of the Owner's option (a):

> `ContentResource.openUri` currently falls back to `source_url` when
> `link_kind` is not `landing_page`. The 716 kakaocdn pilot resources have
> `link_kind='unknown'` and an unsigned locator, so today that button would
> open a 403 for those rows. 9-C must route `link_kind='unknown'` to
> the **content item's** `source_url` — the original legendstudy.com post —
> opened with the existing `ExternalLinkButton` /
> `LaunchMode.externalApplication` path.

The other 23 resources are stable Box landing pages classified as English
`listening_audio`; the existing `landing_page` open path is already correct.

`link_kind` is already in `SupabaseResourceRepository.projection`, and
`content_items.source_url` is already in `SupabaseContentRepository.projection`
and on `ContentItem.sourceUrl`. **No schema, projection or repository change is
needed** — only the open-target rule in the presentation layer.

Publication order once that lands: `content_items` → `exam_subjects` →
`resources`, so a child is never visible before its parent.

## 8. Search acceptance (after publication)

Against real pilot data, Guest and authenticated:

- 최신순 ordering across 2025–2026, `sort_date desc nulls last`
- 고1 / 고2 / 고3 filter → 6 / 6 / 11 posts respectively in the pilot
- 연도 필터: 2025 → 15 posts, 2026 → 8 posts
- 시험 필터: 수능 1, 모의평가 3, 학력평가 19
- 과목 필터: all 23 v1 names appear; 국어 returns the 화작/언매 papers too
- 문제 / 정답 / 해설 resource-kind queries; combined 정답,해설 must satisfy both
- a subject + kind query stays on the same occurrence
- Home query handoff into Materials
- empty / no-result / error states still reachable

Before publication, the same checks can be run privately with a service-role
SQL read; the public client must **not** be given a preview path.

## 9. Rollback / cleanup

Only rows this pilot created, identified by the 23 `external_post_id` values.
Existing production rows are never touched. All FKs are `ON DELETE RESTRICT`,
so the order is mandatory:

```sql
begin;
create temporary table pilot_posts as
select id from public.source_posts
where source = 'legendstudy' and external_post_id in ( /* the 23 ids */ );

delete from public.resources
where source_post_id in (select id from pilot_posts);
delete from public.exam_subjects
where content_item_id in (select id from public.content_items
                          where source_post_id in (select id from pilot_posts));
delete from public.exams
where content_item_id in (select id from public.content_items
                          where source_post_id in (select id from pilot_posts));
delete from public.content_items
where source_post_id in (select id from pilot_posts);
delete from public.ingestion_quarantine
where source_post_id in (select id from pilot_posts);
delete from public.source_posts where id in (select id from pilot_posts);
commit;
```

Because every id is deterministic, the same set can also be named directly by
`uuid5` without depending on `external_post_id` lookup; the query above is kept
because it is what the Owner can read and verify at a glance.

The `subjects` seed is **not** rolled back by this: taxonomy rows are a
released master, not pilot content, and removing them would break any mapping
that survived. If the taxonomy itself must be withdrawn, that is its own
reviewed step and requires `exam_subjects` to be unmapped first.

Personal tables (`profiles`, `bookmarks`, `recent_views`) are untouched by both
apply and rollback.

## What is still refused

- Executing `--apply` — the write path exists as of Day 9-B3 but has **not**
  been run against production; that is a separate Owner decision.
- Any migration or schema change — the pilot needs none.
- Supabase Storage mirroring — Owner deferred it pending a rights decision.
- The ~1,400 legacy posts — deferred.
- Publication — separate Owner approval after the 9-C open-target change.
