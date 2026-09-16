# Day 11-B1 — Feedback production security package

Date: 2026-09-17. Production apply: **NOT PERFORMED**.

## Scope and architecture

The reviewed candidate is `supabase/migrations/20260917000100_feedback_operations.sql`.
The original `supabase/drafts/20260916000100_feedback_operations.sql` remains
unchanged and is not a production migration. Feedback is the source of truth:
the insert trigger creates one `feedback_notifications` email outbox row, and a
future server worker sends email asynchronously. A provider failure changes the
outbox state and never intentionally deletes or rolls back a persisted feedback
row. Trigger failure is an availability failure and rolls back the transaction,
which avoids silent outbox loss; this trade-off must be accepted before apply.

The client submits category, title, body and bounded diagnostic fields only.
`user_id` defaults from `auth.uid()` and is omitted by Flutter. Status and all
timestamps are server-controlled. No recipient address is stored in either
table; the future worker will read a server-side secret/config value.

## Security findings and decisions

- Anonymous guests may insert only a new feedback row with a NULL owner.
- Authenticated users may insert only a row whose server-derived owner is their
  JWT identity, and may read only their own rows.
- No normal client may update or delete feedback. Admin status update is the
  only authenticated update path in v1.
- `admin_users` has RLS and no anon/authenticated table grants or policies.
  Membership is owner/service-role controlled out-of-band; no admin UUID/email
  is included here.
- All three functions are explicitly qualified where they access objects and
  use `search_path = ''`; only `is_feedback_admin()` is executable by
  authenticated users because it is referenced by RLS.
- Outbox rows have a unique `(feedback_id, channel)`, bounded attempts, and a
  sent timestamp/state consistency check. Only trusted server code receives
  outbox grants.
- Diagnostic values are client claims for operations only and are never used
  for authorization, routing, or secrets.

## Open decisions / residual risk

1. Account deletion currently uses `ON DELETE SET NULL` to preserve support
   records. Product Owner must confirm this retention/privacy choice against
   the future account-deletion policy.
2. Admin status reverse transitions are allowed by the v1 check constraint;
   the future inbox may choose a monotonic UI workflow or an explicit review
   policy.
3. Guest abuse protection is bounded payloads plus client duplicate-submit
   guard in v1. Add edge/WAF/rate limiting only if observed abuse requires it.
4. The trigger gives strong enqueue reliability but makes an unavailable
   outbox table/function an insert outage. Monitor this before considering a
   more distributed design.
5. The worker still needs safe claiming, provider-neutral send abstraction,
   retry/backoff, redacted logging and idempotent completion before email is
   enabled.

## Required order after independent review

Owner review → apply candidate manually → execute acceptance SQL with marked
test data → assign admin out-of-band → implement/deploy worker with secrets →
build Admin Inbox. B1 does none of these Production actions.
