# Account Deletion & Privacy Lifecycle

## Native Apple gate — 2026-09-21

App iOS Apple native sign-in integration does not close account-deletion release
requirements. APPLE_ACCOUNT_DELETION_REVOKE remains OPEN; client deletion and server
candidate do not prove authorization/token revocation. No deployment or actual
account deletion was executed. Apple Web secret renewal and Owner-reported Google
credential rotation also remain OPEN; see [acceptance checklist](auth-native-owner-acceptance.md).


Status:
- **ACCOUNT DELETION FOUNDATION: IMPLEMENTED (client + server candidate), fail-closed**
- **PRODUCTION ACCOUNT DELETION: PENDING** — the function is not deployed and no
  account has been deleted by these tasks
- **PRIVACY LIFECYCLE: DESIGNED**

No Production mutation was made: no Dashboard change, no deploy, no Auth Admin
call, no DB write, no secret.

## Data inventory — every reference to auth.users

Read from the applied migrations, not from memory.

| table | link to the user | on delete | classification |
|---|---|---|---|
| `profiles` (display name, grade, NEIS school pair, D-Day) | `id` → `auth.users(id)` | **cascade** | DELETE_WITH_ACCOUNT |
| `bookmarks` | `user_id` → `auth.users(id)` | **cascade** | DELETE_WITH_ACCOUNT |
| `recent_views` | `user_id` → `auth.users(id)` | **cascade** | DELETE_WITH_ACCOUNT |
| `study_sessions` | `user_id` → `auth.users(id)` | **cascade** | DELETE_WITH_ACCOUNT |
| `mock_exam_attempts` | `user_id` → `auth.users(id)` | **cascade** | DELETE_WITH_ACCOUNT |
| `mock_exam_answers` | → `mock_exam_attempts` | **cascade** | DELETE_WITH_ACCOUNT |
| `admin_users` | `user_id` → `auth.users(id)` | **cascade** | DELETE_WITH_ACCOUNT (but see admin policy) |
| `feedback_submissions` | `user_id` → `auth.users(id)` | **set null** | ANONYMIZE (operational record) |
| `feedback_notifications` | → `feedback_submissions` | cascade | SYSTEM_RETENTION (survives, already de-identified) |
| content/exam/subject/resource tables | no user column | — | not user data |
| local study document (device) | `owners[<user id>]` | app-managed | DELETE_WITH_ACCOUNT, locally |

**Therefore no migration is required.** The schema was already built for this:
every user-owned row cascades from the auth user, and feedback is detached
rather than destroyed. Deleting the auth user is the whole deletion.

School, grade and D-Day are `profiles` columns, not separate tables. Study
timer history and mock-exam scoring are user-owned tables. Bookmarks and recent
views reference `auth.users` **directly**, not through `profiles`.

## Feedback policy

`feedback_submissions.user_id` is already `on delete set null`, so a deletion:

- keeps the report body, category, timestamps and diagnostics (operational
  record, needed to investigate a bug that a departed user reported),
- drops the link to the person,
- leaves `feedback_notifications` intact, because its parent row survives — the
  Email Worker keeps working and no foreign key breaks,
- cannot be blocked by a RESTRICT, so a deletion never fails on feedback.

Open Product/legal question (REVIEW_REQUIRED): whether the free-text body should
also be scrubbed when it contains self-identifying text. Not decided here.

## Admin policy — fail closed

`admin_users` cascades, so deleting an admin would silently remove an operator's
access. The delete-account candidate therefore refuses a caller who holds an
admin role (403 `admin_blocked`), and the app shows Korean copy pointing at the
operator. **Product Owner decision required** on whether an operator procedure
should exist for removing an admin account, and what it is.

## Architecture — server-authoritative

A client cannot delete an auth user: `anon`/`authenticated` have no such
privilege, and the Auth Admin API needs the service role, which must never be
shipped in an app. Widening RLS with broad client DELETE grants was rejected for
the same reason — it would give every signed-in session a standing delete grant
on user tables, for a once-in-a-lifetime action.

Chosen: **Supabase Edge Function with the service role, caller resolved from the
verified bearer token** (`supabase/functions/delete-account/`, candidate).

- `POST /delete-account`, no body. The body is never read, so a client cannot
  name a target; the token decides whose account is deleted.
- 401 unauthorized · 403 admin_blocked · 200 `{status:"deleted"}` · 500
  deletion_failed. No schema, no ids, no row counts. Nothing is logged.
- Idempotent: an already deleted user still answers `deleted`, so a retry or a
  double tap is harmless.

Order of operations: verify token → resolve caller → admin check → delete auth
user (one statement; Postgres performs every cascade inside it) → app purges the
local study space → local sign-out → guest state.

### Partial failure

The auth deletion and the app-side cleanup are not one transaction, but the
window is small and one-directional:

- **Server succeeded, app cleanup failed** — the account is gone; the device may
  still hold that owner's local study document. The next sign-in as a different
  user cannot read it (state is owner-keyed). The page shows server completion;
  retry runs only unfinished local cleanup/sign-out, never another deletion.
  This state is page-local, not a durable restart cleanup queue.
- **Server failed** — nothing is signed out, nothing local is purged, no success
  is claimed, and the user can retry.
- No `DELETION_REQUESTED`/`DELETING` state machine was built: a single cascading
  statement does not need one. If LS LAB later adds slow work (storage objects,
  export, billing), that is when the lifecycle states earn their place.

## Re-authentication

`AccountDeletionService.requiresRecentAuthentication` exists as a contract and is
`false` in v1. What counts as a recent authentication differs per provider, and
Google / Apple / Kakao have not been through production sign-in yet, so no rule
was invented. Two-step confirmation (explicit acknowledgement plus a final
dialog) is the current friction.

