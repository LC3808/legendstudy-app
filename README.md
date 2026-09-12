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

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d <device-id>
flutter build apk --debug
flutter build ios --simulator --debug
```

The app opens a Korean Home / Browse / Saved / My Page shell. All destinations
are placeholders, with no login requirement, network calls, or backend setup.

Optional local configuration:

```sh
cp config/development.example.json config/development.json
flutter run --dart-define-from-file=config/development.json -d <device-id>
```

`APP_ENV` defaults to `development`. `appConfigProvider` exposes this public
setting for future service composition; it does not select a backend or change
application IDs. Local JSON and `.env` files are ignored. Dart defines are
extractable from client binaries: never include server secrets, service-role
keys, OAuth secrets, or signing material, even in ignored client config files.

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
