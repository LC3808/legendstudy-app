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

## 2026-10-16 — TEST purchase grant failure and ACL change blocked

Owner confirmed version2 TEST login and credit1 purchase. TEST JWT auth/user200;
empty-body verifier400; unauthenticated/invalid/foreign public anon JWT401.
Purchase verifier calls at12:50:10,12:50:42,12:51:14 KST returned503. Database errors
42501 point to iap_post_verified_purchase line22 calling credit_post_grant.
Outer function owner postgres has EXECUTE; inner owner essay_executor ACL contains
only essay_executor. postgres lacks EXECUTE; account allowed=true. Thus server
Store verification reached grant path; this is not a UI-only balance refresh issue.
IAP grants0/transactions0, balance3/reserved0. Google acknowledge/consume state is
not directly observed; app consumes only after granted/already_processed.

Owner approved TEST-only inner-function EXECUTE to postgres, preserving all other
ACLs. Direct GRANT failed42501; SET LOCAL ROLE essay_executor also failed42501.
Both transactions rolled back. Verified original ACL and function definition hash
0df3300b46a557380e30867e061594bf unchanged. Membership postgres→essay_executor is
ADMIN=true, INHERIT=false, SET=false. No Production access/change for this operation.
Additional approval needed for a transaction-scoped temporary membership SET enable
before granting, then restoring SET=false before commit. No such change executed.

Proposed exact TEST-only transaction (NOT EXECUTED; additional approval required):
```sql
BEGIN;
GRANT essay_executor TO postgres WITH SET TRUE;
SET LOCAL ROLE essay_executor;
GRANT EXECUTE ON FUNCTION essay_private.credit_post_grant(
  uuid,integer,text,text,text,text,timestamptz) TO postgres;
RESET ROLE;
GRANT essay_executor TO postgres WITH SET FALSE;
COMMIT;
```
Final expected delta: postgres function EXECUTE only; membership SET/INHERIT remain
false, ADMIN true; executor retained, anon/authenticated/PUBLIC denied. Check ACL,
function definition hash and Ledger before/after. Failed transaction must ROLLBACK.
Rollback function permission only (authorized function-owner context required):
```sql
REVOKE EXECUTE ON FUNCTION essay_private.credit_post_grant(
  uuid,integer,text,text,text,text,timestamptz) FROM postgres;
```
No replay/manual grant/additional purchase. Owner must separately approve original
purchase recovery after ACL fix; do not trigger restore/retry until then. Public HOLD.

### Oct16 TEST ACL applied after explicit temporary-SET approval

Owner confirmed app closed and approved temporary SET/restore, no purchase replay.
Approved transaction succeeded; function ACL now includes postgres=X/essay_executor
alongside original essay_executor=X/essay_executor. Function definition hash remains
0df3300b46a557380e30867e061594bf. anon/authenticated/PUBLIC EXECUTE remain false.
Postflight found GRANT had created a separate postgres-grantor membership with
INHERIT=true (original supabase_admin grant unchanged). Removed only this newly
created membership with REVOKE essay_executor FROM postgres GRANTED BY postgres.
Final membership exactly restored: only supabase_admin grant, ADMIN=true,
INHERIT=false, SET=false. Final persistent delta is target function EXECUTE only.
Ledger check12:59 KST: balance3/reserved0/IAP grants0/transactions0. No replay.
Google purchase/consume current state still requires existing transaction recovery;
previous verifier reached grant before42501, but no post-fix verification executed.
Production and Claude/main unchanged. General release HOLD.

Executable rollback (TEST only, function ACL addition only; do not run now):
```sql
BEGIN;
GRANT essay_executor TO postgres WITH SET TRUE, INHERIT FALSE;
SET LOCAL ROLE essay_executor;
REVOKE EXECUTE ON FUNCTION essay_private.credit_post_grant(
  uuid,integer,text,text,text,text,timestamptz) FROM postgres;
RESET ROLE;
REVOKE essay_executor FROM postgres GRANTED BY postgres;
COMMIT;
```
Read-only final checks must confirm original membership and original function ACL.
Next approval: existing credit1 purchase recovery only, +1 at most, dedup/consume
and restart checks; no additional purchase or manual Credit grant.


