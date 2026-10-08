# Production activation closeout — 2026-10-08

Owner authority: SIGNUP CREDIT + MY RUNTIME + ADMIN BACKEND/AUTH. Public visuals
belong to Manus. Backend base remains final Store RC7d1c036 plus the prior reviewed
signup guard ba1f875; APP main is not canonical. No whole branch merge.

## Minimal candidate changes

- Original Admin migrations20261007000100/200/400 and their verification assets
  are imported byte-for-byte from49c02de. No historical migration rewrite or
  notification-center migration003 activation.
- Corrective20261008000100 replaces only five existing Admin read functions.
  Known prosrc hashes, security-definer/stable/empty-search-path properties must
  match before replacement; unexpected deployed code aborts. OID/owner/ACL preserved.
  Snapshot/dashboard/grant availability exclude payment_orders.grant_id in
  CANCEL_PENDING. Reserved/next-expiry follow canonical credit_summary spendable
  scope. Raw balance/reserve/ledger history remain unchanged.
- Inquiry Credit resolves Auth UUID → credit_accounts.id. No account mapping guessed.
- Member detail adds only verified-email boolean, identity provider names, existing
  intended major and at most50 interested university/division entries. No passwords,
  identity payload, tokens, answer body or new personal-data store.
- Corrective20261008000200 grants only UPDATE(intended_major) to authenticated.
  Local canonical migrations exposed a real MY save failure: the new column had
  no write ACL. Existing exact owner RLS must match; extra permissive write policies
  abort. No new policy, table-level UPDATE, insert or ownership bypass.
- Signup guard20261007150000 remains unchanged. Captured signup cohort, verified
  email, canonical +3/no intrinsic expiry, account locks/unique keys preserved.
  Existing lifecycle candidate worker requires verified email; no new email service,
  trigger, wallet, worker activation or deletion architecture.

Seven preservation answers: no new collection; existing raw timestamps/ledger kept;
no derived-balance overwrite; no historical-event replacement; no scale conversion;
owner/role/retention/deletion boundaries retained; no Application/outcome schema.
Existing current-value goal semantics remain unchanged.

## Verification and limitations

Run `PGLITE_MODULE=/path/to/pglite/dist/index.js node supabase/verification/admin_console/activation.mjs`.
Existing Admin read/inquiries/Ops tests plus corrective assertions run on the canonical
local chain and existing Supabase shims. Payment/deletion/Math subsystems are omitted
as in the historical harness; the related Math cleanup is also omitted. Payment
stand-in has the columns the read needs; actual canonical credit_summary SQL is used
for comparison with clearly marked local lifecycle shims. This is not hosted or
full lifecycle E2E. Authenticated owner target/major edits and other-owner RLS denial
are real SQL role checks in the local engine. Verified signup uses the actual local
claim/grant function: unverified rejected, confirmed +3, repeated/provider-link claim
returns the same grant, no expiry. PGlite is single-connection; a separate `concurrency.py` run used real local
PostgreSQL17.11 with8 simultaneous connections: exactly1 grant,1 transaction,+3,
no expiry; unverified denied and relogin retry returned the same grant. It also
reran all402 original SQL checks. Hosted concurrency remains unverified.
The existing complete lifecycle suite also passed112 checks plus its ownership /
rollback checks with the new signup guard injected at the existing Auth shim boundary
(`verified_signup/lifecycle.py`). It includes lifecycle benefit idempotency and the
erase-versus-grant race on synthetic local users. No Production erasure occurred.

## Production gate / apply and rollback

Status: NOT_APPLIED. No DB connection, Supabase management binding, Cloudflare
management binding or real admin/reviewer session is present in this environment.
No secret values were read or requested in chat; no new credential/JWT minted.

1. Re-read latest LAB/backend/Wiki and run activation_preflight.sql using an existing
   approved connection. Inspect migration versions, exact functions/owners/ACL,
   allowlists, lifecycle enabled/benefit-worker state, profile RLS and payment schema.
2. If any candidate version is already tracked, compare exact deployed definitions;
   do not replay or rewrite history. Unknown hashes/policies/collisions STOP that apply.
3. Capture exact function definitions/ACL/owner and intended_major ACL for rollback.
   Verify real concurrent duplicate signup through existing canonical locks/unique
   constraints in an approved isolated transaction test; no general-user grant.
