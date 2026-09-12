# Current Status

Last reviewed: 2026-09-12

## Phase

**Phase 1 — Day 3 Data Model v0.1 and draft SQL designed locally, not applied**

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
- Flutter application scaffold is merged to `main` via PR #2
- Day 1 squash merge commit: `873f4e1e0d131bb81dfa63766ff51966764ddd42`
- Day 2 production identity/brand baseline is merged to `main` via PR #4
- Day 2 squash merge commit: `5699af00c34d5101483f9f2750d2474ecd9aa686`
- Schema designed locally; no Supabase project/migration has been applied by this task.
  Existing remote project/schema state has not been queried or verified.
- No production ingestion pipeline exists yet
- Day 2 static analysis and all 4 existing tests passed; Android debug APK and iOS simulator builds passed with the approved identity

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
- Router-based navigation using `go_router`
- Riverpod for dependency/state composition
- Feature-oriented code organization with presentation/domain/data separation where it adds value
- No Supabase credentials or production secrets committed to Git
- Initial UI establishes LegendStudy brand tokens and reusable design primitives before feature proliferation

## Immediate next steps

1. Review Day 3 schema/RLS/idempotency (ChatGPT first, Claude recommended); local commit only.
2. Resolve model/open questions and obtain explicit owner approval before any SQL execution.
   User applies only to a verified separate LegendStudy Supabase project in a later task.
3. Build ingestion prototype and validate representative posts across multiple years.
4. Re-check sitemap/RSS/robots/direct attachment behavior during ingestion implementation.
5. Add original LegendStudy brand assets and replace placeholder launcher icons when the assets are committed to the repository.
6. Register the approved application identifier with Apple/Google and configure signing/OAuth in later platform-integration tasks.

## Known open questions

- Apple/Google registration availability and signing setup for the approved identity
- Supabase project creation timing and environment naming
- Curated historical taxonomy releases, reconciliation keys and publication/review thresholds
- Source-link-first adopted; any selective mirroring and retention policies require later review
- AdMob/IAP timing for v1.0
- Launcher icon replacement when original brand assets are supplied

## Application implementation details

- Flutter 3.32.0 stable / Dart 3.8.0 actually used; dependencies locked.
- Riverpod 3.3.2 for dependency/state composition; go_router 17.0.0 for routing.
- Feature presentation folders, shared widgets, core configuration/theme, app composition.
  Real domain/data layers are deferred until business logic and data access exist.
- Home `/home`, Browse `/browse`, Saved `/saved`, Profile `/profile` are placeholders.
- Orange accents with white/light surfaces, Korean Material localization, scalable text.
- Owner-approved Android application ID/namespace/Kotlin package and iOS Runner bundle ID:
  `com.legendstudy.app`. iOS RunnerTests uses `com.legendstudy.app.RunnerTests`.
  Dart package remains `legendstudy_app`; Android/iOS display name is `레전드스터디`.
- No iOS development team or Android release signing configuration committed.
- Public `APP_ENV` via Dart defines; local config ignored; no backend secrets required.
- `flutter analyze`: passed with no findings.
- `flutter test`: 4 passed (startup/all tabs, direct route/error recovery,
  360×640 display at 2× text scaling, config default/provider override).
- `flutter doctor -v`: all installed toolchains reported healthy.
- Supabase remains uncreated/unverified by this task; Day 3 draft schema exists but is not deployed. No production ingestion exists.

## Historical Day 1 platform verification (2026-09-12)

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

## Review / merge status

- PR #2 was reviewed against routing, Riverpod setup, theme/configuration, secret handling, tests, and wiki consistency.
- No blocking defect was found for the Day 1 scaffold.
- PR #2 was squash-merged into `main` on 2026-09-12.
- PR #4 was reviewed against Android/iOS identity configuration, display names, brand-asset conventions, secret/signing boundaries, and wiki consistency.
- No blocking defect was found for the Day 2 identity/brand baseline.
- PR #4 was squash-merged into `main` on 2026-09-12.
- No GitHub Actions workflow is configured yet; merge verification relies on the recorded local analyze/test/build results plus repository review.

