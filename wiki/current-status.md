# Current Status

### 2026-10-14 — Owner iPhone 실기기 검증 및 UX 후속 과제

Owner가 iPhone 실기기에서 직접 확인한 결과: review 계정 로그인, Supabase 연결,
Credit 잔액 10, 논술 LAB 진입, 한양대 2024 수시 인문계열 시험 조회,
나의 첨삭 기록 조회, WEB에서 생성된 기존 실제 AI 첨삭 결과 표시 모두 PASS.
검증 출처는 Owner 실기기 보고이며 자동화 테스트 결과로 대체 표기하지 않는다.

UX 개선 과제 (기록만, 이번 작업에서는 구현하지 않음):
- 시계 아이콘만으로 접근하기 어려운 History에 '나의 첨삭 기록' 메뉴 명시.
- 결과 화면에 대학·학년도·시험 정보 표시.
- 평가 결과의 긴 텍스트와 과도한 자간 개선.
- History 목록의 대학·시험별 구분 개선.

무료 재첨삭은 기존 승인 범위에서 이미 완료: run
`414a207b-2c51-48e6-97ea-2ddf49b77c9e`, 추가 Credit 0, 잔액 10,
최초·재첨삭 History 보존, 중복 사용 차단, WEB 비교 표시 확인.
이번 실기기 보고는 기존 결과 조회 PASS이며 재첨삭 결과·3→4 비교 화면까지
명시적으로 확인한 보고는 아니므로 그 항목은 확인 대기로 구분한다.
다음 단계는 기존 저장된 재첨삭 결과의 APP 표시·비교 확인 및 Owner 품질 검토.
완료된 재첨삭을 재실행하거나 추가 Provider 호출·Credit 거래를 하지 않는다.
실행 OFF 및 일반 사용자 공개 HOLD 유지. 코드·UI·DB·배포 변경 없음.

### Oct14 20:28 KST — approved free rewrite completed; native rewrite confirmation pending

Owner confirmed the initial result in Native APP and approved one free rewrite
(maximum 2 Provider calls, $2, 0 Credit, same-run recovery).
Run `414a207b-2c51-48e6-97ea-2ddf49b77c9e` completed and settled as
`included_revision`, parent `5b636cda-9915-42e1-b209-9934c7c0fcb1`.
Same Hanyang 2024 admission humanities afternoon2, question1, Package17.
The 1174-character revised test answer was submitted; evaluator and independent
review each ran once. Stored receipts: input26409/output6040 tokens total;
token-rate estimate $0.226436 (not a billing invoice), within approved $2.
No further Provider retry or evaluation was executed.

Operating DB: required credits0, rewrite Ledger rows0, balance10/reserved0/available10.
Original snapshot/result hashes unchanged. Actual reserve duplicate guard rejects
REEVALUATION_ALREADY_USED; one child remains, with no extra Provider call or debit.
WEB authenticated History shows both records; existing result and comparison UX
shows utilitarianism3→4, other four criteria unchanged4, one improvement/four same.
Prior improvement is recorded resolved. This is a QA answer, not proof of student outcomes.
Owner confirmed initial WEB/APP equality; rewrite Native display confirmation remains
pending the existing Owner question. Shared backend does not substitute for native UI QA.

Pages canonical deployment45c3935b-c8c8-4fd4-94fc-5c1e31bb51a8 and Worker
version6ff0ea08-ad10-4cb0-bffd-56313d470126 restored execution OFF.
Cloudflare API independently confirmed both live flags false. Public HOLD maintained.
No schema/Prompt/resultSchema/resultUX/Math/Payment/IAP changes.
Private comparison artifact: /private/tmp/essay-cycle-comparison.html (answers/results,
not committed). WEB screenshot: /private/tmp/essay-rewrite-result.png.
Next: Native rewrite display confirmation and Owner feedback-quality review.
Failure recovery was not invoked; no new failure-injection claim is made.



### Oct14 first paid E2E — operating WEB PASS; overall service PARTIAL

Owner approved one initial submission, at most2 Provider calls/$2, 1Credit and same-run
recovery. review@legendstudy.com submitted one 1152-character QA-generated text answer
for Hanyang2024 admission humanities afternoon2, Package17, question
4cbe8b69-2ccc-5c4e-9e77-0644f90e2cde. Package digest:
40ef4e7bbe5295facf146946b7f1924f086ff6e540108a3def8efb22e37ba4ae.
Run5b636cda-9915-42e1-b209-9934c7c0fcb1 completed at2026-10-14T08:30:54.827523Z
(17:30:54KST), submitted08:29:19Z. No schema/RLS/Registry change.

