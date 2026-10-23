# Payment / Credit / MY P0 integration — 2026-10-23

Owner confirmed both Galaxy S8 and iPhone 12 Pro Max final candidate checks normal.
Both were installed with existing signing, com.legendstudy.app and Production
public configuration. Android replacement was explicitly authorized after the Play
signer mismatch; first uninstall found the package already absent. Fresh source
installation, then final candidate update succeeded. iPhone candidate installation
succeeded; automated launch met a locked device, then Owner confirmed both devices.
No additional purchase or Store submission.

## Verified scope

Top-up nearest-expiry text removed; MY credit history/top-up buttons; KST date-only
history; purchase-history first Back returns to top-up; settled purchases refresh
both histories and balance; approved LAB self-revision copy. Existing refund,
onboarding, billing verification, backend and signing preserved. Eleven UI/test
files integrated selectively from the payment branch, not a whole-branch merge.
Router/profile/provider overlap resolved by retaining target behavior and adding
only these UI changes. No unresolved conflicts.

## Validation

Flutter 3.47.7 / Dart 3.13.5. Candidate analyze PASS; 40 focused credit/history/auth/
LAB tests PASS. Android release APK 86,975,188 bytes and iOS release 34.7MB PASS.
All 1,106 tracked candidate files matched the isolated integration index before
documentation additions. Owner confirmed login, MY/balance/buttons, history/back,
LAB/PDF/Essay History on both final candidate devices. Exact balance number was not
recorded independently. Earlier source tests: Credit26 and regression49 PASS.

## Remaining release boundary

Purchased-credit expiry policy: purchase date +3 calendar months, KST23:59:59.
Three existing purchase grants (Apple1/3, Google1) extension SQL is prepared and
isolated-tested, Production NOT_APPLIED. No credit quantity/history mutation here.
Production SQL needs fresh target review before Owner application; isolated PASS
is not deployment. Actual Store distribution still requires Owner confirmation.
