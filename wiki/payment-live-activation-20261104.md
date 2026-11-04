# Toss WEB LIVE activation — 2026-11-04

Status **PARTIAL**. Owner LIVE activation approved; implementation and isolated verification completed. Production DB preparation and WEB REVIEW preparation deployed; LIVE activation pending; LIVE_VERIFIED NO / PRODUCTION_ACTIVE NO.

This supersedes the previous [TASK17 HOLD decision](payment-app-foundation.md#task17-toss-최종심사-준비--2026-11-02-오후) for WEB only. Fixed confirmed Auth UID ddc5ae63-acbb-490b-a423-c996b811dea8 AND exact review@legendstudy.com remains TEST. Other authenticated users use LIVE. Server checks current Supabase Auth; client email/mode/is_test never selects environment. Existing order mode determines confirm/reconcile/refund credentials even after identity/config changes. No APP58/StoreKit/Play/bonus/beta/price/refund-policy changes.

## Actual audit

- Production stlhijzpjfgwwdgunlsd: configuration TEST;18 TEST orders,9 PAID/TEST_RECORDED,9 ORDER_CREATED;TEST grant0/LIVE order0. Latest TEST paid2026-11-02 16:27:47KST; historical successful TEST evidence preserved.
- Existing payment_order selects global mode; payment_process rejects a different global mode. Cloudflare-only LIVE switching cannot retain review TEST. Existing grant/cancel/compensation logic already supports LIVE and atomic ledger/idempotency.
- Cloudflare legendstudy-lab Production: REVIEW, enabled true; TEST keys/Finance registered, LIVE keys와 환불담당 PAYMENT_SUPPORT_SUBJECTS initially absent. Values never printed. Current deployment1e842209-74a6-478c-846c-ebea8779fcf4/source metadata0e735c6fbf74d3351cbb8eca9915b1c650c37251 differs from previous TASK17 deployment. Source found in /tmp/legendstudy-feedback-web-20261104 and integrated into TASK17; only deployed0e735c6 imported, later unrelated changes excluded.
- Admin rows and paid totals distinguish modes; revenue parser accepts LIVE/KRW only. Old DB runtime label LIVE_OFF is hard-coded; candidate WEB fetches actual runtime instead.

## Implementation and verification

WEB branch codex/toss-test-task17: account-specific server selection, both key families kept separate, four SKU price/quantity checks, old-order recovery, stale create retry via existing new-order flow, explicit no-charge/no-entitlement TEST banner. Ordinary LIVE UI omits TEST banner. Existing provider lookup-first/idempotency/finish/refund logic reused.

[Exact DB review package](../supabase/verification/payments/live-20261104/README.md) includes prepare/activate/postflight SQL, preservation answers and recovery procedure. prepare adds one private helper and changes two existing functions' mode expressions; exact previous hashes/identity/topology guards; no historical rows or ledger changes. Configuration stays TEST until separate activation. Requested Owner approval before applying this newly required DB change.

Local WEB1563 PASS/4 skipped; final admin/payment201 PASS; typecheck/build/lint PASS. Disposable PG existing payment/Math regressions and21 new mixed-mode checks PASS: TEST+0, LIVE grant3 once, duplicates, refunds, identity changes, legacy TEST recovery, private ACL, history preservation. [Evidence](../supabase/verification/payments/live-20261104/validation.json). Synthetic provider/isolated DB validation is not hosted TEST or LIVE E2E. No actual payment/cancellation performed.

## Remaining gates

Owner asked to add TOSS_LIVE_CLIENT_KEY/TOSS_LIVE_SECRET_KEY as Production Secrets and confirm merchant LIVE/card/domain approval, retaining TEST keys and REVIEW until verified. Owner approved preparation; hosted migration20261104021443 applied. Existing Finance JWT previously expired11/3; current runtime validity must be verified/renewed safely through existing signer (registered binding alone is not proof). Establish current deployment source/worker preservation. Then hosted reviewer TEST regression, staged LIVE activation and Owner-approved1c/4,900KRW smoke on named ordinary account; announce target and amount before charge/cancel. Verify exactly one purchase grant/ledger entry and permitted refund; do not touch existing customer orders. Until actual approval/grant success, never report LIVE_VERIFIED.

Recovery after LIVE history: PAYMENT_ENABLED=false pauses new orders/confirm while keeping DONE reconciliation and refunds. Keep dual-mode DB/handler; do not set DB back to TEST or delete/mutate historical modes. New signing key/role/schema redesign is unnecessary. Full guide is in the linked review package.

## Owner 승인 준비 SQL 적용 — 2026-11-04

[운영 영수증](../supabase/verification/payments/live-20261104/production-prepare.json): hosted migration20261104021443,원문을동일버전repository migration으로보존. 적용전후주문18/지급167/거래262전체행hash동일,helper EXECUTE postgres/essay_executor만허용,임시SET/CREATE회수PASS. DB TEST/WEB REVIEW유지. Owner입력완료후LIVE두키/기존TEST두키등록확인(원문미출력),실제키인증/상점승인미확인. 최신운영소스통합후결제/관리자242PASS/1opt-in skip.

준비WEB 배포617be5aa-2f7f-43bd-bf9c-0937b721119f/source a901568fa7b0acc752061d6fd7361ad5772875c8. 운영canonical success/manifest일치/환경설정전체동일. 요금·결제·관리자결제·문의·논술6URL HTTP200,runtime REVIEW/TEST/비로그인consumer_purchase=false. 기존라우팅동일,결제외API입력불변. LIVE키등록은존재확인이며실제키유효성/상점승인/Finance갱신/환불담당권한/새TEST·LIVE E2E는남아있다. 실제청구/취소0.

## Finance 갱신·상점 승인 확인 — 2026-11-04

Owner가 LIVE 카드 사용 승인과 lab.legendstudy.com 도메인 등록 완료를 확인했다. 기존 서명키의 공개부분을 현재 JWKS와 대조하고 기존 Finance subject/role/issuer로 7일 토큰을 갱신했다. 읽기 전용 payment_process get/nonexistent PT404 PASS 후 PAYMENT_FINANCE_TOKEN만 좁게 갱신, 다른 설정 보존. 만료2026-11-11 11:25:53KST; 자동갱신 없음, 만료 전 Owner 안전 갱신 필요. 서명키/DB ACL 변경0, 비밀값 출력0.

배포1f83e03e-cc84-4fdd-a627-35d8798dd4f5/source a901568fa7b0acc752061d6fd7361ad5772875c8, 기존1463자산 모두동일. 주요6URL200, 익명runtime REVIEW/TEST. Finance 검증은 직접 RPC까지이며 배포후 인증사용자 E2E는 로그인 대기. [영수증](../supabase/verification/payments/live-20261104/finance-recovery.json).

원래 주문18·지급167·거래262의 hash는 보존됐다. 검증 사이 정상 signup_bonus 1건(11:22:01KST)이 추가되어 현재 지급168/거래263이며 결제 지급이 아니다. TEST 지급0/LIVE주문0, DB TEST 유지. Owner 지정 실결제·환불 담당 admin@legendstudy.com은 기존 관리자임을 확인했다. 대상1회4,900원; support allowlist 설정/실제 TEST 회귀/LIVE 활성화·청구·환불은 미완료.
