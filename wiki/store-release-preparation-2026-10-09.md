# Store Release Preparation — 2026-10-09

**STORE_RELEASE_PREPARATION: PARTIAL** — agent-side readiness is captured and the
release package is assembled; the remaining gates are Owner signing/accounts and a
payment-compliance decision. Codex owns in-flight APP/LAB backend + Web MY work;
this pass is **documentation + QA only — no app code changed**. Base
`claude/final-store-release-2026-10-08 @ b59ca82`; Codex `codex/essay-web-runtime
@ 2657952` preserved (not merged, not touched).

Measurements are from the **debug** build on an arm64 emulator / iOS simulator —
upper-bound, not release-representative. The signed release build must be
re-measured on-device by the Owner.

---

## 1 · Android release readiness
| Item | Value |
|---|---|
| applicationId / namespace | `com.legendstudy.app` |
| versionName / versionCode | `0.1.0` / `1` (from pubspec `0.1.0+1`) |
| minSdk / targetSdk / compileSdk | **24 / 36 / 36** |
| App label | 레전드스터디+ |
| Permissions | INTERNET, ACCESS_NOTIFICATION_POLICY, POST_NOTIFICATIONS (+ auto DYNAMIC_RECEIVER_NOT_EXPORTED); biometric/fingerprint explicitly **removed** (`tools:node="remove"`) |
| signingConfig | release config is created only if `android/key.properties` exists; **no debug-key fallback** |
| key.properties / keystore | **ABSENT** — no LegendStudy keystore anywhere |
| AAB | **BLOCKED** (needs the Owner upload keystore) |
| Debug APK | builds + installs (sideload QA artifact) — **distinct** from the Play AAB |
| Play App Signing | not yet enrolled (Owner, in Play Console) |

- **SIGNING: BLOCKED.** No new key generated. `targetSdk 36` satisfies Play's
  current target-API requirement. `versionCode` must be bumped before each
  upload (currently 1).

## 2 · iOS release readiness
| Item | Value |
|---|---|
| Bundle Identifier | `com.legendstudy.app` |
| Display name | 레전드스터디+ |
| Version / Build | `0.1.0` / `1` (`$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)`) |
| CODE_SIGN_STYLE | Automatic; `CODE_SIGN_IDENTITY[iphoneos]` = "iPhone Developer" |
| DEVELOPMENT_TEAM | **not pinned in project** — Owner selects the team in Xcode |
| Entitlements | Sign in with Apple (`com.apple.developer.applesignin`); no push, no associated-domains |
| Privacy manifest | `PrivacyInfo.xcprivacy` **present** — SystemBootTime (reason `35F9.1`, the study clock), `NSPrivacyTracking` declared |
| Usage strings | `NSPhotoLibraryUsageDescription` present; app uses only `ImageSource.gallery` → **no camera string needed** |
| Signing identities | **Apple Development** only (woojin chang / `7P4MAL37T7`) |
| Provisioning profiles | **0** |
| Archive / App Store | **BLOCKED** — no Distribution cert + no App Store provisioning profile |

- **SIGNING: Development install possible** once the team is set in Xcode
  (Automatic signing + the existing Apple Development identity → run on a
  registered device). **Distribution/Archive BLOCKED** (needs paid Apple
  Developer Program membership → Distribution cert + App Store provisioning
  profile). No new certificate issued.

## 3 · Store metadata (draft — reuses approved copy; nothing new confirmed)
- **App name (ko):** 레전드스터디+ · **(en):** LegendStudy Plus. Logotype `+` is a
  small superscript; stores that disallow superscript styling use the plain
  official name.
- **Category:** Education.
- **Short/subtitle (draft, from approved copy):** "내신 관리부터 수능, 논술 준비까지".
- **Full description (draft, from approved onboarding/splash copy):** 학습 기록·공부
  시간·성적 변화를 한곳에서; 내신 LAB · 모의/수능 LAB · 논술 LAB; "나의 학습 기록이
  쌓일수록, 나의 가능성은 선명해집니다." — **Owner to finalize marketing wording.**
- **Age rating / content:** educational; contains private user-generated content
  (essay answers) and an external web link — complete the ratings questionnaire
  honestly (expected 4+/Everyone, confirm via the forms).
