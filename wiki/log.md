# Development Log

## 2026-09-16 — Day 12 Home Information Architecture & Visual Hierarchy

- Reordered Home to D-Day, Study, Meal, Search, Recent Updates and Recent Views;
  removed the duplicate `오늘의 공부` heading and emphasized populated Study
  duration without adding unsupported metrics.
- Added centralized semantic section accents with neutral surfaces and preserved
  Meal, Search, Recent, D-Day, Auth, Feedback and personal-state behavior.
- Focused/full Flutter tests, analyze, Android debug, iOS simulator and physical
  iPhone Profile launch passed. No Production or Supabase mutation.

## 2026-09-15 — Day 9-C3 Saved / Recent UI + MY Integration

- Replaced Saved and Recent placeholders with authenticated personal lists,
  existing MY routes, detail navigation, retry/error/empty states, and Home's
  small recent section. Hydration uses a bounded public content batch query and
  omits inactive/missing content safely.
- Added C3 list, guest safety, ordering, batch, long-title/2× layout and retry
  tests. Full Flutter regression, analyzer, Android debug and documented iOS
  simulator validation passed. No production mutation, publication, or DB/RLS
  change. Publication readiness is YES; actual publication remains unexecuted.

## 2026-09-15 — Day 9-C1 Resource Detail + Safe Open Target

- Reused the existing search → content-detail route and resource repository.
- Added deterministic resource target resolution: unknown resources open only the
  parent LegendStudy source, landing pages open their own source URL, and files
  require a valid `file_url`; no source URL fallback is used for unknown/file.
- Detail resource presentation keeps occurrence-scoped subject grouping, adds the
  approved Korean labels and concise original-page guidance for unknown resources.
- Relevant tests and analyzer pass. No bookmark/recent/MY, DB, ingestion,
  publication or Production mutation. Day 9-C1 is implemented; Day 9-C remains
  incomplete.

## 2026-09-12

- Created public GitHub repository `LC3808/legendstudy-app`.
- Initialized repository with `README.md`.
- Added `AGENTS.md` and `CLAUDE.md`.
- Established repository-local `wiki/` as the canonical long-term development knowledge base.
- Recorded role split: Codex main coder, Claude support/review, ChatGPT planning/review, Manus execution support, user as product owner and default Supabase executor.
- Recorded core constraints: separate from Muselry, no simple WebView, verify wiki against actual code/DB/Git state.
- Added initial product scope, architecture, database, ingestion, design system, and durable decisions documents.
- Re-read the canonical chain in order: `AGENTS.md` → `wiki/index.md` → `wiki/current-status.md` and confirmed the role split and operating rules are internally consistent.
- Re-checked representative current and older `legendstudy.com` content. Confirmed 1,673 archive items and verified that older posts also use a one-post-to-many-resources pattern with PDFs, audio, scripts, and grade-cut material.
- Confirmed legacy taxonomy differences such as mathematics `가형/나형`; ingestion must preserve raw labels and avoid silently forcing modern taxonomy onto historical data.
- Froze the existing `wiki/product-scope.md` as the initial v1.0 implementation scope.
- Advanced project status from Phase 0 to **Phase 1 — implementation kickoff / Flutter scaffold ready**.
- Sitemap/RSS/robots/direct attachment mechanics remain implementation-time verification items where current inspection was inconclusive.

### Issue #1 — Day 1 Flutter scaffold

- Implemented native iOS/Android Flutter shell with Korean Home, Browse, Saved,
  and My Page destinations; feature-oriented presentation and documented future
  domain/data boundaries.
- Chose Riverpod 3.3.2 and go_router 17.0.0 with lifecycle-managed router and
  independent tab branches; added orange/light theme tokens and public config pattern.
- Used Flutter 3.32.0 / Dart 3.8.0. Temporary platform identity is
  `dev.legendstudy.scaffold`; production identity and signing remain owner decisions.
- Added strict analyzer settings and 4 passing tests for startup/navigation,
  direct routes/recovery, 2× text scaling on a small display, and configuration.
- `flutter analyze`, `flutter test`, Android debug APK and iOS simulator build passed.
  Installed and launched on iPhone 17 Pro / iOS 26.5 simulator; home shell verified visually.
- First Android build installed NDK 26.3.11579264. No unresolved build blocker.
- Updated README, current status, architecture, and design system. Secret-pattern
  scan and ignore checks passed. No Supabase schema, backend keys, or production
  signing configuration added. Original launcher branding remains follow-up work.
- Pushed branch `codex/issue-1-flutter-scaffold` to GitHub and opened PR #2.
- ChatGPT review checked routing, Riverpod composition, theme/config setup, test coverage,
  secret handling, temporary platform identifiers, and wiki consistency; no blocking issue found.
- PR #2 was marked ready and squash-merged into `main` as commit
  `873f4e1e0d131bb81dfa63766ff51966764ddd42`; Issue #1 closed through the PR.
- Post-merge `wiki/current-status.md` was corrected so the canonical status no longer
  claims the implementation branch is local/unpublished.

### Issue #3 — Day 2 production identity and brand baseline

- Updated Android applicationId/namespace/Kotlin package and iOS Runner bundle
  identifiers to owner-approved `com.legendstudy.app`; moved MainActivity under
  `com/legendstudy/app/`. RunnerTests uses `com.legendstudy.app.RunnerTests`.
- Both platforms now display `레전드스터디`; Dart package remains `legendstudy_app`.
- Established `assets/brand/` and `source/` with original-asset conventions; no
  original logos are present, so Flutter launcher icons and palette remain unchanged.
- Updated README and current-status, decisions, design-system, architecture wiki.
- Flutter 3.32.0 / Dart 3.8.0: pub get, analysis, 4 tests, Android debug build,
  iOS simulator build and diff checks passed. Verified new identity/display names
  directly in APK metadata and built iOS Info.plist, plus all Xcode configurations.
- Old identifier remains only in historical Day 1 wiki entries. No secrets,
  signing/team, OAuth, backend or feature changes. Store registration not attempted.
- Worked in `~/development/legendstudy-app` on `codex/day-2-production-identity`.
- Pushed commit `017630067c97578008b9f93359af0caef018ede2` and opened PR #4.
- ChatGPT review found no blocking issue in platform identity, display-name, brand-source,
  secret/signing boundary, or wiki changes.
- PR #4 was squash-merged into `main` as commit
  `5699af00c34d5101483f9f2750d2474ecd9aa686`; Issue #3 closed through the PR.
- Post-merge `wiki/current-status.md` was updated so canonical status matches the merged state.


### Day 3 — Data Model v0.1 and Supabase SQL draft

- Re-read canonical documents, verified origin/clean state, updated main and created
  `codex/day-3-data-model-v01` in the official development checkout.
- Read representative public source posts for modern options, legacy 가형/나형,
  calendar/academic-year differences and audio/script/landing-page attachments.
- Initial pre-review baseline (superseded by remediation below): designed eight tables with versioned nullable taxonomy mappings, raw labels,
  resource provenance/composite FK, source-link-first access and stable ingestion keys.
- Added draft migration, offline parser/structural checker and future read-only
  inspection SQL; documented grants/RLS, indexes, cascade boundaries and review cases.
- Initial pre-review validation (historical only): pglast 8.4 accepted 67 migration statements, two PL/pgSQL bodies and eight
  inspection SELECTs; structural checks and diff checks passed. Five offline
  injected safety regressions were detected; credential-pattern scan found no matches.
  No SQL executed.
- Updated database, ingestion, current-status, decisions and architecture wiki.
  No Flutter or platform/dependency changes, and no Supabase project/backend applied.
- Local commit only; push/merge/application require later authorization. ChatGPT
  review followed by Claude RLS/FK/idempotency review is recommended before execution.

## 2026-09-12 — Day 3 review fix

- Applied owner-provided corrections following Claude verdict C against
  `413b58849b1d395815a5090102aa2aa26c8f8b04`, on the same Day 3 branch.
- Fixed source/slug identity, generated date sorting, soft merge, persistent
  quarantine, mapping states, column exposure, taxonomy/content visibility and
  profile/recent upsert contracts. Removed premature indexes/extension dependency.
- Review-fix inventory at that commit (superseded by unified model below): 68 statements,
  9 tables/RLS tables, 15 policies, 9 non-constraint indexes, 7 triggers, 2 functions.
  Fourteen SELECT-only review queries prepared, not executed.
- Strengthened AST/grant/FK/function/trigger/index checks and checked-in mutation
  regressions. Five tests pass, including 31 unsafe schema, two contract and three
  inspection mutation cases. SQL/PLpgSQL grammar checks and diff whitespace check pass.
- S-9 deliberately uses a verified-row ingestion contract, not a protection trigger.
  Deferred URL UNIQUE pending evidence; notifications stay v1.0 with later schema.
- Updated database/ingestion/status/decisions/architecture/product scope and README.
  Complete Claude S-number mapping is unavailable in the supplied directive;
  known S-7/S-8/S-9/S-12 decisions are documented without inventing the rest.
- Owner confirms LegendStudy Supabase is not created/linked. No DB commands,
  SQL execution, source import, SDK/UI work, remote push, merge or other project access.
  Runtime validation remains explicitly pending. Follow-up commit preserves the
  reviewed baseline; no amend.

## 2026-09-12 — Unified content model before deployment

- Applied follow-up scope after review-fix commit 9a45b08, same Day 3 branch.
  Revised the existing unapplied initial migration; no new migration or amend.
- Added content_items for native search/Home/category/detail; moved common source
  identity, slug/publication and merge state there. Exam extension uses shared PK
  and enforced type discriminator. General resources, Saved and Recent target content.
- Preserved versioned/raw taxonomy, same-content scope FK, owner RLS, column grants,
  verified ingestion contract, quarantine and source-link-first behavior.
- Home is source publication/update chronology; modified posts preserve parent IDs
  and upsert resources. Private classification/quarantine precedes publication.
- Read representative study collection (991), admissions column (927), university
  essays (1612/1610) and exam pages; documented five cases, no binary downloads/imports.
- Final draft: 74 statements, 10 RLS tables, 16 policies, 10 non-constraint indexes,
  8 triggers, 2 functions. Fifteen future SELECT-only inspections, never executed.
- Six offline regression methods pass: 45 schema, four personal target/policy, two
  contract and three inspection mutations rejected. SQL/PLpgSQL parser and diff
  whitespace checks pass. No credential-pattern matches in changed files.
- Updated database/ingestion/architecture/product scope/status/decisions/README.
  Supabase still not created/linked/applied. No SQL/DB commands, Flutter feature,
  SDK, import, remote push or merge. Actual runtime acceptance remains pending.

## 2026-09-13 — Final checker hardening

- Applied the supplied Claude Final Delta Review verdict B (minor corrections before
  merge) against b28c003 on the same Day 3 branch. Migration SQL is unchanged.
- Added independent AST checks for slug/URL required global uniqueness, default-private
  publication, generated-date input ranges and critical domain/order constraints.
- Added 52 scalar mutation cases; all 14 test methods pass (106 negative cases total),
  including formatting/comment and equivalent single-column UNIQUE acceptance.
- Prepared orphan active exam SELECT-only inspection (16 inspection statements total)
  and three conditional generated-column fallback notes. No fallback applied.
- SQL/PLpgSQL parsing, checker and git diff --check pass. Updated README/status/database
  minimally; no schema, Flutter, ingestion implementation or architecture changes.
- No Supabase project/link/DB connection/SQL execution, remote push or merge. New
  follow-up commit, no amend. Actual target runtime acceptance remains pending.

## 2026-09-13 — Supabase deployment and runtime results recorded

