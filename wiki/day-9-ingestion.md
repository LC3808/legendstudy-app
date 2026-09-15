# Day 9-B — legendstudy.com Ingestion

Status: **design + implementation + dry-run COMPLETE. No production write.**
Day 9-B stops at the Production gate below. `--apply` is implemented as a
refusal and has no write path.

## Baseline

Started 2026-09-15 on `codex/day-7-school-neis`, HEAD `f664c79`, no tracked
changes. Pre-existing untracked `Claude outputs/`, `supabase/.temp/`,
`tool/__pycache__/` preserved. Local repository, `wiki/` and the applied
migrations are canonical; GitHub `origin/main` is not consulted.

Read before implementing: `AGENTS.md`, `wiki/index.md`, `current-status.md`,
`log.md`, `ingestion.md`, `database.md`, `architecture.md`,
`day-9-search-explore.md`, `supabase/migrations/20260912000100_initial_content_schema.sql`
and the Day 9-A search/resource repositories. The identity, quarantine and
soft-state contracts in `ingestion.md` are followed, not re-invented.

## Site survey — 2026-09-15

`sitemap.xml` is complete and is the canonical post enumeration: 1,720 `<loc>`
entries, of which **1,673 are numeric post URLs** (id 2 … 1709, with gaps; id
1520 returns 404) and 42 are category pages. The 1,673 figure in
`ingestion.md` is therefore revalidated, not merely inherited.

`robots.txt` (`User-agent: *`) disallows `/guestbook`, `/m/guestbook`,
`/manage`, `/owner`, `/admin`, `/search`, `/m/search`. Numeric post paths and
`/sitemap.xml` are allowed. A `Crawl-delay: 20` exists only for `bingbot`; no
directive targets `*`, so the crawler applies its own 1.5 s serial default.

227 posts in the modern id range 1481–1709 were surveyed in full, plus
stratified probes at 1475, 1470, 1460, 1450, 1430, 1400, 1350, 1250, 1150,
1100, 1000, 900, 800, 700, 600, 500, 400, 300, 200, 100, 50. Attachment link
text, href, metadata and category path were read; no attachment bytes were
downloaded.

### Post identity

`article:txid` is `780233_1705`; `article:pc_view_url` is
`https://coroico.tistory.com/1705`. The numeric Tistory post id is present in
the URL, the canonical link, `og:url`, the mobile URL and txid, and is used as
`source_posts.external_post_id`. URL is location only, exactly as
`ingestion.md` requires. `normalize_post_url` folds `/1705/`, `/m/1705`,
`www.` and the `coroico.tistory.com` origin onto `https://legendstudy.com/1705`.

`article:published_time` and `article:modified_time` are present on every
sampled post. Publication time is **not** the exam date: post 1705 covers a
2026-05 sitting and was published 2026-07-24.

### Post patterns

| Pattern | Description | Example |
|---|---|---|
| A — modern exam | one post = one sitting, every subject, `figure.fileblock` attachments | 1705, 1706, 1708 |
| B — modern essay | 논술 by university/year, no exam extension | 1699, 1612, 1610 |
| C — column | schedule/admissions article, zero attachments | 1701, 1613, 1491 |
| D — legacy exam | plain `<a>` to `t1.daumcdn.net/cfile/tistory/{ID}` | 1475 and below |
| E — split legacy exam | 국영수 and 사탐/과탐 in separate posts | 1470, 1450, 500 |

The boundary between C/D generations is sharp: **every sampled post with id
≥ 1481 uses `blog.kakaocdn.net` and none uses cfile; every sampled post with
id ≤ 1475 uses cfile and none uses kakaocdn.** Post 1478 (a schedule column)
sits between them with no attachment.

### Attachment URL stability — the central finding

Modern attachments render as:

```
https://blog.kakaocdn.net/dna/{s1}/{s2}/{s3}/{filename}
    ?credential=…&expires=1790780399&allow_ip=&allow_referer=
    &signature=…&attach=1&knm=tfile.pdf
```

Measured 2026-09-15:

- the path (`{s1}/{s2}/{s3}/{filename}`) is **identical** across a rendered
  page and an independent no-store refetch;
