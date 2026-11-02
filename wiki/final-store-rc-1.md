# LEGENDSTUDY-APP-FINAL-STORE-RC-1

**Current release authority:** Oct19 v1 Store readiness below supersedes historical
unsigned-signing, free-only/no-native-purchase and pending-major notes. Native IAP
exists; Apple release policy is undecided. Historical checklists are not fresh PASS.

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

## Oct19 v1 Store readiness

Owner switches to release-only stabilization. Math/science quality,WEB UX,TTS naturalness,
personalized messages and university/question expansion are POST_LAUNCH, not v1 blockers.
No app/LAB feature code changed. Existing PDF/bookmark/recent/study/restart,university/major,
essay first/free/additional/shared History and Google TEST IAP acceptance are preserved.
School/latest splash/onboarding/account-management final smoke is not newly claimed PASS.
Sep2026 G1 organizer code/official source PASS; fresh iPhone display confirmation requested.
Device is currently unavailable to CoreDevice; no installation/deletion/reset attempted.

Remote source checked: APP5d106af,LAB916b46c,DOCSee4d6ce.
Old temporary worktrees/builds were absent. Fresh RC clone under
`/private/tmp/legendstudy-release-candidate-20261019`; restored existing public Production
client config/upload signing/native Google callback into ignored local files only.
No secret/new key/server configuration committed or changed. Source remains RC,not main/Claude.

### Local validation and artifacts

- Flutter3.47.6 Analyze PASS;35 focused organizer/auth lifecycle/deletion/billing tests PASS.
- Android shared `tool/store-release`:1.0.0(12),com.legendstudy.app,BILLING,Production host,
  review-only=false,three Store release flags=true. Signed AAB77.7MB,jarsigner verified;
  upload certificateSHA256 c00f4260d5b95a084335576c03bf36b8914a2f33cb3da701403e0adbacfb8ef1
  matches existing accepted upload key. No key rotation/Play signing investigation.
- Artifact: `build/app/outputs/bundle/release/app-release.aab` within fresh RC clone.
  SHA256 96246c497ccc45f906ca6c3200ede0e5993c88e2874cfce18463fc52fa6519cf.
- First Android build failed generated integration_test registration after concurrent Flutter
  test invocation; standard sequential release rebuild PASS without code/dependency changes.
  Future Flutter build/test operations in the same checkout must be sequential.
- Play Console latest bundle/active internal version2 (0.1.0); only1/2 listed. Local12 is higher and unused in the inspected list. iOS upload history still not independently inspected.
- iOS unsigned Release Archive PASS204.0MB,1.0.0(12),com.legendstudy.app,minimum15.0,
  encryption=false. Final built Info.plist Google callback matches existing public iOS client.
  `build/ios/archive/Runner.xcarchive` is unsigned and not uploadable; no IPA exported.
  Distribution identity/provisioning remain BLOCKER.
- No live request made from either artifact. Production IAP/server execution/public gates were
  not enabled. Embedded normal release flags are not evidence that paid service is launch-ready.

### Fresh App Store Connect read-only inspection

App6820826957:iOS1.0 Prepare for Submission. Description/keywords/support/version/copyright
and reviewer username applereview@legendstudy.com populated. Reviewer login usability not tested.
Support/privacy public URLs both HTTP200; privacy URL inside ASC is blank and data-collection
questionnaire is at Start. Selected iPhone screenshot slot0/10; other size coverage not inferred.
No selected/uploaded build shown. Pricing screen asks Add Price;175 territories available.
**Automatic release selected**, contrary to manual-release policy. No setting changed.
Paid Apps contract absent; updated Developer Agreement banner remains visible. Owner handles
contract resolution; do not infer acceptance from past status or accept agreements automatically.
Native StoreKit/products retained; Apple paid-feature launch policy/Sandbox still unresolved.

Owner corrected Play authority to ceo@copacabana.co.kr and opened existing Copacabana Console.
The other email is a tester,not the developer Console authority; no account created.
LegendStudy package com.legendstudy.app: active internal2(0.1.0),previous1 inactive,Production
inactive. Dashboard initial setup **0/11 complete**: privacy,app access,ads,content rating,
target audience,data safety,government,financial,health,category/contact,Store listing.
Production release is locked pending initial setup. No field/track/upload changed.

### Gates / next work

1. Play initial setup0/11: prepare concrete Store declarations/assets for Owner approval before changes/upload.
2. Apple Distribution identity/provisioning: current keychain only Apple Development; no new
   certificate generated. Signed Archive/IPA and TestFlight require completion,upload separate.
3. ASC approved metadata completion: screenshots,privacy URL/data disclosure,price,manual release,
   build linkage and reviewer access. Do not silently change Store fields.
4. Apple paid-feature policy/contract/Sandbox; Production IAP/refund activation remains unapproved.
5. Owner remaining device confirmation,including Sep G1 Incheon. Existing PASS not repeated.

No Production DB,Provider,Credit,purchase,refund,Store upload/review/public action. Refund TEST
OFF preserved,not redeployed/retested. LAB unchanged. General release HOLD.


## Oct19 final Android Production AAB18 preparation

Owner authorizes build/read-only Store inspection only. Source APPb18f6b5 and DOCS738d0f0
remote heads matched;clean trees. No feature changes or repeated organizer/Google purchase E2E.
Flutter Analyze PASS;45 billing/auth/session/environment/read-only/deletion tests PASS.
Existing tool/store-release Android build PASS64.9s,Production config and upload key reused.

Artifact: `/private/tmp/legendstudy-android-1.0.0-18/legendstudy-production-1.0.0-18.aab`
(original build/app/outputs/bundle/release/app-release.aab),77,681,396bytes.
SHA256:c2c732f0c634cb4be29451436f4d06875a31a7b6add53de1eb304bf3d5a4ba0d.
Actual bundletool manifest:com.legendstudy.app,versionName1.0.0,versionCode18,minSDK24,
targetSDK36,BILLING present. bundletool1.18.1validate PASS. jarsigner reports jar verified;
certificateSHA256 c00f4260d5b95a084335576c03bf36b8914a2f33cb3da701403e0adbacfb8ef1
matches the existing accepted upload key. Self-signed/no timestamp and JarInputStream ZIP
ordering warnings recorded;no repacking/resigning/key rotation. Play acceptance remains
unverified until separately approved upload,not inferred from local verification.

Config:APP_ENV production,stlhijzpjfgwwdgunlsd,REVIEW_READ_ONLY=false. Existing Store wrapper
sets deletion/essay-live/evaluation=true;IAP client defaulttrue. No TEST project values in
input defines;no local config/keystore/service-role file bundled. AOT includes Production
host,lab.legendstudy.com,privacy URL and all4existing com.legendstudy.essay.credit1/3/5/10.
TEST host constant in isolation validator is not an active TEST connection. Production-only
host validation/session separation tests preserved. Native account deletion enabled/tested,
not executed. Production essay catalog origin unchanged. No server flags activated by build.
No launch from artifact/no Provider/Credit/purchase/DB/delete operation.

Fresh Play read-only:developer6807727077532562397 app4972317086113621808;latest uploaded
versionCode2/internal active,1inactive;18higher/not shown uploaded. Production inactive.
Initial setup0/11. App name 레전드스터디+ present;short/full descriptions blank;icon/feature
graphic/phone screenshots absent. Privacy URL blank. Category unselected;contact email,
phone,website blank. Login/app-access,ads,content rating,target audience,data safety,
government,financial,health declarations incomplete. No fields saved or files uploaded.
Closed/public tests and production show complete initial setup first. No additional numeric
tester/day requirement shown here;do not infer this account is blocked by a generic14day rule.
Existing Google TEST E2E preserved;production-device/store delivery is not newly verified.

Public browser:privacy/support/account-deletion pages render without login. urllib request
received403 but browser rendered normally;not recorded as site downtime. Privacy text still
LAB/browser-centric with future payment wording;support describes web4900KRW refund formula
without Store separation;deletion page retains preactivation/policy-pending language.
These content/actual-release-policy mismatches need Owner-approved reconciliation before
Store submission;no legal compliance approval claimed. Existing URLs reused,no page built.

Remaining:complete Play11setup/assets/reviewer declarations;confirm Production paid-service/
refund readiness and public disclosures under existing approval gates;approved upload then
Play delivery/device verification. AAB local preparation PASS,release readiness PARTIAL.
No Android TEST app replacement;no upload/review/public release. General HOLD.

