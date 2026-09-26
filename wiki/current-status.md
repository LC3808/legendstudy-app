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

2026-09-27 read-only public Production query confirms27 active content items,
including1710, ordered1712→1711→1710 by original published_at then id descending.
Owner confirms1710 apply/activation and device PASS; the former HOLD is superseded.
The9 foreign-language/Hanmun taxonomy gaps are advisory, raw/unmapped with nullable
subject_id. Existing code already implements this policy. Local accepted state
still has26 entries:1710 reconciliation is pending, not a new publication.

Wave1 read-only inventory COMPLETE (2026-09-27): sitemap1676, candidates781
fully observed;296 actually published2020→current (27 public baseline +269 new),
485 candidate posts pre2020. Earlier-lastmod895 excluded with13 bounded sanity
checks and0 exceptions; not an exhaustive reread of those895.
Writer/parser extension IMPLEMENTED / TESTED. Saved296 posts reclassified,
no network re-observation. New269:217 writer-ready (10 no advisory +207 advisory),
52 identity-review posts remain frozen in23 groups, no other holds. Ready types:
exam63, essay135, study14, column5. Existing exam invariants and NULL raw taxonomy
preserved; new non-exam scope has no exam/occurrence children.229 focused/regression
tests PASS; deterministic rerun and planned-key checks PASS. Production publication
**NOT YET APPLIED / OWNER GATED**. Private DB access unavailable: exact live inserts/
no-ops/collisions UNKNOWN; read-only preflight SQL prepared.1710 acceptance gap
unchanged (no recrawl; full A1 observation evidence absent from redacted snapshot).
[Implementation and gate](materials-data-rollout.md#wave1-writerparser-extension--2026-09-27).


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

Materials Recent Updates queries all active content by original
`published_at DESC`, then stable `id DESC`; full timestamp retained. Owner device
order PASS and fresh public Production read agree.1710 is already published;
do not reapply it. Inventory and minimal writer/parser implementation are complete. Obtain private
read-only preflight results, then exact bounded Production review/Owner approval.
52 identity-review posts remain isolated; no publication has been executed.

Materials PDF retains Owner device PASS. UI badge/MY density micro-polish remains
deferred per [EOD closeout](eod-2026-09-25.md). Next data priority is Wave1 review/implementation → controlled publication →
release, then older waves; see
[rollout](materials-data-rollout.md). No automatic backfill/publication authority.
Mock full catalogue/history/advanced analysis remain gaps. Multi D-Day is
IMPLEMENTED (Production `day_targets` schema applied; OWNER DEVICE PASS); Home customization, analytics platform, Achievement and Notification
backend remain planned/foundation. Prior detailed checkpoints are preserved in
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
- **Multi D-Day: IMPLEMENTED / Production schema applied / OWNER DEVICE PASS.** Owner-scoped `day_targets` (RLS, single primary), 2 legacy single
  D-Days backfilled. Home customization and `analytics.legendstudy.com` remain
  **PLANNED / FOUNDATION**.
- Top-level engineering rule: **minimum cost; easiest viable solution; lightweight
  structure; concise implementation; reuse first; expand only on demonstrated
  need/failure evidence.** Read Wiki first and avoid repeating solved research or
  scale-premature/speculative engineering.


## Materials rollout priority

Wave1(2020→current) is the release data gate; older waves and product priorities
are preserved in [Materials rollout](materials-data-rollout.md).


D-Day: IMPLEMENTED / Production applied / OWNER DEVICE PASS; no code changes.
Post-Wave1 [Personalization planning](home-personalization-and-events.md#personalization-package-after-wave1--owner-direction-2026-09-27) is preserved, not implemented.
