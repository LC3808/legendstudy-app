# Day 11-B4-A — Feedback Email Notification Design

Status: DESIGN COMPLETE; no Worker deployed, no secret configured, no email
sent and no Production mutation performed.

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

B4-B should prepare a small migration candidate adding `processing` to the
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

## B4-B implementation contract

1. Add the smallest reviewed claim/lease/retry migration and service-role-only
   claim/finalize functions.
2. Implement `process-feedback-notifications` with method/invocation-secret
   validation, bounded batch, provider-neutral `EmailProvider` interface and
   Resend adapter.
3. Claim, send with `feedback-email/<feedback_id>`, finalize by claim token,
   and classify errors without payload leakage.
4. Add fake-provider tests for success, temporary/permanent failure,
   backoff/max attempts, lease recovery, concurrent claims, duplicate
   invocation, escaping, missing secrets and invalid recipient configuration.
5. Gate deployment on SQL/Deno tests, credential scan, Owner migration/domain/
   secret review and a read-only pending-count check. Deploy disabled or
   scheduler-blocked before enabling it.

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
