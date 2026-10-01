# ADR-1B — Erasure, retention and re-registration boundary

2026-10-01 · DESIGN / CANONICAL CONTRACT · NOT IMPLEMENTED.
Successor to [ADR-1](account-deletion-14-day-architecture.md). Owner A/B/C/D are
accepted; ADR-1's earlier readiness NO remains historical. This review concludes
**READY_FOR_ADR2_IMPLEMENTATION = YES_WITH_EXTERNAL_GATES**. ADR-2 still requires
explicit authorization. No SQL, migration, credentials, live Auth/DB query, provider
operation, LAB change or deletion was performed.

## Evidence and present behavior

Canonical APP source inspected: `codex/essay-scaffolding-vnext` at
`cbd80c90f5b104dc50e9d1a961f73d48849ce52e` plus preserved local ADR-1 documents.
[Commercial migration](../supabase/migrations/20260929000300_essay_credit_commercial_core.sql),
[ledger](../supabase/migrations/20260928000200_essay_entitlements.sql),
[Essay operations](../supabase/migrations/20260928000300_essay_server_operations.sql),
[Auth service](../lib/features/auth/auth_oauth.dart),
[email service](../lib/features/auth/auth_email.dart),
[native Auth](../lib/features/auth/native_auth.dart),
[Auth acceptance](auth-native-owner-acceptance.md) and ADR-1 are the evidence base.

A. Existing signup protection: unique credit account per current user, unique signup
   grant per account, `external_reference=signup_bonus/<Auth UUID>`, transaction key
   `grant/signup_bonus/<Auth UUID>`, atomic posting/unique constraints. Explicit
   `essay_claim_signup_credit` and profile-insert trigger share the same grant path.
   Eligibility checks Auth creation time against the migration's fixed activation
   timestamp; it does not identify a returning deleted signup identity.
B. Auth hard deletion detaches account.user_id and decision.evaluation_id; ledger
   rows and embedded reference strings survive.
C. A subsequently created Auth account is expected to have a new UUID. If otherwise
   eligible, the current profile trigger can grant another three credits. Rejoin was
   not executed here. No current cross-deletion benefit check exists.
D. Signup reference/key, manual `operator/<Auth UUID>` actor, opaque billing keys and
   external references survive. Some identify accounts even after FK nulling.
E. These rows alone cannot safely answer returning verified identity: they know an
   obsolete UUID, not a verified current credential. Retaining email beside them or
   a permanent old→new UUID map would defeat minimization. Do not duplicate balances.

## Decision matrix

| Area | OWNER_POLICY | CURRENT_SYSTEM_SUPPORT | GAP | MINIMUM_IMPLEMENTATION_DIRECTION | PRIVACY_RISK | LAUNCH_BLOCKER | OPEN_EXTERNAL_DEPENDENCY |
|---|---|---|---|---|---|---|---|
| A Credit/Billing | Necessary transaction facts only; remove unnecessary linkage | Immutable ledger + FK SET NULL | Embedded UUIDs; unspecified financial retention | Narrow privileged privacy-detachment exception; preserve amounts/chains; opaque future references | Detached does not mean anonymous | YES before lifecycle activation | Category-specific accounting/processor retention review |
| B Operational data | Fixed336h deadline; erase personal content | Essay/HQP cascades and immediate-delete candidate | Pending gates, feedback/storage/provider/recovery gaps | ADR-1 worker plus owner inventory and restore gate | Content survives outside FK graph | YES | Provider revoke capability, storage inventory, backup configuration |
| C Receipt | Minimal receipt30days after completion | None | Retry/restore evidence without permanent subject | Deidentified presentation receipt; separately bounded restore matching discussed below | Restore matching remains pseudonymous | YES | Actual maximum restorable backup horizon and off-site recovery path |
| D Rejoin/benefit | Rejoin after ERASED; benefit once per verified identity | Once per current UUID only | New UUID bypass and coupled signup/grant | Purpose-limited eligibility markers, atomic existing-ledger grant, separate account creation | Stable marker remains personal/pseudonymous anti-abuse data | YES | Verified identity inputs/config, secret custody, privacy disclosure |

