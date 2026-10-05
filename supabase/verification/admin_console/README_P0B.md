# ADMIN-P0-B — Credit grant boundary, payment operations read, 1:1 inquiry

Migration: `supabase/migrations/20261005000300_admin_console_p0b.sql`
Verification: `supabase/verification/admin_console/behavior_p0b.sql`

## What this adds

| Surface | Entry point | Authorization |
|---|---|---|
| Payment operations read | `public.admin_payment_orders(jsonb)` | `public.admin_operator()` |
| Member inquiry submit | `public.inquiry_submit(jsonb)` | `auth.uid()` |
| Member inquiry list | `public.inquiry_mine(jsonb)` | `auth.uid()`, own rows only |
| Operator inquiry list | `public.admin_inquiry_list(jsonb)` | `public.admin_operator()` |
| Operator inquiry detail | `public.admin_inquiry_detail(jsonb)` | `public.admin_operator()` |
| Operator reply | `public.admin_inquiry_reply(jsonb)` | `public.admin_operator()` |
| Operator status change | `public.admin_inquiry_set_status(jsonb)` | `public.admin_operator()` |
| Dashboard support metrics | `public.admin_support_metrics()` | `public.admin_operator()` |
| Delivery queue claim | `public.claim_inquiry_notifications(integer)` | `service_role` |
| Delivery queue complete | `public.complete_inquiry_notification(...)` | `service_role` |

## What this deliberately does NOT add

- No Credit write path. `public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz)`
  remains the only grant entry point, it is executable by `essay_finance` alone, and
  a browser role cannot reach it. The console reaches it through a server boundary
  that holds the finance bearer.
- No order action path. `public.payment_support(jsonb)` remains finance-only.
- No new email service. Replies queue on `public.inquiry_notifications`, drained by
  a function that reuses the existing Resend provider and claim/retry shape.

## Why a new inquiry model instead of `public.feedback_submissions`

`feedback_submissions` is the APP feedback form: `app_version`, `build_number`,
`platform` and `os_version` are NOT NULL, and its notification queue mails the
operator. A LAB web inquiry has none of those values and needs the reply mailed to
the member, so reusing it would mean fabricating build metadata. The additive model
here reuses the same queue semantics and the same delivery provider instead.

## Harness notes

`harness.sh` creates `essay_executor` WITH BYPASSRLS and `essay_worker` /
`essay_finance` WITHOUT it, matching `20260928000300_essay_server_operations.sql`.
A pre-created role with the wrong RLS posture is silently kept by that migration's
`if not exists` guard, which makes `credit_post_grant` see zero profiles and raise
`INVALID_GRANT`. The harness now asserts the attributes rather than assuming them.

`behavior.sql` installs a structural stand-in for `public.payment_orders` whose
column set mirrors `20261003000100_payment_foundation`. `behavior_p0b.sql` drops it
in section D to exercise the genuinely absent path, where the read must report
`NOT_INSTALLED` and a JSON null rather than a fabricated zero.
