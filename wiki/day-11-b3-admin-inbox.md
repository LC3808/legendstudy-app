# Day 11-B3 — Admin Inbox

Status: COMPLETE; Production E2E PASS.

## Scope

- Added a server-derived admin check using `is_feedback_admin()` through the
  authenticated Supabase session. No email or UUID is used for authorization.
- Added the MY → 관리자 → 문의 관리 entry and guarded feedback list/detail
  routes. Guest and normal-user access is denied at the page boundary; the
  already Production-verified RLS remains the final boundary.
- Added newest-first feedback listing with a bounded limit of 50, status
  filters, Korean category/status labels, detail diagnostics, loading/empty/
  error/retry states and forward-only `new → reviewing → resolved` actions.
- Status mutations are guarded against duplicate taps and the returned row is
  checked before refreshing detail state. Failed mutations leave the previous
  state visible.

## Production state

Production feedback migration, Guest/Auth JWT/RLS acceptance, admin bootstrap
and Admin JWT acceptance are complete. Owner-confirmed physical E2E on a new
iPhone running iOS 26.4.2 passed: feedback submission, Admin Inbox list/detail,
diagnostics, `new → reviewing → resolved`, and list/detail synchronization.

The login follow-up now waits for the matching authenticated identity before
leaving the login page, then returns to the prior route or falls back to `/my`
when there is no route to pop. No arbitrary delay is used.

This follow-up made no Production mutation.

## Deliberately pending

- Email Worker, provider selection, secrets, admin email delivery and test
  email are not implemented.
- `resolved → reviewing/new` reverse transitions remain an Owner policy
  decision and are not exposed in this UI.
- Account-deletion feedback retention/anonymization remains an Owner policy
  decision.

## Validation

Focused auth/school/Admin Inbox regression tests and `flutter analyze` pass.
Full Flutter tests and Android/iOS simulator builds pass; physical iPhone E2E
is Owner-confirmed as above.
