# Durable Decisions

This file records long-lived product and architecture decisions. Routine progress belongs in `log.md` and `current-status.md`.

## 2026-09-12 — Project independence

LegendStudy is fully separate from Muselry, including repository, codebase, Supabase, secrets, OAuth setup, identifiers, wiki, and deployment.

## 2026-09-12 — Native app, not WebView

LegendStudy will not be implemented as a simple WebView wrapper around `legendstudy.com`.

## 2026-09-12 — Canonical knowledge location

The repository-local `wiki/` directory is the official long-term development knowledge base. There must be only one canonical `wiki/current-status.md`.

## 2026-09-12 — Agent role split

- Codex: main coder
- Claude: support coder / code reviewer
- ChatGPT: planning, architecture, specification, review
- Manus: execution, Git/build/deployment support; Supabase direct work only when specifically useful
- User: final product decisions and default direct executor of Supabase SQL/migrations

## 2026-09-12 — Public repository during early development

The repository starts public to reduce multi-agent access friction. Before private conversion, access for all required development agents must be verified. Secrets are forbidden from Git regardless of repository visibility.

## 2026-09-12 — Structured ingestion

The app should consume normalized structured data. `legendstudy.com` content should be ingested into the backend rather than scraped by the mobile app during normal usage.

## 2026-09-12 — Login philosophy

Public study-resource access should not require login where possible. Login is primarily for personalization and synchronization.

## 2026-09-12 — Production application identity

Owner-approved in Day 2 / issue #3: use `com.legendstudy.app` for both Android
applicationId/namespace and the iOS Runner bundle identifier. Dart package remains
`legendstudy_app`; both platforms display `레전드스터디`. The iOS test-only bundle
uses `com.legendstudy.app.RunnerTests` to remain distinct from the app target.

This decision replaces Day 1's temporary identity and is independent of Muselry.
It does not imply Apple/Google registration, signing or OAuth configuration.
If platform registration reports a conflict, report it to the owner and keep the
choice unresolved rather than silently inventing another production identifier.
