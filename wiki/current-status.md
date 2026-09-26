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

Flutter3.47.5 / Dart3.13.4 via ./tool/flutterw. Current Recent ordering task:
analyze PASS;51 focused Flutter +181 ingestion +38 focused Python tests PASS.
Full Flutter/builds not rerun. Prior UI/PDF validation is preserved in
[history](history/status-checkpoints.md#pre-recent-ordering-validation--2026-09-26)
and [EOD](eod-2026-09-25.md). Owner device PASS is separately reported below.

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

Phase1 discovery/delta foundation is complete. Existing A1 bootstrap, recent-delta
and A3 general controlled apply/activation code are present. Local ignored accepted
state has26 entries (inspected2026-09-26); no blanket re-observation or state rewrite
in this task. Historical23-row baseline and earlier pending checkpoints are
preserved in [history](history/status-checkpoints.md#pre-recent-ordering-status--2026-09-26).
Scheduler/broad automation is not authorized by controlled per-post publication.

Current1710 result: raw subject recognition fixed (unknown18→0), but9 canonical
subjects are absent. Owner confirmed **taxonomy approval first; HOLD**.
Medium / publishable=false; plan1 source +1 content +1 exam +33 occurrences +67
resources, **not applied**. Current handoff and safe dry-run:
[Materials rollout](materials-data-rollout.md#recent-publication-ordering-and-1710-hold--2026-09-26).
No Production mutation, migration, attachment fetch or1618 change.


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

Materials Recent Updates now queries all active content by original
`published_at DESC`, then stable `id DESC`; full timestamp retained. Search,
filters, saved/recent semantics remain unchanged. Flutter analyze and51 focused
Flutter tests PASS; ingestion181 + focused38 tests PASS. Actual device order is
not reverified here.1710 publication remains Owner-approved HOLD pending canonical
taxonomy support, not ready for controlled apply.

Materials PDF retains Owner device PASS. UI badge/MY density micro-polish remains
deferred per [EOD closeout](eod-2026-09-25.md). Next data priority stays latest-post
readiness → Wave1(2020→current) → release, then older waves; see
[rollout](materials-data-rollout.md). No automatic backfill/publication authority.
Mock full catalogue/history/advanced analysis remain gaps; Multi D-Day, Home
customization, analytics platform, Achievement and Notification backend remain
planned/foundation. Prior detailed checkpoints are preserved in
[history](history/status-checkpoints.md#pre-recent-ordering-status--2026-09-26).


## Handoff

Start with [Task Routing Map](index.md#task-routing-map), decisions and product scope.
[Policy audit](mobile-policy-audit.md) owns code/test evidence and remaining gaps.
[Log](log.md) is chronology; [deduplicated historical status evidence](history/status-checkpoints.md)
preserves former checkpoints without burdening the current restore path. Historical
PASS and staged migration statements are date-specific, not current HEAD/status.


## 2026-09-25 EOD override

[Canonical same-day closeout](eod-2026-09-25.md) supersedes earlier 2026-09-25
pending-device/EOD statements where they conflict.

- **MATERIALS_DIRECT_PDF: OWNER DEVICE PASS** — Production resolved/pdf plus actual
  iPhone problem and answer PDF in-app open.
- Materials title/source/grouping and 학력평가/모의평가/수능 classification are
  Owner-reviewed. Badge centering and MY vertical-density code are automated PASS
  but **Owner visual satisfaction is not sufficient to freeze them**; defer
  micro-polish to a later dedicated UI session.
- OAuth local runtime configuration was restored; canonical profile-device command
  and required public config boundary are recorded in the EOD closeout.
- **Daily Sync Phase1 COMPLETE; Phase2 NOT STARTED / OWNER GATED.**
- Multi D-Day, Home customization and `analytics.legendstudy.com` remain
  **PLANNED / FOUNDATION**, not implementation.
- Top-level engineering rule: **minimum cost; easiest viable solution; lightweight
  structure; concise implementation; reuse first; expand only on demonstrated
  need/failure evidence.** Read Wiki first and avoid repeating solved research or
  scale-premature/speculative engineering.


## 2026-09-26 Materials rollout priority override

Owner sets the immediate product sequence to finish the Materials foundation
quickly and accurately before expanding major feature work. Canonical plan:
[Materials rollout and historical backfill](materials-data-rollout.md).

1. Bootstrap/reconcile the already-published Production baseline into Daily Sync
   accepted state; then re-run recent delta and controlled latest-post publication.
2. Historical Wave1 **2020→current**, including safely supported essay-source
   Materials, is the initial App-release data gate.
3. Begin initial App deployment/release work after Wave1 validation rather than
   waiting for the whole archive.
4. Later backfill **2015–2019**, then **2010–2014**.
5. Next major product tracks: Essay DB/LAB using existing Manus research/assets;
   Mock score/grade history; Admissions evidence/rules and later model-gated
   acceptance estimation; internal-grade input and university/department analysis.
6. Multi D-Day/Home customization/analytics.legendstudy.com remain planned and
   are scheduled around the higher-priority data/product tracks.

Do not commission duplicate research. Check Wiki/Research Registry/imported Manus
sources first and retrieve original Manus reports when synthesis detail is
insufficient. Current implementation handoff is the Recent ordering /1710 HOLD section above.
No scheduler, broad automation, backfill mutation or Essay schema is bundled.
