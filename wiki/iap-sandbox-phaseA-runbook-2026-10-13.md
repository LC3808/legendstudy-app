# IAP Sandbox Phase A — implementation + E2E runbook (2026-10-13)

Phase A built the **code + gating** for an isolated Apple-Sandbox → verify → grant →
ledger → balance E2E. **No production change, no deploy, no DB change, no activation, no push.**
Reuses the existing Edge Function, RPC, and Credit Ledger — no new balance system.

## What changed (code)
- `supabase/functions/verify-iap-purchase/core.ts`
  - `handler(ports, enabled, sandboxGrant=false)` — new 3rd arg (default false ⇒ Sandbox stays
    `pending`, production behavior identical).
  - Grant gate now: grant a verified **Production** tx, OR a **Sandbox** tx **only** when
    `sandboxGrant` is true; anything else → `pending`.
  - `sandboxGrantAllowed(get)` + `projectRef()` + `PRODUCTION_PROJECT_REF` — pure, fail-closed gate.
- `supabase/functions/verify-iap-purchase/index.ts`
  - `project` now from `SUPABASE_URL` (prod == previous constant; portable to a test project; safe fallback).
  - Computes `sandboxGrant = sandboxGrantAllowed(Deno.env.get)` once and passes it to `handler`.
- `supabase/functions/verify-iap-purchase/core_test.ts` — +7 tests (gate on/off, production unaffected,
  forged-tx rejected, and the fail-closed `sandboxGrantAllowed` matrix incl. production denylist).

## Fail-closed isolation (not a single env var)
A Sandbox grant requires **all** of (every input server-side, never client-supplied):
1. `IAP_ALLOW_SANDBOX_GRANT === 'true'` (default off),
2. `IAP_APPLE_ENVIRONMENT === 'Sandbox'`,
3. the function's own project ref (from `SUPABASE_URL`) resolves **and is not** `PRODUCTION_PROJECT_REF`
   (`stlhijzpjfgwwdgunlsd`) — **denylist**,
4. that ref **equals** `IAP_SANDBOX_PROJECT_REF` — **explicit allowlist**.
Consequences: in production (ref = production) a Sandbox grant is impossible **even if the flag is
mis-set** (condition 3 fails). A test project grants only Sandbox txs, only when it has matched its
own ref to the allowlist. Production and Sandbox verification environments are distinct
(`IAP_APPLE_ENVIRONMENT`); a test project's grants land in the test DB only.

## Owner — isolated test environment (do NOT use production; no new project is created by Claude)
On a **separate, Owner-provided** Supabase test project (never production):
1. Apply the **same canonical migrations** (credit ledger + `iap_post_verified_purchase`). Same
   contract — no ledger copy, no separate balance.
2. Edge Function secrets on the test project: `IAP_ENABLED=true`, `IAP_ALLOW_SANDBOX_GRANT=true`,
   `IAP_APPLE_ENVIRONMENT=Sandbox`, `IAP_SANDBOX_PROJECT_REF=<test project ref>`, and the Apple
   verification secrets (`IAP_APPLE_PRIVATE_KEY/KEY_ID/ISSUER_ID/BUNDLE_ID/APP_ID/ROOT_CERTIFICATES_BASE64`).
   `SUPABASE_URL/ANON_KEY/SERVICE_ROLE_KEY` are auto-injected. Secrets never in code/Git/Wiki.
3. **Production project**: leave `IAP_ALLOW_SANDBOX_GRANT` unset/false. (Even if set, the denylist blocks it.)
4. Deploy `verify-iap-purchase` to the **test** project only (production deploy is a separate Owner step).

## E2E procedure (on the isolated test project)
1. Point a debug iOS build at the test project; sign for Sandbox; sign in a Sandbox tester.
2. Buy `com.legendstudy.essay.credit3` → expect `granted`; `credit_summary.spendable` +3, `paid` +3.
3. Repeat the same transaction → `already_processed`, balance unchanged (idempotent).
4. Kill the app mid-flow → relaunch → `restorePurchases` settles exactly once.
5. Cross-account replay (different signed-in user) → `rejected` (account binding).
6. Inspect `credit_transactions` (type `purchase`, reason `iap_apple_v1`) + `postflight.sql` for audit.
7. Confirm paid-credit `expires_at` = purchase + 3 months.

## Tests — actual results (2026-10-13, local)
- `deno check` core.ts / index.ts / core_test.ts — PASS.
- `deno test core_test.ts` — **19 passed / 0 failed**, covering: sandbox gate on→granted+idempotent,
  gate off→pending, production unaffected, forged tx→rejected, unauthenticated→rejected, wrong
  SKU→rejected, and the fail-closed `sandboxGrantAllowed` matrix (flag off / wrong env / allowlist
  mismatch / unresolved ref / **production denylist**).
- **DB-level ledger test — EXECUTED and PASSED** against a local isolated pglite fixture (no cloud/
  production DB). Builder `supabase/verification/iap/local_fixture.mjs` constructs the canonical
  ledger prerequisites (real `essay_private.clock()` + `essay_private.credit_post_grant()` sliced from
  the migrations; minimal table DDL), then the **unmodified** `behavior.mjs` runs:
  `IAP canonical grant/replay/cross-account/SKU mismatch/role/ACL/expiry PASS (rollback)`.
  Covers: grant creation, ledger record (amount=3), replay idempotency (already_processed),
  cross-account reuse denied, wrong-SKU denied, service_role-only ACL (authenticated denied), paid
  3-month expiry, and failed-insert → no grant (trigger rollback, grant count unchanged).
  - Local setup used: `npm i @electric-sql/pglite@0.2.17`; `PGLITE_MODULE=<pkg>/dist/index.js`,
    `IAP_TEST_DB=<empty dir>`. Note: pglite 0.2.17 ships `dist/pgcrypto.tar.gz` but **not**
    `dist/contrib/pgcrypto.js`, which `behavior.mjs` imports via `PGCRYPTO_MODULE`; add a one-line
    wrapper mirroring a sibling contrib module (`{name:'pgcrypto',setup:()=>({bundlePath:new
    URL('../pgcrypto.tar.gz',import.meta.url)})}`) and point `PGCRYPTO_MODULE` at it. (pgcrypto's
    functions are not actually required — the RPC uses core `sha256`/`gen_random_uuid`.)
- **NOT covered by behavior.mjs** (reported, not claimed): the `credit_summary` read RPC itself (the
  ledger amount is asserted directly instead), and concurrent-request idempotency (single-connection
  pglite can't simulate it; the RPC's `pg_advisory_xact_lock` on the receipt hash is the mechanism).
  Production-flow regression is covered by the deno suite above.
- **NOT executed here**: a real Apple Sandbox purchase E2E — needs Apple Sandbox tester + the test
  project + store secrets (Owner). Mock/unit/DB-fixture passing is **not** reported as a real sandbox success.

## Not done (needs Owner)
- Provision the isolated test Supabase project + apply migrations + set test secrets + deploy.
- Apple Sandbox tester, Store API key/secrets, Apple root certs.
- Run `behavior.mjs` against the fixture DB; run the real sandbox purchase E2E.
- Production deploy of the updated Edge Function (separate approval).

## Guardrails honored
No production DB change, no production deploy, no activation, no prod secret change, no new external
Supabase project, no existing-user Credit change, no push, no Flutter payment-UI change, no Codex
essay/PDF change. Flutter client untouched (verified `git status lib/` clean). pdfium build blocker
tracked separately ([pdfium blocker](pdfium-build-blocker-2026-10-13.md)).