- Day 3 main merge verified locally at c16350c0a60fe1c6281234a7c2056cf02b54d9ad.
  Owner reports initial migration applied: Success. No rows returned.
- Dedicated LegendStudy project stlhijzpjfgwwdgunlsd, ap-northeast-2 (Seoul), PG 17.6;
  prerequisites passed, separate from Muselry. Inventory: 10 tables, 16 policies,
  10 non-constraint indexes, 8 triggers, 2 functions; RLS enabled, FORCE RLS false.
- Generated feed/date/type columns created/calculated successfully; no fallback.
  Anon REST active reads/inactive [] and private-table permission denials passed.
- Real password-grant JWT users A/B: profiles ownership, bookmarks isolation,
  HTTP 403 spoof rejection, recent isolation and ID-preserving timestamp upsert
  passed. Anon profiles denied HTTP 401. No credentials retained in documentation.
- Taxonomy/content policy separation retained structurally; SQL Editor SET ROLE
  rejected as authoritative client-path proof. Full taxonomy REST trace not supplied.
- Owner confirms fixture cleanup: all 10 application tables 0 rows. Two Auth test
  users may remain for future tests; user deletion is not claimed.
- Updated deployment docs on codex/day-3-post-deployment-docs, including the stale
  ingestion status paragraph. Initial migration unchanged; future changes require
  new migrations. Docs task performed no SQL/DB operations, push or merge.
- Documentation validation: git diff --check and the offline schema checker pass;
  initial migration verified byte-identical to the Day 3 main merge. No SQL executed.
- Next: Day 4 Flutter ↔ Supabase connection; Flutter remains unconnected now.

## 2026-09-13 — Day 4-A Flutter–Supabase foundation

- Started from post-deployment main 5af7905 on codex/day-4-supabase-foundation.
- Added SDK-compatible supabase_flutter 2.15.4, explicit public config validation,
  awaited initialization and injectable client/Auth/repository providers. Existing
  Riverpod/go_router versions preserved; test-only http/integration_test added.
- Content uses exact public projection, source-time feed ordering, bounded escaped
  title/summary search and nullable slug reads. Personal repositories enforce current
  session ownership and narrow profile/bookmark/recent payload contracts.
- Home/Browse display minimal loading/empty/error/data/search; no UI redesign,
  login/OAuth, ingestion, DB schema or migration change. Signed-out personal calls
  are safe (empty reads, typed rejected writes without network).
- AGENTS/CLAUDE and Wiki align Claude UI/UX leadership with Codex implementation.
- pub get/analyze and 18 tests (14 new): PASS. Android/iOS simulator debug builds
  PASS; Android NDK 27 required by native plugins. CocoaPods configuration added.
- Installed/launched iPhone 17 Pro iOS 26.5; config-missing screen visually verified.
  Real LegendStudy init/read smoke NOT RUN: no local publishable key/config supplied.
  Opt-in read-only integration test prepared; no test login or fixture creation.
- diff check, credential scan, local-config/signing ignore checks and initial
  migration byte comparison: PASS. No Supabase SQL, remote push or merge performed.
- Next: local configured smoke, then Claude UI/UX v1 specs → Codex UI implementation.

## 2026-09-13 — Day 4-A final actual Flutter smoke

- Continued from clean 033ec66 on codex/day-4-supabase-foundation.
- Expanded the opt-in iOS test to observe actual Home/Browse loading-to-empty,
  active Auth subscription and all signed-out personal repository read/write paths.
- Real Supabase initialization PASS; dedicated LegendStudy content GET x3 HTTP 200,
  empty content_items as expected; Home/Browse empty and Auth signedOut PASS.
- Fixed test-harness subscription lifetime after a timeout; no production code fix
  was needed. Read-only host/path/method guard prevents DB writes; transport logs
  only status/count. Local public key never enters source/fixtures/Wiki/logs/Git.
- No SQL/schema/migration, data insert, OAuth test, UI redesign, push or merge.
- Next after Day 4-A merge: Day 5 approved Claude UI/UX v1.1, planned canonical
  wiki/ui-ux-v1.md; start with 홈 · 자료 · 학습 · MY shell in a separate task.

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

## 2026-09-13 — Day 5 UI shell and official v1.1 specification

- Verified main merge 20ae5bf and started codex/day-5-ui-shell. Added canonical
  ui-ux-v1.md from the owner's approved directive, registered UI reading order and
  updated product scope/decisions: school/NEIS/timer/history/social Auth/ad support
  are v1 goals but remain outside Day 5 backend implementation.
- Four stateful branches 홈/자료/학습/MY. Preserved Saved code under /my/saved,
  added school/recent shells, legacy redirects and root native material detail shell.
- Home section skeleton retains actual recent updates; Materials retains repository
  search. Study is idle-only, MY observes Auth. No fake ads, records, meal or purchase.
- Refined spacing/type/radius/divider tokens and shared header/card/state widgets;
  page-local Material boundaries keep ink effects scoped through nested navigation.
- pub get/analyze PASS; all 24 tests PASS, six new shell/state/semantics cases.
  Android/iOS builds PASS. iPhone 17 Pro visual checks: all tabs and MY Saved.
  Existing real Supabase smoke also PASS (3 GETs, HTTP 200, empty, signedOut).
- diff/security/ignore checks PASS; exact local key absent from Git candidates.
  Migration, repository data implementations and dependencies unchanged. No SQL,
  school/meal DB, timer runtime, OAuth, ads/IAP, import or ingestion.
- No separate Claude original supplied: canonical document explicitly identifies
  its approved-directive provenance. Local commit only; no push/merge; no blocker.


## 2026-09-13 — Day 5 official brand assets

- Added the owner's three canonical originals unchanged with hashes/provenance.
  Replaced Home's temporary book icon/Text lockup with the official Korean wordmark
  crop; maintained system typography, orange theme and existing navigation/data.
- Initially classified the 72×72 image as the launcher canonical source; the
  owner corrected that classification in the subsequent asset-role entry below.
  Platform launcher icons remained Flutter placeholders.
- analyze PASS, 24 tests PASS, Android debug/iOS simulator builds PASS. Configured
  iPhone 17 Pro Home screenshot inspected. Source hashes, exact crop pixels,
  packaged Android asset and diff/security checks PASS. Existing Supabase code and
  migration unchanged; no SQL, OAuth, school/meal/timer service, AdMob or IAP work.
- Local follow-up commit only, preserving 56ecec5; no push or merge.


## 2026-09-13 — Correct official symbol and legacy favicon roles

- Corrected assets/brand/README.md, design-system and active status/architecture:
  square logo's orange memo/document + pencil is the official core symbol and
  future launcher design reference; 72×72 “study” is a legacy favicon only.
- Launcher replacement and high-resolution production/restoration remain future
  brand work. Do not enlarge the low-resolution square image into final launcher art.
- Home remains unchanged; size/spacing/hierarchy and contrast refinements recorded
  as provisional future UI work. Source/generated image bytes and all code unchanged.
- Documentation-only follow-up after 9abbb08; diff/scope checks PASS. Flutter tests
  and builds not rerun. No DB/Supabase changes, push or merge.


## 2026-09-13 — Day 6 entry P0 search/cards

- Verified clean main/origin at 7e241e8; created codex/day-6-materials-search.
- Refined Home search entry, Materials submit/clear and IME-aware 200-character
  limit. Compact content cards add neutral type badges and real date metadata.
  Preserved routing, projections, Auth/personal repositories and DB contracts.
- P0 validation: flutter analyze PASS; 26 unit/widget tests PASS; git diff --check
  PASS. UI tests cover navigation, submit/clear, tab/detail return state, type/date
  cards and 360×640/2× scaling. No push/merge; P1 refinement follows.


## 2026-09-13 — Day 6 entry P1 hierarchy / completion

- Applied smaller spacing/wordmark, separate divider/card borders, section typography,
  centered spinner and consistent selected NavigationBar icons/label weight.
  Recorded canonical UI/token refinements and deferred feature boundaries.
- Final analyze PASS; 26 tests PASS; Android debug and iOS simulator builds PASS.
  Home→Materials visual check on iPhone 17 Pro / iOS 26.5 passed. Diff/security and
  unchanged router/backend/config/assets/dependency checks PASS. No DB/SQL work.
- Two local refinement commits on codex/day-6-materials-search from main 7e241e8.
  Ready for scoped Day 6 actual features; no blocker, push or merge.


## 2026-09-13 — Day 6 Materials/Search/native resource detail

- From clean 027ba1d on codex/day-6-materials-search, added real content-type filters,
  batched exam metadata, native single-title detail and resource/subject left fallback.
  All existing query guards and routing topology retained; no schema/migration work.
- Actual projections verified on five public tables (HTTP 200/0 rows). Used existing
  file_extension/file_size; link_status is private, so no availability claim or
  broken/restricted classification. A future eligibility contract is needed for that.
- url_launcher already locked at 6.3.2 promoted to direct dependency for external
  HTTP(S) actions; no WebView/PDF renderer or fake runtime data. Source/file priority
  and OS launch failure feedback tested; live files unavailable in the empty DB.
- analyze PASS, 56 tests PASS, Android debug/iOS simulator builds PASS. Real Flutter
  read-only smoke: eight GETs HTTP 200/empty, initialized/signedOut, safe personal
  calls. Normal simulator Home→exam filter and tab-return state visually checked.
- diff/security/exact-key/immutable schema checks PASS. One local feature commit;
  no push, PR or merge. Day 7 can build on this baseline with the documented limits.


## 2026-09-13 — Day 7 storage contract preflight / proposal only

- Branched from 30cdcb47; profiles has no school fields. Read-only proposed-column
  probe returned 42703. Stopped feature work per owner's STOP 2/3.
- Added school storage proposal with exact new SQL, owner RLS impact, validation
  and rollback. No migration file or SQL execution. Official NEIS school sample
  confirmed identifier names only; production key/meal review still pending.
- Documentation-only local commit; diff check PASS. Existing code/schema untouched,
  tests/builds not rerun. No Supabase write, push, PR or merge; approval required.


## 2026-09-13 — Prepare approved school storage migration

- Preserved 4078017; added new profile_school_selection migration and read-only
  before/after verification SQL. Nullable code pair + value CHECK, authenticated
  column INSERT/UPDATE only; existing owner RLS/profile contract unchanged.
- Official NEIS sample reconfirmed code examples; no invented code regex. Proposal
  updated to approved direction / prepared / NOT APPLIED with exact owner SQL.
- pglast syntax and new AST gate PASS; five unsafe mutations rejected; existing
  checker/14 tests PASS; diff/secret scan PASS. Initial migration and Flutter intact.
- No DB application or production writes. Owner deployment/REST/JWT verification
  pending before Day 7 implementation. Local commit only; no push/PR/merge.


## 2026-09-13 — Day 7 School / NEIS resumed implementation

- Owner reports school-storage migration deployed/validated; updated database and
  current status, keeping applied migration bytes unchanged. No Codex production SQL.
- Added Profile pair save/clear, school domain/repository, MY submit-search/selection,
  guest session selection and Home meal states. Auth-change/late-write isolation,
  Korea date rollover, source attribution and menu normalization included.
- NEIS official terms forbid issued-key disclosure: prepared a public read-only
  bounded Edge Function; key stays server-side, not in Flutter. Not deployed.
- Analyze/77 Flutter tests/Deno check/9 proxy tests/Android/iOS builds PASS.
  Actual simulator Home → school → back verified. Official sample school, dated
  meal and INFO-200 reads confirmed; production keyed/proxy smoke not claimed.
