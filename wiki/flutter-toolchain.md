# Flutter toolchain and dependency audit

Reviewed 2026-09-21. Project-only maintenance; no global shell/old SDK/signing or
Production changes. UI fix/audit already landed separately in 3199b25; not repeated.

## Baseline and stable selection

- Starting HEAD 3199b25, branch codex/day-7-school-neis; only existing Owner edits
  in ios/Runner/Info.plist and Runner.xcodeproj/project.pbxproj plus preserved
  Claude outputs, Supabase temp and Python caches. Both Owner files hash-checked.
- Previous project SDK Flutter 3.47.3 stable / Dart 3.13.3; immediately preceding
  full baseline 513 PASS / 1 existing skip, analyze and both builds PASS.
- Current verified SDK **Flutter 3.47.5 stable / Dart 3.13.4**, same directory
  /Users/woojinchang/development/flutter-3.47. Official Git stable HEAD and tag
  3.47.5 agree (6a19cca56475dbfba1478ee68d7bd0c2ef891da1). Official release JSON
  endpoint was unavailable (HTTP 404), so Git stable/tag and upstream changelog
  were cross-checked instead. Patch includes iOS/Xcode debugging fixes.
- pubspec Dart ^3.13.3 / Flutter >=3.47.3 constraints remain valid and unchanged;
  helper pins the verified development toolchain, not a new minimum app requirement.
- .zshrc prepends old development/flutter/bin after fvm/default/bin, making
  Flutter 3.32 / Dart 3.8 the PATH default. No relevant alias override found in
  inspected startup files. Do not use this old SDK for LegendStudy.
- Use ./tool/flutterw (Python 3 required). It selects the dedicated SDK, checks
  exact stable version, prepends only its child-process PATH and preserves arguments.
  LEGENDSTUDY_FLUTTER_SDK supports other machines with the same verified version.
  Missing/wrong SDK fails closed, no global fallback. IDE SDK path set separately.

## Dependency decisions

Unrestricted pub upgrade dry-run proposed 64 graph changes, including app_links
6→7 via Supabase minor. Applied a targeted compatible upgrade instead. No new
app dependency or constraint change; lockfile includes exactly these ten updates:

| Package | Before | After |
|---|---|---|
| shared_preferences | 2.5.3 | 2.5.5 |
| shared_preferences_android | 2.4.13 | 2.4.28 |
| shared_preferences_foundation | 2.5.4 | 2.5.7 |
| shared_preferences_platform_interface | 2.4.1 | 2.4.2 |
| url_launcher_android | 6.3.20 | 6.3.33 |
| url_launcher_ios | 6.3.4 | 6.4.2 |
| url_launcher_linux | 3.2.2 | 3.2.3 |
| url_launcher_macos | 3.2.3 | 3.2.6 |
| url_launcher_web | 2.4.1 | 2.4.3 |
| url_launcher_windows | 3.1.5 | 3.1.6 |

A — Applied compatible patch/minor platform fixes/docs/SDK alignment above.
Legacy preferences API/storage keys retained; no data migration/API rewrite.
B — Deferred major: go_router 18, flutter_lints/lints 6, app_links 7. app_links
7 has iOS scene-lifecycle changes and 7.1 introduces AGP 9 build migration.
C — Deferred even if resolvable: Supabase 2.17.2 and its GoTrue/PostgREST/realtime/
functions/storage graph, Riverpod 3.4.3, go_router 17.5 and unrelated transitive
updates. Preserve Auth/device acceptance baseline; migrate/test these as separate
changes with lifecycle benefit and migration evidence, not version-count cleanup.
SDK-constrained analyzer/test packages are not overridden. No clearly unused
app dependency was removed. Final outdated JSON has 38 entries (includes absent/
resolvable entries); pub's newer-package summary is 34, not 34 required upgrades.

## Native build systems

- iOS 15.0; Podfile has post_install deployment-target alignment custom logic.
  Podfile.lock only lists Flutter; plugins use SPM, but workspace/xcconfigs retain
  Pods references. SPM-only cleanup **DEFERRED**: current build works and Owner
  signing edits are in progress. Do not run pod deintegrate simply to hide warning.
- Owner-reported automatic Team/Xcode Managed Profile/Apple capability preserved.
  No signing, entitlement, callback, bundle identifier or console setting change.
- Xcode 27.0 (27A266a); Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20; Java 17.0.19
  installed, Java/Kotlin compilation target 11; NDK 28.2.13676358 retained.
  Flutter warns of future AGP/Kotlin support removal; follow-up coordinated native
  migration, no validation bypass. Kotlin-generated android/.kotlin cache ignored.

## Verification and Owner boundary

New SDK pub get/analyze/full suite: PASS, **513 PASS / 1 existing skip**, including
Auth, native start/cancel, SDK lifecycle/isolation, grade, bookmarks, Materials,
router and small-screen/2× tests. No additional UI changes after upgrade.
Helper fake-SDK checks: wrong version, non-stable rejection and argument forwarding
PASS. Owner native files unchanged byte-for-byte. Final Android debug and iOS simulator builds PASS. Initial iOS attempt failed during concurrent SDK artifact download;
retry after upgrade cache completion, not a claimed app regression. SDK upgrade
also ran an automatic project-wide pub upgrade at completion. Final diff review
caught that expansion; reconstructed the initially clean lockfile with only the
10 reviewed package blocks, ran pub get, and repeated analyze/full tests/both
builds on that final graph. No automatic broad upgrade is retained. Future SDK maintenance should run outside
the app directory and finish all cache operations before starting project commands.

MY school/grade root cause and P0/P1/P2 audit remain in
[Core App improvements](core-app-improvements.md#my-configured-state-and-core-mobile-audit--2026-09-21).
At this toolchain task's close, physical Profile acceptance had not yet been
reported. Owner subsequently confirmed App session restore PASS on iPhone Profile;
the disconnected Debug home-screen relaunch warning is a tooling constraint, not
a restore failure. See the current checkpoint for latest acceptance status.

Sources: [Flutter 3.47.5](https://github.com/flutter/flutter/releases/tag/3.47.5),
[upstream patch notes](https://github.com/flutter/flutter/blob/3.47.5/CHANGELOG.md),
[app_links migration](https://pub.dev/packages/app_links/changelog),
[preferences](https://pub.dev/packages/shared_preferences/changelog),
[iOS launcher](https://pub.dev/packages/url_launcher_ios/changelog),
[Android launcher](https://pub.dev/packages/url_launcher_android/changelog).
