# PAYMENT APP foundation

2026-10-03: implemented and isolated verified; **Production NOT_APPLIED**. Owner authorized APP scope after LAB PAYMENT-2 identified the missing shared financial boundary. [Owner package](../supabase/verification/payments/README.md) and [exact RPC/financial contract](../supabase/verification/payments/contract.md) own implementation details. No LAB code, migration deployment, provider call or LIVE activation.

Provider-neutral identity: TOSS/APPLE_IAP/GOOGLE_PLAY + mode + verified purchase ID. Only Toss runtime is enabled; IAP API/verification remains future work. Owner pre-apply amendment supersedes the prior hash without changing Ledger economics.

`payment_order(jsonb)` creates/reads own versioned order from server-authenticated identity and server SKU policy. `payment_process(jsonb)` is restricted to the existing trusted finance capability for durable confirm/cancel/reconciliation operations. TEST records never post spendable Credit. The future LIVE branch atomically binds one payment to one existing purchase grant; it creates no second wallet and does not change signup or Essay/Math economics. Price/quantity/validity/deduction snapshots are persisted rather than trusted from browser/callback.

General refund uses grant-attributed net consumption, not wallet balance;29,900−5×4,900=5,400. Account locks and a narrow grant fence protect provider/local cancellation gaps. UNKNOWN remains recoverable; provider failure leaves credits intact; exact retries and concurrent finish calls post once. Detached financial account cancellation remains possible without restoring personal linkage. Statutory exceptions are not forced through general-policy arithmetic.

Owner package contains migration hash, ownership allowlist, catalog/postflight, failure evidence and empty-install rollback. Existing helper bodies/ACL/ownership are preserved. New function bootstrap restores temporary SET/public CREATE; no new role or permanent runtime privilege expansion. Rollback refuses payment history or unexpected dependencies.

Validation: payment checks including real multi-session concurrency and transaction failure; G1 Credit84 + static7; Humanities/HQP102; Math131 + runtime37 (C01–C30) + learning63 (L01–L40). Exact current counts/hash in package. Auth claims are simulated locally; no real JWT gateway/Cloudflare/provider proof.

Independent [Toss TEST gate](../supabase/verification/payments/provider-test.md): official TEST/Sandbox/API documentation reviewed; runtime TEST credentials/session unavailable, calls0. Provider-only TEST may proceed independently once configured, with no Ledger access. Provider success must never be promoted to APP/LAB end-to-end success.

Next: Owner migration review, then separately authorized apply/config and LAB payment implementation. LIVE additionally requires payment/deletion reconciliation for provider-paid/ungranted outcomes, financial privacy/retention, statutory exception handling, operational reconciliation and explicit Owner activation. Current public policy and Production remain unchanged. Unified Wiki and LAB were not modified in this APP-only phase.

## PAYMENT-E2E-PREP-1 — 2026-10-03

Canonical candidate3b3b869 / hash77b460bf… supersedes e4836eda pre-apply. Original60
payment checks retained;67 current checks and Credit84, Humanities102, Math131+37+63
rerun PASS. [Independent Hosted TEST bootstrap package](../supabase/verification/payments/hosted-test/README.md)
contains24 exact ordered hashes and function ownership/ACL inventory; fresh non-superuser
PG17 install, postflight, payment rollback/failure restoration and local authenticator
finance SET/revoke PASS. Managed Auth/JWT signatures/expiry remain HOSTED_VERIFICATION_REQUIRED.
LAB Preview pair enforcement and real workerd redirect checks are implemented on its
payment feature branch. Official documentation Sandbox proof is recorded in LAB; merchant
leglabn24k E2E remains NOT_RUN. No project/config/deployment/Production changes.
Next: Owner approves empty TEST project creation, then package/config/gateway verification,
then separately authorized merchant E2E. Do not replay bootstrap into Production.

## PAYMENT-E2E-HOSTED-COMPAT-1 — 2026-10-03

