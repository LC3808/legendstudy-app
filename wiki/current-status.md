# Current Status

Last reviewed: 2026-09-12

## Phase

**Phase 1 — Day 1 Flutter scaffold implemented and verified locally**

## Verified state

- GitHub repository exists: `LC3808/legendstudy-app`
- Visibility: Public during early development for multi-agent development convenience
- Default branch: `main`
- Repository initialized on 2026-09-12
- `AGENTS.md`, `CLAUDE.md`, `.gitignore`, and canonical repository-local `wiki/` seed exist
- Canonical reading order re-verified from repository contents: `AGENTS.md` → `wiki/index.md` → `wiki/current-status.md`
- Role split is current and consistent across the operating documents
- v1.0 scope is frozen for initial implementation; community, NEIS meals, advanced badges/recommendations, and early-admission acceptance prediction remain post-v1.0 unless explicitly promoted
- `legendstudy.com` remains accessible as the source site and currently exposes 1,673 archive items
- Representative 2020-era posts confirm older content patterns with multiple resources per post, including problem PDFs, answer/explanation PDFs, listening MP3, listening scripts, and grade-cut material
- Historical naming differs materially from newer curricula (for example, legacy mathematics `가형/나형`), so ingestion must preserve raw labels and support taxonomy versioning/uncertainty
- Flutter application scaffold implemented for iOS and Android with a Korean four-tab shell
- Supabase project/schema for LegendStudy has not yet been created or verified
- No production ingestion pipeline exists yet
- Static analysis and all 4 baseline tests pass; Android debug APK and iOS simulator builds pass

## Operating model

- Codex: main coder
- Claude: support coder / code reviewer
- ChatGPT: planning, architecture, specification, review
- Manus: execution, Git/build/deployment support; direct Supabase work only when specifically useful
- User: product owner and default direct executor of Supabase SQL/migrations

## Product constraints

- LegendStudy is completely separate from Muselry
- Simple WebView implementation is prohibited
- Actual code/DB/Git state must be cross-checked against wiki before decisions
- `legendstudy.com` remains the existing content source
- Normal app browsing should consume normalized structured data, not scrape the website at runtime

## Implementation baseline for first scaffold

- Flutter mobile app for iOS and Android
- Supabase planned for auth, normalized content data, bookmarks/history/profile sync, and backend support
- Router-based navigation
- Explicit state-management choice during scaffold implementation
- Feature-oriented code organization with presentation/domain/data separation where it adds value
- No Supabase credentials or production secrets committed to Git
- Initial UI must establish LegendStudy brand tokens and reusable design primitives before feature proliferation

## Immediate next steps

1. Review the Day 1 scaffold changes before merging the implementation branch.
2. Confirm final app identifiers before signing, OAuth, or store registration.
3. Define normalized data model v0.1 from representative current + legacy content.
4. Prepare Supabase schema/migrations for direct user execution in a separate issue.
5. Build ingestion prototype and validate representative posts across multiple years.
6. Re-check sitemap/RSS/robots/direct attachment behavior during ingestion implementation.

## Known open questions

- Final Flutter package/application identifiers
- Supabase project creation timing and environment naming
- Exact content taxonomy needed to represent historical posts consistently
- PDF/audio storage strategy: source-link preservation vs selective mirroring
- AdMob/IAP timing for v1.0
- Launcher icon replacement when original brand assets are supplied

## Day 1 implementation details

- Flutter 3.32.0 stable / Dart 3.8.0 actually used; dependencies locked.
- Riverpod 3.3.2 for dependency/state composition; go_router 17.0.0 for routing.
- Feature presentation folders, shared widgets, core configuration/theme, app composition.
  Real domain/data layers are deferred until business logic and data access exist.
- Home `/home`, Browse `/browse`, Saved `/saved`, Profile `/profile` are placeholders.
- Orange accents with white/light surfaces, Korean Material localization, scalable text.
- Android application ID/namespace and iOS bundle ID: temporary `dev.legendstudy.scaffold`.
  Dart package: `legendstudy_app`. No production identity is confirmed.
- No iOS development team or Android release signing configuration committed.
- Public `APP_ENV` via Dart defines; local config ignored; no backend secrets required.
- `flutter analyze`: passed with no findings.
- `flutter test`: 4 passed (startup/all tabs, direct route/error recovery,
  360×640 display at 2× text scaling, config default/provider override).
- `flutter doctor -v`: all installed toolchains reported healthy.
- Supabase remains uncreated/unverified; no schema or production ingestion changes.

## Platform verification (2026-09-12)

- `flutter build apk --debug`: passed; `build/app/outputs/flutter-apk/app-debug.apk`.
  First build installed Flutter-required Android NDK 26.3.11579264; build took 626s.
- `flutter build ios --simulator --debug`: passed; `build/ios/iphonesimulator/Runner.app`.
- Installed and launched `dev.legendstudy.scaffold` using `xcrun simctl install/launch`
  on iPhone 17 Pro simulator / iOS 26.5. Screenshot visually verified the Korean
  home page, orange CTA, and four-tab shell. No device signing was needed.
- `git diff --check`: passed; credential-pattern scan found no matches; ignore
  rules checked for local config, `.env`, Android signing properties and Apple keys.
- Initial sandbox restrictions on Git/SDK/simulator access were resolved through
  approved scoped tool execution; no remaining build environment blocker.

## Remaining manual / release work

- Review and push/merge the local implementation branch; no remote publication yet.
- Confirm production identifiers; configure signing only after confirmation.
- Provide original brand assets and replace generated Flutter launcher icons.
- Android device/emulator launch and signed physical iOS/release builds were not
  tested; perform those checks before distribution. Neither release readiness nor
  a deployed backend is implied by this scaffold.
