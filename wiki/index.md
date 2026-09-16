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
- `study-home-ui-polish.md` — Study/Home polish, visual review and iPhone physical acceptance subset
- `design-system.md` — visual identity and UI design tokens
- `decisions.md` — durable product/architecture decisions
- `log.md` — chronological development log
- `roadmap-essay-lab.md` — planned Essay Lab priority and October 2026 roadmap
- `day-10-b-home-polish.md` — Home meal and expandable recent sections

- [Day 10-A Flutter 3.47.3 official toolchain migration — COMPLETE](current-status.md#day-10-a--flutter-3473-official-toolchain-migration--complete)

## Canonical-source rule

There must be only one canonical `current-status.md` for the repository. Notion, chats, external documents, Claude notes, Manus reports, and ChatGPT plans may support the project, but they do not replace this repository-local wiki.

- [D-Day storage — applied and runtime verified](day-7-dday-storage-proposal.md)

- [Study v1 — Day 8 approved design and UI contract](study-v1.md)
- [Day 8 Study storage — deployed migration / JWT acceptance PASS](day-8-study-storage-proposal.md)

- [Day 8 Study migration — copy-ready Owner SQL package](day-8-study-migration-package.md)

- [Day 8 Claude Study UI review and Owner overrides](day-8-study-ui-review.md)

- [Day 8-C Mock Exam — Guest/Auth runtime PASS / physical checks pending](day-8-mock-exam.md)

- [Day 8-D Mock Exam scoring — architecture proposal](mock-exam-scoring-v1.md)
- [Day 8-D1 Scoring storage — COMPLETE, actual JWT/RPC PASS](day-8-scoring-storage-proposal.md)

- [Day 8-D1 Scoring — applied SQL execution package](day-8-scoring-migration-package.md)

- [Day 8-D1 Scoring — actual JWT acceptance PASS and fixture cleanup](day-8-scoring-jwt-acceptance.md)

- [Day 8-D2 Answer Entry + Raw Score — COMPLETE, Guest/Auth Flutter PASS](day-8-d2-answer-scoring.md)

- [Day 8-D3 Grade + Result UX — COMPLETE, actual A/B Flutter PASS](day-8-d3-grade-result.md)

- [Day 9-A Search / Explore — COMPLETE / validation environment](day-9-search-explore.md)

- [Day 9-B Ingestion — survey, pipeline, dry-run; production gate open](day-9-ingestion.md)

- [Subjects taxonomy v1 — canonical subjects and raw-label mapping](day-9-subjects-taxonomy.md)

- [Day 9-B2 Pilot C — production apply package, not executed](day-9-pilot-c-package.md)

- [Day 9-C1 Resource Detail + Safe Open Target](day-9-c-resource-detail.md)
- [Day 9-C2 Bookmark + Recent Views](day-9-c-personal-state.md)
- [Day 9-C3 Saved / Recent UI + MY Integration](day-9-c-personal-lists.md)
- [Day 9-D1 Pilot C publication package — implemented; publication COMPLETE](day-9-d1-publication-package.md)

- [Essay Lab Product Roadmap — PLANNED, target 2026-10 Beta](roadmap-essay-lab.md)
- [Day 10-B Home Polish v2 — implemented; device launch follow-up](day-10-b-home-polish.md)
- [Day 10-C Legacy Subject Alias — minimum foundation implemented](legacy-subject-aliases.md)
- [Day 11 Account, Personal and Feedback Operations — foundation / Production pending](day-11-account-personal-feedback.md)
- [Day 12 Home visual hierarchy — implemented](day-12-home-visual-hierarchy.md)