- `credential` and `expires` are **identical across different posts**
  (1500, 1620, 1706 all carried `expires=1790780399`), i.e. a single
  site-wide rolling signing window, expiring 2026-10-01 00:00 KST;
- loading the **unsigned path** fails; loading the path with an **expired
  `expires`** fails; `credential` alone fails. Only the current full signature
  loads. (Verified with a same-scheme image asset from post 1705, where load
  success is observable.)
- the page's own embedded JSON exposes the Tistory file identity as
  `kage@{s1}/{s2}/{s3}`, confirming `{s1}/{s2}` as a provider-issued id.

Legacy `https://t1.daumcdn.net/cfile/tistory/{HEXID}` URLs carry **no query at
all** and load unsigned.

Consequences, and they are not symmetric with expectation:

- the **recent** material the product cares about most has the **unstable**
  locator; the **legacy** archive has the stable one;
- `ingestion.md` forbids persisting expiring secrets in public URLs, so the
  signed query is stripped and never written anywhere — samples, artifacts and
  planned rows are asserted free of `credential=`, `signature=`, `expires=`;
- the stored `resources.source_url` for a modern attachment is the unsigned
  canonical path. It is a stable **identity and provenance locator, not a
  proven download link**, and is therefore recorded with
  `link_kind='unknown'`, `link_status='unchecked'`, `file_url=NULL`. See the
  Production gate.

### Supporting providers

`app.box.com/s/{id}` carries English listening audio (86 links across the 227
modern posts) and `drive.google.com` appears on some pre-2016 posts. Both are
landing pages, not proven media bytes, and are recorded with
`link_kind='landing_page'`. Every Tistory attachment observed in the modern
range is `.pdf`; no `.hwp`, `.hwpx` or `.zip` was observed there. Older posts
advertise hwp in their titles (e.g. post 800) and are out of pilot scope.

### Modern-range inventory (id 1481–1709, 227 posts)

| Category | Posts | Tistory attachments |
|---|---|---|
| 논술 기출 자료 | 134 | 1,635 |
| "고3"을 위한 공간 | 38 | — |
| "고1"을 위한 공간 | 22 | — |
| "고2"를 위한 공간 | 21 | — |
| 수업 자료실 | 8 | — |
| 교육 입시 관련 소식 | 4 | 0 |
| **exam-category subtotal** | **81** | **2,620** |
| **total** | **227** | **4,280** |

86 Box links; 0 Google Drive; 0 cfile; all extensions `pdf`.

## Parsing contracts

### Exam identity comes from title and category only

Attachment filename prefixes carry at least five generations
(`2026년 5월 고3_`, `2024_5월_`, `25학년도 9월 모평_`, `2023년 고2 3월_`,
`2021-4월-`), so they are never an identity source. Filenames supply subject
and resource kind only.

- `[YYYY년 M월 시행]` / `(YYYY년 M월 시행)` gives the administered year/month.
- The nominal month is the `M월` a student would search for. Post 1513 is
  titled `(2023년 5월 시행) 2023년 4월 고3 모의고사`: `exam_month = 4`, and the
  administered-month difference is recorded in `exams.normalization_note`.
  `exam_date` is never inferred; only `sort_date` derives from year + month.
- Grade comes from `고N` in the title, else from the category
  (`"고N"을 위한 공간`, `N학년 …`).
- Exam type is matched longest-first so `모의평가`/`모평` wins over the generic
  `모의고사`: 수능→`csat`, 모의평가/모평→`evaluation_mock`,
  전국연합학력평가/학력평가/학평/모의고사→`national_mock`.

### calendar year vs academic year

`academic_year` is only taken from the source for `csat` and
`evaluation_mock`, and only when it equals the sitting year or the next one;
anything else quarantines as `exam_academic_year_conflict`.

