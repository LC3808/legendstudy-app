# Day 11 — Account, Personal and Feedback Operations

Status: **implementation foundation complete; Production feedback package not
applied.**

Day 11 reuses the existing Supabase Auth/profile/bookmark/recent architecture.
No Production migration, RLS change, secret configuration, email delivery or
data mutation was executed.

## Audit matrix

| Area | Status | Evidence / boundary |
|---|---|---|
| Email/password signup/login | IMPLEMENTED | `AuthPage` uses existing Supabase SDK; real provider acceptance pending owner config |
| Google / Apple / Kakao | PARTIAL | OAuth calls and redirect contract exist; provider/dashboard/redirect setup not verified |
| Logout | IMPLEMENTED | local Supabase sign-out button; auth stream drives account state |
| Session persistence | IMPLEMENTED BY SDK / runtime pending | SDK owns persisted session; no custom token storage |
| Profile auto-create/reload | PARTIAL | login attempts owner profile upsert; no DB auth trigger; reload uses existing owner query |
| Account switch isolation | IMPLEMENTED | existing generation/auth identity guards and C2 tests |
| School persistence | IMPLEMENTED | authenticated profile school pair; guest remains session-only |
| Other settings | PARTIAL | grade profile field exists; Home expansion/navigation remain ephemeral |
| Bookmarks | IMPLEMENTED | C2 owner-scoped repository/RLS contract |
| Recent views persistence/order | IMPLEMENTED | server `viewed_at`, unique owner/content, descending query |
| Meaningful recent views | IMPLEMENTED | foreground-only 10-second tracker and meaningful actions |
| Recent individual/all delete | IMPLEMENTED | owner-scoped repository methods and MY confirmation UI |
| Feedback form | IMPLEMENTED | categories, title/body validation, diagnostics and duplicate-submit guard |
| Feedback DB/RLS | READY | draft SQL only; not applied |
| Admin role/inbox | PARTIAL/BLOCKED | server-managed `admin_users` design in draft; no Production inbox until applied |
| Email notification | NOT READY / CONFIG PENDING | outbox contract drafted; Edge Function/provider not implemented |

## Auth and identity

The app exposes email/password signup/login and OAuth entry points for Google,
Apple and Kakao. OAuth is not claimed as operational until the Supabase
provider settings and `com.legendstudy.app://login-callback` redirect are
configured and tested. No automatic identity merge is performed: different
provider identities may create separate accounts, even when an email appears
similar. Account merge requires an explicit future security design.

Supabase SDK session persistence is retained; access/refresh tokens never enter
`AuthStatus`, UI state, logs or repository-owned storage. After successful
password/OAuth session creation, the client attempts an owner-derived profile
upsert. This is a convenience retry path, not an auth trigger, so the owner
must still verify profile creation under the deployed grants.

## Settings inventory

| Data | Storage | Account scoped | Cross-device | User deletable |
|---|---|---:|---:|---:|
| School selection | `profiles` cloud | yes | yes | clearable |
| Display name / grade | `profiles` cloud | yes | yes | nullable/updateable |
| Bookmarks | `bookmarks` cloud | yes | yes | individual |
| Recent views | `recent_views` cloud | yes | yes | individual/all |
| Home expansion | widget state | no | no | disappears with screen |
| Navigation/session UI | ephemeral | no | no | n/a |
| Feedback | `feedback_submissions` draft | optional owner | server record | future owner policy |

Guest school selection remains session-only. There is no automatic guest-to-auth
school migration, avoiding silent cross-account attribution; this is a future
product decision if needed.

## Meaningful recent views v2

`meaningfulRecentViewThreshold` is one constant: 10 foreground seconds. The
detail tracker pauses on inactive/paused/detached lifecycle states and resumes
only on `resumed`; background wall-clock time is excluded. A detail lifecycle
records at most once when either:

- foreground dwell reaches 10 seconds; or
- the user attempts to open a resource/original page, or successfully saves the
  item.

An explicit resource-open attempt qualifies intent even if the platform launch
fails. A guest save prompt does not call the bookmark repository and therefore
cannot qualify a cloud recent view. Revisit uses the same threshold, so a quick
reopen does not advance `viewed_at`.

The existing server contract remains: `recent_views` is unique on
`(user_id, content_item_id)`, upsert updates the server `viewed_at` trigger, and
queries order by `viewed_at desc, id desc`. MY now supports owner-only single
delete and confirmed delete-all. Home remains a bounded read-only projection.

## Feedback architecture

`FeedbackPage` is available to guests and authenticated users. It collects:
category (`inquiry`, `bug`, `suggestion`, `other`), title and body, and attaches
app version/build, platform, OS version and locale. It never collects tokens,
keys, passwords, device identifiers or precise location. Payloads are bounded
to title 120 and body 5000 characters; submit is disabled while in flight.

The draft package in
`supabase/drafts/20260916000100_feedback_operations.sql` defines:

- `feedback_submissions` with server-default `new` status and optional owner;
- `admin_users`, managed only by Owner/service role;
- `feedback_notifications` as a minimal email outbox;
- owner/guest insert policies, owner read policy and server-derived admin
  select/status policies;
- an insert trigger that enqueues notification state without making email part
  of the feedback transaction.

The draft is deliberately outside `supabase/migrations/` and was not applied.
Feedback persistence is the source of truth; email failure must never roll back
the user submission.

Admin inbox UI is deferred until the Owner applies and verifies the package.
The client never decides admin status and never calls an email provider.
Admin push is LATER because no push infrastructure exists in this repository.

## Muselry follow-up

Muselry was not modified. Future work should separately design and implement
the same inquiry/feedback storage, server-derived admin inbox, email delivery
and optional admin push pattern while keeping the two repositories and
databases independent.

## Essay Lab

Essay Lab remains HOLD: E1 inventory complete, E2 evaluation harness prepared,
actual AI evaluation not started. Day 11 adds no Essay Lab code or schema.

## Owner actions before Production use

1. Review and explicitly apply the draft SQL through the normal Supabase
   preflight/migration process.
2. Add the intended admin user to `admin_users` using an owner/service-role
   operation; never expose this as a client setting.
3. Configure OAuth providers and callback URLs for Google/Apple/Kakao, then run
   real interactive acceptance.
4. Implement/deploy the server-side Edge Function/outbox worker and configure
   `LEGENDSTUDY_ADMIN_EMAIL` plus provider secrets in Supabase secrets only.
5. Send one controlled test email and verify inbox/status retry behavior.
6. Re-run authenticated/guest RLS acceptance, recent deletion acceptance,
   account switch/session restore and feedback/admin acceptance.
