# APP Release Finalization — 2026-10-09

**APP_RELEASE_FINALIZATION: PARTIAL (agent gates COMPLETE; Owner signing/submission gates remain).**
No new features; existing implementation preserved. Verification-and-audit pass on
the release branch; **no code change was required** — the RC was already finalized.

## Authority
- APP base: `claude/final-store-release-2026-10-08 @ a3cc3b3` (contains Codex
  closeout `0570099` +16; RC-1 `7d1c036` +3; canonical icon correction).
- Codex candidate `23d4555` = `codex/essay-web-runtime` (separate, in-flight Essay
  runtime) — **not merged, not touched.**
- LAB Production `main` and DOCS `legendstudy-docs` read for authority.

## Canonical icon
- Master `assets/brand/source/legendstudy_app_icon_master.png` SHA-256
  **`e37afa18ceaf9e27ab275c1cb460b512697baa3d745689ed741c871ce079abfe` — EXACT
  MATCH.** Orange rounded-square + white note + white pencil, original ratio.
  **Not regenerated or reinterpreted.** CHANGED: NO.

## Splash
- White background + orange symbol (`ic_brand_symbol` / bundled
  `legendstudy_symbol.png`); the app-icon orange background is **not** applied to
  splash; no extra copy/decoration. Native launch = symbol only; Flutter cold-start
  brand frame adds name + tagline (cold-start-only, parallel timing). STATUS:
  preserved/verified.

## CTA hierarchy (audit — already Owner-approved 2026-10-08, no change)
Centralized in `lib/core/theme/app_theme.dart` with a documented convention:
- **Primary (FilledButton)** = reserved for strong final actions only (form submit/
  save, auth submit, destructive confirm, essay submit, onboarding completion,
  payment).
- **Secondary (OutlinedButton)** = general/navigational CTAs (orange outline,
  transparent fill, navy label, light-orange press tint).
- **Tertiary (TextButton)** = cancel/secondary (navy).
- Usage: FilledButton ×32 (all legitimate strong actions), OutlinedButton ×23,
  TextButton ×110, **ElevatedButton ×0**. Min touch target 48×48 across all three.