For 교육청 학력평가 the site writes the **calendar** year as `N학년도`. Post 1705
is titled `[2026년 5월 시행] 2026년 5월 고3 모의고사` while its own body heading
reads `2026학년도 고3 전국연합학력평가` for a cohort whose 수능 is 2027학년도.
`national_mock` therefore never takes the source label; `academic_year` stays
NULL and the rejected label is recorded in `normalization_note`. This matches
`ingestion.md` ("Distinguish calendar year/academic year/nominal month;
bound-check known values rather than inventing facts").

### Subject

`subjects` is empty in production, so every occurrence is created
`mapping_status='unmapped'` with `subject_id`, `taxonomy_version`,
`mapping_confidence` and `verified_at` all NULL — the shape the
`exam_subjects_mapping_state` CHECK requires — and the raw label preserved.
No taxonomy row is invented and no verified row is ever touched.

`source_subject_key` is the raw subject token exactly as the source writes it
(`국어(언매)`, `물리학1`, `통합사회`). The column only requires a non-blank
value, so no transliteration or hashing is introduced; the key is
evidence-backed and deterministic across reruns, and never derives from array
index, display order or title hash.

Matching is longest-token-first across the modern and historical vocabularies
at once, **and** requires a word boundary:

- longest-first stops `한국사` being read as the historical `국사`, and
  `한국근현대사` being read as `한국사`; likewise 세계사/세계지리,
  사회문화/통합사회, 경제/경제지리;
- the boundary rule rejects a token that starts inside a longer Hangul word.
  The source typo `생화활과윤리` ends with the historical subject `윤리`; without
  the rule it silently became a 윤리 occurrence on a 2025 모의평가.

Historical labels (`수학 가형/나형`, `국사`, `한국근현대사`, `법과사회`,
`경제지리`, `윤리`, `물리1`, `생물1`) are flagged and annotated, never mapped to
a modern elective.

Group prefixes `사회탐구_`, `과학탐구_`, `사탐_`, `과탐_`, `사_`, `과_` are stripped
before matching. 고1/고2 combined papers use the group name as the subject
(`통합사회`, `통합과학`, `사회`, `과학`, `사회탐구`, `과학탐구`) and 고2 papers drop
the elective number (`물리학`, `화학`).

### Resource kind

Observed across all 2,620 modern exam attachments: `문제` 1,302,
`정답,해설` 1,284, `듣기대본` 30, `대본` 2, `정답해설` 1, and one malformed
`…모의평가-국어-문제`. Mapping is longest-first so `정답,해설` is not read as
`해설`:

| source tail | resource_type |
|---|---|
| 문제 | `question` |
| 정답,해설 / 정답해설 / 정답 및 해설 / 해설,답안 | `answer_explanation` |
| 정답 | `answer` |
| 해설 | `explanation` |
| 듣기대본 / 대본 | `listening_script` |
| 듣기파일 | `listening_audio` |
| 예시답안 / 모범답안 / 우수답안 / 답안 | `answer` |
| 채점기준 / 출제의도 | `reference` |
| 등급컷 | `grade_cut` |

`answer` and `explanation` are **not** synthesised as separate rows when the
source ships one combined file; `answer_explanation` exists in the schema for
exactly this. 등급컷 is published as body text on modern exam posts, not as an
attachment, so no `grade_cut` resource is produced there.

### Administering organisation

`exams` has no organisation column and none is added. The evidence is also
unreliable: post 1705's body says `경기도교육청`, while the same page's tag list
says `인천광역시교육청`. Organisation is therefore **not populated**; observed
candidates stay in private `source_posts.raw_metadata`. Recorded as a LATER
gap below.

### Identity, reruns and soft state

Upsert targets follow `ingestion.md` unchanged:

| table | conflict target |
|---|---|
| `source_posts` | `(source, external_post_id)` |
| `content_items` | `(source_post_id, source_content_key)` |
| `exams` | `(content_item_id)` — shared PK, no separate exam id |
| `exam_subjects` | `(content_item_id, source_subject_key)` |
| `resources` | `(content_item_id, source_post_id, source_resource_key)` |

`source_content_key` is `main`; slug is `legendstudy-{external_post_id}-main`,
consistent with the existing `legendstudy-1705-main` example. Generated columns
(`exams.sort_date`, `exams.content_type`, `content_items.feed_updated_at`) are
never produced.

`source_resource_key` is the provider file identity: the kakaocdn `{s1}/{s2}`
pair, the cfile hex id, or `box:{share id}`. It is invariant under signature
rotation — the test mutates `expires` and `signature` and asserts the key and
the unsigned URL are unchanged.

Change detection is a sha256 over title, category, both source timestamps,
parser/mapping versions and the sorted `(provider, key, name, url)` tuples.
Reordered attachments do not change the digest; a corrected title or a newly
added answer file does. `last_crawled_at` records observation only and never
becomes a source modification time.

A source absent from a run is recorded as `source_missing` quarantine for
review. Nothing is hard-deleted and nothing is unpublished automatically.
Posts whose canonical exam identity `(year, month, grade, exam_type)`
collides are emitted as `merge_candidate_exam` for human review; no automatic
merge is performed.

## Quarantine

Codes are deterministic and stored in `ingestion_quarantine.kind`, which only
requires a non-blank value — no schema change is needed. `payload` holds a
bounded JSON object, `status='open'`, matching the existing table.

Blocking (stops a publish candidate): `classification_missing_category`,
`classification_unknown_category`, `exam_year_unknown`, `exam_month_unknown`,
`exam_grade_unknown`, `exam_type_unknown`, `exam_academic_year_conflict`,
`resource_identity_missing`, `resource_identity_duplicate`, `source_missing`.

Non-blocking: `resource_kind_unknown`, `resource_subject_unknown`,
`attachment_none`, `merge_candidate_exam`.

Advisory: `resource_url_expiring` — a uniform, documented property of the
source, recorded once per post with a count. It is deliberately excluded from
per-post confidence so that confidence measures parse quality, and is escalated
to a single production gate instead.

Confidence is `high` when classification and (for exams) year, month, grade and
type are all determined and no non-advisory case is open; `medium` when only
non-blocking cases are open; `low` otherwise. Confidence is never exposed to
the public client — the initial migration's column grants on `exam_subjects`
already exclude `mapping_confidence`, `mapping_note` and `verified_at`.

## Code

```
tool/ingestion/__init__.py     parser + mapping versions, source constants
tool/ingestion/models.py       RawAttachment / RawPost / QuarantineCase / PlannedPost
tool/ingestion/taxonomy.py     observed subject, kind, category, exam-type vocabularies
tool/ingestion/parser.py       HTML + sample record -> raw facts; title/filename parsing
tool/ingestion/normalizer.py   raw facts -> canonical rows, quarantine, confidence
tool/ingestion/crawler.py      robots policy, polite fetcher, sitemap, sample source
tool/ingestion/pipeline.py     aggregation, change detection, merge candidates
tool/ingestion/writer.py       upsert order + apply gate (always refuses)
tool/ingest_legendstudy.py     CLI, dry-run by default
tool/test_ingestion.py         65 offline tests
tool/ingestion/samples/        extracted survey records (no HTML, no body text)
```

Standard library only; no new dependency. Style follows the existing
`tool/verify_*.py` scripts (unittest, urllib, dataclasses, type hints).

The fetcher is serial with a 1.5 s minimum interval, a 20 s timeout, at most
two retries with exponential backoff, an optional per-run request budget, and
a robots check that refuses a disallowed path **before** issuing a request.
Failures are typed: transport (`FetchError`, transient or not) is skipped and
counted; a parser invariant failure is captured per post in `parse_errors` and
never silently swallowed.

### CLI

```
python3 tool/ingest_legendstudy.py                     # offline dry-run (default)
python3 tool/ingest_legendstudy.py --source network    # live dry-run
python3 tool/ingest_legendstudy.py --network-smoke 3   # structure check
python3 tool/ingest_legendstudy.py --survey <index>    # title coverage
python3 tool/ingest_legendstudy.py --apply …           # always refused
```

`--apply` refuses three ways: a target project ref other than
`stlhijzpjfgwwdgunlsd` is named and rejected first, then the missing
`--i-have-owner-approval`, then the Day 9-B gate itself. There is no code path
that writes. Naming the project ref first is what structurally prevents a
Muselry-project mistake.

## Dry-run — 2026-09-15

Two runs, both offline over the committed extraction of 38 real exam posts
(ids 1614–1709, published 2024-03 … 2026-08) carrying 1,205 real attachments.

| | |
|---|---|
| posts parsed | 38 |
| parse errors | 0 |
| content_items | 38 (all `exam`) |
| exams | 38 |
| exam_subjects | 609 across 36 distinct subject keys |
| resources | 1,205 |
| resource types | question 601, answer_explanation 594, listening_script 10 |
| link kinds | unknown 1,205 (all kakaocdn) |
| confidence | high 35, medium 3 |
| publish candidates | 35 / 38 (92.1 %) |
| blocking quarantine | **0 posts** |
| open quarantine | 3 `resource_subject_unknown` + 38 advisory `resource_url_expiring` |
| merge candidates | 0 |

Distribution: grade 1/2/3 = 10/10/18; year 2024/2025/2026 = 15/15/8; type
national_mock 31 / evaluation_mock 5 / csat 2; months 3,5,6,7,9,10,11.
`academic_year` was set on exactly 7 posts — the 2 수능 and 5 모의평가 — and 2
national_mock posts carry the "source academic label not trusted" note.
Attachments per post: min 10, median 35, max 49.

Re-running against the written state file produced `changed=0, unchanged=38`
and a byte-identical `dryrun-posts.csv`.

### Schema conformance

Every planned row was checked against
`20260912000100_initial_content_schema.sql`: slug and `source_content_key`
regex, `content_type` / `exam_type` / `resource_type` / `link_kind` /
`link_status` domains, `year`/`academic_year` bounds, `exam_month` 1–12,
`grade_level` ∈ {1,2,3}, non-blank titles and keys, HTTP(S) URL shape,
non-negative `display_order`, and the `exam_subjects_mapping_state` CHECK.

**38 content_items, 38 exams, 609 exam_subjects, 1,205 resources: zero
violations.** Upsert keys are unique at every level, and all 1,205
`source_resource_key` values are distinct across posts.

### What actually failed, and why

The only three parse failures in 1,205 attachments are **typos on the source
site**, and all three are quarantined rather than guessed:

| file | problem |
|---|---|
| `2025학년도 수능_수학(미정) 정답,해설.pdf` | `(미정)` should be `(미적)` |
| `2024년 10월 사탐_사회문화1 문제.pdf` | `사회문화` has no elective number |
| `2025학년도 6월 s_생화활과윤리 정답,해설.pdf` | `생화활과윤리` should be `생활과윤리` |

The third is the case that motivated the word-boundary rule. Correcting a
source typo is a human decision, so the resource is still ingested and simply
carries no occurrence scope until review.

Two further known data facts, neither of which is a parser defect: post 1705
publishes `국어(언매) 정답,해설` with no matching `국어(언매) 문제`, and subject
coverage is uneven across posts (사회문화 26 occurrences vs 세계지리 25 in the
sample). Resource sets are not assumed to be uniform 문제/정답 pairs.

### Survey coverage

`--survey` over all 227 modern posts: 81 fall in an exam category and **81/81
(100 %) yield a complete exam identity** — calendar year, month, grade and
type — from the title alone (national_mock 65, evaluation_mock 11, csat 5).
The remaining 146 are 논술 / column / 수업 자료실 posts whose classification comes
from the category path.

### Network smoke

`--network-smoke` is implemented and reports cleanly, but **could not be
executed in this session**: outbound access to `legendstudy.com` is denied by
the environment's egress policy from both available shells (`curl` returns
`403 from proxy after CONNECT`; the CLI reports
`SMOKE FAIL sitemap: … URLError` without crashing). The site survey above was
therefore performed through the approved browser surface, and every structural
fact in this document comes from a real page read, not from the crawler code.