Launch blockers here block Production activation, not isolated ADR-2 implementation.
They do not reopen the accepted deadline, cancellation or benefit policy.

## Five separate purposes

- PERSONAL_OPERATIONAL_DATA: account/profile/school/preference, learning, Essay/QA,
  feedback, private objects. Erase; no archival copy for future analytics.
- FINANCIAL_TRANSACTION_FACT: minimum supported quantity/amount/time/type and
  grant/consume/refund/reversal chains. Necessary finance linkage only, finite
  category-specific retention; no statutory period invented here.
- ANTI_ABUSE_ELIGIBILITY_FACT: whether an already-verified signup identity claimed
  this benefit. No Essay/learning/finance joins or reverse-lookup UI.
- MINIMAL_DELETION_RECEIPT: completion/retry incident evidence for30days, not identity
  history, not an analytics profile.
- ANALYTICS_DATA: separate future gate; no pipeline or collection authorized.

Auth subject, benefit marker, financial linkage and future analytics identity must
not become a universal persistent identity. FK NULL is not anonymization.

## A — Finance privacy detachment

| Category | Keep if necessary | Erase/detach | Minimum direction |
|---|---|---|---|
| Free signup/promotion | Quantity/time/type and accounting chain needed to reconcile grants/consumption | Auth/profile/evaluation linkage and UUID-bearing signup keys | No presumption of statutory financial retention; finite operational policy. Replace identity-bearing references with collision-safe opaque ledger-row-based keys |
| Paid/payment/refund | Amount/currency where present, settlement/refund/reversal facts, processor reference only for a documented continuing purpose | Student content and unnecessary Auth/evaluation linkage | Finance-restricted retained facts, separate retention schedule; payment reference is potentially linkable, never advertised anonymous |
| Manual/operator grants | Grant reason, quantity/time and reversal chain | `operator/<UUID>` after operator erasure unless a specifically reviewed accounting duty requires linkage | Non-identifying actor state; no email/name snapshot; transaction remains unchanged economically |

Future grant/idempotency references use opaque transaction/grant IDs, not emails or
Auth UUIDs. Existing uniqueness must remain valid after detachment. A narrow internal
privacy operation may change **only** classified linkage/reference fields and set
privacy-detachment state; it cannot change amount, quantity, time, product, reason,
ledger row IDs or relationship chains. This is an explicit exception to general
append-only UPDATE guards, not a correction or finance CRUD API. Do not copy old
personal values into an audit log; record only completion/count/invariant results.
No browser/operator arbitrary rewrite authority.

Reconcile/release outstanding reservations before detachment. Disable old account
retry access first; old client keys must not recreate grants. Existing ledger-row
identity supports internal reconciliation after reference replacement. Verify all
consumers before replacing keys; if a processor requires an original reference,
retain only that reference under its exact finite finance policy. Do not silently
hash it and call it anonymous. Paid data retention/deletion configuration remains
activation-gated until reviewed; no indefinite catch-all retention default.

## B — Operational scope and providers

ADR-1 cascade graph remains canonical: profiles/school preferences, D-Day, study,
mock attempts/answers, Essay sessions/attempts/evaluations/progress and HQP E1 erase.
E2 removes the reviewer's identity from reviews of other surviving evaluations.
Feedback text plus dependent outbox metadata must be deleted before losing subject
correlation; SET NULL alone is insufficient. Already sent email is an external copy
requiring delivery-system retention review, not a DB FK guarantee.

Storage inventory must resolve all current owner objects across approved buckets,
including canonical path ownership where object metadata is insufficient. The
candidate only removes `owner/avatar.png`. Future uploads must register verifiable
ownership; do not infer ownership from arbitrary filename substrings. Fence uploads,
use Storage API, check absence, retry timeouts. Purge local cache and block deferred
outbox replay; offline device erasure is only verifiable when it reconnects.

