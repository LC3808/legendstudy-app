# PAYMENT-E2E-PREP-1 — independent Hosted TEST bootstrap

**Preparation ready; external installation/configuration NOT performed.** Only a new,
empty LegendStudy TEST Supabase project is eligible. No Production data, users, keys,
migration repair, broad `db push`, Storage, scheduler, AI or Toss calls. Do not run the
Python harness on Hosted: its Auth/platform fixtures are disposable-local-only.

## One canonical payment candidate

APP source revision **3b3b869297a0884bfb908c87977fa14519f72d91**.
`20261003000100_payment_foundation.sql` SHA-256
`77b460bf2bf437a8d6dd03d78454ece17c6c4143fe50d7f28b6ea30a51509c75`.
Old e4836eda / be808d96… is **SUPERSEDED_PRE_APPLY**, not another install option.
No migration bytes changed in PREP-1. Provider-neutral delta adds provider namespace,
renames the persisted purchase identifier, scopes uniqueness by provider/mode, adds
provider to DTO, and rejects unimplemented IAP adapters. Toss input remains bounded
at200; no change to Ledger posting, expiry, refund arithmetic, locks or TEST isolation.
The original60 assertions are retained plus7 provider cases. Fresh rerun: Payment67,
Essay Credit84, Humanities/HQP102, Math131+37+63. See parent evidence files.

## Exact allowlist

[manifest.json](manifest.json) is the machine-readable ordered **24-file** allowlist:
filename, SHA-256, prerequisite chain, deployer, required custom roles after each step,
and every new/changed function signature/owner/security/config/EXECUTE ACL.
It deliberately uses a conservative complete dependency chain, not guessed minimal SQL.
All application relations are postgres-owned; function exceptions are in the manifest.
Managed auth.users/auth.uid, anon/authenticated/service_role and extension facilities
are prerequisites, NOT supplied by our bootstrap. Read-only [preflight.sql](preflight.sql)
and parent [payment postflight](../postflight.sql) must run against the selected TEST project.

ADR-2 is an explicit **new TEST project dependency**, not permission to apply ADR-2 to
Production. day_targets is included only because ADR-2 cleanup requires its relations;
this does not repair Production tracking. provider005, avatar bucket, resource quota,
Math migrations are excluded. Math remains regression coverage, not payment prerequisite.
Never replay the allowlist against an existing project. Existing custom roles/objects or
unexpected owners/ACL are STOP conditions. No historical grants/learning data are imported.

Owner may execute each exact hash-verified file, in manifest order, once, using TEST
SQL Editor/approved migration runner with stop-on-error. Preserve each file's own
transaction; do not wrap all files or paste fixtures. Record applied filename/hash and
success locally. SQL Editor execution does not itself establish migration-ledger tracking;
use the approved exact-file tracking process separately, not `repair` or manual ledger SQL.
No ready-to-run remote apply command is supplied before project identity approval.

## Ownership and gateway

Deployer: postgres NOSUPERUSER, CREATEROLE, BYPASSRLS. Full24-file local PG17 run used
this identity from the first application migration, not only the final payment file.
Platform bootstrap alone used a local fixture administrator. No application migration
was superuser-applied. Managed Supabase grants/default privileges still need Hosted verification.

Final custom roles: essay_executor and account_erasure_executor NOLOGIN/BYPASSRLS;
essay_worker, essay_finance, account_lifecycle_worker NOLOGIN/NOBYPASSRLS.
Each automatic postgres membership: ADMIN=true, INHERIT=false, SET=false,
grantor=supabase_admin. Temporary SET/schema CREATE restored. Exact schema ACL and
finance EXECUTE inventory: [validation.json](validation.json). No new privileged role.

Payment RPC ownership/ACL stays [parent ownership.md](../ownership.md).
`essay_finance` can ALSO execute existing essay_admin_grant and essay_refund. It is a
trusted finance capability, **not payment-only**, and must be isolated to this empty TEST
project. No browser/service_role fallback, no signing key in Cloudflare. Server token
never inherits essay_executor. Disable all AI dispatch and do not provision worker JWTs.

Gateway enrollment is a separate Owner-approved TEST configuration step:
`GRANT essay_finance TO authenticator WITH ADMIN FALSE, INHERIT FALSE, SET TRUE;`
Verify postgres has ADMIN on essay_finance before this step; inspect authenticator role
and membership before/after. Preserve every existing platform membership. If managed
permissions reject the narrow grant, STOP; never impersonate supabase_admin or broaden roles.
No grant to anon/authenticated/service_role. Supabase Data API must expose public only,
not essay_private/account_private/payment_private. Revoke this specific enrollment to
stop new finance requests; reconcile any outstanding TEST obligations before teardown.

### Signing and finance JWT procedure — later Owner action only

