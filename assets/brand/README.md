# Official LegendStudy+ brand assets


## FULL-ORANGE launcher icon + simple splash — Owner approved 2026-10-08 (CURRENT)

Supersedes the 2026-09-29 75% white-canvas icon (kept below + in git history, commit `9af9667`).

- **Design:** launcher icon = **brand-orange background + white notebook/pencil symbol**.
  No white outer canvas, no border, no text, no wordmark.
- **Orange = `#FFA300`** — the app's canonical brand token `AppTokens.primary` /
  `AppTokens.brand` (`lib/core/theme/app_theme.dart = 0xFFFFA300`). The Owner source
  symbol itself is `#ffa200`; the LAB/web brand oranges (`#ffac14`, `#ffa400`) are
  nearby but the **APP canonical token wins for the APP icon**.
- **Source unchanged:** `assets/brand/source/legendstudy_app_iocon_1024.png`
  (SHA pinned; the script asserts the hash and never alters it). The symbol is NOT
  redrawn — `tool/export_launcher_icons.py` derives a per-pixel symbol-coverage map
  from the source blue channel (preserving its anti-aliasing) and does a faithful
  figure/ground colour-swap: `launcher = t·white + (1−t)·orange`.
- **Optical size:** iOS AppIcon + Android legacy mipmaps at **78%** (squircle-safe);
  Android **adaptive** foreground = white symbol on transparent, farthest point at
  **~31.5dp** (inside the guaranteed 33dp / 66dp-diameter safe circle); adaptive
  **background = `@color/ic_launcher_background` = `#FFFFA300`** (`values/colors.xml`).
  iOS icons stay **RGB, no alpha** (App Store requirement).
- **Splash (unchanged intent, simplified):** white/warm-white background + centred
  **orange** symbol. The launcher `ic_launcher` is now orange-bg, so the Android splash
  drawables (`drawable[-v21]/launch_background.xml`) and Android-12 themes
  (`values-v31` + `values-night-v31` `windowSplashScreenAnimatedIcon`) reference the new
  **`@drawable/ic_brand_symbol`** (orange symbol on transparent). iOS `LaunchImage`
  (orange symbol) unchanged. Dark mode keeps the white splash.
- **Flutter cold-start frame** (`lib/features/brand/brand_frame.dart`): centred orange
  symbol + the minimal `레전드스터디⁺` wordmark only — **the long tagline was removed**
  (Owner: simple splash). Cold-start-only, ≤~1.5s, no version/loading/features/ads.
- **Regenerate:** `…/python tool/export_launcher_icons.py` to check, `--write` to export.
  Verified `flutter analyze` clean, 967 tests pass, unsigned Android AAB + iOS (no-codesign)
  release builds PASS, iOS Simulator icon/splash/transition QA PASS.

---

## Launcher 75% scale + cold-start splash — Owner approved 2026-09-29 (SUPERSEDED 2026-10-08)

- **Source asset:** `assets/brand/source/legendstudy_app_iocon_1024.png` unchanged
  (SHA pinned; the script asserts the source hash and never alters it).
- **Export rule (75%):** `tool/export_launcher_icons.py` (`SCALE = 0.75`)
  composites the source at 75% onto a white 1024 canvas before every export, so
  the rotated document keeps clear margin off the iOS squircle / Android circle
  masks. No recolor, redraw, crop or new symbol. Run
  `…/python -B tool/export_launcher_icons.py` to check, `--write` to re-export.
  Outputs: iOS AppIcon (15 sizes + 1024, padded), Android legacy mipmaps and the
  adaptive foreground (symbol at 45dp on the 108dp canvas; safe radius 23.89dp <
  33dp), plus the transparent runtime symbol
  `assets/brand/generated/legendstudy_symbol.png` and the iOS `LaunchImage`
  (180/360/540). The App-Store 1024 is now the padded composite (no longer pixel-
  equal to the raw source — an intended, approved change).
- **Splash rule:** native launch stays minimal — **warm-white/white background +
  centred orange symbol only** (iOS `LaunchScreen.storyboard` centres the symbol
  `LaunchImage`; Android pre-12 `launch_background.xml` centres `@mipmap/
  ic_launcher`; Android 12+ `values-v31`/`values-night-v31` set
  `windowSplashScreenBackground` white + `windowSplashScreenAnimatedIcon`).
  Product name and tagline are **not** in the native splash — they are drawn by
  the Flutter cold-start brand frame (`lib/features/brand/brand_frame.dart`):
  symbol + `레전드스터디⁺` (superscript +, single near-black `#12161F`) + tagline
  **"나의 학습 기록이 쌓일수록, 나의 가능성은 선명해집니다."**. The frame is
  cold-start only, runs in parallel with init (visible up to ~1.5s from process
  start, no extra delay if init already exceeded it, no re-show on resume), and
  is aligned to the native symbol to avoid size-jump / double-splash / white
  flash. See [app-icon-splash-v1.md](../../wiki/app-icon-splash-v1.md).
