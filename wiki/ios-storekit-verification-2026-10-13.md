# iOS StoreKit / IAP — STEP 4 read-only verification (2026-10-13)

Claude, read-only review of the existing IAP implementation against the STEP 4
checklist. **No code changed.** Scope: client (`lib/features/billing`,
`lib/features/credits`) + server (`supabase/functions/verify-iap-purchase`,
RPC `iap_post_verified_purchase`). Runtime/production DB was NOT re-verified
(no DB access; Owner executes Supabase). Deployment facts below are from
`supabase/verification/iap/README.md`, not re-measured here.

## Checklist result (code-level)

| # | Item | Status (code) | Where |
|---|---|---|---|
| 1 | StoreKit product IDs ↔ Flutter mapping | PRESENT | `credit_product.dart` ↔ `core.ts products` ↔ RPC `quantity` — all four IDs identical |
| 2 | 1/3/5/10 price & type (consumable) | PRESENT | KRW 4,900/11,900/17,900/29,900 (display fallback); store price authoritative; consumable |
| 3 | purchaseStream receipt & state handling | PRESENT | `IapController.handleOne` (pending/canceled/error/purchased/restored) |
| 4 | verify-iap-purchase request/response contract | PRESENT | `SupabaseFunctionPurchaseVerifier` ↔ `core.ts handler` (granted/already_processed/pending/rejected) |
| 5 | Receipt & transaction verification | PRESENT | Apple App Store Server API `getTransactionInfo` + `SignedDataVerifier` (JWS, root certs); Google Play Developer API `purchases.products.get`. Client receipt never trusted |
| 6 | Duplicate purchase / double grant prevention | PRESENT | idempotency key = `transaction_id`; RPC `external_reference = iap/<platform>/sha256(tx)`, advisory xact lock, `already_processed` on replay; client `_processed` guard |
| 7 | cancel / error / pending handling | PRESENT | pending→open+retry; canceled/error→finish, no grant; unknown status→pending (never implicit grant) |
| 8 | unfinished-transaction recovery after app kill | PRESENT | `init()`→`restorePurchases(applicationUserName: accountId)`; server ledger is the authority (not store restore) |
| 9 | refund / revocation handling | PARTIAL | verifier reads Apple `revocationDate`→`revoked`; `core.ts` rejects revoked at purchase time. **No asynchronous refund/revocation webhook (App Store Server Notifications v2 / Play RTDN) to claw back an already-granted Credit** — see blockers |
| 10 | server Credit Ledger posting | PRESENT | `essay_private.credit_post_grant(...)` → canonical `credit_grants`/`credit_transactions`; balance re-read via `credit_summary` (credit-v1). No separate IAP/platform balance |

## Transaction-id / idempotency consistency — CONSISTENT
Client `transaction_id` (Apple JWS tx id / Google orderId) → edge `verified.transactionId`
(cross-checked `=== request.transaction_id`) → RPC `p_transaction` →
`reference = 'iap/'||platform||'/'||sha256(transaction_id)` as the unique ledger key.
Same identifier end-to-end; replay returns `already_processed`.

## accountId binding — CONSISTENT (one sandbox check needed)
Client sets `applicationUserName = Supabase auth userId` (Apple `appAccountToken`,
Google `obfuscatedExternalAccountId`). Server requires `verified.accountId === authenticated user`.
Apple token is lowercased server-side (UUID match OK). Google `obfuscatedExternalAccountId`
is compared **without** case folding — confirm in sandbox that Play echoes the UUID unchanged.

## Code-level findings
- **F1 (medium) — no async refund/revocation path.** Only synchronous revocation at
  purchase is handled. A refund after a successful grant does not claw back Credit.
  Needs App Store Server Notifications v2 + Google RTDN consumers (server work) before
  or shortly after monetization go-live. Policy decision for Owner.
- **F2 (low) — Google accountId case/charset.** Strict equality vs. Supabase UUID; verify in sandbox.
- **F3 (info) — Sandbox never grants.** By design `environment !== 'Production' → pending`.
  So a sandbox purchase exercises auth/validation/store-verify/idempotency but **stops at
  `pending` and never posts Credit**. Full grant+ledger E2E must use the `behavior.mjs`
  fixture harness (service-role RPC against an isolated migrated fixture) or a TestFlight/
  production transaction — not a plain sandbox buy.
