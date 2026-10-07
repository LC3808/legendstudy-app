# LEGENDSTUDY-APP-FINAL-STORE-RC-1 — 2026-10-07

## Owner release-defines confirmation — supersedes initial config notes below

Owner confirms native essay available in v1. Independent Opus audit is cross-check
material: P0=0, P1=2 (defines), GO_WITH_FIXES; no feature change required. We did not
reopen router/onboarding/manifest audits. All three flags are now fixed true by
`tool/store-release`: ACCOUNT_DELETION_ENABLED, ESSAY_LIVE_WRITES_ENABLED,
ESSAY_EVALUATION_REQUESTS_ENABLED. Existing public production fields are retained;
the ignored local config was updated in place. Both platforms share the same loader
and overrides. Temporary merged config is mode0600 and deleted after the build.
Direct Flutter/Xcode commands bypass the wrapper; final signed builds must use it.
Updated defines: Android unsigned AAB PASS; iOS unsigned archive through the shared
entrypoint PASS. Generated iOS DART_DEFINES independently confirms all three true.
Merge/preservation, secure temporary file cleanup and missing Android signing rejection PASS.

Android release signing now consumes ignored android/key.properties; no key generated,
no debug-key fallback. Existing upload-key file is absent. iOS still has only Apple
Development identity; Team/distribution provisioning/export need Owner completion.
Signing/device status remains NO. No new feature-code/Production/Payment changes.

Focused device smoke after signing: login → first-run → native 논술 LAB → 문항 →
답안 저장 → 평가 요청 진입; deletion request→cancel on disposable synthetic account;
external browser link→return. No deletion of the durable reviewer or real student data.

## Result and evidence

APP base `73a2a358631f478d5bceaccb8ecd03c38218890a` on
`origin/claude/app-release-blocker-closeout-1`; closeout branch
`codex/final-store-rc-1`. Unified Wiki read at `207677d`: CURRENT_STATUS,
AI_CONTEXT, Daily 2026-10-06/05; Oct07 did not exist. Local APP release/privacy
handoffs were read but their October4 pending statuses are historical.

- Flutter3.47.6 stable / Dart3.13.5; fresh pub get + analyze PASS.
- Full tests: Owner authority +967 ~2 PASS; not rerun (no Dart/app feature change).
- Android release AAB PASS, 73.9MB; **unsigned**, not ready for Play upload.
- iOS release no-codesign PASS, Runner.app32.2MB; unsigned archive PASS198.3MB.
  App Settings Validation PASS; no IPA exported; not installable until signed.
- Generated Android registrant initially included integration_test after `pub get`
  with `build --no-pub`. Sequential retry alone failed. Standard `flutter build
  appbundle --release` regenerated the release registrant and PASSed. No generated
  file edits, dependency changes, skips or inclusion of test plugin in release.
- SDK wrapper incorrectly required3.47.5: aligned wrapper/default path and README
  with Owner-approved3.47.6. No SDK installation/upgrade.
- Manus logo diff:48PNG + mapping/manifest + picker +pubspec; independent optional
  visual change, not merged. Existing name fallback remains; not a release blocker.
- Production writes/deploys/Store uploads0. Toss/Payment/Math untouched.

Artifacts in `/private/tmp/legendstudy-final-store-rc` (temporary; preserve before cleanup):

- `build/app/outputs/bundle/release/app-release.aab`
- `build/ios/iphoneos/Runner.app`
- `build/ios/archive/Runner.xcarchive`

## Metadata and configuration

