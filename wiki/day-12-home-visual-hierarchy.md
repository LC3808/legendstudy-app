# Day 12 — Home Information Architecture & Visual Hierarchy

Status: **implemented; local validation complete**.

## Final Home order

1. D-Day — exam goal and countdown
2. 나의 공부 시간 — current learning activity
3. 우리학교 급식 — school-life information
4. 자료 검색 — material discovery and quick filters
5. 최근 업데이트 — new material discovery
6. 최근 본 자료 — personal re-entry history

This preserves the existing providers, navigation and data-fetching semantics.
No feature, database, Supabase, publication or personal-state contract changed.

## Visual identity

Home semantic accents are centralized in `AppTokens` and used as restrained
accents rather than full-card fills:

| Section | Accent |
|---|---|
| D-Day | brand orange |
| 나의 공부 시간 | indigo/purple |
| 우리학교 급식 | green |
| 자료 검색 | blue icon/header |
| 최근 업데이트 | amber |
| 최근 본 자료 | violet |

Daily cards retain neutral warm surfaces and borders. Accent cards use a soft
left gradient band; content text remains neutral for contrast. Search and recent
sections use a consistent section-title row with an icon and accent color.

## Study cleanup

The duplicate `오늘의 공부` heading was removed. The section is now titled only
`나의 공부 시간`. With a completed record, the duration is the primary value
with `오늘 공부` as its label. With no record, the existing concise empty state
`오늘 공부 기록이 아직 없어요.` remains. No weekly metric or unsupported goal
data was invented.

## Preserved behavior and accessibility

- Meal today/tomorrow, 17:00 KST priority, midnight refresh and expansion remain.
- Recent Updates and Recent Views remain independently collapsed to two and
  expandable to six.
- Search, D-Day, Study navigation and detail routes remain unchanged.
- Day 11 meaningful recent-view rules, Auth, Feedback and MY are untouched.
- Section titles include icon, text and layout cues; color is not the sole signal.
- Existing 48px action targets and 1x/2x text-scale coverage remain.
- 360×640 and 428×926 Home coverage remains in the existing widget suite; the
  simulator screenshot was reviewed at the available iPhone viewport.

## Validation

- Focused Home/D-Day/Study/Meal files passed sequentially.
- Full Flutter suite: 341 passed, one opt-in read-only network skip.
- Flutter 3.47.3 analyze: clean.
- Android debug build: pass without dependency-validation skip.
- iOS simulator build: pass without external xcconfig.
- iOS simulator Home screenshot: `/tmp/legendstudy-day12-home.png`.
- Physical iPhone Profile launch: build/install/launch and VM service attach pass.
- `git diff --check`: pass.

No Production mutation or Day 11 feedback draft deployment was performed.
