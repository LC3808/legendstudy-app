# Current Status

Last reviewed: 2026-09-13

## Phase

**Day 7 Home refinement verified; D-Day persistence requires storage approval. Runtime closeout remains in progress.**

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

1. Finish the remaining Day 7 runtime gate. Owner has reported actual JWT/RLS
   storage and fixture cleanup PASS, server secret registration, neis deployment,
   deployed school/meal/empty smoke and Flutter guest search/selection/Home empty PASS.
   These are owner-reported results, not newly rerun during attribution refinement.
2. Distinguish authenticated Flutter persistence verification from the completed
   REST/JWT harness before declaring the full gate complete. Resolve local CLI
   metadata cleanup separately; do not commit supabase/.temp/.
3. OAuth, timer, public resource link_status eligibility and PDF viewer remain
   separate milestones. Local commits only; no push, PR or merge authorized.

## Known open questions

- Apple/Google registration availability and signing setup for the approved identity
- Flutter environment configuration and future backend environment separation
- Curated historical taxonomy releases, reconciliation keys and publication/review thresholds
- Source-link-first adopted; any selective mirroring and retention policies require later review
- AdMob/IAP timing for v1.0
- Launcher icon production/restoration from the official memo/document + pencil symbol in the square brand reference; legacy 72×72 favicon is not the canonical basis

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
- `flutter test`: 56 passed, including routing/large-text/configuration,
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
- Produce/restore a high-resolution version of the square reference’s memo/document + pencil symbol in a future brand task before replacing Flutter launcher icons. Do not enlarge the low-resolution reference into a final icon.
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
- Corrected launcher design basis: the orange memo/document + pencil symbol at
  the top of legendstudy_square_logo_source.png. The 72×72 “study” image is a
  legacy favicon, not a launcher canonical source. High-resolution production/
  restoration is deferred to a later brand task; no low-resolution enlargement
  into final launcher art. Platform placeholders remain unchanged.
- flutter analyze PASS; all 24 tests PASS, including image/header semantics and
  360×640/2× text regression. Android debug and iOS simulator builds PASS using
  the external owner-managed configuration. iPhone 17 Pro / iOS 26.5 installed,
  launched and Home screenshot visually checked with the official wordmark.
- Source hashes/crop pixel identity, Android asset packaging, credential-pattern
  and exact-key scans, git diff --check PASS. No DB/SQL/migration or new services.
  Prior actual Supabase smoke remains valid evidence; not rerun for this asset edit.
- Follow-up local commit on codex/day-5-ui-shell; 56ecec5 preserved. No push/merge.


## Day 5 — Brand asset role correction (2026-09-13)

- Owner clarified the square reference's memo/document + pencil symbol as the
  official core symbol and future launcher design basis. The 72×72 “study” image
  is a legacy favicon only; source filenames, bytes and Home derivative unchanged.
- Home wordmark size/spacing and UI hierarchy are provisional. Future refinement:
  smaller wordmark consideration, header/first-section continuity, clearer outline/
  divider and text contrast, stronger section separation without excessive orange.
- Documentation-only follow-up after 9abbb08. No UI/function/navigation/Supabase,
  launcher or DB changes. High-resolution symbol production/restoration deferred.
- git diff --check PASS; changed-file scope and preserved asset bytes verified.
  Flutter tests/builds not rerun because no implementation or build inputs changed.
  Prior brand implementation validation remains recorded above. No push/merge.


## Day 6 entry — P0 UI refinement (2026-09-13)

- Started clean main at 7e241e8, verified equal to freshly fetched origin/main.
  New branch codex/day-6-materials-search; Day 5 review verdict supplied by owner:
  B. READY AFTER MINOR UI FIX. No routing or backend contract changes.
- Home search surface and Materials keyboard-submit/clear UI refined; IME-aware
  200-character input limit retained. No automatic search or forced branch focus.
- Cards use neutral type badges, bounded title/summary and optional real date row;
  fake CTA removed. Exam metadata/resources remain later Day 6 contract work.