The network smoke must be run once on a machine with egress before any
production apply — see the Codex handoff.

## Day 9-A search compatibility

Checked against `lib/features/materials/data/supabase_search_repository.dart`
and `day-9-search-explore.md`. Every field the search path reads is supplied:

| search need | supplied by |
|---|---|
| `exams.year` / `exam_month` / `grade_level` / `exam_type` | parsed from title + category; 100 % complete on the surveyed exam posts |
| `exams.sort_date` | generated from `year` + `exam_month`; never `created_at`, never a UUID |
| `content_items.is_active` / `content_type` / `title` / `summary` | set; `is_active=false` until reviewed |
| `content_items.feed_updated_at` | generated from the source publication/update times written here |
| `exam_subjects.id` / `display_order` / `is_active` | per-occurrence, deterministic order |
| `resources.resource_type` / `display_order` / `is_active` | per-attachment |
| grouping 문제 / 정답 / 해설 under one subject | `resources.exam_subject_id` scoped to the occurrence of the same content item |

Day 9-A's typed tokens line up with what is produced: a bare four-digit year
means **calendar** year, which is the value written to `exams.year`; `고1/2/3`
matches `grade_level`; `수능`→`csat`, `모의평가`→`evaluation_mock`,
`학력평가`→`national_mock` match the values produced here; 문제/정답/해설 match
`question` / `answer`+`answer_explanation` / `explanation`+`answer_explanation`.
Because the source ships combined 정답,해설 files, a `정답` query and a `해설`
query both correctly return them.

