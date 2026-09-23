# Auth Recovery Foundation

## App native/shared-account follow-up — 2026-09-21

Google now uses the native SDK on Android/iOS; iOS Apple uses native ID-token
exchange; Kakao and Android Apple retain browser OAuth. Official-source local
marks, common social-button geometry and LegendStudy Account copy replace the
text-only fallback. Direct login returns Home; protected return stays intact.
Google flag additionally requires public client config; missing iOS scheme fails
safely before SDK launch. Native credentials never enter UI state or logs.

Owner reports LAB Web Email/verification/recovery/Google/Kakao/Apple/session E2E
PASS on 2026-09-21. That supersedes earlier LAB-unverified context only for those
reported Web flows, not App native or shared identity. Same account does not mean
shared session. Opt-in debug-only GET comparison checks SDK/server/expected owner
without displaying/storing IDs. Profile/release never exposes the checker.

Owner current checkpoint: App and LAB Email/Apple/Google/Kakao login PASS;
App Profile-build session restore PASS; Apple/Google LAB/App shared identity PASS.
Kakao shared identity NOT VERIFIED. App recovery mailbox/device matrix is not
inferred from login success. Earlier 2026-09-20 pending tables below are historical.
See [current status](current-status.md) and [native acceptance](auth-native-owner-acceptance.md).

2026-09-23 routing correction: direct login always goes Home. Protected callers
use internal extra=true to request a safe existing navigation-stack return. An
arbitrary returnTo query is not interpreted. All providers use the same signedIn
handler; initialSession/restore is not a new-login navigation event. Login helper
copy is now one sentence, without LegendStudy Account duplication.
Apple revoke/renewal, Google rotation and account-deletion release gates stay OPEN.


Status: **CODE VERIFIED / PRODUCTION READINESS PREPARED; PRODUCTION RECOVERY
E2E PENDING.** The application foundation is verified and the deep link the
recovery email must open is now registered on both platforms. Registering the
redirect URL in Supabase, a real recovery email, and physical-device acceptance
remain Owner-side Production gates. This task did not send a Production recovery email; prior mailbox acceptance is not assumed.


## Account lifecycle completion review — 2026-09-20

**CODE READY; PRODUCTION CONFIGURATION UNVERIFIED; PRODUCTION E2E PENDING;
OWNER ACTION REQUIRED.** Existing email/OAuth/recovery/profile/logout/deletion
architecture is reused. No account lookup API, new identity store, LAB code,
Production configuration or mutation was introduced.

- Signup retains email/password/confirmation, validation, busy guard and safe
  copy. The actual SDK response's session presence determines immediate sign-in
  versus conditional email-verification guidance; client flags do not guess the
  server Confirm Email policy. Duplicate-account copy avoids confirming identity.
- `SUPABASE_SIGNUP_REDIRECT` now centrally supplies signup `emailRedirectTo`.
  Empty preserves SDK/Supabase Site URL fallback; it does **not** establish app
  verification return. Owner should configure the existing native callback
  `com.legendstudy.app://login-callback` and allow-list it in the dedicated project.
- Recovery remains `SUPABASE_RECOVERY_REDIRECT`, expected
  `com.legendstudy.app://auth-recovery`, separately allow-listed. Both callback
  registrations already exist on Android/iOS. These are build defines, not
  dynamically loaded secrets. No actual deployment/config was changed.
- PKCE link exchange requires the initiating installation's verifier. A link on
  another device/reinstall is not promised to work. Expired/reused/malformed
  links use safe error classification and re-request guidance. Router tests cover
  warm events and initial replay; the previously documented cold-start event
  replay race still requires real email/device acceptance.
- SDK initial events can contain expired persisted sessions before refresh.
  Expired/malformed/missing-expiry sessions now expose Guest identity until a
  valid SDK session arrives. This event guard is not a new token validator or
  expiry scheduler; refresh remains SDK-owned. Existing transient stream-error
  handling and server authorization remain unchanged.
- New-password submit requires current identity; owner changes clear fields and
  suppress stale completion/navigation. Duplicate submissions remain blocked.
  The existing authenticated-session update contract is retained (not restricted
  to a recovery event); success retains the SDK session and opens MY.
- “가입한 이메일을 잊으셨나요?” gives original-provider guidance and reuses Guest
  feedback at `/auth/support`, returning to Auth with Back. No email address is
  looked up. Auth shows policy links only for configured safe web URLs; missing
  URLs remain hidden. No placeholder URL was added.
