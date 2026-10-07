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