| Item | Verified result |
|---|---|
| Version/build |0.1.0+1; Store history not accessible, Owner must confirm unused build|
| Android / iOS ID |com.legendstudy.app|
| Display / brand |레전드스터디+ / LegendStudy Plus; existing launcher and splash assets retained|
| Android |min24, target/compile36; release signing unconfigured; AAB has no signature blocks|
| iOS |deployment15.0; Xcode27.0; iPhone+iPad declared; no Team in project|
| Signing identity |one Apple Development identity; no Apple Distribution identity found|
| iOS privacy |16 packaged PrivacyInfo.xcprivacy files parse; required-reason/Console validation still needed on final signed archive|
| Android permissions |INTERNET, ACCESS_NOTIFICATION_POLICY, POST_NOTIFICATIONS + plugin's signature-scoped dynamic-receiver permission; no storage/location/camera permission|
| iOS permissions |photo library for avatar; Sign in with Apple entitlement; no tracking permission|
| Ads / Community |no ad SDK; Community not released|
| Browser |externalApplication link; native PDF viewer; no unrestricted in-app web browser|
| Public URLs |privacy/, terms/, support/, account-deletion/ HTTP200 on lab.legendstudy.com (browser User-Agent; default Python request returned403)|
| Deep links |com.legendstudy.app auth-recovery/login-callback + Google reversed client scheme|

Ignored `config/store-rc.local.json` contains only allowlisted public build defines
from the existing local config; mode0600, not committed. `APP_ENV=production`,
existing Production Supabase URL/publishable key, Google public IDs, Email/social
login configuration retained; `ACCOUNT_DELETION_ENABLED=true`; canonical privacy
and terms URLs set. No privileged key copied. Existing ignored Auth.local.xcconfig
has Google reversed client ID only. No release flavor is configured.

**Release configuration decisions still required:**
- Essay write/evaluation flags remain default false in these artifacts. Native
  catalogue entry is implemented; do not represent this build as active AI submission.
  Owner must select catalogue-only truthful release copy OR existing approved runtime
  configuration and focused device acceptance; no provider activation done here.
- Recovery redirect define is absent in existing local configuration; final auth
  build must reconcile `SUPABASE_RECOVERY_REDIRECT=com.legendstudy.app://auth-recovery`
  with the existing hosted allowlist and verify return on device. No Auth settings changed.

## Store gates

P0: Android upload keystore + release signing config; iOS Team/distribution profile
and signed archive; final public release defines; both-platform device smoke;
Store build-number history, durable synthetic reviewer, privacy/Data Safety answers,
required screenshots/content rating/export-compliance answers; external-link/payment
policy decision below. Console values and credentials were not invented.

Latest Oct06 authority supersedes old deletion pending claims: backend synthetic
REQUEST→CANCEL→REQUEST→ERASED/DONE PASS; public deletion flow LIVE. That specific case
had0 Storage objects before/after, not1→0 proof. Apple revoke remains provider-specific
acceptance unless documented separately; email deletion does not prove Apple revoke.
Latest Wiki records privacy contradiction resolved by LAB ed8a1ca; don't reopen it
using October4 text. Final Console disclosure still needs active feature/provider scope.
Existing data-map draft in app-release-closeout.md is a starting point, not a signed-off
submission: add intended_major, interested universities and notification/read state
(account-linked personalization/notification functionality and lifecycle deletion).

P1: optional university logos, Gradle/AGP/Kotlin future support warnings, CocoaPods→SPM
migration suggestion (both build gates already pass); no upgrade needed for this task.
iPad layouts/2x text still need device acceptance because iPad is declared.

## External digital-service policy audit (no policy-driven code changes)

Current code: native essay route primary; secondary “웹에서 이용하기” opens the LAB
root in an external browser. No direct native Toss purchase CTA/IAP/Play Billing
implementation found in inspected LAB entry. External browser alone does not establish
policy compliance; where this link leads matters. Web payment is another team's scope.

- Apple: §3.1.3(b) cross-platform entitlements and §3.1.3(f) free companion exception
  have conditions; a generic AI education app is not automatically a reader exception.
  Storefront-specific external purchase allowances are not a global exemption.
  If v1 stays free/catalogue-only without purchase steering, IAP is not automatically
  required merely for existing code. Paid digital consumption/link destination must
  receive a commercial/Store decision before submission. If link enables prohibited
  steering in chosen storefronts, hide/restrict it in Store build or choose a supported
  entitlement/payment route; do not silently add IAP in this closeout.
- Google: consumption-only apps may access externally paid content, but linking from
  the app to alternate-payment destinations (including eventual navigation) is restricted
  absent an applicable enrolled exception. “웹에서 이용하기” must be assessed against the
  actual final destination. Existing web payment work does not automatically authorize
  native purchase routing or require new Play Billing for a free v1.