## Oct16 refunded order and purchase history tab

Owner clarified they were already on the product/top-up screen; the app had no
purchase-history tab. Previous guidance about a history screen was incorrect.
Read-only Play Console orders verified today's12:50KST credit1 test order as
**refunded / KRW0**. No order mutation or replay performed. Google documents
license-test auto-refund after3 minutes without acknowledgement:
https://developer.android.com/google/play/billing/test . The actual refund is
verified; its precise cause is not separately confirmed by an order-detail event.
TEST13:08KST: balance3, IAP grants0, IAP transactions0. Previous grant failure42501
and subsequent ACL correction are recorded above. Existing refund must not be
replayed; another test purchase requires new Owner approval.

Owner requested purchase history. Added top-up/history tabs to existing purchase
page, preserving controller lifetime and restore behavior. Existing authenticated
RLS on credit_accounts/credit_transactions is reused (owner + lifecycle guards).
Only created_at,balance_delta,reason_code are projected for purchases, newest50.
No tokens/order references exposed. Empty/error/loading/refresh states distinguish
settled Credit grants from failed/pending/refunded Google orders. Free signup
Credit is excluded. Successful purchases invalidate history and balance together.
No new DB objects, grant calls, storage or payment engine. Read-only authenticated
role query on TEST sees1 account,0 purchases,balance3. No privilege expansion.

Preservation review: (1) display existing ledger time, (2) original transactions
unchanged, (3) no UPDATE/history loss, (4) existing auth/account identity,
(5) no learning/decision/outcome conflation, (6) owner-only minimal projection,
(7) UI does not infer purchases from balance or treat store errors as grants.

Files: lib/features/billing/presentation/purchase_history.dart,
credit_purchase_page.dart, billing_providers.dart; purchase_history_test.dart and
billing_page_lifetime_test.dart. Local checks:41 relevant tests and Analyze PASS;
360px/200% widget check and tab switching/controller retention covered.
Not yet in installed versionCode2; build/upload and physical verification pending.
No new purchase/Credit/Provider/Production/Claude change. General release HOLD.


## Oct16 final read-only refund analysis / work stopped

Owner clarified the reported second purchase was the same12:50 purchase; no
separate new order identified. Play order detail directly verified (KST):
12:50:05 Order received →12:50:05 This order was processed →12:55:06 This order
was refunded. Detail does not expose refund reason, acknowledgement or consumption
flags. Purchase token was not copied/read/replayed. Actual duration5m01s must not
be rewritten as3 minutes from documentation.

Server evidence12:50–12:51: auth/user200 three times; grant RPC403; PostgreSQL
42501 at iap_post_verified_purchase line22 calling credit_post_grant; verifier503
at12:50:10,12:50:42,12:51:14. This is the first proven failure, after auth and the
Google-verification gate. Google raw response and original purchaseStream events
are not retained in the inspected logs; server calls demonstrate client delivery,
not the exact purchased/restored event subtype. Current device logs cannot recover
those original events. No new failure code after ACL fix has been observed.

Installed AAB source85e6161 controller hash matches current controller. With
pending/rejected verification, no _finish, no balance refresh; success or duplicate
success refreshes canonical balance then Google consumePurchase. autoConsume=false.
Consumption is the app's acknowledgement path. Thus grant failure prevents this
path. No independent timed retry scheduler exists here; recovery depends on store
events or entering the purchase screen (restorePurchases). A pending message is
not evidence that background retry or delivery eventually succeeded.

Most supported explanation: grant42501 → no consumption/acknowledgement → license
TEST refund. This remains a causal inference, NOT a Google reason-code finding.
Official Google test docs describe unacknowledged license-test auto-refund after
3 minutes; the console actually records5m01s. Other refund reasons cannot be
conclusively excluded without Google reason evidence.
https://developer.android.com/google/play/billing/test

Existing permission defect fixed/verified: service_role can execute public grant
RPC; its postgres definer can execute inner grant + schemaUSAGE; executor preserved,
PUBLIC/anon/authenticated denied, role options restored, definition unchanged.
Latest read-only ledger check13:22KST balance3/reserved0/IAP grants0/transactions0.
No manual grant or replay. New purchase cannot be replaced with refunded order.

