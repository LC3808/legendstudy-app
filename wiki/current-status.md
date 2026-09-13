# Current Status

Last reviewed: 2026-09-13

## Phase

**Day 5 UI shell implemented locally against approved UI/UX v1.1; validation below**

## Verified state

- GitHub repository exists: `LC3808/legendstudy-app`
- Visibility: Public during early development for multi-agent development convenience
- Default branch: `main`
- Repository initialized on 2026-09-12
- `AGENTS.md`, `CLAUDE.md`, `.gitignore`, and canonical repository-local `wiki/` seed exist
- Canonical reading order re-verified from repository contents: `AGENTS.md` → `wiki/index.md` → `wiki/current-status.md`
- Role split is current and consistent across the operating documents
- v1 scope now includes school/NEIS meals, timer/history, social auth and one-time ad removal per approved UI/UX v1.1. Community, advanced badges/AI recommendations, friends/ranking and admission prediction remain post-v1.
- `legendstudy.com` remains accessible as the source site and currently exposes 1,673 archive items
- Representative 2020-era posts confirm older content patterns with multiple resources per post, including problem PDFs, answer/explanation PDFs, listening MP3, listening scripts, and grade-cut material
- Historical naming differs materially from newer curricula (for example, legacy mathematics `가형/나형`), so ingestion must preserve raw labels and support taxonomy versioning/uncertainty
- Flutter application scaffold is merged to `main` via PR #2
- Day 1 squash merge commit: `873f4e1e0d131bb81dfa63766ff51966764ddd42`
- Day 2 production identity/brand baseline is merged to `main` via PR #4
- Day 2 squash merge commit: `5699af00c34d5101483f9f2750d2474ecd9aa686`
- Day 3 merged to main: `c16350c0a60fe1c6281234a7c2056cf02b54d9ad` (verified locally).
- Dedicated LegendStudy Supabase project created and initial migration applied.
  Deployment/runtime facts below come from the owner's post-deployment report;
  this documentation task did not reconnect to the database or repeat the tests.
- No production ingestion pipeline exists yet
- Day 2 static analysis and all 4 existing tests passed; Android debug APK and iOS simulator builds passed with the approved identity

## Operating model

- Codex: main coder + implementation lead
- Claude: UI/UX lead + support coder / code reviewer
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
- Dedicated Supabase backend deployed; Flutter initialization/repositories implemented in Day 4-A
- Router-based navigation using `go_router`
- Riverpod for dependency/state composition
- Feature-oriented code organization with presentation/domain/data separation where it adds value
- No Supabase credentials or production secrets committed to Git
- Initial UI establishes LegendStudy brand tokens and reusable design primitives before feature proliferation

## Immediate next steps

1. Review Day 5 UI shell against wiki/ui-ux-v1.md; local commit only, no push/merge.
2. Implement later Auth/NEIS/persistence/ads/IAP milestones only within their agreed
   scope. Day 8 introduces real timer behavior; Day 5 provides no timer logic.
3. Obtain detailed Claude screen artwork if needed; this branch follows the owner's
   approved v1.1 directive and does not invent an unavailable original document.

## Known open questions

- Apple/Google registration availability and signing setup for the approved identity
- Flutter environment configuration and future backend environment separation
- Curated historical taxonomy releases, reconciliation keys and publication/review thresholds
- Source-link-first adopted; any selective mirroring and retention policies require later review
- AdMob/IAP timing for v1.0
- Launcher icon replacement after a higher-resolution official icon is supplied (current canonical icon: 72×72)

## Application implementation details

- Flutter 3.32.0 stable / Dart 3.8.0 actually used; dependencies locked.
- Riverpod 3.3.2 for dependency/state composition; go_router 17.0.0 for routing.
- Feature presentation folders, shared widgets, core configuration/theme, app composition.
  Day 4-A adds minimal content/personal domain/data and Riverpod composition.
- Home /home and Materials /materials retain repository-backed states. Study
  /study is idle UI; MY /my has saved/school/recent child shells. See ui-ux-v1.md.
