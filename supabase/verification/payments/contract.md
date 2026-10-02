# Payment foundation v1 — bounded server contract

APP owns persistence; LAB implementation NOT started. No HTTP/SDK/provider adapter is implemented here. All JSON input is bounded and unknown keys rejected. Request UUIDs are operation-scoped. No client price, account, quantity, mode, or coupon authority. SQL errors use PT401/403/404/409/422/503; malformed UUIDs may yield 22P02, unique contention 23505. Gateway must map those to sanitized API errors.

## Authenticated user RPC: public.payment_order(p jsonb)

`dto_version: "payment-v1"` always required.

| action | Other exact keys | Result |
|---|---|---|
| create | sku (`1c`, `3c`, `5c`, `10c`), request_key UUID | server-generated order snapshot |
| get | id UUID | own order only |

Subject is `essay_private.uid()`, never a payload identifier. Lifecycle advisory lock precedes current allow check, even on retries. Missing ADR prerequisite fails closed. Server configuration selects mode. New order validity is 30 minutes; unpaid expired orders remain historical ORDER_CREATED but confirm_begin rejects by expires_at. This is independent of paid Credit expiry. Duplicate create preserves original snapshot/deadline; changed SKU conflicts.

Result exact fields: dto_version, order_id (`ls_` + UUID without hyphens), id, provider, mode, sku, amount, quantity, currency=KRW, state, grant_state, expires_at, paid_at, credit_expires_at. Nullable fields are null before completion. No provider key, financial account/grant id, buyer identity, worker secret or internal notes in user projection. Order ID is identifier, never authorization.

Prices v1: 1c=4900,3c=11900,5c=17900,10c=29900 KRW. This is the server-side snapshot of approved LAB pricing.ts; future price changes require a new reviewed policy version. No prices are accepted from clients. TEST order creation does not create a Credit account.

## Trusted gateway RPC: public.payment_process(p jsonb)

Only `essay_finance` EXECUTE, with a non-null server-authenticated subject; no anon/authenticated/service_role access. This is the existing financial capability, NOT a browser role. No new role or role membership is granted to the browser. Future LAB must authenticate buyer via normal JWT, fetch `payment_order.get` with that JWT to prove ownership, then use a separately provisioned trusted server capability. Do not mint financial authority from untrusted JWT claims or pass a browser-selected subject. Gateway credentials/issuance are deployment gates, not installed secrets.

All actions include dto_version/action/id. Allowed extra keys:

| action | Extra keys | Boundary |
|---|---|---|
| confirm_begin | request_key, payment_key, amount | stored amount match; unexpired order; durable payment-key binding and operation |
| confirm_finish | operation_id, payment_key, amount, paid_at ISO timestamp | verified provider success only; atomic canonical posting + PAID |
| cancel_begin | request_key | server usage/refund calculation; reserve fence before provider call |
| cancel_finish | operation_id, payment_key, amount | verified provider cancellation only; canonical debit once |
| outcome | operation_id, outcome UNKNOWN or REJECTED | UNKNOWN retains fence; REJECTED only after authoritative provider rejection |
| get | none | latest bounded operation, recovery |

Gateway result adds operation_id, operation_state, provider_idempotency_key, operation_amount, consumed, payment_key; these remain server-only. No raw responses. `provider_idempotency_key` is durable, reused on provider retries. Request retries use the original request key; changing it for an existing confirmation conflicts. Gateway may retrieve the original pending operation rather than generate a new key. Cancel request changed extra amount/reason is rejected.

## Provider verification boundary

DB does not contact Toss or cryptographically establish provider success. Only trusted gateway may assert finish. Before finish it MUST independently validate provider paymentKey/orderId, merchant/environment, currency KRW, totalAmount, approvedAt and canonical success status. Redirect/webhook alone is insufficient. Provider error or ambiguous network response must NOT call finish. For unknown completion, query Toss and reconcile the same operation; do not grant independently. Webhook is only a bounded wake-up until provider lookup validates canonical facts; out-of-order/duplicate delivery uses get/finish and the same operation. Provider/API idempotency retention is not permanent: durable DB identity persists beyond it; lookup before reattempt once provider retention is exceeded.

## TEST versus LIVE

