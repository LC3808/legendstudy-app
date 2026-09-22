# App Native Auth and Shared Account — Owner Acceptance

Reviewed 2026-09-22. **CODE/LOCAL EVIDENCE ≠ PRODUCTION E2E.**
Owner reports LAB email signup/verification/login/logout, recovery,
Google/Kakao/Apple OAuth and header/session lifecycle PASS on 2026-09-21.
This is Web-only evidence, not App native or cross-platform identity evidence.
LAB repository/console configuration was not changed or independently inspected.

## Kakao iOS browser handoff — 2026-09-22 (current)

Owner reports Kakao authorization, email-only scope, Supabase callback/exchange and
session creation **PASS**. After manually closing browser X, App is authenticated.
Scope/consent/redirect allow-list therefore remain unchanged. Kakao automatic iOS
handoff is **BLOCKED pending corrected Profile acceptance**; overall E2E NOT VERIFIED.
Owner also confirms **APPLE_LAB_APP_SHARED_IDENTITY: PASS** and
**GOOGLE_LAB_APP_SHARED_IDENTITY: PASS** in addition to their App login PASS.
Email/session restore PASS retained; no inferred Kakao/Email identity result.

### Failure layer and minimal correction

Inspected locked supabase_flutter 2.15.4, app_links 6.4.1, url_launcher_ios 6.4.2.
The App omitted authScreenLaunchMode, so Supabase passed platformDefault to
url_launcher. For HTTPS, iOS URLLauncherIOS.launchUrl selects inApp=true and
presents **SFSafariViewController**, not ASWebAuthenticationSession.
URLLaunchSession closes on its user-finish callback or explicit close call.
Supabase _onAuthStateChange persists sessions; it does not close this browser.
App AuthPage signedIn handling returns Home/protected destination underneath it.
Thus a received callback/session and a browser still covering Home can coexist.
This source-confirmed missing browser-dismiss integration explains the reported
X-to-reveal-authenticated-App symptom. No evidence of a broken scope/exchange or
missing scheme; the exact physical callback timing was not independently captured.

