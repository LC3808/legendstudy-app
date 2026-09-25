# Current Status

## Current product state

LegendStudy+ / 레전드스터디+, native Flutter App. Five tabs: Home / Materials /
Learning / LAB / MY. Guest-first materials search/filter/detail/external access;
owner-scoped saved/recent. Study Timer + Mock Exam/scoring/result foundation,
optional Mock study-time inclusion, KST shared aggregation. MY Profile/private
photo/school-grade, seven-day/eight-week/six-month study trends, actual Mock score
summary; LAB independent internal-grade/Mock details and external Essay entry.
Internal-grade backend, advanced analysis/admissions, Community, Level and full
Achievement Engine are NOT implemented. No WebView or shared App/Web session.

Current editing UX: Profile and school/grade Save success→previous screen once;
failed/partial save stays. School results directly below search. Chart uses actual
max, zero unpainted, oldest→newest, no horizontal scrolling. Login default HOME,
trusted explicit protected return preserved. Owner corrections now add logout HOME,
verified avatar read-after-write. Owner-approved Design System v2 now uses Orange /
Deep Navy / Cool Neutral, white grouped surfaces and plain section headings.
Guest MY exposes Login and hides private dashboard modules. Materials pages contain
5 items with explicit load-more after Owner device follow-up; Settings logout follows
service/policy groups. Home has an own-nickname greeting and small daily semantic
icons. Greeting uses compact16px hierarchy and a noninteractive planned bell slot.
D-Day name/date metadata sits above D-n; study label/value share a wrapping row.
Brand accent is now Owner-confirmed #FFA300; no peach selections. Meal's explicit
trailing control opens up to3 actual provided-day chips, lazily bounded past/future
context; preview14/19KST/7day policy unchanged. All major groups share a white surface, stronger cool-neutral border and the unchanged approved Home shadow; nested/items remain flat; Meal selection has
no checkmark. Timer/Trend daily summary shows displayed7day total + daily max,
with the neutral mean caption directly above its dashed line. Mock has official year/grade/month→actual subject/
variant/key and separate free title/time/manual-score practice. Free scores are
local personal records, excluded from official MY/LAB/admissions. MY confirmed correct-count snapshots push LAB and preserve Back.
[Canonical design](design-system.md) maps the approved proposal to implementation.

## Owner verified

- App and LAB Email/Google/Apple/Kakao Production login PASS (Owner report).
- App Profile-build session restore PASS; school/grade values device PASS.
- Apple and Google LAB/App shared identity PASS; Kakao equality NOT VERIFIED.
- Meal Owner E2E PASS: Home excludes breakfast,14/19KST progression, next eligible
  date within7 candidates D..D+6, expanded full-date meals. Keep implementation.
- Storage SQL acceptance is not App photo E2E. Owner reports first-photo false
  success on baseline; corrected photo/new UI device acceptance remains pending.
- Materials initial5/load-more, vertical study bars, MY→LAB→Back PASS (Owner follow-up2).
- UI_V2: OWNER DEVICE PASS. Home/Materials/global/Learning/LAB/MY/Settings surfaces,
  Study chart/average and Meal UI accepted by Owner. Border/shadow frozen.
- Final Materials filter exposure and week separator corrections locally validated;
  these two small changes have no separate new device-run claim. Other release gates remain.

## Local automated validation

Canonical ./tool/flutterw: Flutter3.47.5 stable / Dart3.13.4. B2 candidate:
**788 Flutter PASS /1 existing skip; analyze PASS; iOS simulator / Android debug
builds PASS.** Resolver-focused23 tests include8 responsive loading/error/retry
cases at360×640/428×926,1×/2×. Prior B2 Deno48PASS (resolver23), ingestion170PASS,
Python parity/quota static contracts2PASS. SQL9 statements + PLpgSQL1 function
parse PASS. Local quota concurrency tests were not run; Owner runtime acceptance is below.
Activation-preparation Deno52PASS (resolver27); entrypoint/config/security checks
PASS with no network permission. Flutter unchanged/not rerun in this wiring task.
Credential-pattern/explicit-scope audit, diff and Wiki routing PASS. These are
local automated results, not Production source/PDF or physical-device acceptance.

