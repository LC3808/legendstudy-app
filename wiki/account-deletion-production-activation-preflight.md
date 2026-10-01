# ADR-2P — Production activation preflight

## ADR-2D current ownership successor

[Ownership correction](account-deletion-ownership-compatibility.md): local non-superuser
apply/rollback verified; 112 lifecycle +17 ownership checks PASS. Failed ADR-2C Production
attempt fully rolled back/untracked. Its hash `b815b4d82ddf14c33f22be64f44a21666918787e9466f097f858c5b4b5844ff7` is
SUPERSEDED_PRE_APPLY_FAILED_ATTEMPT. New hash `38c86fd79554225fbc6a5a30be791c860e6c89dcaa64ad7e229e3710b9a29d94`.
Owner review READY; Production retry/general activation NOT_AUTHORIZED. Prior ADR-2C/2P
sections below remain historical; use the current Owner package for any future review.


## ADR-2C targeted recheck — current readiness

[Correction closeout](account-deletion-14-day-implementation.md#adr-2c-narrow-correction--owner-policy-accepted)
supersedes the historical findings below: **P-01 RESOLVED; P-02 PARTIAL_EXTERNAL_GATE;
P-03 RESOLVED** under accepted Owner privacy-first/no-global-hold policy.
CODE_CORRECTION_REQUIRED: NO within the reviewed narrow scope.
READINESS_CLASSIFICATION: **READY_FOR_STAGED_PRODUCTION_APPLY** for default-OFF schema
installation after Owner approval; ACCOUNT_DELETION_GENERAL_ACTIVATION: **NO**.
SCHEMA_INSTALL_IS_DORMANT: PARTIAL — reviewed helper/RLS gates change immediately, but
OFF preserves ordinary signup and accepts no lifecycle requests. Do not enable DB/Edge,
connect admission hooks or release clients before the documented external gates pass.
Read-only recheck2026-10-01: ledger23, version20261001000300 absent, lifecycle table absent;
provider005 remains absent; day_targets tracking remains separate. Other detailed catalog
anchors below are the prior ADR-2P snapshot, not a freshly rerun full catalog audit.
Current hash: `b815b4d82ddf14c33f22be64f44a21666918787e9466f097f858c5b4b5844ff7`. Original hash below: SUPERSEDED_PRE_APPLY.
Correction adds only capture-state metadata and one worker-only RPC to the existing
candidate: total7 new tables /34 new functions (24public+10private), no new migration.
111SQL/48Deno/7Flutter PASS; rollback preservation/refusal PASS. No Production writes.
The [Owner package](../supabase/verification/account_deletion/README.md) is review-ready.
Remaining runtime gates: provider reauth/admission, secrets/role delegation, backup replay,
finance, Storage, scheduler/notification, client UX and separately authorized live checks.
No apply/deploy authorization is implied. Original historical review follows unchanged.

## Original ADR-2P snapshot

2026-10-01 · READ-ONLY PRODUCTION REVIEW / DOCUMENTATION ONLY.
Reviewed implementation: `4f92b58c967895de3769236e0cc5c2698d2b509b`, canonical
`codex/essay-scaffolding-vnext`; local HEAD, origin and actual remote matched, 0/0.
Untracked `supabase/.temp/` preserved. No credential file, JWT sign-in, provider,
Auth deletion, Storage deletion, application write, SQL apply, tracking repair or
deployment was performed. Unified Wiki and LAB were not modified.

**READINESS_CLASSIFICATION: CORRECTION_REQUIRED. GENERAL ACTIVATION: NO.**
The schema can be installed with lifecycle OFF after separate Owner approval and
fresh postflight planning; it is not entirely dormant. This is not approval to
install the current package before reviewing the findings below. Its future restore
contract needs correction. Existing local test results remain historical evidence,
not proof of Production lifecycle execution.

Sources: [ADR-1](account-deletion-14-day-architecture.md),
[ADR-1B](account-deletion-erasure-retention-boundary.md),
[implementation](account-deletion-14-day-implementation.md),
[privacy history](account-deletion-privacy.md),
[Owner package](../supabase/verification/account_deletion/README.md),
[validation](../supabase/verification/account_deletion/validation.json),
[catalog](../supabase/verification/account_deletion/catalog.sql),
[rollback](../supabase/verification/account_deletion/rollback.sql).

## Evidence and Production snapshot

Supabase CLI Management API: functions list, secret **names only**, backups metadata,
and `db query --linked --project-ref stlhijzpjfgwwdgunlsd` with explicit
`BEGIN READ ONLY` / SELECT catalogs / COMMIT. No lifecycle/helper RPC was invoked.
No backup contents, cron command bodies, user identifiers or Storage object names
were printed or committed. Names and aggregate namespace exception count suffice.
No fresh provider-console or installed mobile-binary inspection was performed.

| Check | Actual read-only observation |
|---|---|
| Ledger | **23** versions; latest `20260929000400`, `20261001000100`, `20261001000200` |
| ADR-2 `20261001000300` | ABSENT; expected count after exact installation/tracking is24 only if preflight remains23 |
| Unrelated versions | provider005 absent; day_targets `20260930000100` absent and separate |
| Day-target effect | anon NONE; authenticated SELECT/INSERT/UPDATE/DELETE, independently rechecked |
| Collisions | No account_private schema, account_deletion_requests, public account_* functions, either new role, account_* triggers or lifecycle restriction policies |
| Prerequisites | Required current Auth confirmation column, Essay/credit/profile/learning/feedback/HQP columns and FKs inspected; six existing roles present |
| Dynamic replacement anchors | Quality, Essay owner/lock_job/grant, Mock fetch/submit: all six present in live definitions |
| Rollback preimages | All seven stored canonical function bodies match live after surrounding whitespace normalization; definition hashes alone differed because formatting is not semantic drift |
| HQP | Both tables RLS ON, policies0, postgres-only ACL; E1 evaluation CASCADE, findings CASCADE, E2 reviewer SET NULL |
| Quality authority | quality_operators RLS ON/policies0; service SELECT/INSERT/DELETE only; browser table CRUD NONE |
| Quality functions | All five ql RPCs and helper postgres-owned, SECURITY DEFINER, empty search_path, authenticated EXECUTE, no PUBLIC/anon/service EXECUTE |
| Edge deployment | Only neis, process-feedback-notifications and resource-resolver listed; **delete-account and account-deletion-worker NOT_DEPLOYED** |
| Scheduler | pg_cron exists; one active unrelated job; zero account-deletion jobs by command-pattern metadata check. No external scheduler inventory claimed |
| Storage | One private bucket, profile-avatars; owner policies exact `<subject>/avatar.png`; zero objects outside current flat owner namespace in aggregate check |
| Secrets | No ACCOUNT_* names present in Edge secret inventory; platform SUPABASE_* names exist, values not read |
| Backup | Seven available backup records, PITR false; response does not establish contractual maximum restore horizon. UNKNOWN, not “seven-day retention” |

`PRODUCTION_MIGRATION_PREFLIGHT: PASS` means inspected catalog prerequisites,
anchors and absence/collision checks pass; no migration was dry-run on Production.
`FINANCE_SCHEMA_COMPATIBILITY: PASS` has the same catalog-only scope. No claim of
live worker, client or destructive erasure compatibility follows from these PASSes.

Canonical migration:
[20261001000300_account_deletion_lifecycle.sql](../supabase/migrations/20261001000300_account_deletion_lifecycle.sql).
SHA-256 independently matches committed bytes and validation record:
`d7fa626d468e5c1d071a693f09f15fd4f34838db0f87b1a8acd1955dde6aa3b1`.

Pre-install public table ACL fingerprint (MD5, comparison only):
`20620d73cca1b1daf8b129817bf99b04`; public policy text fingerprint:
`d7e82aeb8dc1c3d1b3093c4ce29b8bb4`. Policy fingerprint must change for intended
restrictions; full table ACL fingerprint changes for new tables/new finance role.
Compare existing client-role ACL entries separately, not global hash equality.

## Findings requiring narrow follow-up — NOT IMPLEMENTED

**P-01 / HIGH — Restore cancellation and intent replay is incomplete.**
`account_deletion_cancel` retains a CANCELLED request but
`account_deletion_restore_manifest` filters only PENDING/ERASING/ERASED.
[restore.ts](../supabase/functions/account-deletion-worker/restore.ts) rejects CANCELLED
and returns only `subjectsToErase`, including not-yet-due PENDING subjects.
A snapshot before a successful cancellation can restore a pending request; the latest
manifest omits its cancellation, so this helper alone can permit reopening without
neutralizing that obsolete request. Conversely its result cannot tell a replay
consumer to restore pending restrictions rather than erase before the deadline.
No executor is currently deployed, so this is an activation/restore-contract flaw,
not evidence of an actual deletion. Correction: bounded authoritative cancellation
reconciliation and typed original-deadline actions, with pre/post-cancellation and
not-yet-due restore tests. Do not extend receipt retention silently or add a permanent
identity registry. External backup policy alone does not fix the missing semantics.

**P-02 / activation implementation gap — reauth/admission integrations are absent.**
Repository search finds no production caller of worker-only `account_reauth_attest`
or `account_identity_blocked`. The client cancellation button only invokes cancel;
it does not perform a challenge. The SQL ticket check is fail-closed and sound as a
contract, but account-deletion GA cannot promise usable cancellation yet. Similarly,
a blocker predicate alone cannot prevent a new Auth subject during ERASING after
Auth deletion and before verified completion. Implement/review narrow trusted
adapters separately; provider configuration is an additional external gate, not
proof the adapters exist. Do not weaken the checks or use admin cancellation.

**P-03 / bounded identity coverage gate — erasure depends on marker inputs.**
`server.ts bindAndCheckpoint` runs before PERSONAL; `markers()` rejects no verified
email/supported provider subject, or more than16 key-version/input combinations.
The request RPC itself does not enforce that coverage. Such an admitted account
can remain retrying ERASING without reaching personal cleanup. Existing account
identity coverage was not queried; no current affected user is alleged. Before
activation prove coverage for every supported account and rotation, or separately
correct the erasure prerequisite so unavailable promotional identity cannot cause
unbounded content retention. Signup-benefit failure must remain fail-closed without
blocking ordinary account creation. This is not authorization to collect new identity.

No migration, function, Flutter, test or configuration file was changed to address
these findings. ADR-2's97 SQL/21 mocked/7 Flutter PASS record is preserved; those
checks do not close P-01/P-02/P-03 or actual gateway/deployment gates.

## Exact migration blast radius

| Category | Candidate change |
|---|---|
| New public table | account_deletion_requests |
| New private tables | benefit_claims, benefit_delivery, reauth_tickets, lifecycle_identity_blocks, restore_tags, dispatch_health in account_private |
| New roles/schema | account_private; account_lifecycle_worker NOLOGIN/NOBYPASSRLS; account_erasure_executor NOLOGIN/BYPASSRLS with narrow finance rights |
| New public functions (23) | account_service_allowed; account_deletion_request/status/cancel; account_reauth_attest; account_benefit_claim/candidates/record_existing; account_deletion_claim/personal/advance/retry/finish/maintenance/provider_result/bind/unbound/notifications/notification_ack/restore_manifest/postconditions/health; account_identity_blocked |
| New private helpers (10) | enabled, lock_subject, allowed, guard_request, personal_write_gate, fenced, finance_privacy_guard, detach_finance, caller_write_gate, activation_guard |
| New explicit indexes (6) | account_deletion_one_active, account_deletion_due, account_deletion_expiry, account_deletion_lease, account_deletion_subject, account_lifecycle_identity_lookup; plus table PK indexes |
| Existing function changes (9) | is_quality_operator; essay_private.uid/owner/lock_job/credit_post_grant/credit_profile_signup; essay_claim_signup_credit; fetch_own_mock_attempt; submit_mock_attempt |
| New triggers | account_deletion_immutable; account_activation_one_way; account_lifecycle_statement + account_lifecycle_write on nine personal parent tables listed below |
| Replaced triggers | credit_grant_terms_frozen and credit_ledger_no_update now call narrow finance_privacy_guard; economic fields still immutable |
| Existing table columns/FKs | No existing column/FK alteration. Existing relations gain policies/triggers/limited finance-role grants |
| New FKs | lifecycle subject→Auth SET NULL; benefit_delivery/reauth subject→Auth CASCADE; delivery grant→credit_grants RESTRICT; identity blocks/restore tags→request CASCADE |
| New RLS | All seven new tables RLS ON, zero policies; restrictive authenticated policies on24 existing public personal tables and storage.objects |
| New grants | Four client account RPCs authenticated EXECUTE; remaining public account RPCs worker EXECUTE; Essay executor private usage/three helper EXECUTE + benefit_delivery SELECT; finance executor SELECT accounts, SELECT/UPDATE grants/transactions |
| Revokes | All new tables/functions PRIVATE/PUBLIC client defaults cleared for PUBLIC, anon, authenticated, service_role; only above narrow regrants |
| ql/HQP | ql-read-v1 and HQP function bodies/signatures/table structure unchanged; shared is_quality_operator intentionally gains lifecycle precedence and VOLATILE lock-aware behavior |

Nine parent tables: profiles, feedback_submissions, bookmarks, recent_views,
day_targets, study_sessions, mock_exam_attempts, student_target_universities,
essay_practice_sessions. Restrictive policy list also includes mock_exam_answers,
essay_drafts/attempts/evaluations/evaluation_dimensions/improvement_items/
improvement_progress/evaluation_evidence/generated_rewrites/learning_events/
ai_processing_runs and credit_accounts/grants/transactions/essay_billing_decisions.
Storage restriction applies only profile-avatars; public guest content is unchanged.
No HQP RLS redesign, credit-balance duplicate, provider005 or day_targets tracking work.

## Installation versus activation and signup cutover

**SCHEMA_INSTALL_IS_DORMANT: PARTIAL.** No lifecycle or benefit rows are seeded;
only dispatch_health singleton OFF is inserted. No scheduler or Edge deployment occurs.
However gates/locks/helper replacements, restrictive RLS and finance UPDATE guard
changes take effect immediately. Existing valid non-deleting subjects should retain
access; absent Auth subjects are immediately rejected. Live behavior is not tested here.

With DB enabled=false, existing profile signup trigger and signup-credit RPC retain
the legacy UUID-based3-credit path; no HMAC secret required for installation. No
credits are retroactively granted by migration. No new client/server needed merely
to leave OFF, and the current old immediate endpoint is absent. Prerequisites: fresh
catalog/anchor confirmation, reviewed intended behavior/rollback preimages, Owner
approval, OFF state verified, all user activation/deploy flags remain OFF.

At **DB enabled=true**, profile signup no longer creates the grant; RPC only returns
a previously delivered grant or NULL. Worker /benefit or scheduled candidate recovery
must deliver it. This flag is one-way and couples deletion requests with benefit
cutover. Missing secret/config makes worker unavailable; account creation remains
allowed, free benefit **DO_NOT_GRANT_YET**. Existing economic balances persist, but
claim callers must tolerate NULL; prior users must not be told a new grant succeeded.
There is no independently switchable benefit-only/deletion-only DB activation flag.
Do not enable it for a scheduler experiment. Legacy signup is a pre-activation
compatibility period, not permission to enable deletion without anti-repeat protection.

`BENEFIT_SECRET_NAME: ACCOUNT_BENEFIT_KEYS` (version→base64 key map, >=32byte keys).
Consumed only by worker runtime, never migration/client. Required before migration:NO;
before a disabled deploy:NO; before functional worker or benefit activation:YES.
Retain old versions for lookup/rotation; input count×key versions<=16. Inputs are Auth
verified email lower/trim and supported provider subjects; no plain email hash, raw
email storage or universal identity. The caller cannot admit its own marker; only
worker role can invoke the atomic claim RPC. Production secret NOT_PROVISIONED by
this task, and name absent in inventory.

## Runtime gates

| Gate | Finding / required evidence |
|---|---|
| Recent reauth server | IMPLEMENTED ticket contract; same auth.uid/session_id, <=5minutes, row/subject lock, strict before deadline; not access-token iat |
| Email / Google / Kakao / Apple reauth | All EXTERNAL_GATE plus missing trusted adapter/consumer wiring (P-02); existing login code is not challenge attestation |
| Disabled deployment | Safe to leave cancellation fail-closed while feature itself remains unavailable; not acceptable to advertise working cancellation to real pending users |
| Storage coverage | COMPLETE_FOR_CURRENT_SCOPE: private profile-avatars/<subject>/*; client currently exact avatar.png, no current Essay/user upload namespace found |
| Storage permissions | NOT_ASSESSABLE at runtime; privileged list/remove/absence verification mocked only. Current owner RLS verified; no destructive call made |
| Future Storage | Explicit owner namespace registration + cleanup/RLS required; nested/unregistered paths fail closed |
| Finance | Economic terms, ledger/reversal IDs and settled consumption preserved; reserved/authorized release reuses canonical release once before session erase |
| Finance detachment | IMPLEMENTED for known signup/manual references and erased operator attribution. Paid/custom opaque references not proven non-personal; external retention confirmation OPEN |
| Backup horizon | UNKNOWN; seven listed copies/PITR OFF do not prove max restorable age.30day receipt coverage NOT_ASSESSABLE |
| Restore | PROCEDURE_ONLY plus local helper; no replay executor/deployed checkpoint. P-01 correction and restore drill required; do not reopen on missing/stale inventory/checkpoint |
| Provider revoke | Actual entrypoint adapter returns false for all providers; local erase may continue, false is retained as unknown, never success |

| Provider | Local revoke adapter | Revoke config name known | Production config verified | Runtime revoke verified | Gate |
|---|---|---|---|---|---|
| Google | NO (unknown stub) | NO dedicated contract | NO | NO | OPEN |
| Kakao | NO (unknown stub) | NO dedicated contract | NO | NO | OPEN |
| Apple | NO (unknown stub) | NO dedicated contract | NO | NO | OPEN; existing Apple deletion release gate remains |
| Email | No external OAuth revoke operation | N/A | Auth runtime not tested | NO | Auth Admin deletion/session invalidation verification |

OAuth login client IDs/settings are not proof of a revoke adapter or credential.
No live provider configuration/secret value was requested. No new legal retention
period or provider compliance claim is made. Analytics retention remains separate.

## Deployment order, worker and observability

Current endpoint absence means immediate-delete runtime risk **NONE in the inspected
project snapshot**; not a guarantee about an old binary or future deployment. Old
handler in pre-ADR2 Git ignores body and deletes on POST. Never redeploy it: a new
client automatically sends status on screen entry and would be unsafe against it.

Current new handler requires explicit JSON operation; old empty-body client receives
400 (or disabled503), **no deletion request**. OLD_CLIENT_WITH_NEW_BACKEND:PARTIAL
(safe denial, no working legacy UX). NEW_CLIENT_WITH_OLD_BACKEND:UNSAFE if old handler
were deployed; currently endpoint absent, so unavailable. MIXED_VERSION_SAFE:
CONDITIONAL on new server first and old artifact excluded from every rollback.

Sequence: resolve corrections/gates → approved OFF schema + exact tracking → deploy
new server/worker disabled → verify role/auth/runtime boundaries without dispatch →
validate reauth/admission/checkpoint/finance/Storage → prepare lifecycle-aware APP
with flag OFF → make monitoring/scheduler ready → coordinated activation → explicit
synthetic request/cancel acceptance → broader UI availability. Scheduler must be
servicing obligations before general user requests are accepted, not14days later.

Owner-only future commands (NOT EXECUTED; from approved APP checkout):

```sh
supabase functions deploy delete-account --project-ref stlhijzpjfgwwdgunlsd
supabase functions deploy account-deletion-worker --project-ref stlhijzpjfgwwdgunlsd --no-verify-jwt
```

Never omit function name or use --prune. Worker /dispatch uses its own non-JWT bearer
secret, so gateway JWT verification must not reject that credential before the handler.
/benefit independently verifies Auth JWT. The deploy flag disables only gateway
validation, not these handler checks; review both with negative auth tests. For
new delete-account, actual project JWT/signing-key compatibility must be verified;
it forwards caller JWT to PostgREST, never substitutes service-role identity.

Worker names: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY,
ACCOUNT_WORKER_JWT, ACCOUNT_DISPATCH_SECRET, ACCOUNT_BENEFIT_KEYS,
ACCOUNT_RESTORE_KEY, ACCOUNT_RESTORE_KEY_VERSION, ACCOUNT_RESTORE_CHECKPOINT_URL,
ACCOUNT_NOTIFICATION_URL, ACCOUNT_OPERATIONS_TOKEN, ACCOUNT_FINANCE_REVIEWED,
ACCOUNT_LIFECYCLE_ENABLED. Delete-account uses URL/anon key/lifecycle flag only.
Worker config failure returns503. Worker JWT must assume account_lifecycle_worker
through explicitly reviewed authenticator delegation; migration does not provision
that membership or sign a credential. No browser service_role or secret disclosure.

No selected scheduler deployment artifact exists. Intended mechanism: protected
external/server HTTP scheduler, POST account-deletion-worker/dispatch every5minutes,
Bearer ACCOUNT_DISPATCH_SECRET. pg_cron/net already exists but an unrelated job is
not authority to copy its secret/command. Owner must choose/review exact scheduler
and independent watchdog deployment; this is an OPEN deployment gate, not READY.
With schema OFF/no requests it can stay disabled. Once requests exist, disabling
scheduler indefinitely would violate their obligations.

Minimum signals: pending, due-unclaimed, ERASING, expired leases, retry counts/phases,
overdue original deadline, ERASED count, expired receipts, pending notifications,
heartbeat freshness. Existing health RPC exposes enabled/overdue/expired receipts/
expired leases/heartbeat_stale; maintenance/notification functions have additional
counts but **must not be used as read-only probes**. Owner read-only aggregate SQL
can cover remaining lifecycle counts. No deployed independent monitor, notification
transport or delivery-error counter is established. Notification_pending is backlog,
not proof of transport failure; monitor transport failures separately, sanitized.
MINIMUM_ACTIVATION_OBSERVABILITY:PARTIAL; blocks scheduler activation:YES.
Alert payload: counts, phase/error category, age; no contact/content/subject identifiers.
Heartbeat older10minutes or overdue>5minutes is incident delay, never grace extension.

LAB: no code change required before migration or backend security enforcement.
is_quality_operator precedence denies a pending operator across ql/HQP. This is
sufficient for new server access security; already fetched browser data is not
retroactively erased. LAB restricted-session/cancel/cache UX is separate follow-up,
not an authorization bypass permission. No LAB file changed.

## Owner activation gate matrix — primary execution guide

All CAN_PROCEED_NOW entries assume later explicit Owner authorization; none authorizes
execution in this task. Overall package remains CORRECTION_REQUIRED.

| Action | REQUIRED_BEFORE | CAN_PROCEED_NOW | EXTERNAL_GATE | OWNER_ACTION | ROLLBACK_OR_ABORT |
|---|---|---|---|---|---|
| Migration install OFF | Review findings; fresh23/version/hash/catalog/anchors; no collisions; flags OFF | Technically conditional OFF install only; recommended wait for correction review | No benefit/revoke secret needed just for OFF schema | Exact single file, catalog, then exact tracking | Pre-data rollback only; never broad pending apply |
| delete-account deploy | Schema postflight; new artifact pinned; old excluded | Disabled only after schema | JWT gateway acceptance/config | Deploy named function with lifecycle flag false | Leave unavailable; never restore immediate handler |
| worker deploy | Schema, role delegation design, pinned artifact | Disabled only after schema | Worker JWT/config and protected transports for functional deploy | Named deploy; handler auth verification | Before obligations can disable; afterward preserve servicing |
| Benefit activation | Atomic claim acceptance, all supported identities/rotation, seed/recovery readiness | NO | Keys, role JWT, verified identity coverage | Review coupled one-way DB flag before enabling | No revert to legacy grants after activation |
| APP lifecycle UI | New backend proven; reauth/cancel UX; restriction/cache acceptance | NO user activation | Provider challenges/device acceptance | Release flag-off binary first; enable after system ready | Hide new request entry only; retain existing status/cancel |
| Scheduler activation | Corrections, complete worker/gates, monitoring/alerts/checkpoint | NO | Scheduler target/auth, independent watchdog | Enable5minute cadence with controlled activation | Never abandon accepted requests; forward recovery |
| Provider revoke activation | Provider-specific reviewed adapter | NO | Provider credential/config/requirements | Separate deployment/verification | Mark unknown, do not claim total cleanup |
| Destructive Production E2E | Explicit separate authorization; synthetic case336h, scheduler ready | NO | Dedicated approved identity/runtime | Natural full deadline, no bypass | No data restoration promise; forward reconciliation |
| General availability | All above + request/cancel acceptance + restore/finance gates | NO | Backup horizon/drill, finance confirmation, provider release gates | Owner final activation sign-off | Obligations survive outages/rollbacks; no indefinite hold |

## Owner checklist and abort points

| Phase/action | Exact artifact/prerequisite | Expected observation | STOP condition | Abort/rollback |
|---|---|---|---|---|
| A Prepare | This review/P-01–03, approved follow-up revision; existing Owner package | Separate external gate sign-offs; actual target/ref/hash recorded | Unresolved correction, unknown target, stale checkout | No Production effect; stop freely |
| A Config prepare | Secret names above, worker delegation, notification/checkpoint and backup policy | Values provisioned privately later; flags OFF; no requests/markers | Missing key versions, unsupported identity, unsafe restore/revoke claim | Config can remain unused; no value in report |
| B Schema | One reviewed migration transaction,5s lock timeout | Seven tables,33 functions, OFF singleton; no requests/markers/jobs | Any unexpected helper drift/ACL/object or unknown SQL outcome | Query first; do not replay; bounded rollback only before data |
| B Track | Only after schema success and exact file/hash reconciliation | Exact20261001000300 present; count24 if pre-count23 | Unexpected versions/count/SQL mismatch | Do not repair unrelated history; tracking failure is not SQL failure |
| C Server | Named new delete-account deployment after B, Edge flag false | Disabled503; no immediate deletion path | Wrong handler/version or missing server prerequisite | Leave disabled; never downgrade to old handler |
| D Worker | Named worker, scheduler disabled; all config and role delegation prepared | Non-mutating role/health/auth checks possible; no dispatch executed as “health” | Invalid auth, secrets in logs, no monitor/checkpoint | Disabled until ready; no live claim/maintenance smoke |
| E Client | Lifecycle-aware build initially flag OFF, reauth implemented | No accidental immediate-delete path; deadline/cancel/restricted UX accepted | New client against old server; inability to cancel | Hold rollout; preserve working status/cancel once obligations exist |
| F Activate | Corrections/external gates closed; monitoring and scheduler ready first | Coupled DB flag ON; marker grants usable; server/worker/scheduler serving | Any requirement unavailable before first request | Before data stop; after data no schema rollback/admin cancellation |
| G Verify | Separately approved synthetic tests below | Independent recorded gates, no real-user destructive test | False success, forbidden access, missed deadline | Stop new intake safely without disabling obligation servicing; forward fix |

Exact tracking method, only later and after Owner SQL application:

```sh
supabase migration repair 20261001000300 --status applied --linked --project-ref stlhijzpjfgwwdgunlsd
```

CLI help confirms this exact-version command. Not executed here. No db push,
migration up/all-pending replay, hand insertion into ledger, provider005 application
or day_targets repair. A corrected migration would need a newly reviewed hash before
any action; this review does not approve changing/reusing an applied artifact.

Rollback constraint starts with **any real lifecycle/benefit/reauth data**, not just
first hard deletion. The existing rollback refuses these rows and opaque transformed
grants and aborts on unexpected dependencies, without CASCADE. Even if a request
has not reached deadline, rollback would destroy an obligation. One-way enabled flag
also forbids reverting to legacy signup. An outage cannot be handled by switching
the common Edge flag OFF forever because that disables status/cancel and worker too.
A safe intake-only incident control is not currently a separate switch; it needs a
reviewed forward recovery plan. Never manually extend deadlines/cancel user intent.

## Postflight P1–P20 — design only

Use existing catalog.sql plus read-only supplemental categories below. Retain a
private pre-install catalog snapshot; store only sanitized comparisons publicly.
Do not invoke request/cancel/claim/dispatch/maintenance/attest/bind as catalog tests.

| Check | Expected / STOP |
|---|---|
| P1 ledger | Only20261001000300 added;23→24 conditional; untracked SQL not called tracked |
| P2 tables | Exactly seven listed lifecycle/private tables |
| P3 functions |23 public account_* +10 private helpers; signatures match validation |
| P4 owners | New tables/public RPCs postgres; detach_finance account_erasure_executor; existing owners preserved |
| P5 RLS | Seven new tables ON; current personal RLS not disabled |
| P6 policies/grants | New tables zero policies/no client CRUD; intended restrictive policies only |
| P7 anon | No new RPC/table privilege; no invocation needed for catalog proof |
| P8 authenticated | Only service_allowed/request/status/cancel EXECUTE, subject-derived |
| P9 worker/service | Worker23-minus4 RPCs only; service_role none; no browser membership; narrow finance/Essay grants |
| P10 function safety | SECURITY DEFINER where specified, empty search_path; trigger/private helpers checked by exact definitions, not blanket definer expectation |
| P11 Essay | Existing role table/function ACL unchanged; reviewed helper/policy changes only |
| P12 HQP | Tables RLS/ACL and all three RPC bodies/signatures/ACL unchanged |
| P13 ql-read | Both RPC bodies/signatures/ACL unchanged; helper intentionally changed |
| P14 finance | Economic schema/FKs intact, two intentional trigger replacements, narrow finance role only; no grant from install |
| P15 provider005 | Still absent |
| P16 day_targets |20260930000100 still absent, prior CRUD-only effect retained |
| P17 requests | count0 immediately after install |
| P18 markers | All benefit/identity/restore/ticket/delivery counts0; dispatch singleton false only |
| P19 jobs | No new account scheduler; dispatch not called |
| P20 old runtime | Fresh Edge list still excludes old handler; reviewed new deployment only before activation |

Supplemental Owner-only SQL after application (READ ONLY; not run here):

```sql
BEGIN READ ONLY;
SELECT n.nspname, c.relname, pg_get_userbyid(c.relowner), c.relrowsecurity,
       c.relacl FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE c.relkind='r' AND (n.nspname='account_private' OR n.nspname='public'
 AND (c.relname LIKE 'essay_%' OR c.relname LIKE 'credit_%'
 OR c.relname LIKE 'human_quality_%' OR c.relname IN
 ('account_deletion_requests','quality_operators','day_targets')));
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
 FROM pg_policies WHERE schemaname IN ('public','account_private','storage');
SELECT p.oid::regprocedure, p.proacl FROM pg_proc p
 JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='essay_private' OR n.nspname='public' AND p.proname LIKE 'essay_%';
SELECT state, phase, count(*) FROM public.account_deletion_requests GROUP BY state, phase;
SELECT count(*) AS markers FROM account_private.benefit_claims;
SELECT count(*) AS deliveries FROM account_private.benefit_delivery;
SELECT count(*) AS tickets FROM account_private.reauth_tickets;
SELECT count(*) AS identity_blocks FROM account_private.lifecycle_identity_blocks;
SELECT count(*) AS restore_tags FROM account_private.restore_tags;
SELECT enabled FROM account_private.dispatch_health;
SELECT count(*) AS account_jobs FROM cron.job
 WHERE command ILIKE '%account-deletion%' OR command ILIKE '%account_deletion%';
SELECT p.oid::regprocedure, pg_get_userbyid(p.proowner), p.prosecdef,
       p.proconfig, p.proacl, md5(pg_get_functiondef(p.oid))
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='account_private'
    OR n.nspname='public' AND (p.proname LIKE 'account_%' OR p.proname LIKE 'ql_%');
COMMIT;
```

Preflight ql body fingerprints for exact comparison after install:
list_cases `8b9530f9af6befd098e36a8d5c246b58`;
case_detail `d2a8ea8edcb2a29c309edcd9c892788e`;
submit_human_judgment `63ba87e2852903ba062a07be430a6217`;
review_state `f3f2bbdd83a4b0bc13e97f00237e1770`;
list_human_judgments `f3f5278cbfc1b49725d477932a89237a`.
These are function-definition hashes, never student-output hashes.

## First Production verification plan — NOT EXECUTED

A: ordinary non-operator; B: dedicated synthetic Quality operator only if separately
approved; C: dedicated lifecycle account with synthetic profile/learning only, no
real Essay answer/provider dependency where avoidable, no paid credit/payment history.
Never Owner's normal account or real student. No account/allowlist registration in
this task. C creation and any promotional grant/test cleanup require explicit later
Owner authorization; record expected bounded test data and cleanup obligations.

1. Schema/security: P1–20; anonymous/normal worker RPC denial; actual worker role
   safe read-only health. A successful disabled503 is not functional readiness.
2. Request/status/cancel: C explicit request, original deadline/status, repeat request
   idempotency, new-service denial, real reauth then cancellation strictly before336h.
   Verify normal login did not cancel. Missing reauth adapter means STOP before request.
3. Access: pending A cannot create/use personal/Essay work; pending dedicated B cannot
   ql/HQP access. No Owner account used. Client cache/UX and server denial separate.
4. Benefit: separately approve legitimate synthetic eligibility/grant test; verify
   unavailable check does not grant or block account creation; concurrency remains
   isolated proof until explicitly approved. No fabricated marker or secret in report.
5. Worker/scheduler: wrong bearer denied; valid worker health is read-only. A valid
   /dispatch call can mutate benefits/heartbeat/maintenance even with no due erasure,
   so it belongs to separately authorized activation testing, never this preflight.
6. Destructive E2E later: second explicit request on C after clean cancellation,
   natural336hour deadline, dedicated synthetic data, no deadline override/bypass.
   Independently verify Storage absence, Auth absence, HQP E1/E2 where synthetic
   fixtures are separately approved, finance invariants, minimal receipt and eventual
   expiry. Until then DESTRUCTIVE_ERASURE_E2E:NOT_RUN; local tests are supporting proof.

Keep separate: SCHEMA_APPLIED, MIGRATION_TRACKED, SERVER_DEPLOYED, WORKER_DEPLOYED,
SCHEDULER_ACTIVE, CLIENT_ROLLED_OUT, REQUEST_CANCEL_E2E_PASS,
DESTRUCTIVE_ERASURE_E2E_PASS, PROVIDER_REVOKE_VERIFIED, BACKUP_RESTORE_VERIFIED,
FINANCE_RETENTION_CONFIRMED. None is promoted by another's success.

## Closeout

ADR_2P_PRODUCTION_PREFLIGHT: COMPLETE (review complete; activation gates unresolved).
CODE_CORRECTION_REQUIRED:YES; implemented:NO. Owner checklist/first verification plan:
READY as a conditional review package, not an executable authorization.
PRODUCTION_WRITES:0; migration/tracking/deploy/scheduler/provider/Auth-delete/
Storage-delete:NOT_RUN. Production AI remains OFF per canonical closeout; no new AI
runtime invocation. Documentation only; no Unified Wiki change. Next: Owner/ChatGPT
review → separately authorize narrow corrections → required external gates → fresh
Owner staged-apply authorization. No automatic implementation or deployment follows.
