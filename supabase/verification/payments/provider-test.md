# Independent Toss provider TEST gate

2026-10-03 official review; no provider transactions executed in this task. Runtime has no Toss-related environment variable names. Cloudflare remote binding presence was NOT independently verified. No secret values read/output. No authenticated Sandbox session supplied. Missing provider access blocks ONLY provider verification, not APP persistence tests.

Official sources:
- https://docs.tosspayments.com/guides/v2/get-started/llms-guide
- https://docs.tosspayments.com/guides/v2/get-started/environment
- https://docs.tosspayments.com/guides/v2/get-started/payment-flow
- https://docs.tosspayments.com/guides/v2/cancel-payment
- https://docs.tosspayments.com/reference

Official TEST payments are virtual approvals with no real withdrawal. Sandbox-issued test paymentKey/orderId can support independent API verification; this does not require an APP grant. SDK v2 is the intended later LAB integration; no obsolete v1 implementation added. Exact SDK surface selection belongs to later LAB task, not this DB foundation.

Pending configuration names (new explicit contract, not a claim of existing bindings): TOSS_TEST_CLIENT_KEY, TOSS_TEST_SECRET_KEY, TOSS_MID=leglabn24k; deployment payment mode must be TEST. Owner enters secrets directly in approved environment/Cloudflare binding; never chat/Git. Matching test key pair only, live prefixes rejected before network; absence fails closed. Provider TEST harness must have no Supabase financial write capability.

After approved runtime access is supplied: create two distinct Sandbox TEST payments, keep identifiers only in protected ephemeral runtime; verify V2 redirect contract, confirm POST /v1/payments/confirm, lookup GET /v1/payments/{paymentKey}, full and partial POST /v1/payments/{paymentKey}/cancel, duplicate idempotency, lookup after ambiguous result, amount mismatch and bounded errors. TEST keys select environment; use official HTTPS API, not a guessed alternate test hostname. Success callbacks are not proof. Report only pass/fail/counts, no keys/JWT/raw provider payload/card/buyer data. No Ledger calls. A provider-only PASS must remain separate from APP integration and LAB checkout readiness.

TOSS_PROVIDER_TEST: BLOCKED (runtime TEST credentials/Sandbox access unavailable)
SDK checkout / confirm / lookup / full cancel / partial cancel / provider idempotency / error behavior: NOT_RUN.