- P0 validation: flutter analyze PASS; 26 unit/widget tests PASS; git diff --check
  PASS. UI tests cover navigation, submit/clear, tab/detail return state, type/date
  cards and 360×640/2× scaling. No push/merge; P1 refinement follows.


## Day 6 entry — P1 hierarchy and final validation (2026-09-13)

- pagePadding 20, sectionGap 24, divider #E5E5E5 and separate cardBorder #DCDCDC.
  SectionHeader 15sp/w700 with top 24/bottom 8; card/chip radii and smallGap retained.
- Official Home wordmark width 210, subtitle removed; centered loading spinner.
  All NavigationBar tabs have outlined/filled icon pairs and selected label weight;
  indicator #FFE3B0. Materials article icons replace the identical search glyph.
- Deferred: D-Day/Today Study/Recent Views/MY redesign, Saved/bookmark, support
  route/IAP, timer/NEIS/OAuth/Ads/ingestion/DB. MY support prominence unchanged;
  future ListTile presentation can accompany its real feature milestone.
- Final flutter analyze PASS; all 26 tests PASS. Home entry/submit/clear, branch
  state/detail-back, detail without NavigationBar, four labels/MY Saved and
  360×640/2× text coverage pass. Android debug/iOS simulator builds PASS with
  owner-managed external config. iPhone 17 Pro / iOS 26.5 Home and Materials
  inspected; search surface navigation and selected tab confirmed visually.
- git diff --check and credential scan PASS. Router bytes, domain/data contracts,
  Supabase/config, source/generated artwork and dependencies unchanged from baseline.
  No SQL or new backend features; actual Supabase smoke not rerun for UI refinement.
  Integration test entry label updated to the new UI without changing its contract.
- No blocker or pending owner decision for this refinement. Day 6 actual feature
  development can start within its separately defined contract; it is not claimed
  implemented here. Two local commits, no push/merge.


## Day 6 Materials/Search/Detail implementation (2026-09-13)

- Continued clean codex/day-6-materials-search from 027ba1d, preserving refinement
  commits 5a3b27d/027ba1d and official main baseline 7e241e8. Feature commit separate.
- Actual public projections of content_items, exams, exam_subjects, subjects and
  resources returned HTTP 200/0 rows on the dedicated LegendStudy project before
  implementation. Actual names are file_extension/file_size, not proposed aliases.
- Type-only, keyword-only and combined search with independent type clearing;
  Home shortcuts use real types. Existing query guards, public projection and
  ordering retained. Four tabs, root detail, MY nesting and redirects retained.
- Pure Dart ExamMetadata/ContentResource and small ExamRepository/ResourceRepository
  boundaries. Exam list batched; resources paged in display_order/id ASC. Optional
  left joins preserve mapped → raw historical → general subject fallback.
- Native detail shows a single title, type, real metadata/summary/source clocks,
  resources and external source/resource actions. Async loading/empty/error/retry;
  no resources is normal, including columns. No fake production content.
- url_launcher 6.3.2 changed from transitive to direct dependency only. HTTP(S)
  externalApplication open, landing_page source first, otherwise verified file URL
  then source. Launch false/exception produces safe feedback; remote success not claimed.
- Known contract limit: private link_status prevents broken/restricted discrimination.
  UI says availability unconfirmed. Guaranteed health-based disabling needs a separate
  public eligibility/publication contract; no schema/grant change was attempted.
- Final analyze PASS; 56 unit/widget tests PASS (26 retained/adapted + 30 new),
  covering type/keyword/filter state, search guards, exam nulls/year distinction,
  left fallback, resource paging/URL policy, detail states/retries, direct back,
  root detail without tabs, return state, 360×640/2× text and external opener outcomes.
- Android debug and iOS simulator builds PASS using owner-managed external config.
  iPhone 17 Pro / iOS 26.5 normal app installed/launched; Home exam shortcut,
  type-only empty result and type retention across Study/Materials visually checked.
- Actual Flutter Supabase smoke PASS: eight public GETs HTTP 200, all empty as
  expected (recent/Home/search/type/combined/slug/exam/resource left projection).
  Initialization, Home/Materials loading→empty, signedOut and personal guards PASS.
  No INSERT/UPDATE/DELETE/SQL or login. Five-table projection preflight also PASS.
  This proves empty-query compatibility, not populated production join/file behavior.
