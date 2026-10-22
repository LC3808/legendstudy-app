# Current Status

## PHASE 3 — 건국대 2문항 공개 연결 / 전체 PARTIAL

최신 Owner P0 승인으로 기존 운영 E2E 통과 건국 인문2/자연1의 일반 로그인 실행 범위를 연결했다. WEB 운영 화면·iOS Simulator 대학→Math 진입 PASS. 기존 실제 평가·무료재첨삭·History·Credit1/0·WEB/APP 교차조회 결과 재사용. 신규 Provider/Credit 거래0. 다른10대학은 공식 운영패키지 및 실제 E2E 미완료로 HOLD.

기존71701 적용·71702 미적용, 157시험512문항 자료보존. 전체DB237시험700문항 및133RLS·기존ID/답안/Ledger 불변. 신규테이블/결제/IAP/스토어 변경없음. Math 기존 함수2개/실행flag의 정확한1leaf 범위 변경과 롤백은 [PHASE3 상세](phase3-service-20261022.md). 신규앱 물리기기/Android의 이번변경은 미검증.

다음: 기존 숙명 accepted package를 운영문항에 연결 검증하고 대학별 실제 E2E·비용·실패명세를 확장. 경희·동국 추가자료보강 HOLD. 과거완료기능/건국성공평가는 반복하지 않는다. 이전단계는 [로그](log.md)에 보존.

## Product state

[Payment](payment-app-foundation.md): code PASS; LIVE OFF.

[MATH-2E](math-essay-learning-runtime.md): C/D/E installed per Oct08 Owner inventory; live Web activation unverified.

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

Latest integration checks are above; [integration evidence](production-integration-2026-10-09.md#local-app-branch-integration--2026-10-10)
distinguishes compile/widget acceptance from actual backend/device OAuth and Store QA.
Earlier regression evidence: [history](history/status-checkpoints.md#pre-recent-ordering-validation--2026-09-26).

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

Existing ingestion/publication evidence is preserved in
[Daily Sync checkpoint](history/status-checkpoints.md#daily-sync-checkpoint-preserved-during-oct14-native-ux-handoff).
[Materials final closeout](materials-final-closeout-2026-09-27.md) remains the
canonical acceptance source; Owner device QA pending. No reingestion in this task.

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


## Materials rollout priority

The [final closeout](materials-final-closeout-2026-09-27.md) supersedes the older
wave rollout gate. Owner device QA then Essay LAB; maintenance only for real defects.

Post-Wave1 [Personalization planning](home-personalization-and-events.md#personalization-package-after-wave1--owner-direction-2026-09-27) is preserved, not implemented.

- Oct14: HOLD-only private connection probe added to existing Cloudflare entry: fixed Registry/Package/policy reads and nonce-only Queue ACK; no runtime/Provider/Ledger path. Two queue boundary checks PASS; operating verification pending.

- Oct14 operating postflight: LAB/Worker Registry234 + service/user Auth PASS; Queue no-op ACK. Package rights and exam policy block evaluation; reviewer/provider bindings missing. Runs0/checkpoints0, Provider/Credit NOT_RUN, HOLD. See tool/cloudflare_essay/README.md.

## Historical: 2026-10-21 — Backend recovery gate follow-up

Private logical DB/Storage backup and isolated service-data restore verified. Full recovery remains PARTIAL pending Vault/cron restoration; exact two Production migrations not applied. Existing contract tests reused, no app/code/Provider/Credit changes. See supabase/verification/essay_service_contracts/production-plan.md.

## 2026-10-22 — Student material browsing

71701 is already applied; no DB work this task. Shared metadata selection remains HOLD-only. Canonical official page links now override stale registry PDF links for the 11 colleges; unverified Sogang/SWU links withheld. Source catalog tests 13 PASS, analyze PASS, Android debug19 and iOS Simulator debug19 builds PASS. Native/device and logged-in student E2E NOT_ASSESSABLE; no store upload. Production WEB still shows old Registry subsets. See Unified Wiki 2026-10-22-material-service-connection review.

## 2026-10-23 — 실제 인문 운영 E2E

건국 인문2번 APP 최초→WEB 무료 재첨삭→APP 교차 History PASS(실제 Provider). Credit1/0·실패 순차감0. 운영10호출/보수비용USD0.972644. iOS Simulator 범위이며 Android/iPhone·Math·나머지 문항 미검증. 일반 공개HOLD. Math 전역OFF, 정확한 계정/leaf의 한시적 DB 예외와4행 ACTIVE 준비, Worker 인증 갱신 여부 확인 필요. [상세·복구·증거](phase3-service-20261022.md). 결제/IAP 변경 없음.

Math 인증 조사: 기존7일 전용역할 JWT 발급·갱신 경로와 Oct09 실제 성공 기록 발견. 두 운영Secret 존재; 현재 유효성은 미확인, 만료 장애로 단정 금지. 인증키/Secret/운영설정 변경 없이 상세 phase3 기록 정정.

## 2026-10-23 Math 인증 복구·실제 평가
두 전용 JWT의 실제 만료를 확인하고 기존 키로7일 갱신, 설치 후 역할 인증PASS. WEB 건국 자연1번 이미지판독·확정·실제평가·저장PASS, 최초1Credit/예약0, APP Simulator 같은결과조회PASS. Native History→Math 화면이 뒤에 열리는 문제 최소수정·회귀테스트PASS. APP 합성답안 입력 대기, 무료재첨삭/APP→WEB는 미완료이므로 전체PARTIAL. 대기 중 Math실행flagsOFF·한시DBgate/status예외원복, JWT/답안/결과보존. 기존 인문성공반복없음. [상세](phase3-service-20261022.md).

## 2026-10-23 수리 재첨삭 완료
Device Hub Send Clipboard로입력해결. 건국자연1번 APP무료재첨삭→실제Provider→결과/History→WEB교차조회PASS(iOS Simulator). 최초1/재첨삭0Credit·예약0보존. Math누적3호출/보수USD0.181868. 검증종료후Math flagsOFF·DB한시예외원복,일반공개HOLD. 실기기/다른대학전체PASS아님. 상세 phase3-service-20261022 기록참조.

## 2026-10-23 공개 연결 진행
Owner가 E2E 통과 문항 공개 승인. 건국 인문만 명시적 서버 시험 범위로 연결 중. 기존 건국 인문/수리 성공 반복 없음. 로컬 Worker11/WEB45 PASS, 운영 적용·11대학 전체는 미완료. [상세](phase3-service-20261022.md).