## Remaining manual / release work

- Register the approved identifier with Apple/Google and configure signing in a separate task.
  Registration availability has not been checked or claimed; no conflict was reported by local builds.
- Provide original brand assets and replace generated Flutter launcher icons.
- Android device/emulator launch and signed physical iOS/release builds were not tested; perform those checks before distribution.
- Neither release readiness nor a deployed backend is implied by this scaffold.

## Day 2 verification (2026-09-12)

- Official working checkout: `~/development/legendstudy-app`; origin verified as
  `https://github.com/LC3808/legendstudy-app.git`.
- Flutter 3.32.0 / Dart 3.8.0 used; `flutter pub get` and `flutter analyze` pass;
  `flutter test --reporter expanded`: all 4 tests pass.
- `flutter build apk --debug` and `flutter build ios --simulator --debug`: pass.
- APK metadata verifies package `com.legendstudy.app`, launch activity
  `com.legendstudy.app.MainActivity`, and application label `레전드스터디`.
- Built iOS `Runner.app/Info.plist` verifies `CFBundleIdentifier=com.legendstudy.app`
  and `CFBundleDisplayName=레전드스터디`. All Runner and RunnerTests configurations
  inspected directly in the Xcode project (Debug, Release, Profile).
- Repository source scan finds the old identifier only in historical Day 1
  current-status/log entries; none in active platform/runtime configuration.
- `git diff --check` passes. No secrets, signing material or development team added.
- `assets/brand/README.md` defines expected originals and `assets/brand/source/`
  is retained for unmodified source files. No original logo binaries are available;
  existing Flutter launcher icons and all UI palette tokens remain unchanged.
- No new features, Supabase project/schema, OAuth, AdMob, IAP or store registration.
- No implementation/build blocker. Apple signing, Google/Apple/Kakao OAuth,
  final launcher icon and store registration remain manual follow-up work.


## Day 3 design / verification (2026-09-12)

- Branch: `codex/day-3-data-model-v01`, based on updated main in
  `~/development/legendstudy-app`; origin verified as the LegendStudy repository.
- Draft: `supabase/migrations/20260912000100_initial_content_schema.sql`.
- Eight proposed tables: source_posts, exams, subjects, exam_subjects, resources,
  profiles, bookmarks, recent_views. No ingestion_runs or v2 feature tables.
- Versioned/raw taxonomy, calendar versus academic year, same-exam resource FK,
  source-link-first URLs, stable ingestion keys and user-owned upsert rules documented.
- Four active public content tables, backend-only provenance, own-row personal
  policies; explicit grants and RLS on all eight tables. 15 policies, 11 additional
  indexes, two invoker clock functions and seven triggers in the draft.
- Three source-grounded cases documented: recent 2026 May exam, legacy math 가형/나형,
  English audio + script; separate calendar/academic-year example also verified
  against source page text. No attachment binaries downloaded or validated.
- Offline pglast 8.4 / PostgreSQL 18.4 parser accepted 67 migration statements and
  two PL/pgSQL function bodies; 8 future SELECT-only inspection statements parsed.
  Checked-in structural checker passes; five injected safety regressions were all
  detected (RLS/owner omission, client content write, weakened FK, content cascade).
  Credential-pattern scan found no matches. No SQL statements/function bodies executed.
- `git diff --check` passes. Flutter/platform/brand/dependency files unchanged;
  Flutter tests/builds not rerun for this SQL/documentation-only task.
- RLS runtime, actual FK/trigger behavior, PostgREST upserts, extension availability
  and query plans remain untested until separately approved DB validation.
- No Supabase CLI application/reset/push, DB connection, project creation/linking,
  remote Git push or merge. No keys, credentials, auth provider or storage setup.
- Review guidance and future validation/rollback considerations are in
  `supabase/README.md` and `wiki/database.md`. No design-task blocker.
