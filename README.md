# LegendStudy App

LegendStudy mobile application project.

This repository is the canonical source for the LegendStudy native app and its in-repository development wiki.

## Ground rules

- Muselry and LegendStudy are completely separate projects.
- Do not implement LegendStudy as a simple WebView wrapper.
- Canonical development knowledge lives in `wiki/`.
- Before work: read `AGENTS.md` → `wiki/index.md` → `wiki/current-status.md`, then verify against actual code/DB/Git state.
- After work: update `wiki/current-status.md`, `wiki/log.md`, and any affected wiki documents.

## Development

Verified toolchain: Flutter **3.32.0**, Dart **3.8.0**. Use the committed
`pubspec.lock` for reproducible package versions.
The [official Supabase Flutter package](https://pub.dev/packages/supabase_flutter)
was checked; pub resolved 2.15.4 as compatible with this SDK (latest stable 2.17.2
at implementation time). Existing Riverpod/go_router versions were preserved.
Android native plugins require NDK 27.0.12077973 (pinned in app/build.gradle.kts).

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d <device-id>
flutter build apk --debug
flutter build ios --simulator --debug
```

The app opens a Korean Home / Browse / Saved / My Page shell. Home and Browse
consume public Supabase content; Saved/Profile screens remain placeholders.
Public reads require no login. Local configuration for backend access:

```sh
cp config/development.example.json config/development.json
flutter run --dart-define-from-file=config/development.json -d <device-id>
```

Fill SUPABASE_PUBLISHABLE_KEY locally after copying the example; never commit the
real value in this project. SUPABASE_URL is the dedicated LegendStudy HTTPS URL.
`APP_ENV` defaults to `development` and does not change the project or app identity.
`AppConfig` validates the target URL and accepts only an sb_publishable_ client key.
A missing/invalid config still builds and opens the shell with explicit settings
errors; startup failures show a safe message. No dummy backend/data fallback is used,
including production. Valid config initializes Supabase before runApp.

Local JSON and `.env` files are ignored. Publishable keys are intended for public
clients and depend on RLS/column grants; they are extractable from binaries, not
server secrets. Never include service-role/secret keys, passwords, OAuth secrets,
signing material or test JWTs, even in ignored Flutter define files. Production
release pipelines must inject valid public config and verify startup before shipping.

Optional **read-only**, real-device/simulator smoke (requires that local config):

```sh
flutter test integration_test/supabase_smoke_test.dart -d <device-id> --dart-define-from-file=config/development.json
```

This initializes the SDK with empty session storage, performs anonymous repository
read and expects the current empty database, checks signed-out personal handling,
and creates no Auth user or DB fixture. Run normal `flutter test` without network
or keys. The opt-in smoke was not run during Day 4-A unless recorded in current-status.

Search is bounded to 200 characters / 8 whitespace-separated tokens / 100 results;
each token matches title OR summary, AND between tokens. LIKE %/_ are literal;
PostgREST grammar delimiters are quoted. Asterisk is rejected with a clear message
because PostgREST treats it as a wildcard alias. No search engine/schema changes.

Owner-approved Android application ID / namespace and iOS bundle ID:
`com.legendstudy.app`. Dart package remains `legendstudy_app`; the separate iOS
test bundle is `com.legendstudy.app.RunnerTests`. Both platforms display
`레전드스터디`. Signing, OAuth and store registration are still unconfigured;
this identity decision does not establish registration or availability in stores.

Original brand assets belong in `assets/brand/` (see its README). No original
logo files are present yet, so generated Flutter launcher icons remain unchanged.
No guessed or redrawn logo has been introduced.

See [architecture](wiki/architecture.md), [design system](wiki/design-system.md),
and [current status](wiki/current-status.md) for implementation boundaries and
verified build outcomes.