One gap: `subjects` is empty, so `exam_subjects.subject_id` is NULL on every
row. Search still renders the group using the public raw occurrence label
(explicitly supported in `day-9-search-explore.md`), but the 과목 filter and
the exact-subject-name path have nothing to resolve against. See SHOULD below.

## Day 9-C readiness

Day 9-C needs stable `contentItemId`, `examSubjectId`, `resourceId`, resource
kind and a safe source URL. The first four are provided and stable across
reruns. The fifth is the open question: a modern `resources.source_url` is an
identity locator, not a verified download. `link_kind='unknown'` and
`link_status='unchecked'` already say so, and the public grants do not expose
`link_status`, so the client cannot claim availability it has not verified —
consistent with Day 9-A's "첨부 종류는 등록 정보 기준" wording. 9-C must settle
the fetch/redirect story before adding a viewer.

## DB gaps

### BLOCKER — must be resolved before publishing modern resources

1. **Modern attachment locators expire.** Every `blog.kakaocdn.net` URL needs
   the site-wide rolling signature, which cannot be stored (policy) and would
   break on 2026-10-01 anyway (fact). Ingesting the metadata is safe today;
   **publishing those resources as if they were openable is not.** This needs
   an Owner decision, not a schema change. Options, with no implementation
   started:
   - **(a) publish metadata, open the source post.** Keep the unsigned path as
     identity; the app opens `https://legendstudy.com/{id}` for the actual
     download. No mirroring, correct attribution, works today. Recommended for
     the pilot.
   - **(b) controlled storage mirror.** Copy PDFs to Supabase Storage and set
     `file_url`. Best UX, but it is redistribution of third-party exam material
     and needs an explicit rights decision first (§45). Out of Day 9-B scope.
   - **(c) runtime re-resolution.** The app fetches the post page to obtain a
     fresh signature. Rejected: `AGENTS.md` §8 forbids runtime scraping.