- Canonical identity remains the dedicated LegendStudy `auth.users.id`, used by
  profiles and personal data. Future LAB must use that same project/identity;
  actual LAB auth configuration has not been inspected. No token/cookie/session
  handoff or shared WebView was added. Account linking/duplicate identities need
  Owner acceptance, not email-based client merging.

### Readiness and Owner acceptance

| Area | Code/local evidence | Production configured | Production E2E | Owner action |
|---|---|---|---|---|
| Email login/signup | Existing UX + SDK response tests | Not inspected | Pending | Confirm Email/SMTP policy, real mailbox and return |
| Email verification | Configurable signup redirect | Not inspected | Pending | Allow-list callback and supply build define |
| Recovery | Existing callback/UI + failure tests | Not inspected | Pending | Allow-list recovery, same-install cold/warm/expired/reused links |
| Session/logout/isolation | SDK with in-memory persistence + A→Guest→B regressions | Not inspected | Pending | Kill/relaunch, refresh failure, A/B device acceptance |
| Google/Kakao | Existing callback and visibility flags | Not inspected; flags default off | Pending | Console, official button assets/style, cancel/success/device QA |
| Apple | Existing foundation; default off | Not inspected | Pending / HOLD | Token revoke/deletion contract before enabling |
| Account deletion | Client ready + server candidate; regression retained | Deployment unverified, flag default off | Pending / HOLD | Deployment/config, Play web request URL, Apple revoke |
| Policy URLs | Central safe URL path, missing links hidden | Actual values unverified | Pending | Approved privacy/terms URLs |
| LAB account | Same-project/identity architecture compatible | LAB not inspected | Pending | Verify common project and linking policy separately |

Local SDK tests use synthetic unsigned sessions, mocked HTTP and in-memory
persistence. They do not prove physical storage survival, Production refresh,
mail delivery, provider configuration or server account deletion. Existing
Materials guest access, login return without auto-save, bookmark owner isolation,
grade/profile preservation and deletion cleanup contracts remain regression gates.


### Local validation — 2026-09-20

- Full Flutter suite **501 PASS / 1 existing skip** (baseline 493 + 8 new).
  New SDK tests **5 PASS**, new UI tests **3 PASS**; existing auth focused run
  **68 PASS**. Materials login-return/bookmark/account isolation and account
  deletion/profile regressions remain in the full suite.
- iOS simulator offline Auth journey **3 PASS**, native 1×/2× help and real
  keyboard screenshots reviewed. Separate 360×640 render **3 PASS**; 2× dialog
  content scrolls while close/contact actions stay reachable. No overflow.
- `flutter analyze`: no issues. Android debug and iOS simulator builds PASS;
  normal simulator app reinstalled/launched after the fixture runner.
- Credential signature scan + Auth log-call inspection and `git diff --check`
  PASS. No passwords/tokens/raw callbacks logged. Synthetic fixtures only.
- Native evidence: `/private/tmp/legendstudy-auth-native/`; 360×640 evidence:
  `/private/tmp/legendstudy-core-ui/auth-help*.png` (local, not committed).
- Production mutation **0**. Production email, OAuth, device persistence and
  deletion acceptance are **not** claimed by these local tests.

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
Android has distinct `auth-recovery` and `login-callback` host filters; both
registrations are covered by local tests. Provider console enablement is separate.

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
has an account: "입력한 이메일로 비밀번호 재설정 안내를 요청했습니다." This
asserts the request, not delivery. Supabase answers
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
5. **OAuth completion** — functional code/flags and both native callback paths
   exist; actual provider console/physical cold/warm acceptance and official
   button design remain open. Console state was not remotely queried.
6. **Account deletion / privacy lifecycle** — client/server candidate exists;
   deploy, enablement, lifecycle decisions and E2E remain Owner gates. See
   [account-deletion-privacy.md](account-deletion-privacy.md).
7. **Current local Flutter validation** — see below; separate from mailbox E2E.

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

The 2026-09-20 Core Account pass revalidated recovery/auth routing in the full
446 PASS / 1 skip suite; analyze and Android/iOS simulator builds PASS. Neutral
request copy, autofill/next-done and new-password show/hide were added. 360×640/2×
recovery/new-password renders with keyboard insets PASS. Older verification
counts above are historical. Real email and physical cold/warm acceptance remain
pending; current release matrix is in [core-app-improvements.md](core-app-improvements.md).
