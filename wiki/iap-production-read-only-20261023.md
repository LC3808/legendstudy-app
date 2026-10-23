# IAP Production recovery — PHASE 1 read-only checkpoint

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
