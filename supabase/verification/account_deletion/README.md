# ADR-2 Owner review / application package

**LOCAL CANDIDATE; Production NOT_APPLIED. No action in this package has been executed on Production.**
Migration: [20261001000300_account_deletion_lifecycle.sql](../../migrations/20261001000300_account_deletion_lifecycle.sql).
SHA-256: `d7fa626d468e5c1d071a693f09f15fd4f34838db0f87b1a8acd1955dde6aa3b1`.
[Implementation](../../../wiki/account-deletion-14-day-implementation.md), [validation](validation.json),
[catalog](catalog.sql), [rollback](rollback.sql).

## Installation is not activation

1. Verify approved APP branch/commit and the hash with `shasum -a 256` on this one file.
   Verify the LegendStudy shared project, canonical chain through LSA-2C/HQP, all actual current personal-domain relations and storage policies.
   Last Owner-reported ledger snapshot:23; HQP20261001000200 tracked. This task did not query it again.
   Run catalog.sql read-only and compare prior function definitions/ACLs privately. Preflight must find no `account_private`, account RPC namespace, lifecycle table or either new executor role.
2. STOP for unexpected schema/helper body, role/name/version collision, unidentified project, unreviewed finance retention or missing cleanup inventory. Migration has no broad replay and fails on conflicts.
3. After separate Owner approval, SQL Editor executes **only this file** including its transaction. Never `db push` / `migration up` / all-pending replay. Candidate includes a5s lock timeout. Record unknown outcome and inspect before retrying. Installation defaults lifecycle OFF; ordinary signup remains legacy until explicit activation.
4. Compare catalog postflight: no new browser table grants; client RPC/worker roles below; intended restrictive policies and gates only. Existing ql/HQP DTO function bodies/signatures remain unchanged. is_quality_operator takes lifecycle precedence. Economic ledger fields remain immutable.
5. SQL application and migration tracking are separate. Only after verified exact schema/hash, Owner may use the existing explicit-version procedure:

   ```sh
   supabase migration repair 20261001000300 --status applied --linked --project-ref stlhijzpjfgwwdgunlsd
   ```

   Do not manually insert ledger rows. Verify only that version was added (23→24 only if preflight still23). Verify tracked SQL correspondence. Tracking failure does not justify SQL replay. provider005 stays unapplied; day_targets20260930000100 stays separately unregistered.
6. **Do not activate with SQL installation alone.** Review/fulfil the external gates below, deploy reviewed server/client boundaries separately, verify actual JWT/Storage/Auth behavior with separate authorization. This task performed no deployment or real-account deletion.

## Activation gates and exact runtime contract