- Actual JWT A/B tests pending external account credentials; reusable safe harness
  prepared. No production fixture writes or auth-user creation/deletion this run.
  Live Day 7 acceptance pending; no Day 8 completion/readiness claim, push/PR/merge.

- Final repository checks: credential-pattern and exact external publishable-key
  scans PASS; applied migration bytes unchanged; git diff --check PASS.


## 2026-09-13 — Compact NEIS attribution UI

- Moved Home source to the right of the school action in the same row; original
  no-school visibility retained. School footer now uses short secondary/meta copy.
- Shared >=48×48 source button opens a concise native explanation with close action.
- Analyze and 85 Flutter tests PASS; 360×640 at 1×/2× covers Home no-school/data/
  empty, school setup, touch bounds and dialog. Existing card height unchanged
  when unset; reduced by 18px/40px for selected-school data/empty in layout tests.
- UI-only refinement; data/API/storage/state logic unchanged. diff --check PASS.
  Existing untracked supabase/.temp/ excluded. No push, PR or merge.


## 2026-09-13 — Home daily dashboard follow-up

- Preserved compact-attribution commit; official wordmark derivative now crops
  레전드스터디 only (216×55, x=718..933/y=64..118), renders at 180px. Originals unchanged.
- School/study actions share heading rows; no Home attribution. Compact school
  footer/dialog retained. Cards retain 48px actions and reduce vertical padding
  from 16px to 8px; header/inter-section spacing is tightened without font changes.
- One session-only D-Day supports date/label/settings/clear; exit reset and no
  account save are disclosed. Korean midnight, leap/year boundaries, expired
  states and identity isolation tested. Production target fields absent (42703);
  no permanent persistence or production SQL/data write performed.
- Analyze PASS; 93 Flutter tests PASS including existing NEIS/School tests and
  360×640 at 1×/2×. At 1×, study body bottom is y=539 (unset), 535 (meal fixture),
  514 (empty), above NavigationBar at y=560. This is current extent, not a claimed
  before/after pixel reduction. Longer real menus and 2× text require scrolling.
- Android debug and iOS simulator builds PASS. Configured iOS app Home, D-Day
  reset notice and calendar inspected; /tmp/legendstudy-home-refined.png captured.
  Guest school selection resets on app restart as before. No authenticated
  persistence/runtime-gate completion is claimed.
- Credential-pattern scan and git diff --check PASS; applied migrations and
  canonical brand source bytes unchanged. CLI .temp remains untracked/excluded.
  No push, PR or merge.


## 2026-09-13 — D-Day storage proposal / STOP

- Prepared supabase/proposals/profile_day_target.sql and
  day-7-dday-storage-proposal.md: nullable target_date/target_label pair, finite
  date, trimmed 1–80-char label and authenticated column grants. Existing RLS,
  anon restrictions, profile/school payload contracts and migration bytes preserved.
- Proposal execution SQL (5 statements), verification queries and rollback parse
  successfully with pglast; embedded SQL identical. Diff/credential scan PASS.
- No production SQL/schema/data change. Proposal deliberately stays outside applied
  migrations pending approval. STOP before application; session UI is not persistent.
  No push, PR or merge. Existing untracked CLI metadata excluded.


## 2026-09-13 — D-Day information hierarchy

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


## 2026-09-13 — Final D-Day storage migration preparation

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


## 2026-09-13 — Owner D-Day migration application report

- Owner confirms production D-Day migration and pre/post checks completed:
  profile_rows 0→0, digest unchanged, populated_targets=invalid_pairs=0.
  DB preparation STOP released. No SQL executed by Codex.
- Dedicated tool/verify_day_target_jwt.py prepared. Uses actual login JWTs,
  narrow save/clear payloads and owner-only fixture cleanup; no service credentials.
  Hidden terminal password entry supported. Python syntax/diff checks PASS.
- Awaiting external credentials or owner execution result. D-Day JWT acceptance,
  Flutter persistence and runtime smoke are NOT yet verified. Flutter remains
  session-only; no feature commit, push, PR or merge at this checkpoint.


## 2026-09-13 — D-Day JWT preflight diagnostics fix

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


## 2026-09-13 — D-Day Flutter persistence implementation

- Owner confirms D-Day JWT/REST acceptance and cleanup PASS after production migration.
- Added dedicated narrow-payload repository and authenticated asynchronous target
  controller, failure-preserving editor, guest-only memory state and stale identity
  response guards. Approved pill/date layout and 48px actions retained.
- Analyze, 107 Flutter tests, 13 Python tests, Android debug/iOS simulator builds,
  credentials and diff checks PASS. Production/schema/migrations unchanged.
- Prepared opt-in real Flutter test using hidden local password input and one-shot
  loopback handoff; credentials never embedded in defines/artifacts or logged.
  Authenticated Flutter runtime NOT RUN without owner credentials. No fixtures
  created this turn; prior JWT cleanup PASS is owner-reported. No COMPLETE claim.
- Local feature commit only; no push, PR or merge. Existing CLI .temp excluded.


## 2026-09-13 — Day 7 final runtime closeout / COMPLETE

- Checked actual codex/day-7-school-neis checkout, feature code, acceptance markers
  and current Wiki before editing. Product Owner supplied final real Flutter smoke
  PASS; results recorded as owner-run evidence, not rerun by Codex in this docs task.
- Day 7 School + NEIS Meals COMPLETE: production school migration and real JWT/RLS
  storage/ownership checks accepted; server-only NEIS secret, deployed proxy search/
  meal/empty and Flutter guest search/selection/Home empty runtime PASS.
- Home UI refinement COMPLETE. D-Day production migration, JWT/REST acceptance and
  actual Flutter persistence runtime PASS: save, container restore, edit, clear,
  account switch isolation and profile/school field preservation.
- Fixture cleanup PASS; Auth users retained. Restore evidence is ProviderContainer
  reconstruction, not an assertion of OS process restart or OAuth runtime testing.

```text
DDAY_RUNTIME PASS login_preflight
DDAY_RUNTIME PASS home_save
DDAY_RUNTIME PASS container_restore
DDAY_RUNTIME PASS home_edit
DDAY_RUNTIME PASS account_switch
DDAY_RUNTIME PASS home_clear
DDAY_RUNTIME PASS profile_school_preserved
DDAY_RUNTIME PASS fixture_cleanup
DDAY_RUNTIME PASS auth_users_retained
Flutter persistence smoke: PASS
```

- Day 7 = COMPLETE; next stage = Day 8 Study. Planned: general timer, today's total /
  study history / recent seven days, platform-capability-aware focus/DND integration,
  mock-exam mode, then automatic-grading/score/grade feature design. No Day 8 code yet.
- Preserved long-term backlog: Admissions Engine / 수시 prediction, university
  official calculation rules, admissions data collection/normalization, official
  service-page maintenance, Privacy/Terms/Support/Account deletion and potential
  prediction web service. Routine detail was not added to decisions.md.
- Reconciled stale pending status in current-status and related Wiki references.
  Documents only; no Flutter/DB/production/migration/Auth change. Markdown link,
  unchanged SQL-block and diff checks PASS; tests/builds not rerun. No push/PR/merge.


## 2026-09-14 — Day 8 Study architecture / DB contract proposal

- Inspected local Day 7-complete checkout, Wiki, Study/Home/Auth code and all applied
  migrations. Study remains disabled idle shell; no existing Study storage contract.
- Proposed durable local running state plus immutable terminal cloud intervals,
  clock/lifecycle/recovery, guest/account isolation, idempotent retries, Home and KST
  seven-day totals. Documented concrete UI states for Claude review.
- Included mock countdown/scoring extension boundaries and official Android/iOS
  capability research. Device-local focus preference; no iOS global toggle promise.
- Added SQL proposal, read-only preflight/catalog and destructive rollback reference,
  with owner JWT/REST acceptance plan. No applied migration edits or production calls.
- Day 7 remains COMPLETE; Day 8 design / DB contract pending Product Owner approval.
  No Flutter/native/DB deployment, Study implementation, push, PR or merge. Existing
  untracked supabase/.temp/ remains excluded. Static checks recorded in proposal.
- Static validation PASS: SQL and PL/pgSQL parser, proposal scope, unchanged applied
  migration bytes, Wiki links, added credential-pattern scan and git diff --check.
  Parser uses PG 18.4 grammar; production PG 17.6 execution compatibility remains
  an owner deployment gate. Flutter tests/builds and live checks were not rerun.


## 2026-09-14 — Day 8 approved storage migration package

- Owner approved local running/paused state, completed cloud records, KST split/union
  totals, limits and platform boundaries. Removed cloud cancellation/status column.
- Added 20260914000100_study_sessions.sql: 11 columns, generated duration from validated
  active intervals,6 CHECKs,owner policies and narrow grants,one query index.
- Prepared read-only preflight/catalog,copy-ready SQL package,rollback and actual A/B
  JWT acceptance plan. Summary SELECT bounded to KST window and2,000 rows with explicit
  overflow; no aggregate RPC or lifetime-history download.
- Existing applied migrations and Flutter/Day7 contracts unchanged. No production
  request/SQL,fixture/Auth changes,push,PR or merge. Day7 COMPLETE; Day8 production
  application and actual JWT acceptance remain pending before implementation.
- Offline checker and2 tests (11 forbidden-contract mutations) PASS; SQL/PLpgSQL,
  immutable migration hashes,package/source equality,links,credential-pattern and
  diff checks PASS. ParserPG18.4; actualPG17/JWT execution not performed. Flutter
  tests/builds not rerun because implementation is unchanged.


## 2026-09-14 — Study production accepted / JWT verifier prepared

- Owner confirms migration/postflight PASS,study/profile rows0,empty profile digest,
  interval example true,expected grants and unchanged existing RLS/constraints.
- Added dedicated getpass-based Study JWT verifier and preflight-only mode; existing
  A/B Study rows STOP. Narrow random-ID cleanup includes uncertain INSERTs,profile
  snapshots remain read-only,Auth users retained. Explicit A/B count scope; global
  zero remains Owner-reported until independent global post-run count.
- Python syntax,13 offline tests,credential-pattern scan,unchanged migration/Flutter
  scope and diff checks PASS. Actual JWT acceptance NOT RUN. No fixtures or production
  request this task; no Flutter/DND/mock UI,push,PR or merge. Day8 remains incomplete.


## 2026-09-14 — Study generated rejection verifier fix

- Owner observed normal400/428C9 on direct generated duration INSERT after initial
  runtime stages passed; cleanup/baseline/profile preservation/Auth retention PASS.
- Restricted duration-only expected pairs to400/428C9 or403/42501. Ordinary user_id /
  created_at remain403/42501 only; no blanket400 pass or cleanup changes.
-17 offline tests,Python syntax,credential scan,diff and unchanged schema checks PASS.
  Full live acceptance awaits rerun. No production/Flutter/migration/push/PR/merge.


## 2026-09-14 — Day 8-A Study Core implementation

- Start: codex/day-7-school-neis at b7086cf (historical baseline only). Owner confirms
  full Study production JWT acceptance PASS; no new schema/production deployment.
- Added local monotonic stopwatch,atomic per-owner draft/history/outbox,immutable
  cloud repository,pending retry,KST interval-union seven-day/current overlay and Home.
  Timer-first UI,48px controls,tabular figures and narrow/large-text layout. Claude
  source review preserved verbatim; Owner overrides explicitly appended.
- Analyze,134 Flutter tests,Android debug/iOS simulator builds,18 Study Python tests,
  syntax,credential scan,diff checks PASS. iOS guest native start/pause/resume/end,
  running-state reconstruction,local history/Home and original snapshot restoration PASS.
