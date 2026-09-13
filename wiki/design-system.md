# Design System

## Brand source

LegendStudy should preserve the visual continuity of the existing `legendstudy.com` brand and the legacy logo assets supplied by the product owner.

## Primary color direction

Use the established LegendStudy orange family as the primary accent. Initial working tokens:

- Primary Orange: `#FFAC14`
- Primary Dark: `#E99500`
- Primary Soft: `#FFF3DC`
- Background: `#FFFFFF`
- Surface Warm: `#FFFDF9`
- Text Primary: `#202124`
- Text Secondary: `#666666`
- Divider: `#EEEEEE`

These values are starting tokens and may be refined after visual testing against the source logo assets.

## Usage principle

Do not flood the UI with orange. Use it primarily for:
- primary actions
- selected states
- key icons
- emphasis lines
- countdown/highlight elements
- brand moments

Content-heavy screens should remain highly readable and mostly neutral.

## Logo/icon

Use the existing LegendStudy identity as the basis for app branding. Preserve original assets; derived mobile-ready assets should be created separately rather than overwriting source files.

## Accessibility

- Maintain sufficient text/background contrast.
- Do not rely on color alone to communicate state.
- Ensure touch targets and typography are appropriate for student mobile use.

## Day 1 implementation

`lib/core/theme/app_theme.dart` implements the working tokens above in a reusable
Material 3 light theme. Orange buttons use dark text; selected navigation uses
the soft orange indicator with a dark icon and visible labels. Main backgrounds
stay white, with warm navigation surfaces. Spacing: 24 logical pixels; accent
container radius: 20. Buttons have at least 48 logical-pixel minimum dimensions.

Placeholder content scrolls and is constrained to 600 logical pixels on wide
screens. Korean Material localization is enabled with platform fonts. A widget
test checks every tab at 360 × 640 and 2× text scaling for layout exceptions.
This is baseline coverage, not a full accessibility audit. Launcher icons are
unmodified Flutter placeholders. The Day 5 brand correction below records the
subsequently supplied official sources and remaining launcher-resolution work.

## Day 2 brand asset baseline

`assets/brand/` is the canonical location for original owner-supplied brand assets.
Expected files are `legendstudy-logo.png`, `legendstudy-logo-horizontal.png`, and
`legendstudy-symbol.png`; `assets/brand/source/` preserves original design files.
These are filename conventions, not a claim that logo binaries are available.
See `assets/brand/README.md` for preservation and provenance rules.

At Day 2, no original logo files were present in the repository. No logo is
fabricated or redrawn, and generated Flutter launcher icons remain unchanged
until real source assets arrive. The existing palette and orange-accent usage
remain unchanged. Both platform app display names are `레전드스터디`.

## Day 5 UI/UX v1.1 implementation

Read ui-ux-v1.md before UI changes. Palette unchanged. AppTokens now distinguish
pagePadding 24, sectionGap 28, smallGap 8, cardRadius 16, chipRadius 24; existing
spacing/radius aliases remain compatible. Text roles: headline 24, title 22,
subtitle 17, body 16/14, meta 12; dividers use #EEEEEE.
Per-tab headers replace the generic shell AppBar. Each ShellPage owns its Material
surface/scroll scope, so ink effects remain within its navigator page. Nested
screens retain back AppBars. The brand correction below replaces the temporary
Home icon/text lockup with official artwork; no animation or fake ad slot.

Text/outlined action labels use Text Primary on white for readable contrast;
orange remains a fill/selection/accent. Day 5 visual checks cover all four tabs
and nested Saved; 2× text-scale regression passes. This is basic UI/accessibility
coverage, not a full screen-reader or WCAG certification.


## Day 5 official brand correction (2026-09-13)

Canonical owner-supplied sources (preserved byte-for-byte):

- `assets/brand/source/legendstudy_app_icon_source.png` — launcher canonical, 72×72.
- `assets/brand/source/legendstudy_square_logo_source.png` — square logo, 150×150.
- `assets/brand/source/legendstudy_wordmark_source.png` — website banner, 1100×156.

Never use a general-purpose/Material icon as the official brand. Never recreate
its wordmark with a Text widget. Derived assets must come exclusively from these
canonical sources; preserve source files and record crop/resize provenance.
Home uses `assets/brand/generated/legendstudy_wordmark_header.png`, the unchanged
Korean artwork cropped from the banner (box 718,64,1030,119; 312×55). Its display
width is at most 280 logical pixels with preserved aspect ratio and an accessible
header label. The existing orange brand family and system UI typography remain.
See assets/brand/README.md for source hashes and exact reproduction instructions.

Platform launcher replacement is deferred: the official icon is only 72×72;
obtain a higher-resolution official original before generating the 1024×1024 iOS
marketing icon. Current platform icons are placeholders, not approved brand art.
