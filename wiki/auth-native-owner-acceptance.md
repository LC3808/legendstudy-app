# App Native Auth and Shared Account — Owner Acceptance

Reviewed 2026-09-21. **CODE/LOCAL EVIDENCE ≠ PRODUCTION E2E.**
Owner reports LAB email signup/verification/login/logout, recovery,
Google/Kakao/Apple OAuth and header/session lifecycle PASS on 2026-09-21.
This is Web-only evidence, not App native or cross-platform identity evidence.
LAB repository/console configuration was not changed or independently inspected.

## Owner iPhone Profile evidence — 2026-09-21

EMAIL_AUTH_APP_PRODUCTION_E2E: PASS (Owner report).
APP_SESSION_RESTORE: PASS (Owner profile terminate/relaunch report).
MY school/grade configured value DEVICE E2E: PASS.
These supersede earlier pending entries for these checks only. Signup/recovery
edge cases not separately reported here; Google/Kakao/Apple App E2E, App/LAB shared
identity and A/B isolation remain unverified. Next provider stage: Google, one at a
time. Latest meal/Settings UI changes require their own Owner recheck.

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
| Email | YES | App signup/recovery redirects/policy not fully verified | PASS (Owner login) | NOT VERIFIED |
| Google | YES | NOT VERIFIED for native clients | NOT VERIFIED | NOT VERIFIED |
| Kakao browser/deep-link | YES | NOT VERIFIED for App return/consent | NOT VERIFIED | NOT VERIFIED |
| Apple native iOS / browser Android | YES | NOT VERIFIED for device signing/audiences | NOT VERIFIED | NOT VERIFIED |

Proceed one stage at a time: **Email → Google → Kakao → Apple → App/LAB identity
comparison → session restore → A/B isolation**. Record a provider PASS before
starting the next provider. Diagnose a failure within that provider; do not change
all consoles together. Local SDK/mock tests do not close any Device E2E gate.
Same-provider/same-account identity comparisons may be recorded after each login;
close the overall shared-identity gate only after all four pairs are checked.

First Owner action: on the intended physical device, open App login and use an
existing LAB **email/password** account. Enter credentials only in the App.
Confirm return to Home and authenticated MY; report platform and PASS/FAIL plus
safe visible error text only. Do not send passwords, tokens or user IDs. This
initial login check alone does not close signup/verification/recovery acceptance;
continue those Email checks above before moving to Google. No new console change
is needed merely to try an existing email/password login.

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