Remaining acceptance gates: post-fix grant execution, exactly-once +1, Google
consume/ack success, restart balance persistence and same-token dedup in actual
E2E. These are unverified outcomes, not proven new bugs. No-purchase checks already
available: ACL/definition/RLS reads, code ordering and existing Mock tests (pending
not completed/not refreshed, success completion, duplicate behavior, completion
failure). Those tests do not prove actual Google consumption or hosted grant.

Safe next procedure requires separate Owner approval:1 credit1 TEST purchase,
no-charge always-approves test card, account test3, start from3; watch auth→verify→
grant→balance4→consume promptly; stop on error, no additional buys/manual grant;
confirm order remains processed, one grant, dedup and restart balance. Any code/DB
fix needs evidence and separate applicable approval. Today only Wiki changed;
no purchase/Provider/Credit/DB/Production/Claude changes. Public HOLD; stop work.


## Oct16 approved new TEST purchase / grant success, final checks pending

Owner approved one new credit1 TEST purchase after ACL fix, then reported purchase
complete and app charged. New Play order (distinct from refunded order):13:35:10KST,
TEST credit1, status processed. No token copied or old order replayed. Console
shows catalogue amount4900 and TEST product marker; do not equate displayed amount
with actual charge. Owner was instructed to use no-charge always-approves test card.

Server13:35:13 auth/user200 →13:35:14 grant RPC200 →verifier200 →credit_summary200.
At13:35:44KST: test3 balance4/reserved0; exactly1 IAP grant and1 IAP transaction,
purchase delta+1,reason iap_google_v1. Google verification gate passed as required
before grant in deployed verifier. This proves real TEST grant success after fix.

Not yet certified: same-token replay idempotence, explicit Google acknowledgement/
consumption state, app restart persistence. Exactly one row alone is not a duplicate
replay test; processed order alone is not proof of consumption. Owner asked to fully
restart app and enter top-up without buying, report balance4 and any completion-delay
message. No additional purchase/manual grant/Production action authorized or run.
Keep overall E2E PARTIAL until remaining evidence arrives; public HOLD.

Owner subsequently confirmed4 usable Credits after requested full restart. Server
13:37:35KST independently confirms balance4/reserved0/grants1/transactions1. Restart
persistence PASS; no extra grant observed. This does not prove same-token replay
or explicit Google consume flags. Those two final acceptance checks remain open.


## Oct16 final acceptance — Google states and duplicate grant verified

Owner authorized no-new-purchase final verification. Existing local LegendStudy
service-account credential used only for Google OAuth + orders.get and
purchases.products.get of the successful13:35 order. No token printed/persisted;
order response token was passed in memory to the product GET. No acknowledge,
consume, refund, or purchase mutation called. Google response13:43KST:
orderState=PROCESSED, purchaseState=0, acknowledgementState=1, consumptionState=1,
purchaseType=0 (license test),quantity1. No current cancellation/refund indicated.
Sources: https://developers.google.com/android-publisher/api-ref/rest/v3/orders/get
and https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products

Existing grant key confirmed as iap/google/sha256(successful orderId),not raw token.
One grant/one transaction,+1, account hash matches Google's account binding.
After inspecting deployed definer RPC, ran exactly one duplicate RPC validation in
TEST BEGIN/ROLLBACK with transaction-local service_role claim, fixed successful
order/product/purchasedAt and existing test3 account. Preconditions checked exact
existing grant key,owner,expiry,origin,balance4; abort on mismatch. RPC returned
already_processed; pre/post transaction counts and balance unchanged; rollback.
Independent postflight: grants1/transactions1/original key rows1/balance4/reserved0.
No ledger rows/schema/permissions changed. This is real deployed DB-RPC duplicate
validation, not an end-to-end HTTP replay of the raw purchase token.

Existing core_test.ts13 tests PASS without network runtime permission, including
same-request granted→already_processed contract and revoked/cancelled/account/SKU
mismatch rejection. This covers request contract locally; actual identical-token
Edge HTTP replay was intentionally not run because Google state+RPC evidence
sufficed for the approved layered validation. Do not label it HTTP replay PASS.

