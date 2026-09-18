# Auth Recovery Foundation

Status: **CODE VERIFIED / PRODUCTION READINESS PREPARED; PRODUCTION RECOVERY
E2E PENDING.** The application foundation is verified and the deep link the
recovery email must open is now registered on both platforms. Registering the
redirect URL in Supabase, a real recovery email, and physical-device acceptance
remain Owner-side Production gates. No recovery email has ever been sent.

## What exists now

| piece | file |
|---|---|
| Korean error mapping | `lib/features/auth/auth_errors.dart` |
| Recovery seam + validation constants | `lib/features/auth/auth_recovery.dart` |
| Recovery request screen | `lib/features/auth/presentation/password_recovery_page.dart` |
| New password screen | `lib/features/auth/presentation/new_password_page.dart` |
| Entry point + mapped errors on login | `lib/features/auth/presentation/auth_page.dart` |
| Routes and recovery-event routing | `lib/app/router.dart` |
| Auth change event on the UI state | `lib/core/supabase/supabase_providers.dart` |
| Configurable redirect | `lib/core/config/app_config.dart` |

Routes: `/auth/recovery` and `/auth/new-password`, both wrapped in the existing
`NestedPage`. No new design system; `ShellPage`, `SectionHeader` and `AppTokens`
are reused.

## Contracts

- Request: `client.auth.resetPasswordForEmail(email, redirectTo: …)`.
- Update: `client.auth.updateUser(UserAttributes(password: …))`.
- Both sit behind `AuthRecoveryService`, so widget tests drive the screens with
  an in-memory double and no network call is reachable from a test.

### Redirect URL and deep link

`AppConfig.recoveryRedirectUrl` comes from the `SUPABASE_RECOVERY_REDIRECT`
define and defaults to empty. `recoveryRedirectTo` returns null when empty, so
the SDK falls back to the project's Site URL.

The recovery link the platforms are configured for is
`com.legendstudy.app://auth-recovery`, declared once as `recoveryDeepLink` in
`lib/features/auth/auth_recovery.dart`:

| platform | registration |
|---|---|
| iOS | `CFBundleURLTypes` in `ios/Runner/Info.plist`, scheme `com.legendstudy.app` |
| Android | VIEW/BROWSABLE intent-filter in `AndroidManifest.xml`, `host="auth-recovery"` |

A custom scheme, not a universal link, because `legendstudy.com` is served by
Tistory: `/.well-known/apple-app-site-association` and
`/.well-known/assetlinks.json` both return 404 and cannot be hosted there, so a
universal link would block recovery on an undecided domain. The scheme equals
the bundle id / application id and matches the OAuth callback the app already
uses (`com.legendstudy.app://login-callback`), so nothing new was invented.

The value is **not** applied automatically. The Owner registers it in the
Supabase redirect allow-list and passes
`--dart-define=SUPABASE_RECOVERY_REDIRECT=com.legendstudy.app://auth-recovery`.
Android's filter is scoped to the `auth-recovery` host, so enabling OAuth later
needs its own `login-callback` filter.

### A link that cannot be used

gotrue reports an expired, already-used or wrong-device link as an **error on
the auth state stream**, not as an event, so it used to be silent.

That error must not become the provider's error. Riverpod 3 retries a failed
provider automatically (first backoff 200ms, doubling) and a rebuild here only
re-subscribes to the same SDK stream, so the retry cannot recover; meanwhile
`triggerRetry` reports `AsyncLoading(retrying: true)` rather than an error, so a
listener's `onError` never runs, and every widget reading the provider would
lose the user id because a link expired. `withAuthFailures` therefore carries
the failure as a value beside the last known identity, and `authStateProvider`
sets `retry: (_, _) => null`.

The router reads that carried failure, filters it with `isRecoveryLinkFailure`
and opens `/auth/recovery?reason=link`, which shows "재설정 링크를 사용할 수
없어요. 다시 요청해 주세요." Other auth failures are ignored there so they cannot
hijack navigation. Only `reason=link` travels in the route — never a token or
address.

### Cold start needs no recovery intent state

`onAuthStateChange` is a `BehaviorSubject`, so a new subscriber is replayed the
last auth state, and `supabase_flutter` starts its deep-link observer inside
`Supabase.initialize` (before `runApp`). Combined with
`ref.listen(..., fireImmediately: true)`, a recovery event raised before the
router exists is still seen. No persistent recovery-intent state was added.
Known limit: a BehaviorSubject replays only the newest event, so an event
emitted immediately after `passwordRecovery` could mask it; not reproduced, and
intent state is the fix if it ever is.

### Recovery session is not an ordinary session

`AuthStatus` now carries the `AuthChangeEvent` that produced it and exposes
`isPasswordRecovery`. The router listens for that event and routes to
`/auth/new-password`; an ordinary `signedIn` event does not. The recovery token
itself is never read, logged or placed in a route — only the event is observed.

`/auth/new-password` renders no form at all without a session, because
`updateUser` requires one; it offers "재설정 메일 다시 요청" instead.

## Account enumeration

The request screen shows one success message regardless of whether the address
has an account: "비밀번호 재설정 안내를 확인해 주세요." Supabase answers
`resetPasswordForEmail` the same way in both cases, so the UI does not need —
and does not have — a "가입되지 않은 이메일" branch.

## Password policy

The client enforces only a minimum length of 8 and that the two fields match.
The project's real policy is not readable from this repository, so no further
rule was invented; a server rejection (`weak_password`, `same_password`) is
surfaced through the Korean mapper instead.

## Error localization

`authErrorMessage` matches the stable `AuthException.code` first, then lowercase
message substrings, and falls back to
"요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요." Raw SDK English,
tokens, URLs and status codes never reach the user. The reported
`Invalid login credentials` now renders as
"이메일 또는 비밀번호가 올바르지 않습니다."

## PENDING — Owner / production

1. **Supabase redirect allow-list** — register
   `com.legendstudy.app://auth-recovery`, and confirm the project Site URL,
   which is where an unmatched redirect (and any desktop user) lands.
2. **A mailbox that actually receives mail** — an Auth user's address is not
   proof of a mailbox. PKCE also requires the link to be opened on the same
   install that requested it.
3. **Real recovery email end-to-end** — never exercised; no email was sent.
4. **Deep-link acceptance on a physical device** — the registration exists now
   but has not been exercised on hardware.
5. **OAuth completion** — Google / Apple / Kakao remain unconfigured, and
   Android needs a `login-callback` intent-filter of its own.
6. **Account deletion / privacy lifecycle** — not implemented.
7. **Flutter validation on the Owner's machine** — see below.

## Validation status

Owner verification on official Flutter 3.47.3 completed:

```
/Users/woojinchang/development/flutter-3.47/bin/flutter test test/auth_recovery_test.dart
# 19 tests PASS
/Users/woojinchang/development/flutter-3.47/bin/flutter test
# 368 PASS, 1 existing opt-in test skipped
/Users/woojinchang/development/flutter-3.47/bin/flutter analyze
# No issues found
```

Production recovery E2E is intentionally still pending; no redirect registration,
recovery email receipt, password change or physical-device recovery acceptance
is claimed here.

The 2026-09-18 readiness pass (deep-link registration, unusable-link UX, 27
focused tests) is **not** revalidated on the Owner's machine yet — see
`Claude outputs/legendstudy-auth-recovery-production-readiness.md` for the full
prerequisite matrix and handoff order.
