# Architecture

## Baseline direction

Planned client: Flutter mobile app for iOS and Android.
Planned backend: Supabase for authentication, normalized app data, personalization, and server-side support where appropriate.

The Flutter shell is implemented below; Supabase remains planned and unconfigured. Always verify `wiki/current-status.md` and the repository.

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

The owner-approved production app identifier is `com.legendstudy.app` on Android and iOS. Backend environments, signing, OAuth and store registration remain unconfigured; all remain independent of Muselry.

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
- Korean Material localization enabled. No WebView, network source scraping,
  Supabase dependency/schema, authentication, or production feature logic exists.

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


## Day 3 data boundary — proposal, not integrated

Data Model v0.1 and a draft migration now exist locally; no SQL was executed and
no Supabase project was created or linked. `wiki/database.md` is the canonical
entity/RLS/index specification; `wiki/ingestion.md` defines source identity,
reprocessing and uncertainty. The owner confirms the LegendStudy project is not created/linked; the draft is unapplied.

The proposed read path is public active exams → subject occurrences → resource
links. Original post diagnostics and quarantine stay backend-only in source_posts and ingestion_quarantine. Content writes
belong to trusted ingestion; user profile/bookmark/recent-view writes use a user
session with RLS. Service-role credentials never enter the client.

Future pure-Dart domain objects may be ExamSummary/ExamDetail, ExamSubject,
SubjectMapping and StudyResource; data DTOs may use matching `*Dto` names with
explicit nullable/raw fields. This is naming guidance, not implemented code.
Repositories should expose filters and bounded keyset pages, not Supabase query
builders or source HTML. The data layer maps PostgREST rows and distinguishes
landing-page links from verified direct binaries; the domain preserves unknown
mapping/date values. Fetch paginated exams separately from their resource lists.
Auth-user ownership is independent of optional profiles. RecentViewsRepository
should upsert `(user_id, exam_id)` and honor server timestamps; bookmark saves use
insert-on-conflict-do-nothing semantics. Hidden exam joins become unavailable
items that owners can still remove. Details and sort_date + id cursor NULL-tail behavior are
specified in the database document.

No Flutter files, dependencies, runtime behavior, signing, branding or platform
identifiers changed in Day 3; actual repository/data-source implementation follows
review and a separately authorized schema application.

### Day 3 review: future repository/API contracts

- Explicit column projections from database.md are mandatory, including nested
  projections. Do not SELECT *; internal diagnostics are not client-granted.
- Use left joins for optional taxonomy detail and raw_subject_label fallback.
  Inactive taxonomy does not hide active exam occurrences or scoped resources.
- Profile POST merge-upsert supplies id, display_name and grade_level only, conflict
  target id. Owner RLS guards old/new rows; id UPDATE permits the unchanged key.
- Recent POST merge-upsert supplies only user_id/exam_id with that conflict target;
  omit id/viewed_at. The invoker trigger supplies viewed_at. API behavior is a
  future actual-PostgREST test gate, not verified by the offline parser.
- Feed uses generated sort_date DESC NULLS LAST + id DESC. Missing actual dates
  remain unknown; sort_date is only a sorting proxy. Parameterized ILIKE starts
  without pg_trgm; measure before adding a search index.
- Stable source identity, slug, verified-row exclusion, persistent quarantine and
  duplicate soft merge belong to trusted ingestion contracts, not Flutter.
- Push notifications remain v1.0, with device tokens/preferences/delivery schema
  designed in a later v1.0 milestone. No interest-subject array or SDK added now.
