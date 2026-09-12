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
