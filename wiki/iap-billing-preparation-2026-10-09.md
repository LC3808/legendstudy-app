# In-App Purchase (Credit) Preparation — 2026-10-09

**IAP_PREPARATION: PARTIAL** — the Flutter client (Apple IAP + Google Play
Billing adapter, product catalog, purchase UI, server-verification contract,
pending/failure/recovery) is **implemented, compiling and unit-tested**. End-to-
end is **BLOCKED** on three Owner/Codex gates: the server verification endpoint
(IAP verification is future work in the payment foundation), Store Console
product registration, and sandbox credentials.

Independent branch `claude/iap-billing-preparation` off the Claude RC
`e50e072`. **No Codex code touched**; `codex/essay-web-runtime` and
`codex/integrated-account-data` preserved (no merge). No Payment/Toss/Ledger/DB
change. Target 005 HOLD.

## Architecture (reuses approved commerce policy — nothing redesigned)
- Web = Toss (**unchanged**); iOS = Apple IAP; Android = Google Play Billing.
- Credit is a **consumable** product (Apple Consumable / Play consumable one-time)
  — never a subscription.
- **The app never grants Credit.** A store "purchased" event is submitted for
  **server verification + idempotent ledger grant** (provider `APPLE_IAP` /
  `GOOGLE_PLAY`), then the balance is re-read from the existing
  `credit_summary` RPC (`credit-v1`). Store "restore" is **not** used to rebuild
  a balance — the server ledger is the single authority.

## Products (Owner-approved economics; 20-Credit excluded this release)
| Product | Credits | Approved KRW | Proposed product id |
|---|---|---|---|
| 1 Credit | 1 | 4,900 | `com.legendstudy.essay.credit1` |
| 3 Credits | 3 | 11,900 | `com.legendstudy.essay.credit3` |
| 5 Credits | 5 | 17,900 | `com.legendstudy.essay.credit5` |
| 10 Credits | 10 | 29,900 | `com.legendstudy.essay.credit10` |

- Prices are **display fallbacks**; the store returns the authoritative localized
  price at runtime (shown on the card). 1 Credit = one first review + one
  re-review of the same answer (14-day window). Signup free 3 Credits and the
  paid-Credit 3-month expiry are **server policy — unchanged**; the app only
  displays the `credit_summary` breakdown (구매/가입 무료/기타 + nearest expiry).
- Product IDs are **proposed candidates** — confirm/avoid duplicates against the
  Store Consoles before finalizing.

## Flutter implementation (this branch)
- `lib/features/billing/credit_product.dart` — catalog + id↔credits mapping + KRW
  format (pure, tested).
- `lib/features/billing/purchase_verification.dart` — `PurchaseVerifier` interface,
  `VerificationOutcome` (granted/already_processed/pending/rejected; unknown →
  **pending**, never an implicit grant), `IapVerificationRequest`, and the default
  `SupabaseFunctionPurchaseVerifier` (Edge Function `verify-iap-purchase`).
- `lib/features/billing/iap_controller.dart` — `in_app_purchase` wiring
  (isAvailable, queryProductDetails, buyConsumable, purchaseStream,
  completePurchase) + a **testable `handleOne`** decision core.
- `lib/features/billing/billing_providers.dart` — Riverpod providers; after a
  settled purchase it invalidates `creditBalanceProvider` (re-reads the ledger).
- `lib/features/billing/presentation/credit_purchase_page.dart` — product cards
  (store price, 답안 summary), phase states, guest + unavailable guards. Reached
  from the LAB balance card "충전하기" → route `/lab/credits`.
- `pubspec.yaml` — `in_app_purchase: ^3.2.0` (resolved 3.3.1). The
  `com.android.vending.BILLING` permission is **auto-merged** by the plugin — the
  Codex-owned `AndroidManifest.xml` is **not edited**.

