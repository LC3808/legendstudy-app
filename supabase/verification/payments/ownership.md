# PAYMENT APP ownership and capability audit

Pre-implementation allowlist. No new roles, existing helper bodies/owners remain unchanged.

| Signature | Owner | Security | EXECUTE |
|---|---|---|---|
| public.payment_order(jsonb) | essay_executor | DEFINER | authenticated, essay_executor |
| public.payment_process(jsonb) | essay_executor | DEFINER | essay_finance, essay_executor |
| payment_private.result(uuid) | postgres | DEFINER | essay_executor, postgres |
| payment_private.spend_guard() | postgres | DEFINER | postgres (trigger invocation only) |

All empty search_path. New private schema payment_private owned by postgres; USAGE to essay_executor only. New payment relations postgres-owned, RLS enabled, no client CRUD; essay_executor exact SELECT/INSERT/UPDATE, events INSERT/SELECT. Existing essay_finance is the trusted payment gateway capability, never a browser credential. No service_role EXECUTE.

Ownership initialization needs temporary postgres SET essay_executor and CREATE on public for exactly the two new public functions. Restore membership/options and public schema ACL before commit. No existing owner transfer, permanent SET/INHERIT, or new privileged role. Failure injection must verify complete restoration.

LIVE disabled in private configuration by default. No client/finance activation API. Later LIVE activation requires separate Owner authority. TEST records never bind to a credit grant or create a credit account.
