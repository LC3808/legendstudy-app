# IAP / Store Billing — READ-ONLY Gap Analysis & Implementation Design

2026-10-07 · **DESIGN / GAP ANALYSIS ONLY — PRE-IMPLEMENTATION.** No code/DB/
migration/Production/Store-product/Toss/Payment change. Authority: Unified Wiki
(`legendstudy-docs` 00_PROJECT/CURRENT_STATUS.md) + **READ-ONLY Production DB
verification** (Supabase `stlhijzpjfgwwdgunlsd`, 2026-10-07) + APP Store RC branch
`codex/final-store-rc-1 @ 7d1c036`. Canonical backend ledger =
`legendstudy-app claude/app-release-blocker-closeout-1 @ 0b0b562` (**32 migrations**);
`origin/main` (1 migration) is NOT backend truth. Policy statements cite official
Apple/Google docs and must be re-verified against current (2026-10) rules — no guessing.

> **Payment foundation is Production-applied; IAP (Apple/Google) is not.** The Toss
> payment path + canonical Credit Ledger are **IMPLEMENTED / Production-applied /
> Toss Production TEST E2E PASS (2026-10-07: PAID → TEST_RECORDED → CONFIRM/
> SUCCEEDED), LIVE_PAYMENT_ENABLED: NO.** Apple/Google IAP is a future
> commercialization phase (near Toss approval): their provider values exist in the
> Production schema but have **no verification runtime, no client, no store
> products** — see §Production Payment Authority.

---

## 0. PRODUCTION PAYMENT AUTHORITY (READ-ONLY verified 2026-10-07)

Corrects the earlier RC-only reading. The RC closeout note "Toss/Payment writes 0"
meant *that closeout task changed nothing*, **not** that payment is absent from
Production. READ-ONLY checks against Production `stlhijzpjfgwwdgunlsd`:

**A. Applied + active in Production (canonical 32-migration ledger @ 0b0b562):**
- Tables `public.payment_orders` / `payment_operations` / `payment_events`;
  `payment_private.configuration` (mode `TEST`/`LIVE`).
- `payment_orders.provider` enum **= `('TOSS','APPLE_IAP','GOOGLE_PLAY')`**
  (verified in Production).
- Functions present: `public.payment_order`, `public.payment_support`,
  `public.payment_compensate`, `public.credit_summary`,
  `essay_private.credit_post_grant`.
- Credit ledger (`credit_accounts/grants/transactions`) live.
- **Toss Production TEST E2E PASS (2026-10-07):** PAID → TEST_RECORDED → CONFIRM/
  SUCCEEDED. **LIVE_PAYMENT_ENABLED: NO** (TEST mode only; no real money; Toss LIVE
  activation/merchant approval is a separate paid-launch gate). Payment =
  "IMPLEMENTATION COMPLETE / TEST E2E COMPLETE / LIVE OFF" (Unified Wiki).

**B. Store RC branch / origin/main only (NOT backend truth):** `tool/store-release`,
signing config, RC closeout docs. `origin/main` has 1 migration and is not the
ledger. (The payment migrations themselves ARE in Production — not RC-only.)

**C. IAP schema present but NOT runtime-activated:** `APPLE_IAP`/`GOOGLE_PLAY` are
valid provider values, but the confirm/compensate logic gates non-Toss
(`provider<>'TOSS' → PT403 PROVIDER_NOT_ENABLED`), and READ-ONLY shows **no
Apple/Google payment verification/confirm function exists** (only account-deletion's
`account_store_apple_revocation`, unrelated). No IAP client, no store products.

Toss known-good runtime is FROZEN and untouched by this analysis.

## 1. CURRENT_STATE

- **Toss payment path is Production-applied (TEST E2E PASS, LIVE OFF)** — see §0.
  Migrations `20261003000100_payment_foundation.sql` +
  `20261004000100_payment_runtime.sql` are in the Production canonical ledger.
- `payment_orders.provider` enum is **already `('TOSS','APPLE_IAP','GOOGLE_PLAY')`
  in Production**, but the confirm/compensate logic gates non-Toss: `if
  provider<>'TOSS' then raise PT403 'PROVIDER_NOT_ENABLED'`. So **Apple/Google are
  modeled but have no server verification runtime yet** — that is the core IAP gap.
- **Flutter has read-only credit only**: `lib/features/credits/credit_balance.dart`
  (`credit_summary` RPC → `CreditBalance` dto 'credit-v1'; `CreditBalanceCard`).
  **No purchase/paywall/StoreKit/Play-Billing client; no IAP deps in pubspec.**