Final acceptance: purchase/auth/server verification/grant+1/restart balance PASS
from prior evidence; Google ACK/consume now directly PASS; duplicate grant handling
PASS at deployed RPC plus local request contract. No remaining blocker for these
specified checks; optional full HTTP replay requires actual TEST user session but
is not needed to repeat purchase or consume. General production launch remains HOLD.
No extra purchase/manual grant/Production/Claude changes. Work ends after Wiki.

## Oct18 final integration — TEST refund deployment preflight

Owner final directive: Codex sole execution authority; existing Google E2E/transactions preserved. Apple contract handled by Owner, no purchase until active agreement and product lookup. No Production DB/deploy/transactions. Existing Store money-refund authority is Apple/Google; this code only reconciles Credit after a verified store event. It does not execute the web 3-month/used-credit4900KRW cash-refund formula at the Store.

Fresh TEST kpqbedylxlyntrrfybpn metadata: public.iap_revoke_refunded_purchase(text,text,text,text,jsonb) and iap_post_verified_purchase exist, postgres SECURITY DEFINER, service_role EXECUTE true, anon/authenticated false. account_private.lock_subject(uuid) executable by postgres. iap_refund_events RLS enabled; anon/authenticated SELECT false. No RPC executed and no records modified. Last live Edge list has verifierv9 only; refund Edge absent. ASC Sandbox/Production notification URLs unset (read-only inspection). Existing refund migration must NOT be re-applied merely to deploy the Edge.

Local deno test supabase/functions/iap-refund-notifications/core_test.ts:10PASS; deno check index.ts PASS. These test handler routing/idempotent-port/error behavior, NOT actual Store signatures or hosted Credit recovery. Prior Google E2E not repeated.

Approved disabled-deployment scope (executed; verification below): deploy existing supabase/functions/iap-refund-notifications/{index,core,stores}.ts ONLY to TEST. Set IAP_REFUND_ENABLED=false. Public Store webhook requires gateway verify_jwt=false for this function alone (existing purchase verifier stays true); enabled handler authenticates Apple signed JWS/environment/bundle and Google OIDC signature/issuer/audience/service-account/package. OFF handler rejects POST503 before verifier or RPC. Do not register ASSN/RTDN URLs or enable recovery in this deployment. No migration, key rotation, purchase, refund or Ledger call. After approval: inspect deployment flag/version/JWT policy and GET405/POST503 only. Rollback: retain OFF and delete only this newly-created TEST function if required, with no DB rollback.

Later separate gate: validate TEST Apple Sandbox environment/root cert configuration and RTDN audience/service-account; configure TEST URLs/notification delivery and enable function only with explicit authorization. Real refund/recovery/reversal tests need a separately approved transaction; do not use preserved Google success purchase without permission. Existing RPC ignores unmatched purchases only after writing an audit row, so even unmatched probes are not read-only. Non-refund Apple TEST notifications are verified then ignored and do not prove Credit recovery.

### Oct18 Owner-approved disabled TEST installation — PASS

Set only TEST `IAP_REFUND_ENABLED=false`, then deployed existing `iap-refund-notifications/{index,core,stores}.ts` to `kpqbedylxlyntrrfybpn` with gateway `verify_jwt=false`. Hosted function ACTIVE v1, code hash `c8a551544895b0d20456e9c092532a6dcac805f39ca93ad7b7f71df674fce1d5`. ACTIVE denotes deployment, not refund activation. Anonymous GET returned405/rejected; empty JSON POST returned503/disabled. Handler checks OFF before Store verification or recovery RPC. No Store payload/token supplied.

Purchase verifier now reports v10 (preflight v9), `verify_jwt=true`, same code hash `f4e6aa2025aada3ed01145f639d71e1a52987e0cecb94cc21bc7fb4263f8a8a5`. Only refund function was named in deployment; do not claim the verifier version was unchanged. Project Secret update may refresh function versions; exact version-bump cause not independently audited. Purchase code and JWT policy unchanged by metadata evidence.

No DB migration/RPC execution, URL registration, activation, refund/Credit transaction, purchase or Production change. Existing local10tests/typecheck evidence retained. Actual Store notification/signature/recovery E2E remains NOT_VERIFIED and requires separate approval. Rollback remains OFF plus removal of newly installed TEST function if needed; not executed. Public HOLD.
