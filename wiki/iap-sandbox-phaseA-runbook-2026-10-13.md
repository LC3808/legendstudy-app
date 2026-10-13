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
- **credit_summary + concurrency — EXECUTED and PASSED** on a local throwaway real Postgres 17
  (no cloud/prod DB), via `supabase/verification/iap/pg_integration.mjs` (reuses the real
  `credit_summary`, `iap_post_verified_purchase`, `credit_post_grant` SQL):
  - **A credit_summary**: `spendable 0 → 3 (paid 3, free 0, other 0)` across a real grant, and the
    summary equals the canonical ledger sum (`== 3`). Uses the real read RPC — no separate balance calc.
  - **B true concurrency**: two **independent connections** race the same transaction →
    `["already_processed","granted"]`, exactly **one** grant row for the receipt, paid total 6
    (3 + one concurrent grant; the duplicate granted nothing). Exercises the RPC's cross-connection
    `pg_advisory_xact_lock` + unique `external_reference`.
  - Local setup: real Postgres (`initdb`/`pg_ctl`, `LC_ALL=C`, TCP 127.0.0.1, socket in `/tmp`),
    `npm i pg`, run with `PG_MODULE`/`PGHOST`/`PGPORT`/`PGUSER`/`PGDATABASE`; stop + `rm -rf $PGDATA` to clean up.
  - Production-flow regression is covered by the deno suite above.
- **NOT executed here**: a real Apple Sandbox purchase E2E — needs Apple Sandbox tester + the test
  project + store secrets (Owner). Mock/unit/DB-fixture passing is **not** reported as a real sandbox success.

## Not done (needs Owner)
- Provision the isolated test Supabase project + apply migrations + set test secrets + deploy.
- Apple Sandbox tester, Store API key/secrets, Apple root certs.
- Run `behavior.mjs` against the fixture DB; run the real sandbox purchase E2E.
- Production deploy of the updated Edge Function (separate approval).

## Test project — pre-verification (READ-ONLY, 2026-10-13)
Owner created the IAP-only test project. Public identifiers only (no secrets recorded):
- **Test**: `legendstudy-iap-sandbox`, ref `kpqbedylxlyntrrfybpn`,
  `https://kpqbedylxlyntrrfybpn.supabase.co`, region ap-northeast-2, Postgres 17.11, ACTIVE_HEALTHY.
- **Production (do NOT touch)**: `LegendStudy`, ref `stlhijzpjfgwwdgunlsd`. (Also visible: Muselry —
  separate product; `legendstudy-payment-test` `wsnrwklplnunjktyfmbr` — an older payment test project.)

Read-only findings:
- **CLI**: v2.114.0, authenticated; **linked to NO project** (`supabase link` not run in this worktree;
  no `supabase/.temp`, no `project_id` in `config.toml`) — so no command can accidentally hit production.
- **Test DB initial state**: public/essay_private/account_private/payment_private schemas are **empty**
  (only the default Supabase `auth.*` system tables; `auth.users` rows=0). **Migrations: none.**
  **Edge Functions: none.** → clean project, **no migration conflicts expected**.
- **Sandbox gate accepts the test ref**: `projectRef('…kpqbedylxlyntrrfybpn…') = kpqbedylxlyntrrfybpn`;
  `sandboxGrantAllowed` = **true** with the test secrets, and **false** for the production ref even with
  the flag on (verified by running `core.ts` against the test URL). `verify-iap-purchase` has no
  `config.toml` entry → defaults to `verify_jwt=true` (matches deployed), no config change needed.
- **Flutter test-build defines** (`lib/core/config/app_config.dart`): `SUPABASE_URL`,
  `SUPABASE_PUBLISHABLE_KEY` (+ for Sandbox sign-in as needed: `APP_ENV`, `GOOGLE_OAUTH_ENABLED`/
  `GOOGLE_SERVER_CLIENT_ID`/`GOOGLE_IOS_CLIENT_ID` or `APPLE_OAUTH_ENABLED`).

## Isolated Supabase test project — preparation checklist (Owner creates the project; Claude prepared this)
Owner will create a **separate** Supabase test project and provide its ref; nothing below touches
production. The production project ref (`stlhijzpjfgwwdgunlsd`) is denylisted in code regardless.

1. **Settings after project creation** (collect, don't commit secrets): project ref, `SUPABASE_URL`
   (`https://<ref>.supabase.co`), anon/publishable key, service-role key (server-only).
2. **Canonical migration order**: apply `supabase/migrations/*.sql` in ascending filename order
   (`20260912… → 20261009000200_iap_verified_credit`) to the test project (CLI `supabase db push`
   or SQL editor). Includes the credit ledger + `iap_post_verified_purchase`.
3. **Verify ledger/RPC**: run `supabase/verification/iap/postflight.sql` (read-only) and confirm
   `iap_post_verified_purchase` is service_role-only (anon/authenticated `has_function_privilege` =
   false). Optionally run `pg_integration.mjs` against a local mirror for summary/concurrency.
4. **Edge Function deploy**: deploy only `verify-iap-purchase` to the **test** project
   (`supabase functions deploy verify-iap-purchase`). Do not deploy to production.
5. **Sandbox Secret list** (test project Edge secrets): `IAP_ENABLED=true`,
   `IAP_ALLOW_SANDBOX_GRANT=true`, `IAP_APPLE_ENVIRONMENT=Sandbox`, `IAP_SANDBOX_PROJECT_REF=<test ref>`,
   `IAP_APPLE_PRIVATE_KEY`, `IAP_APPLE_KEY_ID`, `IAP_APPLE_ISSUER_ID`, `IAP_APPLE_BUNDLE_ID`,
   `IAP_APPLE_APP_ID`, `IAP_APPLE_ROOT_CERTIFICATES_BASE64` (`SUPABASE_URL/ANON_KEY/SERVICE_ROLE_KEY`
   auto-injected). Secrets entered only in the dashboard/CLI — never in code/Git/Wiki.
6. **Production misconnection prevention**: `IAP_SANDBOX_PROJECT_REF` must equal the test ref and
   must not be the production ref; the code denylists the production ref (fail-closed) and gates on
   `SUPABASE_URL`'s own ref; keep production's `IAP_ALLOW_SANDBOX_GRANT` unset. Use the test
   project's own keys only (mismatched prod keys fail-closed to `pending`).
7. **Test Flutter build** (points the app at the test project):
   `flutter build ios --debug --dart-define=SUPABASE_URL=https://<test-ref>.supabase.co
   --dart-define=SUPABASE_PUBLISHABLE_KEY=<test anon/publishable key>` (match the app's config keys),
   signed for a Sandbox tester. Do the Sandbox purchase with that build.
8. **Teardown**: delete the test project's Edge secrets, undeploy/disable the function, and delete or
   pause the test project. No production artifact is created or changed at any point.

## Guardrails honored
No production DB change, no production deploy, no activation, no prod secret change, no new external
Supabase project, no existing-user Credit change, no push, no Flutter payment-UI change, no Codex
essay/PDF change. Flutter client untouched (verified `git status lib/` clean). pdfium build blocker
tracked separately ([pdfium blocker](pdfium-build-blocker-2026-10-13.md)).
