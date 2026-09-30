# Product Scope

Current Owner clarification2026-09-30: [post-audit Product boundaries](product-architecture.md#post-audit-owner-alignment--2026-09-30) and [Essay first → post-CSAT admissions → January expansion](roadmap-academic-analytics.md#phased-and-source-gated--owner-clarification-2026-09-30) take precedence over earlier broad defer/order wording. Future Academic/Admission remains phased and source-gated, not cancelled. No new foundation implementation is authorized.

**Current Owner target2026-09-29:** [2026–2027 canonical roadmap](roadmap-monetization-and-in-app-learning.md#20262027-roadmap-and-monetization--owner-decision-2026-09-29) 우선.
10월 중순 App+Essay Store 출시·10월 말 안정화 후 Mock/CSAT BETA, 2027 내신/Admissions.
아래 과거 순서는 이 목표로 대체되며 미구현 기능의 자동 승인/완료를 뜻하지 않는다.

**Historical Owner priority2026-09-27:** Materials final device QA → Essay LAB canonical
model (separate instruction) → internal-grade → mock-score → admissions.
[Source policy, corpus target and handoff](materials-closeout-essay-lab-handoff.md).
No Essay LAB/payment/admissions implementation is included in Materials closeout.

## Current delivery priority — 2026-09-20

Current cross-product priority is Auth Production completion → App/Web boundary
→ LAB authenticated IA/UX → Core release readiness → Academic Record/Analytics
→ Essay service → Teacher/School B2B. Canonical direction and scope limits live in
[product architecture](product-architecture.md) and [platform boundaries](product-platform-boundaries.md).
Materials remains independent and free; Guest access and existing Core quality
must be preserved. Daily Sync stays a backlog contract, not newly authorized work.
Older targets below are historical, not implementation claims or an override of
this order. Email/password exists; social-only is superseded, provider flags and
Production acceptance remain gates. Viewer, payments, Achievement, Community
and B2B implementation are not authorized by this documentation update.

## v1.0 target

### Core content experience
- Home with recent public content across exam materials, study collections, education/admissions columns and university essays, plus the planned major exam countdown
- Browse by content type; exam-specific grade/year/session/type/subject filters where data supports them
- Unified content search and native content detail; optional resources/type-specific metadata
- Resource detail page
- PDF viewing
- Answer/explanation access
- English listening/audio access where available
- Recent items across all content types
- Saved/bookmarked items across all content types

### Account/personalization
- Google login
- Apple login
- Kakao login
- Naver login
- Social-login-only; no Facebook, X or email/password signup in v1
- My page
- School and grade settings (persistence requires login)
- NEIS school meals
- Study timer: guest temporary execution allowed, durable history requires login
- Study-time history and accumulated time for authenticated users
- Cross-device sync for personalized data when logged in

### Notifications
- New material notifications
- Major exam schedule notifications

### Monetization foundation
- Free app with ads; no interstitial ads in v1
- ₩4,900 one-time “커피 한 잔 후원” permanently removes ads
- Not a subscription and not a core-feature unlock
- No ads in PDF viewing, timer execution, login, school setup or between important CTAs

## Explicitly not required for initial v1.0

- Community / free-talk board
- Meal-photo/community
- Advanced badge/achievement system
- Friends/ranking
- AI/personalized recommendation engine
- Early-admission acceptance prediction service

These may be promoted into v1.0 only by an explicit product decision recorded in `decisions.md`.
The long-term shape of the achievement system and the admission-prediction
service is recorded in [roadmap-academic-analytics.md](roadmap-academic-analytics.md);
that roadmap does not promote either into v1.0.
The long-term shape of Community, the in-app viewer and paid tiers is recorded in
[roadmap-monetization-and-in-app-learning.md](roadmap-monetization-and-in-app-learning.md);
that roadmap does not promote Community into v1.0 either.

## UX principle

Study material access should not require login unless the operation is inherently personal (save/sync/profile/etc.).

## Day 3 schema boundary

Push notifications remain in v1.0 product scope: new material and major exam
schedule notifications. Data Model v0.1 covers content + basic personalization
only. Device push tokens, notification preferences and delivery backend are
intentionally deferred to a later **v1.0 implementation milestone**, not v1.1/v2.
No profiles.interest_subjects array is added; any future subject preference uses
an explicitly designed normalized relation.

## Unified content boundary

General study PDFs, education/admissions columns, university essay materials and
other reviewed educational content do not require an exam record. Original-post
opening is permitted from native cards/details; a full native article body is not
required in this schema milestone. The app does not scrape HTML during normal use
or become a WebView clone. Home “recent updates” means known source publication/
modification time, not app ingestion time. No recommendation engine, university
master or additional social functionality is introduced by this clarification.

## Day 5 scope update

The owner explicitly promoted school settings, NEIS meals, timer/history, social
Auth and the ad-removal support purchase into v1. See ui-ux-v1.md for the approved
policy and guest/auth boundary. This does not authorize backend implementation in
Day 5: only Home/Materials/Study/MY navigation and UI skeletons, with existing
ContentRepository reads retained. Saved is under MY, not a bottom tab.

## Integrated In-App Exam V1 boundary

[Canonical In-App Exam architecture](architecture-in-app-exam.md) refines the
previous viewer → attempt ordering. Primary mobile is paper-first/answer-first:
exam selection → Attempt → OMR/answers → unanswered review → submit → server
score → raw score/basic grade/cutoff → Academic Record → history/basic comparison.
Viewer is optional and failures cannot block this engine. Optional Tablet viewing
remains a separate route. This feature-V1 contract does not promote all roadmaps
into the initial app release. Deep Analytics/AI strategy remains V2+; original
rights/storage restrictions stand and integrated engine readiness is CONDITIONAL.

## Owner MY Achievement surface amendment — 2026-09-23

MY collection access and a compact earned-achievement visual are accepted product
directions. FOUNDATION only in this release: data/UX contract in
[Achievement Engine](roadmap-academic-analytics.md#9-achievement--badge-engine).
No catalogue, award persistence, collection UI or Level system is implemented.
Advanced badge/achievement engine remains outside the initial required release;
roadmap examples are not approved production awards. No migration is required by
this documentation foundation.

## Analytics layer and research scope — 2026-09-24

[Three-layer allocation](product-architecture.md#academic-analytics-three-layer-allocation--2026-09-24)
is approved direction: MY snapshot / Mobile LAB actionable analysis / Web LAB deep
work. Candidate checkers, simulations, advanced analytics, admissions judgments and
notification delivery are not newly implemented or approved by this UI task.
[Research registry](research-registry.md) records Daily Sync research complete per
Owner, implementation pending; original report evidence remains unavailable here.
Admission probability/bands/automatic eligibility/AI judgment are research-gated,
not permanently removed. Compliance P0 evidence audit remains pending.

## Longitudinal strategy scope — 2026-09-24

[Longitudinal Learning and Admissions Data Strategy](longitudinal-learning-admissions-data-strategy.md)
is an Owner-adopted HIGH / CANONICAL PRODUCT STRATEGY, not a v1 feature promotion.
Data preservation/context/provenance must inform future designs now; full personal
history, Application/Outcome, cohort, consulting and predictive models advance by
their separate scope/data/privacy/statistical/evidence gates. Existing excluded
features and meaningful Guest/free access remain. This update implements nothing.