- No client-side grant anywhere; quantity is server-derived from product id only. Good.

## Server contract & ledger status
- RPC `iap_post_verified_purchase` + Edge `verify-iap-purchase` v1 **deployed**, `verify_jwt=true`,
  SECURITY DEFINER / `search_path=''` / service_role-only (anon/authenticated denied).
  **`IAP_ENABLED` absent → gated OFF; real grants = 0** (per iap README). Paid-credit expiry
  = purchased_at + 3 months in RPC. Not re-verified against live DB here.

## Correction 2026-10-13 — App Store Connect products ARE registered
Owner directly confirmed in App Store Connect that the 4 논술 Credit products are **already
registered**, all type **Consumable (소모품)**, current status **"제출 준비 중" (Prepare for
Submission / Ready to Submit)**:
`com.legendstudy.essay.credit1/3/5/10`. **Do not create new products or change Product IDs.**
This supersedes any earlier "App Store Connect 상품 미등록" statement in this doc.
Still **UNVERIFIED by Claude** (no ASC access here; Owner to confirm): exact price tiers,
localized 표시명/설명 metadata, and the Paid Applications contract/agreement status.

## Sandbox test readiness
- Harness present: `supabase/functions/verify-iap-purchase/core_test.ts` (deno test),
  `supabase/verification/iap/behavior.mjs` (pglite fixture; role/receipt/SKU/replay/expiry/
  rollback), `postflight.sql` (read-only prod metadata + grant count).
- Product registration: **DONE** (4 consumables, 제출 준비 중 — Owner-confirmed 2026-10-13).
- **Still blocked on**: Store API credentials/secrets (below) and a sandbox tester account;
  plus price/metadata/contract-status confirmation (UNVERIFIED above). None present in this environment.

## Owner-direct setup required (needs Owner; products already registered — do not recreate)
- **App Store Connect** (products exist, 제출 준비 중): confirm each product's **price tier**,
  localized **표시명/설명**, and **Paid Applications contract** status; do NOT create new
  products or change IDs. Create an App Store Server API key (issuer id / key id / .p8 private
  key) and add a sandbox tester — **only if actually missing** (currently UNVERIFIED/likely missing).
- **Google Play Console**: same 4 consumable products; a Play Developer API service account
  (JSON); package `com.legendstudy.app`; internal-test track.
- **Supabase Edge Function secrets**: `IAP_ENABLED` (set `true` only at go-live),
  `IAP_APPLE_PRIVATE_KEY`, `IAP_APPLE_KEY_ID`, `IAP_APPLE_ISSUER_ID`, `IAP_APPLE_BUNDLE_ID`,
  `IAP_APPLE_APP_ID`, `IAP_APPLE_ENVIRONMENT`, `IAP_APPLE_ROOT_CERTIFICATES_BASE64`,
  `IAP_GOOGLE_SERVICE_ACCOUNT_JSON`, `IAP_GOOGLE_PACKAGE_ID`
  (+ existing `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`). Secrets never committed.

## Code changes that may be needed (pending Owner approval; not yet done)
- Refund/revocation consumers (F1) — server-side, separate design + Owner approval.
- Optional: normalize Google `obfuscatedExternalAccountId` comparison (F2) if sandbox shows a mismatch.
- No change needed for items 1–8, 10.

## Release blockers
- **IAP activation gated** (`IAP_ENABLED` off; 0 grants) — intentional; Owner-approved go-live only.
- **Store API credentials/secrets + sandbox tester absent** (Owner-direct). Product registration
  itself is DONE (see Correction 2026-10-13); price/metadata/contract status still UNVERIFIED.
- **No async refund/revocation handling** (F1).
- **論述 LAB GA HOLD** — monetization of a HELD service must not be exposed without Owner approval.
- **Android release build blocker (pdfium)** — see `pdfium-build-blocker-2026-10-13.md`.

## HOLD / policy
논술 LAB general availability stays HOLD. No IAP activation, production DB change, server
secret registration, or App Store Connect operational change without separate Owner approval.
