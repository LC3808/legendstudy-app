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
10 items with explicit load-more; Settings logout follows service/policy groups.
[Canonical design](design-system.md) maps the approved proposal to implementation.

## Owner verified

- App and LAB Email/Google/Apple/Kakao Production login PASS (Owner report).
- App Profile-build session restore PASS; school/grade values device PASS.
- Apple and Google LAB/App shared identity PASS; Kakao equality NOT VERIFIED.
- Meal Owner E2E PASS: Home excludes breakfast,14/19KST progression, next eligible
  date within7 candidates D..D+6, expanded full-date meals. Keep implementation.
- Storage SQL acceptance is not App photo E2E. Owner reports first-photo false
  success on baseline; corrected photo/new UI device acceptance remains pending.
- New MOBILE_UI_OWNER_E2E: NOT VERIFIED. Build/test PASS is not Production E2E.

## Local automated validation

Canonical ./tool/flutterw: Flutter3.47.5 stable / Dart3.13.4. Latest validation:
685 Flutter PASS /1 existing skip; analyze PASS; Android debug/iOS simulator
builds PASS;67 render cases (360×640/428×926,1×/2×), selected Home/Materials/
Learning/LAB/MY/Settings/Guest PNGs inspected. Deno deletion tests last passed11
in the prior task; no Deno changes in v2. Secret signatures, source/ignore readiness,
diff and Wiki link/routing checks PASS. No physical-device claim.

## Production DB/Storage applied

Owner reports study_sessions.include_in_study_total migration
20260923000100 applied; total/excluded/invalid-non-mock counts all0 at verification.
Owner reports20260923000200 profile-avatars private bucket applied, PNG1MiB,
exact auth.uid()/avatar.png, SELECT/INSERT/UPDATE/DELETE owner-only SQL PASS.
[Database](database.md) owns schema evidence and prior deployment inventory;
[Study storage](day-8-study-storage-proposal.md), [school storage](day-7-school-storage-proposal.md),
[scoring storage](day-8-scoring-storage-proposal.md) retain original acceptance.
Feedback/admin/email-worker prior Production acceptance: [operations](day-11-account-personal-feedback.md).
No current task DB/Storage mutation, migration application or function deployment.

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

## Current work and next actions

Design System v2 approved scope implemented and locally verified. Original proposal
is retained with implementation/deferred mapping; historical peach-strip styling is
superseded. No Auth, Meal, photo Storage, Timer/Mock/Trend data-contract changes.
Owner reviews Home → Materials/search/load-more → Learning → LAB → authenticated
MY → Guest MY Login → Settings/policy/logout. Check both normal and larger text.
Device visual acceptance remains NOT VERIFIED. Existing Achievement scope unchanged.
Local commit only, PUSH NO; preserve Owner iOS and existing untracked files.
Next implementation follows Owner review and release gates, not automatic roadmap
expansion. No Production secrets or UUIDs in docs.

## Handoff

Start with [Task Routing Map](index.md#task-routing-map), decisions and product scope.
[Policy audit](mobile-policy-audit.md) owns code/test evidence and remaining gaps.
[Log](log.md) is chronology; [deduplicated historical status evidence](history/status-checkpoints.md)
preserves former checkpoints without burdening the current restore path. Historical
PASS and staged migration statements are date-specific, not current HEAD/status.
