# Current Status

Last reviewed: 2026-09-12

## Phase

**Phase 0 / Day 0 — repository and canonical wiki initialization**

## Verified state

- GitHub repository exists: `LC3808/legendstudy-app`
- Visibility: Public during early development for multi-agent development convenience
- Default branch: `main`
- Repository was initialized on 2026-09-12
- `AGENTS.md`, `CLAUDE.md`, and canonical `wiki/` seed are being established
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

## Immediate next steps

1. Finish Day 0 seed files
2. Re-verify `legendstudy.com` structure, content taxonomy, attachment patterns, RSS/sitemap availability, and ingestion constraints
3. Confirm v1.0 scope
4. Define initial normalized data model
5. Create Flutter scaffold and baseline architecture
6. Prepare Supabase schema/migrations for user execution
7. Build ingestion prototype

## Known open questions

- Final Flutter package/application identifiers
- Supabase project creation timing and environment naming
- Exact content taxonomy needed to represent historical posts consistently
- PDF/audio storage strategy: source-link preservation vs selective mirroring
- AdMob/IAP timing for v1.0