- Display name, package `com.legendstudy.app`, version/build, deep links and
  OAuth remain unchanged.


## Canonical launcher source — Owner supplied 2026-09-20

`assets/brand/source/legendstudy_app_iocon_1024.png` is the sole approved launcher
source (Owner filename, including `iocon`, preserved). PNG decoding/CRC PASS,
1024×1024 RGBA; alpha is 255 everywhere; no embedded ICC/gamma profile.
SHA-256: `7f37ed2c16a43f739cfcb618190bacedaaacdb7877dcf000578f8b6611e25a68`.
Source bytes are untouched. No crop, rotation, recoloring, rearrangement, added
text/+ symbol, shadows or AI regeneration. No color transform is applied.

`tool/export_launcher_icons.py` checks source hash, every output pixel/size/mode,
Contents.json references and adaptive safe-circle containment. Requires Pillow
in a tooling environment only; no Flutter/native dependency added. Run with
`python3 -B tool/export_launcher_icons.py` to check, append `--write` to re-export.

- Android legacy mipmaps: 48/72/96/144/192px direct proportional exports.
- Android API26+ adaptive: 108dp layer exported at xxxhdpi (432px), unchanged
  whole source fitted centrally to 60dp (240px), 24dp (96px) canvas padding per
  side; white background. This platform padding prevents diagonal document
  corners from being masked. No cutout/repositioning of the pencil or document.
  Saturated orange mark radius is 31.96dp, inside the guaranteed 33dp circle;
  circle and squircle previews preserve the complete mark. See
  [Android adaptive icon guidance](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).
  Existing manifest `@mipmap/ic_launcher` resolves to the new v26 adaptive XML.
  No monochrome redraw is provided; OS/user themes can transform icon appearance.
- iOS: existing Contents.json preserved, all 15 distinct PNG sizes exported,
  including iPhone/iPad and 1024px App Store. RGB exports remove only fully opaque
  alpha. App Store RGB pixels equal the source's RGB pixels exactly.
- Existing white launch screens remain. Android 12+ now resolves the official
  adaptive launcher; iOS launch has no Flutter art. No delays/animations added.
- Display name remains 레전드스터디+ / English LegendStudy+. Technical IDs,
  app version, auth/deep links, Home artwork and in-app code are unchanged.
- Low-resolution files below are legacy/reference only, never launcher inputs.
  The previously missing legacy favicon was restored byte-for-byte from Git to
  satisfy the Owner instruction to retain it. The old HOLD below is historical.

## Completion validation — 2026-09-20

- Launcher export check: 21 PNGs PASS (15 iOS, 5 legacy Android, 1 adaptive),
  exact source hash, pixel equivalence, dimensions, opaque output, XML and safe zone.
- Flutter analyze PASS; full suite 427 PASS / 1 existing skip. Focused brand render
  4 PASS at 360×640/428×926, 1×/2×. Android debug/iOS simulator builds PASS.
- Pixel 5 / API36 fresh emulator: actual circle launcher, full accessibility label
  레전드스터디+, official-icon cold splash and Home PASS. The narrow app-drawer
  cell ellipsizes the visual name; full installed label is unchanged and correct.
  Squircle is an offline masked render/safe-zone check, not a second OEM device.
- iPhone 16 Pro / iOS18.6 simulator: AppIcon/name, white launch and Home PASS.
  No document/pencil clipping or Flutter placeholder remains in reviewed flows.
- Local screenshots: `/private/tmp/legendstudy-icon-review/` (temporary evidence,
  not a competing status document). Android system image and isolated AVD were
  added locally for validation; no app dependency or Production config used.
- Diff/syntax/credential checks PASS; identifiers, source bytes and legacy assets
  preserved. Production mutation 0. Brand scope complete; Owner review/push remains.
  Overall Core App release gates in Wiki are independent and remain open.

Owner-supplied historical originals, received 2026-09-13 on codex/day-5-ui-shell:

- `source/legendstudy_app_icon_source.png` (72×72): legacy “study” favicon asset;
  NOT the launcher canonical source. Its historical filename is retained.
- `source/legendstudy_square_logo_source.png` (150×150): official core symbol and
  square brand reference. The orange memo/document + pencil symbol at the top is
  the canonical design reference for future iOS/Android launcher icons.