## OAuth implications

"회원탈퇴" means **the whole LegendStudy account**, not unlinking one provider.
Unlinking (`unlinkIdentity`) is a different feature and is not offered. Identity
linking behaviour is still unverified in production, so the copy does not
promise anything about other providers' accounts.

## Local device data

There is no `shared_preferences`, secure storage or database on the device. The
only persisted user data is the study document written through the native
channel, namespaced per owner (`owners[<user id>]`, `guest` when signed out).
`purgeStudyOwner` removes exactly one owner's space and leaves other owners and
the outbox untouched, which is also what keeps account switching clean.

## App Store / Google Play

Read from the official pages on 2026-09-18, not from memory.

**Apple** (developer.apple.com, "Offering account deletion in your app"): an app
that supports account creation must offer account deletion, and **deletion must
be initiated inside the app** — a non-regulated app may not require phoning or
emailing support. The whole account record and associated personal data must go,
unless retention is legally required. Reauthentication, confirmation steps and a
stated processing time are all explicitly allowed, as is linking out to a page
that completes the deletion — but the link must be direct. Users everywhere must
be offered it, not only in GDPR/CCPA regions. **Sign in with Apple accounts must
additionally have their tokens revoked through the Sign in with Apple REST API**
— LegendStudy offers Apple sign-in, so this is a real obligation once Apple
OAuth goes live and the current candidate does not do it.

**Google Play** (Play Console Help, account deletion requirements): an app with
account creation needs **both** an in-app deletion path **and** a web link where
deletion can be requested without reinstalling the app. That page must load,
name the app or developer, and make the deletion path prominent. The Data safety
form's data-deletion questions must be answered in Play Console, and the answers
appear on the store listing.

Consequences for LegendStudy: the in-app path exists here. The **web deletion
request URL does not exist yet** and depends on the undecided domain/hosting
question (`legendstudy.com` is Tistory) — Owner decision. The **Apple token
revocation step is an open gap** to close during Apple OAuth production work.

## Future LS LAB / Schools

The classification model is deliberately wider than "delete everything":
USER_CONTENT, PERSONALIZATION, TRANSACTION_RECORD, OPERATIONAL_RECORD,
ANONYMIZED_ANALYTICS. Essay attempts and evaluations would be USER_CONTENT;
credits, purchases and institution-issued entitlements are TRANSACTION_RECORD
and may have to survive a personal account deletion in de-identified form. A
student leaving does not imply a school's purchase record is erased. Nothing of
this is built, and no LS LAB schema exists yet.

## Implementation status

| piece | file | state |
|---|---|---|
| Service seam + Korean failure copy | `lib/features/auth/account_deletion.dart` | IMPLEMENTED |
| Fail-closed config flag | `lib/core/config/app_config.dart` (`ACCOUNT_DELETION_ENABLED`) | IMPLEMENTED, off |
| Deletion screen, two-step confirm | `lib/features/auth/presentation/delete_account_page.dart` | IMPLEMENTED |
| MY entry | `lib/features/profile/presentation/profile_page.dart` | IMPLEMENTED |
| Route `/my/delete-account` | `lib/app/router.dart` | IMPLEMENTED |
| Local purge | `lib/features/study/data/study_local.dart` | IMPLEMENTED |
| Edge Function | `supabase/functions/delete-account/` | CANDIDATE, not deployed |
| Flutter tests | `test/account_deletion_test.dart` | 16 PASS |
| Deno tests | `supabase/functions/delete-account/handler_test.ts` | 9 |
| Migration | — | not needed |

With the flag off MY retains the entry; its screen explains unavailability and
links to the existing feedback route. There is no disabled destructive CTA and
no fake success. This support fallback does not satisfy the release deletion gate.

2026-09-20: busy operations block back navigation; tests cover duplicate taps,
back while busy, server success/local failure retry with one server call, and
other-owner preservation. Full suite 446 PASS / 1 skip; analyze and Android/iOS
simulator builds PASS. Code candidate YES, last documented deployment NO (not
remotely queried in this task), config default OFF, Production E2E NO. Web deletion
request URL, Apple revocation and retention decisions remain Owner release gates.

## Private avatar dependency — 2026-09-23 candidate

Photo rollout adds one private Storage object per owner. New candidate cleanup
removes it via Storage API before auth deletion; storage failure aborts deletion,
already absent object remains idempotent. Server PROFILE_PHOTO_ENABLED stays off
until bucket + reviewed rollout. An auth deletion failure may follow successful
photo cleanup, so retry can find no photo. Auth lookup errors are not proof that
a user is already deleted. No deployment or real deletion performed in this task.
Owner rollout and rollback: [Database](database.md#private-profile-avatar--owner-applied).
ACCOUNT_DELETION_PRODUCTION_READY remains NO, including Apple revoke gate.

## Longitudinal analytics privacy review — 2026-09-24

[Canonical data strategy — Privacy and user rights](longitudinal-learning-admissions-data-strategy.md#privacy-and-user-rights)
adds future operational/analytics separation, purpose boundaries, minor/student
review, cohort suppression, retention/deletion and model-training gates.
Preserving history does not authorize indefinite retention. Pseudonymization is
not automatic anonymization or exemption from user rights. Historical cascade/
ANONYMIZED_ANALYTICS descriptions above do not settle future derived-data cleanup.
Inventory operational, pseudonymous and derived records before rollout; review
correction/deletion propagation, vendors, exports and least-privilege access.
[External/B2B sharing](longitudinal-learning-admissions-data-strategy.md#external-sharing-and-b2b-boundary)
needs separate Privacy/Legal/Governance review. No legal conclusion, consent model,
retention period or new processing authorization is decided here. Existing account
deletion/Apple revoke/Store gates remain OPEN; no code or Production mutation.
