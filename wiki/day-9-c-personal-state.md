# Day 9-C2 — Bookmark + Recent Views

Status: **implemented / local validation PASS**. This record describes C2;
C3 is now implemented separately. Recent semantics below reflect the later v2 contract.

## Contract

- Bookmark and recent-view identity is always `content_items.id`.
- Existing `BookmarkRepository`, `RecentViewRepository`, Supabase
  implementations, and `authStateProvider` are reused; the inline increment below
  adds a bounded membership read while retaining existing writes/RLS. No migration,
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
- The keyed bookmark provider now selects from a shared owner-scoped store,
  clears on identity changes, and discards stale async results. Account A state
  cannot appear for account B or after logout.

## Validation

`test/day9_c2_personal_test.dart` covers authenticated saved/unsaved state,
add/delete, duplicate-tap protection, guest no-write, A/B isolation, one-time
recent recording across rebuild, recent failure visibility, and fresh-entry
recording. Full Flutter regression and platform-build results are recorded in
`wiki/current-status.md` after the closeout.

C3 completes the list integration in [day-9-c-personal-lists.md](day-9-c-personal-lists.md).


## Materials inline bookmark — 2026-09-20

### Single state and bounded reads

`bookmarkStateProvider(content_items.id)` remains the UI seam for both detail and
search. `bookmarkStoreProvider` owns membership and per-ID operations; no second
search-only saved set exists. `fetchBookmarkedIds` queries only `content_item_id`
with session-derived `user_id`, an `IN` filter and limit 100. Distinct input IDs
are capped at 100; the controller splits larger sets. Same-turn registrations
coalesce (250 IDs → 100/100/50), with pagination querying only unseen IDs.
`fetchOwnBookmarks` still has its existing recent-100 list contract and is never
used to infer that older bookmarks are absent. Schema, RLS, write/upsert/delete
contracts and the legacy single-ID repository method remain intact.

### Optimistic and lifetime contract

- Explicit save/unsave immediately flips the shared icon; that ID is busy until
  completion. Rapid repeat taps do not enqueue writes; other IDs remain usable.
- Success retains the state and invalidates the saved-list provider. Failure
  restores the prior state with a safe Korean message, never a raw exception or
  a search-wide error. Unknown membership is loading/retry, never a writable guess.
- Pending IO keeps the store alive across tile disposal/refresh/re-entry, avoiding
  duplicate mutations. Container disposal and stale owner completions are ignored.
  Membership is an in-memory session cache, not a cross-device realtime promise.
- Owner/loading/error identity changes clear the store and advance its generation;
  A→Guest→B and delayed A reads/writes cannot populate B. Same-owner token refresh
  does not clear the cache or interrupt a mutation. Detail's post-save recent/error
  callback also checks the original owner before acting.
- Inline save does not fabricate a detail visit/recent view. Existing meaningful
  recent-view behavior inside detail remains unchanged.

### Search/Guest/UI contract

A keyed 48×48 minimum icon button shares the row's top metadata line without
truncating its long title. Filled/outline state, selected semantics and Korean
save/unsave/loading/busy/retry tooltips communicate state. Tapping it does not
open detail; title/row navigation continues to use the existing route.

Guest sees a login-required dialog and may cancel or push `/auth`. Existing auth
return pops to the mounted Materials route on success/cancel, with no auto-save.
Query, grade/year/month/exam-type/subject/content-type filters, loaded pages and
scroll stay intact. Neither a bookmark mutation nor login invalidates search.

### Evidence and limits

- `inline_bookmark_state_test.dart`: 8 tests for real query construction against
  mocked HTTP, batch counts/pagination, read retry, optimistic add/delete rollback,
  duplicates, owner transitions/stale IO, token refresh and disposal/re-entry.
- `inline_bookmark_journey_test.dart`: 2 real-router fixture journeys at 1×/2×;
  Guest login/cancel, all six filters/query/pages/scroll, no auto-save, icon-vs-row
  taps, list→detail save and detail→list unsave, failure and A→Guest→B.
- `day9_c2_personal_test.dart`: added duplicate-tap regression so optimistic
  membership never triggers detail recent-view recording before server success.
- Full **493 PASS / 1 existing skip**; native iOS fixture journeys **2 PASS**;
  analyze, Android debug/iOS simulator builds, credential scan and diff check PASS.
- 360×640 widget and native iOS renders reviewed at 1×/2×, including long Korean
  titles and failure message. Evidence local in `/private/tmp/legendstudy-core-ui/inline-*.png`
  and `/private/tmp/legendstudy-inline-native/`; test account/repositories are doubles.
- Production bookmark/account E2E and physical-device acceptance remain Owner
  validation. No Production writes or schema changes were performed. Existing
  policy/Auth/deletion release blockers remain; **RELEASE READY NO**.
