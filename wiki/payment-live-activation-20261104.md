# Toss WEB LIVE activation — 2026-11-04

Status **PARTIAL**. Owner LIVE activation approved; implementation and isolated verification completed. Production DB/schema/config/deployment unchanged; LIVE_VERIFIED NO / PRODUCTION_ACTIVE NO.

This supersedes the previous [TASK17 HOLD decision](payment-app-foundation.md#task17-toss-최종심사-준비--2026-11-02-오후) for WEB only. Fixed confirmed Auth UID ddc5ae63-acbb-490b-a423-c996b811dea8 AND exact review@legendstudy.com remains TEST. Other authenticated users use LIVE. Server checks current Supabase Auth; client email/mode/is_test never selects environment. Existing order mode determines confirm/reconcile/refund credentials even after identity/config changes. No APP58/StoreKit/Play/bonus/beta/price/refund-policy changes.

## Actual audit

- Production stlhijzpjfgwwdgunlsd: configuration TEST;18 TEST orders,9 PAID/TEST_RECORDED,9 ORDER_CREATED;TEST grant0/LIVE order0. Latest TEST paid2026-11-02 16:27:47KST; historical successful TEST evidence preserved.
- Existing payment_order selects global mode; payment_process rejects a different global mode. Cloudflare-only LIVE switching cannot retain review TEST. Existing grant/cancel/compensation logic already supports LIVE and atomic ledger/idempotency.
- Cloudflare legendstudy-lab Production: REVIEW, enabled true; TEST keys/Finance registered, LIVE keys와 환불담당 PAYMENT_SUPPORT_SUBJECTS initially absent. Values never printed. Current deployment1e842209-74a6-478c-846c-ebea8779fcf4/source metadata0e735c6fbf74d3351cbb8eca9915b1c650c37251 differs from previous TASK17 deployment. Source object absent in fetched LAB repository and local LegendStudy checkouts; preserve actual current deployment before shipping.
- Admin rows and paid totals distinguish modes; revenue parser accepts LIVE/KRW only. Old DB runtime label LIVE_OFF is hard-coded; candidate WEB fetches actual runtime instead.

## Implementation and verification

WEB branch codex/toss-test-task17: account-specific server selection, both key families kept separate, four SKU price/quantity checks, old-order recovery, stale create retry via existing new-order flow, explicit no-charge/no-entitlement TEST banner. Ordinary LIVE UI omits TEST banner. Existing provider lookup-first/idempotency/finish/refund logic reused.

[Exact DB review package](../supabase/verification/payments/live-20261104/README.md) includes prepare/activate/postflight SQL, preservation answers and recovery procedure. prepare adds one private helper and changes two existing functions' mode expressions; exact previous hashes/identity/topology guards; no historical rows or ledger changes. Configuration stays TEST until separate activation. Requested Owner approval before applying this newly required DB change.

Local WEB1563 PASS/4 skipped; final admin/payment201 PASS; typecheck/build/lint PASS. Disposable PG existing payment/Math regressions and21 new mixed-mode checks PASS: TEST+0, LIVE grant3 once, duplicates, refunds, identity changes, legacy TEST recovery, private ACL, history preservation. [Evidence](../supabase/verification/payments/live-20261104/validation.json). Synthetic provider/isolated DB validation is not hosted TEST or LIVE E2E. No actual payment/cancellation performed.

## Remaining gates

Owner asked to add TOSS_LIVE_CLIENT_KEY/TOSS_LIVE_SECRET_KEY as Production Secrets and confirm merchant LIVE/card/domain approval, retaining TEST keys and REVIEW until verified. Owner DB preparation approval is pending. Existing Finance JWT previously expired11/3; current runtime validity must be verified/renewed safely through existing signer (registered binding alone is not proof). Establish current deployment source/worker preservation. Then hosted reviewer TEST regression, staged LIVE activation and Owner-approved1c/4,900KRW smoke on named ordinary account; announce target and amount before charge/cancel. Verify exactly one purchase grant/ledger entry and permitted refund; do not touch existing customer orders. Until actual approval/grant success, never report LIVE_VERIFIED.

Recovery after LIVE history: PAYMENT_ENABLED=false pauses new orders/confirm while keeping DONE reconciliation and refunds. Keep dual-mode DB/handler; do not set DB back to TEST or delete/mutate historical modes. New signing key/role/schema redesign is unnecessary. Full guide is in the linked review package.
