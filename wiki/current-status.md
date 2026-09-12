# Current Status

Last reviewed: 2026-09-12

## Phase

**Phase 1 — implementation kickoff / Flutter scaffold ready**

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
- Flutter application scaffold has not yet been created
- Supabase project/schema for LegendStudy has not yet been created or verified
- No production ingestion pipeline exists yet
- No app build exists yet

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

1. Codex creates the Flutter scaffold and baseline folder architecture
2. Establish package/bundle identifiers before platform-specific signing or OAuth setup
3. Add baseline navigation, theme/design tokens, environment configuration pattern, linting, and smoke tests
4. Define normalized data model v0.1 from representative current + legacy content patterns
5. Prepare Supabase schema/migrations for direct user execution
6. Build ingestion prototype and validate against representative posts across multiple years
7. Re-check sitemap/RSS/robots/direct attachment behavior during ingestion implementation; these remain unverified where current tooling could not conclusively inspect them

## Known open questions

- Final Flutter package/application identifiers
- Supabase project creation timing and environment naming
- Exact content taxonomy needed to represent historical posts consistently
- PDF/audio storage strategy: source-link preservation vs selective mirroring
- AdMob/IAP timing for v1.0
- Final state-management package choice for the scaffold
