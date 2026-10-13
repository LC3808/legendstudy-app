# IAP Sandbox E2E + async refund — design & code-impact (2026-10-13)

STEP 4 follow-up. **Design and impact analysis only — no code changed, no DB change,
no IAP activation, no push.** Reuses the existing Credit Ledger and `verify-iap-purchase`;
does not duplicate the ledger or create a separate balance. Implementation proceeds only on
Owner approval. Common server pieces are designed here (STEP 6) without duplicate builds.

## A. Current ledger model (verified, reused as-is)
- `credit_grants` (one row / grant: account_id, origin, `external_reference`, expires_at).
- `credit_transactions` (grant_id, transaction_type, balance_delta, reserved_delta, decision_id,
  idempotency_key, reason_code, actor_reference). Types: purchase/signup_bonus/promotion/
  admin_grant/compensation/b2b_program/**refund** (balance_delta>0); reserve/consume/release/
  expiration/**adjustment** (adjustment: balance_delta<>0, reserved_delta=0).
- **Consumption is per-grant**: reserve/consume carry `grant_id`; essay spend reserves from the
  oldest eligible grant (FIFO by expiry). A grant's **remaining unspent** =
  `sum(balance_delta - reserved_delta) WHERE grant_id = g`.
- IAP purchase grant key: `external_reference = 'iap/'||platform||'/'||sha256(transaction_id)`.
- Note: the existing positive `refund` type is **essay re-review domain (Codex)** — store-refund
  clawback must NOT reuse it. Clawback uses negative `adjustment` instead.

## B. Sandbox E2E design
**Goal**: prove client → edge → verify → grant → `credit_summary` balance in Sandbox, while
Production still never grants on Sandbox.

**Isolation model (no duplicate ledger):** run the E2E against a **separate, isolated Supabase
environment** (dedicated test project / branch / local `supabase start`) with the **same
canonical migrations** applied — same RPC and ledger contract, a *different database*. Production
is untouched. No ledger copy, no second balance system.

**Minimal gated code change** (today `core.ts`: `environment !== 'Production' → pending`):
add env flag **`IAP_ALLOW_SANDBOX_GRANT`** (default absent/false). Grant proceeds on a Sandbox
transaction **only when the flag is true**, which is set **only in the isolated test project**.
Production never sets it → Sandbox stays `pending`. Request/response contract is unchanged.

Sub-item coverage:
1. Apple Sandbox verify — `stores.ts` with `IAP_APPLE_ENVIRONMENT=Sandbox`, SignedDataVerifier (sandbox).
2. Sandbox↔Production isolation — separate project/DB + flag default-off; edge accepts only its own environment.
3. Test Credit grant — same `iap_post_verified_purchase` into the test ledger.
4. Balance/history — `credit_summary` (credit-v1) + `credit_transactions` in the test project.
5. Idempotency — unchanged `transaction_id`→`sha256` reference; replay → `already_processed`.
6. App-kill recovery — `restorePurchases(applicationUserName=accountId)` + server ledger authority.
7. Account isolation — test auth users live only in the test project; service_role-only RPC; RLS unchanged.
8. Traceability — `postflight.sql` (read-only), `behavior.mjs` assertions, credit_transactions audit, a test-run log doc.

**Zero-code interim (optional):** without the flag, a real Sandbox buy still exercises
auth/validation/store-verify (stops at `pending`), and grant+idempotency+ledger are proven via the
`behavior.mjs` service-role fixture. Full continuous sandbox E2E needs the flag (above).

## C. Async refund / revocation design (F1)
Store-payment refund (Apple/Google returns money) is handled by the stores; **server Credit
recovery is a separate flow** that removes only **unspent** Credit from the refunded grant.
Toss/Web refund policy is untouched. Ledger stays append-only (compensating entries, never edits).

- **Apple**: App Store Server Notifications V2 — Apple POSTs a signed JWS; types REFUND / REVOKE
  (and REFUND_REVERSED). Verify with the same `SignedDataVerifier` + Apple root certs. Identify the
  original transaction (transactionId / originalTransactionId).
- **Google**: Real-time Developer Notifications (Pub/Sub) voidedPurchase + reconcile via
  `purchases.voidedpurchases.list`. Verify the Pub/Sub push OIDC token; re-confirm via the service
  account. Identify by orderId.
- **Original-transaction mapping**: notification tx/orderId → `reference = iap/<platform>/sha256(tx)`
  → the `credit_grants` row.
- **Idempotency**: notifications redeliver — key recovery by `(reference, notification_uuid, type)`
  in a new `iap_refund_events` table; repeats are no-ops.
- **Unused-credit recovery**: new service-role RPC `iap_revoke_refunded_purchase(reference, …)` posts
  one negative `adjustment` = `-min(granted_qty, remaining_unspent_of_that_grant)`, reserved_delta=0,
  reason_code `iap_refund_<platform>`. Clamped ≥ the grant's own remaining → never negative, never
  touches consumed/reserved units, FIFO-safe, account spendable stays ≥ 0.
- **Already-used exception**: if `remaining < granted_qty`, the consumed difference cannot be clawed
  back; recover only `remaining` and record a shortfall in the audit log for Owner policy.
- **Refund-reversal/correction**: Apple REFUND_REVERSED / a revalidated Google purchase → a
  compensating positive `adjustment` restoring the previously recovered units, keyed idempotently.
- **Delivery-failure reprocessing**: Apple `getNotificationHistory` backfill + a scheduled Google
  Voided Purchases reconciliation sweep, both idempotent (same event key).
- **Audit/retention**: `iap_refund_events` (immutable append) + the adjustment transactions are the
  audit trail. credit_transactions remains append-only.

**Codex alignment needed**: clawback only appends `adjustment` on a purchase grant and never alters
consume/reserve logic or the essay-domain positive `refund`. Confirm with Codex that a negative
adjustment on a purchase grant does not interfere with re-review eligibility (which keys off
`decision_id` refunds, a different grant/semantics).

## D. Existing-code reuse scope
Reused unchanged: credit_grants/credit_transactions, `credit_summary`, `iap_post_verified_purchase`,
`verify-iap-purchase` (core.ts/stores.ts), `@apple/app-store-server-library`, Google service-account
verify, `reference`/sha256 idempotency scheme, service-role SECURITY DEFINER pattern, `behavior.mjs`
fixture, bounded-body/validation patterns. New only: one gated env flag; refund Edge handler(s);
one additive recovery RPC + `iap_refund_events` idempotency/audit table (uses existing `adjustment`
type — **no transaction-type/constraint migration**).

## E. Files that would actually change (proposed; not done)
Sandbox E2E (small, Claude-owned IAP edge):
- `supabase/functions/verify-iap-purchase/core.ts` (+ `index.ts`) — gated `IAP_ALLOW_SANDBOX_GRANT`.
- `supabase/functions/verify-iap-purchase/core_test.ts` / `supabase/verification/iap/behavior.mjs` — sandbox-grant + isolation cases.
Refund (larger; needs Owner approval + Owner-applied DB):
- NEW `supabase/functions/iap-refund-notifications/` (Apple ASSN v2 + Google RTDN).
- NEW migration `supabase/migrations/<ts>_iap_refund_recovery.sql` — `iap_revoke_refunded_purchase`
  RPC + `iap_refund_events` table (additive; service_role-only).
- NEW tests under `supabase/verification/iap/`.
- No Flutter client change required (server-side; client re-reads `credit_summary`). Optional UI copy only.

## F. Test plan
- Unit: core sandbox-grant branch; RPC fixture (grant/idempotency/refund recovery/used-credit clamp/reversal/reconcile) in `behavior.mjs`, all rolled back, isolated DB only.
- Integration (isolated test project): real Apple Sandbox buy → grant → balance; app-kill recovery; replay idempotency; account isolation.
- Refund: simulated ASSN v2 REFUND/REVOKE + Google voided → recovery; redelivery idempotency; used-credit clamp; reversal re-grant; reconciliation sweep; audit assertions.
- Read-only `postflight.sql` metadata/grant-count checks. Nothing against a live DB.

## G. Security / operational risks
- `IAP_ALLOW_SANDBOX_GRANT` true in Production ⇒ free Credit. Must be default-off, **test-project-only**,
  documented, and alarmed; hard isolation = separate project/DB.
- Refund webhooks are public endpoints: strict JWS/OIDC verification, reject unauthenticated, bounded
  body, idempotent, rate-limited (reuse core.ts hardening).
- Clawback must clamp ≥0 and never touch consumed credit; disputes on already-spent credit → Owner policy.
- Secrets (Apple .p8, Google SA JSON, Apple root certs) only in Edge secrets — never in code/Wiki.
- Reconciliation must be idempotent to avoid double recovery/double grant.

## H. Owner — App Store Connect checklist (do NOT paste key/cert contents anywhere)
1. **In-App Purchases** → create 4 **Consumable** products:
   - `com.legendstudy.essay.credit1` — 표시명 "논술 Credit 1개", KRW 4,900 tier, 설명 "논술 답안 1개 첨삭(답안당 재첨삭 1회 포함)".
   - `com.legendstudy.essay.credit3` — "논술 Credit 3개", KRW 11,900.
   - `com.legendstudy.essay.credit5` — "논술 Credit 5개", KRW 17,900.
   - `com.legendstudy.essay.credit10` — "논술 Credit 10개", KRW 29,900.
   - Each: Cleared for Sale, review screenshot + review notes, localized 표시명/설명.
2. **App information**: Bundle ID `com.legendstudy.app`; note the numeric **App ID** (Apple ID) for `IAP_APPLE_APP_ID`.
3. **App Store Server API key** (Users and Access → Integrations → In-App Purchase): create key → record **Key ID**, **Issuer ID**, download the **.p8** (store securely; load into the Edge secret `IAP_APPLE_PRIVATE_KEY`; never commit).
4. **Apple root certificates** (AppleRootCA-G3 chain) base64 → Edge secret `IAP_APPLE_ROOT_CERTIFICATES_BASE64`.
5. **Sandbox tester**(s): Users and Access → Sandbox → add test Apple IDs.
6. **App Store Server Notifications V2 URL** (Production + Sandbox) → the deployed refund Edge Function URL.
7. Confirm `IAP_APPLE_ENVIRONMENT` (Production vs Sandbox) per environment; set `IAP_ENABLED=true` only at go-live; `IAP_ALLOW_SANDBOX_GRANT=true` only in the isolated test project.
(Google Play / RTDN / Pub/Sub + service account is STEP 5; noted for planning.)

## I. Approval needed before implementation
1. Approve the gated `IAP_ALLOW_SANDBOX_GRANT` edge change (contract unchanged, Claude-owned).
2. Provision an isolated test Supabase environment (new project / branch / local) with canonical migrations.
3. Approve the refund design → then the additive migration (Owner-applied) + new refund Edge Function.
4. Confirm the Codex consume/grant model alignment (negative `adjustment` vs essay `refund`).
5. Decide the already-used-credit shortfall policy.
6. Store product registration + secrets (Owner-direct, section H).

HOLD/policy unchanged: 논술 LAB GA HOLD; no production DB change, IAP activation, secret registration,
store operational change, or push without separate Owner approval.