2. Nothing else blocks. The applied schema expressed every row this pipeline
   produces with **zero violations**; no migration is required for the pilot.

### SHOULD

1. **Seed `subjects`.** 36 distinct raw subject keys already exist in a
   38-post sample. Without taxonomy rows the 과목 filter and facet list stay
   empty. A reviewed `taxonomy_version` seed plus a mapping pass would move
   occurrences `unmapped → provisional`. Needs its own migration and Owner
   approval; `mapping_status='verified'` rows must never be touched by
   automated ingestion.
2. **Deterministic quarantine code.** `ingestion_quarantine.kind` is free text
   and the pipeline writes fixed codes into it, which works. If reporting
   grows, a CHECK constraint or a lookup table would make the vocabulary
   enforceable. Not needed for the pilot.
3. **Query plans on real data.** Day 9-A recorded this; it can only be
   measured after a pilot populates rows.

### LATER

1. **Administering organisation** (`서울특별시교육청`, `한국교육과정평가원`, …). No
   column exists and the source evidence is self-contradictory. Revisit only
   with a reliable source field.
2. **Legacy generation (id ≤ 1475, roughly 1,400 posts).** The cfile locators
   are stable and unsigned, which makes them *easier* to publish than the
   modern ones, but the posts use 가형/나형 and pre-2014 subjects that the
   current taxonomy cannot express, and 국영수 / 사탐·과탐 are often split across
   posts, which needs the merge workflow.
3. **Listening audio and hwp/zip.** Box landing pages are recorded; playback,
   and the hwp/zip material advertised on pre-2016 posts, are separate work.
4. **`exam_date`.** Bodies sometimes state a day ("5월 7일에 … 주관"), but the
   same pages contradict themselves on organisation, so prose is not trusted.

## Production pilot proposal

