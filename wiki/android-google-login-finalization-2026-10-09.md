# Login UI & Android Google Auth Finalization — 2026-10-09

**CLAUDE_LOGIN_AUTH_FINALIZATION: PARTIAL** — the login UI refinement is
**COMPLETE** (implemented, tested, visually verified); real Android Google sign-in
is **BLOCKED** on one Owner Google Cloud config step (the debug SHA-1 is not
registered on the Android OAuth client). The app code is already correct.

Independent branch `claude/android-google-login-final` off the latest Codex
integration `codex/production-integration @ 8e89dfc`. **No Codex code changed**
(auth contract, essay runtime, credit ledger, DB/schema untouched); no merge.

## Android Google auth
- **Root cause (config, not code):** `GoogleSignIn` on Android uses the Web
  **serverClientId** (set) and is validated by **package name + SHA-1**. If the
  app's debug SHA-1 is not registered on an **Android OAuth client** in the
  Owner's Google Cloud project, `authenticate()` fails (an API/DEVELOPER_ERROR,
  not a user cancel). Codex's integration already **fixed the error mapping**
  (`googleFailureCode` → real error vs cancel) and the auth init, so this now
  surfaces as a real error — but login still fails until the SHA-1 is registered.
- **Code:** correct and unchanged. Android path uses `serverClientId` (Web
  client), no `google-services.json` needed (google_sign_in 7.x). Web + iOS
  client IDs are configured.
- **Verification value (for the Owner to register):** app id
  `com.legendstudy.app`; **debug keystore SHA-1**
  `0F:EB:E3:EF:8F:2C:92:C7:42:D9:08:D9:B4:68:5D:3E:E1:B6:A9:88`
  (SHA-256 `2B:33:DA:49:95:CC:E9:24:AE:D8:E6:2C:4E:6C:5A:EE:E7:2A:7D:47:BF:69:29:1C:FC:03:3B:86:82:4C:D7:74`).
  These are non-secret fingerprints. The **release** SHA-1 comes from the Owner
  upload keystore (still absent — see store-release-prep).
- **Supabase:** Google provider must be enabled with the **Web client ID** as an
  authorized client and the ID-token audience; verify in the dashboard (Owner).
- **Physical login:** NOT verified as success — a real success is impossible
  until the SHA-1 is registered, so this is BLOCKED (not a code defect). The app
  reads the real config via `--dart-define-from-file`.

## Login UI (Owner-approved, implemented)
- **Hero copy** → **"나의 가능성을 좀 더 / 선명하게 만드세요."** — centred, 26sp, w800,
  navy (`AppTokens.textPrimary`).
- **Account links on one centred line:** **회원가입 | 비밀번호 찾기 | 이메일 찾기**
  (`Wrap`, wraps naturally on a small screen / at 200% text). Functions/links
  preserved; the signup toggle becomes "로그인" in signup mode; "이메일 찾기" opens
  the existing find-email dialog (extracted to `showFindEmailDialog`).
- **Email login** unchanged: 로그인/이메일/비밀번호 (+ visibility toggle) + orange
  filled CTA.
- **Social:** Google · Kakao on all platforms; **Apple shown on iOS only, hidden
  on Android/web** (capability preserved — `availableOAuthProvidersProvider` now
  gates Apple by `TargetPlatform.iOS`).
- **Guest entry:** a **"비회원으로 이용하기"** text button at the bottom → `context.go
  ('/home')`. No anonymous account; onboarding/first-run routing is Codex's and is
  not reimplemented (auth state vs onboarding-completed stay separate).

## Tests / build
`flutter analyze`: **No issues.** `flutter test`: **991 passed**, 2 skipped. The
only failures are **4 pre-existing on the Codex base** (`day6_repositories_test`
×2, `supabase_foundation_test` ×2) — confirmed failing on a clean `8e89dfc`
before any change here; **not touched** (Codex's in-flight integration). Updated
the login-string assertions in 6 existing auth tests; added `login_capture_test`
(hero / one-line links / guest / **Apple-hidden-on-Android** / iOS-shows-Apple /
no overflow at 360×640). Android debug APK built; iOS simulator build PASS.

## Device QA
- **SM-G950N (physical, API 28, 360dp):** the device holds the Owner's **signed-
  in** session, so the login screen was **not** forced open (a logout with Google
  login still config-blocked would strand the account). Authed surfaces (Home/LAB/
  MY/Materials) already verified clean in the prior pass. **Google-login success
  requires the SHA-1 registration above, then an Owner-initiated sign-in.**
- **Android emulator:** overloaded on this host (system ANR) → login screen
  verified via the deterministic widget capture instead.
- **iOS physical:** wireless-only, not dev-paired; no change here.

## Owner action required
- **WHAT:** register the debug SHA-1 (above) on an **Android OAuth client**
  (package `com.legendstudy.app`). **WHERE:** Google Cloud Console → APIs &
  Services → Credentials (and confirm the Google provider + Web client ID in the
  Supabase dashboard). **HOW:** add/confirm the Android OAuth client with the
  package + SHA-1; add the release SHA-1 once the upload keystore exists.
  **SUCCESS:** Google sign-in on the Android device creates a Supabase session and
  lands on Home with the existing profile. (Do not paste secrets in chat/wiki.)

## Boundary
Auth contract / Credit Ledger / Payment / Toss / IAP / Essay runtime / Math
provider / Evaluation history / Profile DB schema: **unchanged** ·
CODEX_WORK_PRESERVED: **YES** (no merge) · MAIN_MERGED: **NO** · STORE_SUBMITTED:
**NO**.