- **Verdict: coherent and Owner-approved → no sweeping refactor** (per "no refactor
  unless release-blocking"; a broad change would risk the green test suite).

## UI (existing screens, preserved; not re-rendered on device this pass)
onboarding · login (orange-outline entry prompts) · home · materials (active +
`published_at DESC`, not modified-date) · PDF/resource · saved/recent · Study Timer
(start/pause/resume/stop + 7-day chart oldest→newest, average line/avg/max; shared
`my_study_summary` contract with Web — unchanged) · D-Day (representative +2,
more/collapse, `YYYY.MM.DD.(요일)`, 360px/200%) · MY · settings. No feature added,
no aggregation/sort semantics changed. LAB entry keeps the four Essay types GATED
(not shown as usable).

## Tests / builds (this branch, 2026-10-09)
- `flutter analyze`: **No issues found.**
- `flutter test`: **967 passed, 2 skipped — All tests passed.**
- iOS `flutter build ios --release --no-codesign`: **PASS** (`Runner.app` 32.1 MB,
  bundle `com.legendstudy.app`).
- Android `flutter build apk --debug`: **PASS** (`app-debug.apk`). Android **release
  AAB signing is BLOCKED** on the Owner upload keystore (`android/key.properties`
  absent; no debug-key fallback by design).
- Version `0.1.0+1`.

## Boundary (unchanged)
ESSAY_RUNTIME_CHANGED: NO · DB_CHANGED: NO · PAYMENT_CHANGED: NO · TOSS_CHANGED: NO ·
IAP_CHANGED: NO · TARGET_005: HOLD. Manus and Codex work preserved; Codex
`essay-web-runtime` untouched.

## Owner action required (remaining Store gates)
1. Android upload keystore + `android/key.properties` → signed AAB (release build is
   agent-blocked without it).
2. iOS signing/team/provisioning + archive/export via Xcode or `tool/store-release`.
3. Build number bump for submission, reviewer account, device smoke, App Store
   Connect / Play Console inputs (screenshots, content rating, export compliance,
   external-link/payment policy answers), recovery-redirect verification.

## Signed-release attempt (2026-10-09)
- **ANDROID_SIGNED_AAB: BLOCKED.** No LegendStudy keystore exists anywhere on the
  machine (only an unrelated *muselry* keystore — not used), no env/CI/gradle
  signing path, git history never held one, `android/key.properties` absent, and
  gradle has no debug-key fallback. **No new key generated.** Owner upload keystore
  required.
- **IOS_ARCHIVE: BLOCKED.** Only an *Apple Development* identity (woojin chang
  7P4MAL37T7) and **0 provisioning profiles** — **no Distribution identity/profile**.
  `build ios --release --no-codesign` already PASS; a distribution Archive needs the
  Owner's Team/Distribution cert + profile.

## Simulator Visual QA (iPhone 17 Pro, iOS 26.5, real rendering — 2026-10-09)
Built with the public `config/development.local.json`, installed and driven on the
booted simulator; every screen below was actually rendered.
- **Splash:** white bg + centred orange symbol only (no orange bg, no copy). ✅
- **Home (guest):** cards (D-Day/공부시간/급식), search + chips, **로그인 =
  orange-outlined** (secondary). Bottom nav 홈/자료/학습/LAB/MY. ✅
- **Materials:** live data (`2026년 9월 고1 모의고사` …), filter dropdowns +
  type chips (전체✓), bookmark icons. ✅
- **Material detail:** `출처: 레전드스터디 닷컴 · 원문 보기` (external), per-subject
  resources (국어/영어/수학/한국사/통합사회/통합과학 · 문제·정답·해설), 저장. ✅
- **Study Timer:** idle `00:00:00` + **공부 시작 (orange filled, primary)** →
  running `공부 중` with **일시정지/종료 (orange outlined)** → stop → `이 기기에
  저장됨` (guest local). **최근 7일 chart updates, today's bar at the right.** ✅
- **D-Day:** 관리 sheet (`아직 저장된 일정이 없어요 · 앱 종료 시 초기화`) → create
  form `이름/메모 0/15` + `날짜: 2026.10.09.(금)` (YYYY.MM.DD.(요일)). ✅
- **MY (guest):** login prompt (orange-outlined), private modules hidden, gear. ✅
- **Settings:** grouped 계정 / 기본정보(학교·학년) / 학습설정(모의 시간 toggle,
  orange) / 서비스정보(문의, 앱 안내 다시 보기) / 약관·개인정보. ✅
- **LAB:** 내신분석 LAB [준비 중], 수능·모의고사 LAB [준비 중] (gated/honest),
  논술 LAB "이용 가능" + **논술 LAB 시작하기 (orange filled)** + **웹에서 이용하기 ↗**. ✅
- **Login:** email/password + **로그인 (orange filled, strong action)** + tertiary
  links + **Google / Kakao / Apple** brand-styled social buttons. ✅
- **CTA hierarchy confirmed on-device:** filled-orange only for strong actions
  (공부 시작, 로그인 submit, 논술 시작); orange-outlined for nav/general (로그인
  entry, timer controls); text for tertiary. No jarring filled-orange on the warm
  surface. No clipping/overflow seen; Dynamic Island safe area respected.
- **Not rendered:** Onboarding (only shows for authenticated-not-onboarded users; a
  guest never reaches it, and real login needs Owner credentials — not performed).
  Small-screen (360px) / 200% text per-screen device pass not repeated here; the
  967-test suite already asserts 360×640 @2x no-overflow.

## Functional smoke (guest, real)
Materials search/browse + detail + source link ✅ · Study Timer start→run→stop→save
+ 7-day chart ✅ · D-Day management + create form ✅ · 5-tab + nested-route + back
navigation ✅ · Login page + 3 social providers render ✅ (actual auth needs Owner
credentials — not performed) · LAB gated labels + web link ✅. PDF viewer *open* not
exercised (resource structure verified).

## Next
Owner provides Android keystore + iOS Distribution identity/profile → signed
AAB/Archive via `tool/store-release` → device smoke → Console submission. The code
RC is green and finalized on `a3cc3b3`+; simulator visual + functional QA PASS.

---

# Device-first release + splash/wordmark (Owner priority override, 2026-10-09)

Owner re-prioritised: produce **installable** builds for hands-on first-run QA
*before* signed store artifacts, verify the splash cold-start, and restore the
approved brand wordmark. No store submission.

## Installable builds
- **ANDROID_INSTALLABLE_APK: READY.** `flutter build apk --debug`
  (`--dart-define-from-file=config/development.local.json`) →
  `build/app/outputs/flutter-apk/app-debug.apk` (~276 MB, auto debug keystore,
  sideload-installable). Verified: `adb install` Success on an arm64 emulator,
  launches, Home renders, launcher icon correct (orange gradient + white
  notebook/pencil). This is the fast Owner-install path.
  - *Not* the Play artifact: a release **AAB** still needs the Owner upload
    keystore (`android/key.properties` absent; no debug fallback by design).
- **IOS_INSTALLABLE: PARTIAL.** Simulator build PASS
  (`build ios --debug --simulator`), installed+run on iPhone sims. **Physical
  iPhone install = Owner action**: only an *Apple Development* identity
  (`7P4MAL37T7`) and **0 provisioning profiles**; the two physical iPhones are
  visible only *wirelessly* and not paired for development. One-step Owner path:
  open `ios/Runner.xcworkspace` in Xcode, select the team (auto-signing), connect
  + trust the iPhone, Run (Xcode auto-provisions a development profile). No new
  signing key generated.

## Splash cold-start (Owner observation: "orange symbol → ~2s later wordmark")
- **ROOT_CAUSE:** No hardcoded delay anywhere. `main()` captures `processStart`
  then `await Supabase.initialize()`; the native splash (symbol-only) is visible
  during engine + Supabase init (~2s in a *debug* build, sub-second in release).
  The **wordmark is drawn by the Flutter brand frame, not the native splash**, so
  it only appears once Flutter is up — and only if init left >150 ms of the
  parallel 1.5 s budget, else the frame (and the wordmark) is **skipped** entirely
  (observed: debug slow-init → native symbol → Home, no wordmark). So wordmark
  visibility is *erratic* (shows on fast init, skipped on slow init) and, when it
  showed, it *popped* in with no transition.
- **PLATFORM CONSTRAINTS (verified):**
  - **Android 12+** system `SplashScreen` is **icon-only**
    (`windowSplashScreenAnimatedIcon`) — it cannot render a wordmark/text. Hard OS
    limit → a frame-1-complete wordmark is not achievable natively on Android.
  - No bundled font (platform default SF Pro / Roboto) → a *baked* native wordmark
    image cannot pixel-match the live Flutter text cross-platform and would add a
    font-shift at handoff + iOS/Android divergence. So baking text into the native
    splash is rejected.
- **CHANGE (FIXED, within constraints):** the Flutter brand frame now holds the
  symbol **solid + pixel-matched** to the native symbol (no jump/flicker) and
  **eases the wordmark in** (320 ms) so the lockup *completes* smoothly instead of
  popping. Timing logic unchanged (no added delay; Owner-approved parallel budget
  preserved). Native splash left symbol-only (consistent across iOS/Android).
- **OWNER DECISION (optional, not done — needs Owner visual sign-off):** to show
  the wordmark from the very first native frame on iOS only, bake a symbol+wordmark
  `LaunchImage`. Deliberately not done unilaterally (iOS/Android divergence +
  Android 12+ can't match it).

## Brand wordmark restored (레전드스터디⁺ — Owner standard)
- New reusable `lib/features/brand/brand_wordmark.dart` (`BrandWordmark`): Korean
  logotype `레전드스터디` + **superscript `+`** as a *separate, size/position-
  controlled* element (not the Unicode `⁺`); a11y/plain name `레전드스터디+`;
  `BrandWordmark.englishName = 'LegendStudy Plus'` (never `LegendStudy+`).
- Wired into the brand frame, the onboarding brand slide (replaced the stray
  `'LegendStudy+'` title), and the Settings "앱 사용 안내 다시 보기" replay —
  rendered identically everywhere. Verified on-device (simulator): the `+` sits
  small and raised at the top-right of the name.
- Login/Signup carry **no** logotype header today (text headers only) — left as-is
  (no unsolicited redesign); flagged for Owner review.

## Device matrix QA — SIMULATOR / EMULATOR only (NO physical device)
Debug build, public config. First-run surfaces: Splash → Login → Signup → Home +
MY/Settings/replay. (Onboarding/Initial-Profile need an authenticated session →
Owner-authenticated QA; the brand replay is the guest-reachable logotype proxy.)
- **iPhone small — iPhone 17e (26.5), SIMULATOR:** splash = white + orange symbol;
  Home clean, no clipping. ✅
- **iPhone large — iPhone 17 Pro Max (26.5), SIMULATOR:** Home / Login
  (orange-filled 로그인 + Google/Kakao/Apple) / Signup (orange-filled 회원가입,
  8-char helper, 비밀번호 확인) / MY / Settings / brand replay (new 레전드스터디⁺)
  all clean, Dynamic-Island safe-area respected. ✅
- **Android normal — Pixel-class phone (android-36 arm64), EMULATOR:** APK
  install Success, launches, Home clean, no crash in logcat, launcher icon
  correct. ✅
- **Android large — Medium Tablet (android-36 arm64), EMULATOR:** splash symbol
  centred (landscape), Home renders as a centred max-width column (no edge-to-edge
  stretch). ✅ (P2: tablet layout is phone-style centred — not blocking.)
- The pre-existing `LegendStudyBrand_API36` AVD is **broken** (an `arm` — not
  arm64 — image, unsupported by QEMU2); replaced with arm64 AVDs for QA.

## Problem classification
- **P0 (blocks install/use/crash/clipping):** none found on the four sizes.
- **P1 (Owner visual review):** splash wordmark timing/visibility (erratic by
  design; smoothed — Owner to decide if iOS native lockup is wanted); wordmark
  superscript final size/kerning; whether Login/Signup should carry the logotype.
- **P2 (non-blocking):** tablet layout is a centred phone column.

## Verification (this change)
`flutter analyze`: No issues. `flutter test`: **967 passed, 2 skipped.**
CHANGED_FILES: `lib/features/brand/brand_wordmark.dart` (new),
`lib/features/brand/brand_frame.dart`, `lib/features/onboarding/presentation/onboarding_page.dart`,
`lib/features/onboarding/presentation/brand_replay_page.dart`. No native splash,
icon, DB, payment, Toss, IAP, or Essay-runtime change.