- diff/security/ignore and exact external-key scans PASS. Initial migration and all
  Supabase SQL/schema files unchanged. Auth/personal/config and artwork unchanged.
  No fixture ingestion, WebView, native PDF viewer, bookmark UI, OAuth, NEIS, timer,
  AdMob or IAP changes. No push, PR creation or merge.
- Ready for Day 7 scope planning/review; native PDF viewing and populated-data/runtime
  file access remain future verification. Link-health limitation must remain explicit.


## Day 7 preflight — stopped before feature implementation (2026-09-13)

- Started from clean 30cdcb47 on new codex/day-7-school-neis. Day 6 history retained.
- profiles has no school storage contract. Initial migration/client verified;
  public read of proposed columns returned HTTP 400/42703 on LegendStudy.
  Owner Day 7 STOP conditions 2/3 apply: no code assumes new DB fields.
- See day-7-school-storage-proposal.md: two nullable NEIS identifier columns on
  profiles, pair CHECK, restricted column grants, unchanged owner RLS; exact
  proposed SQL, validation, compatibility and rollback. NOT APPROVED/APPLIED.
- Only official schoolInfo sample identity fields checked (one public sample row).
  NEIS client-key exposure/meal API review and full smoke remain pending.
- No School/Meal implementation, guest persistence or authenticated save. No SQL,
  production write, migration file, push, PR or merge. Day 6 tests/build evidence
  remains unchanged; this documentation-only task does not rerun Flutter builds.
- Next: owner review/approval and verified application, or explicit guest-only scope.
  Day 7 incomplete; Day 8 readiness is not claimed.


## Day 7 school migration preparation (2026-09-13)

- Owner approved profiles school identifier storage. Separate commit after 4078017;
  production application remains owner-only and has NOT occurred in this task.
- Added 20260913000100_profile_school_selection.sql: nullable TEXT pair, validated
  profiles_neis_school_pair CHECK (NULL equivalence, trimmed/nonempty 1..32 values),
  authenticated INSERT/UPDATE on those columns only. No policy/table-level/anon
  grant or service-role change. No row DML/backfill. Existing profile payload valid.
- Official schoolInfo sample rechecked: J10 / 7530932. No fixed-format regex; 32 is
  a defensive app limit, not a claimed NEIS code-length specification.
- Owner scripts: profile_school_before.sql and profile_school_after.sql. Compare
  original-column fingerprint/row count before/after without concurrent writes;
  inspect types/nullability/CHECK/ACL/RLS. REST/JWT behavior remains separately pending.
- pglast 8.4 / PostgreSQL 18.4 grammar PASS (target is PG17.6; no runtime execution).
  New AST scope/check/grant gate and five unsafe mutations PASS. Existing checker
  and 14 tests PASS. Owner SQL block identical to migration. diff/security PASS.
- Initial migration SHA-256 unchanged; Flutter code/dependencies unchanged. No
  production SQL/write, push, PR or merge. database.md does not claim deployment.
- Resume Day 7 after owner deployment and verification results; NEIS client-key
  exposure/meal API gates still require review before implementation proceeds.


## Day 7 School / NEIS resumed implementation (2026-09-13)

- Started at 7601b4e on codex/day-7-school-neis. Owner reports production school
  migration applied and validated: nullable TEXT pair/CHECK/grants/owner policies,
  zero partial pairs and zero profile rows. Storage STOP lifted by owner. See
  database.md for the reported deployment versus unperformed client verification.
- Profile model/read projection extended; separate session-owned school pair
  save/clear omits name/grade, while existing profile upsert omits school fields.
- Pure Dart School/Meal and small repository; Flutter calls only dedicated
  /functions/v1/neis. Official NEIS terms Article 7 prohibit sharing/publication
  of issued keys, so NEIS_API_KEY exists only in the prepared server-side function.
  No fallback to limited unauthenticated samples in the production app.