Migration inserts only private configuration TEST. No activation RPC. No LIVE secret, no provider call. TEST success creates TEST_RECORDED and never invokes credit_post_grant; TEST refunds revoke only the test record. TEST records are not a second wallet and cannot be used by Essay/Math. TEST runtime usage remains zero because these credits cannot be consumed. Partial-refund arithmetic and real-grant lineage are proved with synthetic LIVE-mode fixtures in disposable PG only, not simulated production spending.

LIVE economic branch is future-capable but NOT activated: exact one existing `purchase` grant, immutable external reference `payment/<order UUID>`, atomic transaction posting, canonical paid timestamp + three calendar months in UTC. No free signup policy or consumption-order changes. A LIVE outcome for a deleted/restricted principal fails closed with PAID_REQUIRES_REFUND_RECONCILIATION; it remains detectable pending, not silently granted. An account-deletion/payment reconciliation extension is REQUIRED BEFORE LIVE so provider-paid/ungranted orders cannot be stranded. This task does not change ADR erasure policy or deploy LIVE.

## Refund consistency

General-policy refund = max(0, original amount - net consumed units × stored4900). Per-grant consume/refund postings determine used units; included reevaluation produces no new debit; released/failed evaluations do not count as consumed. No total wallet inference. Existing reservations block cancel_begin. No zero/negative-money cancellation is sent. Financial account -> order -> grant/operation locks follow lifecycle lock where present. No provider network call holds these locks.

cancel_begin records exact remaining quantity and enters CANCEL_PENDING without removing credits. New ledger postings on that grant are fenced, including expiry/technical reversal, except the exact pending cancellation adjustment. Provider UNKNOWN retains fence; confirmed rejection returns PAID without debit; confirmed cancel atomically debits that grant's remaining units and records PARTIALLY_CANCELLED or CANCELLED. No other grant is touched. General refund retires all unused entitlement for that purchase; a partial cash refund is not a second independently refundable remainder. A later technical reversal against a cancelled purchase fails closed for explicit financial reconciliation, not automatic recredit of refunded credit. Detached credit account still supports cancellation via grant.account_id; no reattachment of personal identity.

Statutory cancellation/exception amounts are deliberately not exposed through general_refund arithmetic. They require separately reviewed support authority/contract before LIVE; no arbitrary amount override in this API. No self-service cancel UI is implemented. Backend finance role is the controlled support boundary.

## Deployment gates

Owner migration review/apply separate; ADR lifecycle prerequisite independently reviewed/applied; existing ledger owner topology must match. TEST provider secret binding and trusted gateway capability required; LAB functions/SDK/callbacks are later scope. Before LIVE additionally resolve provider-paid/ungranted deletion/reconciliation, overdue paid grant expiry, financial retention/privacy detachment and statutory exceptions; review actual merchant partial-cancel support, privacy, monitoring and deployment. Nothing here declares a Production checkout ready.

## Provider-neutral purchase identity — Owner amendment

`payment_orders.provider` is TOSS / APPLE_IAP / GOOGLE_PLAY. `provider_purchase_id` is a bounded opaque external grantable purchase identity, unique together with provider and mode. TEST and LIVE are separate namespaces. Existing unique grant_id and server order identity preserve one purchase→one canonical grant. No second wallet, no Auth duplication.

Toss adapter maps verified paymentKey to provider_purchase_id; its public request field stays payment_key, with existing200-character Toss bound. Generic storage allows1024 characters for future normalized purchase identities; this is not permission to store receipts, credentials or raw provider payloads. A future Apple/Google adapter must independently verify the actual grantable transaction/purchase identity (not merely a subscription-family ID), account binding, environment and SKU snapshot, then use the same durable purchase uniqueness/one-grant discipline. Provider-specific verification, replay/refund rules and receipt normalization remain future work. No store API or recurring-product authority is implemented.

Current order RPC always selects TOSS server-side and rejects client provider selection. Current finance RPC rejects non-TOSS rows with PROVIDER_NOT_ENABLED before any processing. Schema vocabulary does not enable IAP or allow caller-claimed verification. User DTO adds provider to this unreleased payment-v1 contract. Current KRW catalogue, pricing, expiry and general refund policy remain unchanged; future store-specific policies need their own reviewed adapter, not a wallet or persistence rewrite.
