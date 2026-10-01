# ADR-2 — 336-hour account deletion implementation

## ADR-2C narrow correction — Owner policy accepted

2026-10-01. **COMPLETE / LOCAL ISOLATED VERIFIED. Production NOT_APPLIED.**
Starting APP commit9084a69; same unapplied migration version20261001000300.
Old hash `d7fa626d468e5c1d071a693f09f15fd4f34838db0f87b1a8acd1955dde6aa3b1` is **SUPERSEDED_PRE_APPLY**.
Reviewed SQL SHA-256: `b815b4d82ddf14c33f22be64f44a21666918787e9466f097f858c5b4b5844ff7`.

| Finding | Final correction | Evidence / remaining gate |
|---|---|---|
| P-01 | RESOLVED: manifest includes CANCELLED and original intent/deadline/terminal times; unbound facts remain visible. Typed per-request restore actions preserve pending restrictions, resume due erasure, neutralize cancellation, or reapply completed erasure. | R1–R8; deterministic deduplication and independently verified action postconditions before reopening. Real restore replay/backup horizon remains external. |
| P-02 | PARTIAL_EXTERNAL_GATE: trusted /reauth fresh email challenge and signed /admission adapter implemented; server-derived subject/session only. | Wrong subject/session, stale token-only proof, unsigned/stale hook and metadata forgery denied locally. Real provider configuration/client UX not verified. |
| P-03 | RESOLVED: capture CAPTURED/NOT_AVAILABLE/FAILED_SAFE independently of erasure. Missing keys/identity/derivation do not trap personal cleanup or Auth-last completion. | I7 plus mocked worker failures; Owner accepts bounded duplicate grant when historical evidence cannot survive erasure. |

**Owner policy: PRIVACY ERASURE > PROMOTIONAL ABUSE PREVENTION. GLOBAL HOLD REJECTED.**
Known surviving benefit markers prevent repeat grants. If capture is unavailable or
permanently impossible, erase normally: no raw email/Auth UUID/student-data fallback,
stronger identity collection, or global suspension. A later valid new account with no
historical evidence runs normal eligibility and may receive the promotion; this bounded
risk is accepted. A **temporary current eligibility-system failure** remains different:
account creation ALLOW, free benefit DO_NOT_GRANT_YET. No second credit ledger.

/reauth verifies caller through Auth, binds the verified JWT session, performs a fresh
same-subject email/password challenge, revokes only its temporary session, then attests
a short-lived ticket. ACCOUNT_EMAIL_REAUTH_ENABLED defaults false. Google/Kakao/Apple
remain fail-closed external gates; passwords/tokens are not stored/logged.
/admission verifies Standard Webhooks signature/timestamp using ACCOUNT_AUTH_HOOK_SECRET.
Signed candidate email is deny-only, never benefit proof; user_metadata is not authority.
Configure this hook only after its endpoint/secret are ready and default-OFF behavior is
verified. Provider identity/linking races and supported identity-set coverage remain gates.
Lifecycle denial markers use the restore key with a separate HMAC purpose; they do not
depend on promotional keys. Restore checkpoint integrity remains a distinct requirement.

Validation: **PG17 111 assertions; Deno48; Flutter7 PASS**, focused analyze/typecheck clean.
Rollback data/dependency refusal and canonical restoration PASS. Read-only Production
recheck: ledger23, ADR-2 absent, lifecycle table absent; provider005 absent and day_targets
tracking separate. This is not Production lifecycle verification. Writes/deploy/provider
calls0; no LAB edits. Owner review package READY; Production apply remains unauthorized.
Schema-OFF staged readiness does not imply general activation; external gates stay open.

