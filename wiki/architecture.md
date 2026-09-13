# Architecture

## Baseline direction

Planned client: Flutter mobile app for iOS and Android.
Backend: dedicated LegendStudy Supabase is deployed for normalized data and Auth; Flutter integration foundation is implemented; live connection verification requires local config.

The Flutter shell is implemented below; the backend schema is applied and Flutter connection code is present. Always verify `wiki/current-status.md` and the repository.

## High-level components

1. Native Flutter app
2. Supabase Auth
3. Supabase Postgres
4. Optional Supabase Edge Functions for server-side operations
5. Ingestion tooling that converts `legendstudy.com` content into normalized app records
6. Existing website as the public source/content origin where appropriate

## Client architecture goals

- Clear separation between presentation, domain/use-case logic, and data access
- Repository/service abstraction around Supabase and external content
- Typed models
- Router-based navigation
- State management chosen explicitly during scaffold setup
- Testable ingestion-independent UI
- No runtime page scraping for normal app browsing

## Data flow

`legendstudy.com` → ingestion/parser → normalized Supabase records → Flutter app

The app should consume structured records rather than parse the website during normal user interaction.

## Environments

The owner-approved production app identifier is `com.legendstudy.app` on Android and iOS. The dedicated backend is LegendStudy (`stlhijzpjfgwwdgunlsd`, Seoul ap-northeast-2, PostgreSQL 17.6), separate from Muselry. Flutter local public configuration, signing, OAuth and store registration remain pending.

## Implemented Day 1 scaffold (2026-09-12)

- Flutter 3.32.0 / Dart 3.8.0, iOS + Android native Flutter hosts at repository root.
- `lib/app`: application composition, router lifecycle and navigation shell.
- `lib/features/{home,browse,saved,profile}/presentation`: independent placeholder pages.
- `lib/core/config`: typed, overrideable public environment provider.
- `lib/core/theme`: reusable brand tokens and Material 3 light theme.
- `lib/shared/widgets`: shared placeholder layout with scrolling and width constraint.
- Future feature `domain/` owns pure Dart entities/contracts; `data/` implements
  repositories and maps transport data. No speculative data/domain classes were
  added to a shell without business behavior (see `lib/features/README.md`).
- Riverpod (`flutter_riverpod` 3.3.2 locked) supplies testable dependency injection
  and a path to asynchronous feature state without code generation. Navigation
  state is owned only by the router, not duplicated in a tab-index provider.
- `go_router` 17.0.0 locked uses `StatefulShellRoute.indexedStack` for four independent
  branch stacks: `/home`, `/browse`, `/saved`, `/profile`. `/` redirects home and
  unknown paths offer a home recovery action. Router disposal is provider-owned.
- Package versions were resolved against the installed SDK, rather than upgrading
  the user's global Flutter installation. Commit `pubspec.lock` with changes.
- Korean Material localization enabled. At the Day 1 scaffold stage, no WebView,
  network source scraping, Supabase dependency/schema, authentication, or production
  feature logic existed. See the deployed Day 3 backend boundary below.

### Development environment and identity

As of Day 2, Android application ID, namespace and Kotlin package are
`com.legendstudy.app`. The Kotlin activity is under
`android/app/src/main/kotlin/com/legendstudy/app/MainActivity.kt`.
iOS Runner uses `com.legendstudy.app` for Debug, Release and Profile; RunnerTests
uses the distinct test-only bundle `com.legendstudy.app.RunnerTests` in all three
configurations. Dart package remains `legendstudy_app`. Android and iOS display
`레전드스터디`.

The owner approved this production identity; Apple/Google registration and
availability have not been checked or claimed. No Apple team, certificate or
provisioning profile is configured; Android release signing remains unconfigured.
Official brand sources and derivative provenance live in `assets/brand/README.md`.
Home uses the supplied wordmark crop. Future launcher icons use the square brand
reference’s orange memo/document + pencil symbol, not the legacy 72×72 favicon.
High-resolution symbol production/restoration is deferred; current Flutter
launcher icons remain placeholders.

