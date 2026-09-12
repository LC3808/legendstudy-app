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

Temporary Android application ID / namespace and iOS bundle ID:
`dev.legendstudy.scaffold`. Dart package: `legendstudy_app`. These values are
only for development and are not an approved production identity. Obtain final
identifiers before signing, OAuth, store registration, or distribution. iOS
has no committed development team; Android release signing is unconfigured.
Generated Flutter launcher icons remain placeholders until original brand
assets are available.

See [architecture](wiki/architecture.md), [design system](wiki/design-system.md),
and [current status](wiki/current-status.md) for implementation boundaries and
verified build outcomes.
