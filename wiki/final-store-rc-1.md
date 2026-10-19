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
