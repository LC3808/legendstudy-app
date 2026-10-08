# Current Status

## Shared MY foundation — 2026-10-08

[Shared MY/Application/Study/Student360](my-shared-foundation.md): LAB school flow 3c432cd Production deployed + Owner verified. Signup predecessor +3 closed separately. New Target/Application/Study/Admin candidates are LOCAL_VERIFIED, NOT_PRODUCTION_APPLIED. Target unique replacement is held by Owner §74; APP Flutter regression is pending SDK access. Payment/IAP/deletion runtime/Manus visuals unchanged.

## APP Store RC — 2026-10-07

[Final Store RC closeout](final-store-rc-1.md): current APP authority includes completed
personalization, native LAB entry, notifications and account deletion. Owner full tests
+967 ~2 PASS; Flutter3.47.6 fresh analyze, unsigned Android AAB and iOS release PASS.
Owner has confirmed all three release flags true; tool/store-release preserves other
production defines for both platforms. Android local upload-key binding prepared.
Store submission remains blocked by signing, device smoke
and Console inputs. SDK wrapper aligned with verified3.47.6; no feature/Production change.
Oct06 Unified Daily supersedes older APP deletion/release pending statements below.

## Product state

[Payment](payment-app-foundation.md): code PASS; LIVE OFF.

[MATH-2E](math-essay-learning-runtime.md): isolated; NOT_APPLIED.

[HQP](human-quality-persistence-implementation.md): gateway PASS; write NOT_ASSESSABLE.
[ADR-2D](account-deletion-ownership-compatibility.md): LOCAL_VERIFIED; NOT_APPLIED.

Native: Home/Materials/Learning/LAB/MY; guest materials, owner saved/recent; Timer/Mock, MY profile/avatar, school-grade/D-Day and trends. [APP closeout](app-release-closeout.md): baseline5 fixed; tests/build compile PASS; Store BLOCKED (deletion/revoke/policy/signing/device gates).
Internal-grade backend, advanced analysis/admissions, Community, Level and full
Achievement Engine are NOT implemented. No WebView/shared session.