- A/B Flutter runtime is awaiting hidden-password Owner runner; not marked PASS.
  Physical-device lifecycle/process-kill acceptance remains outstanding. No DND,
  Focus,mock UI,notification/scoring implementation. Day8 overall not COMPLETE.
- Existing migrations/profile/school/D-Day preserved. No push,PR or merge. Existing
  untracked Claude outputs source and Supabase CLI temp metadata remain excluded.


## 2026-09-14 — Day 8-A runtime closeout: COMPLETE

- Owner reports all14 STUDY_FLUTTER stages and final Flutter persistence smoke PASS;
  checked against the repository runner/integration test. Guest and authenticated
  flows, cloud save/restore, Home aggregate, account isolation and pending sync/retry
  PASS. Profile/school/D-Day preservation and fixture cleanup PASS; Auth users retained.
- Production Study migration applied, Postflight and full real JWT acceptance PASS.
  **Day 8-A Study Core = COMPLETE. Day 8 overall is not COMPLETE.** Earlier pending
  entries are historical. Physical lifecycle/OS restart checks remain follow-up.
- Next: Day 8-B Focus / DND using official platform capabilities. Android first-use
  항상 사용 / 이번만 / 사용 안 함; preference device-local. Permission denial or failure
  never blocks Study start; iOS does not claim automatic system Focus toggling.
- Docs-only closeout; diff/scope checks PASS. Prior implementation tests/builds retained,
  not rerun. No Flutter/DB/production changes, Push, PR or Merge.


## 2026-09-14 — Day 8-B Focus / DND implementation

- Start: codex/day-7-school-neis at3c211fe (historical baseline). Reviewed local
  timer/native storage and official Android/Apple API behavior; target/compile35.
- Added capability-based Focus service/controller and compact first-start/settings
  UI. Android API29+ owns explicit Zen rule; previous Android/iOS manual guide.
  Device preference ask/always/disabled; once ephemeral; backup exclusions. Timer
  commits before permission handoff, all Focus failure paths allow Study start.
- Latest policy: pause/resume keep Focus; end/recovery/account switch reconcile only
  the app's activation. No global DND overwrite, notification reading or cloud fields.
- Analyze,156 Flutter tests,2 Android JVM lease tests,Android debug/iOS simulator
  builds PASS. iOS native guide/timer/preference/cleanup smoke PASS; diff/security/scope
  checks PASS. Existing Day 8-A134 tests preserved; DB/migrations unchanged.
- Physical Android DND/user-state/permission/kill/restart and iPhone guide unverified;
  no connected Android device or AVD. Owned rule can outlive app kill until re-entry;
  deadline is not a scheduled OS expiry. Day 8-B NOT COMPLETE; Day8 overall NOT COMPLETE.
- No DND bypass or third-party runtime/DND package (JUnit is test-only), mock UI, notifications, scoring, Push, PR or Merge.


## 2026-09-14 — Day 8-C Mock Exam design

- Reviewed current Study model/controller/repository, native Focus draft recognition
  and deployed migration contract; no new production verification or DB changes.
- Designed compact entry/setup, presets/custom, separate mock states, monotonic active
  countdown and explicit timeUp confirmation; corrected earlier auto-completion wording.
- Defined local v1 migration preservation, guest/auth isolation/outbox, KST aggregate,
  Focus cleanup, optional best-effort notification and physical/runtime test gates.
- Day 8-C DESIGN COMPLETE only; implementation pending. Day8-B physical acceptance
  remains pending; Day8 overall NOT COMPLETE. No scoring/answer schema or UI.
- Documentation links/scope and git diff --check PASS; no code tests/builds rerun
  for this documentation-only task. No Push, PR, Merge or production changes.


## 2026-09-14 — Day 8-C Mock Exam implementation

- Implemented compact mode switch/setup/presets/custom countdown, separate mock state,
  durable timeUp awaiting confirmation, early submit and shared local/outbox/aggregate.
- Upgraded local envelope v1->v2 preserving prior work; account-switch mock freezes
  without auto-upload. Existing Focus reuse and optional native local notifications;
  no schema/migration, answers/scoring/grades or new runtime dependency.
- Analyze and177 Flutter tests PASS; Python runner2 tests/syntax PASS; final Android
  debug/iOS simulator builds and diff/credential/scope checks PASS. Real iOS Guest
  setup/pause/resume/running restore/one-minute timeUp/frozen restore/confirm/local
  result/Home/fixture cleanup PASS. Auth Mock smoke awaits Owner getpass execution.
- Physical Android/iPhone background/lock/Focus/notification/kill/reboot pending;
  Day8-C implemented / runtime validation pending, NOT COMPLETE. Day8 overall NOT
  COMPLETE;8-D implementation not started. No Push, PR or Merge.


## 2026-09-14 — Day 8-C Flutter runtime acceptance recorded

- Owner reports full Mock Flutter persistence smoke PASS: Guest/Auth runtime,
  cloud save/restore, Home aggregate, account isolation and pending sync/retry.
- Profile/school/D-Day preservation, fixture cleanup and Auth users retained PASS.
  Full safe stage output preserved in day-8-mock-exam.md; prior pending entry above
  describes the implementation checkpoint, not the current runtime state.
- Day8-C implementation complete; final COMPLETE remains on hold for physical
  background/lock/Focus/local notification/kill/reboot. Day8 overall NOT COMPLETE.
  Day8-D Scoring requires separate Owner approval.
- Documentation only; diff/scope checks PASS. No tests/builds rerun, code/DB/production
  changes, Push, PR or Merge.


## 2026-09-14 — Day 8-D Scoring architecture/storage proposal

- Cross-checked actual exams.content_item_id, occurrence same-content FK, resources,
  Study immutable storage and private quarantine. Reviewed official scoring/subject
  references; no scraping, key ingestion, production query or data import.
- Proposed timer-only independence; complete MCQ keys first, per-item points,
  version-pinned Dart preview/server recomputation and owner-private immutable attempts.
  Raw-score estimates distinguished from official absolute-rule grades.
- Added five-table migration proposal with publication/aggregate guards, FK/grants,
  indexes, deletion/rollback and real JWT/engine/UI acceptance plan. No executable
  migration, scoring Flutter implementation or applied-schema change.
- Owner review needed for launch question types, grade labels and Study-delete cascade;
  8-D1 data/storage ->8-D2 entry/raw score ->8-D3 grade/results recommended.
- Doc links/scope/diff checks PASS. No SQL syntax/runtime or scoring test PASS claimed;
  these await executable8-D1 package. Day8-D NOT COMPLETE;8-B/8-C physical gates pending.
  No Push, PR or Merge.


## 2026-09-14 — Day 8-D1 Scoring storage package

- Recorded Owner-approved MCQ-first and grade labels; replaced proposed Study cascade
  with owner-safe SET NULL(study_session_id). Attempts/answers survive Study deletion.
- Added new scoring migration: five tables, independent cutoff versions, 12 functions,
  trusted scoring RPC, immutable publication/results, derived public availability and RLS.
- Prepared full Preflight/Postflight/empty-only rollback SQL and JWT/RPC acceptance plan.
  Updated scoring contract, architecture, database, current status and index.
- Static SQL/scope/old-migration hashes/package parity/credential checks PASS. In-memory
  PostgreSQL17.5 synthetic tests PASS, including grade vectors, role isolation, Study
  unlink/retry, field preservation and rollback. This is not real JWT/REST evidence.
- No production request/application/fixture, Flutter scoring, scraping or real key import.
  Day8-D1 migration package prepared / Owner approval pending; Day8-D NOT COMPLETE.
  Day8-B/8-C physical gates pending. No Push/PR/Merge.


## 2026-09-14 — Day 8-D1 current-version submission guard

- Owner confirmed scoring migration remains unapplied. Updated that migration's new
  submission path and INSERT guard to require current published key/cutoff; scope
  matching unchanged. Existing same-ID/same-request retries retain historical results.
- Added key/cutoff v1 -> v2 regressions proving stale new submissions reject, current
  versions succeed and prior snapshots/scores/grades remain unchanged. Original19 +2
  local groups and37 vectors PASS; static grammar/credential/package/diff checks PASS.
- Native PostgreSQL17.6 independent READ COMMITTED sessions:7 concurrency groups PASS,
  covering actual lock waits, current switches in both orders, idempotency, competing
  current uniqueness and publication/edit races. Private cluster and fixtures removed.
- Migration/package/proposal/acceptance and related Wiki synchronized. No production
  SQL, Flutter implementation, real key input, Push/PR/Merge. Owner final review pending.

## 2026-09-14 — Day 8-D1 JWT verifier preparation

- Recorded Owner-reported scoring migration/Postflight PASS; five empty scoring tables,
  catalog/engine checks and prior public baseline preservation confirmed by Owner.
- Added actual A/B REST/RPC verifier with hidden inputs, external pinned driver,
  project/admin identity checks and optional read-only preflight. Runtime remains pending.
- Implemented the explicitly approved run-UUID-only cleanup: three named USER triggers
  in one transaction, locks, count/digest/scope checks, FK cascade retained, trigger
  restoration and baseline comparison before commit. No ordinary deletion contract change.
- 45 Python offline tests PASS (16 new scoring tests plus29 existing JWT tests),
  including native PostgreSQL full flow, cleanup rollback and safety failures. Syntax,
  credential scan, unchanged migration hashes, SQL package parity and diff checks PASS;
  these are not real JWT evidence. No production connection/fixture/schema operation,
  migration or Flutter change, Push/PR/Merge.

## 2026-09-14 — Day 8-D1 COMPLETE

Owner reports actual A/B JWT/RPC acceptance PASS: server-side scoring, own result
and snapshots, direct score/grade forgery denial, owner isolation, idempotent retry,
current version switch and stale key/cutoff rejection, invalid inputs, Study deletion
retaining attempts/answers with a NULL link, and owner attempt deletion/cascade.
Fixture scope/cleanup, cleanup trigger restoration, scoring baseline restoration,
existing data preservation and Auth user retention all PASS.

**Day 8-D1 = COMPLETE. Next: Day 8-D2 Flutter Answer Entry + Raw Score.**
Day 8 overall is not COMPLETE; Day 8-B/8-C physical-device gates remain pending.
Flutter scoring/Dart parity and real source ingestion are not verified by this result.
This is Owner-run production evidence; this documentation closeout made no DB requests.

- Updated current status, scoring contract/architecture/database, execution package,
  acceptance evidence and index. Documentation-only closeout; no test/runtime rerun,
  code/DB changes, Push/PR/Merge. Day 8-D2 implementation has not started.

## 2026-09-14 — Day 8-D2 Answer Entry + Raw Score implementation

- Added typed availability/answer-only questions, v3 atomic answer drafts and scoring
  outbox, Guest mcq5-v1 and Auth fixed-payload RPC/read-back. Owner epochs, pause/timeUp
  locks, pending/stale recovery and separate result review preserve existing contracts.
- Added compact five-choice/group/grid answer UI and raw score/review. Timer-only remains
  with empty production data; correct answers are withheld until submission.
- Full228 Flutter tests and37 shared vectors PASS. Android debug/iOS simulator builds
  PASS. Native iOS synthetic Guest answer/pause/restore/submit/result and local file
  cleanup PASS. Real A/B Flutter scoring remains pending; D1 acceptance is separate.
- Actual public availability-empty Flutter read PASS; analyze/diff checks PASS.
- No DB/schema/migration change or production fixtures. Day8-D2 implemented/runtime
  validation pending; Day8 overall not COMPLETE. D3 requires separate approval.

## 2026-09-14 — Day 8-D2 A/B Flutter smoke runner prepared