Not to be executed in Day 9-B. Sizes below are measured from the dry-run, not
estimated.

| scope | posts | exams | exam_subjects | resources | quarantine | publishable |
|---|---|---|---|---|---|---|
| A. 2026 고3 only | 4 | 4 | 93 | 177 | 0 | 4 / 4 |
| B. 2026, all grades | 8 | 8 | 117 | 224 | 0 | 8 / 8 |
| **C. 2025–2026, all grades (recommended)** | **23** | **23** | **363** | **716** | **0** | **23 / 23** |
| D. 2024–2026 (the whole dry-run set) | 38 | 38 | 609 | 1,205 | 3 | 35 / 38 |

Plus 23 `source_posts` rows for scope C.

**C is recommended.** It is 100 % publishable with zero quarantine, covers the
two most recent school years including the 2026학년도 수능 and the 2027학년도 6월
모의평가 — the material students actually use — and 716 resources is small
enough for the Owner to spot-check by hand. A and B are safe but too thin to
exercise search ranking; D adds three typo cases and 2024 material without
improving the product much.

Publishing is a separate decision from ingesting: every row is planned with
`is_active=false`, and flipping publication requires the BLOCKER above to be
resolved first.

## Production gate

`Production pilot 적용 준비: NO.`

Metadata ingestion is ready and verified, but a pilot whose whole purpose is to
make search useful cannot ship while its attachments are unopenable. The gate
is one Owner decision (BLOCKER 1a/1b), not more engineering.

When approved, apply in this order:

1. preflight: confirm project ref `stlhijzpjfgwwdgunlsd`, record current row
   counts for all six content tables, confirm `subjects` is empty;
2. run the network smoke on a machine with egress and confirm the live page
   structure still matches this document;
3. live dry-run limited to the pilot scope; diff against this document's counts;
4. apply inside one transaction per post, parents before children, using the
   upsert targets above, with `is_active=false` everywhere;
5. postflight: re-count, confirm the deltas match the table above, confirm no
   `verified` `exam_subjects` row was touched;
6. rollback plan: the pilot rows are identifiable by
   `source_posts.external_post_id`; deletion order is resources →
   exam_subjects → exams → content_items → source_posts (all FKs are
   `ON DELETE RESTRICT`);
7. only then, a separate reviewed publication step sets `is_active=true`.

## UI follow-up

Not a Day 9-A defect and not to be changed now:

- once rows exist, the 과목 filter will list nothing until `subjects` is seeded
  (SHOULD 1). The screen already falls back to the raw occurrence label, so
  results still read correctly.
- 9-C must distinguish "an attachment is registered" from "this file opens",
  which is the BLOCKER above surfacing in the UI.

## Validation

- `tool/test_ingestion.py`: **65 tests, PASS**, no network. Coverage includes
  post-id identity and URL normalisation, signature stripping, provider
  identity stability under signature rotation, title parsing (administered
  prefix, postponed sitting, 학년도 trust rules, false-positive numbers),
  filename kind and subject parsing including every substring trap and the
  word-boundary rule, modern and legacy HTML fixtures, classification,
  row shape and generated-column omission, mapping-state CHECK conformance,
  duplicate and missing provider identity, idempotency, change detection,
  merge candidates, vanished sources, parser-failure reporting, robots
  enforcement, request budget, sitemap extraction, and the apply gate.
- `python3 -m py_compile` on all new modules: PASS.
- Credential scan of new code, samples and artifacts: no `credential=`,
  `signature=`, `expires=`, bearer token, service-role key or password.
- `git diff --check`: PASS.
- Pre-existing `tool/test_*.py` failures (`test_scoring_admin_config`,
  `test_verify_mock_scoring_jwt`, `test_grade_wrapper`,
  `test_run_mock_*_flutter_smoke`) are unrelated: they import `psycopg`, which
  is not installed in this environment. Not caused by, and not touched by,
  this work.
- No Flutter source was changed, so the Flutter suite was not re-run.

## Artifacts

`build/ingestion-dryrun/` (gitignored) holds the working output. The reviewed
copy is committed at `tool/ingestion/samples/dryrun-2026-09-15/`:
`dryrun-summary.json`, `dryrun-posts.csv`, `dryrun-quarantine.csv`,
`dryrun-owner-sample.md` (the 20-row Owner review table).

