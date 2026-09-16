# Day 9-A — Search / Explore

Status: **Day 9-A COMPLETE** — Search / Explore implementation and scoped
validation PASS. The former Xcode 27 external validation override has been
replaced by the repository's official iOS 15/arm64 settings; this is not Day
9-B/C/D completion.

## Baseline and boundaries

Started 2026-09-15 on `codex/day-7-school-neis`, HEAD `3519073`, no tracked changes.
Existing `Claude outputs/`, `supabase/.temp/`, `tool/__pycache__/` are preserved.
Local repository is canonical. Day 8-A/D1/D2/D3 COMPLETE and accepted iPhone
Study/Mock lifecycle/UI results are retained. Focus details, reboot and Android
physical-device checks remain separate; no Study/scoring feature expansion here.

Day 9-A builds public search. Day 9-B supplies real legendstudy.com content;
9-C adds PDF/bookmark/recent writes; 9-D covers populated production search quality
and physical runtime. No ingestion, production fixture, DB/schema/migration/RPC,
Auth account operation, push, PR or merge accompanies this work.

## Verified schema and production evidence

Read initial migration `20260912000100_initial_content_schema.sql`, current Wiki,
existing content/exam/resource/personal repositories and routing before changes.

- `source_posts` is private provenance; public parent is `content_items.id`.
- `exams.content_item_id` is the shared PK, with composite discriminator FK
  `exams_content_type`. There is no separate `exams.id`.
- `exam_subjects.content_item_id` references exams; each occurrence has its own ID.
- `exam_subjects_versioned_mapping` links `(subject_id,taxonomy_version)` to subjects.
- `resources_subject_same_content` binds a scoped resource to its occurrence and
  same parent; unscoped resources work for every content type.
- Bookmarks and recent views reference `content_item_id`, with owner RLS. Search
  does not write either table. Parent ID and slug remain stable through 9-B/9-C.
- Anonymous/authenticated public reads share active-parent/active-child policies.
  Missing/inactive taxonomy uses the public historical raw occurrence label.
  Private source/quarantine, mapping note/confidence and link-health columns are
  not selected. No service-role client or login is required.

On 2026-09-15, anonymous read-only HEAD/count requests returned HTTP200 / zero
visible rows for content_items, exams, subjects, exam_subjects and resources.
This measures publicly visible rows, not hidden administrative rows. D3's accepted
cleanup/baseline preservation remains the latest private-table evidence.
No synthetic content was inserted to make the UI look populated.

## Search contract

`SearchQuery`, `SearchFilters`, `SearchTerms`, `ResourceSearchItem`, `ResourceGroup`,
`SearchFacets`, `SearchPage` and `SearchResultState` live in the Materials domain.
`SearchRepository` separates queries from `SupabaseSearchRepository` and Riverpod
`SearchController`. The UI never builds Supabase queries. Older ContentRepository
remains the Home feed/native-detail contract; test-only legacy adapters preserve
historical navigation tests without adding a production fallback.

- Trim, collapse whitespace and lowercase Latin. `9 월` equals `9월`.
- Bare four-digit year / `년` means **calendar year**, not academic year.
  Academic-year source wording remains in the parent title and typed exam model;
  it is never silently substituted for calendar year.
- `고1/2/3`, months 1–12, 수능→csat, 모의평가→evaluation_mock,
  학력평가→national_mock, 모의고사→exam use existing metadata/taxonomy.
- Exact public subject names resolve to current public subject IDs (all matching
  taxonomy versions, bounded 100); no dependency on currently loaded facet pages.
  An explicit subject and a different typed subject yield no results.
- 문제/정답/해설/듣기 use actual resource_type values. Multiple resource-kind
  terms mean any of those kinds; other text terms are ANDed across title/summary.
- A subject+resource query matches resources on that **same occurrence**, not a
  different subject's attachment on the parent. Results show matching subject
  groups plus any common parent attachments. Detail continues to show the parent.
- Remaining text uses quoted literal ILIKE conditions; `%`, `_`, backslash and
  PostgREST punctuation are escaped. `*`, >200 characters or >12 words are rejected.
  No FTS, fuzzy matching or inference of historical taxonomy is introduced.
- Grade options follow the actual 1/2/3 CHECK. Year/month/exam-type options come
  from public exams; subjects come from public taxonomy. Filter discovery reads
  100 rows per stream + sentinel, then explicitly offers “필터 목록 더 보기”.
  Loaded options are deduplicated; years descending. Options are not claimed to
  be a complete catalogue while another page exists. Search itself does not
  depend on this partial option list. Filtering applies immediately.