## Oct19 Xcode automatic distribution signing preparation

Owner approved new Apple Distribution certificate, automatic App Store provisioning
and Archive verification only;IPA Export/TestFlight upload remain separate gates.
After Owner Xcode re-login, one Apple Distribution identity was created for Copacabana
Co. (VUKFS69GB4),fingerprint D10347DD9621A11F38CD6923AD10BE7DB52D1E48.
Existing Apple Development A98E1BFD3480040B968DBF7197A8A6058B04C9E2 retained;no
revocation or key replacement. Existing com.legendstudy.app/team/project settings unchanged.

Production1.0.0(18) Archive SUCCEEDED and codesign --verify --deep --strict passed:
`/private/tmp/legendstudy-ios-1.0.0-18/Runner.xcarchive`. This archive is development
signed (get-task-allow=true/device-limited);do not call it an exported App Store IPA.
Automatic archive with global Apple Distribution override failed conflicting signing
settings in Runner/dependencies;diagnostic override only,no project edits. Use normal
automatic Archive then Organizer automatic distribution signing instead.

Organizer Custom → App Store Connect → Export preparation (no final Export action),
version management/symbol upload unchecked → Automatically manage signing generated
`iOS Team Store Provisioning Profile: com.legendstudy.app`,UUID
3f6105ea-0f50-45a4-9c75-44b7eb29e817,expiry2027-10-19T03:57:20Z.
Verified team/application identifier, get-task-allow=false,no device list/no enterprise
flag,and DeveloperCertificates matches the new Distribution identity. Existing development
profile retained. No private key/profile bytes committed.

Owner completed macOS keychain authorization. Organizer reached Review legendstudy_app.ipa
content with Apple Distribution/App Store profile,version1.0.0(18),team/application ID
matching,beta-reports-active=true,get-task-allow=false. Final Export button was not
pressed;Cancel returned to Archives. Distribution preparation PASS;no exported IPA
or upload/Store validation/approval claimed. Certificate/profile signing blocker closed;
Apple paid-contract/Sandbox/release-policy gates remain separate.
No Store upload/submission,DB/Provider/Credit operation. Public HOLD.

## Oct19 approved iOS IPA Export PASS

Owner authorized local App Store Connect IPA Export only. Reused previously verified
Runner.xcarchive1.0.0(18),no rebuild. xcodebuild -exportArchive completed successfully
with method=app-store-connect,destination=export,teamVUKFS69GB4,automatic signing,
manageAppVersionAndBuildNumber=false,uploadSymbols=false. No TestFlight/Store upload.

Artifact: `/private/tmp/legendstudy-ios-1.0.0-18/AppStoreExport/legendstudy_app.ipa`
Size:16105966bytes (15.36MiB). SHA256:e1d3765351fb64e4c0dcffeae5205d318ee5e9a8f1c81326341692a0f61fa22b.
Unpacked IPA:com.legendstudy.app/1.0.0/18,encryption=false. codesign deep/strict PASS;
Apple Distribution:Copacabana Co.(VUKFS69GB4). Signed entitlements application ID/team
match,get-task-allow=false,beta-reports-active=true. Embedded Store profile
3f6105ea-0f50-45a4-9c75-44b7eb29e817,no device list,existing generated profile reused.

Actual Archive build DART_DEFINES:APP_ENV=production,Production Supabase host,
REVIEW_READ_ONLY=false,no TEST project value. Exported AOT contains Production host
and lab.legendstudy.com. TEST host literal remains in environment-isolation validator;
it is not an active TEST configuration. Diagnostic guard code retained,flag OFF.
No p12/p8/key/jks/keystore files in IPA. No source/config contract change.
IPA was not installed/executed;this verifies packaged configuration,not new live E2E.
Previous Google/essay E2E preserved. Apple IAP contract/Sandbox and release-policy gates
remain separate. Next approval is TestFlight upload;Store review/public release remain
unapproved. No DB/Provider/Credit operation. General HOLD.

## Oct19 approved TestFlight upload

Owner authorized upload of existing IPA only;SHA256 rechecked and matched
e1d3765351fb64e4c0dcffeae5205d318ee5e9a8f1c81326341692a0f61fa22b.
Owner installed official Apple Transporter,accepted its license and completed login.
Transporter Copacabana Co. identified existing app6820826957,version1.0.0(18).
Single Deliver completed Oct19 13:40 KST;Transporter shows Delivered/app processing.
No rebuild/re-export;no tester/group additions or distribution,Store review submission.
Apple processing completed: TestFlight iOS list shows version1.0.0/build18,
Ready to Submit (제출 준비 완료),90-day expiry and testable-build guidance.
Metadata: Binary Validated (검증됨),uploaded Oct19 13:41 KST,bundlecom.legendstudy.app,
version1.0.0/build18,non-exempt encryption=false. Server-reported entitlements match
VUKFS69GB4.com.legendstudy.app/teamVUKFS69GB4,get-task-allow=false,
beta-reports-active=true,Apple Sign In Default. No signature/entitlement error shown.
Build ID57833805-7b4a-47f6-9aeb-4556d27f5a4e. Internal group assignment available;
groups0,no testers invited,no beta distribution or Store submission performed.
Upload+Apple processing PASS;tester delivery/device test NOT_RUN pending Owner approval.
Transporter yellow status was app processing,not a reported signature failure.
Local screenshot:/private/tmp/legendstudy-ios-1.0.0-18/testflight-build18-validated.png.
ASC:https://appstoreconnect.apple.com/apps/6820826957/testflight/ios/57833805-7b4a-47f6-9aeb-4556d27f5a4e/metadata
No DB/Provider/Credit operation. Apple IAP contract/Sandbox remains separate. Public HOLD.

## Oct19 Owner internal TestFlight distribution

Owner authorized existing account holder only and build18 distribution. Created internal
Owner Internal QA(group2ac54dff-949c-4385-9f4b-9e841ff20646),automatic distribution OFF.
Selected existing Account Holder/Administrator only;no external users or account roles
changed. ASC confirms1tester/1build,1.0.0(18)Testing. No rebuild/reupload/review submission.
Connected iPhone12ProMax currently1.0.0(17). Installation NOT_RUN. Attempted protected
local Documents/Preferences backup was rejected before execution by automatic approval
review because auth/session data could be copied without explicit backup authorization.
Requested Owner approval for local-only protected backup;no data copied or reset.
Same bundle/team verified;actual development-to-TestFlight data/session preservation
remains unverified until installation checks. Do not claim lossless migration from IDs alone.
main.dart skips intro for existing Auth;AppDelegate also treats study-state-v1.json as
existing installation. Preserve these;fresh intro cannot be validated on this existing
state without reset. Existing isolated simulator intro PASS retained;fresh-device QA gap.
Device feature tests await safe install:login,PDF/saved/recent,study,profile,essay/history,
Credit read only;no purchase/new evaluation/deletion. Public HOLD.

### Owner-approved preinstall backup completed

Owner explicitly approved Documents/Preferences then actual Application Support path.
Device copy succeeded:Documents0files,Preferences1file5039bytes,Application Support
7files3959558bytes. Protected local directory0700/files0600,local SHA256 manifest
re-read verification PASS;no file contents/auth tokens printed or uploaded. Location:
/private/tmp/legendstudy-testflight-preinstall-20261019 (private backup,not committed).
Earlier incorrect Documents assumption corrected from AppDelegate storage paths.
Existing iPhone still1.0.0(17);no uninstall/reset/install performed by agent. Owner asked
to accept internal invitation and update through TestFlight to18 without deletion,then
verify session/Draft/study/Credit. Installation/data preservation still pending,not PASS.
Backup covers those app-container paths,not an asserted full-device/Keychain backup.

### Owner device clarification: TestFlight on a different iPhone

Owner confirmed TestFlight1.0.0(18) on iPhone17ProMax,not the USB-connected
iPhone12ProMax. Installation accepted as Owner-confirmed PASS,not direct tool inspection.
Connected12ProMax still1.0.0(17) by devicectl;this is expected and not a failed update.
Its original app/session/local files were not replaced or reset;protected backup retained.
Prior Owner response "confirmed" applies to their TestFlight check;do not infer a
17-to18 data migration on12ProMax or granular fresh-onboarding/feature PASS from it.
Per-feature fresh intro,PDF/saved/recent,study,profile,essay/history/Credit verification
needs explicit device results where not already reported. No purchase/evaluation/deletion.
Apple IAP contract/Sandbox blocker remains separate. Store review/public release HOLD.

