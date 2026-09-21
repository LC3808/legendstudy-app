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

Verified toolchain: Flutter **3.47.5 stable**, Dart **3.13.4**.
Canonical local SDK: `/Users/woojinchang/development/flutter-3.47` (directory name
retained after patch upgrade). Use `./tool/flutterw` to avoid PATH's old Flutter
3.32.0 / Dart 3.8.0. The wrapper requires Python 3 for SDK metadata validation,
checks the exact verified stable version and never falls back to global Flutter.
Other machines may set `LEGENDSTUDY_FLUTTER_SDK` to the same verified SDK version.
No global shell configuration or old SDK is changed. IDE SDK selection must point
to this directory separately. Keep the committed `pubspec.lock`.
See [toolchain audit and deferred migrations](wiki/flutter-toolchain.md).
Android plugins require NDK 28.2.13676358; no signing changes are made here.

```sh
./tool/flutterw pub get
./tool/flutterw analyze
./tool/flutterw test
./tool/flutterw run
./tool/flutterw build apk --debug
./tool/flutterw build ios --simulator
```

For Owner iPhone profile acceptance, connect/unlock the physical iPhone first:

```sh
cd /Users/woojinchang/development/legendstudy-app
./tool/flutterw run --profile --dart-define-from-file=/Users/woojinchang/legendstudy-local.json
```

Select the actual physical iPhone if prompted; do not select the simulator for
profile mode. No physical device was connected at this audit, so no device ID is
invented. The existing external config path was verified without printing its
contents; provider enablement/E2E is not inferred from its existence. Xcode Owner
signing remains intact. Disconnected Debug home-screen relaunch restrictions do
not test session restore; profile/release terminate/relaunch E2E remains pending.

The app opens 홈 / 자료 / 학습 / MY. Home and Materials consume public Supabase
content; Study is idle UI and MY owns saved/school/recent shells. Read
[UI/UX v1.1](wiki/ui-ux-v1.md) before UI implementation.
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