Existing presentation/runtime notes are preserved in [shared foundation history](my-shared-foundation.md#preserved-prior-presentation-status); Manus visual authority remains unchanged.

## Owner verified

- App and LAB Email/Google/Apple/Kakao Production login PASS (Owner report).
- App Profile-build session restore PASS; school/grade values device PASS.
- App/LAB identity PASS: Kakao same UUID Owner-verified; Apple/Google historical PASS.
- Meal Owner E2E PASS: Home excludes breakfast,14/19KST progression, next eligible
  date within7 candidates D..D+6, expanded full-date meals. Keep implementation.
- Storage SQL acceptance is not App photo E2E. Owner reports first-photo false
  success on baseline; corrected photo/new UI device acceptance remains pending.
- Materials initial5/load-more, vertical study bars, MY→LAB→Back PASS (Owner follow-up2).
- UI_V2: OWNER DEVICE PASS. Home/Materials/global/Learning/LAB/MY/Settings surfaces,
  Study chart/average and Meal UI accepted by Owner. Border/shadow frozen.
- Materials filter/week separators locally validated; separate device acceptance pending.

## Local automated validation

Flutter3.47.5 / Dart3.13.4 via ./tool/flutterw. Essay L1 analyze/focused/client JWT PASS;
full925 PASS/2 skips/5 known baseline failures (no new Essay regression).
[UI validation and screenshots](essay-lab-ui-ux-v1.md). Earlier regression evidence in
[history](history/status-checkpoints.md#pre-recent-ordering-validation--2026-09-26).
Device review pending.

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
Schema/Storage entries above are Owner-applied; Materials publication is below.

## Daily Sync status

Phase1 discovery/delta foundation is complete. Existing A1 bootstrap, recent-delta
and A3 general controlled apply/activation code are present. Local ignored accepted
state has26 entries (inspected2026-09-26); no blanket re-observation or state rewrite
in this task. Historical23-row baseline and earlier pending checkpoints are
preserved in [history](history/status-checkpoints.md#pre-recent-ordering-status--2026-09-26).
Scheduler/broad automation is not authorized by controlled per-post publication.

Pre-pilot public baseline27 includes1710 (Owner apply/device PASS); it must not
be republished. Foreign-language/Hanmun raw NULL taxonomy gaps remain advisory.
Accepted state26 still excludes1710; A1 reconciliation is a separate pending task.

[Materials FINAL CLOSEOUT](materials-final-closeout-2026-09-27.md),2026-09-27:
full category discovery915 (exam354/essay561). Existing writer added243 exams +127
essays in37 bounded batches; exact inserts14833. Active441 content /296 exams
(G1:79/G2:81/G3:136) /135 essays. Public441 search/detail/resources/grade PASS;
canonical duplicates/collisions0, unrelated mutations0, recent timestamps preserved.
Partial1474/1447 inactive after1431/1404 activation;2 test recent_views removed,
original sources/content retained.1432 nominal month corrected5→4. Source343 is
one real historical identity exception. No schema/migration or new architecture.
Busan1593 generic PDF resolver deployed; actual HTTP206/PDF signature PASS, latest
CTA/PDF native device QA PENDING. Owner iOS/onboarding files preserved.
Owner source rule supersedes registry-as-publication-gate;18 full-set counterparts
released from52 identity holds,34 partial holds remain. Accepted26/1710 A1 unchanged.
Essay2020–2025 admission years evidenced independently of source publication years.
Latest analyze/focused38/Python389/resolver38 PASS; full Flutter855 PASS/1 skip/
3 baseline failures (badge and load-more expectations); native PostgreSQL25 NOT_RUN.
Materials is NOT CLOSED until Owner device PASS. Next **Essay LAB P0**, canonical
model first after separate instruction; then internal-grade, mock-score, admissions.
[Canonical handoff](materials-closeout-essay-lab-handoff.md). No further audit/backfill.


## Open release gates

- Account deletion NOT_APPLIED; ADR-2D retry review/activation gates OPEN.
  Apple revoke, privacy/Store acceptance OPEN.
- Apple secret renewal and Google credential rotation OPEN.
- App recovery mailbox expired/reused/cold/warm acceptance remains open;
  see [Auth acceptance](auth-native-owner-acceptance.md).
- Native focus/DND physical acceptance and notification operations: [Study](study-v1.md).
- Community block/report/moderation/support/terms are coupled release prerequisites;
  backend absent. [Platform boundaries](product-platform-boundaries.md).
- Achievement catalogue and authoritative award persistence absent. Owner promotes
  MY achievement access direction only; foundation scope in [roadmap §9](roadmap-academic-analytics.md#9-achievement--badge-engine).

## Longitudinal data strategy

[Canonical strategy](longitudinal-learning-admissions-data-strategy.md): Learning/Decision/Outcome
history adopted; architecture PLANNED, evidence/privacy gates remain.

## Current work and next actions

[Owner delivery targets](roadmap-monetization-and-in-app-learning.md#delivery-calendar):
mid-Oct Store launch → end-Oct Essay stabilization → Nov Mock/CSAT BETA.
Next: worker/Scaffolding → loop E2E → IAP/Store; ads/Growth must not delay launch.
[School History & Coupon/Voucher](school-history-and-coupon-design-v1.md): design adopted,
NOT implemented — Coupon/Voucher is **Launch P0** (ships with IAP/Paywall, reuses G1 ledger);
School History + 2-correction/14-day-cooldown is **P0_NON_BLOCKING** (staged migration). No
code/DB change.

[Final Owner device QA](materials-final-closeout-2026-09-27.md#owner-device-gate):
run latest profile build; check full exam sequences/known missing cases, Essay
2020+ year/university searches and all CTA forms, especially Busan1593 real PDF.
Onboarding Phase1.1 and school-search hotfix are Owner-reported PASS and preserved.
On device PASS: Materials CLOSED. [Scaffolding/timing](essay-lab-scaffolding-production-apply.md)
DEPLOYED/KEEP19. Identity PASS. [Pilot1.3](essay-lab-scaffolding-ai-pilot-1-3-run-a.md):
2 frozen, quality PARTIAL; Owner review pending. Production AI/student/worker OFF.
[G1 Credit](essay-lab-product-v1.md#credits--g1-commercial-policy-2026-09-29): v2/+3/manual grant
DEPLOYED. [Owner status RPC](essay-lab-server-transactions.md#owner-status-projection) PASS;
Ledger21; L1 PASS. [L2-C3](essay-lab-model-bakeoff-l2-b.md): S/H + Gate D Owner PASS, CORE0/Positive Learning PASS. GPT candidate;AI OFF.
Multi D-Day: applied/Owner PASS; ACL correction Owner-applied/verified.
Home customization and Analytics/Achievement/Notification backends remain planned.


## Handoff

Start with [Task Routing Map](index.md#task-routing-map), decisions and product scope.
[Policy audit](mobile-policy-audit.md) owns code/test evidence and remaining gaps.
[Log](log.md) is chronology; [deduplicated historical status evidence](history/status-checkpoints.md)
preserves former checkpoints without burdening the current restore path. Historical PASS statements are dated evidence.


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

The [final closeout](materials-final-closeout-2026-09-27.md) supersedes the older
wave rollout gate. Owner device QA then Essay LAB; maintenance only for real defects.

Post-Wave1 [Personalization planning](home-personalization-and-events.md#personalization-package-after-wave1--owner-direction-2026-09-27) is preserved, not implemented.
