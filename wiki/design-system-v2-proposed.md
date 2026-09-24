# Design System v2 — PROPOSED (UI/UX Lead review)

Status: **OWNER APPROVED — IMPLEMENTED IN CODE; DEVICE REVIEW PENDING.**
Owner implementation instruction on2026-09-24 selected Palette A, Materials10,
existing load-more, Settings-bottom logout, removal of peach strips, visible Guest
login. Original proposal authored by Claude(UI/UX lead)2026-09-24 is retained below;
its approval-pending/no-code wording describes that proposal stage only. This
implementation status supersedes those historical restrictions.

Scope: visual system, information hierarchy, component rules and screen redesign
for Home / Materials / Learning / LAB / MY / Settings. Functional contracts, IA
(5 tabs), navigation, backend and scope are unchanged. This is not a re-plan.

Related canon: [design-system.md](design-system.md), [ui-ux-v1.md](ui-ux-v1.md),
[core-app-improvements.md](core-app-improvements.md),
[current-status.md](current-status.md). Newest explicit Owner decisions
(2026-09-23 Mobile IA override, edit/visual conventions) are treated as
authoritative over older Day 5/6 styling.

---

## 0. Code-grounded baseline (verified 2026-09-24, no edits)

- Tokens are centralized in `lib/core/theme/app_theme.dart` (`AppTokens`). Only
  **5** hardcoded `Color(0x..)` exist outside the theme (provider_button ×3,
  home_page ×1, content_type_badge ×1). **The problem is token semantics, not
  scattered hardcoding.**
- **No dark mode.** Single `AppTheme.light`; no `ThemeMode`/`darkTheme`. Dark is
  future scope; v2 defines light only, with a dark-ready token structure.
- **The peach-strip + black-line = `SectionHeader(emphasized: true)`**:
  `color: surfaceContainerLow` (pale peach in an orange-seeded M3 scheme) +
  `border-left: onSurface (#202124) 3px`. Used **14×**: Home 1, Study 1,
  Materials 2 (incl. `검색·필터` line 193), Settings 6, MY 4.
- **Page bg `#FFFFFF` vs card `surfaceWarm #FFFDF9`** ≈ 1% difference; separation
  carried only by a `#DCDCDC` border → no surface hierarchy (root "밋밋" cause).
