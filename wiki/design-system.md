# Design System

## Current display identity — 2026-09-20

Official display name is **레전드스터디+** (English **LegendStudy+**), separate from
unchanged technical identifiers. Native labels and in-app text are applied;
original Home artwork is preserved with a separate product-name caption.
Launcher completion now uses Owner `assets/brand/source/legendstudy_app_iocon_1024.png`
(1024×1024 PNG), preserving source bytes. Legacy reference assets are not inputs.
Android/iOS launcher, splash and Home runtime review PASS. Android circle is
verified on emulator; squircle by offline mask check. Android safe-zone padding
and iOS opaque RGB exports are documented in the
[brand asset record](../assets/brand/README.md). No design or technical ID changes.
Historical entries below are preserved.

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
- Divider: `#E5E5E5`
- Card/search border: `#DCDCDC`
- Navigation indicator: `#FFE3B0`

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

- `assets/brand/source/legendstudy_app_icon_source.png` — legacy “study” favicon,
  72×72; NOT a launcher canonical source. Historical filename retained.
- `assets/brand/source/legendstudy_square_logo_source.png` — official core symbol
  and square brand reference, 150×150. Its top orange memo/document + pencil symbol
  is the canonical design basis for future iOS/Android launcher icons.
- `assets/brand/source/legendstudy_wordmark_source.png` — official wordmark
  reference / website banner, 1100×156.

Never use a general-purpose/Material icon as the official brand. Never recreate
its wordmark with a Text widget. Derived assets must come exclusively from these
canonical sources; preserve source files and record crop/resize provenance.
Home uses `assets/brand/generated/legendstudy_wordmark_header.png`, the unchanged
Korean artwork cropped from the banner (box 718,64,934,119; 216×55). Its display
width is at most 180 logical pixels with preserved aspect ratio and an accessible
header label. The existing orange brand family and system UI typography remain.
See assets/brand/README.md for source hashes and exact reproduction instructions.

Platform launcher replacement remains deferred. Do not enlarge the low-resolution
square image into a final launcher icon. High-resolution production/restoration of
the memo/document + pencil symbol is a future brand task, not Day 5 implementation.
The legacy favicon is not the design basis. Current platform icons are placeholders.

### Provisional Home styling / later UI refinement

The current official wordmark image remains applied, but its size, spacing and
whole-screen hierarchy are not a final approved design. Later refinement should
consider reducing wordmark size, improving continuity between the header and first
section, strengthening divider/outline and text contrast, and clearer section
separation. Continue to avoid excessive orange. No UI redesign accompanies this
asset-role correction.


## Day 6 entry — shell hierarchy refinement

Current tokens supersede the historical Day 5 values: pagePadding 20, sectionGap 24,
divider #E5E5E5, distinct cardBorder #DCDCDC for cards/search surfaces. cardRadius 16,
chipRadius 24 and smallGap 8 unchanged. SectionHeader uses its own 15sp/w700 role,
top 24/bottom 8; ContentCard titles retain 17sp/w600. Home official wordmark was 210
logical pixels wide at Day 6, without the introductory subtitle. Artwork bytes unchanged.
Loading spinners are centered to avoid stretching under list width constraints.
Material NavigationBar remains: all four tabs have outlined/filled icon pairs;
Materials uses article_outlined/article. Labels use selected w700 vs normal w400,
with a restrained #FFE3B0 indicator. System body fonts remain unchanged.


## Day 7 compact NEIS attribution (superseded on Home)

Home places 출처: NEIS at the right of the existing school-setting action row,
using 12sp secondary text and no separate source block/spacer. Preserve attribution
visibility only with a selected school. School setup footer uses the short label
출처: 교육부·시도교육청 NEIS in a natural secondary position without extra padding.
Both are TextButtons with >=48×48 touch targets, system text scaling and a short
native source dialog. Longer scaled labels may wrap within the shared action row;
never shrink text scaling or clip the explanation to fit. No new card/section.


## Day 7 Home follow-up

Home now renders only the official 레전드스터디 artwork (without 닷컴), at 180px
maximum width. Source bytes are unchanged; see assets/brand/README.md provenance.
Home top inset 12px, branded header bottom 8px; utility cards use horizontal 16px /
vertical 8px padding. School name/학교 설정 and 나의 공부 시간/학습으로 이동 share
heading rows. Actions retain minimum 48px targets and wrap at large text scale.
Home has no source attribution. School setup alone retains its compact meta
attribution and native information dialog. Quick/find and study headings use
8px top / 4px bottom spacing; other screens keep existing section tokens.
D-Day settings accept one date and label (trimmed, 1–80 Unicode code points).
The editor explicitly says settings reset on app exit and are not account-saved.
Dates count Korean calendar days: future D-n, today D-DAY, past 지난 일정.
No database write/persistence is implemented pending a separate storage approval.


## D-Day information hierarchy refinement

- Schedule name and countdown now share the first row with settings at the right.
  Long names ellipsize; countdown and >=48px settings target take priority.
- Active countdown uses primarySoft pill, textPrimary 16sp/w800 with zero tracking;
  no orange-on-white small text or red warning color. Exact date is secondary on
  the second row. Expired targets use plain secondary 지난 일정, without a pill.
- 360×640 at 1×/2× verified for long labels and D-DAY/D-1/D-23/D-999/D-7300/expired;
  header alignment, full countdown, date position, targets and no increased card
  height verified. Analyze PASS, all 95 Flutter tests PASS, diff check PASS.
- UI only; session storage, calendar rules and pending DB approval remain unchanged.
  Platform builds not repeated for this typography-only change. No push/PR/merge.