- Added opt-in native Flutter SDK login/AnswerEntry/RPC/result-restore smoke with
  hidden inputs and one-shot loopback delivery, separate from D1 acceptance.
- Tests real scoring/read-back, pause/draft restore, account switch, historical
  same-ID retry after current switch, and stale submission answer preservation.
- Reuses D1 UUID-scoped transactional fixture cleanup; checks every registered
  Study owner, restores the three approved USER triggers and verifies baseline.
- 9 runner offline tests plus45 existing JWT tests, full228 Flutter tests,
  analyze and iOS simulator integration-target build PASS. Syntax/credential/diff
  checks PASS. No production calls, schema changes or Flutter feature changes.
- Owner actual A/B execution remains pending. No Push/PR/Merge; Day8-D2 is not COMPLETE.

## 2026-09-14 — Day 8-D2 COMPLETE

- Owner reports actual A/B Flutter scoring smoke PASS: login/preparation, answer
  entry, pause/resume, draft restore, server RPC/raw result, server-confirmed result
  restore, account isolation, retry/idempotency and stale-version handling.
- Existing native synthetic Guest runtime PASS retained. Pause/timeUp mutation policy
  PASS combines runtime pause verification with existing automated timeUp lock tests.
- Local fixture cleanup, run UUID scope/cleanup, cleanup trigger restoration, scoring
  baseline restoration, existing data preservation and Auth user retention all PASS.
- **Day 8-D2 Answer Entry + Raw Score = COMPLETE. Next: Day 8-D3 Grade + Result UX.**
  Day8 overall NOT COMPLETE; Day8-B/8-C physical-device gates remain pending.
- Documentation-only closeout based on Owner evidence; no runtime/test rerun, Flutter
  or DB change, Push/PR/Merge. Documentation diff checked.


## 2026-09-14 — Day 8-D3 Grade + Result UX implementation

- Added source-validated confirmed/estimated/unavailable labels, primary raw score,
  separate incorrect/blank summary and jumps, accessible answer review, source dialog
  with safe external links and Study/Home navigation. No score/grade hardcoding.
- Preserve pinned key/cutoff provenance in native results; optional subject/date fields
  support future history. Legacy source-less caches retained without invented grade
  basis. Auth remains server-canonical; no current-version automatic regrade.
- 242 Flutter tests, analyze, Android debug/iOS simulator builds PASS. Native synthetic
  Guest three-grade-state/source/review/historical-restore and original-file cleanup PASS.
- Updated scoring/Study/architecture/index/status/D3 Wiki; corrected superseded paused
  marking and unimplemented-engine wording. Entitlement/Free/Basic/Pro remains planning.
- D3 implemented, NOT COMPLETE: actual A/B production runtime remains Owner-gated by
  this request's production-data-input prohibition. No production fixture, DB/schema/
  RPC/migration change, Push/PR/Merge. B/C physical acceptance remains pending.


## 2026-09-14 — Day 8-D3 A/B Flutter smoke runner prepared

- Added dedicated hidden-input, allowlisted-output D3 runner/native integration test
  for three grade modes, summary/review/provenance, restore/history, v1/v2 reproducibility,
  account isolation, exact retry, legacy fallback and actual Study/Home navigation.
- Reuses D1 transactional cleanup unchanged; every extra definition UUID is preflighted,
  each native Study/attempt UUID is registered before dispatch, maximum three each.
  Three approved cleanup triggers, owner/digest/baseline/Auth-retention guards retained.
- 11 new runner safety tests /65 combined Python offline tests PASS; actual-router
  offline widget test, full243 Flutter tests, analyze and iOS simulator integration-target build PASS.
- No feature code, schema/migration/RPC or production request/fixture operation.
  Owner execution remains pending; D3/Day8 NOT COMPLETE. No Push/PR/Merge.

## 2026-09-14 — Study/Home UI polish

- Added explicit meal expansion with complete lunch/dinner menus and responsive
  long school header; newest-first study rows; icon/style-distinct pause/resume;
  outlined selected modes; Korean default, English45 without listening and history30;
  ordered presets and consistent 시험 시간 copy.
- Owner-reported iPhone profile/start, background/lock, pause, mock timeUp,
  notification and kill/relaunch restoration PASS. Focus guide, Android physical,
  reboot and remaining acceptance stay pending; B/C/Day8 not marked COMPLETE.
- Analyze, all257 Flutter tests,14 render cases, Android debug/iOS simulator builds
  and diff check PASS. Real iPhone12 Pro Max profile UI at1×/2× PASS;22 final
  screenshots reviewed. Test-only native viewport/touch mismatch corrected.
  Normal profile app reinstalled without uninstalling and launched after UI tests.
  Details: study-home-ui-polish.md. D3 runtime runner
  work remains separate; DB/schema/migration/RPC untouched; no Push/PR/Merge.

## 2026-09-15 — D3 runner safe diagnostics; Owner execution pending

- Verified local HEAD88c4a60 / codex/day-7-school-neis and preserved existing D3
  untracked runner/integration/tests and four Wiki edits. No new commit.
- Owner's two-line runner FAIL lacks recoverable stage/exception evidence; exact
  prior root cause remains unknown. Reproduced generic-error hiding offline and
  added allowlisted stage/type/status/code/exit diagnostics, prefixed native markers,
  explicit missing stages, bridge and finalizer failure reporting.
- Today's missing temporary venv and shutdown simulator restored/prepared; these
  current observations do not establish yesterday's failure cause.
- Python syntax/credential/diff checks PASS; D3 offline20 and existing D1/D2 scoring25
  PASS on local PostgreSQL17. Integration analyze and15 relevant Flutter tests PASS.
- D1 UUID-scoped transactional cleanup unchanged; no production request or actual
  credential execution. STOP for Owner getpass run. D3 NOT COMPLETE; iPhone physical
  subset PASS and UI polish preserved. No schema/RPC, Push/PR/Merge or feature edits.

## 2026-09-15 — Optional external pooler host

- Added one shared host loader reused by D1 verifier and D2/D3 runners. External
  SUPABASE_SESSION_POOLER_HOST skips host prompt; absence retains prior prompt;
  invalid values fail closed. Existing host validation and project pin preserved.
- A/B/DB getpass unchanged. External JSON not edited; no host duplication in config,
  password storage or Keychain implementation. Future Keychain scope recorded as TODO.
- Offline49 tests, Python syntax, credential scan and diff checks PASS. No production
  execution/DB/schema/RPC, feature or cleanup changes; D3 acceptance still pending.

## 2026-09-15 — Day 8-D3 COMPLETE / verifier wrapper

- Owner reports all13 A/B application stages, local cleanup, six fixture/trigger/
  baseline/data/Auth retention stages and final Flutter grade result smoke PASS.
  D3 COMPLETE; D1/D2 COMPLETE retained; Day8 overall not declared COMPLETE.
- Flutter exit0; extra app_stop exit3 reproduced for an absent simulator process,
  consistent with already-exited test app. Preserve acceptance; raw original stderr
  unavailable, so do not generalize every termination3 into success.
- Later system-Python missing psycopg is an environment error, not D3 regression.
  Added executable shell wrapper: reuse external venv, explicit --setup to stable
  user directory with pinned dependency. No global pip/vendor or credential logs.
  Existing external pooler-host loader and all getpass prompts retained.
- Six new offline wrapper tests, shell/Python syntax, credential and diff checks PASS.
  Prior49 Python and15 Flutter checks retained; no accepted production runtime rerun.
- Current-status/D3/scoring/Study/architecture/index updated. iPhone physical subset
  and UI polish PASS preserved; Focus details/reboot/Android physical still pending.
  No production DB/schema/RPC or app feature changes; no Push/PR/Merge.


## 2026-09-15 — Day 9-A Search / Explore implementation

- Started from local 3519073 on codex/day-7-school-neis with no tracked changes;
  preserved existing untracked directories. Day 8 accepted results remain intact.
- Added typed search/filter/result/facet contracts, public Supabase repository,
  Riverpod controller, metadata/subject/resource queries, parent aggregation and
  bounded pagination. Home passes q to Materials; native detail identity retained.
- Read-only public counts each 0 for content/exam/subject/occurrence/resource tables.
  Verified PGRST118 inverse relation ordering and 42501 empty-embed projection
  constraints, then implemented explicit exam-first/public-field reads. Verified
  PGRST103 counted offset edge and fixed cross-stream paging with separate count.
  Actual SDK read-only search/facets/later-page smoke PASS; no production writes.
- Analyze PASS; full 306 tests PASS, one network opt-in skipped in default regression
  and separately PASS. 29 render/handoff tests PASS, 52 desktop Flutter PNGs generated,
  representative 360×640/428×926 at 1×/2× reviewed across required states. Filter
  contrast/density refined; long titles/subjects wrap. Android debug build PASS.
- iOS simulator build blocked before compilation: xcrun/xcodebuild exit 69 requires
  Owner acceptance of the Xcode license. Profile/device execution and native
  keyboard/screenshots cannot be verified yet. Owner notified; no license accepted
  by the agent. Prior Day 8 iPhone PASS is not relabelled as new-UI validation.
- Diff and credential checks PASS. Day 9-A implemented but NOT COMPLETE pending
  iOS closeout. Day 9-B can plan against stable identities/contracts; no ingestion
  authorized or performed. Wiki status/search/architecture/database/index updated.
  No DB/schema/migration/RPC, push/PR/merge or Study/scoring feature changes.


## 2026-09-15 — Day 9-A iOS validation / COMPLETE

- Owner resolved Xcode license gate. New Xcode27 rejects iOS12 and the default
  simulator architecture combination. Preserved repository targets/Podfile; used
  an external iOS15/arm64/ONLY_ACTIVE_ARCH validation xcconfig. Simulator and
  signed profile builds PASS under those conditions; plain/default build remains
  a separately documented release-toolchain issue requiring Owner policy review.
- iPhone17 Pro simulator iOS26.5,402×874 logical portrait:14 native screen scenarios
  (seven at1×/2×) and Home query handoff PASS.26 OS screenshots captured; representative
  hierarchy, spacing, long text, zero/one/many, loading/error/filter states reviewed.
- Added compositor wait/actual-width filenames and real keyboard inset assertion.
  Assertion exposed hardware-keyboard simulation; after switching to software
  keyboard,1×/2× inset and Korean OS screenshot checks PASS. Restored original
  keyboard setting. No focus-only screenshot counted as keyboard acceptance.
- Analyze and29 targeted widget tests PASS; prior full306 regression, public SDK
  smoke and Android debug PASS retained. Main simulator app restored without
  clearing its container; actual public Materials empty state verified in native UI.
  Profile build is not a physical profile launch; no
  physical phone was connected. Prior Day8 iPhone acceptance remains unchanged.
- Day9-A COMPLETE for Search/Explore scope; Wiki status/index/architecture updated.
  Next:9-B real-content ingestion under its own request;9-C/9-D remain open.
  No product feature, DB/schema/RPC/dependency changes or push/PR/merge.

## 2026-09-15 — Day 9-B legendstudy.com ingestion (survey, pipeline, dry-run)

- Surveyed the live site: sitemap lists 1,673 numeric posts; 227 modern posts
  (id 1481–1709) read in full, plus stratified legacy probes down to id 50.
  robots.txt allows post paths and the sitemap; `Crawl-delay` targets bingbot only.
- Found two attachment generations with a sharp boundary near id 1481/1475.
  Modern kakaocdn locators require a site-wide rolling signature expiring
  2026-10-01 00:00 KST; the unsigned path and an expired signature both fail to
  load. Legacy cfile locators are unsigned and stable. Signed query is never
  stored; `kage@{s1}/{s2}` is the stable resource identity.
