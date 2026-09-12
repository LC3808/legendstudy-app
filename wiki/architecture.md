# Architecture

## Baseline direction

Planned client: Flutter mobile app for iOS and Android.
Backend: dedicated LegendStudy Supabase is deployed for normalized data and Auth; Flutter integration remains Day 4 work.

The Flutter shell is implemented below; the backend schema is applied but Flutter is not connected. Always verify `wiki/current-status.md` and the repository.

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

The owner-approved production app identifier is `com.legendstudy.app` on Android and iOS. The dedicated backend is LegendStudy (`stlhijzpjfgwwdgunlsd`, Seoul ap-northeast-2, PostgreSQL 17.6), separate from Muselry. Flutter backend configuration, signing, OAuth and store registration remain pending.

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
Brand source conventions live in `assets/brand/README.md`; no original logos
are present and the Flutter launcher icons remain unchanged.

`AppConfig.fromEnvironment` reads public `APP_ENV` (default `development`) through
`appConfigProvider`; this is a configuration extension point, not a working
backend/flavor switch. Use `--dart-define-from-file=config/development.json` from
the committed example. Local configs are ignored; client defines are never a
safe place for secrets. No backend keys are currently used or needed.

Package references: [Riverpod](https://pub.dev/packages/flutter_riverpod/versions/3.3.2)
and [go_router](https://pub.dev/packages/go_router/versions/17.0.0).


## Day 3 unified data boundary — deployed backend, Flutter not integrated

The owner reports the dedicated Supabase initial schema applied and REST/JWT
runtime tests completed for the cases in database.md. Supabase is the deployed
backend source of truth; all 10 application tables are empty after fixture cleanup. database.md defines entities/security; ingestion.md defines source
classification, reprocessing and quarantine. No Flutter/SDK integration exists.

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

Deployment facts are owner-reported; this docs task did not reconnect to Supabase.
RLS client-path validation uses real REST/JWT, not SQL Editor SET ROLE. Preserve
the applied initial migration; future DB changes require new migrations. Day 4
adds supabase_flutter, URL/publishable-key configuration, initialization, public
ContentRepository reads with explicit projections, Auth sessions and personal
repositories. No service_role/secret key may enter Flutter. No such code is added
by this documentation update.
