# In-App Purchase (Credit) Preparation — 2026-10-09

> Follow-up: [Codex integration](production-integration-2026-10-09.md) now merges this client and deploys a gated server/RPC. Historical client-only evidence below remains; server absence is superseded, real Store/refund acceptance is still pending.

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

## Device readiness & QA — 2026-10-09 (physical SM-G950N / API 28)
Real device `SM-G950N` (Android 9, 1080×2220 @ density 480 = **360dp wide**),
signed-in account (배재고등학교·2학년, 6 Credits). Debug APK installed and driven.
- **Home / Materials / LAB / MY / Essay LAB entry:** render cleanly, **no
  clipping / overflow** on the narrow old device. LAB order (논술 → 내신 →
  모의/수능) and MY 성적 order (논술 LAB top → 내신 LAB → 모의/수능 LAB) confirmed
  **on real hardware**. Balance card shows `6 Credits · 구매 0 · 가입 무료 3 · 기타 3`;
  the new **충전하기** entry renders.
- **IAP purchase screen (real device):** Play Billing client connects, but a
  **sideloaded debug APK cannot query products** (products unregistered + build
  not from a Play test track) → the screen shows the balance + a graceful
  "현재 이 기기에서는 Credit 충전을 사용할 수 없어요" state. **No crash, no overflow.**
  This is the correct behaviour — APK install is **not** real Play Billing (needs
  a Play internal-test-track build). No purchase attempted.
- **Fix applied (own code):** `IapController.init()` hardened with try/catch so any
  plugin error resolves to a deterministic `available=false` and never logs an
  unhandled async error (seen once on the sideloaded build). Re-verified: logcat
  clean, screen renders the same graceful state. `flutter test` **985 pass**.
- **Found (flagged, NOT fixed — Codex essay domain):** the **Essay LAB empty-state
  body** ("공식 문항 자료를 준비하고 있어요…") renders **edge-to-edge without the page
  horizontal padding**. Minor cosmetic; in `lib/features/essay/` (Codex-owned) —
  handed to Codex rather than edited here.
- **iOS physical:** two iPhones visible **wirelessly only, not dev-paired**; Apple
  **Development** identity + team `7P4MAL37T7`, **0 provisioning profiles**. A real-
  device install is an Owner Xcode step (below). Not performed.

## Boundary
PAYMENT_CHANGED: **NO** · TOSS_CHANGED: **NO** · Ledger/DB/Essay-runtime/Admin
grant: **unchanged** · CODEX_WORK_PRESERVED: **YES** (no merge) · Main merge:
**NO** · Store submission: **NO** · Real purchase executed: **NO** · Target 005:
**HOLD**.

## 2026-10-15 — Google TEST authentication preparation (Codex)

Latest Owner scope: independent preparation only; STOP after report. No login,
signup grant, purchase, verifier invocation, DB change or deployment performed.
Claude b97e833 was verified in its local worktree (not assumed remote); worktree
unchanged. Only its AppConfig host support selectively reused, with explicit
APP_ENV=test now requiring TEST host; other environments preserve Production-only.

Evidence and cause boundary:
- Claude config/iap-test.json metadata: APP_ENV=test, correct TEST URL and
  publishable-key format. No credential values recorded.
- Locked SDK2.15.4 already persists sessions under sb-<project-ref>-auth-token. Therefore
  cross-project restoration is NOT proven by the reported old logged-in screen.
- Prior Claude guard allowed Production URL even for APP_ENV=test: closed locally.
- Connected SM_G950N reports com.legendstudy.app0.1.0/versionCode1, installer=null,
  lastUpdate2026-10-10. This does not establish the Play internal-test binary or its
  compiled defines; no APK replacement, uninstall, data clear or session deletion.
- TEST read-only: users1/email-confirmed1/signed-in0/profiles0/accounts0/Ledger0.
  No actual TEST login yet. Profile provisioning on login is the existing path
  to the signup trigger; do not manually grant or duplicate the free3.
- Deployed TEST verifier v5 uses own SUPABASE_URL, verify_jwt=true. It calls its
  own auth/v1/user before Store verification and own grant RPC afterward. Current
  Codex Edge source is older than TEST/Claude; do not redeploy it over TEST.

Minimal local change:
- lib/core/config/app_config.dart: exact TEST/Production host selection.
- lib/core/supabase/test_session_storage.dart + lib/main.dart: TEST-only wrapper
  over existing SDK TEST key filters foreign/malformed issuer BEFORE restoration.
  It never reads/deletes Production storage and does not erase rejected records.