## Oct19 TestFlight18 Owner defect fixes — local candidate19

Owner iPhone17ProMax:login/home/existing essay history/account/guide PASS;startup and
post-login unexpectedly open deletion form. Confirmed router cause:accountLifecycleRedirect
routed every non-NORMAL/non-CANCELLED state,including AsyncLoading/error/null,to
/my/delete-account. The router refresh listener fires during startup/profile resolution;
ordinary auth success already targets /home. No evidence of a new deletion request.
Fix:home is always allowed;restricted/unknown states retain personalized-route restriction
but return home,never automatically open deletion form. Direct MY deletion remains;
request/cancel/server functions and14-day policy unchanged. No deep-link/stack cause claimed.

Removed redundant Materials "필터 목록 더 보기" button only;existing filter arrangement,
choices/search/reset/retry and repository contracts retained. Regression includes a
nextOffset100 facet response,absence of button and year selection.

Public Production GET /api/essay/catalog returned essay-source-registry-v1,21 source
universities/77unique VERIFIED exams/237questions,years2021–2027. All exams nonempty.
App merge preserves42university catalog. Current237 differs from historical234;no data
modified. Environment Production/review-read-only OFF;TEST not used. Shared History
contract tests pass;Owner existing results/history PASS reused,no new authenticated query
or token extraction. No claim of live all-account History/PDF coverage.

Hanyang shared university URL bn14860 is reachable but identifies2025 humanities MOCK
essay;incorrect as a generic source for other selected exams. Verified official archive:
https://go.hanyang.ac.kr/web/pds/pds_list.do?ct02=ns01&m_type=SUSI
It lists2024humanities afternoon2 and other years. Display adapter uses this archive
for Hanyang;raw registry/catalog source URL and IDs/questions remain untouched.
Device browser-specific launch failure not independently reproduced. Owner fallback
policy applied without DB/LAB changes. Source:https://go.hanyang.ac.kr/web/pds/pds_view.do?bn=14860&m_type=SUSI

Validation:project Flutter3.47.6 Analyze no issues;150related tests PASS,including
auth/login/recovery/lifecycle,search/filter,Catalog/native360dp/200%,History,environment.
Initial PATH SDK3.8 failed dependency resolution;verified project wrapper used thereafter.
iOS Release1.0.0(19) no-codesign build PASS (35.9MB);not a signed Archive/IPA. Existing TestFlight18 preserved;no new upload.
Final device PASS requires next signed TestFlight candidate and Owner rerun:startup/login
lands home;manual MY deletion only;Catalog/exam/questions;Hanyang archive;filter no button.
No DB/Provider/Credit/purchase/deletion action. Apple IAP gate remains.Public HOLD.


## Oct19 TestFlight19 signed release and internal distribution

Owner approved Archive/IPA/upload/existing Owner group for source2e32195;remote matched
and source tree clean. Reused Copacabana VUKFS69GB4 automatic signing and existing
App Store profile;no certificate/profile recreation or source behavior changes.
Archive and App Store Export PASS. IPA16,105,728bytes:
`/private/tmp/legendstudy-ios-1.0.0-19/AppStoreExport/legendstudy_app.ipa`
SHA256`fde1f2c19ea3135b161ed48fb2883433a3f1e55654de4a7cdbe584c6ef64cade`.
Bundlecom.legendstudy.app,version1.0.0/build19,encryption exemption false.
Deep/strict signature verification PASS;Store profile,get-task-allow=false,
beta-reports-active=true,no device list. Compiled Production host stlhijzpjfgwwdgunlsd,
APP_ENV=production,REVIEW_READ_ONLY=false. TEST host constants in validation code do
not constitute an active TEST connection. Analyze150related tests from unchanged source
reused. Official Transporter delivered19 at14:39KST;ASC processing observed.
Existing18 and iPhone12ProMax17 preserved. No DB/purchase/Credit/Provider/deletion or
Store review/public release. Processing/distribution/device outcome recorded below.

Apple processing completed;build19 UUID f7cc9407-78aa-4983-8163-c9f8fc5b7eae became
ready. Added to existing Owner Internal QA only;ASC shows1tester/2builds,19and18 Testing.
No new testers/group;automatic distribution policy unchanged. Proof:
`/private/tmp/legendstudy-ios-1.0.0-19/testflight-owner-distributed.png`.
Owner iPhone17ProMax update/retest requested:startup and login home,no automatic deletion;
manual MY deletion entry only(no execution);LAB/catalog/exam/questions/History/Credit;
filter-more absent/search/filter;Hanyang official archive. Device result pending;overall
PARTIAL,not final PASS. Real pending-deletion account was not changed;restriction tested
locally only. Apple paid-contract/Sandbox remains independent release blocker.


### Oct19 Owner TestFlight19 device acceptance — PASS

Owner reports "모두확인 완료. pass" for the requested iPhone17ProMax TestFlight19
checklist:logged-in relaunch and completed login land home without automatic deletion;
manual MY deletion entry;essay university/exam/question/History/Credit queries;
filter-more removed with search/filter working;Hanyang official source archive opens.
Archive/export/upload/Apple processing/internal distribution and this bounded device
regression are PASS. Device evidence is Owner-reported,not remote UI instrumentation.
No actual account deletion,purchase,new evaluation or pending-deletion account mutation
was requested/performed;14-day and restricted-account policy retain prior code/test
verification,not a new destructive E2E. Original12ProMax app remains preserved.
No additional build/deploy needed for this acceptance. Apple IAP contract/Sandbox and
other store release gates remain separate;this does not authorize Store review/public
release. Public HOLD maintained.

## Oct19 20:28 KST Owner submitted iOS and four IAPs

Owner confirms App Store review submission completed at 2026-10-19 20:28 KST:
iOS app version1.0 / build1.0.0(19), and consumable credit1, credit3, credit5,
credit10. All five items Waiting for Review. Release method MANUAL per Owner.
This supersedes the earlier read-only observation of a submission draft and
AFTER_APPROVAL selection; no Codex submission or setting change was performed.
Owner report is the evidence source; no repeat submission/build/device E2E.

Apple Paid Apps agreement and bank processing, Korea tax pending, and Apple
Sandbox product/purchase E2E remain separate incomplete items. Existing US tax
forms active per prior Owner report. Review submission is not review approval,
contract activation, Sandbox PASS or public release. General public HOLD remains.

Next priority: Android Google Play release preparation. Existing AAB18 remains
intact:77,681,396bytes;SHA256 c2c732f0c634cb4be29451436f4d06875a31a7b6add53de1eb304bf3d5a4ba0d.
Source b18f6b5 predates current RC changes in account_deletion.dart,
source_catalog.dart and materials_page.dart (routing, Hanyang source link,
filter button). It must not be represented as containing TestFlight19 fixes.
Next action: reconcile current Play mandatory listing/policy state and prepare
latest RC AAB when needed, preserving upload key/TEST install/Google E2E PASS.
Prior Play0/11 is historical, not a freshly reverified current status. No rebuild,
upload, purchase, Provider/Credit/DB operation or public release in this update.

## Oct19 official homepage prepared — deployment approval pending

Owner requests home.legendstudy.com official homepage. Independent LAB worktree
/private/tmp/legendstudy-home-20261019, branch codex/official-home-20261019,
local commit 20cf31b. Only official-home/ added; LAB/app/payment/database unchanged.
Hero, resources/PDF, study timer/D-Day, essay LAB, preparing store labels, support,
privacy/terms/account-deletion links and authority-derived business footer ready.
Actual Owner resource/timer screenshots; Pretendard, light background, navy/orange.
Build/static checks PASS. Chrome desktop and mobile 360/390px QA PASS (no horizontal
overflow/missing images). Existing public legal/support/LAB pages render in Chrome;
non-browser requests to LAB receive edge 403. legendstudy.com HTTP200.

home DNS NXDOMAIN, authoritative Gabia; existing LAB Cloudflare Pages unchanged.
Proposed new independent Pages legendstudy-home + direct upload official-home/dist
+ home CNAME to confirmed new pages.dev hostname. Owner approval required before
new hosting deployment/custom domain/DNS. No DNS or operating changes made.
HTTPS home NOT PASS; awaiting approval. Branch kept local to avoid unintentionally
triggering existing LAB preview deployment. Rollback and exact scope in official-home/README.md.
General public app HOLD and store preparing labels maintained.