- Orange accents with white/light surfaces, Korean Material localization, scalable text.
- Owner-approved Android application ID/namespace/Kotlin package and iOS Runner bundle ID:
  `com.legendstudy.app`. iOS RunnerTests uses `com.legendstudy.app.RunnerTests`.
  Dart package remains `legendstudy_app`; Android/iOS display name is `레전드스터디`.
- No iOS development team or Android release signing configuration committed.
- APP_ENV/SUPABASE_URL/SUPABASE_PUBLISHABLE_KEY via Dart defines; local config
  ignored; only public client config, never backend secrets.
- `flutter analyze`: passed with no findings.
- `flutter test`: 24 passed, including routing/large-text/configuration,
  repository/Auth/UI states and six Day 5 navigation/semantics tests; actual iOS
  Supabase integration smoke also passed on the new shell.
- `flutter doctor -v`: all installed toolchains reported healthy.
- Supabase initial schema is applied; actual Flutter initialization and public
  reads are verified in the final smoke below. No ingestion exists.

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
- Replace generated Flutter launcher icons after receiving a higher-resolution version of the supplied canonical 72×72 icon.
- Android device/emulator launch and signed physical iOS/release builds were not tested; perform those checks before distribution.
- Release readiness is not implied by the scaffold or Day 4-A foundation.

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


## Historical pre-deployment: Day 3 unified model (2026-09-12)

- Same official checkout/branch: `~/development/legendstudy-app`,
  `codex/day-3-data-model-v01`; LegendStudy origin verified. Prior review fix
  `9a45b08d80585b23f17c87dd40d693fbae849258` remains intact; separate follow-up commit.
- **Supabase project not created/linked, DB unapplied, zero SQL execution** locally
  or remotely. Existing initial migration revised; no second migration or data import.
- Ten tables/RLS tables, 16 policies, 10 non-constraint indexes, 8 triggers and
  2 invoker functions; 74 migration statements. Public content_items now owns
  identity/routes/publication, resources and personal references support all types.
- Exams shared content_item_id PK + generated type discriminator/composite FK;
  occurrence/resource same-content FK chain retains cross-exam protection. No
  duplicate exam publication flag/source identity. Parent inactivity hides children.
- Home uses latest known source publication/modification, not ingestion timestamps;
  unified search returns parent cards, exam filters join only when needed.
- Source examples checked: recent/historical exams, English practice PDF, historical
  admissions column and university essay PDFs. Only page text/links inspected.
- At the unified-model commit, pglast 8.4 / PostgreSQL 18.4 grammar passed SQL +
  two PL/pgSQL bodies. Fifteen
  SELECT-only inspection statements parsed, none executed. Six regression methods
  pass, including 45 schema mutations, four personal-target/policy mutations, two
  contract mutations and three inspection mutations; harmless reordering accepted.
- `git diff --check` passes; no credential-pattern matches. Flutter/platform/UI/
  dependencies unchanged; Flutter tests/builds not rerun for schema/docs/checker work.
- RLS/runtime/catalog/ACL/trigger/PostgREST/performance acceptance remains pending
  separately authorized LegendStudy setup and explicit project-ref verification.
  Verified mapping protection remains by ingestion contract, not a DB override.
- Notifications stay v1.0 with later schema. Article bodies/university metadata/full
  text search remain deferred; source/title/summary evidence supports initial search.
- No implementation blocker for this draft. No Supabase CLI/DB connection, unrelated
  project access, remote Git push or merge. Independent re-review remains future work.

## Historical pre-deployment: final checker hardening (2026-09-13)

- Owner-supplied Claude Final Delta Review verdict: **B. minor corrections before
  merge**. Strengthened the offline gate on the same Day 3 branch against b28c003;
  independent re-review of this follow-up remains pending.
- Migration SQL byte-for-byte unchanged; schema counts remain 10 tables, 16 policies,
  10 non-constraint indexes, 8 triggers, 2 functions and 74 migration statements.
- Slug NOT NULL/global UNIQUE/regex, source URL collision guard, four default-private
  publication flags, date/numeric ranges and critical enum/order CHECKs are locked.
- Checker and 14 test methods pass: 106 unsafe mutations rejected, including 52 new
  scalar cases. Benign formatting/comments and equivalent UNIQUE structure pass.
  Sixteen future SELECT-only inspection statements parsed, not executed.