- /my/school keeps its nested route and one AppBar title. Submit search, up to
  100 results with refinement notice, school type/address, selected state, immediate
  authenticated save and retry. Guests select in memory; permanent-save action
  explains login requirement. No OAuth or automatic application login added.
- Home meal card: no-school/loading/data/empty/error+retry; source attribution,
  maximum two menu lines. br variants/newlines normalized, allergy/source text
  preserved. Korea UTC+9 calendar date, provider-level reuse, school/date changes
  invalidate; date checked every 30 seconds (no network per tick). Auth changes
  clear owner state and late writes cannot restore a previous user's selection.
- Validation: analyze PASS; 77 Flutter tests PASS (56 retained/adapted + 21 new),
  including storage payload preservation, guest flows, school search, meal states,
  A/B in-memory state isolation, date changes, 360×640/2× and prior Day 6 regression.
  Deno typecheck and 9 proxy tests PASS. Android debug/iOS simulator builds PASS.
  Normal configured iOS app launched; Home no-school and /my/school/back navigation
  verified. This is not a successful live NEIS search/save UI smoke.
- Actual official unauthenticated samples: 진접고등학교 J10/7530932; 20260911
  one lunch row; 20260913 INFO-200 (normal empty). These confirm response contracts,
  not keyed access, proxy deployment or populated live Flutter behavior.
- Pending: existing A/B credentials and issued NEIS key were not provided; proxy
  not deployed. tool/verify_school_jwt.py prepared but NOT executed. No production
  application writes/fixtures, auth users created/deleted, SQL or migration edits.
  Full live acceptance and Day 8 readiness are NOT claimed. See day-7-neis.md.
- Known Day 6 private resource link_status limitation unchanged. No schema, timer,
  OAuth, AdMob, IAP, ingestion, push, PR or merge.

- Final repository checks: credential-pattern and exact external publishable-key
  scans PASS; applied migration bytes unchanged; git diff --check PASS.


## Day 7 compact NEIS attribution UI (historical; Home superseded below)

- Home retains the existing attribution visibility condition: no school means
  no attribution. For a selected school, secondary 12sp 출처: NEIS shares the
  school-setting action row on the right. No extra block or vertical spacer.
- School setup uses right-aligned 출처: 교육부·시도교육청 NEIS without the old
  16px spacer/long body copy. Both source buttons keep >=48×48 touch bounds and
  open a short dismissible native source dialog. No external navigation required.
- Analyze PASS; 85 Flutter tests PASS including all existing NEIS/School tests and
  eight layout/dialog cases. At 360×640, footer/card height is unchanged for no
  school; data/empty decreases 18 logical px at 1× and 40 at 2× in widget tests.
  Minimum touch bounds, same-row placement and dialog open/close pass at both scales.
- UI only: no proxy/key/repository/storage/schema/policy/parsing/meal-state/cache/
  date change. No runtime-gate completion claim. Existing CLI .temp metadata is
  left untouched and excluded from the refinement commit. git diff --check PASS.


## Home follow-up — session-only D-Day

- Official 레전드스터디-only crop applied; canonical source unchanged. School and
  study actions share title rows; Home attribution removed. School footer/dialog retained.
- One D-Day supports date/label, replacement and clearing in memory; editor clearly
  states exit resets and no account save. Auth identity changes clear selection.
  Korean calendar days avoid UTC drift; expired dates display 지난 일정.
- Read-only production REST projection returned 42703 for target_date/target_label;
  repository schema also lacks the contract. Permanent storage requires DB approval.
  No production SQL/writes or applied-migration changes. Storage proposal prepared in
  [day-7-dday-storage-proposal.md](day-7-dday-storage-proposal.md); STOP before applying; authenticated D-Day persistence is not implemented.
- Analyze and 93 Flutter tests PASS; Android debug/iOS simulator build results are
  recorded in the task log. 360×640 / 1× and 2× covers school unset/data/empty,
  D-Day unset/set/clear, study action and school attribution. Large text scrolls.
- Existing CLI supabase/.temp metadata remains untracked and excluded. No push/PR/merge.


## D-Day storage approval gate

