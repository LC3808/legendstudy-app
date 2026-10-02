# PAYMENT APP foundation — Owner review package

Implemented/isolated verified, **NOT APPLIED**. TEST-only installation; LIVE and LAB are not deployed. Base APP cd215a6d88c0f72e59d06478bf4727ed676ca5f9. No remote DB connection or ledger inspection occurred; remote migration count is NOT_ASSESSABLE in this phase.

Migration: `20261003000100_payment_foundation.sql`
SHA-256: `77b460bf2bf437a8d6dd03d78454ece17c6c4143fe50d7f28b6ea30a51509c75`

[RPC contract](contract.md), [ownership allowlist](ownership.md), [isolated payment evidence](validation.json), [G1 Credit84](g1_validation.json), [Humanities/HQP102](legacy_validation.json), [Math regression](regression.json), [provider gate](provider-test.md).

## Exact scope

Owner provider-neutral amendment, pre-apply: provider TOSS/APPLE_IAP/GOOGLE_PLAY plus unique(provider,mode,provider_purchase_id). Current runtime remains Toss-only; no Apple/Google implementation. Previous hash is SUPERSEDED_PRE_APPLY; if any previous version was applied, STOP instead of replaying this file.

Three public payment relations: payment_orders, payment_operations, payment_events. One private configuration relation with TEST default. No wallet/balance table. Two public RPCs, two private helpers. Only existing-object change is the additive payment_purchase_spend_guard trigger on credit_transactions; existing Ledger columns/helpers/functions/ACL/RLS unchanged. No historic data backfill. No provider payload, buyer email/name/card, JWT or secret storage.

Indexes: unique owner/request key (retry), provider/mode/purchase identity (one verified purchase), grant_id (one purchase grant), operation request scope/provider idempotency (retry), one confirm/one pending/one successful cancellation (serialization), owner history (bounded lookup), pending reconciliation traversal, per-order events. No analytics indexes. Standard primary/FK support included as defined in migration; no speculative reporting indexes.

## Prerequisites and STOP

Owner must independently run [catalog.sql](catalog.sql) read-only. Verify required Credit G1 plus subsequent canonical owner/ACL changes, auth/profiles, essay_finance, essay_executor. ADR-2 allowed/lock_subject functions and their current essay_executor EXECUTE are required for activation; missing lifecycle fails closed. Do not implicitly apply ADR-2, provider005, day_targets or Math migrations. Math is regression coverage, not payment SQL installation dependency. Verify current remote ledger separately; new version must be absent and every new object absent. Unexpected ownership, schema CREATE, membership/ACL, collision or missing prerequisite: STOP. No broad db push or migration repair.

Expected deployer postgres NOSUPERUSER with existing CREATEROLE/BYPASSRLS and ADMIN-only essay_executor membership. Exact public schema ACL is captured/restored. Temporary SET+public CREATE initializes only payment_order and payment_process as essay_executor. No role creation, new permanent membership, existing function-owner changes or implicit service-role access. Review this explicit bootstrap with the whole package.

## Owner execution sequence — not performed

1. Review policy/contract, rollback constraints, prerequisite catalog, migration hash and current remote branch. STOP on any mismatch.
2. Separately authorize schema apply. Apply exactly this file once in its own transaction; never replay unrelated files. Capture local baseline catalog/count evidence before apply.
3. Run [postflight.sql](postflight.sql): correct owners, empty search_path, RLS ON, direct client CRUD none; authenticated only payment_order, essay_finance only payment_process. Verify all payment row counts0 and mode TEST. Compare existing ledger function/ACL/catalog evidence, and role/schema restoration.
4. Track only this exact version through the approved Owner migration process; no manual history insert or unrelated repair is supplied here. Verify ledger and exact source hash independently.
5. No functions/secret/scheduler deployment in this package. LAB implementation is a later task. Runtime must authenticate buyer before finance calls and independently verify Toss. Configure only TEST keys in approved server environment, never chat/Git/browser. Provider-only testing may proceed independently when keys are supplied; no Ledger use.
6. Before any hosted TEST flow verify least-privilege gateway capability, TEST isolation and provider integration. Public policy unchanged. LIVE is separately prohibited and requires the additional contract gates.

## Rollback / forward recovery

[rollback.sql](rollback.sql) refuses if ANY payment history exists, refuses unexpected dependencies (no CASCADE), and drops only these new objects/trigger. Empty-install rollback tested under non-superuser topology and restores existing functions/role/schema ACL. Never rollback once provider or user obligations exist; reconcile/forward-fix instead. Rollback does not undo provider operations and is NOT authorized for Production here.

## Verification and limitations

Run Python psycopg + PostgreSQL17 harnesses:

```sh
python tool/test_payment_foundation.py --pg-bin /path/to/postgresql17/bin
python tool/test_payment_legacy.py --pg-bin /path/to/postgresql17/bin
python tool/test_payment_g1.py --pg-bin /path/to/postgresql17/bin
python -m unittest discover -s supabase/validation/essay_lab_product -p test_g1_core.py
python tool/check_wiki_handoff.py
```

Unix-socket disposable DB only; network DSN unsupported. Auth shim models roles/auth.uid JWT claims; no real JWT gateway proof. Actual canonical migration/functions loaded, no fake Essay/Math table stubs. Production-equivalent non-superuser used for payment migration and rollback. Existing suites use their documented synthetic fixtures/privileged fixture setup. G1 keeps all84 assertions with only preinstalled-migration/v1-fixture setup adaptation. Math131 + runtime37 (C01–C30) + learning63 (L01–L40); Humanities/HQP102. Payment67 checks include bootstrap failures, atomic grant/cancel failure, real multi-connection confirm/cancel races, TEST isolation and detached-account cancellation.

No provider TEST, Storage, scheduler, remote Auth or Production verification claimed. LIVE provider-paid/ungranted deletion reconciliation, overdue paid outcomes, statutory exception authority, financial retention/privacy and deployment credential provisioning remain activation gates. General refund only, not a legal entitlement decision. The package is ready for Owner migration review and subsequent LAB coding, not Production or LIVE activation.
