# Owner P0 — Payment / Credit / MY native validation (2026-10-23)

**REOPENED:** Owner reports final Android startup deletion-form redirect and orange
buttons. Previous final-device acceptance did not establish these regressions absent.
Target4035592 retains pre-existing old lifecycle/theme despite newer fixes in the
payment source branch. Scoped integration omitted those fixes. Restore existing
2e32195 startup behavior and approved Oct10 navy/neutral CTA theme; no backend change.
Partial correction analyze +17 tests PASS, but Owner subsequently reports broader obsolete UI/material/DB integration. Partial candidate NOT_INSTALLED and NOT_PUBLISHED; full baseline reconciliation required.

Latest Owner returns work to `legendstudy-iap-fix`, branch
`codex/iap-credit-production-recovery-20261023`. Initial dirty PHASE1 Wiki notes
were preserved in e9722bd. UI from c603059/32eb5b7 was brought forward explicitly;
no payment-engine redevelopment or changes in another worktree. Target confirmed
by Owner: `claude/app-release-readiness-eab636`.

## Toolchain and source verification

Flutter3.47.7 stable / Dart3.13.5 at `$HOME/fvm/versions/stable`; pubspec requires
Dart^3.13.3 and Flutter>=3.47.3. Existing pubspec.lock unchanged. SDK invoked
explicitly / command-local PATH; old Dart3.8 and global settings unchanged.
Doctor: Xcode27.1/CocoaPods1.17, AndroidSDK37, devices available; Android license
warning remains but installed required build tooling completes builds. Gradle/AGP/
Kotlin deprecation warnings retained without unsolicited upgrades.

Source analyze PASS after braces correction in Credit history and a package-import
lint correction in the existing math selection test (no Math implementation change).
Payment/Credit tests26 PASS; auth/session/MY/LAB/PDF/Essay-history regression49 PASS.
These automated tests are distinct from physical-device acceptance.

Android release initially failed because dev-only integration_test remained in
the generated registrant when using --no-pub. Retrying without --no-pub regenerated
the release registrant and passed; no hand-edited generated file or dependency
change. Run native builds sequentially after tests.

## Build and device evidence

| Item | Verified state |
|---|---|
| Android source APK | PASS; com.legendstudy.app,1.0.0+18,89,477,950 bytes |
| Android APK SHA256 | 89796069c07c8cd316f33a4be0ab3e3460aba666e23534b236e455f3a860dfb2 |
| iOS source release | PASS; com.legendstudy.app, existing team/signing,36.3MB |
| Android device | SM-G950N: Owner explicitly authorized removal/reinstall after signer mismatch. Uninstall found package already absent; fresh source installation and final candidate update succeeded. Owner confirmed final candidate normal. |
| iPhone device | Owner clarified iPhone12ProMax “자유잍튜브”; install and launch PASS. Earlier iPhone17ProMax attempts failed locked and made no installation. |
| Physical UI acceptance | Owner replied 완료 to the UI checklist; exact balance number not supplied. Owner subsequently confirmed prices returned to KRW. No new purchase; transient USD cause unproven. |

Existing signing references and production public config reused in ignored local
files only. No new key/account/certificate. Public config targets LegendStudy
stlhijzpjfgwwdgunlsd; package/bundle unchanged. No Store upload/submission.

## Exact UI scope and merge preparation

- Remove nearest-expiry text from top-up summary.
- MY balance has 크레딧 내역 / 충전하기 actions.
- MY all-credit history reuses existing owner-RLS ledger, bounded50; KST dates only.
- Purchase-only history now also shows expiry date only; NULL no-expiry retained.
- Settled purchase invalidates both histories and canonical balance.
- Purchase-history first back → top-up; subsequent back → prior page.
- LAB copy uses Owner's university-criteria/self-revision sentence.

No new storage design; the [payment preservation review](payment-app-foundation.md)
applies: immutable transaction facts, shared account identity, derived summary,
financial/learning separation, owner-only access. Dates display current server
terms; UI does not pretend the new expiry policy is already deployed.

Target snapshot c3ac6ec2b156a5aa1f5ae5bb0c072bedb03b0fe8 contains distinct refund,
onboarding and brand work. Whole-file overwrite of router/profile would introduce
unrelated source-branch device-intro, aspirations and LAB label differences.
Prepared [scoped patch](../tool/iap_recovery/p0_scoped_app_merge.patch) preserves
those target choices, changes only11 UI/test files, and passes git apply check on
an isolated target index. Candidate archive is under this worktree's ignored
build/device-validation/merge-candidate; other worktrees/target refs untouched.
Candidate analyze PASS, focused UI6 and auth/LAB regression34 PASS. Candidate Android release PASS.
Candidate iOS release PASS (34.7MB). Both candidate builds retain existing signing.

Scoped integration commit published: `40355925c8cb7cc4787c6393681568e8457f0949`, parent target c3ac6ec2. Eleven UI/test files plus four Wiki files, preserving target refund/onboarding/backend. Both final candidate devices accepted by Owner. Publication and post-integration checks recorded below; other worktrees remain untouched.

