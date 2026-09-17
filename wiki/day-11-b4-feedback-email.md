# Day 11-B4-A — Feedback Email Notification Design

Status: B4-A DESIGN COMPLETE; B4-B IMPLEMENTED / NOT DEPLOYED. No secret is
configured, no email was sent and no Production mutation was performed.

## Current Production contract

`feedback_submissions` is the source of truth. Its insert trigger creates one
`feedback_notifications` row per feedback with a unique `(feedback_id,
channel)` key. The current outbox columns are `id`, `feedback_id`, `channel`,
`status`, `attempt_count`, `last_error_code`, `created_at`, and `sent_at`.
`status` is constrained to `pending`, `sent`, or `failed`; `sent` requires
`sent_at`. Client roles have no outbox access. The Production-verified trigger
and RLS boundary remain unchanged by B4-A.

## Provider decision

Recommended provider: **Resend**, behind a provider-neutral worker adapter.

- Resend has a simple HTTP email API and Supabase documents an Edge Function +
  Resend integration. The API supports `Idempotency-Key` on `POST /emails`,
  retained for 24 hours; B4-B should use a stable key such as
  `feedback-email/<feedback_id>` rather than a random value.
- Postmark and Amazon SES remain viable alternatives. Postmark is worth
  reconsidering if deliverability/support becomes the priority; SES is worth
  reconsidering when volume or AWS consolidation outweighs additional setup.
  Neither has a clear B4-A advantage for the current low-volume case.
- Resend pricing was checked 2026-09-17 and currently lists Free as $0/month,
  3,000 emails/month and 100 emails/day. Verify again before launch; pricing
  and quotas are not architecture invariants.

