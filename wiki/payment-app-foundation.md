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

### TASK17 Finance 바인딩 진단 정정 — 2026-11-02

Owner Secret삭제·교체금지. Dashboard/API 등록확인; 앞선 “미등록/누락” 표현을 정정한다. 운영88a28465-0c5f-46ad-b76c-9323b3dfd606/source fccff25에서 finance_key_present=true/is_string=true/is_empty_string=true 실측. reviewer는존재/비어있지않음. TEST키형식·MID검사PASS. context.env는변경없이전달되며 설정검사에서Supabase호출전503; 서명/만료/권한오류401과다르다.

Production설정전체·자산1178불변재배포로도동일. 암호화저장값이빈것인지Cloudflare전달문제인지는redacted metadata로구분불가; 원인단정·새키요청안함. 기존설정재사용검증은수행했으나복구는미완료. Supabase payment_process는essay_finance만EXECUTE,유효identity필수,DB함수/ACL불변.141테스트/typecheck PASS. 별도TEST runtime200/승인미완료,운영TEST주문11/LIVE0/지급연결0/기존원장해시동일. Secret·DB쓰기0. [상세진단](https://github.com/LC3808/legendstudy-lab/blob/codex/toss-test-task17/wiki/toss-test-task17.md).


### TASK17 Finance 최종 원인 구분·복구 절차 — 2026-11-02

Production 빌드전용 진단77cc3c43에서 앱실행 전 process.env에도 finance present/string/empty=true, reviewer nonempty=true. exit73으로 배포 전 종료, pnpm build복원·환경설정동일·운영88a28465보존. 따라서 코드기본값·Functions전용접근오류가 아닌 Cloudflare 제공설정 문제다. [10/23 Secret replay 사고](essay-p0-direct-execution-20261023.md)에 Finance 영향이 명시돼 있고 이후 Finance 복원근거는 발견하지 못했다. 이는 현재빈값과일치하는유력원인이며 암호화저장상태/정확한과거쓰기의증명은아니다.

기존운영토큰은API로읽어복구할수없음. Owner 안전저장소의원본→운영DB read-only get/nonexistent검증(PT404)→Owner 승인복원→보존재배포 우선. 만료/분실시 기존Production발급주체·essay_finance·기존gateway subject를확인한뒤 제한만료토큰재발급; TEST/service_role/worker대체·새서명키·ACL변경금지. 현재issuer/subject미확인으로임의발급안함. Dashboard위치·오류구분·재검증순서는 [WEB 실행절차](https://github.com/LC3808/legendstudy-lab/blob/codex/toss-test-task17/wiki/toss-test-task17.md#safe-owner-recovery-procedure-not-executed).

최종운영runtime503/별도TEST200, 기존35grants·124transactions해시동일/LIVE0/TEST지급연결0. Secret교체·DB쓰기0. 승인E2E·복구·재심사제출은미완료이며운영LIVE HOLD유지. 앞선저장/전달원인미확정기록은위빌드전증거로좁혀졌다.


### TASK17 원본 Finance 토큰·서명키 발견 — 2026-11-02

앞선 원본/issuer/subject 미확인 기록을 정정한다. 범위를홈디렉터리까지확장해 기존 review-finance-token.jwt와 review-signing-key.jwk를발견했다(둘다0600,Git밖). 토큰원문/키/subject는기록하지않았다. 기존JWT는Production issuer·essay_finance·nonnull sub, 발급2026-10-07 08:37:24Z/만료2026-10-14 08:37:24Z. 현재Production JWKS로서명검증PASS;보관private JWK의공개부분/kid도현재검증키와일치. DB조회로기존gateway Auth계정존재/allowed=true 확인. 원본은존재하지만만료되어그대로복원불가.

발급코드최초Git근거9ea7e2a7(Oct03 TEST),실제TEST발급/검증Oct04; Production REVIEW확장은원격 origin/manus/payment-review-signer-1의 ed5a53a92dbad83970ad3f36d1b276f826ceda90(Oct07). 현재작업브랜치에는TEST전용이어서놓쳤던이력이다. 해당커밋의 mint-finance-token.mjs는명시옵트인/정확한운영project/ES256/essay_finance/최대7일,0600새파일,원문출력없음. 당시운영토큰을누가어떤명령으로생성했는지실행로그는미확인이나동일claim/기간·서명키·Oct07실제승인기록이있다. 합성키로해당커밋회귀PASS.

서버경로: Pages context.env→cloudflare/payments.ts rpc finance Authorization→Supabase PostgREST 서명·만료·role검증→public.payment_process→essay_private.uid()/account_private.allowed. 실제운영authenticator→essay_finance는SET=true/INHERIT=false/ADMIN=false;finance NOLOGIN/NOBYPASSRLS, payment_process EXECUTE 허용·anon/authenticated/service_role거부. 결제Edge Function이나원문대조테이블을쓰지않는다. JWT는payment-only가아닌기존finance권한이므로브라우저배포금지.

안전갱신: 기존키/기존subject/issuer/role를그대로재사용하고iat/exp만갱신,초기검증TTL1시간권장. 서버키·DB권한변경불필요. 새0600파일에만저장→운영RPC get/nonexistent UUID PT404확인→Cloudflare PAYMENT_FINANCE_TOKEN 단일Secret복원→보존재배포→REVIEW권한/TEST E2E. 서명키를Cloudflare에넣지않는다. Secret삭제는이미유출된JWT의암호학적폐기가아니며신규요청차단은HOLD/권한회수로별도검증한다. 원본이발견되어이번요청의“없다면새발급절차”조건은만료토큰갱신절차로대체;실제발급/설정/DB쓰기0. [실행절차](https://github.com/LC3808/legendstudy-lab/blob/codex/toss-test-task17/wiki/toss-test-task17.md#original-token-found--2026-11-02).


### TASK17 Toss 최종심사 준비 — 2026-11-02 오후

Owner가Toss회신을근거로WEB결제화면Credit→이용권,구매횟수만큼논술첨삭명시,기존review@재사용을지시했다. 앞선payment@전용결정을대체한다. review기존Auth UUID ddc5ae63-acbb-490b-a423-c996b811dea8만서버허용목록;관리자권한부여없음. WEB요금/결제/환불/해당header명칭만변경,가격4900/11900/17900/29900·DB·APP·MY/학습화면Credit구조보존. 홈페이지전체명칭변경완료라고보고하지않는다.

기존키/subject로24h Finance갱신,read-only PT404 PASS후Cloudflare 두Secret(finance/reviewer)만반영. DB서명키/ACL변경0. 만료2026-11-03 13:21:09 KST,심사일정전갱신필요/자동갱신없음. 최종운영9459776f-fecf-47ca-8f01-35f2f661813a/source ecd8ffc,REVIEW/TEST200,consumer_purchase=false(비로그인). 중간정적빌드공개Auth환경누락으로결제페이지로그인이해제되어보이는문제는기존NEXT_PUBLIC설정재빌드및배포preflight추가로수정했다. 운영984개비결제자산동일.

Owner review로그인→1회TEST주문 f1f36979-33fa-4ee2-971d-7646d6e367f8→실제Toss창표시PASS. 창취소→취소되었습니다PASS. 비로그인orders/confirm/status/cancel401,관리자결제disabled. 일반계정실제로그인/실제거절callback/승인후환불은미검증;로컬권한회귀PASS. 실패페이지실접근PASS. Owner카드인증후승인성공E2E/TEST_RECORDED확인대기. 실제성공으로과장금지.

회귀175+계정잔액15/TS/lint/build PASS. 04:21:29Z기준50grants·139transactions해시보존(6b878f50751867093aa02d3a2eed9f3f / 8650fb83ce93cf837b37a801c1d15e79),LIVE0/TEST지급0. 이전오전35/124와다른기준이며동시가입증가를결제지급으로해석하지않는다. [심사안내서·미완료구분](https://github.com/LC3808/legendstudy-lab/blob/codex/toss-test-task17/docs/TOSS_FINAL_REVIEW_GUIDE_TASK17.md). 외부메일/재심사제출0,LIVE HOLD.


### TASK17 TEST 성공 승인 확정 — 2026-11-02 13:30 KST

Owner카드인증후완료화면의논술랩이용하기/마이페이지이동확인·논술LAB이동. Owner제공Toss TEST API로그는confirm HTTP200/DONE,승인13:30:30 KST. 동일주문 f1f36979-33fa-4ee2-971d-7646d6e367f8 운영DB PAID/TEST_RECORDED/grant NULL/CONFIRM SUCCEEDED정확히1건을독립조회확인. TEST성공승인E2E PASS,이전승인대기기록대체. 기존50grants/139transactions해시동일,LIVE0/TEST지급연결0. 전체51/140증가1건은동시signup_bonus_v1+3이며결제귀속지급0. 실제카드사거절callback/승인후환불은미검증. 재심사안내서갱신,외부전송0/추가배포0.


### TASK17 상품 명칭 정정 — 2026-11-02

Owner는기존합의대로사용자노출AI명칭제거를지시했다. 앞선Toss회신의서비스분류를상품명AI표기로확대한것은Agent오류이며Owner결정이아니다. WEB요금/환불/상품설명/Toss새주문상품명/재심사안내서에서AI제거. 기존승인거래의원래상품명은감사기록으로보존,결제원장수정없음.


### TASK17 결제 확인 대기 화면 — 2026-11-02

Owner스크린샷의대기화면을완료카드와통일.시계아이콘/진행안내,처리중재확인·이동버튼숨김,오류시복구버튼표시.초기busy로버튼깜빡임방지.API승인흐름불변.17테스트/build PASS,운영e081a02c/source8180124의대기안내·복구카드실접근확인.추가결제/원장/설정변경0.


### TASK17 약관·개인정보 용어 통일 — 2026-11-02

Owner가지정한/terms/·/privacy/의크레딧을이용권으로변경한다. 공용정책본문·약관metadata·두경로header표시포함.금액/기간/환불/개인정보처리조건·DB/APP변경없음.관련20테스트/build PASS.


### TASK17 WEB 전체 용어 점검 — 2026-11-02

Owner의전체점검요청:56페이지엔트리/전체src문자열/정적export155운영URL GET200 확인. 공개HTML잔여는/support/,/essay-lab/,/account/credits/ 및관리자credit/내부connection. 소스문자열잔여42파일146조각(사용자공용23/83,관리자18/62,내부1/1);문장수/노출횟수아님. 로그인후모달·오류분기는소스확인,실제전체실행아님. 사용자세션로그아웃상태,자유입력공지DB전체는미조사. [전체위치·범위·한계](https://github.com/LC3808/legendstudy-lab/blob/codex/toss-test-task17/docs/TASK17_WEB_TERMINOLOGY_AUDIT.md). 이번은점검만,코드/배포/DB변경0.


### TASK17 WEB 전체 이용권 통일 — 2026-11-02

Owner 최신지시로 관리자까지포함하여 WEB 고정표시명칭 크레딧/Credit→이용권 통일. MY·논술/수리·제출/오류/모달·관리자·공용header·metadata포함. DB/RPC/APP/기존원장/과거기록불변. 전체회귀1552PASS/4skipped,TS/build PASS. 기존Functions/Secret보존배포. 로그인후모든상태수동검증은아니며소스/회귀로보완. [WEB 변경·실접근검증](https://github.com/LC3808/legendstudy-lab/blob/codex/toss-test-task17/docs/TASK17_WEB_TERMINOLOGY_AUDIT.md).