- **App icon:** canonical master (orange gradient + white note/pencil) — unchanged.
- **Review notes:** must explain the 논술 LAB web path + Credit model (see §7).

## 4 · Policy URL audit (verified live — **real pages, not fabricated**)
| Purpose | URL | Status |
|---|---|---|
| Privacy Policy | `https://lab.legendstudy.com/privacy` | **200 — "LegendStudy 개인정보처리방침"** |
| Terms | `https://lab.legendstudy.com/terms` | **200 — "LegendStudy 이용약관"** |
| LAB Refund | `https://lab.legendstudy.com/refund` | **200 — "LegendStudy 논술 LAB 환불정책"** |
| Support | in-app 문의·건의 (`/my/feedback`); public: `https://lab.legendstudy.com` | 200 (no dedicated support page) |
| LAB Pricing | no standalone page found; pricing is shown inside the 논술 LAB web flow | — |
| `legendstudy.com/privacy`, `/terms` | — | **404** (use the LAB URLs above) |

- **Apply at release (env, not committed):** `PRIVACY_POLICY_URL=…/privacy`,
  `TERMS_URL=…/terms`. These feed Settings "약관 및 개인정보" (today they show
  "준비 중" only because the env vars are unset in dev). `SUPABASE_RECOVERY_REDIRECT`
  / `SUPABASE_SIGNUP_REDIRECT` are also Owner-registered env values. **Config code
  is Codex's — this pass only lists the URLs and where they apply; nothing wired.**

## 5 · Screenshot plan (specs + composition)
**Capture from the real app (no mock/placeholder evaluation screens).**
- **Android (Play):** 2–8 phone screenshots, 16:9 or 9:16, min edge 320px, max
  3840px, PNG/JPEG. Feature graphic 1024×500. Phone + (optional) 7"/10" tablet.
- **iOS (App Store Connect):** 6.9" (1320×2868) **or** 6.7" (1290×2796) required;
  6.5"/5.5" optional. iPhone-first (iPad optional).
- **Screens (approved, stable now):** Home · Materials (list) · Material detail /
  PDF · Study Timer (running + 7-day chart) · D-Day · Settings.
- **Defer to a FINAL capture after Codex integration (may change):** **MY**
  (Codex Web-MY integration) and **LAB / 논술 LAB** (Codex essay runtime) — do not
  ship store shots of these until Codex lands.
- This pass delivers the plan + specs only; final framed assets are produced once
  signing + Codex integration are in place.

## 6 · First-run performance (measured, debug — **no code changed**)
| Metric | Android (arm64 emu, debug) | iOS (sim, debug) |
|---|---|---|
| Cold start → first frame | **~4.3 s** (`am start -W` TotalTime 4273 ms) | **> 2–3 s** (splash still up at 2 s) |
| Warm start (process alive) | **~0.1 s** (WaitTime 96 ms) | fast (process persists) |
| Brand wordmark on splash | frequently **skipped** (native symbol → Home) | same |

- **Root cause (observable, not changed):** `main()` **`await
  Supabase.initialize()` runs before `runApp()`**, so the first Flutter frame
  (brand frame / Home) cannot draw until that network init finishes — the native
  symbol splash is held for the whole init, and the 1.5 s parallel brand-frame
  budget is often already spent, so the wordmark is skipped. This is the ~2 s the
  Owner observed, amplified by debug/JIT on the emulator.
- **Improvement candidates (code — deferred; Owner/Codex):** draw the brand frame
  **before/without blocking on** Supabase init (initialize in parallel or lazily),
  trim other pre-`runApp` work. **Do not add fixed delays.** Measure the **signed
  release (AOT)** build on-device — it will be materially faster than these debug
  numbers; that is the real gate.

## 7 · Store compliance risk audit (no Payment/Toss/IAP change)
- **🔴 TOP RISK — digital purchase rules (Apple 3.1.1 / Play Billing):** the 논술
  LAB sells Credit for in-app digital content. The app offers a native 논술 LAB
  entry **and** a "웹에서 이용하기 ↗" external link to `lab.legendstudy.com` where
  Credit is purchased (Toss). Apple generally requires **IAP** for digital content
  consumed in-app and restricts steering to external purchase; Play similarly
  expects Play Billing. The payment enum already includes `APPLE_IAP` /
  `GOOGLE_PLAY` (prior IAP analysis), i.e. IAP is anticipated. **Decision needed
  (Owner + Codex):** IAP for in-app essay Credit vs. a reader/multiplatform
  posture. This is the most likely rejection cause. **Not changed here.**
