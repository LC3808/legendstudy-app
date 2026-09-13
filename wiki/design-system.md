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
unmodified Flutter placeholders; original LegendStudy logo assets are not in the
repository and should be supplied before production icon work.

## Day 2 brand asset baseline

`assets/brand/` is the canonical location for original owner-supplied brand assets.
Expected files are `legendstudy-logo.png`, `legendstudy-logo-horizontal.png`, and
`legendstudy-symbol.png`; `assets/brand/source/` preserves original design files.
These are filename conventions, not a claim that logo binaries are available.
See `assets/brand/README.md` for preservation and provenance rules.

No original logo files are present in the repository as of this work. No logo is
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
screens retain back AppBars. No new logo, asset, animation or fake ad slot.

Text/outlined action labels use Text Primary on white for readable contrast;
orange remains a fill/selection/accent. Day 5 visual checks cover all four tabs
and nested Saved; 2× text-scale regression passes. This is basic UI/accessibility
coverage, not a full screen-reader or WCAG certification.
