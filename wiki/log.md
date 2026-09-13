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