- `source/legendstudy_wordmark_source.png` (1100×156): official wordmark reference
  in the original website banner.

Source bytes are preserved without alteration. SHA-256:

- `legendstudy_app_icon_source.png`: `03aeee4f7f524b1d07a6c30017666f66a11b42ba94d1c7634f03f023ad29cb60`
- `legendstudy_square_logo_source.png`: `353e35d3429d1a94a77ca45c15f7d8ddf911cb05ccb94bb228aa541c1803e583`
- `legendstudy_wordmark_source.png`: `697023da6d49db39bca6a232b3b539f4904ca95277181a4e766fa1061d81ac62`

`generated/legendstudy_wordmark_header.png` is a lossless 216×55 crop of the
wordmark source: Pillow crop box `(718, 64, 934, 119)` (left/top inclusive,
right/bottom exclusive). It retains the Korean “레전드스터디” artwork;
the 닷컴 suffix, URL, separate ornament and horizontal rules outside the crop are omitted.
No redrawing, recoloring or replacement typography. Reproduce with Pillow:

```python
from PIL import Image
Image.open('assets/brand/source/legendstudy_wordmark_source.png').crop(
    (718, 64, 934, 119)
).save('assets/brand/generated/legendstudy_wordmark_header.png')
```

Home renders the crop at up to 180 logical pixels wide, respecting available
width and aspect ratio. Only this derived asset is in the runtime Flutter bundle.
General-purpose icons and Text widgets must not impersonate the official logo.
Body typography and existing orange theme tokens remain unchanged.

At the Day 5 baseline, platform launcher icons remained Flutter placeholders. Do not enlarge the low-resolution
square reference into a final launcher icon. High-resolution production/restoration
of its memo/document + pencil symbol is a separate future brand task; no launcher
replacement or restoration is performed in Day 5. The legacy favicon is not its basis.

The current Home wordmark size, spacing and overall hierarchy are provisional.
Future refinement should consider a smaller wordmark, better continuity between
header and first section, clearer divider/outline and text contrast, and stronger
section separation while continuing to avoid excessive orange.

## Earlier 2026-09-20 display identity / launcher HOLD (superseded above)

- Official user-facing name: **레전드스터디+**; English: **LegendStudy+**.
  Android/iOS display names, Flutter app title, About, notifications and Focus
  labels updated. Native version/build remains dynamic.
- Home keeps the unchanged original wordmark artwork with a separate product-name
  caption. The caption is text, not a redrawn logo; screen readers announce the
  product name once. Auth flow/layout is unchanged.
- Canonical source directory remains `assets/brand/source/`; original hashes and
  generated wordmark are unchanged. Repository and all-branch asset history checked.
  The 72×72 favicon is explicitly NOT the launcher source (79fd09a correction).
  The 150×150 square is a reference with additional text, not a production-size
  isolated launcher icon. No suitable high-resolution launcher original found.
- **OWNER ICON SOURCE REQUIRED**: supply the original high-resolution launcher
  artwork (1024×1024 or vector) and, if available, adaptive foreground/background.
  No upscaling, crop, recoloring, AI generation or reconstruction performed.
- Launcher application HOLD on both platforms: existing Flutter mipmaps/AppIcon
  remain. Android has no adaptive foreground/background resource; safe-zone review
  is pending the real source. iOS existing 1024 placeholder has no alpha, but this
  does not establish acceptance of the future Owner asset.
- Splash audit: Android pre-12 white launch background; iOS centered 1×1 transparent
  LaunchImage on white. Android 12+ can still show the placeholder launcher icon.
  No launch asset changes, animation, artificial delay or network splash added.
- Technical identifiers unchanged: `com.legendstudy.app`, `legendstudy_app`,
  existing Supabase identifiers, deep links and OAuth callbacks.
- Validation: full existing Flutter suite 423 PASS / 1 existing skip; new brand
  render suite 4 PASS across 360×640 and 428×926 at 1×/2× (Home/Auth/MY/About).
  Analyze PASS; Android debug and iOS simulator builds PASS. APK and built Info.plist
  confirm display name and unchanged package/bundle ID. iPhone 16 Pro / iOS 18.6
  simulator launch and Home render inspected. Android physical launch not tested.
  Large About title wraps at 2× without overflow; no font shrinking.
- Brand string audit, original-asset hash/technical-ID checks, credential-pattern
  scan and diff check PASS. Production mutation 0; full brand readiness remains NO
  until the Owner launcher source is supplied and native icon/splash review passes.
