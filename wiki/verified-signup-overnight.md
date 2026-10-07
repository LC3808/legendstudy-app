# Verified signup — Overnight Phase A (2026-10-07)

Owner requires confirmed email → canonical +3 once, no intrinsic expiry. Source
basis is final Store RC, not APP main. Existing `credit_post_grant`, unique
`credit_signup_once_per_account`, per-account locks, external reference/idempotency
and lifecycle benefit delivery are reused; no client grant or new wallet.

Source gap: legacy `credit_signup_eligible` checks only the captured creation cutoff.
The active lifecycle candidates already require verified email, but the same guard
must hold at the underlying eligibility authority, including legacy paths. Migration
20261007150000 adds `email_confirmed_at is not null` to that predicate only. It
retains cutoff, OID, owner, ACL, stable/security-definer/empty search_path properties.
Unknown body or an existing verification predicate aborts for reconciliation.
Google/Apple/Kakao reuse the canonical Auth UUID and its verified email state;
provider-link/relogin never becomes a separate ledger account or benefit key.

Validation: local PGlite PostgreSQL engine, 11 behavioral assertions PASS: unverified,
verified, old cohort, exact cutoff, unknown user, subsequent confirmation/retries,
owner/ACL identity, repeat-apply and unknown-body refusal. Existing grant/concurrency
mechanisms were not modified. No claim of hosted grant E2E or concurrency retest.

Production apply BLOCKED: no DB/Supabase management credential or connector in this
cloud environment. No new credential minted. Email confirmation ON was publicly
verified. Current deployed eligibility/lifecycle state, migration collision and
exact rollback definition must be read before apply; do not assume source=deployed.
For rollback capture `pg_get_functiondef`, owner/ACL and hash before apply, then
restore that exact definition transactionally and verify catalog. No backfill or
existing grant mutation; rollback cannot undo a separately committed grant.

Preservation review (seven answers): no new raw events; existing grant timestamps /
origin / request keys retained; no derived balance overwrite; no history replacement;
no cross-scale analytics; owner/role/privacy/deletion guards unchanged; future
Application/outcome storage remains absent. MY target edits reuse APP's current
preference semantics, never convert interests to actual applications.

No Payment/Toss/deletion architecture changes. Unified Wiki contains current
cross-repo Phase status; this file records only the backend delta and validation.