- README adds three generated-column fallback options only after observed target
  failure; orphan active exam inspection added without changing schema enforcement.
- git diff --check passes. Supabase still not created/linked, DB unapplied, SQL/DB
  execution absent. No Flutter edits, remote push, merge or other-project access.
- No checker/schema mismatch or blocker found. Next: user push and commit/PR #5
  final review, then separately authorized LegendStudy project/runtime work.

## Current deployment and runtime verification (recorded 2026-09-13)

Evidence: owner-provided post-deployment results, not a new DB inspection by Codex.
Earlier pre-deployment entries above are historical and superseded by this record.

| Item | Recorded state |
| --- | --- |
| Project | LegendStudy, completely separate from Muselry |
| Project Ref | stlhijzpjfgwwdgunlsd |
| Region | ap-northeast-2 (Seoul) |
| PostgreSQL | 17.6 |
| Applied migration | supabase/migrations/20260912000100_initial_content_schema.sql |
| Application result | Success. No rows returned |
| Inventory | 10 tables, 16 policies, 10 non-constraint indexes, 8 triggers, 2 trigger functions |
| RLS | enabled on all 10 tables; FORCE RLS false |
| Cleanup | all 10 application tables have 0 rows after runtime fixtures were removed |

Prerequisites confirmed: auth.users/auth.uid(), anon/authenticated/service_role,
service_role BYPASSRLS, deployer REFERENCES on auth.users, and no application-table
or set_updated_at/set_viewed_at collisions before application.

Generated feed_updated_at, exams.content_type discriminator and sort_date were
created/calculated successfully on PostgreSQL 17.6; no fallback is needed.
Anon REST reads active content; direct inactive-slug lookup returns []. Source_posts
and ingestion_quarantine return HTTP 401 permission denied for anon; authenticated
SELECT privilege is absent. Anon profiles access also returns HTTP 401.

Two test users obtained real JWTs by password grant. Both created their own
profiles; A reads A and B cannot read A (empty result). A creates/reads a bookmark;
B cannot read it and spoofing A's user_id returns HTTP 403 RLS violation. Recent
views isolate A/B; repeated (user_id, content_item_id) upsert preserves row ID,
creates no duplicate and advances viewed_at, confirming the PostgREST/clock path.

Taxonomy/content visibility remains structurally correct: the reported inactive
master is hidden while SQL policies retain active raw occurrence/resource visibility.
The report does not provide a distinct REST/JWT trace for the full taxonomy case;
do not upgrade that structural result to exhaustive client-path behavioral coverage.
SQL Editor SET ROLE is not authoritative RLS evidence; use actual REST/JWT clients.

Zero-row cleanup covers source_posts, content_items, exams, subjects, exam_subjects,
resources, profiles, bookmarks, recent_views and ingestion_quarantine. Auth test users
A/B may be retained for later Auth/OAuth tests; their deletion is not claimed.
No passwords, JWTs or API keys are stored here.

The applied initial migration is immutable, including its historical DRAFT comments.
All future DB changes require a new migration. The Day 3 record predates Flutter
integration code; see Day 4-A below for the current client verification boundary.

## Day 4-A integration foundation (2026-09-13)

- Started from post-deployment main merge 5af7905 on codex/day-4-supabase-foundation.
- supabase_flutter 2.15.4 resolved on Flutter 3.32.0/Dart 3.8.0; existing Riverpod
  3.3.2/go_router 17.0.0 remain locked. http 1.6.0 + SDK integration_test for tests.
- Binding/config validation → awaited Supabase.initialize → injected client → runApp.
  Missing/invalid config gives a clear error state; no production data fallback.
- ContentRepository: exact 11-column projection, active filter, feed DESC NULLS LAST
  then id DESC, bounded token search, nullable slug result and valid empty lists.
- AuthStatus stream exposes signed-out/authenticated identity, with SDK errors as
  AsyncError. Personal reads signed out return null/[]/false; writes reject with
  SignedOutException before network. Interfaces derive owner from current session.
- Profiles upsert only id/display_name/grade_level; bookmarks ignore duplicates;
  recent touch sends only user_id/content_item_id. List reads are capped at 100.
