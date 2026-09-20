# Day 9-C2 — Bookmark + Recent Views

Status: **implemented / local validation PASS**. This record describes C2;
C3 is now implemented separately. Recent semantics below reflect the later v2 contract.

## Contract

- Bookmark and recent-view identity is always `content_items.id`.
- Existing `BookmarkRepository`, `RecentViewRepository`, Supabase
  implementations, and `authStateProvider` are reused unchanged. No migration,
  schema, RLS, grant, RPC, or production write was made.
- Signed-out reads remain empty/false and personal writes remain guarded by the
  existing `SignedOutException` contract. No guest local bookmark or sync layer
  was added.

## Detail behavior

- The detail page has a 48px-height bookmark control with loading, saved,
  unsaved, mutation, and failure states. Authenticated mutations call only the
  existing add/delete methods; duplicate saves remain idempotent at the
  repository contract and rapid taps are serialized/ignored while mutating.
- Guest save pushes login and returns to the same detail without automatically
  saving. No personal repository write occurs until an authenticated explicit save.
- A resolved, active detail qualifies at most once per owner/detail lifecycle:
  10 foreground seconds OR external resource/original open attempt OR successful
  save. A quick revisit alone does not record. Even a failed launch is intent,
  not proof of PDF reading; external browser dwell is not counted. Rebuilds do
  not repeat the write. The repository supplies owner and server `viewed_at`;
  the UI supplies neither. See [v2 contract](day-11-account-personal-feedback.md#meaningful-recent-views-v2).
- Missing/error detail results never record a view. Recent-write failure is
  non-blocking and leaves the detail visible.
- The keyed bookmark provider watches auth identity, reloads on account
  changes, and discards stale async results, preventing account A state from
  appearing for account B or after logout.

## Validation

`test/day9_c2_personal_test.dart` covers authenticated saved/unsaved state,
add/delete, duplicate-tap protection, guest no-write, A/B isolation, one-time
recent recording across rebuild, recent failure visibility, and fresh-entry
recording. Full Flutter regression and platform-build results are recorded in
`wiki/current-status.md` after the closeout.

C3 completes the list integration in [day-9-c-personal-lists.md](day-9-c-personal-lists.md).
