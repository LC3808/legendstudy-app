# TASK18-B isolated PDF QA

Entrypoint: `tool/qa/pdf_download_main.dart`. Synthetic one-page PDF only.
Reuses production download widget/service, native save channel and PDF Viewer.
No Supabase/Firebase initialization. Authorization and bytes are fixture overrides;
network-error switch is simulated, not a real network outage. Analytics is Noop.
OFFICIAL_LINK opens a public site only when explicitly tapped.

Use a separate bundle `com.legendstudy.app.task18qa` and display name `LS PDF TEST`.
Never install this entrypoint under `com.legendstudy.app` or existing Math TEST ID.
Use an external QA Info.plist/empty entitlements/xcconfig through
`XCODE_XCCONFIG_FILE`; do not change the production Xcode project. Verify the
built Info.plist and signature before device installation. This is not a release
artifact or production server/GA4 verification.

2026-11-04: iOS Release 1.0.0(1) installed/launched on test iPhone12ProMax.
Local build/ios/iphoneos/Runner.app is this QA artifact, not APP58. APP58's
separate private release58 artifacts remain untouched. Rebuild using the normal
entrypoint and approved configuration for any future release.

Manual matrix and results: wiki/task18b-pdf-validation-release-20261104.md.
