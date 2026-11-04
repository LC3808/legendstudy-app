# WEB Toss LIVE + fixed reviewer TEST — 2026-11-04

Status: IMPLEMENTED candidate / isolated TEST_VERIFIED; Production prepare APPLIED (20261104021443), activation APPLIED; PRODUCTION_ACTIVE YES; LIVE_VERIFIED NO.

Owner approved WEB LIVE activation; review@ remains TEST. Unexpected DB changes must be reported first. Existing payment_order selects one global mode; payment_process rejects any order of another mode. Therefore Cloudflare-only activation cannot satisfy the requested coexistence.

## Minimal reviewed DB change

[prepare.sql](prepare.sql) adds one private, non-browser executable helper `payment_private.current_order_mode()` and replaces only mode selection/eligibility expressions in existing `payment_order` and `payment_process`. The helper uses current Auth UID plus current auth.users email and confirmed timestamp; fixed reviewer UUID `ddc5ae63-acbb-490b-a423-c996b811dea8`. A changed email or recreated account does not inherit TEST. Browser-supplied mode/email are rejected by existing exact RPC fields. Function hashes, confirmed reviewer, initial TEST configuration and role/schema topology are prerequisites; drift aborts the transaction. Existing owners/ACL are restored and checked.

No Order/Payment/Credit/Ledger schema or row changes. Existing TEST creation remains until separately applying [activate.sql](activate.sql). Activation changes only private configuration TEST→LIVE. Under LIVE, both stored modes can be reconciled; old orders never change mode. Existing grant/cancel code, quantity/price/expiry, one-grant and operation uniqueness stay intact.

## Execution and recovery

1. Owner reviews prepare.sql; apply in Production only after explicit DB approval. Verify helper private ACL and configuration still TEST; compare baseline order/ledger row hashes.
2. Confirm merchant LIVE/card/domain approval, both LIVE keys and existing TEST keys. Renew expired Finance JWT through the existing signer and subject without changing signing keys/roles. Values never enter Git/log/chat.
3. Build against the actual current deployment and preserve unrelated functions/assets. Deploy adapter while REVIEW remains configured. Run reviewer TEST regression.
4. Pause new purchases with PAYMENT_ENABLED=false. Apply activate.sql and set Cloudflare PAYMENT_MODE=LIVE with fixed PAYMENT_REVIEW_SUBJECTS UUID. Validate account routing, keys and stored-order recovery, then enable purchases.
5. Owner-approved 1c/4,900 KRW LIVE smoke on the named ordinary account. Announce account/amount before actual charge or cancellation. Verify Toss DONE, exactly one purchase grant/ledger linkage; do not use an existing customer transaction.
6. Kill switch: PAYMENT_ENABLED=false prevents new orders/provider confirms but keeps DONE reconciliation/refunds. Keep DB mode LIVE after any LIVE order exists; reverting it to TEST would strand LIVE recovery. Do not delete orders or reverse grants manually. Retain deployed dual-mode handler for history recovery.

## Evidence and open gates

Production read-only: configuration TEST;18 TEST orders (9 PAID/TEST_RECORDED,9 ORDER_CREATED),TEST grants0,LIVE0. Confirmed reviewer UID verified. Current Cloudflare deployment `1e842209-74a6-478c-846c-ebea8779fcf4`, source metadata `0e735c6fbf74d3351cbb8eca9915b1c650c37251`; mode REVIEW/enabled true. TEST keys/Finance registered; LIVE keys and PAYMENT_SUPPORT_SUBJECTS absent at initial audit. Existing support-cancel API therefore needs an explicitly authorized operator allowlist before operational refund acceptance. The current source was located in /tmp/legendstudy-feedback-web-20261104 and integrated; preserve other API inputs and unrelated static assets.

Local WEB1563 tests PASS (4 skipped), final admin/payment201 tests PASS; typecheck/build/lint PASS. Disposable PostgreSQL runs existing payment and Math regressions and added21 checks in [validation.json](validation.json): fixed identity, email changes, recreated email, TEST+0, LIVE3 grant once, duplicate confirmations/cancellations, legacy TEST recovery, private ACL, historical order preservation. No remote provider calls or Production DB writes. Run `python tool/test_payment_live_activation.py --pg-bin /opt/homebrew/opt/postgresql@17/bin` with psycopg installed. Local Auth shim is not hosted Auth E2E.

Admin UI already distinguishes mode per transaction and TEST amounts are explicitly not revenue. Existing analytics parser requires LIVE/KRW. Production admin_payment_orders still has a historical hard-coded LIVE_OFF runtime label. The WEB candidate now reads the actual payment runtime for status and labels historical mode as recorded order environment; per-order TEST/LIVE reporting stays unchanged.

Prepared SQL approved/applied with unchanged row hashes; LIVE keys now registered. Missing: merchant approval, runtime key validation, Finance runtime validity/renewal, hosted TEST regression, approved LIVE charge/refund E2E. No new APP path, StoreKit/Play change, bonus/beta policy change, or student data mutation.

## Seven preservation answers

1. Payment/order/provider/operation facts retain original timestamps and existing events.
2. Existing immutable order price/quantity/mode and provider linkage reproduce facts.
3. No historical mode rewrite/backfill; only future selection policy changes.
4. Existing Auth UID is authority; email alone cannot transfer TEST privileges.
5. Financial transactions remain separate from learning/decision/outcome records.
6. No new buyer data collection; private Auth lookup only, no raw key/token logging.
7. Revenue derives from LIVE orders only; TEST amounts never become revenue facts.

Current hosted activation/TEST evidence: [activation-validation.json](activation-validation.json). LIVE charge/refund acceptance still pending Owner admin login; preparation-gate descriptions above are historical.