- **Account deletion:** in-app flow exists (`/my/delete-account`) ✅ (satisfies
  Apple 5.1.1(v) / Play account-deletion policy).
- **Sign in with Apple:** present alongside Google/Kakao ✅ (Apple 4.8 when other
  social logins are offered).
- **External web link:** "웹에서 이용하기" opens the system browser — acceptable as
  long as it is not used to **circumvent** IAP for the in-app digital service (ties
  to the top risk).
- **UGC (essay answers):** private, not social — lower risk; no public feed. If any
  sharing is added later, add reporting/blocking (Apple 1.2).
- **Privacy / data safety:** collects email + profile + study data; privacy
  manifest present and privacy policy URL live. Complete Play **Data safety** and
  Apple **privacy nutrition** forms to match.
- **Permissions:** minimal (INTERNET, notifications, photo library for avatar) —
  all justified.

## 8 · Release package — checklists
### Android release checklist
- [ ] Owner upload keystore + `android/key.properties` (storeFile/… )
- [ ] Enroll Play App Signing
- [ ] Bump `versionCode` (currently 1) per upload
- [ ] `flutter build appbundle --release` via `tool/store-release`
- [ ] Play Console: listing, Data safety, content rating, target-audience,
      policy URLs, screenshots/feature graphic, countries, pricing (free + IAP?)
- [ ] Reviewer test account (Owner-created; Codex owns auth)

### iOS release checklist
- [ ] Apple Developer Program membership active
- [ ] Set DEVELOPMENT_TEAM in Xcode; Distribution cert + App Store provisioning
- [ ] Bump build number per upload
- [ ] Archive + export (App Store) via Xcode / `tool/store-release`
- [ ] App Store Connect: app record, privacy nutrition, age rating, URLs,
      screenshots (6.9"/6.7"), export compliance, review notes
- [ ] Reviewer test account + 논술 LAB explanation in review notes

### Carry-over (both)
- Store metadata draft (§3) → Owner finalizes copy
- Policy URLs (§4) → wire env at build; set in both consoles
- Screenshot plan (§5) → final capture after signing + Codex integration
- Payment-compliance decision (§7) → Owner + Codex

## 9 · Known blockers
1. **Android signing** — upload keystore + key.properties (Owner).
2. **iOS signing** — paid membership → Distribution cert + App Store profile; set team (Owner).
3. **Payment/IAP compliance** — IAP vs external-web decision for 논술 LAB Credit (Owner + Codex).
4. **Reviewer account** — Owner-created test login (account creation is not an agent action).
5. **Final screenshots** — after Codex MY/LAB integration + a signed build.
6. **Policy-URL env wiring** — in Codex's config at release.

## 10 · Owner action required
- **What / where / how / done-when:**
  - **Android keystore** → on the Owner's machine → create/restore the upload
    keystore + `android/key.properties`; enroll Play App Signing →
    done when `flutter build appbundle --release` signs and Play accepts the AAB.
  - **iOS distribution** → Apple Developer portal + Xcode → activate membership,
    set the team, create Distribution cert + App Store provisioning profile →
    done when Xcode archives and App Store Connect accepts the build.
  - **Policy URLs** → build env / both consoles → set
    `PRIVACY_POLICY_URL=https://lab.legendstudy.com/privacy`,
    `TERMS_URL=https://lab.legendstudy.com/terms`, refund =
    `…/refund` → done when Settings shows live links and the consoles accept them.
  - **Payment compliance** → with Codex → decide IAP vs external for 논술 LAB
    Credit → done when the chosen flow passes both stores' digital-goods rules.
  - **Reviewer account** → Owner creates a test login → done when a reviewer can
    sign in and reach the gated features.

## Boundary
APP_CODE_CHANGED: **NO** · DB_CHANGED: **NO** · PAYMENT_CHANGED: **NO** ·
TOSS/IAP/Essay-runtime/Onboarding-routing/Auth/Profile: **unchanged** ·
CODEX_WORK_PRESERVED: **YES** (no merge of `codex/essay-web-runtime`) ·
Main merge: **NO** · Store submission: **NO**.
