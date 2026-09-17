# Auth Recovery Foundation

Status: **IMPLEMENTED (application code) / PRODUCTION CONFIG PENDING.**
No Supabase dashboard setting was changed, no redirect URL was registered and
no recovery email was sent.

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

### Redirect URL — deliberately not invented

`AppConfig.recoveryRedirectUrl` comes from the `SUPABASE_RECOVERY_REDIRECT`
define and defaults to empty. `recoveryRedirectTo` returns null when empty, so
the SDK falls back to the project's Site URL. **No LegendStudy recovery URI
scheme or host was decided or hard-coded here.** The existing OAuth callback
`com.legendstudy.app://login-callback` was left alone and not reused for
recovery, because that is a product decision the Owner has not made.

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

1. **Production recovery redirect URL configuration** — decide the LegendStudy
   recovery URI (scheme/host or a universal link), register it in the Supabase
   dashboard's redirect allow-list, and pass it as `SUPABASE_RECOVERY_REDIRECT`.
2. **Real recovery email end-to-end** — never exercised; no email was sent.
3. **Universal / app link acceptance on a physical device** — the app has no
   `app_links` wiring of its own; `supabase_flutter` handles the deep link, and
   that path is unverified.
4. **OAuth completion** — Google / Apple / Kakao remain unconfigured.
5. **Account deletion** — out of scope, not started.
6. **Flutter validation on the Owner's machine** — see below.

## Validation status

`flutter analyze` and `flutter test` could **not** be executed in the session
environment: only the repository folder is mounted and it carries no Flutter
SDK, and the Owner's macOS SDK cannot run there. Static structure and a
credential scan were checked instead. The Owner must run:

```
/Users/woojinchang/development/flutter-3.47/bin/flutter analyze
/Users/woojinchang/development/flutter-3.47/bin/flutter test test/auth_recovery_test.dart
```

Until those pass, treat this commit as code-complete but unverified.