Minimal correction: **Kakao + iOS only** uses the SDK's
`authScreenLaunchMode: LaunchMode.externalApplication`. The system browser hands
back the existing custom scheme; no in-app Safari sheet remains to require X.
This does not close a system Safari tab, suppress OS consent prompts, implement
custom OAuth, or claim a native Kakao SDK. Android mode and native Apple/Google,
Email, recovery and scope=account_email remain unchanged. Owner must confirm the
complete handoff on the actual Profile device; local launch-mode tests do not prove it.
[Official launch-mode behavior](https://pub.dev/packages/url_launcher#browser-vs-in-app-handling).

### Native registration and lifecycle audit

- Source CFBundleURLTypes contains com.legendstudy.app and the existing Google
  build-setting placeholder in one schemes array. Both hosts use the same scheme;
  host is not a CFBundleURLSchemes registration unit. No evidence requires splitting
  dictionaries. Info.plist/project.pbxproj were byte-preserved, not staged.
- Auth.local.xcconfig exists with GOOGLE_REVERSED_CLIENT_ID. The **final built**
  build/ios/iphonesimulator/Runner.app/Info.plist has exactly one app custom scheme,
  one expanded reversed Google scheme and no unresolved placeholder. Values from
  local configuration are not printed or copied into documentation.
- Final built plist retains UIApplicationSceneManifest/FlutterSceneDelegate,
  single scene. AppDelegate registers plugins via didInitializeImplicitFlutterEngine.
- app_links 6.4.1 uses legacy application(open:options:) → handleLink → initial/stream
  events. Supabase consumes uriLinkStream and exchanges recognized callback params;
  GoRouter does not perform token exchange. Bare callback URIs contain no code/token
  and are not a complete authentication/recovery test.
- app_links and UIScene participate in transport, but the deprecation warning alone
  does not establish this failure. Owner's successful session already establishes a
  functioning callback path for that attempt. No speculative plugin upgrade or scene
  rewrite. Future cold/warm device coverage remains required.
  [Flutter lifecycle guidance](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate).

### Direct-open diagnostic procedure and actual limits

After building/installing on a **booted** simulator, with no live credentials:

```sh
xcrun simctl openurl booted 'com.legendstudy.app://login-callback'
xcrun simctl openurl booted 'com.legendstudy.app://auth-recovery'
```

Run each separately; accept the expected iOS Open confirmation and check the App
comes forward. Repeat after terminating the App (cold) and while it is already
running/backgrounded (warm). For a physical device use the installed Profile build
and tap each token-free link from a local test document; verify the same behavior.
Bare recovery URL only tests transport, not password reset; do not add real tokens
or codes to shell history/test documents. Full recovery email cold/warm E2E is separate.

Actual local attempt: iPhone 17 Pro simulator iOS 26.5, final simulator build installed.
login-callback from stopped state and auth-recovery after explicit App launch both
returned simctl success and showed the **LegendStudy+ Open confirmation**. Screenshots
/private/tmp/ls-login-cold.png and /private/tmp/ls-recovery-open.png were reviewed.
Registration/OS resolution is verified, **post-confirmation direct-open completion is
NOT VERIFIED**. Computer-use could not bind Simulator (Invalid app), so the dialog
was not clicked; no cold/warm app_links or physical Profile PASS is inferred.

If direct links cannot resolve, investigate installed plist/registration. If they
resolve/open but OAuth fails, inspect browser dismissal and callback transport/events
separately; an authenticated App hidden behind Safari is not missing session creation.
Owner next: new Profile build → Kakao → confirm automatic App foreground, Home/MY
without closing X. Preserve OS-required confirmation behavior; record actual outcome.

Validation: full **558 PASS / 1 existing skip**, analyze, iOS simulator/Android debug
builds PASS. SDK launcher seam now checks iOS useSafariVC=false and unchanged Android
mode/Apple browser behavior, scope and PKCE. Existing callback-host registration,
signedIn→Home, recovery separation and native Auth regressions PASS. Secret/diff scan
PASS. No Production request/mutation, console/allow-list edit or new dependency.

## Kakao KOE205 scope correction — 2026-09-22 (scope now Owner-verified)

Owner now reports **Apple and Google App Production E2E PASS**; preserve these
results alongside Email/session restore PASS. This supersedes earlier Apple-blocked
and Google-pending statements below. No new shared-identity comparison or platform-
specific expansion is inferred. Their code/configuration was not changed here.
Kakao App Production E2E remains **NOT VERIFIED** after the correction.

Owner inspected the actual Kakao authorization scope:
`account_email profile_image profile_nickname account_email`.
Kakao consent has account_email required, nickname/image disabled. Requesting those
disabled profile scopes causes the reported KOE205. Do not enable them to compensate.

### Actual source trace and correction

- Locked client: **supabase_flutter 2.15.4 / gotrue 2.25.0**, inspected installed
  source, not an assumption based on latest docs. SupabaseAuth.signInWithOAuth
  forwards scopes/queryParams to getOAuthSignInUrl. GoTrueClient._getUrlForProvider
  serializes `scopes` and merges queryParams; it has **no Kakao default-scope list**.
- Defaults come from the **Supabase Auth server** NewKakaoProvider: account_email,
  profile_image, profile_nickname. It appends comma-separated `scopes` without
  deduplication. Thus the App's extra account_email produces the observed duplicate.
- Corrected only Kakao's call to the official SDK API:
  `queryParams: {'scope': 'account_email'}`; omit the additive `scopes` argument.
  Singular `scope` is the provider OAuth parameter, not the GoTrue additive option.
- Auth GetExternalProviderRedirectURL removes `scopes`/provider and passes remaining
  allowed query parameters through oauth2.SetAuthURLParam. `scope` is not in its
  reserved parameter list. oauth2.Config.AuthCodeURL sets default scopes first,
  then applies options using url.Values.Set, replacing that value rather than adding.
  State, redirect/callback, PKCE and browser launch remain SDK/server managed.
- Built-in OAuthProviderConfiguration has no Kakao scope/default-scope field;
  NewKakaoProvider hardcodes this list. No supported built-in provider configuration
  override was found in the inspected source. Custom OAuth/OIDC configuration is
  a different facility and was not introduced. No Dashboard mutation is required
  by this per-request SDK change.

Server source inspected at revision
`64cfdf22e15278eb7f4e7be541156e1cf94f4431`:
[defaults](https://github.com/supabase/auth/blob/64cfdf22e15278eb7f4e7be541156e1cf94f4431/internal/api/provider/kakao.go),
[query forwarding](https://github.com/supabase/auth/blob/64cfdf22e15278eb7f4e7be541156e1cf94f4431/internal/api/external.go),
[reserved parameters](https://github.com/supabase/auth/blob/64cfdf22e15278eb7f4e7be541156e1cf94f4431/internal/api/custom_oauth_admin.go),
[provider configuration](https://github.com/supabase/auth/blob/64cfdf22e15278eb7f4e7be541156e1cf94f4431/internal/conf/configuration.go).
[Official Flutter API](https://supabase.com/docs/reference/dart/auth-signinwithoauth)
and [Go OAuth2 option ordering](https://github.com/golang/oauth2/blob/master/oauth2.go).
Hosted Production Auth revision was not queried; the inspected upstream source
explains Owner's observed URL but is not claimed to be an identified deployed SHA.

### Evidence boundary and Owner action

Local validation: focused Kakao/native 13 PASS; full 558 PASS/1 existing skip;
analyze, Android debug/iOS simulator builds, secret/diff checks PASS.

Tests invoke the actual App SupabaseOAuthService → installed Flutter/GoTrue SDK →
intercepted url_launcher platform boundary. They verify /auth/v1/authorize carries
one `scope=account_email`, no `scopes`, no nickname/image, preserved redirect and
PKCE; Android Apple has no Kakao override. These are **real SDK URL-generation seam
tests, not a live Kakao redirect or successful login**. Production was not contacted.

Owner: rebuild using existing local configuration, retry Kakao, and inspect only
the final Kakao `scope` value. Expected: exactly account_email, once. Confirm App
return/session separately. Do not paste the full authorization URL (it may carry
state/challenges or identifiers). If hosted Auth does not honor singular scope,
stop and report to Supabase support with sanitized scope evidence; seek a supported
server correction rather than enabling extra consent, inventing custom OAuth or
switching to Kakao Native SDK in this task. LAB repository and provider policy remain
unchanged. Apple revoke/renewal and Google rotation gates stay OPEN.

## Apple failure diagnosis — 2026-09-22 (historical; Owner now reports PASS)

Owner's new iPhone `enjoi your life :)`, iOS 26.4.2, launches Profile successfully.
With APPLE_OAUTH_ENABLED=true the Apple button appears, but the attempt ends in
safe generic failure copy. **App Apple E2E: BLOCKED / DIAGNOSIS REQUIRED**, not PASS.
Actual exception/failure stage has not been supplied; root cause is NOT DETERMINED.
Earlier code-ready judgments and LAB Apple Web PASS do not establish native success.

Inspected chain: DeviceIdentityProvider.apple → email-only native credential →
nonempty identityToken → Supabase signInWithIdToken(apple, token, raw nonce) →
SDK saves session/emits signedIn → AuthPage returns Home or protected destination.
A fresh 32-byte nonce is SHA-256 hashed for Apple; the original goes to Supabase.
Authorization code is not required by this ID-token exchange and is not stored.
Runner bundle ID is com.legendstudy.app; all configurations reference the existing
Apple entitlement. Owner reports automatic signing, Copacabana Co., managed profile
and capability present. This does not prove the installed binary's entitlements or
Production provider audiences. Owner pbxproj/Info.plist edits were byte-preserved.

The native SDK maps non-cancel Apple authorization errors to unexpected_failure;
its mapped UI text differs from the reported generic fallback. That is insufficient
to identify the failing layer: other platform and Supabase errors can fall back to
that generic message. No nonce, signing, callback or provider workaround was made.
Google/Kakao/Email/recovery/session behavior is unchanged.

Opt-in `APPLE_AUTH_DIAGNOSTICS=true` enables only Apple stage records in Debug/Profile;
Release always suppresses them. Default builds are silent. Records contain fixed
stage/provider/kind and SDK-enum/allowlisted error code only. No exception message,
response, arbitrary platform code, token, nonce, authorization code, key or UUID.
Stages: nativeCredential, identityToken, supabaseExchange, session. A session complete
record means SDK exchange returned a session, not a device navigation/restore proof.
Unknown codes deliberately remain unknown; do not copy raw errors to compensate.

Owner reproduction (local public config is read by Flutter, never printed):

```sh
./tool/flutterw run --profile -d 'enjoi your life :)' \
  --dart-define-from-file=/Users/woojinchang/legendstudy-local.json \
  --dart-define=APPLE_OAUTH_ENABLED=true \
  --dart-define=APPLE_AUTH_DIAGNOSTICS=true
```

Run from the repository with that iPhone connected/unlocked. Attempt Apple once,
then share **only APPLE_AUTH lines**, plus whether Home/authenticated MY appeared.
Do not share a full device log. Remove the diagnostic define from normal builds.

- nativeCredential error: investigate native authorization/signing on the installed
  device; cancel is not a configuration failure.
- identityToken error: credential returned without usable token.
- supabaseExchange error: inspect the safe code and Owner's provider settings
  read-only; code alone may not uniquely prove audience/nonce/root cause.
- session complete but no Home: investigate event/route locally next; do not change
  provider console settings on this evidence.

[Supabase Apple documentation](https://supabase.com/docs/guides/auth/social-login/auth-apple)
rechecked 2026-09-22: native audiences must be in Apple Client IDs; the working Web
Services ID **com.legendstudy.lab stays first**, native **com.legendstudy.app** is
also allowed. This is a configuration requirement, **not an observed mismatch**.
Owner must verify before any change; no Dashboard or LAB mutation occurred.
Revoke, secret renewal, Google rotation and shared-identity gates remain OPEN.

Local native tests: 11 PASS, including nonce/hash/freshness, cancellation, missing
ID token, actual SDK mock exchange/error/missing session/retry, duplicate and stale
owner protection, opt-in/redaction. No actual Apple account was used.

## Owner iPhone Profile evidence — 2026-09-21

`EMAIL_AUTH_APP_PRODUCTION_E2E: PASS`; existing LAB email/password login returned
to Home and authenticated MY. `APP_SESSION_RESTORE: PASS` after terminating and
relaunching the iPhone Profile build. Configured school and grade actual-value
checks PASS. Latest meal progression and MY Settings UX also passed on Owner iPhone.
The earlier iOS Debug relaunch message (“In iOS 14+, debug mode Flutter apps can
only be launched…”) is a Flutter Debug tooling limitation, not a session failure.
Signup/recovery edge cases were not separately reported. Google/Kakao/Apple App
E2E, actual App/LAB `auth.users.id` equality, and A/B owner isolation remain
unverified. Next provider stage: Apple Native Login on iPhone.

## Implemented paths

| Provider | iOS | Android | Gate |
|---|---|---|---|
| Google | google_sign_in → ID token → Supabase | Same native SDK path | Flag plus public Client IDs; physical E2E pending |
| Kakao | Existing Supabase browser PKCE + native deep link | Same | Flag, account_email scope only; native Kakao SDK not added |
| Apple | Native sign_in_with_apple → ID token + nonce → Supabase | Existing browser OAuth retained | Flag; native entitlement/provisioning; physical E2E pending |

Supabase remains the only App session authority. Native provider success alone
is not success: the ID token must yield a Supabase session. Existing auth events,
profile ownership, session persistence and personal caches are reused. Apple
requests email only; no full-name storage is added. Google initialization is
once per process as required by SDK 7.2.0; its random nonce is initialization-scoped,
SHA-256 hashed to Google and original supplied to Supabase. Apple uses a fresh
random nonce per attempt. No nonce-check relaxation or provider-secret changes.

Google missing public client config hides its button. iOS checks that the matching
reversed-client scheme exists before calling the SDK, failing safely if absent.
Flags remain explicit Owner release declarations, not remote provider discovery.
Apple/Kakao default OFF. Google/Kakao/Apple buttons use local provider marks and
“다른 방법으로 로그인”; see [asset provenance](../assets/auth/README.md), including
remaining custom-label/typography brand review. Direct auth success returns Home;
protected push returns to the originating screen, without automatic bookmark save.
Signup without session stays at login with verification guidance; recovery retains
its existing dedicated event route and authenticated-session update semantics.

## Owner console/config sheet — preserve working Web configuration

Do not change anything merely because a local build passes. Verify existing
values, add only missing native configuration, and repeat LAB acceptance after
any Owner console change. Actual client IDs/fingerprints were not read or guessed.
Secrets remain server-side and are never dart-defines, source or app assets.

### Google

1. In the same Google project as working LAB OAuth, identify the existing **Web
   client ID**; keep its Supabase redirect and secret intact. Native SDK's
   `GOOGLE_SERVER_CLIENT_ID` is that backend/Web client ID, not an Android ID.
2. Register/verify Android OAuth client for package **com.legendstudy.app** with
   the SHA-1 of the actual signing certificate (debug, release and Play app-signing
   are different). Obtain actual fingerprints from local Gradle `signingReport`
   or Play App Integrity; do not substitute upload-key fingerprints for Play's
   app-signing key. SHA-256 is not an input to this OAuth Android client path;
   other platform services may separately require it.
3. Register/verify iOS OAuth client for bundle **com.legendstudy.app**. Supply its
   public ID via `GOOGLE_IOS_CLIENT_ID`. Put its exact reversed Client ID from
   Google's configuration in ignored `ios/Flutter/Auth.local.xcconfig` as
   `GOOGLE_REVERSED_CLIENT_ID = <actual reversed iOS client ID>`.
   Debug/Release (including Profile's Release config) include this file. Do not
   put secrets there. This file is not automatically created with guessed values.
4. Supabase Google Client IDs must preserve the Web client first; add verified
   native audiences as needed, without replacing the working Web client.
5. Enable `GOOGLE_OAUTH_ENABLED=true` only in the intended acceptance/release build
   after configuration review. The two public client IDs use existing dart-define
   or Owner local JSON build input. No Firebase database is required by this path.
6. **GOOGLE_CREDENTIAL_ROTATION: OPEN.** Owner reports earlier LAB screenshot
   exposure; rotate through Owner-controlled consoles, preserving Web behavior.
   No secret or screenshot value is copied here.

### Kakao

1. Keep existing LAB REST API key/server client secret and Supabase callback.
   App still uses Supabase OAuth; no native Kakao key/hash/custom kakao scheme is
   required for this selected path. Do not enter invented native registration.
2. Keep provider callback `https://stlhijzpjfgwwdgunlsd.supabase.co/auth/v1/callback`.
   Separately verify Supabase redirect allow-list includes
   `com.legendstudy.app://login-callback` without deleting LAB redirects.
3. Request only account_email; nickname/profile_image are unused. Verify the
   actual consent screen/settings, required email availability and cancel path.
4. Enable `KAKAO_OAUTH_ENABLED=true` after review. Kakao-native-SDK readiness is
   NOT claimed; App browser/deep-link integration is the maintained architecture.

### Apple

1. Owner reports Sign in with Apple capability prepared for **com.legendstudy.app**.
   Repository adds Runner entitlement for Debug/Release/Profile. Owner must use
   an entitlement-bearing provisioning profile/signing configuration for devices.
2. Preserve Web Services ID **com.legendstudy.lab**. Supabase Apple Client IDs:
   existing Web Services ID **first**, native **com.legendstudy.app** also allowed.
   Do not replace the Services ID with the bundle ID: order affects Web OAuth.
3. Verify the Services ID is associated/grouped with the intended primary App ID
   so the same Apple account can map consistently. Hidden relay email equality
   is not identity proof. No manual merge or existing user mutation.
4. iOS native returns through AuthenticationServices; no web redirect is used for
   native token exchange. Android retains browser callback above and Web client.
5. Enable `APPLE_OAUTH_ENABLED=true` only after Owner config/policy review.
   **APPLE_ACCOUNT_DELETION_REVOKE: OPEN. APPLE_SECRET_RENEWAL_GATE: OPEN.**
   Existing server deletion candidate does not prove Apple authorization revoked.
   No revoke deployment, .p8 handling or client-secret generation was performed.

## Email/recovery

Keep LAB Site URL and Web callbacks. Add/verify only App redirects:
`SUPABASE_SIGNUP_REDIRECT=com.legendstudy.app://login-callback` and
`SUPABASE_RECOVERY_REDIRECT=com.legendstudy.app://auth-recovery`.
Both schemes/hosts are registered; signup and recovery are distinct flows.
No real emails were requested here. Same-install PKCE, expired/reused/malformed
links and warm/cold start remain device checks; see [canonical recovery](auth-recovery.md).

## Shared Account verification (no UUID in reports)

Shared Account is **same auth.users.id**, not shared sessions/cookies/tokens.
Use an explicitly enabled **debug-only** build with `OWNER_AUTH_CHECK=true` and
`OWNER_AUTH_CHECK_START=true`, alongside existing local public configuration.
The route `/auth/owner-check` and entry are absent in profile/release even if
flags are set. Guest can open login, and authenticated return resumes the check.

For each Email / Google / Kakao / Apple:

1. Owner signs into LAB using the chosen provider account and confirms the
   canonical user row in the dedicated Supabase Dashboard. Never infer it from
   matching email text alone, especially Apple relay addresses.
2. Use the same provider/account on App; confirm return/authenticated state.
3. Temporarily paste that Dashboard ID into the obscured debug comparison field.
   It is cleared on submit/account change/dispose and is never logged or saved.
4. Comparison performs only `auth.getUser()` (GET) and checks server/current/
   expected identity equality. UI emits only IDENTITY MATCH / NOT MATCHED.
   Record provider + outcome, never UUID/token. Clear clipboard afterward.
5. If not matched, inspect identities in Dashboard read-only. Do not manually
   merge accounts or change production data; investigate app association/linking.

This proves equality only for the tested pair. Same email across different
providers does not imply linking. Cross-provider linking is a future Product/Security
decision, outside this acceptance; no linking/unlinking UI or automatic merge is implemented.
Do not publish real IDs in screenshots, code, fixtures, Wiki or command arguments.

## Physical acceptance checklist

- Email: existing LAB account login, signup with/without returned session,
  verification return; safe wrong password and duplicate submit.
- Google: real Android/iPhone account selection → App → Supabase session → MATCH.
- Kakao: consent/email → App return → session → MATCH; cancel/network retry.
- Apple: real iPhone native sheet → session → MATCH; Android browser separately.
- Recovery: request → actual email → cold/warm App return → new password → success;
  expired/reused/wrong-install/malformed link; old/new password expectations.
- Each provider's Supabase session: terminate/restart → restore; invalid/expired
  refresh → safe state; logout/restart → Guest.
- A → saved/recent/grade/profile → logout → Guest → B: no A data, including late
  requests. Login from Materials restores destination without auto-save.
- After any Owner console edits: recheck all previously passing LAB Web flows.
- Do not mark App/shared identity PASS until these actual outcomes are reported.

## Sources checked

- [Supabase native ID-token API](https://supabase.com/docs/reference/dart/auth-signinwithidtoken)
- [Google/Supabase setup](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Google Flutter SDK](https://pub.dev/packages/google_sign_in)
- [Apple/Supabase client ID ordering](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Kakao/Supabase](https://supabase.com/docs/guides/auth/social-login/auth-kakao)

Local code uses locked google_sign_in 7.2.0 and sign_in_with_apple 8.2.0.
No broad SDK/toolchain upgrade; crypto was already transitive, now direct.


## Local evidence — 2026-09-21

- Full Flutter suite: **508 PASS / 1 existing skip** (starting baseline 501/1).
- New native token/cancel/duplicate/late-owner tests: **4 PASS**; shared GET-only/
  mismatch/logout/config tests: **3 PASS**. Existing SDK restore and A→Guest→B,
  grade/profile/bookmark/Materials return/deletion regressions remain PASS.
- Auth render matrix 360×640 / 2×: **6 PASS**. iPhone 16 Pro iOS 18.6 simulator
  offline journey: **9 PASS**, including signup/recovery/new password, real
  keyboard, 1×/2× help and provider marks. Screenshot review found no overflow.
  A first harness run used a fixed 380px keyboard boundary on a real larger
  viewport; corrected to actual view/insets and rerun PASS, not an app failure.
- Analyze: no issues. Android debug and iOS simulator builds PASS. New native
  SwiftPM dependency resolution is locked; existing toolchain warnings remain.
- Credential signature scan, Auth logging inspection and diff check PASS.
  Production mutation 0. Local render evidence: `/private/tmp/legendstudy-social-native/`.
- No real provider account sign-in or OS callback E2E was executed. Android
  hardware/emulator provider flows and small-iPhone physical checks remain Owner
  work; 360×640 is widget-render evidence, not a physical-device claim.
- Provider token tests use actual Supabase SDK with mock HTTP/synthetic tokens;
  session restore uses SDK with in-memory persistence, not a kill/reboot proof.

## Sequential Owner acceptance and release gates

Auth UI is **Foundation Complete** against current local evidence. Do not repeat
UI polish; revisit in a final UI/UX pass after functional acceptance.

| App provider | Code ready | Console ready | Device E2E | Shared identity E2E |
|---|---|---|---|---|
| Email | YES | App signup/recovery redirects/policy not fully verified | PASS (Owner login + session restore) | NOT VERIFIED |
| Google | YES | NOT VERIFIED for native clients | NOT VERIFIED | NOT VERIFIED |
| Kakao browser/deep-link | YES | NOT VERIFIED for App return/consent | NOT VERIFIED | NOT VERIFIED |
| Apple native iOS / browser Android | YES | NOT VERIFIED for device signing/audiences | NOT VERIFIED | NOT VERIFIED |

Proceed one stage at a time: **Apple Native Login on iPhone → Apple LAB/App identity
comparison → Google App login/identity → Kakao App login/identity → Email LAB/App
identity comparison → A/B isolation**. App Email login and restore already PASS;
the actual Email identity comparison does not. Record each provider outcome before
starting the next. Diagnose a failure within that provider; do not change all
consoles together. Local SDK/mock tests do not close any Device E2E gate. Close
overall Shared Identity only after all four provider pairs are checked.

First Owner action: on iPhone, use **Apple Native Login**, then confirm the same
Apple identity in LAB and App with the debug-only comparison procedure above.
Never send passwords, tokens or user IDs. No console change is implied by this
sequence; preserve existing working LAB configuration.

Identity evidence comes from Dashboard Authentication → Users → user detail →
Identities and the debug-only comparison tool above. Same email is insufficient.
No real UUID is recorded. APP_SESSION_RESTORE is Owner-reported PASS on iPhone Profile. APP_OWNER_ISOLATION
remains NOT VERIFIED for Production devices despite local regression PASS.

### Independent operational gates

- Account deletion: client foundation/server candidate exist. Production deployment,
  enable flag and E2E remain unverified; Play web deletion-request URL pending.
  Apple authorization revoke remains OPEN even after social login passes.
- Privacy/Terms/Support/deletion guidance: final URLs and content require Owner
  review specifically covering LegendStudy+ App. A LAB route or temporary document
  is not final App policy approval. POLICY_PRODUCTION_READY and STORE_RELEASE_READY
  remain NO until these and the other release gates close.
- Apple: Owner reports App ID com.legendstudy.app, Services ID com.legendstudy.lab,
  Sign in with Apple key created and Web E2E PASS. Key creation does not establish
  client-secret JWT creation/expiry. JWT creation date: **not supplied/unverified**;
  renewal required, expiry/renewal date to be recorded by Owner as nonsecret metadata.
  Never record JWT/.p8 values. Future operations checklist/reminder may track renewal;
  no reminder is scheduled here. Native login does not close Web secret renewal.
- Google: screenshot-exposed client-secret rotation remains OPEN. Owner rotates
  safely and rechecks both Web/App; no secret is copied into this repository.
- Kakao: reuse the existing LegendStudy Kakao application. account_email required;
  nickname/profile_image unused. Key roles below are descriptions, not actual values.

| Kakao credential type | Role | Exposure rule |
|---|---|---|
| REST API key | Existing Supabase-hosted OAuth client identifier | Client identifier, not client secret; kept in existing server configuration, not added to App |
| Native app key | Native SDK platform identifier | Client-distributed identifier; unused by current App browser path |
| JavaScript key | Browser SDK identifier | Client-distributed identifier; not used by this Flutter flow |
| Client secret | Server OAuth credential | Secret; never ship in App, source, logs or Wiki |
| Admin key | Privileged API credential | Secret; not used by App Auth |

After App Auth E2E: **account deletion → final policy/support URLs → release
readiness → Academic Record/Analytics**. Verified App/LAB shared canonical identity
is a prerequisite before Analytics implementation. App quick input/OMR/actions and
LAB history/comparisons/deep analysis must use the same canonical data source;
no Analytics, linking or surrounding feature implementation is part of this task.
