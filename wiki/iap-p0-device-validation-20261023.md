# Owner P0 — Payment / Credit / MY native validation (2026-10-23)

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
| Android device | Existing SM-G950N Play build1.0.0+18; installed Play signer differs from existing upload key. No uninstall/data clear attempted. Owner selected separate test device; it has not appeared in adb yet. |
| iPhone device | Owner clarified iPhone12ProMax “자유잍튜브”; install and launch PASS. Earlier iPhone17ProMax attempts failed locked and made no installation. |
| Physical UI acceptance | Owner replied 완료 to the UI checklist; exact balance number not supplied. New issue: USD prices2.99/6.99/9.99/19.99. No new purchase. |

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

**MERGE NOT EXECUTED. MERGE SHA: none.** Owner requires physical verification first.
Recheck target SHA before applying the patch. Source commit is not a merge commit;
pre-merge candidate checks are not post-merge regression claims.

## Expiry review — Production NOT_APPLIED

Latest Owner specifies exactly KST23:59:59 (prior draft fractional second removed).
Fresh read-only scope: Apple+1 and+3 → Jan22 2027 23:59:59KST; Google+1 → Jan23
2027 23:59:59KST. Existing quantities/transactions stay unchanged, no new grant.
[Owner SQL and procedure](../tool/iap_recovery/expiry/README.md) retains old terms
in restricted immutable audit, verifies runtime/inventory, restores grant guard,
and keeps old/new receipt replay compatible. Isolated Postgres contract rerun PASS
for the exact-second version. It does not mean Production apply. No DB mutation.

## Remaining acceptance

1. Connect separate Android device with USB debugging/trust; install signed APK.
2. Finish iPhone and Android UI/unchanged-session/balance and existing content checks.
3. Verify final target candidate native builds/device paths, then scoped merge only.
4. Re-run analyze/build/regression on merged tree, push and compare remote SHA.
5. Record final results in Unified Wiki; app distribution still needs Owner confirmation.

## iPhone USD price follow-up

Owner accepts requested UI checks but reports USD product prices. Code inspection:
ProductDetails.price from StoreKit is authoritative and unchanged; no hardcoded
USD or currency conversion introduced. Installed app provisioning confirms
development signing (get-task-allow=true), no local StoreKit configuration file.
This is not the App Store-distributed binary even though Supabase is Production.
Actual sandbox account/storefront is not yet known; Owner asked to inspect existing
settings without changing account/country or buying. Do not force KRW strings over
Apple's returned price. Price-region acceptance remains open.

Apple documents [displayPrice](https://developer.apple.com/documentation/storekit/product/displayprice)
as storefront-localized and [development sandbox testing](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox)
as distinct from production distribution. Development signing is confirmed; the
precise reason this device received USD remains unverified until storefront check.
