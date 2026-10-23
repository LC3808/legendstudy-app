# IAP Production recovery — investigation and local implementation

> Latest: Owner-approved v23 is deployed; iOS existing 1+3 Credit recovered and Ledger verified. Earlier READ-ONLY/HOLD notes below are historical. Android real-purchase E2E awaits a non-license-test account.

Current: Android two existing orders are refunded TEST purchases (API-verified); historical12:31 rejection reason unresolved. Package now matches. Apple WebCrypto draft and diagnostics locally verified; Production unchanged by this agent. Latest checkpoint at end supersedes earlier observations.

## Initial PHASE1 checkpoint

2026-10-23 KST. Owner authorized Production READ-ONLY investigation in
`/Users/woojinchang/development/legendstudy-iap-fix`, branch
`codex/iap-credit-production-recovery-20261023`. Both verified; initial tree clean.
No correction-backend folder accessed for edits. No code, DB, secrets, deployment,
purchase, Store transaction, grant, refund or verification RPC mutation performed.
Only this checkout's Wiki handoff was edited.

## Authority and scope

Restore sources: AGENTS, index, current-status, decisions, product-scope,
[payment foundation](payment-app-foundation.md),
[Production integration](production-integration-2026-10-09.md),
[IAP history](iap-billing-preparation-2026-10-09.md), and existing IAP acceptance SQL.
The exact earlier Owner PHASE 1 directive is not present in these repository
sources; this checkpoint covers the explicitly authorized read-only investigation,
not certification that every item in that unseen directive is complete.
Existing G1 ledger and Production Sandbox denial policies remain unchanged.

## Fresh Production evidence

Connected project list confirms LegendStudy `stlhijzpjfgwwdgunlsd`, ACTIVE_HEALTHY.
No other project's DB queried. SQL catalog/count queries used BEGIN READ ONLY.
DB aggregate observed at 2026-10-23 02:10:52 UTC (11:10:52 KST).

- `verify-iap-purchase`: ACTIVE v17, verify_jwt=true, bundle SHA256
  `fa196847ce5f190d8d282ff0d95da1a7a734ddec0422f5de1d5a3f519de6b19e`.
- Deployed source retrieved through get_edge_function. Production URL hardcoded;
  fresh Auth user check, Store verification, account/SKU/transaction checks,
  Sandbox → pending before grant, service-only RPC preserved.
- Deployed code differs from this checkout: deployed PEM normalization and
  IAP_VERIFY_FAIL diagnostic logging are absent locally; local isolated-Sandbox
  gate and dynamic project URL are absent in deployed source. Do not redeploy
  local code blindly or infer running code from Git.
- `iap_post_verified_purchase`: postgres owner, SECURITY DEFINER, empty search_path,
  body MD5 `c216866a95254f1ce3206db9737d38c2`; service_role execute true,
  anon/authenticated false. Same hash as Oct09 historical evidence.
- Inner `essay_private.credit_post_grant`: essay_executor owner, postgres execute
  true, service_role/anon/authenticated false. postgres has schema USAGE and
  EXECUTE on account_private.lock_subject/allowed. Thus the historical TEST inner
  grant permission defect is not established as a current Production defect.
- IAP grants0, all purchase-origin grants0, IAP reason transactions0.
  credit_accounts/credit_grants/credit_transactions RLS all enabled.
- Migration ledger contains payment_foundation 20261003000100,
  payment_runtime 20261004000100, iap_verified_credit 20261009000200.
  Payment RPCs and credit_summary actually exist. Prior NOT_APPLIED payment
  statements describe historical checkpoints, not current DB installation.
  This says nothing about Toss LIVE activation.
- Refund migration20261016120000 absent; public refund RPC and refund event table
  absent; refund Edge absent from live function list. TEST refund deployment
  evidence must not be promoted to Production.

## Existing logs, no transaction replay

Explicit window: 2026-10-22 11:10 through 2026-10-23 11:10 KST.
Function gateway aggregates:21 requests, all503; versions5(2),7(4),10(1),11(2),
12(2),14(4),16(2),17(4).
Diagnostic aggregates:14 IAP_VERIFY_FAIL entries, UNCONFIGURED2 (bothv17),
Error12 (v11:2,v12:2,v14:4,v16:2,v17:2). No numeric Apple HTTP/API error extracted.
Only aggregate diagnostics were projected; no receipt/token/user identifiers.

