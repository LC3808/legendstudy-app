# Day 8 Study storage — proposal, NOT DEPLOYED

Reviewed:2026-09-14. **Pending Product Owner approval.**
Canonical behavior/UI: [Study v1](study-v1.md). SQL is intentionally outside the
migration discovery directory. No current migrations, profiles, Auth users or
production objects were changed. No live production/schema assumption is inferred
from having this file. Owner-run preflight remains required.

## Exact artifacts and execution order

1. Review [proposal SQL](../supabase/proposals/study_sessions.sql).
   Suggested future migration: `20260914000100_study_sessions.sql`; reconfirm a free
   chronological timestamp on approval. Promote identical reviewed SQL into a new
   migration only at that stage; never edit the three applied migrations.
2. Owner opens **LegendStudy / stlhijzpjfgwwdgunlsd** SQL Editor and runs
   [read-only preflight](../supabase/verification/study_sessions_preflight.sql).
   Proposed objects must be absent; auth roles/users/uid function must exist.
   If any object conflicts or schema differs, STOP and review, do not replay/drop it.
   Save profile count/digest, columns, constraints, policies and grants privately.
3. After approval only, execute the entire proposal file as one BEGIN…COMMIT block.
   No IF NOT EXISTS hides a mismatch. It does not seed data or modify profiles.
4. Run [postflight catalog SQL](../supabase/verification/study_sessions_catalog.sql)
   and repeat preflight profile metadata queries. Expected: one new table, generated
   duration, 7 named CHECKs, PK/FK, one non-PK index, 3 owner policies, RLS enabled,
   immutable invoker helper, zero rows, all Day 7 profile evidence unchanged.
5. Actual authenticated REST acceptance follows; SQL Editor SET ROLE is not proof.
   Deploying successfully is not client acceptance and not Day 8 COMPLETE.

## Table and interval contract

| Field | Contract |
|---|---|
| id | UUID primary key, generated once by device and retained through retries |
| user_id | UUID NOT NULL DEFAULT auth.uid(), FK auth.users(id) ON DELETE CASCADE |
| mode | text study or mock_exam |
| status | text completed or cancelled; no cloud active status |
| title | nullable trimmed text1..80characters; required for mock |
| subject | nullable trimmed display text1..40characters; no guessed taxonomy FK |
| planned_duration_seconds | NULL for study; integer60..43200 required for mock |
| started_at / ended_at | finite timestamptz, ordered, totalspan<=24hours |
| active_segments | required JSON array of up to256 ordered nonoverlapping integer millisecond pairs relative to started_at |
| duration_seconds | stored generated integer: floor(sum(active milliseconds)/1000); no client INSERT grant |
| created_at | server now(), no client INSERT grant |

No updated_at because accepted records are immutable for clients. No duplicated
submitted flag, running_since, event log, Focus preferences or scoring data.
Empty segments allowed only for cancelled zero-duration records; completed requires
at least1second. Pause gaps allowed, overlap/out-of-order/negative/fractional/outside
span rejected. Mock active time cannot exceed its plan. Finite past dates accepted;
no current_date/now CHECK that becomes invalid as time passes. Timestamps are
client anchors, not server-attested study evidence. Day totals use raw intervals,
not rounded duration_seconds. No profile row prerequisite: user FK is auth.users.

Text trimming follows the existing profile convention: ASCII space/tab/newline/
carriage-return/form-feed/vertical-tab. Client normalizes whitespace and checks
Unicode scalar length matching PostgreSQL char_length, not UTF-16 code units.
The bounds are proposed product decisions, not official examination requirements.

CHECKs: study_sessions_mode, status, time_bounds, title, subject, mode_fields, duration.
The immutable helper also raises CHECK-violation SQLSTATE23514 for malformed
interval arrays or span. Catalog expectation is **7 named CHECKs**, plus generated
duration NOT NULL and PK/FK. The helper uses
no table access; SECURITY INVOKER, empty search_path and bounded traversal.

Index `(user_id, started_at DESC, id DESC)` supports owner/window history and keyset
pagination. No unnecessary mode/status index at v1 volume. The24h span bounds query
lookback without requiring an ended_at index. Analyze plans after realistic volume.

## Privilege and idempotency contract

- anon/PUBLIC: no table privileges, no helper execution, no public history endpoint.
- authenticated: SELECT/DELETE with owner RLS; column INSERT only for id, mode, status,
  title, subject, plan, start, end, segments. user_id defaults to current JWT. No explicit
  owner/duration/created_at INSERT, UPDATE grant or UPDATE policy.
- service_role: existing backend-only model, CRUD; never shipped to Flutter.
  No service-role policy needed; preflight checks expected BYPASSRLS role.
- Helper EXECUTE auth/service only; invoker does not bypass any policy. Role grants
  and policies are explicit because Supabase default grants must not be assumed safe.

