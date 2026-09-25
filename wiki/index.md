# LegendStudy Wiki Index

This directory is the canonical long-term development knowledge base for LegendStudy.

## Read order

1. `../AGENTS.md`
2. This Task Routing Map
3. [Current Status](current-status.md)
4. [Durable decisions](decisions.md)
5. [Product scope](product-scope.md)
6. Required task-domain documents below, then actual code/runtime/tests.

Search all Wiki with Korean/English aliases before proposing a new concept.
Newest explicit Owner decisions supersede historical scope; record exact scope,
not an inferred promotion of a whole roadmap. Current is not historical evidence.

## Task Routing Map

DATABASE / Study / Score / Mock / MY / LAB / Admissions / Essay / Application /
Outcome / Onboarding / Marketing / Achievement / Notifications / Analytics /
Monetization / B2B 설계는 아래 상위 Longitudinal Strategy를 먼저 읽고 domain
문서를 읽는다. 이 전략은 구현 승인이나 현재 기능 목록이 아니다.

| Task / aliases | Required canonical reading |
|---|---|
| LONGITUDINAL / DATABASE / SCORE / ANALYTICS / ADMISSIONS / 공부시간 데이터 / 공부시간과 성적을 분석하자 / 성적 기록 / 성적 추이 / 모의고사 결과 / 내신 분석 / 수능 성적 / 지원 대학 / 수시 / 정시 / 논술 지원 / 합격/불합격 / 합격 데이터를 모으자 / 합격 예측 / 비슷한 학생 / cohort / 빅데이터 / 컨설팅 | **먼저 [Longitudinal Learning and Admissions Data Strategy](longitudinal-learning-admissions-data-strategy.md)** → 해당 domain 문서. [Data preservation](longitudinal-learning-admissions-data-strategy.md#preservation-and-architecture-review), [cohort/privacy](longitudinal-learning-admissions-data-strategy.md#cohort-analytics-and-minimum-cohort), [prediction gate](longitudinal-learning-admissions-data-strategy.md#admissions-evidence-and-prediction-gate); DATABASE는 이어서 [Database](database.md), SCORE는 [Academic roadmap](roadmap-academic-analytics.md) |
| ONBOARDING / 온보딩 / 정보 입력 / 마케팅 / MARKETING / MONETIZATION / B2B / 데이터 사업화 / 학생 데이터 판매 | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Progressive profiling](longitudinal-learning-admissions-data-strategy.md#progressive-profiling-and-onboarding), [acquisition](longitudinal-learning-admissions-data-strategy.md#acquisition-and-marketing-strategy), [B2B boundary](longitudinal-learning-admissions-data-strategy.md#external-sharing-and-b2b-boundary), [Monetization](roadmap-monetization-and-in-app-learning.md), [Privacy](account-deletion-privacy.md) |
| DESIGN / HOME / UI v2 / UI 다시 수정하자 | [Owner Device PASS / frozen surfaces](design-system.md#ui-v2-owner-device-closeout--2026-09-24), [Current design system](design-system.md), [v2 approved specification](design-system-v2-proposed.md), [UI conventions](ui-ux-v1.md), [Home policy](day-10-b-home-polish.md) |
| AUTH / 로그인 / logout / account / Kakao | [Decisions — login philosophy](decisions.md#2026-09-12--login-philosophy), [native acceptance](auth-native-owner-acceptance.md), [recovery](auth-recovery.md), [deletion/privacy](account-deletion-privacy.md), [current account UX](core-app-improvements.md) |
| STUDY / TIMER / 공부 추이 | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Study v1 and current chart overrides](study-v1.md), [Study UI and Owner overrides](day-8-study-ui-review.md), [Study storage](day-8-study-storage-proposal.md), [current UI convention](ui-ux-v1.md) |
| MOCK EXAM / SCORING / 모의고사 / 모의고사 완성하자 | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Mock Exam](day-8-mock-exam.md), [Current foundation and Phase2 gaps](day-8-d2-answer-scoring.md#end-of-day-foundation-and-phase2-gaps--2026-09-24), [Official/free dual modes](day-8-d2-answer-scoring.md#owner-follow-up-3--dual-practice-modes), [scoring](mock-exam-scoring-v1.md), [current exam→subject→key→result workflow and gaps](day-8-d2-answer-scoring.md#current-exam-selection-and-scoring-handoff--2026-09-24), [grade result](day-8-d3-grade-result.md), [scoring storage](day-8-scoring-storage-proposal.md) |
| ACHIEVEMENT / BADGE / 배지 / Level | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Achievement decision](decisions.md#2026-09-19--achievements-record-behaviour-and-confirmed-growth-never-prediction), [Achievement / Badge Engine](roadmap-academic-analytics.md#9-achievement--badge-engine), [current product scope](product-scope.md) |
| MEAL / SCHOOL / NEIS / 급식 다음 제공일 | [NEIS](day-7-neis.md), [current time/fallback/Home expanded policy](day-10-b-home-polish.md), [school storage](day-7-school-storage-proposal.md), [school/profile UX](core-app-improvements.md) |
| MY / PROFILE / SETTINGS / 프로필 | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [UI conventions](ui-ux-v1.md), [design system](design-system.md), [database/private avatar](database.md), [current profile/account UX](core-app-improvements.md), [personal ownership](day-9-c-personal-state.md), [Design System v2 — IMPLEMENTED](design-system-v2-proposed.md) |
| LAB / ACADEMIC ANALYTICS | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [platform boundaries](product-platform-boundaries.md), [product architecture](product-architecture.md), [academic roadmap](roadmap-academic-analytics.md), [Essay roadmap](roadmap-essay-lab.md), [App LAB details](core-app-improvements.md) |
| MATERIALS / 자료 | [search](day-9-search-explore.md), [resources](day-9-c-resource-detail.md), [personal state](day-9-c-personal-state.md), [saved/recent](day-9-c-personal-lists.md); [Resolver ready-to-deploy handoff](day-9-c-resource-detail.md#production-activation-preparation--2026-09-25) |
| MATERIALS RESOURCE / PDF / 자료 바로 보기 / 문제지 / 정답 / 해설 / SAFE OPEN | [Resource detail + Safe Open](day-9-c-resource-detail.md) → [product scope](product-scope.md#core-content-experience); direct PDF open is release-critical and external/source fallback remains the current boundary |
| D-DAY / D-Day 여러 개 / CALENDAR / 달력 / 일정 / 여러 일정 / 수행평가 일정 | [Home personalization and event collection](home-personalization-and-events.md) → [D-Day storage](day-7-dday-storage-proposal.md), [Home policy](day-10-b-home-polish.md) |
| HOME CUSTOMIZATION / 홈 커스터마이징 / 학생 / N수생 홈 / 학부모 홈 / 교사용 홈 / 학원 / 홈 화면 설정 / 홈 메뉴 숨기기 | [Home personalization and event collection](home-personalization-and-events.md) → [Home policy](day-10-b-home-polish.md), [product architecture](product-architecture.md) |
| ANALYTICS PLATFORM / analytics.legendstudy.com / 관리자 / 빅데이터 / cohort / 데이터 분석 | [Longitudinal strategy](longitudinal-learning-admissions-data-strategy.md) → [product architecture](product-architecture.md#analytics-platform-direction--2026-09-25) → [academic roadmap](roadmap-academic-analytics.md) |
| ADMISSIONS DATA / ANALYTICS / 입시 데이터 / 합격 가능성 | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Owner allocation](product-architecture.md#academic-analytics-three-layer-allocation--2026-09-24), [roadmap / research gate](roadmap-academic-analytics.md#research-boundary--2026-09-24), [Manus registry](research-registry.md), [decisions](decisions.md) |
| DAILY SYNC / INGESTION / Daily Sync 시작하자 / 사이트에 새 글 올렸는데 앱에 안 보여 / Pilot C / quarantine | [Current ingestion handoff](ingestion.md#daily-sync-current-handoff--2026-09-24) → [Phase 1 deterministic delta package](daily-sync-phase-1-deterministic-delta-package.md) → [Research synthesis](research-2026-09-24-product-operations-synthesis.md) → [Current baseline/status](current-status.md#daily-sync-status); [historical pipeline](day-9-ingestion.md), [source provenance and reconciliation](research-registry.md#owner-provided-manus-exports--source-acquired) |
| COMPLIANCE / RELEASE / App Store 출시 | [Privacy/deletion](account-deletion-privacy.md), [Auth acceptance](auth-native-owner-acceptance.md), [current release gates](current-status.md), [Community safety](product-platform-boundaries.md), [research audit boundary](research-registry.md) |
| PRODUCT STRATEGY | [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md) → [Product architecture](product-architecture.md), [scope](product-scope.md), [strategy](roadmap-monetization-and-in-app-learning.md), [Manus registry](research-registry.md) |
| COMMUNITY / 커뮤니티 | [monetization/learning roadmap](roadmap-monetization-and-in-app-learning.md), [Community decision](decisions.md#2026-09-19--community-is-a-free-retention-feature-not-a-launch-blocker), [Profile privacy and safety gates](product-platform-boundaries.md), [private profile](database.md), [research/compliance registry](research-registry.md) |

[Policy/code evidence audit](mobile-policy-audit.md) distinguishes gaps from
implemented/local-tested/Owner-verified claims. Existing document directory below
is preserved; historical checkpoints are accessed only when evidence is needed.

## Product/platform canonical entry points

- [Longitudinal Learning and Admissions Data Strategy](longitudinal-learning-admissions-data-strategy.md) — **HIGH / CANONICAL PRODUCT STRATEGY**, event 보존·cohort·지원/결과·사업화의 상위 원칙; architecture PLANNED

- [Product family and B2B architecture](product-architecture.md) — App/LAB/Teacher/School, shared data/engine, future access/security, priority
- [App/Web platform boundaries](product-platform-boundaries.md) — quick action vs deep work, public IA, domain strategy
- Essay and Analytics roadmaps below retain module-specific detail; they do not redefine the product family.

## Documents

- [Flutter toolchain and dependency audit](flutter-toolchain.md) — canonical SDK/helper, constrained upgrades and deferred native migrations

- [App native Auth and shared-account Owner acceptance](auth-native-owner-acceptance.md) — platform paths, console coexistence, debug comparison and physical checklist

- `core-app-improvements.md` — Materials/account improvements, evidence and Owner release gates

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
- [Design System v2 — IMPLEMENTED](design-system-v2-proposed.md) — Owner-approved Palette A, implemented UI mapping and device-review gate
- `decisions.md` — durable product/architecture decisions
- `log.md` — chronological development log
- `roadmap-essay-lab.md` — Essay service-module research-first roadmap
- `day-10-b-home-polish.md` — Home meal and expandable recent sections

- [Historical checkpoint: Flutter 3.47.5 / Dart 3.13.4 and Owner E2E](history/status-checkpoints.md#2026-09-21-end-of-day-canonical-checkpoint)

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

- [LAB Essay Service Module Roadmap — research complete; Phase 2 Web architecture recorded](roadmap-essay-lab.md)
- [Academic Analytics → Achievement → Admissions Engine Roadmap — PLANNED, not implemented](roadmap-academic-analytics.md)
- [Monetization & In-App Learning Strategy — PLANNED, not implemented](roadmap-monetization-and-in-app-learning.md)
- [Day 10-B Home Polish v2 — implemented; device launch follow-up](day-10-b-home-polish.md)
- [Day 10-C Legacy Subject Alias — minimum foundation implemented](legacy-subject-aliases.md)
- [Day 11 Account, Personal and Feedback Operations — foundation / Production pending](day-11-account-personal-feedback.md)
- [Day 11-B1 Feedback production security closeout — COMPLETE / Production verified](day-11-b-feedback-production.md)
- [Day 11-B3 Admin Inbox — implemented; Production E2E pending](day-11-b3-admin-inbox.md)
- [Day 11-B4 Feedback Email — worker deployed; delivery E2E pending](day-11-b4-feedback-email.md)
- [Day 12 Home visual hierarchy — implemented](day-12-home-visual-hierarchy.md)

- [Auth Recovery — code verified; Production E2E pending](auth-recovery.md)
- [Account Deletion & Privacy — foundation implemented; Production deletion pending](account-deletion-privacy.md)

- [In-App Exam architecture — paper-first engine / independent Viewer gates](architecture-in-app-exam.md)

- [Mobile IA / Profile / Learning handoff](core-app-improvements.md#mobile-ia-profile-and-learning--2026-09-23)

- [MY dashboard / Study Trends / private avatar refinement](core-app-improvements.md#my-dashboard-study-trends-and-lab-refinement--2026-09-23)