`tool/ingestion/samples/day9b_survey_index.jsonl` (227 modern posts) and
`day9b_exam_posts.jsonl` (38 posts, 1,205 attachments) are the extracted
records the offline dry-run and tests run against. They hold metadata only —
no page HTML, no article body text, no attachment bytes, no signed query.

---

# Day 9-B2 — taxonomy + pilot package (2026-09-15)

Owner decisions applied: modern attachment access option **(a)**; Production
Pilot **C** approved; `subjects` seeded before the pilot; legacy deferred.

- Canonical taxonomy v1 designed and seeded as a package —
  [day-9-subjects-taxonomy.md](day-9-subjects-taxonomy.md). 36 raw tokens
  resolve to **23** canonical subjects, not 36. Deterministic ids
  (`uuid5(ns, "v1:<code>")`), `taxonomy_version='v1'`, no schema change.
- Pilot C mapping dry-run: **363 / 363 occurrences provisional, 0 unmapped,
  0 ambiguous, 0 taxonomy gaps** (160 exact, 203 documented alias). All 23
  subjects are used, so the seed has no dead row. `verified` is never produced
  by automated ingestion.
- Apply package with preflight / smoke / live dry-run / seed / apply / postflight
  / publication / rollback — [day-9-pilot-c-package.md](day-9-pilot-c-package.md).
- Apply guards implemented and tested (`assert_in_scope`, `assert_no_collisions`,
  `expected_rows`, `PILOT_C`); `assert_apply_allowed` still refuses every
  argument combination. **No production write was performed.**

## Production gate — updated

The Day 9-B BLOCKER is resolved as a policy, not as code: option (a) keeps the
unsigned kakaocdn path as identity only and sends the reader to the original
post. The remaining precondition moved from "which option" to one concrete UI
rule, and it is now the publication gate rather than the ingestion gate.

`Production pilot 적용 준비:` **package YES, execution NO.**

- Steps 1–4 of the package (preflight, network smoke, live dry-run, subjects
  seed) are executable by the Owner today.
- Step 5, the ingestion apply, still has **no write path in code** — that is the
  Codex handoff.
- Publication stays gated on the 9-C open-target rule below.

## 9-C contract — original post fallback

`content_items.source_url` already holds the post URL, is already in
`SupabaseContentRepository.projection`, and is already exposed as
`ContentItem.sourceUrl`. `lib/core/links/external_link.dart` already opens with
`LaunchMode.externalApplication`, so the WebView-free requirement is met by
existing code. **No schema, projection or repository change is required.**

One presentation rule must change before resources are published:
`ContentResource.openUri` falls back to `source_url` whenever `link_kind` is not
`landing_page`, so all 716 pilot resources — every one `link_kind='unknown'`
with an unsigned kakaocdn locator — would open a 403. 9-C routes
`link_kind='unknown'` to the content item's `source_url` instead. `link_kind` is
already in `SupabaseResourceRepository.projection`, so the rule is data-driven:

| `link_kind` | open target |
|---|---|
| `file` (legacy cfile, unsigned and stable) | the resource URL |
| `landing_page` (Box, Drive) | the resource URL |
| `unknown` (modern kakaocdn, signed) | the **original post** |

The existing caveat copy — "외부 사이트에서 열립니다. 링크의 현재 이용 가능
여부는 확인되지 않았어요." — stays accurate and needs no change.

## Day 9-B2 artifacts

`tool/ingestion/samples/dryrun-2026-09-15/` is the Day 9-B evidence and is left
exactly as it was committed — occurrences there are `unmapped`, because the
taxonomy did not exist yet. Reproduce it with `--no-taxonomy`.

`tool/ingestion/samples/pilot-c-2026-09-15/` is the Day 9-B2 evidence: the
approved Pilot C scope with taxonomy v1 applied. Its `dryrun-posts.csv` carries
two extra columns, `subject_codes` and `mapping_status`, and is the
authoritative post-id list for the package's preflight queries. Reproduce with:

```
python3 tool/ingest_legendstudy.py --pilot c --out build/pilot-c
```

Taxonomy mapping is on by default from Day 9-B2; `--no-taxonomy` restores the
Day 9-B planning behaviour.