## Sorting, paging and bounded enrichment

The public API rejected parent-side `exam(sort_date)` ordering with PGRST118:
PostgREST does not recognize the inverse composite relation as to-one here.
Empty embedded projections also attempted non-public wildcard columns (42501).
Verified fix uses explicit public columns and starts at **exams**:

1. Exams: `sort_date DESC NULLS LAST, content_item_id DESC`.
2. Parents without an exam extension: `feed_updated_at DESC NULLS LAST, id DESC`.

This preserves general content rather than excluding it with a global inner join.
It also safely displays an extension-less exam parent, although ingestion requires
reviewed exam metadata before publication. UUID is only a tie-breaker, never a
substitute for chronology. Generated sort_date retains its canonical DB meaning.

- Page size 24, fetch 25 sentinel. Results page parent identities before enrichment,
  so multiple attachments cannot create repeated search cards.
- Offset selected because the existing API has two differently sorted streams and
  an inverse relation that cannot perform a unified keyset order. No new RPC/view
  is authorized. A bounded zero-row exact count locates the general-content offset
  only when crossing streams. Counted out-of-range pages return PGRST103/416;
  actual page reads are uncounted, with count separately at offset 0. Live read-only
  checks verified both this edge and the corrected SDK path.
- Maximum offset 10000; refine the query beyond that. Concurrent ingestion can shift
  offset boundaries: controller deduplicates parent IDs, but cannot promise a
  snapshot or recover skipped rows without refresh. Restart search after ingestion.
- Occurrence and resource enrichment select only the current <=24 parents, each
  capped 1000 with exact counts. Truncation fails visibly; never infer missing
  availability from silently truncated attachments. No unbounded SELECT-all loop.
- Existing indexes used as designed: exams_date_sort, content_items_active_feed,
  exam_subjects_mapping and resources_subject_content. Additional keyword/metadata
  indexes are not asserted present and query-plan performance is not yet measured.

## UI and 9-C readiness

White background, compact orange selected states, full-width search, 학년/연도/
시험/과목 selectors and retained content-type chips. Months and exam type can be
combined. Clear input retains filters; reset filters retains input. Empty input
browses. Search debounce 350ms respects IME composition; keyboard submit is immediate.
Home input hands raw `q` to the same Materials route/query contract; it has no
second search engine. Branch/detail return retains input and filters.

Loading, empty catalogue, no matching results, safe error/retry and data are
separate. More-page failure preserves current items. Stale requests cannot replace
newer results. No Auth requirement or fake production cards.

Each parent is one lightweight divided result with title, real metadata and groups
of registered resource kinds. Duplicate kinds collapse within an occurrence.
Three groups at most are previewed, with remaining count and native-detail entry;
underlying IDs/resources are retained. Long titles and subject labels wrap.
General content retains known publication/update metadata. No internal ID/version,
private diagnostics, bookmark write or recent write appears in this screen.

“첨부 종류는 등록 정보 기준” distinguishes metadata from verified download success.
resource_type is purpose; MIME/extension/file_url describe PDF/file information.
Public grants do not expose link_status, so broken/restricted classification is
not invented. Existing native detail and safe HTTP(S) external-opening behavior
remain; no new viewer, WebView, storage download or URL fetch is introduced.
9-C must settle link-health exposure and redirect/storage/fetch security before
adding download/viewer behavior. See database.md and ingestion.md.

## Validation and visual evidence

- Deterministic repository/HTTP fixtures live only under test/; multiple years,
  grades, subjects, resource combinations, missing attachments and long labels.
- Domain/query tests cover metadata filters, combinations, literal escaping,
  aggregation/raw fallback, explicit projections, stable order, overflow and the
  exam/general page boundary. Controller covers loading/empty/no-results/error,
  retry, page failure, deduplication and stale results; UI covers debounce, Home
  handoff, filter reset, keyboard and all required screen states.
- Render harness: `test/search_ui_test.dart`, optional `SEARCH_RENDER=true` writes
  actual Flutter PNGs to ignored `build/search-review/`. 360×640 and428×926,
  1×/2×, zero/one/many, long title/subject, loading/error, multi-filter and keyboard
  inset layouts. These are desktop Flutter renders, not iPhone physical evidence.
- Native harness: `integration_test/search_explore_test.dart` with
  `test_driver/search_explore_driver.dart`; captures under ignored build/search-native.
  Synthetic memory data only. Does not override real device dimensions.
