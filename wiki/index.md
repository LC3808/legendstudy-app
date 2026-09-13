# LegendStudy Wiki Index

This directory is the canonical long-term development knowledge base for LegendStudy.

## Read order

1. `../AGENTS.md`
2. `index.md`
3. `current-status.md`
4. For UI implementation: product-scope.md → architecture.md → database.md → design-system.md → ui-ux-v1.md
5. Other task-specific documents as applicable
6. Actual code, Git state, and DB/Supabase state

## Documents

- `current-status.md` — current implementation status, blockers, next actions
- `overview.md` — product purpose and project boundaries
- `product-scope.md` — v1.0 and later scope
- `architecture.md` — app/system architecture
- `database.md` — data model and Supabase policy
- `day-7-school-storage-proposal.md` — school persistence migration, owner deployment report and validation/rollback reference
- `day-7-neis.md` — server-key policy, deployed proxy and completed runtime acceptance
- `ingestion.md` — legendstudy.com ingestion strategy
- `ui-ux-v1.md` — approved UI/UX v1.1 canonical implementation specification; required before UI changes
- `design-system.md` — visual identity and UI design tokens
- `decisions.md` — durable product/architecture decisions
- `log.md` — chronological development log

## Canonical-source rule

There must be only one canonical `current-status.md` for the repository. Notion, chats, external documents, Claude notes, Manus reports, and ChatGPT plans may support the project, but they do not replace this repository-local wiki.

- [D-Day storage — applied and runtime verified](day-7-dday-storage-proposal.md)

- [Study v1 — Day 8 design and UI contract, approval pending](study-v1.md)
- [Day 8 Study storage — SQL proposal, not deployed](day-8-study-storage-proposal.md)
