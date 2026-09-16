# Day 10-B — Home Polish v2

Status: **implemented; local/static/widget validation PASS; physical iPhone
interactive validation blocked by CoreDevice launch timeout.**

## Scope

Home now supports:

- today/tomorrow meals using KST (`Asia/Seoul` UTC+9 semantics)
- 17:00 KST dinner/tomorrow priority
- automatic re-evaluation at the next 17:00 or 00:00 boundary and on app resume
- recent updates fetched with a Home-only limit of 6, collapsed to 2 and
  expandable to 6
- recent views fetched with an account-scoped limit of 6, collapsed to 2 and
  expandable to 6

The Materials full search/list and MY full recent list contracts remain
unchanged. Guest recent-view behavior and C3 account isolation are preserved.

## Meal policy

- Before 17:00 KST, today’s available meals are primary; tomorrow is available
  from the existing expand interaction when present.
- From 17:00 KST, today’s dinner is primary when it exists. Tomorrow follows
  through expansion.
- From 17:00 KST without dinner, tomorrow becomes primary when available.
- If neither primary nor tomorrow data exists, the existing minimal empty state
  remains; no empty tomorrow section is created.
- `Meal` meal types remain open-ended. The v2 priority rule specifically uses
  `석식`; other types continue to render under the existing model contract.
- The lifecycle-owned timer schedules only the next meaningful boundary, never a
  1-second polling loop. Resume invalidates the clock and both meal queries.

## Recent sections

Both Home sections use independent expansion state and the same `더보기` /
`접기` affordance. The initial query/hydration is bounded to six items, so
expansion does not issue another request. Full exploration remains in 자료
찾기 and MY → 최근 본 자료.

## Validation

- Day 10-B widget/policy tests cover meal 16:59, 17:00, dinner/no-dinner,
  tomorrow/no-tomorrow, KST midnight/device-timezone independence, recent
  updates 0/1/2/3/6/7+, recent views 0/1/2/3/6/7+, and guest read safety.
- Existing Day 7 school, Day Target, NEIS attribution and C2/C3 tests pass.
- Full Flutter suite: 335 passed, 1 opt-in read-only network test skipped.
- Flutter analyze: No issues found.
- Android `flutter build apk --debug`: PASS with dependency validation.
- iOS simulator build/run: PASS without external xcconfig; Home rendered on
  iPhone 16 Pro simulator. The existing AppLinks plugin lifecycle warning
  remains informational.
- iPhone Profile build: PASS, but Xcode/CoreDevice automated install/launch
  timed out before interactive Home verification. No Production data was
  changed.
