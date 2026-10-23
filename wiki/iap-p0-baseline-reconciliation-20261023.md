# IAP P0 corrected APP baseline — pre-build report (2026-10-23)

## Canonical lineage and verification limits

Use `codex/material-service-app-20261022` at
`c2f00540a5f18d17c6d03d2760bbce3f203aadaa` as the complete current APP snapshot.
Local service HEAD and remote match. Payment branch fork point is18ca6d5;
its existing source is newer than the wrongly installed Claude baseline but lacks
b1d5b1c source-catalog/PDF/rewrite changes. Do not use either the obsolete4035592
candidate or the payment branch alone as the full replacement APP.

Ancestry verified: integrated RC baaf2bc, startup/material fix2e32195 and approved
native PDF96830e2 all occur in c2f0054. Historical [iPhone latest exam/PDF Owner
acceptance](native-material-pdf-20261022.md) was for96830e2. Subsequent material/
Math navigation has Simulator/tests and scoped operating E2E evidence; latest
b1d5b1c/c2f0054 preserve their own documented partial quality/activation gates.
There is no evidence that the entire c2f0054 tree passed both physical platforms.
It is the latest complete integrated baseline preserving verified features, not
an invented all-features physical PASS.

## Exact candidate

[Patch](../tool/iap_recovery/p0_latest_app_credit_only.patch) and
[manifest](../tool/iap_recovery/p0_latest_app_credit_only_manifest.json).
Candidate Git tree: `a33cbb9f869bf67c9a4071335b7b4c44597429a1`.
Archive location: ignored `build/device-validation/latest-app-credit-candidate`.
No checkout or files in another worktree were changed.

Only11 files differ: router MY-credit route; billing balance/history invalidation;
top-up history Back; purchase date/expiry display; balance/MY buttons; all-credit
history; previously requested LAB copy; three directly related tests. No payment
verification engine replacement. Existing purchase gating and receipt verification
are byte-identical to baseline, as are all other1,350 tracked files.

Preserved exactly: entire lib/features/essay (including latest source_catalog and
source_catalog_page); PDF/history/Math, account/startup, theme, onboarding, content
repositories, Supabase/config/main, native Android/iOS, dependencies/lockfiles,
assets, backend SQL/Edge/worker/tools and existing tests outside the three listed.
This is source equality against the selected baseline, not new runtime DB proof.
No private local signing/config files copied into this candidate yet. Future build
must reuse verified Production public defines and existing signing explicitly.

## Gates and next steps

BUILD NOT_RUN; DEVICE INSTALL NOT_RUN; TARGET MERGE/PUSH NOT_RUN.
Only pre-build scope/content checks performed. No tests/analyze run for this new
candidate; prior discarded-candidate PASS cannot be transferred to this tree.
No DB, Edge, Provider, purchase, Credit grant or expiry change. Exact23:59:59
expiry SQL remains separately prepared and unapplied.

After this baseline report, build/test this exact tree with existing SDK/config,
verify latest materials/PDF/startup/theme and Credit together, then integrate only
against the rechecked latest baseline. Do not push a broad restoration into an old
Claude branch or overwrite concurrent service changes. The old4035592 commit is
retained as an audit trail and remains release HOLD.

## Owner-requested Android build — 2026-10-23

Android release APK PASS (89.5MB), Flutter3.47.7/Dart3.13.5. Existing production
public defines and upload signing reused; com.legendstudy.app1.0.0+18 verified,
APK signature verification PASS for device API28. No dependency upgrade.
Source/PDF/History/account/Credit tests29 PASS. Analyze reports one pre-existing
info in test/math_canonical_selection_test.dart (relative lib import); no compiler
errors or warnings from analyze, but strict analyze exit1 is NOT called PASS.
Kept that Essay test unchanged. Build warnings: existing Gradle/Kotlin/SDK/font.
All1,361 tracked candidate files still match candidate tree after build, including
lockfile, Essay/backend and native settings. APK hash is recorded in the manifest.
Artifact: build/device-validation/latest-app-credit-candidate/build/app/outputs/
flutter-apk/app-release.apk. Not the old merge-candidate APK.
Device installation, iOS build, target integration and Store submission NOT_RUN.
Earlier pre-build status is historical; this section supersedes Android build only.

## Owner Android confirmation

Owner manually installed the corrected latest-app-credit-candidate APK using the
provided adb install -r command and replied “확인 완료.” Record as Owner confirmation
of the corrected Android build. No itemized new UI/PDF/balance values were supplied;
do not invent automated physical checks or extend this to iOS/final merge. Previous
obsolete4035592 acceptance remains withdrawn. iOS and target integration pending.