`AppConfig.fromEnvironment` reads public `APP_ENV` (default `development`) through
`appConfigProvider`; this is a configuration extension point, not a working
backend/flavor switch. Use `--dart-define-from-file=config/development.json` from
the committed example. Local configs are ignored; client defines are never a
safe place for secrets. Day 4-A extends this configuration as described below.

Package references: [Riverpod](https://pub.dev/packages/flutter_riverpod/versions/3.3.2)
and [go_router](https://pub.dev/packages/go_router/versions/17.0.0).


## Day 3 unified data boundary — backend contracts

The owner reports the dedicated Supabase initial schema applied and REST/JWT
runtime tests completed for the cases in database.md. Supabase is the deployed
backend source of truth; all 10 application tables are empty after fixture cleanup. database.md defines entities/security; ingestion.md defines source
classification, reprocessing and quarantine. Day 4-A implements the client foundation below.

The app's public primary entity is **content_items**. source_posts is backend-only
provenance/ingestion metadata. exams is an optional exam-type extension with shared
content_item_id PK. General resources attach to content_items; scoped exam resources
use the occurrence/content composite FK. Saved and Recent target all content types.

### Repository and API boundaries

- ContentRepository returns ContentSummary/ContentDetail cards and bounded parent
  pages for Home, search and categories. DTOs use explicit nullable fields and the
  exact SELECT projections in database.md, including nested projections; no `*`.
- Search applies content type/title/summary/published-date criteria on parents.
  Explicit year/grade/exam-type/subject filters use the optional exam/occurrence
  relations and intentionally narrow results to exams. Parent paging precedes
  resource expansion; use EXISTS or filtered relations to avoid duplicated cards.
- Home recent updates uses generated feed_updated_at = greatest(source publication,
  source modification), DESC NULLS LAST + id DESC. Local ingestion/update time never
  drives this feed. Source update time unknown means publication fallback, or NULL
  when both unknown. Exam-only chronology separately uses sort_date/content_item_id.
- ExamRepository loads specialized calendar/academic-year/grade/type metadata by
  content_item_id. Optional taxonomy joins use left joins/raw-label fallback;
  inactive taxonomy never suppresses actual active content. Parent is_active is
  authoritative; exams has no second publication flag.
- Saved/Recent repositories use `(user_id, content_item_id)` for every type.
  Bookmark inserts ignore duplicates. Recent POST merge-upsert payload contains
  only those two keys, omitting id/viewed_at; trigger supplies time. Hidden content
  becomes an unavailable item that its owner may still remove.
- Profile POST upsert remains id/display_name/grade_level only. Owner RLS guards
  old/new rows; unchanged id assignment is permitted. Reported REST/JWT profile ownership and recent upsert tests passed. Additional
  profile conflict-upsert cases and Flutter integration remain to be tested.

### Native screen routing

Future content routes resolve a stable content slug (e.g. `/content/:slug`) to a
native summary/detail shell. This is a contract, not a new implemented go_router
route. Type determines optional detail data: exams load exam metadata and subject
resources; study/essay items load general resources; columns/admissions can display
a native title/summary/source action with no exam or attachment. Resource controls
use known file/landing-page metadata. Opening the original externally is permitted;
a WebView wrapper and runtime scraping are not the app architecture. A future
native article body requires separate storage/rendering design.

Content IDs/slugs survive source modifications and soft merges. Backend-only
classification, source keys, diagnostic notes and quarantine do not enter public
DTOs. No university master, article service, search engine, semantic classifier or
notification infrastructure is added. Notifications remain a later v1.0 milestone.

### Post-deployment boundary

Day 3 deployment facts are owner-reported. RLS client validation uses REST/JWT;
SQL Editor SET ROLE is not authoritative. Initial migration bytes are immutable;
future DB changes require new migration files. Day 4-A executes no SQL.

## Day 4-A Flutter integration and UI handoff

`main` initializes Flutter binding, validates AppConfig, awaits Supabase.initialize
and injects the client into ProviderScope. Supabase.instance is accessed only at
that composition root. appConfigProvider, supabaseClientProvider and repositories
are independently overrideable. Config accepts only the dedicated HTTPS project
URL and a publishable key, supplied via compile-time defines. Missing settings and
startup errors render explicit safe states, including in production; no fake data
or dummy backend is installed. No keys or raw SDK errors are logged by app code.

`content/domain` defines the public 11-field ContentItem and repository interface.
`content/data` is the SDK implementation. Home recentContentProvider and Browse
contentSearchProvider expose AsyncValue<List<ContentItem>>: loading, empty, data,
error, with explicit retry; screens never query Supabase directly. Search submits
on button/keyboard action, trims empty input and clears visible results when input
is cleared. Up to 8 tokens/200 characters, each title OR summary, AND between tokens;
LIKE literal escapes and PostgREST quoted values prevent grammar injection. Asterisk
is rejected because of its wildcard alias. Limits are 1..100; default 30. Feed sort
is feed_updated_at DESC NULLS LAST/id DESC. Slug lookup returns null when invisible.
No nested resource/detail UI, advanced filter, taxonomy or pagination UI yet.

`authStateProvider` maps SDK initial/session events into AuthStatus(userId), with
isAuthenticated distinguishing signed-out from authenticated. Raw tokens are never
part of UI state. AsyncError represents subscription failure. This foundation adds
no login UI, automatic test-user login, social providers or anonymous Auth users.

Personal interfaces/implementations are injected by profileRepositoryProvider,
bookmarkRepositoryProvider and recentViewRepositoryProvider. Each call derives the
owner from the current SDK session; no user ID parameter or cached owner. Signed-out
reads return null/[]/false, writes throw SignedOutException before network. Consumers
must handle that outcome and AsyncError. Queries explicitly filter owner and select
only needed columns. Profile writes use id/display_name/grade_level and conflict id;
bookmark saves use ignore-duplicates on the user/content pair; recent merge-upserts
send only that pair, never id/viewed_at. Personal lists sort by server time/id and
are bounded to 100; pagination and joined content hydration are future work. Hidden
content entries retain contentItemId for later unavailable-item UI/deletion.

Claude's UI contract: content loading/empty/data/error; Auth signed-out/authenticated
plus async loading/error; bookmark isBookmarked supplies saved/unsaved and caller
tracks mutation loading/error; recent repository supplies list/empty. In future
personal UI, observe Auth changes and invalidate per-user state, discard results
from a prior user and clear on sign-out. No personal screen cache is introduced now.
Claude leads UI/UX; Codex implements its specs. Existing tabs, brand and typography
remain intact; Home/Browse add only data-state widgets/input.

Android main manifest declares INTERNET; NDK 27.0.12077973 satisfies native plugin
requirements. CocoaPods files integrate native plugins.
Package versions and build/connection evidence live in current-status.md. Real
backend smoke is opt-in via local public config; unit tests use fake repositories
and mock HTTP with synthetic sessions, never a real password/JWT. No service_role
or secret key belongs in Flutter; publishable keys are public, extractable client
values whose access is constrained by RLS/grants.

## Day 5 UI shell

Canonical UI specification: ui-ux-v1.md. StatefulShellRoute.indexedStack is retained
with /home, /materials, /study and /my branches. MY owns saved/school/recent child
routes; root /materials/:slug pushes above the bottom shell, preserving the parent
stack for back navigation. Legacy /browse, /saved, /profile redirect to their new
locations. Search input/branch state survives tab switches; query parameter q is a
keyword entry point. Category chips do not imply taxonomy filtering.

Home orders branded header, non-date D-Day prompt, school/meal placeholder, search,
quick keywords, study summary, actual recent content and recent-view placeholder.
Materials reuses the existing ContentRepository; detail is a read-only title/summary
shell with the existing slug repository method. Domain/data/grants are unchanged.
Study is idle UI only; MY observes authStateProvider and leaves persistence/OAuth/
school/support purchase unconnected. Saved presentation is reused under /my/saved.
No school/meal/timer schema, API, ads SDK, IAP, notifications or ingestion is added.
Shared layout/header/state/card widgets use the existing theme with refined tokens.


## Day 6 Materials / Search / native Detail

Parent ContentRepository keeps fetchRecentContent, searchContent and fetchContentBySlug.
searchContent gains optional contentType: an allowlisted type applies an explicit eq
predicate. Empty keyword with a type lists that type; keyword plus type combines both.
No keyword/type returns empty (the UI prompts for a query or filter). Existing 200-char,
8-token, asterisk rejection, literal LIKE escaping, 11-column projection, active flag,
feed_updated_at DESC NULLS LAST/id DESC and 1..100 bounds remain intact. Materials
retains a submitted query and independent type state across tabs/detail-back. Query
entry stays submit-based; typing is not an automatic network search. Home shortcuts
use the type query parameter; path/navigator/legacy redirect topology is unchanged.
Directly opened detail with no back stack returns to Materials via its back action.

ExamRepository fetches a bounded batch (up to 100 parent IDs) from the exact public
exams projection. The list batches exam metadata once per parent page; non-exam
parents do not trigger exam requests. Pure Dart ExamMetadata preserves separate
calendar year and academic year; presentation omits NULLs and never infers fields
from title, sort_date or historical taxonomy. The detail displays academic year,
actual exam date, round and curriculum only when present. Missing metadata creates
no empty line. Per-region loading/error/retry does not replace the parent content.

ResourceRepository reads the exact public resources fields, including actual names
file_extension and file_size. Explicit left embeds through resources_subject_same_content
and exam_subjects_versioned_mapping fetch only granted occurrence/subject fields.
No inner join or active-taxonomy predicate filters the resource result. Grouping
preserves each occurrence ID, using active mapped name → raw_subject_label → 일반 자료.
General resources are a separate group. display_order ASC/id ASC gives deterministic
order; 100-row pages are fetched until the scoped resource list is complete. Concurrent
changes are not claimed to provide snapshot pagination.

Detail stays /materials/:slug on the root navigator with no bottom NavigationBar.
One native title follows a neutral type badge; metadata, summary, actual source/time
information, resources and 원문 보기 are rendered as applicable. Missing parent is
자료를 찾을 수 없어요. Zero attachments is normal; columns avoid a large empty panel.
No stored article body, PDF renderer, WebView, ingestion, bookmarks or personal writes.

ExternalLinkButton uses an injected opener backed by url_launcher externalApplication.
url_launcher 6.3.2 was already locked transitively; it is now a direct dependency,
without package version/native plugin changes. Only HTTP(S) URLs with host and without
userinfo/control characters are opened. landing_page always uses source_url;
otherwise verified-by-ingestion file_url is preferred, then source_url. No filename,
MIME or direct URL is guessed. False/exception launch results show a retryable safe
message; OS acceptance is not proof of a working remote file. Native PDF viewing is
left for its dedicated milestone.

**Existing contract limitation:** resources.link_status and last_checked_at are private;
RLS does not exclude broken/restricted rows by status. This client cannot identify or
claim their health, and does not select those columns or change grants. Resource actions
are labelled external links with availability explicitly unconfirmed; no download-success
or available badge is shown. Guaranteed disabling of known broken/restricted links needs
a separately reviewed public eligibility/status contract or trusted publication rule.
This is an unresolved link-health capability, not a Day 6 schema change.


## Day 7 School / NEIS

Profile reads include the owner-only NEIS identifier pair. updateSchoolSelection
uses a session-derived id and pair-only upsert; ordinary profile editing omits the
pair. No caller-supplied owner id, new policy, schema edit or auth UI is introduced.
SchoolSelection watches Auth and rebuilds without displaying previous-owner data;
late save completion is discarded after auth changes. Public school search state
contains no account identifiers. Guests keep only process-memory selection.

SchoolRepository returns pure Dart School/Meal entities. NeisSchoolRepository is a
Flutter adapter to the dedicated LegendStudy Edge Function, not a client containing
NEIS credentials. The prepared function permits only school search, identifier
lookup and one-date meal reads with bounded inputs/projections/timeouts. No DB or
Auth admin client. Deployment/key setup/live acceptance remain pending; see
wiki/day-7-neis.md. Sample-only access is never silently used by the real app.

Home's local meal region consumes school/date-dependent Riverpod state; other Home
content remains independent. Korea date comes from UTC+9 and is checked every 30s.
Same selected school/date reuses the provider result; selection/date changes or
explicit retry refresh. Auth change invalidates school/meal state. Existing
StatefulShellRoute topology and Day 6 contracts are unchanged.