Official adapter contracts (documentation, not runtime proof):
[Supabase before-user-created](https://supabase.com/docs/guides/auth/auth-hooks/before-user-created-hook),
[Auth REST API](https://github.com/supabase/auth/blob/master/openapi.yaml),
[Standard Webhooks](https://github.com/standard-webhooks/standard-webhooks/blob/main/spec/standard-webhooks.md).

2026-10-01 · LOCAL IMPLEMENTATION / ISOLATED VERIFICATION · **Production NOT_APPLIED**.
Successor to [ADR-1](account-deletion-14-day-architecture.md) and
[ADR-1B](account-deletion-erasure-retention-boundary.md); their design history is unchanged.
[Owner package](../supabase/verification/account_deletion/README.md),
[validation](../supabase/verification/account_deletion/validation.json),
[migration](../supabase/migrations/20261001000300_account_deletion_lifecycle.sql).

## Policy and canonical state

Owner A/B/C/D implemented as a separate operational lifecycle, not analytics.
Request→DELETION_PENDING→fixed requested_at+336hours→ERASING→verified **local** erasure→ERASED.
Only an explicit, fresh same-subject/session reauthentication ticket permits cancellation,
strictly before deadline. Ordinary login does not cancel; due time wins. No admin hold,
manual cancel/extension endpoint, terminal FAILED, or retry-count abandonment.
A cancelled request remains a separate bounded fact (30days); another request gets a new
ID/deadline. A repeated active request returns the original receipt.

Canonical table: public.account_deletion_requests. Subject FK survives while execution
needs it and is cleared by Auth deletion; fixed deadline and intent/execution times remain
separate. Phase/lease/retry/error are execution metadata, not changed user intent.
ERASED receipt has no Auth UUID/email/provider identity/answer/hash and expires exactly
completed_at+720hours. A separate restore-only keyed tag follows the same bounded receipt
expiry. It is pseudonymous operational control, not anonymous analytics or a permanent
user tombstone. Receipt purge is automatic and watchdog-visible if delayed.

Private purpose-limited facts: benefit_claims, benefit_delivery (current account only),
reauth_tickets, lifecycle_identity_blocks, restore_tags, dispatch_health.
No duplicate wallet, global identity graph, phone/device/IP identity or analytics archive.

## Authority and service restrictions

Authenticated-only account_deletion_request/status/cancel derive auth.uid; no target-user
argument. account_service_allowed requires a still-existing Auth subject and no active
request. Table clients, including service_role, receive no direct lifecycle/private CRUD.
Public worker RPCs are limited to new NOLOGIN account_lifecycle_worker; all use postgres
SECURITY DEFINER and empty search_path. Browser service-role use remains forbidden.
See exact object inventory and security matrix in the Owner package/validation artifact.

Restrictive RLS supplements existing policies on Profile, feedback, bookmarks/recent,
D-Day, Study, Mock, target university, Essay and Credit relations. Statement/row gates
prevent recreation on current owner mutation paths. Mock definer fetch/submit also check the lifecycle before reads/retries. Public guest materials are unchanged.
Essay owner/worker/credit helper gates acquire subject lock before account/session/grant
locks. is_quality_operator now also locks/checks lifecycle, preserving existing JWT and
allowlist checks; ql-read-v1/HQP signatures, DTOs and function bodies remain unchanged.
A deleting reviewer loses new Quality privileges; historical judgments remain until E1/E2.
The helper's volatility becomes VOLATILE to see the lifecycle after a lock wait.

No JWT is impersonated by erasure workers. Existing worker finalization cannot recreate
personal state once the subject is restricted/deleted. Work accepted before the request
is not silently re-run; queued/unstarted dispatch is gated. Reserved billing is released
at final erasure, not refunded merely on request. Cancellation restores server eligibility.
Full APP/LAB restricted navigation/reauth screens remain a separately scoped consumer gate.

## Erasure and transaction integrity

Lock order: subject advisory lock→request row (when relevant)→credit account→Essay
sessions→grants→evaluations. Claim uses try-lock/skip-locked and a2minute fence; cancellation
uses the same subject/request order. Retry does not alter deadline. Per dispatch<=5jobs;
claim API<=20. Personal phase processes<=20sessions and<=1000rows per remaining domain,
returns incomplete for another bounded retry. A single session's cascade is atomic.

PERSONAL releases authorized/reserved decisions through existing essay_private.release,
then deletes sessions, feedback plus notification/outbox dependents, target preferences,
D-Day, Study, Mock, bookmarks/recent. Settled consumption is not refunded. Session cascade
removes attempts/evaluations/dimensions/progress/scaffolding/rewrites/processing and HQP E1
judgments/findings. Feedback free text is deleted, not merely user_id-nullified.

STORAGE enumerates registered owner objects through supported Storage list/remove APIs.
Current namespace profile-avatars/<subject>/* includes all files, not only avatar.png.
Nested/unknown inventory fails closed; new personal namespaces require explicit registration.
PROVIDER records verified vs unknown; unknown revoke does not indefinitely postpone local
cleanup or falsely become provider success. FINANCE privacy-detaches only reviewed formats;
AUTH Admin hard-delete is last after required local cleanup. Independent absence confirms
ambiguous Auth timeout. E2 nulls reviewer identity on other students' retained evaluations.
VERIFY uses phase/FK postconditions and prior verified Storage cleanup. ERASED is local
personal-data erasure; provider_verified=false remains a bounded notification/error, not
an assertion of provider-side erasure. Full provider integration remains an activation gate.

Finance retention preserves quantity/time/type/grant-consume-release-reversal relationships.
Dedicated non-login finance executor may change only allowed linkage fields under strict
triggers: signup/manual Auth-UUID reference keys become opaque row-based keys; erased
reviewer's operator actor reference becomes non-identifying. Another live operator's
attribution is not removed when their recipient deletes. Economic terms stay immutable.
Free promotional and manual grants are distinguished from paid/payment/refund/settlement
records. Opaque paid references and unknown historical formats need external review;
FK NULL is not an anonymization claim, and no statutory retention duration is invented.

## Signup / re-registration

Verified Auth canonical email (trim/lowercase, no Gmail alias guessing) and currently
verified Google/Kakao/Apple identity subjects supply HMAC inputs server-side only. An
unverified email/profile field does not qualify. Benefit markers use purpose-specific
HMAC with versioned server secret, no raw email/permanent Auth UUID. Existing grants seed prior-claim markers when capture is available; capture failure
never delays erasure. Atomic marker locks + existing Credit Ledger grant
ensure at most one3credit delivery. Exact old/current keys are checked during rotation;
losing old keys is a launch/operational incident, not permission to grant again.

After ERASED, a new Auth account may exist; surviving prior-claim evidence denies
another grant. Missing historical evidence follows the accepted normal-eligibility risk. If identity/secret check fails: account creation remains allowed, benefit
not granted yet. Client recovery RPC returns only a grant already delivered server-side. The same dispatcher also recovers up to20 verified eligible accounts per run, so new-account benefit delivery does not require client-side identity/HMAC logic.
Server /benefit endpoint verifies actual JWT user and ignores caller-supplied identity.
No marker is used as an Essay/Learning/Finance/Analytics join key or returned to clients.
Lifecycle blocking markers use a different HMAC domain from benefit markers; restore tags
use the restore key under separate purposes. Provider admission/linking runtime is an activation gate.
Owner-observed same-email linking is preserved as bounded evidence, not universal proof.
Unverified/unsupported identity coverage must be inventoried before activation; no provider
console/configuration was accessed here.

## Worker, notification and restore

Candidate Edge dispatcher and narrow server adapters are implemented but NOT_DEPLOYED.
Default DB/Edge/APP gates OFF. Five-minute dispatch + independent heartbeat/overdue/purge
monitor is the deployment contract. Pending obligations bind/checkpoint before due time;
one failed pending bind does not starve other due subjects. Retry uses sanitized bounded
codes/backoff, no raw exception/identity/provider payload. Notification failure never gates
local erase; it retries independently. Operational notifications contain request/deadline/
state/error only and must obey bounded operational retention.

Restore manifest is protected outside the restored DB, atomically reconciled with bounded
TTL and freshness/ack monitoring. restore.ts computes exact restore-only tag matches,
requires complete inventory/fresh checkpoint evidence, and refuses horizon>30days. Matching
PENDING must regain restrictions/original deadline; CANCELLED neutralizes only that request;
matching completed/due obligations must
be erased before normal service reopens. Checkpoint loss/staleness or unknown backup horizon
means do not reopen. No managed backup was edited and no live restore was performed.

## Tests and limits

Validation:111 isolated SQL assertions,48 mocked Deno tests,7 Flutter tests PASS; focused analyze clean. See validation.json for D1–D75 evidence levels. Actual canonical PG17
migrations/functions and synthetic Essay/HQP/credit records exercise locks, two-connection
races, single release, HQP E1/E2, erasure, signup retry and receipt purge. New catalog/ACL
checks distinguish the intentionally added finance executor rights from existing-role
preservation. Rollback rejects data and unexpected dependencies; clean rollback passes.
Auth role shim is not real JWT/provider verification. Storage/Auth/HTTP/notification/restore
transport tests are mocked. No real identities, credentials, provider calls or Production
fixtures/writes; only sanitized read-only catalog/ledger recheck. No provider005/day_targets tracking repair, no LAB change.

Flutter typed DTO/minimal screen distinguishes normal/pending/erasing/cancelled/erased,
displays fixed deadline and explicit cancellation, never says deletion completed after
request. Local Study owner cleanup preserves other users/guest. Reauthentication UX,
app-wide pending routing/cache/outbox restrictions and LAB consumer UX remain explicit
activation work; server authority does not depend on client redirect.

## Readiness / next gate

LOCAL candidate is reviewable; Production apply/activation NOT_AUTHORIZED. External gates:
provider recent reauth/revoke; verified-identity Auth admission; server role/JWT delegation;
benefit/restore secret provisioning/rotation; paid/legacy finance review; actual Storage
inventory; checkpoint/backup horizon/restore drill; scheduler/watchdog/notification deploy;
APP/LAB consumer acceptance. No default-off installation is a Production lifecycle claim.

Next: Owner/ChatGPT code/migration review→activation-gate verification→Owner exact apply/
tracking→Production postflight/authorization/lifecycle verification→APP/LAB deletion UX.
PRIVACY_ANALYTICS_RETENTION_DESIGN remains separate and unimplemented.

## Seven preservation questions

1. Intent time, fixed deadline, cancellation and execution time are distinct immutable facts.
2. Ordinary Essay/HQP provenance/history remains unchanged until deliberate privacy erasure.
3. Privacy erasure is not correction; E1 deletes dependent reviews, E2 removes reviewer identity.
4. One current Auth identity; purpose-separated benefit/restore facts are not a new universal ID.
5. Lifecycle intent/execution is operational data, not a score, Learning metric or analytics event.
6. No copied content; finite receipt and minimal keyed facts, never FK-null-as-anonymization.
7. Status/alerts derive from lifecycle facts; analytics does not own deletion truth.