## Server verification contract (CODEX — endpoint does not exist yet)
IAP verification/grant is future work in `payment-app-foundation.md` ("IAP
API/verification remains future work"; the native app "exposes no external
purchase CTA"). The client calls:

```
POST (Edge Function) verify-iap-purchase
request : { platform: 'apple'|'google', product_id, transaction_id, verification_data }
response: { status: 'granted'|'already_processed'|'pending'|'rejected', spendable? }
```
Server (Codex) must: verify `verification_data` with the Apple App Store Server
API / Google Play Developer API; map `product_id → credits`; **idempotently**
post to the canonical ledger keyed by `transaction_id` with provider
`APPLE_IAP`/`GOOGLE_PLAY`; handle refund/revocation; return the new spendable.
Secrets stay server-side. Codex may instead expose this as
`rpc('payment_redeem_iap', …)` — only `SupabaseFunctionPurchaseVerifier` changes.

## Credit grant & idempotency
- Grant only after `granted`/`already_processed`; then re-read `credit_summary`.
- Dedupe: the client guards a per-session processed-transaction set **on top of**
  the server's authoritative idempotency (keyed by `transaction_id`), so app
  restarts / duplicate stream events / already-processed transactions never
  double-grant.
- The store transaction is completed **only after** the server settles it; a
  `pending` verification leaves it open for store re-delivery/retry.

## Failure / recovery (implemented client-side, unit-tested)
cancel → idle · error → cleared, surfaced · pending verification → "충전이 지연"
pending (not completed, not granted) · network/server delay → pending · app
relaunch / duplicate event → single grant · refund/revocation → server `rejected`
(client clears, no grant). The app never shows a Credit it did not get from the
ledger.

## Store console setup — checklist
**Apple App Store Connect** (Owner, needs paid membership): In-App Purchases →
create 4 **Consumable** products with the ids above → price tier ≈ approved KRW →
localized display name + description → review screenshot → **Sandbox tester** in
Users and Access. Add the In-App Purchase capability (StoreKit) to the app record.
**Google Play Console** (Owner): Monetize → Products → **In-app products** (one-
time) → create the 4 ids → price → **Activate** → add **License testers** and a
**closed/internal test track** build for Billing testing.

## Sandbox / test plan
Unit contract tests run now (below). **Real** sandbox purchases are **BLOCKED**
until: products are registered + active, the `verify-iap-purchase` endpoint
exists, a signed test build is on a test track (Android) / TestFlight-or-dev build
with a Sandbox Apple ID (iOS). No mock purchase is reported as a real success.

## Verification (this branch)
`flutter analyze`: **No issues.** `flutter test`: **984 passed, 2 skipped**
(15 new billing tests: catalog/mapping, verification-outcome mapping,
`handleOne` — granted/pending/rejected/duplicate/unknown-product/missing-tx/
canceled/error/platform). Android debug APK **PASS** (Billing permission merged);
iOS simulator build **PASS**.

## Remaining blockers
1. **Server `verify-iap-purchase` endpoint** (Codex) — Apple/Google verification
   + idempotent ledger grant.
2. **Store Console** product registration + activation (Owner).
3. **Sandbox credentials / test tracks** (Owner).
4. **Signing** (from the store-release-prep doc) for test-track / TestFlight builds.
5. **Payment-compliance decision** already flagged — IAP (this work) is the
   compliant path for in-app Credit; keep the web Toss path separate and do not
   steer in-app users to it.

## Codex integration handoff
- Implement `verify-iap-purchase` to the contract above against the **existing**
  ledger (do not create a new ledger); keep `credit_summary` as the read.
- Confirm/register the product ids; if different, update `credit_product.dart`
  (the only client mapping).
- Cross-platform entitlement: Web/iOS/Android share one `credit_summary`; this
  client already re-reads it after purchase, so balances stay consistent.

## Boundary
PAYMENT_CHANGED: **NO** · TOSS_CHANGED: **NO** · Ledger/DB/Essay-runtime/Admin
grant: **unchanged** · CODEX_WORK_PRESERVED: **YES** (no merge) · Main merge:
**NO** · Store submission: **NO** · Real purchase executed: **NO** · Target 005:
**HOLD**.
