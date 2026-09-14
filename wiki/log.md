# Development Log

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
