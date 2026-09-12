# Current Status

Last reviewed: 2026-09-12

## Phase

**Phase 0 complete / pre-implementation validation**

## Verified state

- GitHub repository exists: `LC3808/legendstudy-app`
- Visibility: Public during early development for multi-agent development convenience
- Default branch: `main`
- Repository initialized on 2026-09-12
- `AGENTS.md`, `CLAUDE.md`, `.gitignore`, and canonical repository-local `wiki/` seed exist
- Canonical reading order has been verified: `AGENTS.md` → `wiki/index.md` → `wiki/current-status.md`
- Initial `legendstudy.com` structure was re-checked on 2026-09-12
- The site currently exposes 1,673 archive items and representative exam posts contain multiple resources per post (PDFs, MP3, grade-cut material)
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

## Immediate next steps

1. Complete deeper ingestion re-validation: sitemap/RSS/archive mechanics, older post variants, direct attachment behavior, robots constraints
2. Freeze the v1.0 scope after final review
3. Define normalized data model v0.1 from representative content patterns
4. Create Flutter scaffold and baseline architecture
5. Prepare Supabase schema/migrations for direct user execution
6. Build ingestion prototype and validate against representative posts

## Known open questions

- Final Flutter package/application identifiers
- Supabase project creation timing and environment naming
- Exact content taxonomy needed to represent historical posts consistently
- PDF/audio storage strategy: source-link preservation vs selective mirroring
- AdMob/IAP timing for v1.0