The deployed env helper emits UNCONFIGURED for a missing/empty required value.
This proves two v17 configuration failures occurred; it does not identify which
variable or show whether it is still missing now. Generic Error lacks the cause.
Sandbox policy returns pending200 after successful verification, so Sandbox denial
alone does not explain these503 responses. Runtime activation and secret values
were not retrieved. No unsupported Apple401/key diagnosis is made.

Client source completes/consumes only after granted/already_processed, keeps pending
open and depends on purchase events/restore for retry. Existing source inspection
is not device acceptance or proof that a particular order was acknowledged.

## Remaining investigation / next boundary

PHASE1 PARTIAL: current inventory and failure classification established; specific
failing secret/Store stage, present activation values, affected transaction's Store
state and the exact earlier directive remain unresolved. Next read-only work should
identify missing setting names without exposing values and recover narrower error
context from existing records; do not replay a purchase to manufacture evidence.
No fix, secret rotation, Sandbox policy change, refund deployment, manual credit,
purchase or PHASE2 execution is authorized by this checkpoint. Original financial
and learning history remains untouched.


## Owner six-incident investigation — 2026-10-23 follow-up

Owner now explicitly scopes signup3, missing Credit account, Android/iOS paid
purchase, Admin Credit lookup and Admin school display. PHASE2 follows report;
no implementation or Production mutation in this phase. All writes remain inside
legendstudy-iap-fix. Other checkouts were inspected read-only as evidence.

### Authority restored

- Unified docs remote main `e7fe78f40e4b2d4de876e0546c46c1afcde13597` verified via
  ls-remote and GitHub contents; its payment/IAP sections retain dated Oct18 history.
- Active service docs branch `codex/material-service-docs-20261022` remote/local
  `c0c1da5e246680494d9bb91c650dbc81817c5f57` has newer Oct23 service Authority.
  AI_CONTEXT, CURRENT_STATUS, SOURCE_OF_TRUTH and Oct21 North Star inspected.
  Preserve existing Essay engines, server-authoritative Ledger and actual E2E evidence.
  These docs were not edited or checked out by this task.