## Production DB/Storage applied

Owner reports study_sessions.include_in_study_total migration
20260923000100 applied; total/excluded/invalid-non-mock counts all0 at verification.
Owner reports20260923000200 profile-avatars private bucket applied, PNG1MiB,
exact auth.uid()/avatar.png, SELECT/INSERT/UPDATE/DELETE owner-only SQL PASS.
[Database](database.md) owns schema evidence and prior deployment inventory;
[Study storage](day-8-study-storage-proposal.md), [school storage](day-7-school-storage-proposal.md),
[scoring storage](day-8-scoring-storage-proposal.md) retain original acceptance.
Feedback/admin/email-worker prior Production acceptance: [operations](day-11-account-personal-feedback.md).
Owner reports resolver quota migration20260925000100 applied/runtime PASS:
RLS/grants/definer/search_path, calls1–12/13 limit, resource isolation, minute reset.
[Exact evidence and scope](day-9-c-resource-detail.md#production-activation-preparation--2026-09-25).
No agent DB/Storage mutation, migration application or function deployment.

## Daily Sync status

Owner Production aggregate verification2026-09-24: **PHASE_0 PASS /
PILOT_C PUBLISHED_COMPLETE**. source_posts23; active content_items23; exams23;
active exam_subjects363; active resources739; reported integrity checks all0.
Quarantine23 = EXPECTED advisory evidence; automatic deletion prohibited.
This is Owner-reported evidence, not a DB query performed by Codex.

**PHASE_1: COMPLETE — DISCOVERY / DELTA FOUNDATION.** B1/B2 offline validation
passed, followed by one bounded read-only source observation: sitemap 1,676
posts; recent IDs `1712, 1711, 1710, ...`; five landing pages fetched; 7/24
request attempts; retries 0; attachment fetch 0; Production mutation 0. Feed
remains `UNAVAILABLE` because no verified endpoint exists. **PHASE1_SOURCE_VALIDATION:
PASS. BOUNDED_SOURCE_DRY_RUN: PASS. PHASE2: NOT STARTED / OWNER GATED.**
The empty local accepted state selected IDs `2, 4, 6, 7, 8` as `NEW`; this is a
**COLD_START_BASELINE_GAP**, not evidence that Production has five new posts.
Before Phase 2, bootstrap/reconcile the Production canonical baseline into the
accepted local/durable state without turning the 1,676-post inventory into
publication candidates.
[Canonical package](daily-sync-phase-1-deterministic-delta-package.md) and
[research synthesis](research-2026-09-24-product-operations-synthesis.md) are imported
verbatim with verified hashes. That import checkpoint changed Wiki only; implementation does
not start from instructions embedded in the package. **PHASE_2 NOT STARTED /
OWNER GATED**. No scheduler, publication, DB/Storage/schema change or Production
mutation. [Ingestion routing](ingestion.md#daily-sync-current-handoff--2026-09-24)
and [source reconciliation](research-registry.md#owner-provided-manus-exports--source-acquired).

## Open release gates

- Account deletion deployed/configured/E2E + avatar cleanup/retention review;
  Apple authorization revoke remains OPEN. Policy URLs/content/Store acceptance OPEN.
- Apple secret renewal and Google credential rotation OPEN.
- App recovery mailbox expired/reused/cold/warm acceptance and Kakao shared identity
  must not be inferred from login PASS; see [Auth acceptance](auth-native-owner-acceptance.md).
- Native focus/DND physical acceptance and notification operations: [Study](study-v1.md).
- Community block/report/moderation/support/terms are coupled release prerequisites;
  backend absent. [Platform boundaries](product-platform-boundaries.md).
- Achievement catalogue and authoritative award persistence absent. Owner promotes
  MY achievement access direction only; foundation scope in [roadmap §9](roadmap-academic-analytics.md#9-achievement--badge-engine).

## Longitudinal data strategy

[Canonical strategy](longitudinal-learning-admissions-data-strategy.md): HIGH /
CANONICAL PRODUCT STRATEGY; PLANNED ARCHITECTURE. APPLICATION_OUTCOME_DATA: PLANNED.
COHORT_ANALYTICS: FUTURE — DATA/PRIVACY/STATISTICAL GATED.
PREDICTIVE_ADMISSIONS: FUTURE — MODEL/EVIDENCE GATED. Strategy/handoff documentation
complete; no new code, data collection, schema or engine. Latest automated App
validation above is from the subsequent global surface UI task; the strategy itself adds no implementation.

## Current work and next actions

End-of-day2026-09-24: UI_V2 OWNER DEVICE PASS; final small filter/separator
corrections locally validated. No further surface styling work authorized.
Materials: search → grade/year/month/subject → 전체/수능/모의고사/논술/학습자료/입시정보;
initial5 + explicit more, education columns remain discoverable. Study final copy:
이번 주   총 N분 · 일 최대 N분; approved average placement retained.

Mock is FOUNDATION, not complete: supported-key official exam/subject/variant
selection + safe verified scoring; separate local free title/time/manual score.
[Phase2 gaps](day-8-d2-answer-scoring.md#end-of-day-foundation-and-phase2-gaps--2026-09-24):
full official/year-grade-month/key catalogue, official selection completion,
free custom-time polish/subject-score structure and cross-device result history.
Existing safe scoring is not a claim of full catalogue coverage.

Current release priority:
1. Materials direct PDF remains **RELEASE-CRITICAL GAP**: Phase A automatedPASS /
   Owner deviceFAIL. B2 backend+Flutter candidate now implemented after Owner
   Resume decisions: canonical source/no redirects, ephemeral Guest PDF delivery.
   Claude B2 code review PASS and quota runtime Owner PASS (reported). Entry/config
   wired: **READY TO DEPLOY / NOT DEPLOYED**, verify_jwt=false. Shared600/min global,
   12/min resource quota mandatory; Guest invocation/DB-cost DoS remains
   **ACCEPTED MVP OPERATIONAL RISK**, not a protection claim. Owner PDF NOT VERIFIED.
   [Activation handoff](day-9-c-resource-detail.md#production-activation-preparation--2026-09-25).

2. Multi D-Day and Home customization are **PLANNED / FOUNDATION DESIGN ONLY**;
   canonical architecture and current-code audit are recorded in
   [Home personalization and event collection](home-personalization-and-events.md).
   No Flutter implementation or migration exists.
3. Mock Phase2 only when Owner resumes it; gaps above remain OPEN.
4. Longitudinal architecture review when Score/Application/Outcome design starts;
   first read the canonical strategy, preserve history/context/provenance/privacy.

MY Snapshot / Mobile LAB actionable analysis / Web LAB deep analysis allocation
stays canonical; advanced engines PLANNED. Community FUTURE/release-gated;
Achievement FOUNDATION/FUTURE without catalogue/persistence; Notification Center
PLANNED without backend or fake alerts. Existing release gates remain OPEN.
Research synthesis and Phase1 package are SOURCE ACQUIRED in this repository;
individual A–D full reports have not been separately inspected here.
Future Wiki maintenance: separate historical design evidence from current design
policy, preserving links; no such refactor today. B2 local commit and branch push authorized after checks;
Owner iOS/untracked files retained. No automatic roadmap/Phase2 expansion.

## Handoff

Start with [Task Routing Map](index.md#task-routing-map), decisions and product scope.
[Policy audit](mobile-policy-audit.md) owns code/test evidence and remaining gaps.
[Log](log.md) is chronology; [deduplicated historical status evidence](history/status-checkpoints.md)
preserves former checkpoints without burdening the current restore path. Historical
PASS and staged migration statements are date-specific, not current HEAD/status.