- Confirmed the site writes the calendar year as `N학년도` on 교육청 학평 posts
  (post 1705 body vs its own title), so `academic_year` is trusted only for
  수능/모의평가. Organisation evidence is self-contradictory (body 경기도교육청 vs
  tag 인천광역시교육청) and is not populated.
- Implemented `tool/ingestion/` (models, taxonomy, parser, normalizer, crawler,
  pipeline, writer) and `tool/ingest_legendstudy.py`. Dry-run by default;
  `--apply` refuses and names the LegendStudy project ref first. Stdlib only.
- Dry-run over 38 real exam posts / 1,205 real attachments: 0 parse errors,
  0 blocking quarantine, 35/38 publish candidates, zero schema violations,
  byte-identical re-run. The only three failures are source-site typos.
  Title coverage over all 227 modern posts: 81/81 exam posts fully identified.
- Added a subject word-boundary rule after the source typo `생화활과윤리` was
  being read as the historical subject `윤리`.
- 65 offline tests PASS; py_compile, credential scan and `git diff --check` PASS.
  Pre-existing `psycopg`-dependent tool tests still fail for that reason alone.
- Network smoke implemented but not executed: this environment's egress policy
  blocks legendstudy.com from both shells. Must run once with egress before apply.
- No production write, migration, schema change, Supabase call, push, PR or merge.
  `Production pilot 적용 준비: NO`, pending one Owner decision on modern
  attachment access. Recommended pilot: 2025–2026 exam posts, 23 posts /
  23 exams / 363 exam_subjects / 716 resources, all publishable, zero quarantine.

## 2026-09-15 — Day 9-B2 subjects taxonomy v1 + Pilot C apply package

- Owner decisions recorded: modern attachment option (a) with the original post
  as the read path, Pilot C approved, subjects seeded first, legacy deferred.
- Designed canonical taxonomy v1: 36 raw tokens → 23 subjects. Decision basis
  documented from existing contract, not preference — the schema separates
  taxonomy from occurrence, Day 9-A's 과목 filter is flat with no parent
  expansion, and the measured grade distribution shows which tokens are
  spellings rather than subjects. 국어/수학 선택과목 map to their 영역 with the
  raw label preserved; 사탐/과탐 details stay distinct.
- Deterministic subject ids via uuid5 over "<taxonomy_version>:<code>", so a
  re-seed produces identical rows. taxonomy_version 'v1'; curriculum_version and
  parent_id left NULL with reasons recorded; grouping by the public `category`.
- Pilot C mapping dry-run: 363/363 provisional, 0 unmapped, 0 ambiguous,
  160 exact + 203 documented alias, all 23 subjects used.
- Seed emitted to supabase/seed/subjects_taxonomy_v1.sql via a CLI flag and
  asserted byte-identical by the test suite. INSERT … ON CONFLICT DO NOTHING
  only: no UPDATE, no DELETE, so a released row can never be edited by it.
- Added --pilot c / --no-taxonomy / --emit-subjects-seed to the CLI, and apply
  guards assert_in_scope / assert_no_collisions / expected_rows with PILOT_C.
  assert_apply_allowed still refuses every argument combination.
- Found that ContentResource.openUri falls back to source_url for
  link_kind='unknown', so all 716 pilot resources would open a 403. Recorded as
  the publication precondition and the 9-C contract; content_items.source_url,
  link_kind and LaunchMode.externalApplication already exist, so no schema,
  projection or repository change is needed.
- Prepared the full apply package (preflight/smoke/live dry-run/seed/apply/
  postflight/publication/rollback) with measured expected row counts.
- 91 offline tests PASS (65 → 91). No production write, migration, schema
  change, Supabase call, push, PR or merge. Package steps 1-4 are
  Owner-executable; the ingestion writer still has no write path.

## 2026-09-15 — Day 9-B2 live dry-run progress and scope fix

- Diagnosed `--source network --pilot c`: it fetched all 1,673 sitemap posts and
  only then filtered normalized results, so a healthy fast run could remain silent
  for about 42 minutes; repeated 20-second timeouts could extend much further.
- Network Pilot C now selects the approved 23 ids before fetching and fails closed
  if an approved id is absent or a post cannot be fetched. Serial crawling, robots
  rules and the 1.5-second polite interval are unchanged.
- Added flushed sitemap/post fetch/done output and retry diagnostics containing
  only post id, attempt, HTTP status or safe error kind. The 72-request budget
  permits the sitemap and 23 posts their initial request plus two bounded retries.
- Owner-reported Mac network smoke retained as PASS: 1,673 ids, posts 1709–1705
  parsed 5/5, 6 requests, 0 retries, 0 failures.
- 103 ingestion tests, py_compile, credential scan and diff check PASS. No live
  dry-run, production write, seed, migration, Flutter change, push, PR or merge.

## 2026-09-15 — Day 9-B2 Pilot C Box listening classification

- Owner live dry-run confirmed 23 Box landing pages, exactly one stable share id
  per Pilot C post. Source labels identify English listening files; two posts also
  repeat the same share URL on an answer-PDF anchor, and provider-key dedup retains
  the first listening anchor observed by the parser.
- Classification now ignores only the Box UI suffix `(실시간/다운로드)` variants,
  yielding `listening_audio`, English occurrence linkage and `mp3` where present.
  Raw source labels remain unchanged. The existing schema already supports the type.
- Expiration advisory counting is explicitly kakaocdn-only. Box stays
  `landing_page` and receives no signed-URL advisory.
- Pilot expectation updated to 23 posts / 363 occurrences / 739 resources:
  360 question, 356 answer/explanation and 23 listening audio. Quarantine is 23
  kakaocdn expiration advisories, zero blocking; all 23 remain publish candidates.
- Offline Pilot C source/evidence updated with stable Box identities and no query,
  credential, signature or expiry values. No production write, seed, migration,
  Flutter/Search change, apply, push, PR or merge.
- 106 ingestion tests, py_compile, credential scan and `git diff --check` PASS.

## 2026-09-15 — Day 9-B3 Pilot C apply writer

- Recorded Owner-completed verification as fact: live network smoke PASS (5/5),
  live Pilot C dry-run PASS (23 posts / 363 provisional occurrences / 739
  resources / 0 blocking), Production Preflight 1–9 PASS on PostgreSQL 17.6,
  and the subjects taxonomy v1 seed applied (23 rows). Production baseline is
  now subjects = 23 with every other content table at 0.
- Implemented tool/ingestion/apply.py, the write path Day 9-B2 deliberately
  omitted. assert_apply_allowed now refuses a wrong project ref first, then a
  missing Owner approval, then a plan that did not come from --source network.
- Chose one transaction for all 23 posts over the earlier per-post suggestion,
  and documented why: a mid-run failure would otherwise commit a partial pilot,
  break the expected-delta postflight and complicate rollback. Inserted counts
  are compared to the expectation inside the transaction before COMMIT.
  Quarantine commits separately afterwards, per ingestion.md.
- INSERT-only writer: no UPDATE, no DELETE anywhere, asserted by test. Partial
  pilot state fails closed rather than being repaired by an upsert, so manual
  corrections, activated rows and verified mappings are safe by construction.
- Deterministic uuid5 ids for source_posts, content_items, exam_subjects,
  resources and quarantine (exams reuse the content item id). A second run is a
  no-op and advisory quarantine rows cannot accumulate.
- DB password via getpass only; pooler host from config/development.json,
  --db-host or a prompt. No credential in repo, wiki, artifact, stdout.
- Added --postflight for read-only verification.
- 134 offline tests PASS (106 → 134) using an in-memory database double that
  refuses any UPDATE/DELETE and rejects unrecognised queries. No production
  fixture written. py_compile, credential scan and git diff --check PASS.
- NOT APPLIED to production. Execution is a separate Owner decision.

## 2026-09-15 — Day 9-B3 Pilot C applied to production; postflight query fixed

- Owner applied Pilot C to the LegendStudy production project. Inserted:
  source_posts 23/23, content_items 23/23, exams 23/23, exam_subjects 363/363,
  resources 739/739. Canonical transaction COMMIT, quarantine COMMIT (23 rows).
  Every count matched the expectation, so the in-transaction check passed.
- Owner manual postflight PASS: subjects 23, source_posts 23, content_items 23,
  exams 23, exam_subjects 363, resources 739, quarantine 23; active rows 0/0/0;
  provisional 363, verified 0; question 360, answer_explanation 356,
  listening_audio 23; signed_url_rows 0, unknown 716, landing_page 23,
  unknown_without_file_url 716; duplicates 0, orphans 0; anon RLS shows 0 content
  rows and 23 subjects. Content is in production and entirely inactive.
- CLI postflight raised ProgrammingError "only '%s', '%b', '%t' are allowed as
  placeholders, got '%c'" right after COMMIT. Cause: the signed-URL check kept a
  literal '%credential=%' LIKE pattern inside a parameterised statement, and
  psycopg parses placeholders whenever parameters are supplied. Read-only query
  only; no write path involved and no re-apply.
- Fix: the patterns are now a parameter (source_url ilike any(%s)), and
  PsycopgSession passes None rather than an empty tuple for parameterless
  statements so no literal % is ever parsed. Apply writer and ingestion logic
  unchanged.
- Added a PlaceholderStrictSession test double that reproduces psycopg's rule
  offline; it first proves it catches the original statement, then runs the
  whole apply plus postflight through it. 141 offline tests PASS (134 -> 141).
  py_compile, credential scan and git diff --check PASS.
- Day 9-B3 Pilot C Production ingestion COMPLETE. PUBLICATION NOT DONE: all rows
  remain is_active=false pending the 9-C open-target rule and Owner approval.
- 2026-09-15: Day 9-C2 implemented. Connected content detail to existing
  auth-derived bookmark/recent repositories with keyed bookmark state, guest
  no-write behavior, account isolation, one-touch-per-entry recent lifecycle,
  and non-blocking failure UX. Focused C2 tests pass; no production or DB
  changes. Day 9-C remains incomplete.

## 2026-09-16 — Day 9-D1 Pilot C publication package

- Confirmed branch `codex/day-7-school-neis`, HEAD `6338f3e`, and preserved the
  four pre-existing untracked directories. Implemented the dedicated,
  fail-closed `tool/publish_pilot_c.py` package for the exact 23-post Pilot C
  chain. It performs read-only baseline/scope preflight and, only with separate
  Owner approval, one transaction of exact `is_active=false → true` updates in
  content → occurrence → resource order with affected-row verification.
- Added idempotent all-zero / already-published / partial-state semantics,
  guarded soft rollback SQL (no DELETE), anon public-projection acceptance SQL,
  and credential-safe host/password handling. No production connection or SQL
  mutation was executed; no migration, RLS, Flutter, push, PR or merge.
- Added offline publication contract tests covering project/approval gates,
  baseline and scope mismatches, exact counts, mutation shape, rollback,
  idempotency and transaction rollback. Python compile, tests and diff check
  PASS. See [D1 package](day-9-d1-publication-package.md).

## 2026-09-16 — iOS 15 deployment target closeout

- Confirmed branch `codex/day-7-school-neis`, HEAD `a44710a`, and preserved the
  four pre-existing untracked directories. Changed the official iOS minimum from
  12.0 to 15.0 in `ios/Podfile` and all Runner Debug/Profile/Release project
  configurations. Added a Podfile post-install override so every generated Pods
  target also uses 15.0; `pod install` regenerated `Podfile.lock` checksum and
  the Pods project.