- Commerce principle intact: 논술 = consumable Credit (packs 1/3/5/10 = 4,900/
  11,900/17,900/29,900원, +3 free on signup, paid credits expire 3 months); 내신/
  모의·수능 = period entitlement (not sold yet); ads-removal/support = separate
  entitlement. **Credit is not a universal currency.**

## 2. APP_EXISTING_AUTHORITY (reuse — do not rebuild)

- **Ledger:** `credit_accounts`, `credit_grants` (origin incl. `purchase`,
  `signup_bonus`, `promotion`, `b2b_program`), `credit_transactions`, idempotent
  `essay_private.credit_post_grant(user,qty,origin,key,reason,actor,expires)`,
  `public.credit_summary()` (shared with LAB credit-v1).
- **Payment:** `payment_orders` (subject_id, provider, mode TEST/LIVE, **sku
  server-catalog**, amount, quantity, currency, state, grant_state, provider_
  purchase_id ≤1024, grant_id→credit_grants unique, request_key; **unique(provider,
  mode,provider_purchase_id)** = duplicate-delivery guard; **unique(subject_id,
  request_key)** = idempotency), `payment_operations` (CONFIRM/CANCEL + partial-
  unique one-pending/one-confirm/one-cancel + provider_idempotency_key),
  `payment_events` (audit), `spend_guard` trigger.
- **RPCs:** `payment_order(jsonb)` (authenticated; **server derives quantity+price
  from a hardcoded catalog** `1c→1/4900, 3c→3/11900, 5c→5/17900, 10c→10/29900` —
  client never sets price/qty), Toss confirm → `credit_post_grant(origin='purchase',
  +3 months)`, `payment_support(jsonb)` (finance: inspect/cancel/reconcile +
  refund calc), `payment_compensate(jsonb)` (restricted-account refund, Toss-only).
- **Roles:** `essay_executor` (order/operation writes, definer-owned), `essay_
  finance` (support/refund). Browser/anon/service_role have no EXECUTE.

## 3. APPLE_IAP_MODEL

- **4 Consumable products** ↔ sku 1c/3c/5c/10c. StoreKit 2 (`in_app_purchase` +
  StoreKit2 backend). Flow: `payment_order(sku)` creates the order → `purchase()`
  → StoreKit returns a **JWS-signed `Transaction`** → **send to server; verify**
  via App Store Server API (`/inApps/v1/…`) or by validating the JWS signature
  against Apple root certs → new **APPLE_IAP confirm** path writes
  `provider_purchase_id = originalTransactionId`/`transactionId`, then
  `credit_post_grant(origin='purchase', +3mo)` → **`finishTransaction` only after
  the server grant succeeds.**
- **App Store Server Notifications v2** (REFUND / REVOKE / CONSUMPTION_REQUEST) →
  reconcile to the existing cancel/compensate path.
- **Consumables need no Restore** (grants are durable server-side, keyed to the
  user, shared across devices/platforms). **Disable Family Sharing** for
  consumables. transaction_id/original_transaction_id → `provider_purchase_id`
  (fits ≤1024); `unique(provider,mode,provider_purchase_id)` prevents double
  delivery. Pending/interrupted: StoreKit replays unfinished transactions on
  launch → server is idempotent.

## 4. GOOGLE_PLAY_MODEL

- **4 one-time managed (consumable) products** ↔ sku 1c/3c/5c/10c. Play Billing
  Library. Flow: `payment_order(sku)` → `launchBillingFlow` → `purchaseToken` →
  **send to server; verify** via Google Play Developer API
  (`purchases.products.get`) → new **GOOGLE_PLAY confirm** path → `credit_post_
  grant` → **`acknowledge` + `consume` only after the server grant.**
- **Real-time Developer Notifications** (Pub/Sub: SUBSCRIPTION/ONE_TIME, VOIDED) +
  `purchases.voidedpurchases` → reconcile refunds/chargebacks to cancel path.
- `purchaseToken` → `provider_purchase_id`; same uniqueness guard. Pending
  purchases (PENDING state) handled; grant only on PURCHASED+verified.

## 5. CROSS_PLATFORM_ENTITLEMENT (already solved)