Actual OpenAI requests2: evaluator12934 input/2552 output tokens,31954ms;
independent review12546 input/3984 output tokens,52044ms. All8 independent checks
passed; signed review, reviewed output and final checkpoints persisted. No retry or
recovery transaction was required. Price-based estimate$0.23264 using input$4/output$20
per million (https://developers.openai.com/api/docs/models/gpt-5.6-sol); Provider
cost_amount is null, so this is NOT an invoiced cost or proven billing amount.
Ledger exactly reserve(0,+1), consume(-1,-1); available11→10, reserved0.
Existing History and result UI visibly show completed initial evaluation, summary,
strengths, five criteria/star ratings and improvement advice; screenshot local
/private/tmp/essay-first-e2e-result.png. Actual browser, not mock/build-only proof.

LAB093d417 adds server-only ESSAY_E2E_SCOPE pinning account/exam/request key and
rejecting parent runs;9 focused tests, typecheck, targeted lint and build PASS.
Request key b21dabf9-2d51-4446-9e0e-c2d6b4dc3796 retained to prevent another run.
Pages partial-variable PATCH initially blocked by automatic approval review; confirmed
official API null-only deletion and Wrangler single-key PATCH implementation, then
review permitted update. Before/after unrelated bindings identical; no secret values
printed, round-tripped or committed. Math/Payment/IAP/allowlists unchanged.

Both actual gates restored OFF: Pages deployment991b59fd-78a9-4a4f-a9f0-bd6b9d206993,
Worker version21c5dc83-ebcf-4962-b753-73d878a19c06. Metadata verified false on active
Pages deployment and Worker. Public HOLD remains. No extra Owner action for this run.

Remaining: separately approved free reevaluation E2E, native APP result consistency,
real failure recovery exercise and QA review. They are NOT claimed PASS by this run.
Observed UI follow-ups: repeated university in History title/raw admission label,
long criterion headings, formal rather than consistently teacher-style feedback,
and no linked evidence displayed in existing result UX. Do not confuse successful
runtime flow with full pedagogical/product acceptance. Preserve stored Package/output.

## Oct14 operating essay connection — HTTP VERIFIED / E2E PENDING

Cloudflare→Supabase essay_worker HTTP read returned **200 /234** using the existing
allowlisted Chrome account (11:35KST). The IAB administrator session was not that
account; no Math configuration/allowlist/Secret change was needed. Production WEB
da479da deployed as197c1ef5 with internal Worker binding; exam submit remains OFF.
Earlier observed balance11; no new Credit transaction.

Owner installed the disabled exam API through SQL Editor; DB postflight PASS:
[impact/test/rollback](../supabase/reviews/essay-exam-operating-api/README.md).
Actual non-superuser/BYPASSRLS PostgreSQL ownership and real lifecycle function
bodies now tested; private hash ACL incompatibility fixed without extending grants.
Local first1Credit/free rewrite/replay/history/erasure and formal SQL installation,
repeat refusal/empty rollback PASS; Provider transport remains fake.

Owner A: Cloudflare Python Worker + Supabase DB checkpoints; no Linux host.
Checkpoint migration20261014044957 applied/verified; Worker/Queues deployed OFF.
Owner Secret entry pending; no Provider/Credit. Async evaluator/local workerd PASS; reviewer/Provider rights,
operational old-version Package/rewrite selection, admin QA projection and real Provider/Credit E2E
remain incomplete. Approved exam API installed; zero runs/billing, Provider/model policies null.
WEB/Native result adapters preserve approved UX; public HOLD, Math/Toss/IAP unchanged.
See [runtime completion](essay-runtime-completion.md) for details.

## Shared MY foundation — 2026-10-08

[Shared MY/Application/Study/Student360](my-shared-foundation.md): LAB school flow 3c432cd Production deployed + Owner verified. Signup predecessor +3 closed separately. Application/Study/Admin006–008 are PRODUCTION_APPLIED; Owner postflight8 RPC hashes/ACLs and2 table RLS/direct-write denial match. LAB507ed7b deployed; authenticated runtime pending. Target unique replacement is held by Owner §74; APP Flutter regression is pending SDK access. Payment/IAP/deletion runtime/Manus visuals unchanged.

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


## Historical EOD

[September25 evidence](status-archive-2026-10-09.md) is archived; latest Daily takes precedence.

## Materials rollout priority

The [final closeout](materials-final-closeout-2026-09-27.md) supersedes the older
wave rollout gate. Owner device QA then Essay LAB; maintenance only for real defects.

Post-Wave1 [Personalization planning](home-personalization-and-events.md#personalization-package-after-wave1--owner-direction-2026-09-27) is preserved, not implemented.

- Oct14: HOLD-only private connection probe added to existing Cloudflare entry: fixed Registry/Package/policy reads and nonce-only Queue ACK; no runtime/Provider/Ledger path. Two queue boundary checks PASS; operating verification pending.

- Oct14 operating postflight: LAB/Worker Registry234 + service/user Auth PASS; Queue no-op ACK. Package rights and exam policy block evaluation; reviewer/provider bindings missing. Runs0/checkpoints0, Provider/Credit NOT_RUN, HOLD. See tool/cloudflare_essay/README.md.

### Oct14 Hanyang rights approval and independent review — PARTIAL

Owner confirmed OpenAI transmission permission for Hanyang2024 admission humanities
afternoon2 Packagev16's two PDFs, evaluation and independent review only. No operating
DB change or Provider/Credit call was performed. Prepared rights-only v17 candidate
with exact-exam/model policy, content/version guards and non-destructive rollback.
Local PostgreSQL17 non-superuser apply/content-preservation/repeat/rollback PASS.
Separate semantic review request reuses Responses and existing SignedReview; evidence,
usage and receipt use existing checkpoints. Five synthetic semantic/runtime checks
PASS, async parity and queue boundary checks PASS; local Cloudflare workerd startup
PASS after staging module fix. Not deployed; operating E2E NOT_RUN.
Next: Owner approval of candidate SQL, Owner Provider/review-signing Secrets, disabled
Worker deployment/configuration, then separately scoped actual Provider/Credit E2E.
No Math, Payment/IAP, Registry IDs, evaluation prompt/schema or approved UX changes.

### Oct14 Hanyang policy applied; Worker remains OFF

Owner approved rights/model-policy DB scope. Applied migration
`20261014064346_essay_hanyang_reviewed_execution_policy`. Package17 hash
`40ef4e7bbe5295facf146946b7f1924f086ff6e540108a3def8efb22e37ba4ae` verified;
v16 retained and all question/evaluation content unchanged. Existing Worker-role
Package RPC and exam preflight PASS, Registry234, private function ACLs unchanged,
runs0/checkpoints0. No Provider/Credit transaction.
Deployed existing independent-review connection to the same Worker, version
`f27efa26-42ef-4102-ad87-3d048d4363d6`; execution false, Pages unset/off, existing
Secrets preserved. Non-secret model/reviewer bindings now configured.
Owner action: Worker Secrets ESSAY_PROVIDER_KEY and ESSAY_REVIEW_VERIFY_KEYS only;
exact dashboard path and hidden clipboard generation instructions provided. No JWT
reset, no new infrastructure. After settings: safe admission validation, then separate
limited Provider/Credit E2E approval. Actual E2E NOT_RUN; overall PARTIAL/public HOLD.

### Oct14 Provider/review Secrets — operating preflight PASS

Owner entered ESSAY_PROVIDER_KEY and ESSAY_REVIEW_VERIFY_KEYS. Cloudflare metadata
confirms both secret_text; values were never read/output. Existing HOLD-only diagnostic
now reuses the actual exam-admission method (preflight RPC, exact Package converter,
ReviewedRuntimeWorker.authorize, reviewer signing/verification key identity). No
Provider evaluate, submission, reserve or finalize method runs in this check.
Operating browser result: HTTP200, no missing bindings, ready=true, Package17 digest
40ef4e7bbe5295facf146946b7f1924f086ff6e540108a3def8efb22e37ba4ae, question_count1,
model gpt-5.6-sol, review_key_binding PASS, provider_called=false. Credit visible11;
DB runs0/checkpoints0. Worker version c6e89ab9-7248-40c9-ac21-b5acd88158c4, execution
false. Local boundary3 + semantic5 PASS (synthetic only).
This validates key wiring and evaluation configuration, NOT OpenAI key validity,
model access, live model quality, signed live review or charged/free E2E. Actual
Provider/Credit remain NOT_RUN; public HOLD. Next is separately approved bounded
initial evaluation + free reevaluation on the existing allowlisted account. No more
Secret input is currently needed. Screenshot local /private/tmp/essay-runtime-admission-pass.png.