References: [Supabase Send Email](https://supabase.com/docs/guides/functions/examples/send-emails),
[Supabase Scheduling Edge Functions](https://supabase.com/docs/guides/functions/schedule-functions),
[Resend pricing](https://resend.com/pricing),
[Resend idempotency keys](https://resend.com/docs/dashboard/emails/idempotency-keys).

## Domain and recipient configuration

- Recommended sender: `feedback@legendstudy.com`, subject to Owner domain
  verification. `notifications@...` is the fallback naming option; avoid
  `noreply@...` if replies may become useful support traffic.
- Recipient is server configuration only: `LEGENDSTUDY_ADMIN_EMAIL`. It must
  never come from Flutter, feedback columns or user input. The Auth admin
  account address is not inherently the notification destination.
- Required B4-B configuration, stored only in Edge Function Secrets or
  protected scheduler Vault configuration: `RESEND_API_KEY`,
  `LEGENDSTUDY_ADMIN_EMAIL`, `LEGENDSTUDY_EMAIL_FROM`, and
  `FEEDBACK_WORKER_INVOKE_SECRET`. No values belong in Git, Flutter, SQL or
  this Wiki.
- Owner actions are account/domain creation, DNS verification, sender choice,
  API key creation, secret configuration and recipient confirmation. B4-A
  performs none of these actions.

## Worker and invocation model

Worker location: `supabase/functions/process-feedback-notifications/` as a
Deno/TypeScript Supabase Edge Function, following the existing `neis`
function convention. B4-A intentionally does not create the function.

Recommended invocation is Supabase Cron/`pg_cron` + `pg_net` on a short
schedule, initially once per minute. The endpoint is not a client API. If
deployed with JWT verification disabled for scheduler compatibility, it must
require and constant-time-check `FEEDBACK_WORKER_INVOKE_SECRET`, reject
browser/client requests and reject missing/invalid methods or headers. The
scheduler must not transmit a service-role key. Supabase documents scheduled
Edge Function invocation with `pg_cron` and `pg_net` and protected Vault
storage for scheduler credentials.

Flutter only inserts feedback. It never invokes the worker, reads outbox,
chooses a recipient or waits for delivery.

## Claim, idempotency and schema decision

The current schema is **not sufficient for a safe concurrent claim** using only
service-role SELECT followed by UPDATE: two invocations could read the same
pending row. Reusing `failed` as a working state would also make operations
ambiguous.

B4-B migration candidate adds `processing` to the
status constraint, `next_attempt_at timestamptz`, `claimed_at timestamptz`, and
server-generated `claim_token uuid`, plus a partial index for claimable rows.
It should add narrowly scoped `SECURITY DEFINER` claim/finalize functions with
`set search_path = ''`, fully qualified names, revoked PUBLIC/anon/authenticated
execution and service-role-only execution. Claim uses `FOR UPDATE SKIP LOCKED`,
sets processing, increments attempts once, records a lease/token and returns
only the job plus required feedback fields. Finalize requires notification ID
and claim token so a stale worker cannot finalize a later claim.

Resend’s stable idempotency key is an additional duplicate-send defense, not a
replacement for the DB claim/lease. Its 24-hour retention means long outages
still require DB state and reconciliation.

## Retry and state transitions

Proposed B4-B policy, to be tested and not applied here:

- Success: `pending → processing → sent`; set server `sent_at` and clear
  `last_error_code`.
- Temporary network/5xx/429 failure: `processing → failed`, with bounded error
  code and exponential backoff in `next_attempt_at`.
- Permanent configuration/provider rejection: `processing → failed` without
  immediate automatic retry after classification.

Use the existing database ceiling of 8 attempts while initially allowing 3
delivery attempts before terminal failure; B4-B must make and test this
distinction. Lease expiry returns abandoned processing jobs to retryable state
without creating a new row.

`last_error_code` stores only allowlisted short codes such as `provider_429`,
`provider_5xx`, `network`, `invalid_config` or `permanent_rejection`. Never
store keys, authorization headers, raw provider responses, request bodies or
email addresses.

## Email contract and privacy

Use a fixed category-based subject, for example
`[LegendStudy] 새 문의가 접수되었습니다 — 기능 제안`. Do not concatenate the
user title into the subject. Send only category, title, body, received time,
app version, platform/OS and feedback ID. Do not include JWTs, tokens, full
auth/profile metadata, precise location, device identifiers or recipient
selection data.

Prefer plain text. If HTML is used, escape every user-controlled title/body
value and test newline, Unicode and long content. Logs may contain job ID,
feedback ID, state, bounded provider status code, attempt and duration, but not
body content, recipient email, API keys or service-role credentials.

Feedback persistence and Admin Inbox visibility are independent of delivery.
The insert transaction never calls Resend. Provider outage leaves feedback
available and the job pending/failed for retry; the app keeps showing the
successful feedback receipt message.

## B4-B implementation result

Implemented locally in `supabase/functions/process-feedback-notifications/`:

- secret-gated POST handler with configuration validation before claim;
- service-role Supabase adapter for claim, feedback-by-ID, finalize and lease
  reclaim RPCs;
- provider-neutral `EmailProvider` plus plain-text Resend adapter;
- stable `feedback-email/<feedback_id>` idempotency key, bounded batch 10,
  allowlisted error classification and redacted operational logs;
- Deno offline test source plus Python SQL/source contract tests.

The source is **not deployed**. Deno tests could not be executed in this
environment because the `deno` binary is unavailable; the static contract
tests and Python compile checks pass.

## Deployment and rollback package

Deployment order for B4-Candidate review: independently review/apply the
migration, verify domain and secrets out-of-band, inspect pending count
read-only, deploy the function with scheduler blocked, run local/staging tests,
then create the one-minute scheduler and enable it. Never put a service-role
key in scheduler headers.

Safe disable: stop/unschedule the scheduler and block the invocation secret;
feedback insert and Admin Inbox remain active. Do not drop tables or delete
outbox rows as rollback. A migration rollback is non-trivial after rows enter
`processing`; first drain/disable the worker and reconcile claims, then use a
separately reviewed backward migration only if data/state can be preserved.

## B4-B implementation contract

The next owner review must cover SQL function ownership/grants, claim lease
duration, three-attempt worker policy versus the database ceiling of eight,
Resend domain/configuration, Deno tests, pending-row handling and the absence
of a public client invocation path.

## B4-C and security

B4-C should use exactly one `[TEST] Feedback Email E2E <run-id>` fixture,
verify persistence, one outbox row, claim, one received email, `sent` and
`sent_at`, then perform explicit-ID cleanup by policy. B4-A sends nothing.

Public invocation is scheduler-secret protected; forged jobs/recipients are
impossible because the request supplies neither; duplicate sends use atomic
claim plus provider idempotency; secrets stay in Edge Function/Vault; user
content is plain text or escaped; logs are bounded; each claim reads only its
own feedback; service-role credentials never reach client, scheduler headers,
email body or logs.