- The first default Xcode27 simulator build passed deployment-target checks but
  exposed the separate Flutter engine arm64/x86_64 mismatch. Added repository
  native `ARCHS = arm64` to Runner configurations, replacing the need for the
  historical external iOS15/arm64 xcconfig. Default simulator build PASS.
- `flutter pub get`, `flutter analyze`, full Flutter tests (316 passed, 1
  read-only network skip), `pod install`, and `git diff --check` PASS. Connected
  iPhone `00008101-001C39E02E61001E` built, installed and launched Runner; device
  process inspection confirmed Runner. Flutter runner interruption after launch
  prevents a full interactive runtime PASS claim. No DB/publication/feature logic
  or Android changes.

## 2026-09-16 — iPhone native startup SIGABRT diagnosis

- Reproduced the current HEAD (`f83d248`) on iPhone
  `00008101-001C39E02E61001E` (iOS 26.6.1): Debug and Profile both abort
  before `main.dart` in `Dart_Initialize → DartVM::Create`.
- The startup stack matches Flutter issue #175469's iOS 26 physical-device
  failure, whose report identifies `Unable to flip between RX and RW memory
  protection on pages`. The older ptrace/debug-tooling message is not present
  in the new verbose logs and cannot explain the identical Profile failure.
- Clean simulator Debug build/run PASS; the LegendStudy Home screen was
  captured on the iOS simulator. Device Home/Pilot-material rendering remains
  unverified because the engine aborts before Flutter UI startup.
- No repository iOS/toolchain setting was changed. Required next step is
  upgrading to a Flutter SDK containing
  the iOS 26 physical-device fix, then rerunning device Profile before Debug.

## 2026-09-16 — Day 10-A Flutter 3.47.3 official toolchain migration

- Adopted the separately installed Flutter 3.47.3 / Dart 3.13.3 SDK as the
  repository baseline while preserving the original Flutter 3.32.0 SDK. Pub
  constraints were raised without direct package upgrades; the lockfile records
  the required transitive resolution changes. Analyzer is clean and the test
  baseline remains 316 passed with one opt-in read-only network skip.
- Completed the minimum Android toolchain migration: Gradle 8.14, AGP 8.11.1,
  Kotlin 2.2.20 and NDK 28.2.13676358. Normal dependency validation and
  `flutter build apk --debug` pass. Flutter's `android.builtInKotlin=false` and
  `android.newDsl=false` migration properties are retained.
- Accepted Flutter 3.47 iOS Swift Package Manager generated integration while
  retaining CocoaPods. Migrated the custom AppDelegate to
  `FlutterImplicitEngineDelegate`, added the Flutter UIScene manifest, and
  retained iOS 15 / arm64. Simulator build/run and Home render pass; the
  previously verified 3.47.3 iPhone Profile launch has no DartInit SIGABRT.
  Device Debug remains pending CoreDevice availability.
- Recorded Pilot C publication as Product-Owner-confirmed COMPLETE and added
  the Home v2, Subject Alias and MY inquiry/suggestion backlog. No production
  data, RLS, ingestion or publication mutation was performed by this task.

## 2026-09-16 — Essay Lab roadmap priority

- Recorded Essay Lab as the next major product priority, ahead of Academic
  Profile, grade analysis and Admission Simulator, with a target of October
  2026 Beta/initial service. The roadmap defines a Web-primary authoring
  experience, shared Mobile/Web/Supabase identity and data, typed-answer MVP,
  structured question-level evaluation packages, and an initial 5–10 university
  content inventory focused on the latest 2–3 years.
- Recorded the account-level initial three free evaluations, server-side credit
  reservation/settlement, abuse-rate limiting posture, cumulative My Essay
  Pattern and growth history, package-based monetization direction, and later
  coach/university analysis. No code, schema, AI evaluation, billing, RLS or
  Production change was made.

## 2026-09-16 — Day 10-B Home Polish v2

- Implemented KST today/tomorrow meal presentation with 17:00 dinner/tomorrow
  priority, date/17:00 boundary scheduling and resume re-evaluation. Existing
  NEIS and meal contracts remain compatible; no Production read/write was used.
- Bounded Home recent updates and recent views to six records, collapsed to two
  by default with independent six-item expansion. Preserved Materials/MY full
  list semantics, guest safety and account-isolation generation guards.
- Added Day 10-B policy/widget coverage and passed the full Flutter suite:
  335 passed, one opt-in read-only network test skipped. Analyze, Android debug
  build and iOS simulator build/run pass. iPhone Profile build passed but
  CoreDevice launch automation timed out before physical Home interaction.

## 2026-09-16 — Day 10-C Legacy Subject Alias minimum foundation

- Added an offline alias resolver that keeps raw labels unchanged and separates
  safe formatting/source aliases from review-required and historically distinct
  labels. No historical archive ingestion or Supabase migration was executed.
- Added canonical-only search alias lookup and bounded physics/life-science
  display aliases. Python 146-test ingestion suite, targeted Flutter search/UI
  tests and analyze pass. Legacy ingestion remains deferred for curriculum
  review and the next Essay Lab inventory.

## 2026-09-16 — Day 11 Account & Personal Foundation + Feedback Operations

- Audited Auth, settings, profile, school, bookmarks and recent views. Added
  email/password and OAuth entry UI, logout, foreground-only meaningful recent
  view tracking with a 10-second threshold, and owner-scoped recent deletion.
- Added feedback form/diagnostic contract and a non-applied Supabase draft for
  feedback, server-managed admin authorization and notification outbox. Admin
  inbox/email delivery and real OAuth/Production acceptance remain pending
  Owner configuration. No Production, secret, email or Muselry change.

## 2026-09-17 — Day 11-B1 Feedback production security review

- Audited the Day 11 feedback draft and created a separate reviewed migration
  candidate with server-derived owner identity, deny-by-default admin/outbox
  access, explicit grants, empty `search_path` for definer functions, bounded
  outbox retries and duplicate-job protection.
- Added offline SQL contract tests and Gemini handoff artifacts under
  `/tmp/legendstudy-feedback-security-review/`. Updated Flutter to omit
  client-supplied `user_id`. Production apply, admin assignment, secrets,
  email worker and Admin Inbox were not performed.

## 2026-09-17 — Day 11-B1 Feedback Production JWT/RLS closeout

- Product Owner applied the reviewed feedback migration and confirmed RLS,
  grants, function security and trigger presence in Production.
- Final real JWT/RLS acceptance run `4060f61751ae` passed anon insert, A/B
  owner derivation and own reads, cross-user denial, normal-user status
  immutability, admin/outbox denial and exactly-one pending outbox per row.
- The Owner removed five TEST feedback rows from failed/successful runs;
  remaining TEST feedback/outbox rows are 0/0. Feedback DB/RLS is now
  Production Verified and B1 is COMPLETE. Admin bootstrap, Inbox, worker,
  provider secrets, email and push remain undone; retention and reverse-status
  policies remain open.

## 2026-09-17 — Day 11-B3 Admin Inbox

- Implemented the server-authorized MY Admin Inbox list/detail flow with a
  bounded newest-first query, status filters, diagnostic metadata and
  forward-only status actions. Guest and normal-user routes are denied while
  Production RLS remains the data boundary.
- Admin bootstrap and Admin JWT acceptance were already Owner-confirmed;
  controlled Production Admin Inbox E2E remains pending. No Production API,
  feedback mutation, email worker, provider secret or admin change was made.

## 2026-09-17 — Day 11-B3 final follow-up

- Owner confirmed physical Production E2E on a new iPhone running iOS 26.4.2:
  feedback submit, Admin Inbox list/detail, diagnostics and
  `new → reviewing → resolved` all passed.
- Fixed successful password-login navigation by waiting for the matching auth
  identity before returning to the prior route, with `/my` fallback when no
  route can be popped. Authenticated MY school/grade copy now differs from
  guest guidance. No Production mutation or email work was performed.

## 2026-09-17 — Day 11-B4-A Feedback Email architecture

- Audited the Production-verified feedback outbox and documented a
  provider-neutral Supabase Edge Function design with Resend as the recommended
  adapter, scheduler-only invocation, protected server configuration,
  idempotency, bounded retry and logging rules.
- Determined that safe concurrent claims require a small future migration for
  processing/lease/retry state. No migration, function, secret, DNS, provider
  account, Production mutation or email was performed; B4-B implementation and
  B4-C E2E remain pending.

## 2026-09-17 — Day 11-B4-B Feedback Email Worker package

- Implemented the local migration candidate, atomic claim/finalize/reclaim
  contract, secret-gated Deno Edge Function, provider-neutral adapter, Resend
  mapping, retry/idempotency handling and offline test sources.
- No Production migration/deploy, Cron, secret, DNS, Resend API call or email
  was performed. Python static contract checks pass; `pytest` and `deno` are
  unavailable locally. B4-C controlled email E2E remains pending.

## 2026-09-17 — Auth recovery foundation

- Added the forgot-password entry on login, `/auth/recovery` and
  `/auth/new-password`, reusing NestedPage/ShellPage/AppTokens rather than a new
  design system.
- Introduced `AuthRecoveryService` over `resetPasswordForEmail` and `updateUser`
  so the screens are testable with an in-memory double and no network call is
  reachable from a widget test.
- `AuthStatus` now carries the `AuthChangeEvent` and exposes `isPasswordRecovery`;
  the router routes only that event to the new-password screen. The recovery
  token is never read, logged or placed in a route. `/auth/new-password` renders
  no form without a session, because `updateUser` requires one.
- Centralized Korean auth error mapping keyed on `AuthException.code` first and
  message substrings second, with a safe fallback. Raw SDK English, tokens, URLs
  and status codes never reach the user; the reported `Invalid login credentials`
  is now mapped.
- Recovery success copy is identical whether or not the address has an account,
  so the screen does not disclose registration.
- Client password rules kept minimal (length 8, fields match); the project's real
  policy is not readable here, so the server rejection is surfaced instead.
- Redirect URL is configurable via `SUPABASE_RECOVERY_REDIRECT` and defaults to
  empty, so the SDK falls back to the Site URL. No LegendStudy recovery URI was
  invented and the OAuth callback was not reused.
- 15 focused tests added in test/auth_recovery_test.dart. NOT RUN in this
  environment: no Flutter SDK is reachable from the session, so analyze and test
  are pending on the Owner's machine.
- No production Supabase change, no redirect registration, no recovery email.

## 2026-09-17 — Final closeout: Auth Recovery + Feedback Email Worker

- Recorded Auth Recovery as **COMPLETE / CODE VERIFIED** after Owner-confirmed
  official Flutter 3.47.3 validation: focused 19/19 PASS, full suite 368 PASS
  with one existing opt-in skip, and analyze clean. Production Recovery E2E
  remains pending redirect configuration, real email, deep/app link, password
  reset and iOS physical acceptance.
- Recorded B4-A complete and B4-B **IMPLEMENTED / REVIEWED / PRODUCTION
  DEPLOYED** based on Owner-confirmed migration/function/secrets/postflight and
  wrong-secret 403 acceptance. Deno 2.9.6 runtime tests are 5/5 and type-check
  passes.
- Feedback Email Delivery E2E remains pending: Cron is disabled, no successful
  worker invocation or received admin email is verified. The first prerequisite
  is a real receiving `LEGENDSTUDY_ADMIN_EMAIL` mailbox; an Auth account alone
  does not imply mailbox delivery. Existing backlog priority is P0 delivery E2E,
  P1 recovery E2E, P2 OAuth/privacy, P3 Day 13-A, P4 Day 13-B, P5 v1 gap audit,
  P6 app-wide UI polish. Essay Lab roadmap is unchanged.

## 2026-09-18 — Essay Lab / LS LAB roadmap update