| Auth mode | Repository evidence | Revocation boundary |
|---|---|---|
| Google | Native ID-token→Supabase exchange | ID token is not a durable revocation credential; inventory authorized tokens/grants, do not claim Google account deletion |
| Kakao | APP browser PKCE, email scope; LAB OIDC described in Owner acceptance | Kakao unlink is distinct from Supabase deletion; verify required credentials/server route without importing LAB changes |
| Apple | Native ID token/nonce; email scope; existing revoke gate OPEN | Requires an actual supported revocation token flow; current login acceptance is not revoke proof |
| Email | Supabase signUp/password login | Delete Supabase credentials/sessions through Auth; no external email-account deletion |

Official capability references (not proof of this project's configuration):
[Google revocation](https://developers.google.com/identity/openid-connect/reference),
[Kakao unlink](https://developers.kakao.com/docs/en/kakaologin/rest-api),
[Apple deletion/revoke](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple).
No provider operation was performed. Provider outage never extends the deadline:
continue independent active-data erasure; unresolved cleanup remains a visible overdue
incident with minimum necessary protected locator and retry, not ERASED success.
No administrator hold. Credentials/locator disappear once their obligation finishes.

## C — Receipt, backups and restore

Keep Owner default: **completed_at +30days**, auto-purge, no expiry reset on support
access/retry. Receipt contains random request reference, policy version, request/due/
completion times, outcome/phase verification flags; no Auth UUID, email, name, OAuth
ID, evaluation/hash, note or copy of personal data. Support can use a user-held random
receipt reference, not a searchable account directory. After30days, detailed support
attribution intentionally ends. Active failed erasures are not completed receipts;
no premature personal-link purge while cleanup is unresolved.

Thirty days is sufficient for the proposed retry/incident/support mechanism; no
observed code requires longer receipt retention. Actual backup horizon is NOT
independently verified. [Supabase backups](https://supabase.com/docs/guides/platform/backups)
documents plan-dependent bounded recovery and excludes Storage object bytes from DB
backups. Do not assume a plan, PITR window or custom dump retention for this project.

**Restore matching is not solved by an anonymous receipt alone.** Recommend a
separate field/purpose partition of the same bounded erasure control record: a
keyed restore-only tag derived from the old Auth subject, held outside the restore
rollback domain until completion+30days, with no direct UUID. This is pseudonymous
cleanup data, not anonymous, not a permanent tombstone, not the benefit key. A
restricted restore tool computes tags over restored subjects, reapplies completed
and outstanding erasures, replays finance detachment and restores current benefit
claim state before network/service reopening. No general reverse-lookup endpoint.
The receipt remains minimal; the tag expires with it. Separate key from benefits.

Activation requires verifying all eligible restores containing erased data expire
before this30-day matching window, including custom exports and snapshots. Disable
older restore sources under the approved backup policy; do not silently extend
receipt retention. If unavoidable longer recovery exists, report the exact constraint
for Owner decision. Pending obligations must also be durably mirrored outside the
restored DB; scheduling merely from a restored old snapshot loses post-backup requests.
No new generic deletion event-sourcing system: minimum control-record checkpoint and
mandatory closed-service recovery runbook. Do not rewrite historical managed backups.
Test restore before activation. Purge failures alert/retry without resetting expiry.

## D — Identity evidence and smallest benefit model

OWNER_OBSERVED_AUTH_LINKING: in tested current flows, Owner observed Google↔Kakao
and Kakao↔Apple/email with the same email handled as one account/person. Preserved.
Repository confirms Supabase-managed sign-in; no app email-based merge graph found.
`supabase/config.toml` does not pin live provider/linking/email-confirmation settings.
**AUTH_LINKING_INDEPENDENT_VERIFICATION: PARTIAL** (code and public platform docs;
live provider configuration/identity cases NOT_INDEPENDENTLY_VERIFIED).

[Supabase identity linking](https://supabase.com/docs/guides/auth/auth-identity-linking)
describes automatic same-email linking with verification/security qualifications;
it is not a guarantee that all provider combinations always merge. Email confirmation,
provider claims and existing linked identities must be checked server-side. Apple
relay is a different address; never infer the hidden mailbox. Provider subject scope
can change with application/team/configuration changes. After Auth deletion the
old account's identity relation cannot supply a future benefit lookup.

Alternatives: UUID ledger alone fails rejoin; raw email/permanent UUID map violates
minimization; plain email hash permits dictionary matching; device/phone/IP/fraud
identity collection is disproportionate. Recommendation: narrow **purpose-limited
keyed eligibility markers**, separate from balance and transaction records.

Input: server-verified canonical email as represented by Auth, using a versioned
normalization matching tested Auth behavior (whitespace/domain case normalization;
no Gmail dot/plus stripping, no guessed mailbox equivalence). Case behavior for the
local part must be pinned by configuration tests before activation. Never accept
raw_user_meta_data or caller-supplied email/verified flags as evidence. Also retain
markers for already verified provider issuer/app namespace + stable subject, where
available, to recognize the same provider if its email changes. Inputs are processed
transiently; stored markers contain no raw email, provider subject or Auth UUID.

This is a bounded set of independently claimed credential markers, not an identity
graph: no person ID, alias edges, cross-domain ID or historical email collection.
Check the current server-verified linked credential set; any prior claim means no new
benefit, and mark other currently verified credentials as already covered. When a
new credential is explicitly verified/linked to a benefited live account, propagate
claimed status at that point. Unknown/unlinked alternate emails or Apple relay
identities cannot reliably be recognized as the same human. Accept this coverage
limit; policy is once per **verified signup identity**, not once per unknowable person.
Do not create probabilistic matching to close that gap.

Marker conceptual facts: benefit version/type, key version, credential kind,
purpose-separated HMAC, claimed time/state. No permanent Auth/account/grant FK;
no finance/Essay/Quality/learning joins; no reverse lookup UI. Retain while this
once-only benefit remains available, with purpose review and deletion when benefit
policy retires; this is an explicit anti-abuse retention exception, NOT the30-day
receipt and NOT anonymous. Privacy notice/external review before activation.

Secrets: dedicated server-only eligibility key, never browser/repo/SQL literal or
shared JWT/service key. Query all retained key versions. Without raw inputs old
markers cannot be bulk-rekeyed: keep prior verification keys protected while required,
compute new markers on subsequently verified presentations, and do not drop old keys
on an arbitrary rotation schedule. Compromised/lost keys require an incident gate;
unreliable eligibility yields no automatic free grant, not a new tracking system.
Separate restore-tag key and purpose; no key reuse.

Benefit decision and ledger posting must be atomic in one DB transaction under
bounded locks on sorted marker keys: claim markers + existing credit grant +3 commit
or rollback together. Server derives verified inputs; clients cannot choose markers.
A short-lived delivery/reconciliation association may exist while the account lives,
then must detach at erasure. Exact retry returns the prior grant for that live account.
Two accounts sharing a marker cannot both win. Existing profile trigger's synchronous
signup grant must be refactored narrowly so eligibility failure cannot roll back
account/profile creation. Unknown eligibility = pending benefit, not billing failure.

Before activation, seed markers for provably claimed existing live accounts using
verified inputs, without creating credits. Historical already-erased subjects with
only old UUID ledger references cannot be reconstructed; disclose coverage start and
do not mine backups/answers to invent identity. A detected preactivation blind spot
requires a rollout incident decision, not a claim of universal retroactive coverage.

## Re-registration and erasure order

| State/event | Contract |
|---|---|
| NORMAL | Ordinary account; one verified benefit decision |
| PENDING login or email signup | Existing subject → restricted deletion status/reauth cancellation only; no additional account/credit |
| Cancellation before deadline | Explicit fresh authentication + locked state transition; no new benefit; new later deletion request gets its own fixed deadline |
| Deadline reached / cron late | Cancellation denied at now>=deadline; still restricted even before worker claims |
| ERASING | No cancellation, no re-registration through deleting credentials; stale tokens cannot access services |
| ERASED | Only after postconditions verified; creation allowed with new Auth UUID expected |
| RE-REGISTERED | Fresh operational account; known credential marker denies repeat3; no resurrection/rebinding of old finance or learning |
| Benefit store unavailable | Account creation/use ALLOW if lifecycle gate clear; free benefit DO_NOT_GRANT_YET, retry later |

Lifecycle identity blocking is distinct from benefit availability. Use a narrow Auth
creation gate (platform supports a [Before User Created hook](https://supabase.com/docs/guides/auth/auth-hooks/before-user-created-hook))
to block known pending/erasing credentials, including the gap after Auth delete but
before ERASED. Live hook payload/verified-input coverage must be tested; do not claim
configuration exists. Untrusted email can at most restrict a conflicting creation,
never authorize cancellation/linking. Gate cannot recognize unrelated hidden identities.
Lifecycle-store outage fails closed for potentially unsafe account creation; a healthy
lifecycle check with unavailable benefit store still allows creation. Identity-link/
email-change paths while pending must also be fenced. No frontend-only promise.

Order: due claim/fence → reconcile work → release reservations once → Essay/learning
erasure → E1 cascade → feedback/outbox → Storage/provider cleanup → finance privacy
detachment and ensure existing claimed-marker coverage → Auth hard delete LAST →
E2 SET NULL → verify all postconditions → remove direct request subject and release
rejoin restriction →30-day minimal receipt/restore control → automatic expiry.
Capture necessary verified marker coverage before losing Auth identity, preferably at
original grant time; erasure must not wait indefinitely for benefit analytics. If a
required benefit write fails, retain only necessary transient cleanup identity during
ERASING and retry; do not resurrect deleted content. Auth deletion timeout or unexpected
out-of-order success requires independent storage reconciliation and continued rejoin
gate, not false success. Finance detachment failure similarly remains an incident.

## Failure tests required in ADR-2

| Case | Required result |
|---|---|
| Delete/cancel/delete, repeated requests | Preserve events; same active request/deadline on retry; no admin reset |
| Two sessions / stale refresh JWT | Server gate blocks service; one cancellation/claim winner |
| Grace provider login/email signup | Existing pending restriction; no profile/grant recreation |
| Same provider or different provider same verified email after erase | New account permitted; existing marker denies benefit |
| Apple relay/subject changes | Only verified matches count; unknown linkage is disclosed, no inferred person |
| Benefit timeout/concurrent claims | Account unaffected if lifecycle clear; no grant on unknown; one atomic winner |
| Scheduler outage | Original deadline, overdue catch-up, no cancellation after due |
| Auth success + storage timeout | ERASING until independent absence check/cleanup; no success inference |
| Finance detachment failure | Retry narrow phase; immutable economic facts; no indefinite admin hold |
| Receipt purge failure | Overdue deletion alert/retry; expiry unchanged |
| Fingerprint rotation/loss | Multi-key lookup and incident plan; no silent benefit reset |
| Admin or student+reviewer deletion | Fixed deadline; E1 own subject erased, E2 other-subject reviews retained without reviewer identity |
| Backup restored | Closed service until obligations and benefit claims reconciled; no restore older than safe matching horizon |

## Bounded ADR-2 target and readiness

Implement only request/status/cancel authority, service predicate,336h deadline,
lease/fencing/phase retries, existing Essay release integration/HQP cascades,
feedback/storage cleanup, Auth-last erasure, narrow finance privacy detachment,
benefit markers using existing ledger,30-day receipt cleanup, scheduler/watchdog and
notification. Isolated tests and exact Owner package first. No generic workflow,
identity graph, ledger, analytics system or permanent tombstone.

External activation gates: verified provider/linking/hook/revoke coverage; actual
backup/restore horizon and independent obligation durability; category-specific
finance retention and anti-abuse disclosure; server secret custody/rotation and
scheduler deployment. No numerical legal retention duration is claimed. These
configurations can remain disabled while canonical implementation is developed.

**Can ADR-2 now be implemented without inventing a new Owner product/privacy policy?
YES — YES_WITH_EXTERNAL_GATES.** The Owner decisions supply the purpose boundaries;
activation must not silently replace them if a platform constraint fails validation.
No ADR-2 implementation is authorized by this document.

Seven preservation checks: distinct request/claim/completion/expiry times; financial
facts reproducible without unnecessary identity; correction versus erasure explicit;
one live Auth identity and purpose-separated non-universal markers; operational facts
not educational outcomes; bounded access/retention/reidentification risks documented;
no derived analytics treated as domain truth. Analytics remains a separate future gate.
