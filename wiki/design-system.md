# Design System

## Current canonical system — v2 (Owner approved 2026-09-24)

Owner approved Palette A (brand refined below), Materials5 + existing load-more, Settings-bottom logout,
no peach strips and a visible Guest login CTA. The detailed approved design and
implementation mapping live in [v2 specification](design-system-v2-proposed.md).
This file is the canonical entry point; v2 overrides conflicting historical color,
section, D-Day and spacing paragraphs below. Original brand assets stay unchanged.

- Page #F4F6F8; grouped/content surfaces #FFFFFF; primary #FFA300; navy #1B2A4A.
- SectionHeader is a plain semantic18sp title; no emphasized variant/left rule.
- LsCard: white/shadowSm/radius14, no border by default; Home daily opt-in below. LsListRow:48px target/chevron.
  SettingsGroup: small neutral label + related white rows. No nested cards.
- Orange fill uses navy text. Small selected/nav text uses contrast-safe orange
  ink #A94B00; destructive text #B42332. These derived text roles pass4.5:1;
  raw tertiary/danger/orange palette values are not used as small white-bg text.
- Filled/outlined/text buttons remain Flutter components themed centrally;
  ShellPage, AppHeader, SearchEntry, QuickFilterChip, EmptyState/ErrorState retained.
  Home/full search share InputDecorationTheme; Home has compact padding.
- Settings logout follows policy/info, directly above single destructive deletion.
  Guest MY/Settings have visible Login; MY private modules are hidden for Guest.
- Existing provider-button official brand colors are intentionally independent
  (Google/Kakao/Apple guidelines), not rewritten as app accent tokens.
- Functional contracts and light-only scope unchanged. Device acceptance pending.

## Historical design evidence (superseded styling; brand provenance retained)

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

## Home compact cards — 2026-09-22

DailyUtilityCard alone uses homeCardBorder #C8C3BB and shared vertical padding 4px;
Home daily-card gaps 6px. Existing neutral/warm palette, typography and >=48px
interactive targets remain. Optional header action reserves no space when absent.
Global content/search cardBorder remains #DCDCDC. Scaled content grows naturally;
inline meal expands in the Home scroll, with expanded semantics and chevron state.

## Shared section hierarchy — Owner refinement 2026-09-23

`SectionHeader(emphasized: true)` uses theme surfaceContainerLow, onSurface
heading/left rule and compact padding. `SectionDivider` uses theme outline at
1.5 logical pixels. Shape, heading and spacing supplement color. Home sections
after meals, Materials search/filter/results, Learning history/panel boundary,
MY and Settings reuse these primitives. No per-screen orange/shadow/card stack.
Auth form hierarchy remains unchanged. Widget/render matrix covers360×640 and
428×926 at1×/2×; physical acceptance remains Owner work.

## Latest device follow-up — 2026-09-24

Neutral v2 surfaces stay. Small semantic icon accents distinguish Home D-Day
orange / Study blue / Meal green, never full-card color or school red. Home uses
own nickname greeting or safe fallback, not wordmark/brand caption. Materials5
supersedes10. MY score modules are compact snapshots + LAB CTA with caller Back.
Timer recent7days reuses StudyBarChart. No new notification/badge/analytics backend.

## Owner follow-up 3 — confirmed brand

Canonical primary/brand **#FFA300**, from Owner's app-icon source confirmation.
#FB8C00 was the prior v2 working accent and is superseded, not the current brand.
PEACH_UI: PROHIBITED BY OWNER. primarySoft compatibility token is now neutral
#E6E9EE; navigation/chip/scoring selection surfaces are cool neutral. White cards
and #F4F6F8 page remain; no full peach/orange page/card, no thick semantic strip.
Buttons use #FFA300 with #1B2A4A text; contrast is tested against WCAG4.5:1.
White on brand fails4.5:1 and is not used. Small white-background active text keeps
contrast-safe ink, not raw brand orange. Brand assets/provider-brand colors remain.
Home D-Day small icon uses brand; Study blue and Meal green icons remain semantic.
Mock selectors use reduced vertical padding and content-driven height, preserving
48px interaction target and2× wrapping. No clipped fixed-height selectors.

## Owner final UI polish — 2026-09-24

Home D-Day, Study and Meal alone opt into `LsCard.dailySurface`: white,
1px cool-neutral dailyCardBorder #D5DBE3, navy5% shadow offset(0,2)/blur4,
radius14. Other cards retain v2 defaults; no strips/peach/elevation growth.
Brand #FFA300 with navy ink (7.10:1) and existing D-Day/blue Study/green Meal
icons remain. Meal date ChoiceChips explicitly suppress checkmarks while retaining
neutral selected fill and selected semantics. No date/provider/policy changes.
Daily Study summary uses a wrapping “이번 주 / 총 … / 일 최대 …”; the neutral
mean caption sits directly above the dashed line's left start, with white backing
for readability across bars. See [Study policy](study-v1.md#owner-final-ui-polish--2026-09-24).