4. For a confirmed fresh Admin install, apply00100,00200,00400 and corrective08000100
   in one transaction (strip only each file's outer BEGIN/COMMIT), validate then commit.
   Do not expose old unfenced Admin reads between migrations. Record each exact version
   with the existing migration tool. No broad db push, fake tracking or unreviewed SQL.
5. Apply signup guard and major column ACL only after their own preflight. Verify
   anon denial, ordinary-user denial, admin allow, independent Quality operator role,
   canonical Credit consistency and actual reviewer persistence. HTTP200 is not enough.
6. Any precommit failure: ROLLBACK the transaction. After commit, use captured exact
   definitions/ACL; never drop inquiry data, replay old migrations or directly delete
   ledger history. If restoration would expose old incorrect Admin credit reads,
   keep those entry points unavailable pending correction. No automated destructive
   rollback is shipped.

## Finance boundary

Known-good LAB Payment reads server binding PAYMENT_FINANCE_TOKEN. The read-only Production runtime returned REVIEW/TEST (consumer purchase false),
so the known-good config guard passed. This does not establish the token subject,
role, expiry or Admin-safe reuse.
Existing essay_admin_grant records operator from the signed JWT subject, not the
browser payload: blindly reusing a service Payment subject would misattribute audit.
No new signer, finance transport, secret rotation or privileged write is introduced.
Grant/refund controls stay closed until existing authority can be verified safely.
No actual test/review Credit grant, payment, refund or user deletion performed.

Unified Wiki owns the final cross-repo deployment/runtime status. Backend candidates
are reviewable source, not a claim that Production activation succeeded.


## Owner-assisted results and school-name addendum — 2026-10-08

The earlier NOT_APPLIED observations above are historical: Owner supplied ledger
and catalog proof of all six candidates applied. All17 Admin bodies matched source;
Owner Admin reads and normal/review denial passed. New Web-only account had verified
Auth but no profiles row, blocking MY writes and benefit worker candidate discovery.
LAB4de6dfa initializes only missing own profile without overwriting shared APP data.
Actual new-user profile/bonus follow-up remains pending; no manual bonus used.

New candidate20261008000300: admin_dashboard additive profile fields
school_distribution_by_identity (office+school,count,top20) and school_unset_count.
Old field, Credit computations, OID/owner/ACL preserved; exact deployed source hash
required. No external calls inside SQL, no school master/table, no profile writes.
Browser exact-pair name lookup is per aggregate school, bounded/cache, never per-user.
SQL402existing+54correction checks PASS including pair collisions, unset count,
old response preservation, anon/normal denial, admin allow and repeated apply refusal.
Production candidate NOT_APPLIED; read current ledger/hash/ACL before Owner execution.

Preservation review: existing timestamps unchanged; raw facts untouched; current
profile aggregate is not historical school membership; auth identity and credit-account
identity remain distinct; goals are not applications/outcomes; operator authorization
and existing retention remain; derived counts are not raw measurements or predictions.
Manus view contract and conservative Essay comparison gate are maintained in LAB
`docs/MY_STUDENT_360_CONTRACT.md`. No Student360 page or new student store created.


## Benefit dispatch diagnostics — 2026-10-08

Owner explicitly approved first provisioning of ACCOUNT_BENEFIT_KEYS after the
read-only inventory showed zero stored marker versions/deliveries and2 candidates.
Owner reports v1 registered with a private local backup; no value was shared.
Subsequent target read still shows no credit account/delivery/grant. Health fresh,
service_role and lifecycle_worker can execute all3 benefit/health RPCs. Cron targets
the correct Edge /dispatch each minute; pg_net shows200 processed0/retryable0, which
counts deletion work only, not benefit success. Dashboard invocation list was empty
and must not be interpreted as no HTTP execution. Downloaded index/server/worker/http
SHA256 exactly match the reviewed pre-diagnostic source. Root cause beyond missing
key remains unconfirmed; no manual grant, permission expansion or secret rotation.

Candidate adds benefits.attempted/completed/failed and closed-category failure counts
only to the existing secret-protected dispatcher response. Stages AUTH/MARKERS/CLAIM;
only allowlisted SQL codes and HTTP statuses. No raw errors, messages, account IDs,
identities, key material or markers. completed means RPC returned, not necessarily
a new grant. Existing /benefit auth response and deletion transitions stay unchanged.
No SQL migration, Public/MY visual, finance/Toss, grant rule or credential change.

Validation: Deno2.5.4 tests66 PASS (8 new); production-file lint PASS and test typecheck
PASS. Broad test-file lint reports require-await in existing async fixture style
(and new matching fixtures); it is not claimed clean. Owner deploy helper syntax
and mocked JWT-gate preservation, concurrent-version refusal and file bounds PASS.
Helper tool/production/deploy_benefit_diagnostics.py downloads the current function,
fails on changed reviewed hashes or missing verify_jwt metadata, retains rollback
files/config, replaces exactly worker/server/new diagnostics, checks version again,
and deploys only this function. No manual dispatch (which could process deletions).
Rollback if needed: deploy the retained before directory with the same project and
--use-api; no DB rollback or ledger deletion. Production diagnostic deploy PENDING.


## Benefit grant ACL root cause — 2026-10-08

Owner deployed diagnostic Worker v22 preserving verify_jwt=false. Scheduled HTTP200
now reports2 attempts,2 failures CLAIM_HTTP_403_42501. Auth and marker construction
passed. Read-only catalog confirms postgres-owned account_benefit_claim can execute
eligibility/allowed/lock helpers but cannot execute essay_executor-owned private
credit_post_grant; ACL is solely essay_executor=X/essay_executor. Schema USAGE exists.

Candidate20261008000400 grants only EXECUTE on that exact existing helper to postgres.
Uses existing reviewed transaction-only SET-role bridge, preserves supabase_admin
membership and removes only its own postgres-granted temporary membership. No schema
CREATE, helper body/owner/config change, role inheritance, browser/service_role grant
or direct table permission. Preconditions refuse different ACL/owner/security/gate.
Postconditions verify all direct untrusted roles still denied and memberships equal.
The SQL Editor bundle additionally guards the migration version and records the exact
migration source atomically. Neither file calls grant/claim or touches user rows.

Regression now explicitly keeps the function's postgres owner NOSUPERUSER during
benefit execution: prior full-suite runtime used a restored superuser after migration
checks, masking this nested call failure. Actual canonical local functions reproduce
the42501 and leave no partial credit account; corrected claim grants3 once/no expiry
and repeated/concurrent identity claims remain idempotent. Existing lifecycle suite
and forced mid-apply failure rollback run; no existing assertion removed. Only test
transport caller-role SET rights are supplied separately from essay_executor authority.
Production correction remains PENDING until Owner SQL result and automatic worker
grant/ledger/summary verification. No manual3, key rotation or new secret required.

Rollback: if needed use the same temporary owner SET bridge to REVOKE only this
function's postgres EXECUTE, then remove the temporary bridge. That reblocks benefits;
never remove granted Credits or migration history to simulate rollback.


### Owner post-error catalog — 2026-10-08

Owner reported42P01 benefit_acl_before missing; pasted SQL exactly matched the
published apply bundle. A new read-only query nevertheless confirms migration
20261008000400 recorded, postgres EXECUTE effective, and no postgres-granted temporary
essay_executor membership. Thus do not replay the migration or deploy the proposed
temp-table-free replacement. The discrepancy in Editor execution remains unexplained;
rollback was not assumed. Applied source history is preserved. Automatic worker
delivery and target grant/ledger/UI checks remain pending.


## Signup bonus Production ledger verified — 2026-10-08

Owner read-only result for the affected verified test account confirms exactly1
signup_bonus grant, balance3, benefit_delivery linked to that signup grant, and0
signup grants with expiry. Missing ACCOUNT_BENEFIT_KEYS was provisioned with explicit
Owner approval; missing nested postgres EXECUTE was fixed by recorded migration
20261008000400. Temporary role bridge absent. Existing worker recovery now delivered
through canonical authority; no manual grant or replacement wallet. Diagnostic
Worker remains v22. This verifies actual Production delivery/ledger for one account,
not both queued accounts, a new complete signup E2E, or a hosted duplicate-attempt
test. Local duplicate/concurrency checks passed. MY and Essay Header display still
await Owner confirmation; no authenticated browser credit_summary response supplied
in this final check. No Payment/Toss or Public/MY visual change.
