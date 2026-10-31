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
- `ingestion.md` — legendstudy.com ingestion strategy
- `ui-ux-v1.md` — approved UI/UX v1.1 canonical implementation specification; required before UI changes
- `design-system.md` — visual identity and UI design tokens
- `decisions.md` — durable product/architecture decisions
- `log.md` — chronological development log

### Task-specific (2026-11-01 베타 출시 마케팅 & 논술 LAB 정비)

- `beta-launch-marketing-20261101.md` — 마스터 인덱스 + §A 배너 + §B 티스토리 삽입 + §G 정책 + §H 인수인계 + §17 보고
- `web-main-slider-fix-20261101.md` — 메인 슬라이더(티스토리) 원인·수정·검수
- `essay-support-status-ux-20261101.md` — 서강/건국 지원상태 불일치 + 4-state UX
- `essay-schedule-intake-20261101.md` — 논술 일정 입력 양식·검증(`assets/essay-schedule/`)
- `marketing-analytics-events-20261101.md` — 마케팅 Analytics(기존 v1 재사용·확장)

## Canonical-source rule

There must be only one canonical `current-status.md` for the repository. Notion, chats, external documents, Claude notes, Manus reports, and ChatGPT plans may support the project, but they do not replace this repository-local wiki.