- Claude [Oct07 gap analysis](https://github.com/LC3808/legendstudy-app/blob/e4b225572a9b876b44107d847c00772304166905/wiki/iap-store-billing-gap-analysis-v1.md),
  local [Oct09 integration handoff](iap-billing-preparation-2026-10-09.md#codex-integration-handoff),
  Oct18 release/TEST history read. Early design proposals are superseded by actual
  implemented IAP wrapper; do not rebuild Toss or adopt historical proposed SKU IDs.
- [Grok Oct12 review](https://github.com/LC3808/legendstudy-docs/blob/e7fe78f40e4b2d4de876e0546c46c1afcde13597/90_HISTORY/REVIEWS/2026-10-12-grok-code-review.md)
  read: APP#9/LAB#1, Essay branch integration and server balance boundaries; not
  a diagnosis of the Oct22 purchase failure. Separate newer IAP handoff/review
  was requested from Owner if available; it has not yet been identified.

### Findings and smallest candidate changes

| Incident | Verified facts / confidence | Minimum scope / remaining proof |
|---|---|---|
| 1 Signup free3 | Lifecycle enabled=true. Profile trigger intentionally skips legacy signup issuance; claim RPC only returns prior delivery. Two eligible confirmed users created Oct15/19 have benefit_delivery rows with NULL grant_id and no credit account. Deployed claim records this as PREVIOUSLY_CLAIMED when a known benefit marker exists. Eligible users without delivery0. | Do not disable lifecycle, delete markers or grant3 to everyone. Determine whether these two are legitimate returning identities versus incorrect prior marker coverage. Fresh-user failure is not proven from these rows; preserve once-per-verified-identity policy. |
| 2 Missing Credit accounts | Accounts are created lazily inside credit_post_grant, not at Auth creation. Six current Auth identities lack account: three pre-Sep29 cutoff, one unconfirmed/no profile, two NULL-delivery cases above. Five confirmed/profile cases are NOT five new signup failures. There are8 accounts,3 detached; do not equate totals to live member coverage. | No new account table or eager backfill justified. Successful eligible grant creates account atomically. If Owner requires account rows for zero-credit users, that is a separate behavioral decision; UI should distinguish no account from failure. |
| 3 Android purchase | Production metadata lacks both IAP_GOOGLE_SERVICE_ACCOUNT_JSON and IAP_GOOGLE_PACKAGE_ID. Deployed Google path requires these; missing first value throws UNCONFIGURED before Google API/grant. IAP_ENABLED=true now verified. | Configure only verified LegendStudy Play principal/package after PHASE2 approval, then validate existing transaction state before any replay. No current DB permission fix indicated. Exact affected order not yet correlated; no new buy/refund/consume. |
| 4 iOS purchase | Seven Apple setting names present. Nonsecret metadata matches IAP_APPLE_ENVIRONMENT=Production and bundle=com.legendstudy.app. v17 generic Error2 lacks Apple HTTP/API code; all purchase grants0. | Exact fault remains UNKNOWN. Do not infer wrong key, Apple401, successful Store API, or Sandbox transaction from generic Error. Obtain existing transaction time/environment and narrow diagnostic context. TestFlight/Sandbox would be denied by current Production policy even after Store verification; that branch returns pending200, not observed503. |
| 5 Admin Credit lookup | admin_member_credit4 calls and admin_dashboard3 calls HTTP200 in fixed24h window; no admin_member_search call in that window. RPC returns summary=null for missing account; inspected frontend explicitly renders Credit 계정이 없습니다. | If reported message is that empty state, it reflects missing account, not API outage. Separate latent search cast risk exists: q::uuid appears under SQL AND; literal-equivalent SELECT reproduced22P02. This is NOT reproduction of authenticated RPC/PLpgSQL parameter behavior. Need exact UI error/request before claiming root cause. Minimal defensive change, if confirmed, is guarded qid conversion as already used in admin_member_list, preserving ACL/DTO. |
| 6 Admin school display | Profiles with school5; school_display_cache only2 entries; one saved school code lacks cache name. Deployed admin_member_list joins exact office/code and returns school_state=unresolved on miss. | Refresh only the missing verified NEIS display entry through existing cache pathway; retain profile/history and no broad master import. This explains unresolved name for one row; does not prove every reported screen symptom. Actual affected member/page still needs correlation. |

The school/account aggregations expose no user UUID/email or student answer.
Production Worker v35 has benefit-stage diagnostics beyond local source, and dispatch
HTTP200 alone is not a benefit PASS. Latest health last_seen02:15:02 UTC;
no eligible pending-delivery rows were found. Thus do not attribute the two
terminal NULL deliveries to a currently stalled Worker without further evidence.

### Configuration / log evidence refinement

`supabase secrets list --help` inspected, then read-only metadata listing used.
Only names and allowlisted nonsecret value matches printed, no credential values.
CLI JSON calls the digest field `value`; initial comparison against nonexistent
`digest` was inconclusive and corrected. Matched known literal/sha256 candidate
values for IAP_ENABLED=true (updated Oct22 13:21:33 UTC), Apple environment Production
(13:19:07 UTC), bundle com.legendstudy.app (13:41:42 UTC). Presence/digest does not
validate Apple private key, root certificates or API permission.

v17 UNCONFIGURED timestamps: Oct23 10:37:34 and10:37:51 KST. Generic Error logs
span Oct22 23:04–23:39 KST. Platform/order IDs are absent from safe diagnostics;
Google missing config is a deterministic present blocker, but matching either
specific reported purchase to these logs requires additional evidence.
No IAP grant RPC call appears in the fixed24h edge log query. No post-grant
settlement/consume failure can be inferred when grant never occurred.

### Preservation review before candidate implementation

1. Preserve signup/purchase/record timestamps; no invented historical grant date.
2. Retain original Ledger postings, refund and benefit anti-abuse evidence.
3. No balance overwrite, marker deletion or school-history replacement.
4. Existing auth.users identity and canonical account/grant linkage only.
5. Financial entitlement separate from learning/results; Essay runtime untouched.
6. Operator-only minimal diagnostics; no PII/token/key exports or ACL broadening.
7. No account vs zero balance vs unavailable stay distinct; school cache is a
   display projection, never authoritative school selection or B2B membership.

### Phase gate and verification

PHASE1 investigation report is PARTIAL for full root-cause closure: Android missing
configuration and school-name cache gap confirmed; signup suppression/lazy account
mechanism established, but returning-identity legitimacy not independently proven;
iOS and exact Admin error unresolved. No blanket six-incident FIX READY claim.
Owner was asked for the newer handoff/review (if any), purchase time/build/channel
and Admin error wording. These are needed to correlate incidents, not permission
for additional read-only investigation. PHASE2 has not started.

Future checks after scoped approval: Google configuration + actual existing-order
verification, eligible-new vs returning signup distinction, Admin missing-account
and email/UUID searches, saved-school display, iOS exact failure-stage regression;
retain exactly-once grant and no unverified finish/consume. No production E2E is
claimed from catalog queries or source review. Wiki checker and diff check only
are appropriate to this documentation/read-only change.

## Superseding Owner directive / Oct23 handoff and purchase correlation

The attached OWNER MASTER DIRECTIVE authorizes local recovery implementation,
isolated tests and commit/push, while retaining explicit approval before Production
DB, Edge or payment-setting changes. It replaces the earlier work location with
`~/development/legendstudy-payment-recovery-20261023`, branch
`codex/payment-credit-recovery-20261023`. Actual path/branch verified. The earlier
worktree and concurrent Essay worktrees remain untouched by subsequent writes.
Earlier PHASE1-only wording above is historical; Production remains read-only.

Unified main verified at `cf8a9365611fdf105cf602879b91bb7dbefb0465`:
- [Oct23 Claude handoff](https://github.com/LC3808/legendstudy-docs/blob/cf8a9365611fdf105cf602879b91bb7dbefb0465/90_HISTORY/2026-10-23-iap-verify-codex-handoff.md)
- [Oct23 Grok review brief](https://github.com/LC3808/legendstudy-docs/blob/cf8a9365611fdf105cf602879b91bb7dbefb0465/90_HISTORY/REVIEWS/2026-10-23-grok-code-review-iap-verify.md)

The second document contains a review request/proposed code, not the full returned
review. The first records Grok's HOLD conditions. These supersede the Oct12 review
for this incident. Document statements are evidence to verify, not deployment
permission. In particular, “Google normal” conflicts with verified missing Google
settings; digest matches alone do not prove Apple key validity, and a generic Error
without HTTP status does not independently prove the exact failing instruction.

Owner confirms both are official Play/App Store installations, not TestFlight:

| Reported purchase (KST) | Read-only log correlation |
|---|---|
| iOS Oct22 21:04 | Window21:00–21:20: verify-iap-purchase POST503 at21:04:48.646. No IAP_VERIFY_FAIL line in that window. |
| Android Oct23 11:22 | Window11:20–11:35: UNCONFIGURED + POST503 at11:21:58.367/370; two generic Error/503 pairs at11:23:06. |

Both show “구매가 확인되면 크레딧이 자동으로 충전돼요” without credit. This is
purchase-pending wording, not an Admin error. Time proximity supports correlation;
platform/order identifiers are absent from the safe logs, so exact transaction
identity and Store state remain UNKNOWN. The separate Apple3 purchase mentioned
in the master directive still needs its existing transaction evidence. No new
purchase, receipt replay, consume, grant or refund occurred in this investigation.

### Local Apple recovery draft — NOT DEPLOYED

Node X509 verification was reproduced as unsupported in isolated
`supabase-edge-runtime:1.74.3` (Deno2.1.4 compatibility). This proves a compatibility
blocker for that runtime, not the exact first exception for the Production order.
The local draft replaces Apple signing and JWS/certificate verification with Web
Crypto; Google business logic and existing Ledger contracts remain unchanged.
Preserved controls include pinned root, leaf/intermediate signatures and Apple
OIDs, certificate dates, online OCSP for both certificates, signed OCSP authority,
freshness and exact CertID, JWS signature, account/product/transaction/environment,
revocation and existing grant RPC. OCSP failure never grants.

The draft incorporates the handoff's current Apple hosts, 404-only permanent
rejection (410 retryable), PKCS8 newline/base64url handling, raw64 ES256 signatures,
and bounded stage/HTTP diagnostics without key/token/transaction logging.
Production configuration, deployed v17 and all data remain unchanged.

Synthetic tests passed on local Deno and isolated Edge1.74.3: valid chain/JWS and
both OCSP checks, unknown/stale/wrong-CertID/wrong-signer/outage rejection, untrusted
root, expired chain, payload tampering and four key encodings. Existing handler
regressions19 PASS. These are local evidence, not actual Apple JWS, store authority,
DB idempotency or device E2E acceptance. Draft still requires broader certificate
and HTTP/claim regression review, deployment packaging and an exact rollback plan
before requesting a Production change approval.

### Remaining recovery boundaries

- Google: required configuration absent; validate existing authorized Play service
  account/package and API access before proposing the exact setting change.
- Signup: distinguish legitimate fresh identities from previous benefit claims;
  preserve anti-abuse markers. Master directive now explicitly requires normal new
  users to receive an account and free3; it does not authorize blanket backfill.
- Admin: saved-school cache gap confirmed; exact affected screen/member and failed
  credit query remain uncorrelated. Preserve profile selections and histories.
- Refund: Production refund components absent at inspection; isolated prior TEST
  success is not Production support. Do not execute partial store refunds.
- Actual verified purchase delivery, existing unpaid recovery, APP/WEB balance and
  device E2E remain HOLD. No Production recovery PASS is claimed.

Additional local verification: full Apple HTTP-to-verified-purchase projection,
400/401/410/429/500 retryable vs404 rejected, ten signed claim/account/product/
transaction/revocation/future-date failures with mock-grants0, valid mock-grant1.
All passed in local Deno and Edge1.74.3. Dependency versions/lock captured; raw
exception debug output removed. Production rollout is not ready: RSA/delegated
OCSP and malformed-chain coverage, deployment packaging and captured v17 rollback
are outstanding. The old deployment helper only includes three files and must not
be used for the expanded draft. No commit/push/deployment is claimed at this checkpoint.

### Android setting inventory — Owner self-service preparation

Oct23 fresh read-only CLI metadata check (values/digests not printed):

| Secret | Production stlhijzpjfgwwdgunlsd | IAP TEST kpqbedylxlyntrrfybpn | Payment TEST wsnrwklplnunjktyfmbr |
|---|---|---|---|
| IAP_GOOGLE_SERVICE_ACCOUNT_JSON | ABSENT | PRESENT | ABSENT |
| IAP_GOOGLE_PACKAGE_ID | ABSENT | PRESENT | ABSENT |

Reuse the existing IAP TEST credential's original JSON file and existing Play app
package after confirming the active key and app permissions. Oct16 evidence records
successful Google OAuth/order/product reads with an existing local credential;
current credential validity is not established merely by presence. No new account,
key, secret write, purchase, verifier replay or deployment was performed here.
The service-account JSON originates from Google Cloud IAM, while Play Console
Users and permissions grants access to the app. The package is the published app's
package identifier, not its SKU or Cloud project ID. Existing downloaded private
keys cannot be re-downloaded from Google Cloud; locate the original secure file
before considering a replacement key. Supabase metadata listing provides no
recoverable plaintext. Owner instructions target Production Edge Functions →
Secrets, not Vault or API Keys. Existing pending purchases may retry after settings
are saved; no fresh purchase is required. Success means verified grant/ledger and
balance, not HTTP200 pending alone.

### Oct23 12:31 KST — after Owner configured Google settings

Fresh metadata: Production service-account JSON registered12:25:11 KST; package
registered12:25:44. Both PRESENT. Digest-only comparison (no values printed):
service-account JSON exactly matches IAP TEST; package does NOT match IAP TEST.
IAP TEST package digest matches the repository Android applicationId; Production
matches neither that identifier nor checked trailing-space/newline/quoted variants.
Thus presence is fixed but package correctness is not established; the known
TEST/applicationId mismatch is confirmed. Do not rotate/recreate service credentials.
Owner should compare the Production package with the published Play app identifier.

Read-only03:25–03:35 UTC logs:12:31:08.260 and12:31:20.343 requests are HTTP422,
not503. Both corresponding diagnostics say stage Error. Current deployed version19
has same source SHA as priorv17. Rejected extends Error without overriding name,
so the generic Error here can represent explicit purchase rejection. Google404/410,
non-purchased state, quantity/order mismatch or missing binding/time can reach that
branch; platform and exact reason remain absent from logs. Apple-null fields are
common diagnostics and do not identify platform. Wrong package can cause404,
but no Google HTTP response was observed, so that causal chain remains suspected.
No Production change, purchase replay, grant or credential disclosure by this agent.

## Current recovery checkpoint — existing Google orders independently verified

### Android evidence, superseding earlier assumptions

Owner supplied the existing credential directory; the existing JSON was used only
for OAuth and read-only Google orders.get / purchases.products.get. No new key.
Play Console and API independently establish these are TEST orders even though
Owner installed the published Play app. Installation channel is not purchase type.

| Order time KST | Processed | Refunded | API now |
|---|---|---|---|
| Oct23 11:21:55 |11:21:55|11:26:56|REFUNDED, purchaseState1, purchaseType0, ACK0, consumption0|
| Oct23 12:31:02 |12:31:03|12:36:03|REFUNDED, purchaseState1, purchaseType0, ACK0, consumption0|

Both OAuth/order/product reads succeeded (HTTP200 for each order/product). Returned
orderId matches; account binding and purchase time present. Raw IDs, receipts,
tokens, keys and account identifiers were neither logged nor added to the repo.
Calls: OAuth2, orders.get2, purchases.products.get2; Apple API0; new purchases0;
consume/ack/refund/grant0. API quota use only; no paid purchase/provider usage.

**Confirmed current rejection:** googlePurchase checks purchaseState before other
claims and rejects state1; these refunded orders are not eligible for recovery as
paid Production Credit. Additionally, purchaseType0 is Sandbox/test and Production
explicitly denies spendable grant. This is not evidence of successful live IAP.

**Historical12:31 rejection remains unresolved:** 422 happened BEFORE refund.
Current state1 cannot explain that earlier state retroactively. At that time the
package digest differed; Google404/410 or a claim rejection were possible, but
neither raw response nor rejected reason was retained. Do not claim package404 as
confirmed. The11:21 configuration failure was separately confirmed.

Production package updated12:35:25 KST and now exactly matches published Android
applicationId (digest-only check). Stop asking Owner to re-enter it. Current source
version20, same bundle SHA asv17/v19, verify_jwt=true. A source-only rollback
snapshot and metadata are saved in tool/iap_recovery/rollback. Agent deployed0.
Fresh read-only Ledger count: Google grants0, Apple grants0.

### Implemented local changes and review packages

1. Google: diagnostic reasons for not-found/gone token, state, quantity, order,
   binding and purchase-time rejection; OAuth vs purchase HTTP status, key import
   and signing stages separated. No raw response body/identifier logging. Existing
   entitlement checks retained; OAuth404/410 remains retryable service failure,
   rather than declaring a user's purchase invalid because auth endpoint failed.
   Fetch redirects disabled to prevent forwarding credentials.
2. Apple: WebCrypto ES256 request signature; current Apple host;404-only rejection;
   pinned x5c chain, mandatory Apple OIDs, dates, JWS signature; signed, fresh OCSP
   for leaf and intermediate with exact CertID and issuer/delegated responder;
   account/SKU/transaction/environment/revocation gates and existing RPC retained.
3. No Flutter, DB/RPC, settings, Worker or Essay modifications in this draft.

`python3 tool/iap_recovery/build_package.py` produces review manifests and two
source packages without network access: google-diagnostics(3files) and combined
(6TypeScript files + dependency lock). Both use the unchanged deployed Production
index.ts, so local isolated-Sandbox entrypoint behavior is NOT promoted. Both type
check. Deployment requires the exact approved package, verify_jwt=true, and a fresh
source SHA check against the captured rollback; do not run the old3file helper for
the combined package. Restore captured3files/JWT setting for rollback, preserving
all ledger records. Secret changes are outside these packages.

### Verification and limits

Existing handler19 + Google2 + Apple2 suites PASS (23 tests). Apple suites cover EC
and RSA chains, issuer and delegated OCSP, responder-by-key, stale/unknown/wrong
CertID/wrong signature/outage, invalid chain/order/date, JWS tamper, PKCS8 variants,
HTTP mapping and ten signed entitlement rejection scenarios. Both Apple suites
also PASS in Edge1.74.3. This is a pinned local runtime, not proof of the exact
hosted runtime build or actual Apple-signed transaction acceptance. Synthetic keys
are ephemeral fixtures, not newly created Apple/Google credentials.

Actual Apple JWS and existing Apple1/3 transaction recovery remain HOLD. Before
Production replacement: obtain existing transaction input through the authorized
secure recovery path and verify with existing Apple settings, confirm exact
rollback/package and Owner approval, then retry existing valid transaction only.
Observe one grant, duplicate0, original balances preserved; no manual credit.
Google historical422 cannot be retrospectively recovered from generic logs; proposed
safe diagnostic package makes any future existing-transaction rejection specific.
No renewed purchase or test-to-Production entitlement bypass is proposed.

### Gemini review supplied by Owner

Direction agrees with Claude: replace both signing and certificate verification,
not only JWT signing. Independently reproduced Edge X509 unsupported behavior and
WebCrypto fixture PASS support that direction. Generic Error + null HTTP fields
alone do NOT prove no network request or identify the signing instruction; network,
verification and custom errors can lack HTTP fields. Dummy-key401 proves API reach,
not actual Production key validity. Valid synthetic PKI tests must verify signatures
and reject arbitrary dummy JWS; accepting an unsigned dummy is never a test goal.
The pasted analysis is review evidence, not new deployment authorization.

Final supplemental probes: valid wrapped ephemeral PEM imports as EC in Edge1.74.3,
but jsonwebtoken9.0.2 ES256 fails with the prime256v1 curve requirement;
Node X509.verify is explicitly unimplemented; WebCrypto signing passes. This
reproduces BOTH compatibility blockers without attributing a historical Production
exception from generic logs alone. Existing local Apple subscription .p8 imports
and generates a64byte WebCrypto signature in local Deno; Apple API calls0. This
does not prove its equality to deployed secret or Apple issuer/key permission.
Implementation pushed to APP codex/payment-credit-recovery-20261023. Unified
sanitized report pushed to docs codex/iap-recovery-evidence-20261023 (not main).
No Production approval/application or actual Apple recovery claimed.


## Owner-approved recovery — 2026-10-23 13:35 KST

Owner explicitly authorized Production deployment, existing verified iOS recovery,
and actual purchase E2E. Google TEST/refunded orders2 explicitly excluded.
Only verify-iap-purchase changed; no DB/schema/Secret/Essay worker mutation.
Production entrypoint unchanged, verify_jwt=true, exact live TS source matched.
- v21 WebCrypto + bounded Google diagnostics deployed (baseline v20 preserved).
- Existing iOS retry13:26:58 reached OCSP after API/chain/JWS verification.
- v22 added bounded OCSP step/status diagnostics (no raw errors/receipts).
- Actual Apple WWDR G6/root G3 OCSP succeeds on local Deno but Edge1.74.3 fails:
  HTTP200, delegated responder certificate signature verification throws
  NotSupportedError for ECDSA P-384 with SHA-256. Synthetic P256/RSA tests had
  missed this valid mixed curve/hash pairing.
- v23 verifies only that certificate pairing with pinned @noble/curves2.0.1;
  remaining certificate signatures and Apple JWT/JWS stay WebCrypto. Full chain,
  pinned roots, delegation EKU, OCSP signature/status/freshness remain mandatory.
  No bypass, no new key, no fresh Apple purchase.
- v23 source bundle229f53bdd7adc59c2896f481c8755d68e2658ce940f7d95ba7f13682f0e598fa.
  v20 rollback source remains in tool/iap_recovery/rollback (restores known failure).
- Deno24 tests PASS; pinned local Edge synthetic EC/RSA/OCSP suites and new
  P384/SHA256 valid/wrong-key/tampered/expired cases PASS. Real Apple public
  intermediate OCSP also PASS on Edge after fix (no purchase data in that test).
- Owner device confirms existing1+3 charged. Production Ledger: apple delta1 x1,
  delta3 x1, distinct grants2, duplicate external references0. Affected account1;
  prior non-IAP grants3/net7, purchased4, reserved0, spendable11. Earlier other9
  snapshot is historical; do not claim current balance9 or overwrite it.

### Android readiness and common-issue recheck

Play Console read-only: Production release100%, no unpublished changes; all
credit1/3/5/10 have one active purchase option. License test email list
'레전드스터디 IAP 테스트' selected, members3. Owner confirms purchaser is included.
Developer-login email is NOT proof of purchaser identity; Owner confirmation is
explicit evidence. Existing service-account OAuth/order/product GET succeeded;
current package exactly com.legendstudy.app. Client consumes/completes only after
verified grant/already_processed, autoConsume=false. Shared Ledger receipt lock,
SKU quantity mapping, service-only role and same-account replay gates re-read.
Owner asked to perform one real1-credit purchase with non-license-test account
only after these checks. No new Android charge or live grant observed yet.

Current read-only DB state supersedes earlier counts: configured school profiles3,
cache2, unmatched school codes0. No school cache/profile rewrite needed now.
Actual admin_member_search(non-UUID email) in read-only transaction with existing
operator context returns0 rows, no cast exception. admin_member_credit on all3
users without accounts succeeds with summary=null. This is DB-level authorized
context verification, not browser JWT end-to-end. No proven backend lookup outage;
frontend empty-state wording remains distinct from API error.
Signup grants8, each3, all expiryNULL. Pending candidate count0. Sole NULL delivery
belongs to confirmed/eligible Oct23 account without Credit account. Owner confirms
this was deletion/re-registration with existing identity: previous-claim suppression
matches accepted once-per-identity policy. No duplicate free grant, marker deletion,
or blanket account backfill performed. New first-ever-identity device E2E not run.

References: Apple official jws_verification.ts (OCSP checks preserved), Apple PKI
public G6/G3 certificates, noble-curves pinned API. Actual iOS E2E now PASS;
Android real charge/credit/consume and browser Admin UI acceptance remain pending.

### Browser and local app verification follow-up

Existing authenticated operator, separate new LAB tab: /admin/members/ loads9
members; configured schools render names (three rows), Oct23 re-registration
member detail opens successfully and shows the explicit missing-Credit-account
empty state, not a lookup exception. No existing Essay tabs/files altered.
Additional Flutter billing/history/lifetime/session tests could not start: installed
Dart3.8.0 vs package requirement^3.13.3. No Flutter PASS claim. Owner will use a
non-license-test Google account for the final Android1-credit real purchase.

### 13:41–13:43 KST Android follow-up

Owner reports pending message and missing signup3. Play order list shows latest
13:36 KST credit1 explicitly TEST, refunded, KRW0. Therefore the attempt did not
establish a normal live-payment E2E despite intended non-tester use. Verifier
requests13:36/13:40 HTTP200, no new failure diagnostics; Google Ledger postings0.
Sandbox denial returns pending200 by current policy. Historical request payloads
were not retained; exact request-to-order mapping is not inferred from time alone.
Owner supplied app login email privately: exact DB match is Oct23 12:26:50
re-registration, confirmed/profile present, NULL previous-claim delivery and no
Credit account. Same account Owner earlier confirmed was deleted/re-registered.
No new signup fault or need to bypass benefit markers established. App login
identity and Play billing identity are separate; purchase dialog account must be
checked before another charge. No new keys, manual grants, refunds or test-credit
Production bypass performed. Raw email/order identifiers omitted here.

## Owner UI correction — Oct23

Within existing [native navigation](ui-ux-v1.md) and IAP scope, Owner requests
논술 LAB description exactly: “대학별 평가 기준에 맞춰 내 답안을 점검하고, 직접 고쳐써보세요”.
Remove the availability/technical Credit·첨삭·재작성·평가 description from this card.
Release-readiness branch contains the reported old string; recovery branch had
an older HOLD description at the same component. Only this branch's body changed
to the explicit Owner text; no other worktree/Essay backend change.
Purchase history is a local tab, so PopScope intercepts the first app-bar/system
back to return to top-up; subsequent back leaves the page normally. Controller
lifetime and purchase state remain unchanged. Widget regression covers app-bar
and Android system back and eventual exit. Formatting/diff checks completed;
Flutter execution blocked by installed Dart3.8.0 vs required^3.13.3. App release
and device UX acceptance remain pending; these edits are not in the installed app.
No schema, profile, learning record, transaction or Credit balance changes.