Repository receives no owner from presentation. Immutable local owner and request
JWT must match; request-scoped auth prevents A→B switch at dispatch reassigning a
queued payload. Owner comparison alone with a mutable global SDK client is not enough.
Insert with Prefer resolution=ignore-duplicates, return=representation / on_conflict=id.
Resolve empty/uncertain response by owner SELECT and whole normalized payload equality.
Never use merge-duplicates: even own client UPDATE is forbidden. A retry after lost
HTTP success resolves to exactly one row. Collision with another owner's UUID is
not overwrite authorization; inaccessible/different result is a conflict.

Profile editing, school pair and D-Day pair code/policies/grants remain byte-for-byte
unchanged. Study performs no profiles INSERT/UPDATE/DELETE. Acceptance compares Day 7
fields/catalog before/after, and retains Auth users after fixture cleanup.

## Actual JWT/REST acceptance plan (after approval/deployment)

Use existing owner-confirmed A/B accounts with passwords through local getpass and
local public config. Do not print response bodies, JWT, headers/passwords/keys. No
service-role client or SQL SET ROLE substitute. Write a dedicated opt-in verifier
at implementation time with named assertions, safe status/count diagnostics, and
finally-cleanup of only run-owned random session UUIDs registered before dispatch.
No verifier or production mutations were executed during this proposal task.

1. Confirm project, login A/B, current identities and existing profile snapshots
   without logging values. Do not require all Study history empty or touch old rows.
2. A INSERT study completed interval example[[0, 60000],[120000, 180000]]; SELECT
   owner row and require duration_seconds120 and exact bounds/fields, not just HTTP200.
3. A INSERT cancelled zero, normal study with NULLplan and custom mock with plan60,
   active<=60000ms; no exams/profile row required. All expected returned values checked.
4. Boundary accepts:1second completed, 24h span, 256 valid intervals, title80, subject40,
   mock60 and43200, finite historical timestamps, consecutive touching intervals.
5. Reject: invalid mode/status;empty/whitespace/overlong required title;study plan;
   mock missing title/plan, plan59/43201;negative/reversed/nonfinite dates, span>24h;
   completedzero;mock exact active milliseconds beyond plan, including subsecond excess.
6. Reject arrays:null/object/257entries, nonpair, string/nullnumber, fractional/negative
   offset, zero/reversed interval, overlap/out-of-order, outside span. Require DB error
   and absence of the attempted UUID, not only an HTTP failure. Huge payload behavior
   and REST request-size limits are separate API hardening acceptance.
7. Reject attempts to supply user_id, created_at, duration_seconds; forbid own UPDATE
   and merge-upsert too. Confirm canonical existing row unchanged after each attempt.
8. Retry identical UUID, payload and ignore-duplicates; SELECT shows one matching row.
   Simulate lost success response; retry also one row. Different payload under same
   UUID must surface conflict and never mutate original.
9. B SELECT A id yields[]; B UPDATE A must fail (UPDATE ungranted), B DELETE A returns
   no deleted row; confirm A still exists unchanged. B explicit A ownership INSERT
   fails column grant/RLS protection. B attempting A UUID cannot overwrite or claim it.
   B can create/read/delete its own session. Anon cannot read/write/delete.
10. Verify owner today/seven-day algorithm with midnight pause, zero dates, multi-device
    overlap, mode filters and local pending/server duplicate merge. Expected total
    uses unioned intervals; do not assert sum of overlapping mode subtotals.
11. Compare pre-existing profile display_name/grade_level/NEIS/D-Day snapshot and row
    count after tests. Never modify these fields just to create Study fixtures.
12. Finally A/B DELETE only registered run UUIDs, verify absence through each owner's
    real JWT; handle uncertain INSERT by including attempted IDs in cleanup. Existing
    history and Auth users retained. On failed cleanup report IDs privately for owner
    action; never claim fixture-free or COMPLETE without evidence.

## Rollback

[Exact rollback SQL](../supabase/verification/study_sessions_rollback.sql) drops only
this proposed table and helper, without CASCADE. This loses Study history: Owner must
pause client writes/outbox retries, export any records and explicitly approve first.
Dependency conflicts STOP; no forced drop of future scoring objects. Profiles,
existing migrations and Auth users remain. Re-enable only compatible clients after
rollback; keep schema-version-incompatible outbox pending for review, never silently
throw it away. Nothing has been applied now, so no rollback should run now.

## Static validation evidence

- PASS: all four proposal/verification SQL files parse; helper PL/pgSQL body parses.
- Parser: pglast 8.4, matching repository review requirements, PostgreSQL 18.4 grammar.
  Production is owner-reported PG 17.6: this is not execution/compatibility proof.
- PASS: offline scope assertions for one new table, 12 columns, 7 named CHECKs,
  3 owner policies, narrow INSERT contract and absence of profile mutations.
- PASS: all three applied migrations byte-identical to starting commit.
- PASS: changed Wiki local links resolve, git diff --check, no credential-shaped
  added values. No Flutter/native/config/test implementation changed.
- Flutter tests/builds, PostgreSQL execution, real JWT and device lifecycle tests NOT
  RUN for this documentation/proposal task. Production preflight/catalog/JWT and
  full timer runtime remain future approval gates.
