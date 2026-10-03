# PAYMENT APP foundation

2026-10-03: implemented and isolated verified; **Production NOT_APPLIED**. Owner authorized APP scope after LAB PAYMENT-2 identified the missing shared financial boundary. [Owner package](../supabase/verification/payments/README.md) and [exact RPC/financial contract](../supabase/verification/payments/contract.md) own implementation details. No LAB code, migration deployment, provider call or LIVE activation.

Provider-neutral identity: TOSS/APPLE_IAP/GOOGLE_PLAY + mode + verified purchase ID. Only Toss runtime is enabled; IAP API/verification remains future work. Owner pre-apply amendment supersedes the prior hash without changing Ledger economics.

`payment_order(jsonb)` creates/reads own versioned order from server-authenticated identity and server SKU policy. `payment_process(jsonb)` is restricted to the existing trusted finance capability for durable confirm/cancel/reconciliation operations. TEST records never post spendable Credit. The future LIVE branch atomically binds one payment to one existing purchase grant; it creates no second wallet and does not change signup or Essay/Math economics. Price/quantity/validity/deduction snapshots are persisted rather than trusted from browser/callback.

General refund uses grant-attributed net consumption, not wallet balance;29,900−5×4,900=5,400. Account locks and a narrow grant fence protect provider/local cancellation gaps. UNKNOWN remains recoverable; provider failure leaves credits intact; exact retries and concurrent finish calls post once. Detached financial account cancellation remains possible without restoring personal linkage. Statutory exceptions are not forced through general-policy arithmetic.

Owner package contains migration hash, ownership allowlist, catalog/postflight, failure evidence and empty-install rollback. Existing helper bodies/ACL/ownership are preserved. New function bootstrap restores temporary SET/public CREATE; no new role or permanent runtime privilege expansion. Rollback refuses payment history or unexpected dependencies.

Validation: payment checks including real multi-session concurrency and transaction failure; G1 Credit84 + static7; Humanities/HQP102; Math131 + runtime37 (C01–C30) + learning63 (L01–L40). Exact current counts/hash in package. Auth claims are simulated locally; no real JWT gateway/Cloudflare/provider proof.

Independent [Toss TEST gate](../supabase/verification/payments/provider-test.md): official TEST/Sandbox/API documentation reviewed; runtime TEST credentials/session unavailable, calls0. Provider-only TEST may proceed independently once configured, with no Ledger access. Provider success must never be promoted to APP/LAB end-to-end success.

Next: Owner migration review, then separately authorized apply/config and LAB payment implementation. LIVE additionally requires payment/deletion reconciliation for provider-paid/ungranted outcomes, financial privacy/retention, statutory exception handling, operational reconciliation and explicit Owner activation. Current public policy and Production remain unchanged. Unified Wiki and LAB were not modified in this APP-only phase.

## PAYMENT-E2E-PREP-1 — 2026-10-03

Canonical candidate3b3b869 / hash77b460bf… supersedes e4836eda pre-apply. Original60
payment checks retained;67 current checks and Credit84, Humanities102, Math131+37+63
rerun PASS. [Independent Hosted TEST bootstrap package](../supabase/verification/payments/hosted-test/README.md)
contains24 exact ordered hashes and function ownership/ACL inventory; fresh non-superuser
PG17 install, postflight, payment rollback/failure restoration and local authenticator
finance SET/revoke PASS. Managed Auth/JWT signatures/expiry remain HOSTED_VERIFICATION_REQUIRED.
LAB Preview pair enforcement and real workerd redirect checks are implemented on its
payment feature branch. Official documentation Sandbox proof is recorded in LAB; merchant
leglabn24k E2E remains NOT_RUN. No project/config/deployment/Production changes.
Next: Owner approves empty TEST project creation, then package/config/gateway verification,
then separately authorized merchant E2E. Do not replay bootstrap into Production.

## PAYMENT-E2E-HOSTED-COMPAT-1 — 2026-10-03

[Corrected local compatibility evidence](../supabase/verification/payments/hosted-test/README.md#payment-e2e-hosted-compat-1--2026-10-03): PREP-1's public-owner normalization removed. Observed `pg_database_owner` owner/grantor, managed roles/memberships and schema/default ACL reproduced. Same 24 immutable migrations PASS as non-superuser; exact catalog, six injected failures and empty rollback PASS. Payment67, Credit84+static7, Humanities/HQP102, Math131+37+63 rerun PASS. No canonical migration change needed.

This supersedes the simplified PREP-1 fixture as Hosted compatibility evidence. Real Auth/extensions/gateway are not emulated. Existing Hosted TEST project remains untouched, applied0/24; no Finance/Cloudflare/Toss/Production action. Ready to resume HOSTED-1 with fresh preflight; actual installation and merchant E2E remain unverified.

## PAYMENT-E2E-HOSTED-1 — actual TEST installation, 2026-10-03

[Hosted evidence](../supabase/verification/payments/hosted-test/hosted-validation.json): fresh preflight PASS; exact24 files installed, per-file and final114 function catalog/ownership/ACL PASS. Public owner/grantor remains pg_database_owner; custom roles/memberships and payment RLS/TEST foundation PASS. Payment, Credit and Auth counts0; spendable delta0. No unexpected grants. SQL installation verified; migration-ledger tracking NOT_CREATED, no repair. Production untouched. Finance gateway, signing/JWT/token, Cloudflare and Toss NOT_CONFIGURED/NOT_RUN. Ready for separate Finance gateway authorization; stop before configuration.

## PAYMENT-E2E-FINANCE-1 — 2026-10-04

[Hosted gateway evidence](../supabase/verification/payments/hosted-test/finance-validation.json): A–G gateway and owner/foreign-profile RLS pass. Overall BLOCKED: two authenticated profile creations triggered existing signup_bonus3 each (+6 spendable TEST Credit), violating required zero delta. Pre-activation signup branch persists when ADR enabled=false; missing HMAC marker alone does not suppress it. One unconfirmed TEST order/event, no payment operations/purchase grant/LIVE grant. Stop without ledger cleanup, trigger/schema changes or ADR activation. Owner review required; no Cloudflare/Toss/Production action.

## PAYMENT-E2E-FINANCE-1A — 2026-10-04 COMPLETE

Owner corrected zero-total-delta to payment-attributable zero. [Read-only lineage evidence](../supabase/verification/payments/hosted-test/finance-lineage-validation.json): buyer signup+3/gateway signup+3 proven through account/grant/transaction and canonical posting metadata; payment-attributable delta0, purchase/LIVE grants0, unexplained0. Prior BLOCKED record retained for traceability; no bonus removal or ledger/policy change. Actual Hosted A–G PASS preserved; narrow membership rechecked. Gateway Auth identity suffices; future gateway preparation omits public profile. Existing profile/bonus retained. Payment69/Math131+37+63 regressions PASS. Ready for separate Cloudflare authorization; no config/provider/Production action.