- billing_providers.dart/purchase_verification.dart: TEST-only issuer check and
  explicit token forwarding. Missing/foreign session stays pending without a
  verification request. Claim decoding is a routing guard, NOT authentication;
  Supabase Auth/Edge must still verify signatures and identity.
- pubspec.yaml/lock: already-resolved shared_preferences2.5.5 declared as a dev
  dependency for storage tests; no package-version upgrade.
- test/iap_test_session_test.dart + supabase_foundation_test.dart: Mock transport
  confirms TEST JWT header/target, foreign-token zero requests, original storage
  preservation, invalid issuer and production-host guard. Existing billing tests
  retain failure/cancel/retry behavior.39 related tests PASS; Flutter Analyze PASS.

Status: LOCAL PREPARATION PASS / actual JWT, Google verify, grant, deduplication,
consume and restart persistence NOT_VERIFIED. No new build installed today.
Next Owner session: verify/update Play internal-test build with these changes,
login test3@legendstudy.com on TEST (Owner controls password), verify issuer via
server and normal profile/signup balance, then request credit1 purchase approval.
License tester may use the Owner's configured Google account. Confirm test-card
label before purchase; no real-money assumption from internal track alone. Do not
replay previously cancelled orders as success. Expected3+1=4 only after actual
signup3 observation. Purchase1/dedup replay/no extra purchase must be separately
approved; recovery uses existing verifier and grant idempotency, never manual Credit.
Production and Claude/main untouched; public HOLD.

## 2026-10-16 — Signed TEST internal-track AAB prepared

Source: Codex85e6161; Claude local b97e833 read-only. Existing IAP code already
present; no source merge or new engine. Reused ignored config/iap-test.json and
android/key.properties, same existing upload keystore; no credentials committed.
Recovered the existing remote branch into /private/tmp/legendstudy-app-iap-20261016
because the prior temporary checkout was gone; protected worktrees unchanged.

- Owner-authorized Play Console read-only: com.legendstudy.app internal track active,
  versionCode1 (0.1.0), published Oct15 21:24. New artifact versionCode2/version0.1.0.
- Command: ./tool/flutterw build appbundle --release
  --dart-define-from-file=config/iap-test.json --build-number=2
- Artifact: /private/tmp/legendstudy-app-iap-20261016/build/app/outputs/bundle/release/app-release.aab
- Size:76,516,984 bytes. SHA256:66fd122b1f757f4f3b9341cdbeb335afedff301983d6b6383bd2ff2d06f9dda1.
- jarsigner verified; certificate matches existing upload keystore:
  C0:0F:42:60:D5:B9:5A:08:43:35:57:6C:03:BF:36:B8:91:4A:2F:33:CB:3D:A7:01:40:3E:0A:DB:AC:FB:8E:F1.
- Release merged Manifest package/version/BILLING PASS; packaged AAB contains BILLING.
  All3 libapp.so architectures contain the configured TEST URL and TEST publishable key.
  APP_ENV=test config verified; Production host constant remains for the routing guard,
  not an active Production connection. Actual device login/JWT is still NOT_VERIFIED.
- Flutter Analyze PASS;39 related authentication/config/billing/lifetime tests PASS.
  PDFium chromium7811 download reset: reused identical cached binaries from Claude
  read-only. Test-generated plugin registration required normal pub regeneration;
  final signed release build PASS. Existing Gradle/AGP/Kotlin/font warnings remain.
- Four existing credit1/3/5/10 products retained. No Ledger, verifier, DB or UX change.

Build preparation PASS; upload acceptance/device TEST authentication/purchase E2E
pending. Next: Owner approves uploading this exact AAB to internal testing; no purchase
included. Then install via Play, verify TEST login/balance, request separate credit1
purchase approval. No upload, purchase, Credit grant, Provider call, Production change
or Claude/main write performed. General release HOLD.

### Oct16 upload-only approval executed

Owner approved internal-track AAB upload only. Rechecked exact SHA256 above,
selected the signed artifact in existing LegendStudy Play Console (com.legendstudy.app).
Play processed it successfully and displayed version2(0.1.0), API24+, target36,
3 ABIs. Saved internal release2 as draft; Console confirmed changes saved.
Release notes identify TEST authentication isolation/verification preparation.
No rollout/publish action: currently available tester release remains1.
No purchase/grant/DB/Production change. Next gate is internal tester rollout approval,
then device TEST authentication; purchase remains separately gated.