Use the new TEST project's Authentication → Signing Keys. Managed private keys cannot
be extracted. Follow [Supabase custom signing-key/JWT procedure](https://supabase.com/docs/guides/auth/signing-keys):
generate an Owner-held ES256 key locally (`supabase gen signing-key --algorithm ES256`),
import into TEST signing configuration, activate per dashboard procedure. Store private
material outside repos in approved secret storage, not terminal/chat/log capture. Never
copy Production signing keys. CLI commands emit secrets: redirect privately with umask077,
not to this agent transcript. Verify current CLI help for key-file/expiry options.

After import/activation, save the exact single private JWK (with matching kid) in a
mode0600 file outside Git. The included offline tool avoids CLI key-selection ambiguity:

```sh
node supabase/verification/payments/hosted-test/mint-finance-token.mjs \
  /private/owner/test-signing-key.json /private/owner/finance-token.txt \
  <approved-test-project-ref> <synthetic-gateway-subject-uuid>
```

This future Owner command writes a new mode0600 file, never prints JWT, rejects the
Production project, pins ES256/essay_finance, issuer/audience and one-hour expiry. It does
not import keys or contact Supabase. Keep the private JWK offline; enter only bearer-file
contents into PAYMENT_FINANCE_TOKEN through the approved secret UI, then securely remove
the disposable token file after use. Rotate before expiry; no automatic refresh authority.
Publishable key goes in apikey, finance JWT in Authorization. Never mint from buyer input.
Local synthetic signature/claims/file-mode tests do not prove Hosted gateway admission.

### Mandatory Hosted gateway matrix

**HOSTED_VERIFICATION_REQUIRED**, not a local SQL-claims PASS:

| Probe to payment_process get on synthetic order | Expected |
|---|---|
| publishable key / anon | denied, no mutation |
| normal buyer authenticated JWT | denied |
| signed wrong role (essay_worker), no gateway membership | denied |
| expired finance JWT | rejected at JWT gateway |
| invalid-signature finance JWT | rejected at JWT gateway |
| valid short-lived finance JWT |200, correct TEST order, no Ledger mutation |
| same valid finance JWT to private helpers | inaccessible |

Local DB EXECUTE matrix PASS; hosted JWT signature/expiry, authenticator switching,
JWKS propagation and API-key routing cannot be established without the new project.
Do not report finance runtime PASS until all Hosted probes pass. Record status/category
only; no JWTs, signatures, subjects or order identifiers in public evidence.

## Synthetic Auth and profile

Use TEST Authentication email/password only. Owner creates/confirms a dedicated synthetic
buyer through normal signup/email confirmation (or managed Auth user admin UI), with
an Owner-controlled mailbox/password. Do not SQL INSERT auth.users. No OAuth config or
Production identity copy. Test-project login is a **different account/session**, even when
using the same Owner mailbox. Browser and payment runtime must both target this project.
Set approved Preview auth callback/reset URLs explicitly, no wildcard external origins.

LAB does not provision profiles on login. After authentication create the synthetic profile
through the existing authenticated owner RLS path: public.profiles INSERT of only
`id = session.user.id` and optional synthetic display_name; no authority in user-editable
metadata. Existing profile insert privilege and owner policy govern it; do not disable RLS.
Do this once through the authenticated Supabase client/REST, then verify own read and
foreign denial. Missing benefit marker leaves signup benefit ungranted; account/profile
creation must still succeed. No signup marker secret is required for TEST payment.
Never insert paid grants to prepare a test purchase. Support test subject may be this
buyer (cancel API requires support allowlist AND order ownership). Gateway subject is separate.

## Owner execution order and aborts

1. Approve creation of an independent **empty Hosted TEST** Supabase project (PG17),
   no database/user backup restore. This phase has not created it.
2. Run preflight; compare platform role/default ACL/extension topology with manifest.
   STOP on mismatch. Confirm URL differs from Production and record only sanitized evidence.
3. Hash-check and apply24 allowlisted files in order. STOP at first failure; no skip/repair.
   Run parent catalog/postflight; TEST mode, zero payment rows, RLS/ACL/owners exact.
4. Enroll gateway and configure TEST signing keys; run all gateway matrix probes.
   Configure synthetic Auth/profile as above. Token secrets never go to chat.
5. Configure isolated approved Cloudflare Preview scope using LAB's updated handoff.
   Build browser vars and runtime payment vars must point to the **same TEST project**.
   Do not share finance bindings with unreviewed Preview branches; use a dedicated Pages
   test project if branch access cannot be isolated. No main/Production release in this step.
6. Authorize Preview deployment separately, check auth, order/status and no secret in assets.
7. Only after explicit leglabn24k E2E approval: merchant TEST checkout/confirm/duplicate
   refresh/reconcile/support cancellation; verify TEST_RECORDED and zero spendable delta.
8. Leave LIVE disabled. Resolve all provider TEST outcomes before decommissioning.

Abort before data: stop setup; payment-only empty rollback is tested. Whole fresh TEST
project disposal/recreation needs Owner approval; no broad rollback through dependent
ADR/HQP/finance objects. After payment/provider obligations: preserve history and forward
reconcile. Package includes no permission for destructive remote cleanup.

## Evidence and remaining gates

Local fresh24 installation, exact payment rollback, injected end-transaction failure
restoration, postflight, membership/schema ACL and DB EXECUTE checks PASS. Existing
payment failure/concurrency tests and Essay/HQP/Math regressions separately rerun.
Actual Hosted Auth, signing/gateway, SMTP, dashboard ACL, cloud Preview config and merchant
E2E remain HOSTED_VERIFICATION_REQUIRED. Storage/provider/AI are outside this test bootstrap.
PRODUCTION_WRITES=0; EXTERNAL_CONFIG_CHANGES=0; merchant provider calls0 in PREP-1.

## PAYMENT-E2E-HOSTED-COMPAT-1 — 2026-10-03

Local compatibility PASS; ready to resume HOSTED-1, **not a Hosted installation PASS**.
Owner-reported Hosted preflight remains empty (0/24 applied). This task made no Hosted,
Production, Finance gateway, Cloudflare or Toss changes.

Root cause: PREP-1 introduced `ALTER SCHEMA public OWNER TO postgres` as fixture setup.
Git history records no canonical prerequisite requiring it. That normalization hid the
actual PG17/Hosted `pg_database_owner` ownership and ACL grantor. The correction removes
that fixture statement; no migration SQL or manifest bytes changed.

[Observed platform](observed-platform.json) captures sanitized Owner-supplied role,
membership, schema/default ACL evidence. Local-only `tool/payment_hosted_fixture.py`
reproduces and compares those catalogs before installation. Managed extensions and real
Auth/JWT gateway runtime are not emulated. Do not execute the fixture on Hosted.

Fresh PG17.11: all 24 hash-verified files applied in order by non-superuser postgres;
per-file function owner/security/search_path/ACL inventory matches the existing manifest.
Final public owner/grantor stays `pg_database_owner`; only canonical grants are added.
Managed memberships are preserved; custom ADMIN-only memberships and RLS/EXECUTE pass.
No Finance gateway membership is enrolled by this compatibility test.

Payment postflight, TEST isolation and empty-install rollback PASS. Six injected failures
(after temporary SET, schema CREATE, SET ROLE, first public function setup, RESET ROLE,
and before COMMIT) restore exact function definitions/owners/ACL/config, relation
ownership/RLS, memberships, schema/default ACL; no partial payment namespace survives.
[Validation evidence](validation.json) records the topology and failure checkpoints.

Separate existing regression suites rerun: Payment67, Essay Credit84 + static7,
Humanities/HQP102, Math persistence131 + runtime37 + learning63: all PASS. Those suites
retain their existing synthetic fixtures; the full observed platform comparison belongs
to the fresh 24-file bootstrap run, not a claim of managed Auth/extension equivalence.

Next: resume the separately authorized HOSTED-1 exact-file process against the preserved
empty TEST project, starting with fresh read-only preflight. No schema-owner/ACL workaround
is required. Managed gateway/config and merchant E2E remain later verification gates.

## PAYMENT-E2E-HOSTED-1 — actual Hosted bootstrap, 2026-10-03

**24/24 installed and Hosted postflight PASS.** [Actual Hosted evidence](hosted-validation.json) is separate from [local compatibility evidence](validation.json). Fresh project identity/empty-state preflight and observed role/schema/default ACL comparison passed. Each exact hash-verified allowlisted file ran separately as postgres through the existing authenticated CLI Management API; each file's function inventory matched the manifest. No canonical SQL changed.

Final114 functions have exact expected owner/security/search_path/EXECUTE; no unexpected application functions. All application relation owners are postgres. Public schema remains pg_database_owner with pg_database_owner ACL grantor; schema ACL matches the local compatibility result. Five custom memberships are only postgres ADMIN=true/INHERIT=false/SET=false; no authenticator→essay_finance enrollment. Payment RLS/direct-CRUD denial/EXECUTE matrix and TEST configuration pass. Orders/operations/events, credit accounts/grants/transactions and Auth users all0. Spendable Credit delta0. No synthetic orders or financial RPCs invoked.

SQL installation is verified; migration ledger tracking is **NOT_CREATED** (`supabase_migrations.schema_migrations` absent). Do not interpret24/24 as CLI migration-ledger tracking or later run broad db push. No repair/manual ledger writes performed. Any future tracking process needs its own exact-file authorization.

Production untouched; Finance gateway/signing/JWT/token, Cloudflare and Toss remain unconfigured/not run. Ready for separately authorized Finance gateway setup. STOP after bootstrap/postflight; merchant E2E and LIVE remain outside this result.