- Explicit opt-in `test/search_public_readonly_test.dart` runs the real SDK using
  external SEARCH_CONFIG_PATH, no Auth/login/writes. PASS on production empty
  catalogue, typed queries, subject/resource predicate, facets and later pages.
  Default regression skips this network test. Credentials/raw responses are not
  logged. No populated-production runtime claim before 9-B/9-D.
- Analyze PASS; full regression306 PASS (one opt-in network test skipped by
  default), network read-only test separately PASS; all 29 render/handoff tests
  PASS. 52 generated screenshots cover the matrix; representative top/result
  images reviewed for hierarchy, spacing, wrapping and state distinction.
  Android debug build PASS; git diff/credential checks PASS.
- Native harness also overrides Study controller with in-memory storage/clock,
  so Home handoff cannot restore or mutate the Owner's native Study session.
- Owner accepted the Xcode license. iPhone 17 Pro simulator / iOS 26.5 native
  search scenarios and Home handoff PASS; 402×874 logical pixels, 1206×2622 PNGs.
  1×/2× zero/one/many/long-title/long-subject/loading/error/filters/keyboard reviewed.
  Authoritative OS-level captures: ignored build/search-system/402-*.png (26 files).
- Initial native input tests did not prove keyboard display. Added a real inset>0
  assertion and explicit native show request. It correctly failed with Device Hub's
  simulated hardware keyboard, then both 1×/2× passed with software keyboard enabled.
  Korean OS keyboard screenshots confirm the input stays visible. Hardware-keyboard
  setting was restored afterward. Earlier focus-only captures are not keyboard PASS.
- Native screenshots wait for compositor presentation; filenames use actual logical
  width. Optional SEARCH_SYSTEM_CAPTURE emits a safe capture marker and pauses2s
  for host simctl capture. SEARCH_KEYBOARD_ONLY narrows environmental rechecks.
  Default native suite requires Device Hub → Device → Keyboard → Simulate Hardware
  Keyboard OFF, so keyboard absence fails instead of producing a false success.
- iOS simulator and signed profile builds PASS with the external override below.
  No physical iPhone was connected: profile build is not physical profile launch.
  Day 8 physical acceptance remains unchanged; populated-data/device validation is9-D.

## DB gate / next work

- BLOCKER: none for scoped Day 9-A. Release-toolchain decision below and actual
  populated-content/device checks remain separately tracked.
- SHOULD (after real9-B data): profile ILIKE/join/count query plans and facet usage;
  propose a public search/facet projection or indexes only with measured need and
  separate Owner approval. Review offset concurrency and preview density on real
  multi-subject content. Resolve link-health contract before 9-C downloads.
- LATER: approved FTS/trigram, unified keyset query, hierarchical taxonomy UX and
  additional virtualized-list optimization if measured volume warrants them.
- 9-B can prepare ingestion against stable content/occurrence/resource identities;
  preserve raw labels, calendar/academic distinction and existing publication gates.
  This document authorizes no production ingestion or schema change.


## Xcode 27 validation environment / release boundary

Xcode 27.0 (27A266a) rejected the repository's former iOS12 deployment target
(minimum accepted by this toolchain:15). The installed Flutter engine also
requires the Apple Silicon simulator architecture used below. This was resolved
in-repository on 2026-09-16: Podfile and Runner configurations use iOS15, Pods
are pinned to iOS15 in `post_install`, and Runner uses arm64.

The historical successful **validation builds** used this repository-external file:
`/private/tmp/legendstudy-day9-xcode27.xcconfig`:

```xcconfig
IPHONEOS_DEPLOYMENT_TARGET = 15.0
ARCHS = arm64
ONLY_ACTIVE_ARCH = YES
```

That file is no longer needed for normal builds. The repository-native settings
produce the same arm64/iOS15 simulator target without `XCODE_XCCONFIG_FILE`.
The old plain-build failure is retained as historical evidence only.

The supported minimum iOS/toolchain decision is now recorded as iOS15/Xcode27;
default builds are reproducible under the checked-in configuration. Release
signing and device runtime remain separate acceptance claims.
Normal configured simulator app was rebuilt/reinstalled and launched after the
memory fixture harness; no uninstall/container reset was used. Actual Materials
empty state was verified through native UI (normal-app-empty.png), in addition to
the26 fixture-matrix OS captures. Physical phone validation awaits9-D.
