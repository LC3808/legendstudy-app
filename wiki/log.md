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
- Current inventory supersedes the historical baseline above: 68 statements,
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