[Corrected local compatibility evidence](../supabase/verification/payments/hosted-test/README.md#payment-e2e-hosted-compat-1--2026-10-03): PREP-1's public-owner normalization removed. Observed `pg_database_owner` owner/grantor, managed roles/memberships and schema/default ACL reproduced. Same 24 immutable migrations PASS as non-superuser; exact catalog, six injected failures and empty rollback PASS. Payment67, Credit84+static7, Humanities/HQP102, Math131+37+63 rerun PASS. No canonical migration change needed.

This supersedes the simplified PREP-1 fixture as Hosted compatibility evidence. Real Auth/extensions/gateway are not emulated. Existing Hosted TEST project remains untouched, applied0/24; no Finance/Cloudflare/Toss/Production action. Ready to resume HOSTED-1 with fresh preflight; actual installation and merchant E2E remain unverified.

## PAYMENT-E2E-HOSTED-1 — actual TEST installation, 2026-10-03

[Hosted evidence](../supabase/verification/payments/hosted-test/hosted-validation.json): fresh preflight PASS; exact24 files installed, per-file and final114 function catalog/ownership/ACL PASS. Public owner/grantor remains pg_database_owner; custom roles/memberships and payment RLS/TEST foundation PASS. Payment, Credit and Auth counts0; spendable delta0. No unexpected grants. SQL installation verified; migration-ledger tracking NOT_CREATED, no repair. Production untouched. Finance gateway, signing/JWT/token, Cloudflare and Toss NOT_CONFIGURED/NOT_RUN. Ready for separate Finance gateway authorization; stop before configuration.

## PAYMENT-E2E-FINANCE-1 — 2026-10-04

[Hosted gateway evidence](../supabase/verification/payments/hosted-test/finance-validation.json): A–G gateway and owner/foreign-profile RLS pass. Overall BLOCKED: two authenticated profile creations triggered existing signup_bonus3 each (+6 spendable TEST Credit), violating required zero delta. Pre-activation signup branch persists when ADR enabled=false; missing HMAC marker alone does not suppress it. One unconfirmed TEST order/event, no payment operations/purchase grant/LIVE grant. Stop without ledger cleanup, trigger/schema changes or ADR activation. Owner review required; no Cloudflare/Toss/Production action.

## PAYMENT-E2E-FINANCE-1A — 2026-10-04 COMPLETE

Owner corrected zero-total-delta to payment-attributable zero. [Read-only lineage evidence](../supabase/verification/payments/hosted-test/finance-lineage-validation.json): buyer signup+3/gateway signup+3 proven through account/grant/transaction and canonical posting metadata; payment-attributable delta0, purchase/LIVE grants0, unexplained0. Prior BLOCKED record retained for traceability; no bonus removal or ledger/policy change. Actual Hosted A–G PASS preserved; narrow membership rechecked. Gateway Auth identity suffices; future gateway preparation omits public profile. Existing profile/bonus retained. Payment69/Math131+37+63 regressions PASS. Ready for separate Cloudflare authorization; no config/provider/Production action.

## Cloudflare TEST token lifetime — Owner decision, 2026-10-04

Owner approved24h for this dedicated TEST verification token; canonical offline signer
default stays1h, optional final argument86400 selects24h, all other lifetimes rejected.
Synthetic signature/claims/mode0600/default/24h/invalid-lifetime/Production/overwrite tests PASS.
No role, signing configuration, migration or financial changes. Cloudflare runtime
verification remains pending; key-to-MID match UNVERIFIED, merchant E2E not ready.

## PAYMENT-PRODUCTION-READINESS-1 — 2026-10-04

TEST E2E COMPLETE preserved. [Production review package](../supabase/verification/payments/production/README.md) and [exact two-file manifest](../supabase/verification/payments/production/manifest.json) prepared; apply BLOCKED pending prerequisite/Owner review. Explicit read-only Production audit:23 tracked migrations, ADR/Payment absent, purchase grants0, nine existing ADR security contracts PASS, pg_database_owner preserved. No Production mutation. Canonical migration hashes unchanged.

Isolated Payment81/Math131+37+63/Credit84+7/HQP102 PASS, including all four LIVE-equivalent SKU quantities, UTC calendar-month ends,8,100 refund and actual consumption/cancellation competition. Same ledger reused. APP/LAB visible balance parity, LAB LIVE adapter, operational recovery/kill-switch/finance renewal and support/legal cancellation remain pre-LIVE gates. Only a code preparation branch was changed; no activation or deployment.

## Runtime extension preservation review (2026-10-04)
The seven preservation checks: occurrence/record timestamps remain distinct; original ledger postings stay immutable and reproducible; derived balance reads do not replace history; subjects reuse auth.users identities; learning facts remain separate from support decisions; bounded financial operator audit contains no learning data or credentials and is finance-only; credit-v1 is explicitly a derived as-of summary, never a new wallet. Existing consumption ordering and expiry policies are unchanged.

## PAYMENT-PRODUCTION-IMPLEMENTATION-1 — implemented, not activated

TEST_E2E COMPLETE remains accepted historical runtime evidence. PRODUCTION_IMPLEMENTATION COMPLETE (deterministic/local); PRODUCTION_DB_APPLIED NO; LIVE_ENABLED NO. `20261004000100_payment_runtime.sql` SHA-256 `b1613b352ceed6ab300c08c04decf5bb036d019e4318da159b6f3f859f4a6ab3` adds `credit_summary()`, `payment_support(jsonb)` and `payment_compensate(jsonb)` plus private support audit. Canonical Payment migration hash is unchanged. [Three-file exact Owner package](../supabase/verification/payments/production/README.md) remains review-only; latest Production read-only evidence is the preceding readiness audit, no fresh Production access this task. Fresh preflight/apply needs Owner approval.

APP LAB screen and Web account read identical credit-v1, with source-specific spendable quantities and nearest expiry; no new wallet. APP evaluation changes invalidate the read, and manual refresh is available. Reservations, expired entitlements and pending-cancel fences are excluded. Existing signup entitlement has no expiry; ADR signup issuance gate is unchanged. Native app exposes no external purchase CTA.

Payment117 includes all SKUs, concurrency, TEST+0, expiry, real canonical Essay purchase5→success4→included revision4→new answer3, support refund17900−2×4900=8100, cancellation fences, owner/ACL defenses, failure rollback, and history-preserving rollback refusal. Essay84+static7, Humanities/HQP102, Math131+37+63 unchanged suites PASS. Flutter analyze PASS, focused Credit/Essay64 PASS with1 opt-in local skip. Full Flutter927 PASS,2 skips,5 failures: day6_repositories parent projection2, day5_shell badge1, materials_delivery_journey2. All five reproduce at baseline8881eee in a separate checkout; unrelated behavior/tests not modified. Therefore overall unqualified REGRESSION is FAIL, while payment-scoped regression PASS.

LAB feature implements LIVE adapter only with exact Production origin/project, live key family and canonical MID; TEST remains dedicated project with exact verified tleglabn24k response mapping. `PAYMENT_ENABLED=false` stops new purchases/provider confirm; existing DONE confirmation and cancellation recovery remain available. Missing configuration fails closed. Support operations use fresh Auth allowlist before finance RPC; normal buyers retain own-order checks. No financial credentials reach browser. See LAB existing handoff for canonical environment/runbook.

Remaining external gates: fresh Production preflight, separate ADR/payment/runtime migration approval, finance signing/subject/token/config and renewal ownership, Toss/card approval, Owner activation and separately approved1c LIVE smoke. Pricing integration is an exposed runtime contract; approved pricing branch untouched/unmerged. General refunds only; statutory decisions remain authorized support policy and are not inferred from age. No Production mutation, provider calls, main merge, deployment, IAP or student data.

Restricted-account compensation: finance-only payment_compensate takes only server-verified provider DONE identity/amount/paid_at and requires pending LIVE confirmation, no grant and an actually restricted/detached subject. It atomically closes confirmation and claims full refund with revoke_quantity0; existing cancellation finishes without any ledger posting. Duplicate/active-owner/browser defenses are tested. No account resurrection or statutory inference. Existing mismatch monitor intentionally flags no-grant compensated LIVE rows for bounded operator review; inspect completed cancellation before classifying a true orphan grant.

## 2026-10-25 관리자 모바일 구매 집계 정정·스토어 준비

과거 TEST-only/미적용 체크포인트는 당시 기록이다. 현재 Production IAP verify v23 ACTIVE, Google1건1크레딧·Apple2건4크레딧 지급 확인. 구매5중사용1로가용4. 웹 payment_orders는 Toss만 집계해 모바일이 빠졌다. Owner가 새 관리자 읽기 RPC를 적용했고 WEB8261d17/Production7ff387f2에서 모바일 집계/5행 페이지/한국어 예약·확정 표시 확인. 원장/지급함수/결제설정 변경0. 금액·통화·환경 저장이 없어 IAP매출은 추정하지 않는다. [SQL·보존7항·검증·rollback](https://github.com/LC3808/legendstudy-lab/blob/codex/web-app-release-20261024/docs/admin-purchases-20261025/README.md).

스토어 준비: 기존 ignored production config를 `--config`로 전달하여 양 플랫폼 wrapper --check PASS. 구매·크레딧4파일12테스트PASS. 최신 앱 소스의 Android서명설정 존재, iOS Auth.local.xcconfig 부재. 콘솔은Apple로그인/Play기존개발자계정전환 필요. 최신 배포번호/심사상태 미확인으로 업로드번호 확정·서명빌드·스토어 제출은 미실행. 기존1.0/build19,Android18과 실기기2026102401은 역사적 증거로 구분한다. 다음: 콘솔의현재버전→기존Auth설정 확인→중복없는번호의통합RC→기기검증→업로드. 새구매/수동지급/Secret교체 금지.

## 2026-10-25 사용자 크레딧 내역 표시 정책

Owner 추가지침: Android/iOS/WEB 사용자 거래 목록은 reserve/release를 표시하지 않는다. consume 확정은 동일 billing decision의 grant별 postings를 합쳐 `논술 첨삭 · -1 크레딧`처럼 실제 balance_delta 부호로 표시한다. 구매/지급/실제환불·회수/만료 내역은 보존한다. 예약은 가용잔액에 계속 반영하며 관리자Ledger 원본은 그대로 표시한다.

APP은 owner RLS 조회에서 reserve/release를 제외한 뒤 최근50기록을 읽고, 선택한consume decision의 모든postings를 다시 읽어 페이지경계의 일부금액만 표시하지 않도록 한다. UI에서도 예약행을제외한다. WEB은 기존숨김/합산방식 유지,명칭·단위를APP과통일하고decision없는legacyconsume도유지한다. 잔액은기존credit_summary/credit-v1을소비하며내역으로재계산하지않는다. 대학·시험명은현재크레딧조회에없으므로추정표시하지않는다.

보존검토: (1) 기존발생시각을표시하고새사실을기록하지않음; (2) immutable Ledger로재구성가능; (3) UPDATE/삭제없음; (4) 기존owner계정/RLS유지; (5) 금융사용내역이며Learning/Decision/Outcome를새로만들지않음; (6) 기존본인조회권한·보존기간불변/추가PII없음; (7) 합산은화면projection일뿐원장을대체하지않음.

검증: APP구매/Credit15PASS·변경Dart analyze문제0; WEB관련80PASS/2skip·typecheck/Lint/boundaryPASS. 원장입력불변/다중grant합산/예약만있는경우/실제환불·회수/예약중잔액유지 확인. 실기기·운영배포는미실행. DB·Ledger·정산·관리자코드변경0.

Owner가앞선조기빌드중단지시: Android1.0.1(20) 후보는이번수정이전산출물이므로업로드대상아님; iOS빌드중단/스토어업로드0. 현재스토어실측Android1.0.0(18)전체출시/iOS1.0(build19)배포준비됨. 모든앱수정을마친뒤새빌드·검증·업데이트한다. 이번수정은로컬commit이며push/CI·빌드·배포도보류한다.

## TASK17 — 2026-11-02 TEST 결제 복구

기존 REVIEW/TEST 정책을 유지한다. Owner는 새 TEST API 키를 채팅에 보내지 않고 Cloudflare `legendstudy-lab` Settings → Variables and Secrets → Production에 직접 등록한다. `TOSS_TEST_CLIENT_KEY`와 encrypted `TOSS_TEST_SECRET_KEY`만 교체하며 REVIEW를 plain TEST/LIVE로 바꾸지 않는다. 전용 WEB 브랜치 `codex/toss-test-task17`의 기존 배포2b5b0656을 Cloudflare API로 재확인했고 runtime503 PAYMENT_NOT_CONFIGURED가 지속된다. 실제 키 유효성은 metadata로 확인 불가.

운영DB 읽기검증: configuration TEST, TEST주문11/정상기록3/지급연결0, LIVE주문0. 기존Credit grants35/transactions124의 비교해시 확보. 결제123회귀PASS·심사10URL HTTP200은 실제승인 증거가 아니다. 새키등록→보존배포→심사계정 TEST요청/승인/성공·실패→지급0/운영원장보존→재제출보고서 순서로 진행한다. 키등록과 후속은 미완료; 운영Credit·LIVE활성화 금지. [WEB 실행·설정·증빙 기록](https://github.com/LC3808/legendstudy-lab/blob/codex/toss-test-task17/wiki/toss-test-task17.md).

### TASK17 기존 TEST 환경 재확인 — 2026-11-02

Owner 최신지시로 앞선 키재등록 요청은 보류/대체한다. Cloudflare 실측 payment-test는 TEST/전용pages.dev/테스트DB wsnrwklplnunjktyfmbr이고, LAB만 REVIEW/운영도메인/운영DB다. TASK17 배포는 LAB2b5b0656, 기존TEST배포bb59b083(Oct06). 기존TEST runtime200·동일클라이언트키·1Credit TEST주문생성·Toss 카드인증창 진입 확인. Secret 유효성/승인성공은 아직 미검증, Owner 카드인증 대기. LAB runtime503은 별도이며 신규키·설정변경·배포 없이 기존TEST 경로를 우선 재사용한다. 09:43KST 운영 주문11/LIVE0·Credit grants35/transactions124 해시 전부 사전과 동일, TEST grants2/transactions2 해시 동일·지급연결0. 승인 이후 재검증 필요. 재심사는 실제 서비스도메인 결제경로 확인까지 NOT_READY. [WEB 비교·증빙](https://github.com/LC3808/legendstudy-lab/blob/codex/toss-test-task17/wiki/toss-test-task17.md).

### TASK17 payment_review 전용 계정 — 2026-11-02

Owner 확정: payment@legendstudy.com만 기존 /pricing/에서 TEST 결제, 일반/review@/관리자는 HOLD. 가격4900/11900/17900/29900 불변. 기존 confirmed Auth user6eda61e2-be13-4793-a094-5500309b5b4d/non-admin 재사용. 서버 PAYMENT_REVIEW_SUBJECTS를 이 UUID 하나로 PATCH하여 payment_review 권한을 구현한다. 이메일·user_metadata·관리자 권한으로 우회하지 않으며 기존 auth/v1/user 검증이 매 REVIEW 요청에 적용된다. 새테이블·인증·admin권한 없음.

운영배포 ed3c8c8b-4dfb-4373-b63b-aff40afa307b/source d326e67: 정적자산1178개 전부 보존, 설정검사 함수에 값 없는 boolean 진단만 추가. 실제503 원인은 PAYMENT_FINANCE_TOKEN 누락/빈값으로 확인; TEST키형식/MID/공개설정 PASS. 새Toss키 불필요, 기존 운영용 finance credential 복구 필요(TEST DB토큰·service_role 대체금지).140테스트/typecheck PASS, Owner payment로그인 확인. 실제 A/B/C/D 권한수용·승인E2E는 설정오류로미완료.

09:57KST 기존35 grants/124 transactions 해시 보존, TEST주문11/LIVE0/TEST지급연결0 유지. 전체는37/126이며 증가2건은 signup_bonus_v1+6; 총Credit불변으로 오기하지 않는다. 결제귀속지급0. 심사종료: PAYMENT_ENABLED=false 및 허용목록비움→재배포→서버차단 확인; TEST기록보존. [WEB 실제설정·배포·인수인계](https://github.com/LC3808/legendstudy-lab/blob/codex/toss-test-task17/wiki/toss-test-task17.md).