- Superseded the former approximately 5–10 university and latest 2–3 year
  starting scope. A nationwide survey of all 2027학년도 수시 논술 실시
  대학, grounded in official admissions materials, is now the prerequisite
  for university selection and content inventory.
- First-wave selection now prioritizes broad Seoul coverage and adds
  representative non-Seoul formats such as 부산대 and 경북대 only after their
  actual 2027 formats are researched. The latest three years of official
  materials are inventoried where available; missing items are recorded, not
  guessed.
- Added separate `long_essay` and `short_response` tracks, Web-primary LS LAB
  direction, domain/name TBD status, and Manus Phase 0 survey → Phase 1
  inventory/selection → Phase 2 Web MVP foundation. Documentation only; no
  code, Production, DB, Web project or domain mutation.

## 2026-09-18 — Auth recovery production readiness

- Audited the recovery flow end to end against the real SDK contract
  (supabase_flutter 2.15.4 / gotrue 2.25.0, PKCE by default) rather than the
  wiki, and found that no deep link was registered on either platform, so the
  recovery email could never have opened the app.
- Registered `com.legendstudy.app://auth-recovery` in `Info.plist` and
  `AndroidManifest.xml`, declared it once as `recoveryDeepLink`, and recorded
  why a custom scheme beats a universal link while legendstudy.com is on
  Tistory (both `.well-known` files 404 and cannot be hosted there).
- Gave an unusable recovery link a Korean explanation instead of silence, and
  taught the error mapper to read `error_code` when it arrives as `statusCode`.
- Focused tests 19 → 27. No Production mutation: no Dashboard change, no
  redirect registration, no recovery email, no Auth user, no DB write.

## 2026-09-18 — Day 11-B4-C Feedback Email Production Delivery E2E

- Owner confirmed the operational Gmail mailbox received the Production email
  from `feedback@legendstudy.com`; sender, subject, Korean content, metadata
  and Feedback ID passed acceptance. Resend delivery is Production-verified.
- The exact Owner-confirmed fixture was processed once:
  `claimed=1, sent=1, failed=0`. DB postflight passed with `sent`,
  `attempt_count=1`, non-null `sent_at`, cleared claim fields and no error.
- Deleted only the exact fixture by ID after acceptance; cascade removed its
  notification. Target feedback/notification counts are 0, remaining TEST
  feedback/outbox counts are 0, and actionable outbox count is 0.
- Rotated only `FEEDBACK_WORKER_SECRET` because the old raw value was
  unavailable; stored the rotated value in Vault without recording it in Git
  or Wiki. `LEGENDSTUDY_ADMIN_EMAIL` now uses the Owner-controlled operational
  Gmail mailbox; `LEGENDSTUDY_EMAIL_FROM` remains `feedback@legendstudy.com`.
- Enabled exactly one active `pg_cron` + `pg_net` job,
  `legendstudy_feedback_notification_worker`, on `* * * * *` with the exact
  LegendStudy function endpoint and Vault-held invocation header. No
  service-role key is used, no duplicate job exists, and no second test email
  was sent.

## 2026-09-18 — Home content priority adjustment

- Reordered only the Home sections after 자료 검색: 최근 본 자료 now precedes
  최근 업데이트 to prioritize the user's personal re-entry history over the
  global content feed.
- Preserved both sections' existing loading/empty behavior and 2→6
  expand/collapse behavior. No provider, navigation, database or Production
  behavior changed.
- Audited further Home personalization: profile/schema, cloud persistence and
  Guest/Auth merge policy would be required, so no local-only preference was
  introduced; defer the implementation plan to Day 13-A.

## 2026-09-18 — LS LAB Production Web architecture decision

- Recorded the Owner-approved canonical Production direction: separate Next.js
  App Router + TypeScript Web architecture in the `LC3808/legendstudy-lab-web`
  repository candidate; the Manus React/Vite/Express/tRPC foundation remains
  mock/prototype and the Flutter repository remains Mobile-only.
- Recorded Phase 0/1 research outputs as research status, not Production
  ingestion approval: 42 universities, 53 recruitment rows, 42/42 source
  audits, 188 historical source records, 330 official Quick Link candidates,
  188 component records, and separate 42-row rights/use and evaluation-
  readiness registers.
- Defined public metadata/provenance/official Quick Links versus private
  source-derived, evaluation and user data boundaries; recorded taxonomy,
  server-side evaluation job lifecycle, server-authoritative credit direction,
  and official-versus-derived labeling.
- Phase 2 is Next.js Web Foundation Migration. No code, repository creation,
  Supabase schema/Auth, AI, payment, domain, deployment or Production change
  was made.

## 2026-09-18 — Historical Exam Expansion Phase 1-A inventory

- Audited the applied schema semantics and repository ingestion artifacts for
  2020–current without crawling or writing data. The committed candidate set
  covers 2024–2026: 38 exams, 609 occurrences and 1,205 resources.
- Owner SQL postflight verified 2020–current Production coverage: 23 exams,
  363 occurrences and 739 resources; 2025 has 15 exams, 2026 has 8, and
  2020–2024 have zero rows. Current-year future/unpublished rows are not
  classified as missing.
- Owner also found 23 open `resource_url_expiring` quarantine rows mapped to
  the historical scope; no 1:1 relation to exams is assumed.
- Added read-only coverage CSVs, missing matrix, inventory report and Codex
  handoff under `reports/historical-exam/`. Phase 1-A is now ready for
  deterministic-key reconciliation; publication remains gated.

## 2026-09-18 — P2-A social login foundation

- Audited the Google/Apple/Kakao buttons against the real SDK contract and
  found four code gaps behind the "provider not configured" verdict: no Android
  callback filter, an ignored `signInWithOAuth` false result that left the
  screen permanently disabled, no return policy after a successful callback,
  and no seam to test any of it.
- Registered `com.legendstudy.app://login-callback` on Android (iOS already
  matches by scheme), constant-ised the callback, added an OAuth service seam,
  and gave password and social sign-in one shared return policy.
- Stopped a cancelled social login (`access_denied`) from being read as a
  recovery link failure by preferring the specific `error_code`.
- New `test/auth_oauth_test.dart` (16). No Production mutation: no Supabase,
  Google, Apple or Kakao console change, no Auth user, no DB write.

## 2026-09-18 — P2-B account deletion and privacy foundation

- Inventoried every `auth.users` reference in the applied migrations rather
  than assuming cascade: seven tables, six cascading and feedback detaching,
  which means deleting the auth user is the whole deletion and no migration is
  required.
- Added a server-authoritative delete-account Edge Function candidate (caller
  from the token, body ignored, admin refused, idempotent, nothing logged) with
  Deno tests, and a fail-closed Flutter foundation: seam, two-step confirmation
  screen, MY entry, route, Korean failure copy and local study purge.
- Recorded the Apple and Google Play deletion requirements from their official
  pages, including the two gaps LegendStudy still has: the web deletion-request
  URL and Sign in with Apple token revocation.
- No Production mutation: nothing deployed, no Auth Admin call, no account
  deleted, no DB or RLS change.

## 2026-09-18 — end-of-day product decision closeout

- Auth: account deletion and social-login foundations were verified on the
  Owner's Mac (focused 63 PASS, full 412 PASS with one existing skip, analyze
  PASS, delete-account Deno 9/9). Foundations are READY; Production OAuth E2E
  and Production deletion E2E both remain PENDING, as does Apple Sign in with
  Apple token revocation.
- Historical: Phase 1-A1 (2024 reconciliation) was interrupted by quota
  exhaustion and is marked INTERRUPTED / RECHECK REQUIRED; its trailing figures
  are preliminary and were not promoted. Gemini's "publication architecture
  ready" verdict was recorded as an architecture judgement only.
- LS LAB: recorded the essay-centric product model (전형명 becomes provenance;
  University → Essay → Track → QuestionSet → Question), the four separate axes,
  Core-first depth with Owner-only Core selection, the multimodal
  `answer_format`/`input_mode` split with a staged rollout, and the Public
  Catalog figures with structural QA PASS / publication CONDITIONAL.
- The decisive new state: **Core University selection is HOLD until the Owner
  review next week**, together with the list of work that does not start before
  it. Documentation only — no code, no Production mutation.

## 2026-09-19 — Academic Analytics and Achievement roadmap recorded

- Product decision: Study and Mock Exam are not standalone features but the
  first data sources of Subject Study Tracking → Academic Record → Academic
  Analytics → Achievement Engine, with Academic Profile → Target
  University/Department → Admissions Engine alongside.
- The earlier badge/achievement idea was reinstated as an Achievement Engine
  based on learning behaviour and confirmed growth, with the two kinds modelled
  separately, prediction-style badges forbidden, and the Achievement and
  Admissions engines kept apart.
- Recorded the binding boundaries — study time is not an admission-probability
  predictor, correlation is not causation, a score gap is not an admission
  probability, and LS LAB essay results never share a score scale with
  모의고사/내신.
- New `wiki/roadmap-academic-analytics.md`, two durable entries in
  `decisions.md`, a PLANNED entry in `current-status.md`, an index link and a
  cross-reference from `product-scope.md`. v1.0 scope unchanged. Documentation
  only; no code, no schema, no Production mutation.

## 2026-09-19 — Monetization and in-app learning strategy recorded

- Product decision: Web and App take different roles, and features are now
  evaluated on user value, app advantage, retention and monetization together.
- Recorded the in-app PDF viewer direction with a recent-three-years 고3 pilot,
  the separation of metadata coverage from viewer coverage, the permanent
  source-page fallback, and the storage/cache measurements that must precede any
  expansion. Noted explicitly that a mirrored copy is still blocked by the
  deferred rights decision from Day 9, so the strategy does not override the
  2026-09-12 no-bulk-mirroring rule.
- Recorded that premium sells analysis, AI and continuity rather than basic
  access: FREE / BASIC / ADVANCED / MAX as concept, an approximately three-use
  free trial as direction, subscription + credits for AI-heavy features, MAX not
  equal to unlimited AI, and the ₩4,900 ad-removal purchase kept as a separate
  product role.
- Reinstated **Community** on the product map as PLANNED with a FREE / RETENTION
  role — 학교 급식 자랑 and 잡담 first, moderation and safety designed with the
  posting feature, and explicitly not a launch blocker.
- New `wiki/roadmap-monetization-and-in-app-learning.md`, five durable entries in
  `decisions.md`, a PLANNED entry in `current-status.md`, an index link and
  cross-references from `product-scope.md` and `architecture.md`. v1.0 scope
  unchanged. Documentation only; no code, no schema, no Production mutation.

## 2026-09-20 — Historical Phase 1-A1 resumed and inventory closed

- Revalidated from starting HEAD `6474b4e`; interrupted temporary work was not
  treated as evidence. Historical/current parser × fixture replay explains all
  23 additional Box resources from `bf89548`; original 1,205 rows unchanged.
- Current 38/609/1,228; 2024 15/246/489; grade 3 7/151/299. Wrote exact drift,
  natural-key, candidate, resource and raw-subject-pairing CSVs and dry-run reports.
- All candidate keys unique, no merge candidates, inactive rows, source-clock
  determinism and raw-label safety verified. Three ambiguous grade-3 files remain
  unscoped; 7 candidate URL expiration advisories remain. No publication claim.
- Ingestion 146 PASS + 4 historical regression tests PASS; CSV/static/credential
  checks PASS. Production exact keys remain UNVERIFIED; added unexecuted Owner
  SELECT pre/post evidence and controlled-batch handoff. Inventory/dry run COMPLETE;
  publication NOT READY. No Production mutation, PDF download, Storage or push.
