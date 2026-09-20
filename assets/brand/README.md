# Official LegendStudy+ brand assets


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