- Home/Browse show loading/empty/error/data and search input without navigation,
  brand or card redesign. Saved/Profile UI and login/OAuth remain future work.
- At the initial implementation commit no local public key was available, so
  actual initialization/read was pending; the final smoke below closes that gap. Opt-in integration_test/supabase_smoke_test.dart is ready;
  existing Day 3 runtime results remain owner-reported, not re-run by Flutter tests.
- DB schema, migrations and ingestion unchanged; no Supabase SQL, push or merge.

### Day 4-A validation

- flutter pub get / flutter analyze: PASS, no analysis findings.
- flutter test: 18 PASS (4 existing + 14 new), including mock HTTP projection,
  search escaping, personal payload/ownership guard, auth event, UI state/retry.
- Android debug APK and iOS simulator debug builds: PASS without defines.
  NDK pinned to 27.0.12077973 for the added native plugins; CocoaPods integration
  and lockfile committed. No signing identity or release secret introduced.
- iPhone 17 Pro / iOS 26.5: installed and launched com.legendstudy.app; screenshot
  inspected, both missing config fields shown, existing four-tab shell intact.
- At initial implementation, configured smoke was NOT RUN due to missing local
  public config. Superseded by the successful final smoke below.
- git diff --check, credential-pattern scan and ignored config/signing checks: PASS.
  No server keys, real JWTs or passwords found; service_role mentions in docs/SQL
  are role names/security policy, not credentials. Unit sessions are synthetic.
- Initial migration byte-identical to Day 3; SHA-256
  2a2c55cfc542e961fe2356e211141b3a3df0d0c47044efac3f8360dd1f360a2b.
- Local commit only; no push/merge. Next: local smoke and Claude UI/UX v1 → Codex UI.

## Day 4-A final actual Supabase smoke (2026-09-13)

- Base implementation commit: 033ec667b20b0bf3e0fa47a8ece335d2a0af79e2.
  Same codex/day-4-supabase-foundation branch; initial worktree verified clean.
- Actual Supabase.initialize PASS on iPhone 17 Pro / iOS 26.5. Dedicated target
  stlhijzpjfgwwdgunlsd.supabase.co; public key injected from a temporary local
  define file, never source, fixture, Wiki, logs or Git.
- Actual ContentRepository GET /rest/v1/content_items PASS, 0 rows as expected.
  Read-only transport verifies the dedicated host/path/method and HTTP 200 for
  three requests (direct repository, Home, Browse search); no headers/tokens logged.
- Home and Browse: loading → empty PASS. Browse uses submitted search text to
  exercise the real repository; empty query correctly shows its input prompt.
  Transport gating makes loading observable; all responses come from the real DB.
- Auth signedOut PASS with an active provider subscription, matching UI usage.
  Initial test harness awaited an unobserved provider and timed out; keeping its
  subscription fixed the harness. Production Auth implementation is unchanged.
- Signed-out profile/bookmark/recent reads return null/[]/false; all tested writes
  raise SignedOutException without any network request or crash. No automatic login.
- No SQL, inserts, schema/migration changes or UI/UX implementation. Only public
  read requests were sent. This smoke does not re-query all ten tables or verify
  OAuth providers; the owner's ten-table zero-row baseline is preserved by no writes.
  No school/meal/timer database is introduced.

- Final regression: flutter pub get/analyze PASS; 18 unit/widget tests PASS;
  one actual iOS integration smoke PASS. Android debug and iOS simulator debug
  builds PASS. Configured normal app installed/launched separately; Home empty
  screenshot visually checked with no settings/network error.
- git diff --check, credential-pattern scan, exact supplied-key scan and local
  config ignore checks PASS. Initial migration byte-identical; only integration
  test and these two Wiki documents changed. No credentials committed.
- No remaining blocker; local follow-up commit only, no push/merge.

## 2026-09-13 — Reverification with owner-managed external config

- Re-ran on codex/day-4-supabase-foundation from clean 5dcded2 using
  --dart-define-from-file=/Users/woojinchang/legendstudy-local.json.
  The owner-managed file remains outside the repository and was not modified;
  its credential value is not copied into these documents, tests or Git.