Credit is **account-scoped** (`credit_accounts.user_id`) and `credit_summary` is
shared by APP + LAB. **Any provider posts to the same ledger** → scenarios A/B/C
hold with no new wallet:
- A. Web(Toss) buy → app login → same credits ✅ (already true).
- B. iPhone(IAP) buy → LAB web → same credits ✅ (after APPLE_IAP confirm posts the
  grant).
- C. Android(Play) buy → iPhone/web → same credits ✅.
**Server authority:** the provider transaction (`payment_orders`) is **separate**
from the canonical credit grant (`credit_grants`); both already modeled. Honoring
web-bought credits in the app is allowed by store policy; only the **in-app
purchase flow** must use native IAP (§14).

## 6. CREDIT_LEDGER_INTEGRATION

Reuse `credit_post_grant(origin='purchase', key='payment/'||order_id, +3 months)`
exactly as Toss does. **No new ledger, no wallet, no new grant origin.** Provider
provenance stays in `payment_orders` (+ provider_purchase_id), linked by `grant_id`.

## 7. REQUIRED_NEW_SCHEMA (minimal; prefer reuse)

`payment_orders` is already provider-ready. Likely **no new tables**. Candidate
minimal additions (design only, migration NOT written):
- Store-notification **dedup** (Apple notificationUUID / Google message id) — could
  reuse `payment_events`/`payment_operations` idempotency instead of a new table.
- **Raw-receipt retention policy** decision (store the minimum: verified
  transaction id + status; avoid long-term raw payload — a note, maybe a short-TTL
  column, not a dump).
- Per-provider server config (bundle id `com.legendstudy.app` / package name,
  issuer key ids) lives **server-only (secrets), NOT in DB/Dart defines**;
  `payment_private.configuration` already holds TEST/LIVE mode.
`provider_purchase_id` (≤1024) already fits Apple original_transaction_id and
Google purchaseToken.

## 8. REQUIRED_NEW_API / EDGE FUNCTIONS

- **Apple verifier** (server/edge): verify JWS / App Store Server API; **ASSN v2
  webhook** endpoint.
- **Google verifier** (server/edge): Play Developer API product verify;
  **RTDN Pub/Sub** consumer.
- New **APPLE_IAP / GOOGLE_PLAY confirm** server operations mirroring the Toss
  confirm (definer, `essay_executor`/gateway identity only; **never client-callable
  for the grant decision**). Client only calls `payment_order` + hands the store
  token/JWS to the server verify endpoint. Reuse `payment_support`/compensate for
  refund/revoke.

## 9. APP_CLIENT_CHANGES

- Add `in_app_purchase` (StoreKit2 + Play Billing) dependency.
- New `lib/features/purchase/` (or `commerce/`): product fetch, buy, server-verify
  handshake, finish/consume, pending replay. **Reuse** `credit_balance.dart` /
  `CreditBalanceCard` for balance; paywall lists the 4 packs + the **secondary
  coupon entry** (per [coupon design](school-history-and-coupon-design-v1.md)).
- Flow: `payment_order(sku)` → store buy → send JWS/token to server verify → on
  grant, finish/consume → `invalidate(creditBalanceProvider)`. No client-side
  credit math. No code written in this task.

## 10. STORE_CONFIGURATION

- **App Store Connect:** 4 Consumable IAPs, KRW price points, Sign-in/capabilities,
  ASSN v2 endpoint + keys, sandbox testers / TestFlight.
- **Play Console:** 4 one-time (consumable) managed products, KRW prices, Play
  Developer API service account, RTDN Pub/Sub topic, license/internal testers.
- Server secrets (Apple issuer key, Google service-account JSON) **server-only**.

## 11. PRODUCT_ID_PROPOSAL

Reverse-DNS, stable, never reused; map 1:1 to server sku:
`com.legendstudy.app.credit.1` → `1c`, `.credit.3` → `3c`, `.credit.5` → `5c`,
`.credit.10` → `10c`. The **server catalog remains the price/credit authority**;
the store product only names which sku was bought.

## 12. REFUND / REVOKE FLOW

Apple ASSN REFUND / Google voidedpurchases+RTDN → server reconcile → existing
cancel/compensate → revoke the purchase grant (the `spend_guard` + CANCEL path +
`payment_compensate` already handle Toss revoke; extend reconcile to Apple/Google
notifications). Partial consumption already computed in `payment_support`.

## 13. SECURITY / IDEMPOTENCY

- **Never grant on client-reported success**; server verifies every transaction
  with the provider.
- Replay/duplicate: `unique(provider,mode,provider_purchase_id)` + `unique(subject_
  id,request_key)` + operation idempotency keys.
