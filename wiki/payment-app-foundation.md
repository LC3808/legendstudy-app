# PAYMENT APP foundation

2026-10-03: implemented and isolated verified; **Production NOT_APPLIED**. Owner authorized APP scope after LAB PAYMENT-2 identified the missing shared financial boundary. [Owner package](../supabase/verification/payments/README.md) and [exact RPC/financial contract](../supabase/verification/payments/contract.md) own implementation details. No LAB code, migration deployment, provider call or LIVE activation.

`payment_order(jsonb)` creates/reads own versioned order from server-authenticated identity and server SKU policy. `payment_process(jsonb)` is restricted to the existing trusted finance capability for durable confirm/cancel/reconciliation operations. TEST records never post spendable Credit. The future LIVE branch atomically binds one payment to one existing purchase grant; it creates no second wallet and does not change signup or Essay/Math economics. Price/quantity/validity/deduction snapshots are persisted rather than trusted from browser/callback.

General refund uses grant-attributed net consumption, not wallet balance;29,900−5×4,900=5,400. Account locks and a narrow grant fence protect provider/local cancellation gaps. UNKNOWN remains recoverable; provider failure leaves credits intact; exact retries and concurrent finish calls post once. Detached financial account cancellation remains possible without restoring personal linkage. Statutory exceptions are not forced through general-policy arithmetic.

Owner package contains migration hash, ownership allowlist, catalog/postflight, failure evidence and empty-install rollback. Existing helper bodies/ACL/ownership are preserved. New function bootstrap restores temporary SET/public CREATE; no new role or permanent runtime privilege expansion. Rollback refuses payment history or unexpected dependencies.

Validation: payment checks including real multi-session concurrency and transaction failure; G1 Credit84 + static7; Humanities/HQP102; Math131 + runtime37 (C01–C30) + learning63 (L01–L40). Exact current counts/hash in package. Auth claims are simulated locally; no real JWT gateway/Cloudflare/provider proof.

Independent [Toss TEST gate](../supabase/verification/payments/provider-test.md): official TEST/Sandbox/API documentation reviewed; runtime TEST credentials/session unavailable, calls0. Provider-only TEST may proceed independently once configured, with no Ledger access. Provider success must never be promoted to APP/LAB end-to-end success.

Next: Owner migration review, then separately authorized apply/config and LAB payment implementation. LIVE additionally requires payment/deletion reconciliation for provider-paid/ungranted outcomes, financial privacy/retention, statutory exception handling, operational reconciliation and explicit Owner activation. Current public policy and Production remain unchanged. Unified Wiki and LAB were not modified in this APP-only phase.