## Oct19 official homepage deployed — Gabia login pending

Owner approved new Pages + home custom domain + home CNAME. Independent Pages
legendstudy-home created, no Git integration/env/secrets/DB bindings. Static-only
deployment4104f06d-b748-4ee0-b40f-aca5ccbd909c SUCCESS; Chrome HTTPS page rendering
confirmed at https://legendstudy-home.pages.dev/. Existing LAB/apex untouched.
Initial deployment auto-detected LAB-root Functions; replaced by a deployment
from official-home/ and the initial deployment was removed. Future deployments
MUST run from official-home/. No endpoint calls or DB operations performed.

home.legendstudy.com custom domain registered; Cloudflare pending, CNAME record
not set. Gabia login/CAPTCHA requires Owner action; login page handed off. DNS
not modified yet, therefore requested home HTTPS completion remains pending.
Homepage local branch commit bf9d890; static site source20cf31b. Store labels
remain preparing, public app HOLD preserved.

## 2026-11-01 — 공식 홈페이지 출시 전환 후속
기존 준비 홈페이지와 배포 이력은 보존한다. Owner TASK12 출시 문구·스토어 CTA 변경 및 검증은 [공식 홈페이지 출시 보고](official-home-launch-task12.md) 참조. 운영 배포는 별도 승인 대기다.


## TASK14 — beta store release candidate 2026-11-01

Owner explicitly authorized iOS/Android build, upload and review submission, prioritizing release over administrator expansion. Submission remains gated by actual core-function verification; this does not authorize Production beta/Credit changes. Existing native implementation and bundle/package `com.legendstudy.app` preserved.

### Source and automated checks

- Source: `b4dea2fed42df574b363f054e7da84ca7d15393c`; branch `codex/beta-store-release-task14`. Documentation commit after build is not the binary source SHA.
- `./tool/flutterw` Flutter 3.47.5 / Dart 3.13.4; analyze PASS (no issues), full tests **1306 PASS / 7 SKIP / 0 FAIL**. No source edits or weakened tests.
- Existing Production Observation V1 / social-login configuration reused via ignored local files; secrets and signing material not committed. Analytics remains safe Noop without configuration.
- Both versions **1.0.1 (34)** supplied explicitly through release wrapper. Existing TEST build 33 and previous artifacts preserved.
- iOS signed App Store IPA: `build/ios/ipa/legendstudy_app.ipa`; SHA256 `3b878dc5b952f61e66f3b0035d151d9cef7e951b8cff0f4869fc8db5ec2f33d7`.
- Android signed AAB: `build/app/outputs/bundle/release/app-release.aab`; SHA256 `0963d33aabfa9209c7681880bbcbeebb8905e940aab2cab95c0824e53ff44a23`. Existing upload certificate preserved; min SDK24 / target36.
- Local logs: `/tmp/task14-analyze.log`, `/tmp/task14-test.log`, `/tmp/task14-ios-build.log`, `/tmp/task14-android-build.log`. Build warnings: future Kotlin upgrade, SDK XML compatibility and CupertinoIcons reference; no build failure.

### Actual store and device evidence

- App Store Connect app6820826957: existing public version1.0/build19 retained. Transporter upload **SUCCESS**, 2026-11-01 22:03 KST; Processing completed; **1.0.1(34)** linked to existing **Owner Internal QA** group (1 tester), test instructions saved. Upload/internal group assignment is not review submission.
- Google Play app4972317086113621808: AAB34 accepted in internal track4701319249543191162, draft release4. Preview recognizes bundle/version/signing, with one APK size-increase warning (23.4MB install, +6.98MB; supported devices unchanged). Internal release not published; Production18 unchanged. Existing account payment-attention alert remains unverified and financial settings untouched.
- Connected iPhone12ProMax: build34 installed over build32 without uninstall/data wipe. Launch attempt blocked by locked device. Owner subsequently replied “조회 완료 pass” to the requested app launch/existing login/material search/PDF/save/study timer/existing evaluation results checklist on 2026-11-01. Those scoped iPhone checks are **Owner-reported PASS**, not agent-observed E2E. Initial locked-device failure is retained as history.
- Android physical-device/internal-track runtime verification NOT_TESTED. Apple/Google reauthentication completed by Owner.

### Production release blockers — verified read-only

1. **Beta v2 missing**: APP calls `essay_beta_daily_claim_v2`; Production has no v2 RPC. Existing v1 claim would grant2/day when configured; campaign table is empty, so no active beta. Do not invoke old claim or change its policy. Required1/day/KST/end/rewrite contract cannot be claimed verified in Production. Existing `supabase/candidates/essay_beta_daily_v2/precheck.sql` executed in read-only transaction and **PASS** (definition/ACL baseline, no legacy campaign/grant history); migration/activation NOT executed. Reviewed candidate is preparation, not deployment evidence.
2. **Notices missing**: no notice tables/RPC; actual anonymous read-only `notice_list` returned HTTP404/PGRST202. Mandatory notice feature is not ready against this backend.
3. **Remaining acceptance incomplete**: iPhone app launch/existing login/search/PDF/save/timer/existing results are Owner-reported PASS. Separate Apple sign-in flow, Android runtime/login, deletion, cross-platform sync, OCR and new evaluation/free-rewrite flow remain NOT_TESTED. No Provider calls, new evaluations or purchases performed to fake E2E success.
4. Account deletion is NOT classified as missing: deployed delete-account v28 and account-deletion-worker v38 ACTIVE; SQL and active dispatch cron exist. OPTIONS204 proves enabled handler, not successful deletion/revocation. Destructive acceptance remains NOT_TESTED.

Production DB/Worker/Provider/Credit/History/payment policies unchanged. Only read-only DB/catalog/API checks. No actual evaluation, grant, charge, purchase or deletion. Backend blockers require a separate reviewed operational approval under TASK14 restrictions, including existing notices installation and beta-v2 installation/activation dependencies, exact start/scope/Owner/notice identifiers. [Beta candidate policy](essay-beta-daily-v2.md), [notices contract](notices-system.md), [shared TEST limitations](essay-shared-test-task09-20261101.md).

### Handoff and rollback

**BUILD SUCCESS / UPLOAD SUCCESS; REVIEW BLOCKED.** Do not report SUBMITTED FOR REVIEW or IN REVIEW. Existing public binaries remain unchanged. Keep uploaded34 and internal draft for continuation; never reuse34 for different binaries. After backend readiness and actual-device acceptance, confirm Apple compliance, existing review metadata/account/privacy/IAP and Play account alert, then submit with existing settings. Do not roll out a draft with known core blockers.

No Production rollback required: no public release or backend mutation. Retain previous public iOS19 / Android18 and build33 TEST; do not wipe user data or delete uploaded evidence. Local release configuration is ignored; source rollback remains Git-based. Existing homepage history above is superseded by the linked TASK12-B deployment report.

## TASK14-B — scoped backend installation and Owner UX defects

2026-11-01 Owner authorized beta-v2/notices Production installation and review submission only after mandatory gates. This supersedes TASK14's missing-RPC status, not its unverified-device gates.

### Production evidence

- Project `stlhijzpjfgwwdgunlsd`: migrations `20261101133219/notices_v1_task14b` and `20261101133227/essay_beta_daily_v2_task14b` installed from existing candidates. Both postchecks passed, including beta function owner/ACL/digest manifest. Campaign activation is still pending; installation alone does not establish active daily free use.
- Fresh private PG17 custom backup before installation: `development/legendstudy-private-backups/task14b-20261101/database.dump`, 120113137 bytes, SHA256 `0dfdcc0eeab3c27fff9eb642143e0e7e96894774a17c46bb291e01fd3691c9e7`. TOC and full archive decode verified; no full restore rehearsal. Storage objects unchanged and not included in SQL archive.
- Before/after row counts and ordered content hashes unchanged for credit_accounts (15), credit_grants (23), credit_transactions (112), payment_orders (11), payment_operations (3), payment_events (17), essay_billing_decisions (72), runs (54), checkpoints (708). No Provider/evaluation/payment/credit action executed.
- Isolated localhost PostgreSQL17 port55445: existing notices contract PASS; beta-v2 runtime suite 33 assertion groups PASS (60 concurrent claims, 30 reservations/callbacks, midnight/end/rewrite/failure/paid isolation). Production time was not changed.
- Existing authenticated admin published two public pinned APP+WEB notices: `284919ef-fcbf-411e-a17f-df8bc4f2b7da` 앱 출시; `fdeb9d5d-b075-4b2c-9950-cf8fe8c21656` 논술 LAB 베타. Existing beta draft/policy reused; no duplicate existing notice. Published list verified through real admin browser.
- Scope preparation intersected live Pages ESSAY_PUBLIC_EXAMS with existing full release evidence, exact Production runtime policy/package and full question IDs: 160 humanities exams. Partial-release exam excluded. Scope is prepared, not active. No Registry publish flag changes.
- Activation template now supplies a transaction-local five-minute exp claim for the existing hardened admin gate; administrator authorization itself is unchanged. Activation has NOT been executed. Live `/essay-lab/` chunk `3kuh09-194c3f.js` still invokes legacy claim and hard-codes ‘매일 첫 논술 LAB 접속 시 2개가 지급’. v1 compatibility wrapper returns v2 allowance safely, but the visible policy is wrong. Existing source v2 student page needs a separately approved scoped Production WEB release before campaign activation. Current task's SQL permission is not treated as blanket WEB replacement authorization.

