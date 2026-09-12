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

Production environment and identity are not finalized. The explicit development-only baseline is documented below and remains independent of Muselry.

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

Both platform app identifiers use temporary `dev.legendstudy.scaffold`;
iOS test target uses `dev.legendstudy.scaffold.RunnerTests`. Android Kotlin
namespace matches its application ID. No production ownership is implied.
Dart package name is `legendstudy_app`. Final identifiers require owner confirmation
before platform signing/OAuth/store registration. No Apple team is committed;
Android release signing must be configured explicitly before distribution.

`AppConfig.fromEnvironment` reads public `APP_ENV` (default `development`) through
`appConfigProvider`; this is a configuration extension point, not a working
backend/flavor switch. Use `--dart-define-from-file=config/development.json` from
the committed example. Local configs are ignored; client defines are never a
safe place for secrets. No backend keys are currently used or needed.

Package references: [Riverpod](https://pub.dev/packages/flutter_riverpod/versions/3.3.2)
and [go_router](https://pub.dev/packages/go_router/versions/17.0.0).