- User↔transaction binding via `subject_id` (`auth.uid()`); client never sends
  user_id/amount/quantity/origin.
- Secrets server-only; raw receipt minimal retention; audit via `payment_events`.
- TEST mode (`grant_state` TEST_RECORDED, no real grant) already supports safe
  sandbox without posting credits.

## 14. STORE_POLICY_RISKS (verify against current official docs)

- **In-app purchase of digital credits must use native IAP** (Apple StoreKit /
  Google Play Billing). Cannot steer users to Toss web checkout **inside the app**
  for digital goods (anti-steering).
  [Apple IAP](https://developer.apple.com/in-app-purchase/) ·
  [Google Play Payments policy](https://support.google.com/googleplay/android-developer/answer/10281818).
- **Honoring credits purchased on the web is allowed** (multiplatform
  entitlements). The restriction is on the in-app *purchase flow*, not on consuming
  web-bought credits.
- **Korea storefront alternative billing** exists (Apple external-purchase-link
  entitlement; Google user-choice / alternative billing) **but is conditional**
  (enrollment, entitlements, disclosure sheets, commission still applies) — **not a
  simple "link to Toss."** Treat as an explicit Owner decision, not a default.
- **v1 may ship free/catalogue-only** (Essay entry gated, no in-app purchase
  steering) → IAP not required for that build; adding any in-app credit-buy flow
  triggers the IAP requirement. The RC closeout explicitly defers this. **Owner
  decides whether v1 includes purchases.**

## 15. TEST_PLAN

Apple sandbox / TestFlight; Google license testers / internal testing. Verify:
server verification (sandbox), idempotency, duplicate delivery, interrupted/pending
replay, refund/revoke reconcile, cross-platform entitlement (buy on one surface,
consume on another), TEST mode records without granting, mode=LIVE grants once.

## 16. IMPLEMENTATION_ORDER

1. Owner product/policy decisions (§18). 2. Store product config + Product IDs.
3. Server Apple verifier + APPLE_IAP confirm + ASSN webhook → Google verifier +
GOOGLE_PLAY confirm + RTDN. 4. Flutter purchase client + paywall + coupon entry.
5. Refund/reconcile. 6. Sandbox/TestFlight/internal E2E + cross-platform. 7. Store
review submission. (Apple first or Google first per Owner.)

## 17. ESTIMATED_SCOPE

**Medium.** Backend: moderate — reuse the payment/ledger core; add 2 provider
verifiers + confirm paths + 2 notification webhooks (+ refund reconcile). Client:
moderate — StoreKit2/Play-Billing + paywall. Config/Review: Owner (consoles,
pricing, keys, review). The provider-agnostic schema + server catalog + idempotency
already in place remove most of the hard design risk.

## 18. OWNER_DECISIONS_REQUIRED

1. Does v1 ship **with IAP** or **free/catalogue-only** (IAP next phase)?
2. Standard IAP vs **Korea alternative billing** (Apple external link / Google
   user-choice) — commission vs effort trade-off.
3. Exact KRW store price tiers mapping to 4,900/11,900/17,900/29,900.
4. Refund policy + raw-receipt retention duration (privacy).
5. Confirm Product IDs (§11).
6. Whether **coupon redemption** ships the same phase as IAP/paywall.
7. Apple-first or Google-first sequencing.

---

## IAP_IMPLEMENTATION_READY: **DESIGN READY — IMPLEMENTATION NOT STARTED → YES to proceed (gated)**

**Why YES to proceed:** the backend is unusually well-prepared — the payment core
is already provider-agnostic (`APPLE_IAP`/`GOOGLE_PLAY` in the enum), the canonical
credit-grant integration (`credit_post_grant`, +3mo, origin='purchase') and
cross-platform entitlement (account-scoped ledger + shared `credit_summary`) are
**already solved**, and purchase security is server-authoritative (SKU catalog,
idempotency, duplicate guards). The remaining work is bounded and additive
(provider verifiers + confirm paths + webhooks + Flutter client + store config).

**Why NOT "ready/done":** no Apple/Google verification, no IAP client, no store
products, and the RC deliberately excludes IAP. Proceed **only after** the §18
Owner decisions (especially v1-with-IAP-or-not and Korea-billing), in a dedicated
implementation phase — not in the Store RC closeout.

*Read-only analysis. No code/DB/migration/Production/Store/Toss/Payment change; not
committed. Toss known-good state FROZEN and untouched.*
