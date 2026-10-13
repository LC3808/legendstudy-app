# Release blocker — pdfium_dart native-asset download fails Android/iOS release build (2026-10-13)

Recorded during STEP 3. This is a **release blocker** for producing a full
APK/AAB/IPA in the current environment. It is **unrelated to the STEP 3 splash
change** (splash resources are validated independently; see below). The
**PDF viewer is Codex-owned — do not modify its code** to work around this.

## Symptom
`flutter build apk --debug` fails at Gradle task `:app:compileFlutterBuildDebug`
(the Flutter/Dart build step, which runs native-asset build hooks), not at Android
resource linking.

## Root cause
The `pdfium_dart` (0.3.1) build hook downloads a platform binary from GitHub release
assets and the connection is reset in this sandbox:

```
PDFium download failed (ClientException with SocketException: Connection reset by peer
(OS Error: Connection reset by peer, errno = 54), address = release-assets.githubusercontent.com,
uri=https://github.com/bblanchon/pdfium-binaries/releases/download/chromium%2F7811/pdfium-android-arm.tgz); retrying...
Unhandled exception:
ClientException with SocketException: Connection reset by peer ...
  at pdfium_dart-0.3.1/hook/build.dart:53 (_downloadPdfium)
Target build_hooks failed: Error: Building native assets failed.
```

## Reproduction
1. `fvm flutter build apk --debug` (or any full native build) in this worktree.
2. Build reaches `:app:compileFlutterBuildDebug`, retries the pdfium download 3×, then fails.
3. Requires outbound network to `release-assets.githubusercontent.com` / `github.com`,
   which is blocked/reset here.

## Scope / isolation
- STEP 3 splash resources were validated **without** a full build: Android
  `xmllint` + `aapt2` (37.0.0) compile OK for all changed resources; iOS `xmllint` +
  `ibtool` compile OK. So the splash change is verified at the resource level.
- Full on-device install and the signed release build remain **unverified** because of
  this blocker (and, separately, the absent signing keystore — see store-release wiki).

## Remediation options (Owner / Codex decision — not performed)
- Build in a network-enabled environment (or allowlist `github.com` release assets) so the
  hook can fetch `pdfium-*.tgz`; or
- Pre-seed/caches the pdfium binaries for offline builds; or
- Codex (PDF viewer owner) pins/vendors the binary or configures an offline source.

Owner-direct device/release-build verification is required once the network path (and
signing) are available. Claude did not modify the Codex-owned PDF viewer.