## Expiry review — Production NOT_APPLIED

Latest Owner specifies exactly KST23:59:59 (prior draft fractional second removed).
Fresh read-only scope: Apple+1 and+3 → Jan22 2027 23:59:59KST; Google+1 → Jan23
2027 23:59:59KST. Existing quantities/transactions stay unchanged, no new grant.
[Owner SQL and procedure](../tool/iap_recovery/expiry/README.md) retains old terms
in restricted immutable audit, verifies runtime/inventory, restores grant guard,
and keeps old/new receipt replay compatible. Isolated Postgres contract rerun PASS
for the exact-second version. It does not mean Production apply. No DB mutation.

## Final device acceptance and remaining release gates

Owner first confirmed source Android, then explicitly confirmed both final
APP-target candidate devices normal. Final candidate APK update PASS; iPhone
candidate install PASS (automated launch encountered lock; subsequent Owner
acceptance supersedes the launch-only limitation). Login, MY/balance/buttons,
history/back, LAB/PDF/Essay History accepted; exact numerical balance not recorded.
No new purchase. All 1,106 tracked candidate files matched the integration index
before Wiki-only additions. Analyze and 40 focused regression tests PASS.

Remaining: Production expiry SQL is NOT_APPLIED; no Store submission/distribution.

## iPhone USD price follow-up

Owner accepts requested UI checks but reports USD product prices. Code inspection:
ProductDetails.price from StoreKit is authoritative and unchanged; no hardcoded
USD or currency conversion introduced. Installed app provisioning confirms
development signing (get-task-allow=true), no local StoreKit configuration file.
This is not the App Store-distributed binary even though Supabase is Production.
Actual sandbox account/storefront is not yet known; Owner asked to inspect existing
settings without changing account/country or buying. Do not force KRW strings over
Apple's returned price. Owner subsequently confirmed the display returned to KRW without a code/account change; current price display accepted.

Apple documents [displayPrice](https://developer.apple.com/documentation/storekit/product/displayprice)
as storefront-localized and [development sandbox testing](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox)
as distinct from production distribution. Development signing is confirmed; the
precise reason for the transient USD response remains unverified.

## Android rebuild requested by Owner

Android release rebuild PASS with Flutter3.47.7/Dart3.13.5, existing signing,
Production public config, com.legendstudy.app1.0.0+18. APK SHA256: `89796069c07c8cd316f33a4be0ab3e3460aba666e23534b236e455f3a860dfb2`.
Historical rebuild checkpoint preceded device replacement. Owner subsequently authorized the existing SM-G950N reinstall; installation and final two-device acceptance completed as recorded above.

## Final publication and post-integration verification

APP target `claude/app-release-readiness-eab636` fast-forward push PASS; remote SHA
`40355925c8cb7cc4787c6393681568e8457f0949` exactly matches scoped integration.
Single-parent selective integration, not a whole payment-branch merge. Code11 +
Wiki4 files; no backend/config/dependency changes. Other worktrees and their local
checked-out branch refs were left untouched; their next update must fast-forward
from origin normally, preserving any local work.

Post-integration tree: analyze PASS, Android release PASS (87.0MB), iOS release PASS
(34.7MB), focused regression40 PASS. Candidate tracked-content equality verified;
build output and local public configuration remain ignored. Android candidate APK
SHA256 `3a70bebb349c4d5f21ceb640ff4dc15055bacc75f0b29c3658fac9b445d8a666`.
Both physical devices Owner PASS. Wiki handoff/link checks PASS. Production expiry
SQL remains NOT_APPLIED; no Store submission.

## Baseline regression confirmed — supersedes final acceptance

Owner reports obsolete UI/UX and missing material/DB-connected screens. Actual
installed last update16:57:35 is the APP-target candidate1.0.0+18. Target base
c3ac6ec is a divergent Oct18 Claude UI branch, not the later integrated APP base.
4035592 selectively added payment UI onto that old base. It omits current source
changes across60 lib files, including source_catalog/page, question_pdf,
evaluation_report/view, math_workspace, shared_history and newer profile/startup.
Both local build define files point to the correct Production project; this does
not establish runtime reads and must not be described as DB disconnect proven.

Existing Oct18 canonical integration explicitly based on f62b1ee and selected
Claude changes, rejecting whole-file replacements of Codex draft/history/Essay.
Current material-service remote c2f00540a5f18d17c6d03d2760bbce3f203aadaa preserves
Oct22 latest-exam/PDF Owner acceptance; current payment source already includes
much of that newer APP lineage but has differences from current service branch.
Next: reconcile complete approved APP baseline and preserve existing payment UI,
without overwriting the concurrent service worktree or altering Production.
No partial-fix installation, additional merge, DB change or account deletion.
4035592 is NOT release-ready; original device PASS claim withdrawn for full APP.

## Corrected pre-build baseline

[Baseline reconciliation](iap-p0-baseline-reconciliation-20261023.md): c2f0054 plus payment-only11 files; other1,350 tracked files identical. Build/install/merge not run. Latest physical verification limits are explicitly preserved.
