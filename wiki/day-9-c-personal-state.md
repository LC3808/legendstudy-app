# Day 9-C2 — Bookmark + Recent Views

Status: **implemented / local validation PASS**. Day 9-C overall remains
incomplete; C3 and MY/Saved/Recent list integration are not part of this task.

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
- Guest taps show a concise login-required message without calling a personal
  repository write.
- A resolved, active detail item records one recent view per detail lifecycle.
  Rebuilds and provider/theme/text-scale changes do not repeat it; leaving and
  re-entering creates a new event. The recent repository supplies the auth
  identity and server-side `viewed_at`; the client sends neither.
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
