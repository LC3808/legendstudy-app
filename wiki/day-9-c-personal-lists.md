# Day 9-C3 — Saved / Recent UI + MY Integration

Status: **implemented / local validation PASS**. Day 9-C is complete for the
scoped C1-C3 material flow; publication itself remains unexecuted.

## Personal lists

- `/my/saved` and `/my/recent` retain their existing routes and now render
  authenticated personal data with loading, empty, error, and retry states.
- Bookmark and recent rows preserve repository server ordering, then hydrate
  `content_item_id` values through the public `content_items` projection.
  Supabase uses one bounded `id IN (...)` query per list (maximum 100 rows); the
  personal row order is restored client-side.
- Missing, inactive, or deleted content is safely omitted. No private or
  inactive fetch path, cached private content, or schema/RLS bypass exists.
- Guest entry shows a login-required state and performs no personal or content
  cloud request. Auth changes rebuild the provider and discard prior-account
  state.
- List cards navigate to the existing detail route. Returning from detail
  invalidates the relevant list, reflecting bookmark and recent changes.
  The later inline/detail shared bookmark store also invalidates the saved list
  on a successful mutation. No realtime/cross-device synchronization was added.

## Home and accessibility

Home's existing `최근 본 자료` placeholder now uses the same small recent-list
widget. Cards retain the LegendStudy visual language, provide a minimum 48px
interactive surface, wrap long titles, and were checked at 360×640 and 2× text.

## Publication readiness

The scoped A–Q checklist is PASS for search/detail, resource grouping and safe
targets, C2 bookmark/recent behavior, Saved/Recent lists, MY routes, search
back-state, accessibility, inactive Pilot C public exposure, and no DB/schema/
RLS change. Therefore **PUBLICATION READY = YES** for this implementation gate.
This is readiness only: Pilot C remains inactive and no publication or
production mutation was performed. Official Xcode 27/iOS15/arm64 compatibility
is configured in-repository; default simulator validation passes.


## Owner title and badge consistency — 2026-09-25

Saved/recent reuse materialDisplayTitle and canonical materialTypeLabel, with one
existing batch exam metadata provider per displayed list. csat is 수능, canonical
mock types are 모의고사; unavailable exam metadata stays generic 시험 자료.
No stored title rewrite, bookmark/recent mutation or new classification system.
[Latest UI correction](day-9-c-resource-detail.md#owner-final-title-and-classification-corrections--2026-09-25).


## Saved/recent visual hierarchy — 2026-09-25

Both MY lists share the same navy/white small badge and white card with existing
border token, elevation0. Secondary date/neutral delete and primary title retained.
No taxonomy, layout, navigation, persistence or deletion behavior changed. Home
mode excluded from the new badge/border treatment. Analyze/focused26PASS including
8 responsive combinations; device recheck pending. [Design override](design-system.md#savedrecent-card-hierarchy--owner-override-2026-09-25).