Sources: [Apple Review Guidelines](https://developer.apple.com/app-store/review/guidelines/),
[Google Payments policy FAQ](https://support.google.com/googleplay/android-developer/answer/10281818?hl=en).
This is a release risk assessment, not a Store approval claim.

## Owner device smoke — 10–15 minutes per platform

Prerequisite: signed build installed; synthetic existing login credentials available,
no real student data. First-run on fresh install; provider login tests log out between
accounts and verify prior account data clears. Connected iPhone detected; no Android
connected. **This task did not install or execute physical-device flows.**

| # | Check | Result |
|---|---|---|
|1|Cold start / splash|☐PASS ☐FAIL|
|2|Guest Home / no private data|☐PASS ☐FAIL|
|3|Email login; restart session restore|☐PASS ☐FAIL|
|4|Google login/cancel|☐PASS ☐FAIL|
|5|Apple login/cancel (iOS; N/A Android)|☐PASS ☐FAIL ☐N/A|
|6|Kakao login/cancel|☐PASS ☐FAIL|
|7|First-run brand→school→grade→universities→major|☐PASS ☐FAIL|
|8|School/grade save and reopen|☐PASS ☐FAIL|
|9|University search,0–5 selection/skip|☐PASS ☐FAIL|
|10|Desired major save and MY edit|☐PASS ☐FAIL|
|11|Home navigation/empty state|☐PASS ☐FAIL|
|12|D-Day save/reopen|☐PASS ☐FAIL|
|13|Materials search/filter|☐PASS ☐FAIL|
|14|Open one real PDF; return|☐PASS ☐FAIL|
|15|Save/recent persist and account isolation|☐PASS ☐FAIL|
|16|LAB Home|☐PASS ☐FAIL|
|17|내신분석 준비중 truthful state|☐PASS ☐FAIL|
|18|수능·모의고사 준비중 truthful state|☐PASS ☐FAIL|
|19|논술 LAB native entry; match enabled scope|☐PASS ☐FAIL|
|20|웹에서 이용하기 external browser + return|☐PASS ☐FAIL|
|21|Notification centre empty/list/read state|☐PASS ☐FAIL|
|22|MY profile / policies / support|☐PASS ☐FAIL|
|23|Logout; next account has no prior data|☐PASS ☐FAIL|
|24|MY→Settings→탈퇴 요청 discoverable + confirmation; don't delete durable reviewer|☐PASS ☐FAIL|
|25|No crash/overflow/dead-end, small width+large text; timer start/pause/end|☐PASS ☐FAIL|

Do not create or erase a real student account. Actual destructive deletion, if separately
performed, uses a disposable synthetic account only. A failed item records screen/action
and user-visible error, never credentials.

## Reviewer / next owner actions

Use a durable Production email/password synthetic reviewer in secure Console fields only;
no OTP requirement or expiry during review. Synthetic profile/D-Day/saved public material/
short study record are sufficient; no purchase or artificial entitlement required.
Reviewer notes: “레전드스터디+ provides Home, Materials, Learning, LAB and MY. Public
materials are available as guest; sign in for saved/history and personalization. 내신분석
and 수능·모의고사 LAB are coming soon. 논술 LAB opens natively; specify catalogue-only or
verified evaluation capability matching the final build. Account deletion is MY→Settings→
탈퇴 요청, also available at https://lab.legendstudy.com/account-deletion/. No native
purchase button is included.” Finalize scope sentence before Console submission.

1. Select final free/essay runtime scope and external-web-link policy for target storefronts.
2. Configure existing upload signing/Apple Team and unused build number; build with final
   local public defines using standard build commands (omit --no-pub); install signed builds.
3. Execute checklist, supply reviewer/Store disclosures/screenshots, then separately authorize upload.

READY_FOR_DEVICE_SMOKE:NO (signed install pending)
READY_FOR_APP_STORE_CONNECT:NO
READY_FOR_PLAY_CONSOLE:NO