- Proposed executable SQL: supabase/proposals/profile_day_target.sql (outside
  migration deployment path). Nullable date/text pair, finite date, trimmed 1–80
  character label; authenticated column INSERT/UPDATE, existing ownership RLS.
- Proposal includes validation queries, existing-row comparison, JWT acceptance,
  fixture cleanup and rollback. SQL parser and embedded-file equality PASS.
- Production applied: NO. Existing migrations unchanged. Await Product Owner
  approval/application results before implementing authenticated persistence.


## D-Day information hierarchy refinement

- Schedule name and countdown now share the first row with settings at the right.
  Long names ellipsize; countdown and >=48px settings target take priority.
- Active countdown uses primarySoft pill, textPrimary 16sp/w800 with zero tracking;
  no orange-on-white small text or red warning color. Exact date is secondary on
  the second row. Expired targets use plain secondary 지난 일정, without a pill.
- 360×640 at 1×/2× verified for long labels and D-DAY/D-1/D-23/D-999/D-7300/expired;
  header alignment, full countdown, date position, targets and no increased card
  height verified. Analyze PASS, all 95 Flutter tests PASS, diff check PASS.
- UI only; session storage, calendar rules and pending DB approval remain unchanged.
  Platform builds not repeated for this typography-only change. No push/PR/merge.


## D-Day final migration prepared — NOT APPLIED

- Owner approved Home UI and requested the migration stage. Added new migration
  20260913000200_profile_day_target.sql; neither existing migration was modified.
  Historical proposal retained, final execution/validation/rollback SQL and dedicated
  save/clear contract documented in day-7-dday-storage-proposal.md.
- Nullable finite date + trimmed 1–80-character label pair; authenticated column
  grants only, existing ownership RLS reused. No current_date-dependent CHECK.
- Migration/preflight/catalog/rollback parser PASS; embedded file identity, original
  migration bytes, credential scan and diff check PASS. No Flutter code change.
- Production applied: NO. Next: owner preflight → owner SQL Editor execution →
  catalog checks → actual JWT/REST pair and other-field preservation acceptance.
  Home remains session-only until authenticated repository work is approved and verified.
  No production SQL/data mutation, push, PR or merge. Existing CLI .temp excluded.


## D-Day persistence resumed — awaiting actual JWT verification

- Owner confirms production D-Day migration and pre/post checks completed:
  profile_rows 0→0, digest unchanged, populated_targets=invalid_pairs=0.
  DB preparation STOP released. No SQL executed by Codex.
- Dedicated tool/verify_day_target_jwt.py prepared. Uses actual login JWTs,
  narrow save/clear payloads and owner-only fixture cleanup; no service credentials.
  Hidden terminal password entry supported. Python syntax/diff checks PASS.
- Awaiting external credentials or owner execution result. D-Day JWT acceptance,
  Flutter persistence and runtime smoke are NOT yet verified. Flutter remains
  session-only; no feature commit, push, PR or merge at this checkpoint.


## D-Day JWT verifier diagnostics — runtime result pending

- Owner independently confirmed A/B login and empty profile reads plus migrated
  target fields, validated CHECK and grants. Do not infer a DB/account defect from
  the old generic preflight failure message.
- Verifier now reports A/B login status, profile read status/count, named identity/
  shape/empty checks, safe HTTP/JSON/TLS/timeout failure codes; unknown acceptance
  failures retain source-line identifiers. No response bodies, tokens or headers printed.
- Input/returned email case and surrounding whitespace normalized while retaining
  pinned account identity. User UUID/token shape validated. Entire SELECT/filter
  query encoded together; A and B empty checks no longer short-circuit silently.
- --preflight-only performs authentication and reads, with no profile mutations.
  Full mode retains cleanup of only this run's registered profiles and auth-user retention.
- 12 offline regression tests PASS, including healthy preflight, malformed responses,
  TLS/status diagnostics, non-disclosure, existing-row refusal and uncertain-write
  cleanup. Python syntax, credential scan, unchanged migrations and diff check PASS.
- Exact production failure cause remains unconfirmed without rerun diagnostics.
  No production request/SQL/user change performed in this debugging task. Flutter
  persistence remains gated on real JWT acceptance. No push, PR or merge.
