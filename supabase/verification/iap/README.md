# IAP verification acceptance

2026-10-09: endpoint version1 deployed with platform verify_jwt=true; additive
20261009000200 applied. RPC postgres/SECURITY DEFINER/search_path empty,
service_role only; anon/authenticated EXECUTE denied. Real IAP grants: **0**.
No Store credentials or product registration evidence exists in this environment.
IAP_ENABLED is absent (false). Do not enable yet.

## Local checks

- `deno check supabase/functions/verify-iap-purchase/index.ts`
- `deno test supabase/functions/verify-iap-purchase/core_test.ts`
- `node supabase/verification/iap/behavior.mjs`: requires PGLITE_MODULE,
  PGCRYPTO_MODULE and IAP_TEST_DB pointing to an **isolated, already migrated
  canonical Credit fixture** (same fixture as Admin/Credit validation). Never
  point at a live DB. Role/receipt/SKU/replay/expiry/atomic rollback assertions
  all roll back. Auth/lifecycle dependency fixtures use canonical function bodies.
- `postflight.sql` is read-only Production metadata and IAP grant count.

The deployed path authenticates a real user, independently verifies the Store
transaction, checks account binding/product/transaction/time/environment/revocation,
then invokes the service-only wrapper. Browser/client quantity is never used.
Google requires obfuscatedExternalAccountId; Apple requires signed appAccountToken.
The native client supplies its canonical Auth UUID to both Store adapters.
Sandbox transactions never grant spendable Production Credit. Missing settings,
Store failure and ledger failure remain pending. No automatic environment fallback.

Canonical credit_post_grant is reused unchanged: origin=purchase, provider-specific
reason iap_apple_v1 or iap_google_v1; deterministic transaction hash external key,
actor system/iap, UTC calendar3-month expiry from Store purchase time. Original
ledger entries remain immutable. Existing account_id deletion/anonymization
semantics remain; no user/email/receipt payload or token table is added.
A transaction hash remains after profile deletion so it cannot be claimed again.
No balance table, entitlement system, Payment/Toss change or new expiry policy.

## NOT VERIFIED / activation gates

Actual Apple/Google API call, sandbox purchase and Production purchase are unrun.
Post-grant Store refund/revocation notification/reconciliation is **NOT IMPLEMENTED**.
Pre-grant cancelled/revoked transactions are rejected, which is not a complete
refund lifecycle. Receipt audit currently resides in provider-specific ledger
references; full Store reconciliation requires a follow-up before activation.
Cross-platform paid balance uses existing credit_summary; Store-policy acceptance
has not been confirmed. Native store purchase recovery is implemented but still
needs genuine Store/device testing. No paid purchase was made.

Required Supabase Edge Function secret/config names:
- IAP_GOOGLE_SERVICE_ACCOUNT_JSON (dedicated Play Developer API principal)
- IAP_GOOGLE_PACKAGE_ID=com.legendstudy.app
- IAP_APPLE_PRIVATE_KEY, IAP_APPLE_KEY_ID, IAP_APPLE_ISSUER_ID
- IAP_APPLE_BUNDLE_ID=com.legendstudy.app, IAP_APPLE_APP_ID (Console numeric ID)
- IAP_APPLE_ENVIRONMENT (Production or Sandbox; no silent fallback)
- IAP_APPLE_ROOT_CERTIFICATES_BASE64 (JSON array of official Apple PKI DER roots)

Store products must match the four IDs in core.ts. 20c is excluded. Never substitute
Supabase management/service credentials for a test-user token or Store credentials.
A separately reviewed sandbox strategy is required before any sandbox ledger grant.