- Actual iPhone 17 Pro / iOS 26.5 smoke PASS: Supabase initialization, dedicated
  project content GET x3 HTTP 200, content_items [], Home/Browse loading → empty,
  auth signedOut; personal reads empty and writes SignedOutException without network.
- Full regression PASS: pub get, analyze, 18 unit/widget tests, one actual iOS
  integration test, Android debug build and iOS simulator debug build. Both builds
  used the same external configuration. git diff --check PASS.
- Credential-pattern and exact external-key scans PASS for repository candidates;
  local-config ignore checks PASS. Initial migration remains byte-identical.
  No app/test code, DB/schema/migration/SQL, imports or UI changes in this rerun.
- Documentation-only follow-up local commit; no push/merge. No blocker.

## Day 5 — UI shell (2026-09-13)

- Verified clean main at Day 4-A merge 20ae5bf; branch codex/day-5-ui-shell.
- Added canonical ui-ux-v1.md from the approved owner directive; registered reading
  order; updated product scope, durable decisions, architecture and design tokens.
- Bottom tabs 홈 / 자료 / 학습 / MY; Saved reused at /my/saved, school/recent child
  screens, root material detail shell and legacy redirects. Tab stacks are retained.
- Home section skeleton keeps real recentContentProvider; Materials keeps real
  search. Empty backend is normal. Study is idle, MY auth-aware; no fake study/meal
  data, ads or payment. All existing data repositories remain unchanged.
- No DB/schema/migration/SQL, OAuth, NEIS, timer runtime, Ads/IAP or ingestion.

### Day 5 validation

- flutter pub get/analyze PASS; 24 unit/widget tests PASS (18 retained + 6 new).
  Includes exact bottom labels, MY Saved and stack/back behavior, persistent search,
  root detail push, legacy/new routes, guest school entry, Auth variants and semantics.
  Existing 360×640 / 2× text-scale coverage remains passing across all four tabs.
- Android debug and iOS simulator debug builds PASS. iPhone 17 Pro / iOS 26.5
  launched with owner-managed external public config; Home/Materials/Study/MY and
  MY→Saved visually inspected. No credential is recorded in code or these docs.
- Actual Supabase read-only smoke PASS: dedicated content GET x3 HTTP 200, [];
  Home/Materials loading→empty, signedOut and guarded personal operations unchanged.
- git diff --check, credential-pattern/exact-key scans and ignore checks PASS.
  Initial migration byte-identical; data repository implementations and dependencies
  unchanged. No SQL, writes, OAuth, NEIS, ads/IAP, timer runtime or ingestion.
- Source boundary: no separate Claude full-text design file was supplied; the
  official spec records the user's approved v1.1 directive without claiming a copy
  of an unavailable original. No implementation blocker; detailed art can follow.
- Local commit only; no push or merge.


## Day 5 — Official brand correction (2026-09-13)

- Owner supplied three canonical PNG originals under assets/brand/source/:
  legendstudy_app_icon_source.png, legendstudy_square_logo_source.png and
  legendstudy_wordmark_source.png. Bytes preserved; SHA-256 in assets/brand/README.md.
- Home no longer renders the temporary Material book icon or Text wordmark.
  It uses generated/legendstudy_wordmark_header.png, an exact 312×55 crop of
  the supplied banner, at up to 280 logical pixels wide with header semantics.
  System fonts, orange palette, navigation/layout and Supabase code are unchanged.
- Launcher canonical source is registered (72×72). Platform replacement deferred
  until a higher-resolution official original is available; existing launcher
  placeholders are not approved artwork. No fabricated/upscaled replacement.
- flutter analyze PASS; all 24 tests PASS, including image/header semantics and
  360×640/2× text regression. Android debug and iOS simulator builds PASS using
  the external owner-managed configuration. iPhone 17 Pro / iOS 26.5 installed,
  launched and Home screenshot visually checked with the official wordmark.
- Source hashes/crop pixel identity, Android asset packaging, credential-pattern
  and exact-key scans, git diff --check PASS. No DB/SQL/migration or new services.
  Prior actual Supabase smoke remains valid evidence; not rerun for this asset edit.
- Follow-up local commit on codex/day-5-ui-shell; 56ecec5 preserved. No push/merge.