- **Home language break**: top D-Day/Study/Meal use `DailyUtilityCard` (bordered
  card + 4px accent bar) with **6 arbitrary accent colors** (study #5145A6, meal
  #2F855A, search #2563A8, updates #B7791F, recent #6B46C1, dday primaryDark);
  from `자료 검색` down it switches to emphasized peach-strip `SectionHeader`.
  The two halves read as two apps — exactly the Owner's §17/§18 split.
- **Materials initial 24**: `SupabaseSearchRepository.pageSize = 24`; first query
  `.range(offset, offset+pageSize)`. Load model is an explicit **`자료 더 보기`**
  button (`state.nextOffset`), NOT infinite scroll.
- **Search**: `title/summary ILIKE %word%` + subject/year/month/grade/type term
  extraction; order `sort_date DESC, content_item_id DESC` (general stream
  `feed_updated_at DESC`). Recency order, not relevance ranking.
- Remove targets present in code: `검색·필터` (materials_page:193),
  `최신 시험순 · 첨부 종류는 등록 정보 기준` (materials_page:345).
- Guest MY: current HEAD renders `FilledButton('로그인 / 시작하기')`
  (profile_page:85–89). Owner "no login button" is likely an older build or the
  guest sub-widgets' "로그인하지 않은 상태" text below it — **verify against the
  build on device** before treating as a bug.

---

## 1. Executive diagnosis — why it looks unfinished (Deliverable 1)

1. **No surface hierarchy.** Page and card are both ~white; only a thin gray
   border separates them. Modern apps (Toss/Shinhan) put white cards on a cool
   gray page. Without that tonal step, sections look like bordered document
   boxes, not elevated surfaces. *(VISUAL — root cause)*
2. **The emphasized SectionHeader reads as a document sub-heading, not an app
   section.** A pale fill + hard black left rule is the visual grammar of a Word
   heading box. Repeated 14× app-wide, it defines the whole app's feel. *(VISUAL)*
3. **Orange is used as background wash, not accent.** `primarySoft #FFF3DC`,
   `navIndicator #FFE3B0`, `surfaceContainerLow` spend the brand color on pale
   fills, so when a real CTA needs to pop, orange has already been diluted
   everywhere. The Owner's "살구색이 포인트 역할을 못한다" is literally true. *(VISUAL)*
4. **No consistent accent language.** Home alone uses 6 unrelated accent hues;
   nav uses peach; sections use black rules. Nothing ties the screens together. *(VISUAL)*
5. **Weak type hierarchy.** Section title is only 15sp/700; card title 17sp/600;
   body 16 — the steps are too small to create rhythm. There is no hero/primary
   value scale for D-Day or study totals. *(VISUAL)*
6. **Border overload.** Section fill + left rule + card border + input border +
   dividers stack on one screen, all in similar grays — busy but low-contrast. *(VISUAL)*
7. **Flat CTA hierarchy.** Actions are almost all `OutlinedButton` (MY, Settings,
   logout). Nothing signals the single most important action per screen. *(UX)*
8. **Over-explaining copy.** `검색·필터`, `최신 시험순 · 첨부 종류는 등록 정보 기준`
   describe what the UI already shows. *(UX)*
9. **Long initial scroll.** 24 results before any structure = "list dump". *(UX/QUERY)*
10. **Half-finished transitions.** The clean top-of-Home vs document-like
    bottom-of-Home proves an incomplete migration, which the eye reads as
    "stopped halfway". *(VISUAL)*

---

## 2. Reference comparison (Deliverable 2)

Principles extracted; not a clone. Working from the Owner's verbal descriptions
+ general knowledge of these apps (exact attached screenshots were not available
to this pass).

| Attribute | Current LegendStudy | Toss | Shinhan SOL | Hyundai Card | v2 Direction |
|---|---|---|---|---|---|
| Color | orange spent on pale fills | 1 brand blue as accent only, mostly neutral | restrained blue accent | bold high-contrast mono + 1 accent | orange = accent ONLY; neutral base |
| Surface | white-on-white + border | white cards on gray page | grouped white cards on gray | large white fields, deep contrast | cool-gray page + white surface |
| Card | box around everything | card = related group only | grouped rows in card | few, decisive cards | card = related group only |
| Typography | shallow 15/17 steps | strong size+weight steps | clear title/label | bold display type | add hero + clear step scale |
| Spacing | 20 pad / 24 gap, uneven | generous, consistent rhythm | consistent | very generous whitespace | 4-based scale, one rhythm |
| CTA | all outlined | 1 primary filled per view | clear primary | one confident action | Primary/Secondary/Text/Destructive |
| Navigation | peach pill indicator | subtle neutral+brand | clear active | minimal | orange text + subtle tint pill |
| Section | peach strip + black rule | title + spacing | title + grouped card | title + whitespace | title + spacing + surface (no strip) |
| Search | full input + helper copy | compact rounded field | compact field | — | one field family, compact on Home |
| Density | wide padding, thin content | comfortable, scannable | information-dense but tidy | airy | comfortable student density |

- **Toss** — take: strong hierarchy, neutral surfaces, concise copy, card
  grouping. Don't clone: finance density, Toss blue, dashboard structure.
- **Shinhan** — take: grouped cards, quick-action placement, clear selected
  states. Don't clone: banking chrome; the app must not look like a bank.
- **Hyundai Card** — take: bold type, high contrast, confident whitespace,
  content focus. Don't clone: luxury/commerce hero, card-product dominance.

---

## 3. Palette (Deliverable 3a) — two candidates + recommendation

### PALETTE A — Orange + Deep Navy + Cool Neutral  ★ RECOMMENDED
Clean, modern, academic-energetic. Cool neutral base makes orange pop as a
confident action color; navy ink reads premium (toss/hyundai direction).

| Token | HEX | Role |
|---|---|---|
| colorPrimary | #FB8C00 | Legend Orange, committed — CTAs, selection, key accent |
| colorPrimaryPressed | #E67E00 | pressed/active |
| colorPrimarySubtle | #FFF1E0 | selected-row tint, accent chip bg (sparingly) |
| colorBrand | #FFAC14 | brand moments only (splash/wordmark continuity) |
| colorAccent (info) | #2563A8 | limited cool-blue for links/info, not decoration |
| colorBackground | #F4F6F8 | page background (cool very-light gray) |
| colorSurface | #FFFFFF | cards / grouped surfaces |
| colorSurfaceElevated | #FFFFFF + shadow-sm | raised sheet/menu |
| colorTextPrimary | #1B2A4A | deep navy ink |
| colorTextSecondary | #5B6472 | secondary |
| colorTextTertiary | #8A93A3 | meta/caption |
| colorBorderSubtle | #E6E9EE | control outline / subtle separation |
| colorDivider | #EDF0F3 | in-surface divider |
| colorSuccess | #1F9D57 | success |
| colorWarning | #E8A400 | warning (distinct from brand orange) |
| colorDanger | #E5484D | destructive (회원 탈퇴) |
| colorDisabled | #C2C7D0 | disabled fg/detail |

### PALETTE B — Orange + Charcoal + Warm Neutral
Warmer, softer, lifestyle/academic-cozy. Lower risk of feeling corporate, but a
warm off-white base re-introduces some of the beige wash the Owner is escaping.

| Token | HEX | Role |
|---|---|---|
| colorPrimary | #FB8C00 | CTA/selection/accent |
| colorPrimaryPressed | #E67E00 | pressed |
| colorPrimarySubtle | #FFF3E6 | selected tint |
| colorBackground | #FAF7F2 | warm off-white page |
| colorSurface | #FFFFFF | cards |
| colorTextPrimary | #23262B | charcoal |
| colorTextSecondary | #6B7078 | secondary |
| colorBorderSubtle | #ECE7DF | outline |
| colorDivider | #F1ECE4 | divider |
| colorDanger | #E5484D | destructive |

### Preview feel
- **A:** Home/Materials/MY/Settings read clean, academic, energetic; orange
  clearly "pops" on cool gray; strongest separation of page vs card.
- **B:** warmer and softer, friendlier, but flatter contrast and a mild return of
  the current beige feeling.

### RECOMMENDED: **Palette A.**
Reason: the Owner's core complaints are (1) no pop, (2) beige wash, (3) flat.
A fixes all three structurally — a cool-neutral page maximizes orange contrast,
supplies the missing page-vs-surface step, and looks the most consumer-modern.
Brand continuity is preserved by keeping #FFAC14 for brand moments while #FB8C00
carries action. B stays available if the Owner prefers a warmer identity.

---

## 4. Token spec (Deliverable 3b) — Flutter-ready, current naming preserved

Extends existing `AppTokens`; keep names already in code, add the rest.

**Color** — as Palette A table (token names above).

**Typography** (semantic → size/weight/line-height):
- textPageTitle 24 / w800 / 1.25
- textHero (D-Day, study total) 30 / w800 / 1.15
- textSectionTitle 18 / w700 / 1.3  *(up from 15)*
- textCardTitle 16 / w700 / 1.35
- textBody 15 / w400 / 1.5
- textSecondary 14 / w400 / 1.5
- textCaption 12 / w500 / 1.4
- textButton 15 / w700
- textNavLabel 12 / selected w700 / normal w500

**Spacing** (4-based): space2 2, space4 4, space8 8, space12 12, space16 16,
space20 20, space24 24, space32 32. Retire ad-hoc 13/6/10 paddings.

**Radius**: radiusSm 10 (chips/inputs), radiusMd 14 (cards/rows), radiusLg 20
(sheets/hero), radiusPill 999 (selected chips/pills).

**Border**: 1px `colorBorderSubtle` on inputs and standalone controls only.
Cards prefer surface+shadow over border; use at most one of {border, shadow}.

**Shadow**: shadowSm `0 1 2 rgba(20,30,50,.06)` (cards), shadowMd
`0 4 12 rgba(20,30,50,.10)` (sheets/menus). No shadow on rows inside a card.

**Icon**: outline family, 24 default / 20 dense / 22 nav; stroke ~2; trailing
chevron `chevron_right` 20 in tertiary; selected nav = filled variant. No mixing
of outline/filled per screen.

**Motion**: 150ms ease for state, 200ms for surface/sheet; no decorative motion.

**Layout grid**: horizontal page gutter **20** everywhere (matches current
`pagePadding`); card inner padding **16**; row min height 48; max content width
640 (keep). No per-screen gutter differences.

---

## 5. Global policies (Deliverable answers to Q4/Q5 + §12–16, 44–49)

- **SECTION_HEADER_POLICY:** Deprecate `SectionHeader(emphasized: true)` (the
  peach strip + black rule). Redesign the component's responsibility: a section
  is a plain `textSectionTitle` in `colorTextPrimary`, optional trailing action,
  then content; separation comes from spacing + surface grouping, NOT a colored
  strip. Keep a lightweight non-emphasized title only. **No colored title strip
  anywhere.** (Fixes all 14 call sites at once.)
- **PAGE_BACKGROUND_POLICY:** page = `colorBackground` (cool gray); content
  surfaces = white cards. This single change creates the missing hierarchy.
- **CARD_POLICY:** a card groups *related* content only; not every block. No
  nested cards, no card-inside-card. Inside a card: rows + dividers, no inner
  borders. Card grouping itself is the section boundary.
- **BORDER_POLICY:** cards use surface+shadowSm, not borders. Borders remain only
  on inputs and standalone controls. Never stack fill+rule+border+divider.
- **SHADOW_POLICY:** shadowSm on cards; shadowMd on sheets/menus; none on inner
  rows.
- **TYPOGRAPHY_POLICY:** adopt the semantic scale above; hero scale for D-Day and
  study totals gives the screens a focal point.
- **SPACING_POLICY:** one 4-based scale; consistent sectionGap 24 / row rhythm.
- **ICON_POLICY:** one outline family + filled nav-selected; consistent sizes.
- **BOTTOM_NAV_POLICY:** keep 5 tabs. Replace peach `#FFE3B0` pill with
  `colorPrimarySubtle` tint + `colorPrimary` selected icon/label; unselected
  `colorTextSecondary`. Selected state clear but not loud; same accent as the
  rest of the app so nav ≠ different language.

---

## 6. Card & accent cleanup
Home's 6 arbitrary accent hues are removed. Daily cards (D-Day/Study/Meal) keep
the compact card form but drop colored accent bars in favor of: white surface +
shadowSm + a small monochrome/orange icon per card. Optional: a single small
orange accent on the primary metric only. This unifies Home top with the rest.

---

## 7. Screen redesigns (Deliverable 4) — CURRENT ISSUE → NEW STRUCTURE

### 7.1 HOME
- CURRENT ISSUE: clean accent-bar cards on top, peach-strip document sections
  from `자료 검색` down; language break; 6 accent hues.
- KEEP: top daily dashboard structure (Owner "나름 깔끔"), 5-tab IA, D-Day/Study/
  Meal content contracts, session-only D-Day rule.
- NEW STRUCTURE (top→bottom): branded header → daily dashboard (D-Day hero +
  Study + Meal as white cards, shadowSm, mono/orange icons) → compact quick
  search → category chips → recent viewed → recent updates. All below use the
  v2 plain section title (no strip), same card/shadow language as the top.
- VISUAL RULE: one accent (orange) for the primary metric/CTA; everything else
  neutral. Page = cool gray, cards = white.
- CTA: D-Day set = tertiary; 자료 검색 = the search surface itself (primary
  affordance); category chips = secondary. Not all equal weight.
- REMOVE: peach strips; per-section accent colors.

Text wireframe:
```
HOME
LegendStudy+
┌ D-Day ──────────────┐  (hero number, white card)
│ 수능까지  D-212      설정 >
├ 오늘 공부  02:14:00 ─┤  학습으로 이동 >
├ 오늘 급식 ───────────┤  (school set) / "학교를 설정하면…"
└──────────────────────┘
자료 검색
[ 🔍 모의고사, 논술, 학습자료 검색 ]        (compact, tap → Materials)
[모의고사][학습자료][논술][입시정보]
최근 본 자료                         전체 보기 >
· item / · item        (or empty state, compact)
최근 업데이트                        더보기
· item / · item
```

### 7.2 MATERIALS
- CURRENT ISSUE: `검색·필터` peach header, helper copy line, 24-item first load.
- REMOVE (Owner-confirmed): `검색·필터` title (materials_page:193); helper copy
  `최신 시험순 · 첨부 종류는 등록 정보 기준` (materials_page:345).
- NEW STRUCTURE: page title `자료 찾기` → search field (self-explanatory) →
  primary filter chips (학년/연도/시행 월/시험 종류/과목) → content-type chips
  (전체/모의고사/학습자료/논술/입시정보) → results → `자료 더 보기`.
- VISUAL RULE: result list on gray page; each result a white row-card. Selected
  chip = orange fill/tint; unselected = neutral outline. Not every chip bordered
  heavily.
- INITIAL COUNT: see §8. Keep the existing explicit `자료 더 보기` button.

Text wireframe:
```
자료 찾기
[ 🔍 모의고사, 과목, 연도 검색 ]
[학년][연도][시행 월][시험 종류][과목]
[전체][모의고사][학습자료][논술][입시정보]
─ results ─
[type · title (2 lines) · meta · 저장]
…(≈10)
[ 자료 더 보기 ]
```

### 7.3 MATERIAL RESULT CARD (§26)
Priority: content-type badge (small, neutral) → title (2 lines, textCardTitle)
→ one meta line (grade·month·year·type, NULLs omitted) → resource summary chip(s)
→ bookmark (trailing, tap target 48). Tighter vertical rhythm so more results
fit per screen without crowding (target ≈ 3–4 visible on 640h). No fake exam
metadata; attachments 0 is valid (no big empty panel).

### 7.4 LEARNING (§42, 72)
- KEEP: Study Timer / Mock Exam IA and contracts; Study Trend canonical UX
  (7-day/8-week/6-month, dynamic max, zero-unpainted, oldest→newest).
- NEW: apply v2 tokens/components; timer idle + total use hero type; CTA =
  one primary `공부 시작`. Migrate `SectionHeader(emphasized)` at study_page:148
  (`최근 7일`) to the plain v2 section title. No functional change.

### 7.5 LAB (§43, 73)
- KEEP: independent 내신 분석 / 모의고사 분석 / 논술 준비 entries; external Essay
  via canonical HTTPS (no token). Advanced/unverified pages stay hidden (not fake
  ready cards).
- NEW: three entries as v2 entry cards (white surface, icon, title, one-line
  purpose, chevron), consistent Empty/CTA. No re-planning of LAB features.

### 7.6 MY (§27–31, 70)
- CURRENT ISSUE: 3–4 emphasized peach headers + plain dividers; two equal
  OutlinedButtons (공부 추이 보기 / 공부하러 가기).
- KEEP: header + settings gear; compact profile (avatar/nickname/school·grade);
  Profile/Study/Scores/Materials separated by subtle dividers (Owner 2026-09-23);
  no account-email banner (email lives in Settings); no fake Badge.
- NEW STRUCTURE:
  - Profile header = identity block (avatar 56–72, nickname, school·grade),
    reserve a right-side slot for future earned-achievement visual (FOUNDATION
    only, rendered empty/absent until implemented — no fake badges).
  - 학습 = one coherent module: today summary (hero) + two **navigation rows**
    `공부 추이 보기 >` and `공부하러 가기 >` (Owner disliked a strong filled
    `공부하러 가기`; rows avoid the two-big-outlined-buttons area problem and give
    a cleaner scan). Alternative if Owner prefers buttons: primary `공부하러 가기`
    (text/tonal, not loud orange) + secondary `공부 추이`.
  - 성적 = 내신/모의고사 summary rows → LAB detail; data + empty states.
  - 나의 자료 = compact navigation rows (저장한 자료 / 최근 본 자료), not big cards.
  - Section titles = plain v2 (no strip).

Text wireframe:
```
MY                                   ⚙
[avatar] 닉네임
         진접고등학교 · 2학년
학습
오늘 공부 02:14:00
공부 추이 보기                        >
공부하러 가기                         >
성적
내신 분석                             >
모의고사 분석                          >
나의 자료
저장한 자료                           >
최근 본 자료                          >
```

### 7.7 GUEST MY (§32, 33, 66, 70)
- FINDING: HEAD already shows `FilledButton('로그인 / 시작하기')`. Verify on the
  Owner's device build; if truly missing there, it is a build-lag, not a spec gap.
- NEW: dedicated guest block — short copy + one clear primary CTA; hide the
  auth-only study/score/materials sections for guests (currently they still
  render below the button).
```
MY
학습 기록과 저장한 자료를
계정에 연결해 관리하세요.
[ 로그인 ]                (primary; → existing /auth route)
```
Copy short and calm; CTA is the focal element.

### 7.8 SETTINGS (§34–40, 67, 71) — most detailed
- CURRENT ISSUE: 7 emphasized peach headers (one just for a single email row);
  logout mid-list (after 문의, before 약관); guest sees "로그인하지 않은 상태예요."
  with no CTA.
- NEW STRUCTURE: Apple/Toss-style grouped rows on gray page; group title =
  small tertiary label above a white grouped card; rows inside with dividers; no
  colored strips; compact (no giant whitespace per group).
- Row pattern: `[icon?] title  [subtitle?]  [trailing value / chevron / control]`.
- Logout = neutral secondary at the bottom (Owner preference: Settings bottom),
  directly above 회원 탈퇴. Move it out of the mid-list position.
- Destructive hierarchy: 로그아웃 neutral; 회원 탈퇴 danger text (keep current
  restraint — no big red card).
- Guest: replace the bare status text with a login CTA-led 계정 group.

Text wireframe (auth):
```
설정
계정
  forbeelite@…
프로필
  프로필 수정                          >
기본 정보
  학교·학년   진접고등학교 · 2학년      >
학습
  모의고사 응시시간 포함               ●  (toggle)
서비스
  문의·건의사항                        >
정보
  개인정보처리방침                     >
  이용약관                             >
  앱 정보                              >
로그아웃
회원 탈퇴   (danger text)
```
Guest 계정 group = short line + `[ 로그인 ]` primary; hide auth-only groups.

---

## 8. Materials initial count (Deliverable, Q7/Q8, §64/§88)

- MATERIALS_INITIAL_COUNT_CURRENT: **24**.
- MATERIALS_INITIAL_COUNT_CAUSE: `SupabaseSearchRepository.pageSize = 24`
  (`lib/features/materials/data/supabase_search_repository.dart:13`). The first
  page uses `.range(offset, offset + pageSize)`; `pageSize` doubles as the
  load-more page size and the has-more boundary. Not a fixture, not a DB default,
  not infinite scroll — a single constant.
- PAGINATION_MODEL: offset/range based; explicit **`자료 더 보기`** button driven
  by `state.nextOffset` (materials_page:400–408). Facets have their own
  `필터 목록 더 보기`.
- UX_PROBLEM: 24 rows before any grouping = long "list dump" on first entry.
- RECOMMENDED_INITIAL_COUNT: **10** (8–10 acceptable).
- RECOMMENDED_LOAD_MODEL: keep the existing explicit `자료 더 보기` button.
  Cleanest implementation: introduce a distinct `initialPageSize = 10` separate
  from the load-more `pageSize`, OR set `pageSize = 10`. Either keeps the offset
  contract predictable. **No code change in this task** — recommendation only;
  Owner picks the number.
- SEARCH_BEHAVIOR note (§89): ordering is recency (`sort_date DESC`), not keyword
  relevance. Keyword match is substring on title/summary + structured term
  extraction. This is a reasonable v1 model; if the Owner expects
  relevance-ranked results, that is a **separate SEARCH BEHAVIOR issue**, not a
  design fix, and needs a query-contract decision (out of scope here).

---

## 9. REMOVE / SIMPLIFY / KEEP (Deliverable, §90)

REMOVE (Owner-confirmed = firm):
- Materials `검색·필터` header (materials_page:193).
- Materials helper copy `최신 시험순 · 첨부 종류는 등록 정보 기준` (:345).
- Peach `SectionHeader(emphasized)` strips app-wide (all 14 sites).
- Home's 6 per-section accent colors.
- Settings repeated colored section chrome / oversized per-group whitespace.

REMOVE (candidates, need Owner OK — do not remove unilaterally, §65):
- `모의고사 응시시간 포함` subtitle `이 기기의 기본값 · 시험마다 변경할 수 있어요`
  (keep? it explains non-obvious behavior — SIMPLIFY rather than remove).
- Policy "준비 중 · 문의·건의사항으로 연락해 주세요" subtitles (keep until URLs live).

SIMPLIFY:
- MY Study CTA (two big outlined buttons → navigation rows / primary+secondary).
- Settings grouping (grouped rows, fewer headers, logout to bottom).
- Materials result metadata (one meta line, NULLs omitted).
- Home quick search (compact variant, distinct from full Materials search).

KEEP:
- Home top daily dashboard structure; 5-tab IA; all functional/data contracts;
  guest-first materials access; the explicit `자료 더 보기` load model; Study
  chart canonical UX; LAB 3-entry IA; no-fake-data / no-fake-badge rules.

---

## 10. Audits (Deliverable 5 area, §101–103)

- HARDCODED_COLOR_AUDIT: FOUND 5 outside theme (provider_button ×3, home ×1,
  content_type_badge ×1). CENTRALIZED: yes — `AppTokens` holds the system.
  RECOMMENDED_ACTION: migrate the 5 to tokens during v2; the real work is
  changing token *values/semantics*, not de-hardcoding.
- DESIGN_SYSTEM_WIKI_VS_CODE: the code faithfully implements the *current*
  design-system.md (peach strips, warm surface, orange). So the gap is not
  "code ignored the system" — the **system itself no longer matches the Owner's
  direction**. v2 updates the system; code follows after approval. Classify
  current design-system.md tokens: UPDATE (colors, section header, surface),
  KEEP (spacing scale, 48px targets, max-width 640, no-fake-data), STALE (peach
  strip guidance, navIndicator peach, per-section Home accents).
- SHARED_COMPONENT_CANDIDATES (migration KEEP/MODIFY/DEPRECATE):
  - KEEP: `ShellPage`, `AppHeader`, `SearchEntry`, `QuickFilterChip`,
    `EmptyState`, `ErrorState`.
  - MODIFY: `SectionHeader` (drop emphasized strip → plain title + optional
    trailing action), `DailyUtilityCard` (drop accent bar, white surface +
    shadow), `CompactUtilityCard` (white surface + shadow, token radius).
  - ADD (inventory, §74): `LsCard`, `LsListRow`, `LsPrimaryButton`,
    `LsSecondaryButton`, `LsSectionTitle`, `LsProfileHeader`, `LsEmptyState`
    (consolidate one-off widgets so Codex doesn't fork per screen).
  - DEPRECATE: emphasized `SectionHeader` variant; per-section accent tokens.

---

## 11. Owner decisions required (Deliverable, §85/§106) — 3 only

1. **Palette:** A (recommended) or B.
2. **Materials initial count:** 10 (recommended) or another value.
3. **Logout placement:** Settings bottom (recommended, Owner's stated preference)
   or MY bottom.

Already confirmed (not re-asked): remove `검색·필터` + search helper copy; login
default/logout → HOME; MY compact profile; Settings sectioned; no fake badges;
5-tab IA; guest MY needs a visible login CTA.

(Optional, only if the Owner wants: confirm the guest-MY button really is missing
on the device build vs. HEAD showing it.)

---

## 12. Codex implementation package (Deliverable 6, §86/§108) — NOT code

Phases (§76):
- P1 Tokens/primitives: apply Palette A tokens; add semantic type/space/radius;
  redesign `SectionHeader` (no strip); page-gray + white-card surfaces; nav
  selected state.
- P2 Settings + MY: highest-impact; grouped rows, logout to bottom, guest CTA,
  MY module + navigation rows. Use Settings as the v2 validation screen (§104).
- P3 Home + Materials: unify Home top/bottom; remove accents; compact search;
  remove `검색·필터` + helper copy; initial count → approved number.
- P4 Learning + LAB: migrate to v2 tokens/components.
- P5 Render regression + Owner device review.

Migration strategy (§77): **2–3 logical commits, not big-bang and not
one-screen-at-a-time.** Ship P1+P2 together (tokens must land with the first
screens or nothing looks right), then P3, then P4. Never leave one screen on v1
while neighbors are v2.

ACCEPTANCE CRITERIA (§108):
- No emphasized peach section strips anywhere (0 `emphasized: true`).
- Page uses colorBackground; content in white cards (visible tonal step).
- Guest MY shows a visible primary Login CTA; auth-only sections hidden for guest.
- Materials has no `검색·필터` title and no `최신 시험순…` helper copy.
- Materials initial results = approved count; `자료 더 보기` retained.
- Settings: grouped rows, no colored strips, logout at bottom above 회원 탈퇴,
  회원 탈퇴 = danger text (no big red card).
- All screens use shared tokens; nav selected state matches app accent.
- 360×640 and 428×926 at 1×/2×: no overflow, no excessive empty space.
- No fake data, no fake badges, no fake ad slots (unchanged rules).

VISUAL_REGRESSION_PLAN (§109): render matrix 360×640 + 428×926 at 1×/2× for Home,
Materials, Learning, LAB, MY, Guest MY, Settings (guest+auth); golden/PNG compare;
Owner device review as final gate. Separate functional checklist from visual
checklist (§110).

---

## 13. Problem classification (§91)

- VISUAL: peach strips, no surface hierarchy, orange-as-wash, 6 Home accents,
  weak type, border overload, nav peach pill.
- UX/IA: flat CTA hierarchy, over-explaining copy, long initial scroll, logout
  placement, guest MY CTA.
- FUNCTIONAL: guest MY sections rendering for guests (should hide).
- DATA/QUERY: Materials pageSize=24; search recency-vs-relevance (separate).
- FUTURE: Achievement/Badge surface slot (foundation only); dark mode.

Out of scope (unchanged): Daily Sync (DAILY_SYNC: SEPARATE P1), Achievement
engine, Community, payments, navigation re-design, feature removal.

---

## 14. Status

WIKI_STATUS: **IMPLEMENTED (approved scope)**. CODE_CHANGED: YES.
PRODUCTION_MUTATION:0. MOBILE_UI_OWNER_E2E: NOT VERIFIED.

## 15. Implementation evidence — 2026-09-24

- `app_theme.dart`: Palette A, semantic typography/spacing/radii/shadow/icon roles,
  cool page/white surface, neutral input/chip family, selected nav ink/tint.
  Contrast-safe small-text variants primaryInk/dangerInk supplement the palette.
- `shell_widgets.dart`: SectionHeader strip variant removed; LsCard/LsListRow/
  SettingsGroup/GuestAccountPrompt. Existing themed buttons and empty/error widgets
  reused instead of adding redundant LsPrimaryButton/LsEmptyState wrappers.
- Home utility, content, result and LAB cards share neutral white surface. D-Day
  hero stacks below schedule name; Home search compact variant. No meal logic edits.
- MY private dashboard uses grouped surfaces and Trend→Timer navigation rows.
  Guest CTA already existed in source; no device evidence proves why old button
  was missed. Now a dedicated above-fold prompt hides auth-only MY modules.
- Settings profile/auth groups hide for Guest; local school and study preferences
  remain usable under existing guest policy. Logout bottom above deletion.
- Materials pageSize10 (sentinel11), subsequent10, explicit load-more preserved;
  exam→general stream boundary tests adjusted, ordering/query semantics unchanged.
- Tests: design_v2_test.dart contrast/Guest routes/plain semantic headers;
  mobile_ia_render_test.dart seven screen families plus Guest Settings, both sizes/
  scales and populated Materials; existing Auth/Meal/Study/Profile regression suite.
- Future/deferred: dark mode, new motion choreography, extra component wrappers,
  badges and any new analysis. Native widget animations unchanged. Catalogue and
  production auth/provider/DB/Storage configuration are outside this task.