- OFF by default at DB `account_private.dispatch_health.enabled`, Edge `ACCOUNT_LIFECYCLE_ENABLED`, and existing APP feature config. A separately approved owner activation changes only the DB singleton after prerequisites. The one-way DB guard forbids falling back to UUID-only legacy signup after marker-based grants begin. A later operational outage must not disable servicing existing requests.
- Server worker role is `account_lifecycle_worker` (NOLOGIN, no direct tables). Secure PostgREST role delegation / short-lived server worker credential must be provisioned and verified; migration does **not** grant this role to browser roles or provision/sign a token. The current `authenticator` role deployment setting must be explicitly reviewed. Do not substitute browser service_role.
- `account-deletion-worker/dispatch`: protected POST, server dispatch secret; schedule every5minutes. Independent monitor calls `account_deletion_health()` under worker role and alerts on heartbeat older10minutes, overdue>5minutes, expired leases/receipts. Neither alert acknowledgment nor transport success is required for erasure. Scheduler/monitor/transport deployment NOT_DONE.
- Worker server env names: SUPABASE_URL, SUPABASE_ANON_KEY, ACCOUNT_WORKER_JWT, SUPABASE_SERVICE_ROLE_KEY, ACCOUNT_DISPATCH_SECRET, ACCOUNT_BENEFIT_KEYS (version→base64 secret), ACCOUNT_RESTORE_KEY, ACCOUNT_RESTORE_KEY_VERSION, ACCOUNT_RESTORE_CHECKPOINT_URL, ACCOUNT_NOTIFICATION_URL, ACCOUNT_OPERATIONS_TOKEN, ACCOUNT_FINANCE_REVIEWED. No values are in Git. HMAC secrets >=32bytes. Separate restore secret/domain; retain old benefit-key versions so all supported versions are checked. Never silently rotate away a still-required prior key.
- `account-deletion-worker/benefit`: caller JWT independently verified by Auth; subject and verified identities server-derived. Body cannot choose subject/marker. State-only response, existing canonical Credit Ledger atomically grants3; failure503 leaves benefit unavailable, never blocks Auth account creation. The same dispatcher recovers up to20 verified eligible account benefits per run; optional immediate APP/LAB consumer wiring can call this endpoint. Client RPC recovers an already delivered grant and cannot create marker-less grants.
- Recent reauth: no access-token iat shortcut. A trusted, separately verified provider/session reauth adapter may call worker-only `account_reauth_attest(subject,session)` after a real challenge. The cancellation RPC requires same subject/session and a<=5minute ticket, consumes it, locks with worker claim and checks clock strictly before deadline. Provider adapter/UX is an activation gate; until then cancellation fails closed.
- Same verified identity during PENDING/ERASING: shared auth linking behavior + server `account_identity_blocked` must be exercised in actual Auth provisioning/re-entry integration. Never use user_metadata email as verified proof. Lifecycle markers are purpose-separated from benefit markers. Current Owner same-email observations are bounded evidence, not proof of every provider configuration. Apple relay/different verified identity is not probabilistically linked. Auth admission integration must pass before activation.
- Provider adapter currently returns **unknown**, not revoke success. Local cleanup/Auth deletion proceeds without waiting indefinitely for external revoke; ERASED means verified local erasure only. Receipt preserves provider_verified=false + bounded error/notification. Actual provider-side requirements/config/retry procedure are external gates, no credentials or tokens copied into lifecycle tables.
- Finance review gates phaseFINANCE. Current narrow detachment covers known signup/manual UUID reference formats and erased operator actor references; other live operators' attribution and opaque payment references remain unchanged. Unknown/custom references and paid retention need accounting/privacy review before activation. No statutory period is invented.
- Storage current registered namespace: profile-avatars/<subject>/*, supported API list/remove, bounded100 objects/batch20batches. Nested/unregistered paths fail closed, never silently skipped. Future personal buckets must register ownership+RLS+cleanup before launch. Actual bucket/policy enumeration and runtime deletion remain external verification.
- Protected restore checkpoint is outside the database restore domain; atomic current manifest replacement with bounded TTL, authenticated transport, freshness/ack monitoring. Include pending requests before deadline, completed obligations only through30day expiry, no permanent tag archive. Normal managed backup expiry is external; horizon>30days requires explicit review, no silent receipt extension. `restore.ts` blocks normal reopening when matching obligations remain; replay original intent/deadline or completed erasure on the isolated restored environment and verify before reopening. Operational replay/runbook execution is not performed here.

## Security matrix

| Object | PUBLIC/anon | authenticated | service_role | Internal authority |
|---|---|---|---|---|
| public.account_deletion_requests + six account_private tables | ALL NONE | ALL NONE | ALL NONE | postgres-owned; RLS ON; zero policies |
| account_service_allowed, account_deletion_request/status/cancel | EXECUTE NONE | EXECUTE, own auth.uid | NONE | postgres SECURITY DEFINER; empty search_path |
| other new public account_* functions | NONE | NONE | NONE | account_lifecycle_worker EXECUTE only; postgres definer, empty search_path |
| private helpers | NONE | NONE | NONE | postgres; narrow Essay allowed/lock/enabled + benefit_delivery SELECT only |
| finance detachment | NONE | NONE | NONE | dedicated NOLOGIN account_erasure_executor; limited finance UPDATE under strict immutable-field trigger |

The new finance role has RLS bypass solely to detach approved references; it has no client membership and no general erasure RPC authority. No runtime grants to browser service_role. Public material policies untouched. Existing client roles' table ACLs preserved, with restrictive lifecycle policies added to personal relations. Worker has no arbitrary raw-SQL/body/error channel.

## Verification / rollback

```sh
python3 tool/test_account_deletion.py --pg-bin /path/to/postgresql17/bin
python3 tool/test_account_deletion.py --pg-bin /path/to/postgresql17/bin --rollback-probe
deno test supabase/functions/account-deletion-worker/worker_test.ts supabase/functions/delete-account/handler_test.ts
./tool/flutterw test test/account_deletion_test.dart
```

Disposable Unix-only PG17; real canonical migrations/Essay/HQP fixtures. Auth shim supplies users/id/created_at/email_confirmed_at, uid and API roles/default privileges; not real JWT/identity linking proof. Storage/Auth transport tests are mocked, not runtimeverified. Tests accept no remote DSN.
Rollback is **pre-activation only**: refuses any lifecycle/benefit/reauth/opaque-grant data; restores exact prior helper bodies, drops only ADR-2 policies/triggers/new objects/roles, no CASCADE. Unexpected dependencies abort. Once active, forward recovery is required; never roll back to immediate deletion or repeat signup grants. Rollback never automatically repairs ledger.