### Owner device findings and preservation review

Owner reported LAB entry PASS but MY aspirations incorrectly opens high-school editor, accidental school removal, mixed school/aspirations form and indistinguishable university service state. This is not confirmation of separate Apple/Google/signup/deletion/Android tests. Do not ask Owner to repeat the same submitted report.

Seven preservation answers ([canonical review](longitudinal-learning-admissions-data-strategy.md#preservation-and-architecture-review)):
1. Navigation/display changes create no new historical fact; school changes retain existing explicit-save repository semantics.
2. Existing backend remains truth. Previously removed school cannot be inferred or reconstructed from this screenshot.
3. No storage UPDATE contract changes; add removal confirmation and separate aspirations to prevent unrelated edits.
4. Existing authenticated identity/provider isolation retained, including identity recheck after confirmation.
5. Aspirations are Decision data, not actual admissions/outcomes; application read-only summary retained.
6. Existing own-profile access/retention applies; no additional collection or analytics payload.
7. Service labels derive from existing server availability; no stored derived state or inferred eligibility.

Implementation: `/my/aspirations` reuses existing university/major editors; `/my/school` contains school/status/grade only. Search explicitly says high school. Existing saved school removal requires confirmation; cancel writes nothing. LAB cards display available/preparing/unknown states from existing provider; unavailable universities remain disabled. Existing nickname/photo editor preserved. These native source edits require a new build; uploaded34 cannot incorporate them and is not submitted as the fixed release.

Rollback: UI changes are isolated Git changes; preserve34 artifacts. Notices can be archived through existing admin contract. Beta rollback must use candidate guarded procedure and retain any newly accepted runs/grants; never restore the whole DB over later user writes. Original backup is emergency evidence, not an automatic rollback operation.

### UX automated validation

Project SDK analyze PASS. Full run:1309 PASS /1 FAIL /7 SKIP; the sole failure expected one global loading label, whereas the new per-university states correctly rendered four. Updated the assertion to verify each of three cards plus list status, error states and 2 available/1 preparing cards; targeted rerun PASS. New actual-router and school-removal cancellation tests PASS. Final full rerun: **1310 PASS /7 SKIP /0 FAIL**. System PATH Flutter3.8 cannot resolve this project; all valid checks use `./tool/flutterw`.

Published beta notice explicitly states activation is pending; future policy is not advertised as already usable. UI source and verification are separate from the remaining WEB/activation/device gates.

### Build35 and final invariant follow-up

Source `d3e2cbdeba680ea8acbe9f4c588de3ce04548707`, branch `codex/beta-store-release-task14`, pushed with LOCAL/REMOTE equality. Both signed release builds **1.0.1(35)** succeeded using the existing Production Observation V1/social-login config. Build34 IPA/AAB preserved privately under `development/legendstudy-private-backups/task14b-20261101/build34/`. No data wipe or new device PASS inferred.

- iOS IPA `build/ios/ipa/legendstudy_app.ipa`: SHA256 `6475083a37e6ded2842f4cb3fb6ec763e09118c5d36d0e553a93d013fce31f33`. Bundle/version/build verified; codesign deep/strict verification passed. Transporter delivered35 at22:57 KST; App Store Connect processing completed; existing Owner Internal QA group (1 tester) linked, delta-only test notes saved. Review NOT submitted.
- Android AAB `build/app/outputs/bundle/release/app-release.aab`: SHA256 `eab117b9af81cc2344cbe355ff06bd2c8064cf8e3077507a199bbd257fd13087`. Play accepted35/min24/target36, existing internal release4 updated and published to the internal track only at23:03 KST; console confirms “내부 테스터에게 제공됨”.34 excluded from this release but retained in artifact library. Existing Production18 unchanged. Physical Android verification NOT_TESTED (no connected device). Jarsigner reports verified with existing self-signed/no-timestamp and ZIP-stream warnings; Play upload accepted the artifact.
- Local logs `/tmp/task14b-ios-build.log`, `/tmp/task14b-android-build.log`, `/tmp/task14b-full-final.log`. Full Flutter suite1310PASS/7SKIP/0FAIL and Analyze0issues; upload success is not acceptance/review submission.

A later read-only check found one concurrent `signup_bonus_v1` +3 transaction at2026-11-01T13:46:02.612764Z (credit accounts16/grants24/transactions113). This task did not create that transaction or identify its actor. All pre-install rows (`created_at < 2026-11-01T13:32:00Z`) retain their original counts/content hashes; payment and evaluation full-table hashes remain unchanged. Thus historical Credit preservation is verified, not a claim that no other user can write during the work.

Anonymous APP/WEB notice_list each returns2 published notices. Authenticated non-admin notice list/write administrative RPC calls rejected with42501 in a read-only transaction; anon/authenticated have no private-schema usage. Existing Owner admin gate verified read-only. Campaign count remains0. Public beta notice clearly labels activation pending. No Provider, new evaluation, purchase, manual Credit grant/debit or Worker change by this task.

Existing WEB source130cb44 has the v2 student quota component; focused `essay-beta-credit.test.tsx`11PASS. Production student assets are still older. This verifies source behavior, not a scoped deployment artifact or operational activation.

Android internal-only opt-in URL: https://play.google.com/apps/internaltest/4701319249543191162 . Existing tester eligibility unchanged; actual installation/device acceptance pending. Play validation:0 blocking errors,1 APK-size warning (23.4MB,+6.98MB), supported devices unchanged. This is internal testing availability, not Production review submission. iOS35 existing Owner Internal QA assignment confirmed; TestFlight delta checklist saved.


## TASK14-B addendum — read-only onboarding and daily beta activation

This section supersedes the earlier inactive-campaign/WEB-blocked/build35 notes. Owner explicitly approved Production WEB rollout and beta onboarding. Existing Provider/Worker/payment policies remain unchanged.

- APP source `1be8bef`; new signed iOS and Android **1.0.1(36)** built with existing Production Observation V1 config, same Supabase project as WEB. Builds34/35 preserved privately. iOS codesign deep/strict PASS. IPA SHA256 `fd7ccfa57890f8a7ea1b814a67ea986bec450b20d27ca5afa82c3189238a096f`; AAB SHA256 `9afab1ae08b33ea96ad79741ef029982d5af9aa90d3874333069f969e4f1f936`.
- iOS36 uploaded at23:34 KST; processing complete, build422c2057-7d76-4cda-97d1-d25e4ea5bb99 linked to existing Owner Internal QA(1tester); delta notes saved. Android36 signed artifact ready, browser upload initially blocked by extension file-URL access. Neither is submitted for Production review at this checkpoint; device acceptance remains required.
- Additive migration `20261101141223/essay_beta_readonly_onboarding` verified in actual history; authenticated self-scoped `essay_beta_daily_status_v2` installed; entry/start are read-only. Existing15v2function definitions unchanged. Anonymous execute denied. PostgREST schema cache refreshed. New status returns potential daily availability without creating a credit account/grant.
- Campaign `cfc56a2b-8fbd-4c2a-a200-e55b509ad972` activated23:27KST:160reviewed humanities exam scopes,1/day,2026-11-01 start,2026-11-10 inclusive end (=2026-11-11 00:00KST exclusive). No Registry/Worker/math changes. Existing beta notice updated via admin RPC to remove activation-pending prefix; published2notices preserved.
- Production Chrome: modal policy/start inactive guard PASS; after activation start → daily1 visible PASS; checkbox/start/reload → dialog hidden while daily1 remains PASS. Before/after counts: daily_grants0,credit_grants24,credit_transactions113. No Credit grant/debit or new evaluation executed during these checks.
- Production student artifact rollout preserves all other pages, existing21Functions routes, environment/config and non-LAB asset hashes. Initial deployment `af2d26e7-9597-48c9-9e09-acdaeeebcad2`/4685559; auth-refresh correction `98416354-42b9-471c-a896-855d19880860`/c6a3dcd. Cloudflare native FormData returned500 without changing canonical; official Wrangler undici serialization succeeded. Final responsive-dialog deployment `2e88fc75-7ee4-4c10-b3c2-2752f86ce1d6`, source `f14e8ac4428b213dc242d979fbc92d37d840af4b`; Production canonical/viewport verification recorded at handoff.
- Automatic validation: Flutter Analyze0issues; Flutter1311PASS/7SKIP/0FAIL. WEB TypeScript/buildPASS, lint0errors/5existingwarnings, full1527PASS/4SKIP/0FAIL; focused onboarding13PASS after dialog layout adjustment. Isolated PostgreSQL read-only status, unissued allowance, midnight/cutoff and ledger invariance PASS. Prior33groups/concurrency checks remain valid for unchanged allocation functions; not claimed as freshly rerun.
- Production diagnostics retain pre-existing security-advisor findings; no blanket security-PASS assertion. New self-scoped SECURITY DEFINER RPC is intentional and ACL-tested; broad existing advisor cleanup is outside release scope. [Supabase linter reference](https://supabase.com/docs/guides/database/database-linter).
- Rollback: disable only this campaign before restoring pre-addendum Pages deployment `9c505258-4a49-468a-83ae-2326173fb870`; preserve existing grants/runs/history and never restore the full DB over subsequent user activity. Read-only status RPC may remain installed. Private baseline/artifact/settings backups under `.codex/legendstudy-backups/task14b-onboarding*`; original full PG backup above remains preserved.
- NOT_TESTED: new36device delta, Android physical scenarios, actual Provider-backed beta submit/rewrite, full social-login/signup/deletion/sync matrix. Prior Owner34PASS remains scoped to reported existing flows. No actual Provider/payment invocation by this task.

Final WEB check: Production canonical2e88fc75 verified successful; sourcef14e8ac. Existing non-LAB manifest hashes and Production settings exactly preserved. PC and390x844browser viewport dialog rendered; mobile dialog358px wide,16px inset,459px height, no content overflow. Guest start navigated to existing `/login/?next=%2Fessay-lab%2F`. Authenticated hide/reload retained daily1 and did not claim. These are browser checks, not iOS/Android device PASS. Proof `/tmp/task14b-beta-final-desktop.png`, `/tmp/task14b-beta-final-mobile.png`, `/tmp/task14b-beta-live-quota.png`. Build36IPA/AAB preserved privately under `development/legendstudy-private-backups/task14b-20261101/build36/`.


## Owner device feedback build37 — 2026-11-02

Owner36device feedback: profile/aspiration split and home notice N PASS; MY after relogin retained Settings, notice row placement, Credit timestamps and beta copy required fixes. Prior34reported PASS remains scoped; it does not establish all OAuth/signup/deletion/Android scenarios.

APP source **2298eaceea5c15340cb1dc80eb1a8778b5f6962b**, branchcodex/beta-store-release-task14. MY tab always returns its root; notice megaphone moved immediately before Settings; usage/grants show KST date+HH:mm, expiry policy unchanged. Beta title/buttons/copy now match Owner request and end inclusiveNov10 23:59 (=exclusiveNov11 00:00KST). Daily quota and existing signup/purchased credit policies untouched. WEB copy deployed with admin follow-up119ffdb7/source91216e8; root/account notice links included.

Modified APP files: lib/app/navigation_shell.dart; lib/features/profile/presentation/profile_page.dart; lib/features/credits/{credit_history,essay_beta_credit}.dart; tests credit_history,essay_beta_credit,day5_shell and newmy_tab_reset. Existing MY stack test changed to explicit Owner root-navigation requirement; actual router regression added.

Automatic: Flutter Analyze0issues; full1312PASS/7SKIP/0FAIL. WEB1529PASS/4SKIP, TS/buildPASS, lint0errors/5existingwarnings. Existing DB policy/allocation functions unchanged; no new DB/Provider/payment/Credit action this follow-up. Production Chrome quota shows daily1 with new KST/end text; balance is read-only. IAB anonymous LAB availability requests failed while Chrome operational; anonymous LAB runtime is not marked PASS from that browser.

Builds: signed iOS1.0.1(37)/Android1.0.1 versionCode37, com.legendstudy.app, existing Observation V1 Production config/signing retained. iOS codesign deep/strictPASS. Artifacts:
- build/ios/ipa/legendstudy_app.ipa SHA256498dedb98b7c82083a2e38cfb3583792d618dae6e8a6b8b6a43430a867198377
- build/app/outputs/bundle/release/app-release.aab SHA256b78c5013d520921b473a3d8caec1809f1a137db358fe5bd6adee9cafb20a603f
- Private copies development/legendstudy-private-backups/task14b-20261101/build37;34–36preserved. Logs/tmp/task14b-build37-{ios,android}.log and owner-analyze/test-final logs.

Android37 upload accepted; existing internal track release5 published2026-11-02 00:16KST, console explicitly “내부 테스터에게 제공됨”. Version37/min24/target36; supported devices unchanged. Native macOS file picker resolved extension file-URL limitation without changing browser security settings. Existing tester eligibility unchanged; opt-in https://play.google.com/apps/internaltest/4701319249543191162 . This is INTERNAL TEST availability, not Production review submission.

iOS37 uploaded at2026-11-02 00:17KST and processing completed. ASC build709cad3b-dd2d-49a5-a73b-041bf8c67fd7 linked to existing Owner Internal QA(1tester); delta test notes saved and group(1) verified. Owner37delta was confirmed PASS (2026-11-02: “확인 완료. 이상 없음”) for logout/relogin→MY root, notice megaphone, Credit date+HH:mm, beta wording/buttons/quota. Android device validation remains NOT_TESTED. Production review submission not executed until release gates satisfied.

Owner delta checklist: logout/relogin→MY root; notice icon beforegear; Credit grant/usage HH:mm; beta new title/buttons and daily allowance remains after hide; notice2records; WEB notice link. No new evaluation or purchase requested. Full Android/login/account-deletion/sync matrix remains pending, not silently passed. UI rollback requires next signed build using preserved source, not overwriting ledger or reusing an uploaded build number.


## TASK14-C MY profile and LAB availability — 2026-11-02

Owner attachment TASK14-C is the active P0 delta after build37. Build37 acceptance remains valid for its four requested cases; it is not acceptance of later code or Android. See [feature/preservation review](my-college-management-20261026.md#task14-c-native-profile-and-interests--2026-11-02).

- Reuse Native routes `/my/school` and `/my/aspirations`: profile draft-only school/status/grade; independent interests, existing rows before search, per-university department/priority edit and confirmed removal. Nickname/photo remains separately identified.
- Existing `public-service-status` response now provides APP per-university available-exam counts. `베타 첨삭 가능`/`첨삭 준비 중`, start CTA, disabled preparing cards, ready-first ordering; refresh button and app-resume refresh. Unknown/loading/error remain distinct. No catalog-membership-only availability.
- Production read-only schema/RLS/trigger and preflight inspection: owner-scoped profiles/targets; existing target division/priority fields, unique target key; preflight validates active user, runtime policy, approved Provider binding and exact Package. Existing WEB also checks runtime enable/launch HOLD/public question scope. No SQL or Provider request applied.
- School restoration GAP: no school-history table/trigger found in inspected current profile contracts. No guessed restoration, no profile bulk update. Existing backup is not presumed to identify the correct historical school.
- WEB unchanged at `c492334a28657c1c7469d3249b7e1f4e46a58566`; existing target edits and public availability contract reused. Targeted WEB `my/data` + `public-service-status`: 25 PASS. No WEB deployment needed for this APP delta.

| TASK14-C case | Evidence/status |
|---|---|
| A/B interests route, no school search | router widget regression PASS |
| C high-school label | school widgets PASS |
| D search/cancel/empty results preserve school | draft widget + no-write assertions PASS |
| E/F interests add/edit/remove cannot touch profile; profile cannot touch targets | captured mock HTTP payloads and owner filters PASS; no live user mutation |
| G logout/relogin MY root | build37 Owner device PASS; router regression PASS |
| H/I available/preparing separation | widget + strict status parser PASS |
| J/K/L ready navigation, preparing disabled, error distinct | source catalog/public service/preparing regressions PASS |
| M APP/WEB same availability source | shared API code + 25 WEB contract tests PASS; new APP live sync/device delta NOT_TESTED |

Analyze: 0 issues. Full Flutter suite: 1,317 PASS / 7 SKIP / 0 FAIL (`/tmp/task14c-full-test-final.log`); WEB targeted 25 PASS. Build artifacts recorded below after completion. New code requires a new signed build; uploaded37 is preserved. No new Provider/credit/payment flow or production review has been executed in this delta. Rollback: revert this APP delta and issue a higher build number; never overwrite user rows or reuse uploaded versionCodes.


### TASK14-C build38 / store handoff — 2026-11-02

- Source for both platforms: `80d135a5bb3b2727867f3121a191555a901a1165`, pushed on `codex/beta-store-release-task14`. Existing Observation V1 Production config and identifiers/signing reused. No production DB/Worker/Credit/payment mutation in this delta.
- iOS **1.0.1(38) BUILD SUCCESS / UPLOAD SUCCESS**. Release archive and IPA export completed; deep/strict codesign verification PASS. App Store Connect processing completed, build `f743e450-eb18-4e19-9aec-7df41ab4bf09` displayed 제출 준비 완료. This is **not** App Store review submission. Existing Owner Internal QA assignment for38 remains NOT_COMPLETED.
- Android **1.0.1 / versionCode38 BUILD SUCCESS**. AAB signature verification PASS (existing self-signed/no-timestamp warnings). Existing internal release37 preserved; release6 draft prepared, **38 AAB NOT_UPLOADED**. Extension file chooser rejected file access; supported native fallback timed out repeatedly and browser attachment returned `Debugger unattached`. No internal rollout or Production review claimed.
- Private artifacts: `/Users/woojinchang/development/legendstudy-private-backups/task14b-20261101/build38/legendstudy_app.ipa` and `app-release.aab`. IPA SHA256 `071c82dc09dc6f6bd7d43c784d0562a65a41289337f88f00dc3e956389e25834`; AAB `d159137e1012eb3003a637e126207988e0110e874fe33edae64fa4909db6cb58`. Existing34–37 backups preserved. Smaller IPA export omits bundled symbols; archive dSYMs retained and Flutter asset inventory checked.
- Build logs `/tmp/task14c-build38-ios.log`, `/tmp/task14c-build38-android.log`. Earlier final Analyze/full Flutter/targeted WEB checks apply to this exact source; no subsequent executable code change.
- Play Console separately reports incomplete advertising-ID declaration. The merged38 manifest contains transitive `com.google.android.gms.permission.AD_ID` and `android.permission.ACCESS_ADSERVICES_AD_ID`, while existing source metadata disables ad-ID collection and Analytics is Noop without configuration. Declaration consistency is **BLOCKED / unresolved**, not a verified privacy failure or a completed declaration. Do not declare collection/noncollection solely from permission presence. Console also displayed a payment-account attention banner; its actual release impact is NOT_TESTED. No financial settings changed.
- Owner37 device PASS remains limited to MY after relogin, notice icon, Credit timestamps and beta copy/quota. **38 profile Save/cancel, department/priority, LAB counts/refresh and Android device matrix remain NOT_TESTED.** Do not reuse37 acceptance as38 acceptance.
- Next: restore browser control, assign38 to existing Owner Internal QA, resolve truthful Play privacy declaration and upload38 to existing internal track, obtain only new device-delta acceptance, then review submission if all gates pass. Existing tester permissions must not expand. Store review status: **BLOCKED**, not SUBMITTED. Rollback keeps existing37 internal build; code rollback requires a higher build number, never user-data restoration.


### TASK14-C refund navigation addenda — 2026-11-02

Owner directed removal of standalone refund entries in APP Settings and LAB WEB footer only. Existing payment/refund policy and URL remain authoritative; this narrows navigation, not consumer rights or ledger logic.

- APP source `75495ee5f443ea89b8e09e73d3ab87ec9a167569`: Settings order 개인정보처리방침 → 이용약관 → 앱 정보. Purchase screen previously lacked a direct policy link; now terms/refund links precede products using existing AppConfig URLs. `REFUND_URL` remains `https://lab.legendstudy.com/refund/`; actual Observation V1 config uses the default. No billing controller, transaction, Credit or refund logic edited. This source **is not in uploaded38**; integrate into next final release build. New binary/device acceptance NOT_TESTED.
- WEB source `843f3a8a4946382704727d1b9be2b0376b3f9aac`: remove only footer policyRoutes entry; `/refund/` stays indexable. Production **9b7a63ba-448b-498e-acf3-705f7b821040**, project `legendstudy-lab`, https://lab.legendstudy.com . Canonical deployment success and unchanged Production configuration verified. Initial auto-Preview6df49763 did not change canonical; explicit serialized upload subsequently deployed the approved Production artifact.
- Safe artifact overlay: 615 HTML/RSC files transformed;1170manifest entries retained,460 unique changed assets. Each downloaded baseline hash matched; source transformation removes only exact footer link/keyed RSC entry. Existing21Functions/compiled code, JS/CSS, headers, redirects, environment and all body content retained. Three legacy redirected HTML paths remain unchanged because their rendered destinations carry the updated footer. No home.legendstudy.com or legendstudy.com deployment.
- Actual `/terms/` has §7 payment, §8 cancellation/refund, §9 withdrawal/statutory rights and a body `/refund/` link. `/pricing/` and `/support/` retain detailed conditions and direct links. `/refund/` renders normally. All four Production page bodies compare exactly to predeployment. APP/WEB open the same policy URL; no duplicated policy rewrite or new legal interpretation. Existing legacy payment-availability copy remains unchanged by this navigation-only task.
- Checks: Flutter Analyze0issues; targeted settings/billing/mobile IA87PASS, then updated purchase-link assertions2PASS. WEB TypeScript/buildPASS; full1529PASS/4SKIP; lint0errors/5preexistingwarnings; deployment scripts lintPASS. Source diff checksPASS.
- Browser: actual Production footer removed independently from terms body; terms→refund click and pricing/support direct links verified. Desktop CSS viewport1309×818 and mobile355×767 (browser zoom affects requested1440/390 widths), no horizontal overflow. Evidence `/tmp/refund-footer-desktop.png`, `/tmp/refund-footer-mobile.png`. Browser verification is not Owner acceptance or physical-device PASS. **Owner footer review pending.**
- Private backup `/Users/woojinchang/.codex/legendstudy-backups/task14c-refund-navigation/` includes prior project/manifest, downloaded originals, exact patches, compiled Functions, plan and postchecks. Rollback: Pages restore prior Production `119ffdb7-f1c2-4669-b5fa-b66df37e9bed`; no DB restore. APP rollback by revert+new higher build, preserving38.
- Preservation review: no new event/time facts, raw history untouched, no UPDATE/storage change, same identity, no Learning/Decision/Outcome changes, no new data collection/access, no derived facts. Operational DB/Worker/Provider/Credit/payment unchanged.


## TASK14-F final candidate — 2026-11-02

Owner requests frozen 1.0.1(39) release from integrated TASK14-C including settings refund navigation. ASC UI latest38 and Play internal draft excludes prior37, has no uploaded bundle;39 selected. Preserve Owner37 four-case PASS; do not extend it to new39 or Android. Manifest removes transitive AD_ID/ACCESS_ADSERVICES_AD_ID permissions: existing Firebase collection and ad-ID collection remain disabled, no ad SDK/application ad identifier use. Existing signing/public production configuration passes store-release --check for both platforms. Flutter analyze no issues; full test **1317 PASS /7 SKIP /0 FAIL** (/tmp/task14f-analyze.log,/tmp/task14f-full-test.log). Build/artifact/upload/device and review gates pending. No production policy/database/Worker/Credit/payment/Provider changes. November strategy is recorded in [decisions](decisions.md): beta cutoff unchanged; type expansion must not delay submission, paid activation separately approved.


TASK14-F build checkpoint: source `a0aa6184fedc4b20c2bc6909af20eee8cf9aa231` pushed; signed iOS39 IPA and Android39 AAB built successfully with existing identifiers/signatures. IPA codesign deep/strict PASS; AAB jarsigner PASS. Merged Android39 manifest has neither AD_ID nor ACCESS_ADSERVICES_AD_ID; existing Play declaration is No (read-only UI confirmed). Artifact directory `/Users/woojinchang/development/legendstudy-private-backups/task14b-20261101/build39/` preserves prior artifacts. IPA SHA256 `e28c33bcdad0f72b57efa9e7ae3a6f9daad6296bd70c34d167cb9c3d75e7cc19`; AAB `aa118d8e20958556b05c1d665d7ae13bf774affe945c6873d1f91eefedbbfb8f`. Logs `/tmp/task14f-build39-ios.log`, `/tmp/task14f-build39-android.log`. Existing Kotlin/SPM/font warnings are not new fatal build failures.

Production read-only query confirms campaign cfc56a2b-8fbd-4c2a-a200-e55b509ad972 enabled, daily_limit1, starts_on2026-11-01/ends_on2026-11-10, daily-v2; status and claim RPC installed. Actual revision_deadline body retains least(completion+14days, funding-ledger beta cutoff). No grant/claim/submission invoked. Owner confirms Android physical testing is available; no Android device currently attached by adb. New39 physical acceptance remains pending.


### TASK14-F internal distribution checkpoint

- iOS39 upload/processing SUCCESS; ASC build `197c283c-6158-407a-99be-e59622a2e95c` shows 제출 준비 완료 and existing Owner Internal QA association. Existing37 group/tester permissions preserved. 1.0.1 review draft prepared with existing metadata/credentials, beta notes and manual release; build39 attached, saved and reload-persistence verified. No review submission executed.
- Android39 upload SUCCESS; existing internal track4701319249543191162 release6 explicitly **활성 / 최신 출시 버전39(1.0.1) / 내부 테스터에게 제공됨**. Signed bundle39 accepted; supported-device counts unchanged from37. Existing tester permissions preserved. Link: https://play.google.com/apps/internaltest/4701319249543191162 . Internal distribution is not Production review submission. Production18 unchanged.
- Native file picker resolved extension file-URL restriction without changing extension/security settings. No additional Owner setup needed for upload.
- Evidence screenshots `/tmp/task14f-play39-internal.png`, `/tmp/task14f-ios39-internal.png`. Play opt-in/install availability on a physical device is still Owner QA pending; console availability alone is not installation PASS.

| Release gate | Verified status |
|---|---|
| Flutter Analyze / full tests | PASS: 0 issues;1317 PASS,7 SKIP,0 FAIL |
| Signed iOS/Android39 same source | PASS: a0aa6184fedc4b20c2bc6909af20eee8cf9aa231 |
| Android advertising ID declaration consistency | PASS: actual signed AAB permissions absent; existing console No |
| Upload / existing internal distribution | PASS in both consoles; physical installation pending |
| Existing iOS34/37 Owner acceptance | Preserved only for previously confirmed cases |
| iOS39 settings/profile/interests/LAB delta | NOT_TESTED on device; Owner request sent |
| Android39 core device flows | NOT_TESTED; Owner confirms device available, internal link/checklist sent |
| Signup/delete/OAuth and full APP/WEB sync matrix | NOT_TESTED where no explicit device evidence; disposable-account-only deletion |
| Beta production policy | Read-only installed campaign/function verification; no claim/Provider run; server boundary tests covered by suite |
| Store production review | BLOCKED pending required physical acceptance, not SUBMITTED |

No production DB/Worker/Provider/Credit/payment policy changes. No purchase, credit grant/claim, or evaluation executed. New academic-type expansion remains separate from this release. Rollback keeps prior store production versions; internal testers may return to preserved prior TestFlight builds, and code rollback for uploaded Android requires a higher versionCode. No ledger or user-data restoration.


### Final APP UI patch and freeze — 2026-11-02

Owner final scope: remove only ready-university “베타 첨삭 가능”; retain official logo/name, available-exam count, start label and chevron. Pending/error/loading labels, card readiness/onTap, Registry/Package/service API and counts unchanged. Remove the ready-only Text node rather than leave an empty line; the existing title-to-content spacing remains. No storage/update/event/identity/access semantics changed.

Owner explicitly confirmed iOS39 requested delta checks, preserved without extending to unreported signup/delete/OAuth/sync. Android Owner downloaded1.0.0(18), so actual39 installation/device QA remains BLOCKED despite console internal39 availability. This new UI source is not contained in either uploaded39 binary. **A new signed iOS/Android build is required before submitting this change**; next number must be checked against stores (40 candidate, not reserved). No build/upload/submission performed in this narrow patch. Preserve39 artifacts/source a0aa618; subsequent APP UI changes frozen by Owner. Only release verification/build/submission and confirmed blocker fixes continue.

Validation: Flutter Analyze0 issues; card/service-state6 + catalog/navigation/Registry12 =18 PASS,0 FAIL. Wiki handoff PASS (current-status11829 bytes). Logs /tmp/task14-final-ui-{analyze,test,navigation}.log. No new physical-device acceptance claimed. Rollback is reverting this single display patch before a new build; no DB/credit/Provider rollback.


## TASK18 build configuration diagnosis — 2026-11-02

Scope: read-only artifact/config/source inspection; no login-code or Production Auth change. Owner's uncommitted Xcode project edits and `supabase/.temp/` preserved.

### Evidence

- Preserved39 IPA is 1.0.1(39), source a0aa618; local `build/ios/ipa/legendstudy_app.ipa` is 1.0.1(40).
- Exact configured SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, GOOGLE_SERVER_CLIENT_ID and GOOGLE_IOS_CLIENT_ID occur in39 App.framework binary and do not occur in40. Compared internally without logging values.
- Current Generated.xcconfig build40 DART_DEFINES contains only eight Flutter-generated metadata keys; all application connection/OAuth defines are absent.
- AppConfig defaults URL/key/client IDs to empty and OAuth flags to false. main skips Supabase initialization on invalid configuration; emailAuthServiceProvider is null; auth_page displays “현재 로그인할 수 없어요. 잠시 후 다시 시도해 주세요.” before attempting a network login.
- Both IPA bundle IDs, URL schemes, application/team entitlements and Apple sign-in entitlement match. GIDClientID/GIDServerClientID plist fields absent in both: this app obtains IDs from Dart defines, so their plist absence is not a new regression.
- Actual ASC review submission efd80130-07aa-4ea3-a1a4-11f7d5d06254: 1.0.1(40), build fa43dcf2-4cae-402f-b2b9-833488bc985d, rejected 2.1.0; Apple reports that same login error on iPhone17 Pro Max/iPad Air11(M3), iOS27.0.1. Read only; no reply/resubmission.
- Conclusion: missing build-time configuration is established for the local40 artifact and consistent with Apple's failure. Uploaded binary byte identity and independent40 TestFlight device reproduction NOT_TESTED; Owner asked to verify without uninstalling.
- Original40 command not recovered from shell history. Do not invent its exact invocation. Existing39 log path is no longer present; preserve historical command evidence separately from available artifact evidence.
- Existing config passes `python3 tool/store-release ios --config config/observation-v1-qa.local.json --check`.

### Existing39 command and41 recovery procedure

39 used `python3 tool/store-release ios --config config/observation-v1-qa.local.json --build-name=1.0.1 --build-number=39 --export-options-plist=/tmp/task14-export.plist`.

Use the same wrapper and config; preserved39 ExportOptions replaces the ephemeral /tmp file. Run from APP repository root after preserving40 IPA/archive and confirming41 is unused in ASC:

```sh
python3 tool/store-release ios --config config/observation-v1-qa.local.json --check
python3 tool/store-release ios --config config/observation-v1-qa.local.json --build-name=1.0.1 --build-number=41 --export-options-plist=/Users/woojinchang/development/legendstudy-private-backups/task14b-20261101/build39/ExportOptions.plist
```

Wrapper invokes Flutter `build ipa --release --dart-define-from-file=<temporary validated config>` and preserves the existing production/OAuth/Observation settings. Do not substitute a bare Flutter build or Xcode Archive with missing generated defines. No secrets in command arguments/output.

Before upload, verify41 Info.plist/version/signature and binary inclusion of the same four configured values using boolean-only comparisons. Then TestFlight login on fresh session and update path, including iPad, before resubmission. This investigation did not build/upload41 or alter Auth settings. Existing39 Owner PASS remains valid only for39.
