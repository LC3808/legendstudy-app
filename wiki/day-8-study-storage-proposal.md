# Day 8 Study storage — deployed and JWT accepted

Reviewed: 2026-09-14. **Production migration/postflight and full A/B JWT acceptance PASS (Owner-reported).**
Canonical behavior/UI: [Study v1](study-v1.md). Completed sessions only are stored
in cloud. Cancellation remains local, excluded from totals. No cloud status column.
No production calls, Flutter changes or edits to the three previously applied migrations.

## Exact artifacts and execution order

Use [copy-ready migration package](day-8-study-migration-package.md): each execution
step contains one complete SQL block, copied verbatim from its checked-in SQL file.

1. Owner confirms **LegendStudy / stlhijzpjfgwwdgunlsd** in Dashboard SQL Editor.
2. Run [preflight](../supabase/verification/study_sessions_preflight.sql). Both new
   objects must be absent; roles/auth.users/auth.uid present; CREATE/REFERENCES true;
   two generated-expression primitives immutable (`i`). Save profile count/digest
   and existing metadata. Conflict, unexpected privilege or schema: STOP and review.
3. Execute [20260914000100_study_sessions.sql](../supabase/migrations/20260914000100_study_sessions.sql)
   as one block. [Proposal mirror](../supabase/proposals/study_sessions.sql) is identical;
   do not execute both. No replay-safe IF NOT EXISTS conceals conflicts.
4. Run [catalog verification](../supabase/verification/study_sessions_catalog.sql).
   Expected: 11 columns, 6 named CHECKs, PK + auth.users FK, one non-PK index,
   3 owner policies, RLS on/FORCE off, immutable invoker helper, zero initial rows.
   authenticated: SELECT/DELETE/id INSERT/helper EXECUTE true; UPDATE and INSERT
   owner/duration/created false. anon: all checked access false. Compare protected
   table metadata and profile count/digest with preflight, under the same UTC setting.
5. Run real JWT/REST acceptance below after successful catalog verification. SQL
   Editor SET ROLE is not substitute evidence. Application alone is not Day 8 COMPLETE.

## Table and interval contract

| Field | Contract |
|---|---|
| id | UUID primary key, generated once by device and retained through retries |
| user_id | UUID NOT NULL DEFAULT auth.uid(), FK auth.users(id) ON DELETE CASCADE |
| mode | text study or mock_exam |
| title | nullable trimmed text1..80characters; required for mock |
| subject | nullable trimmed display text1..40characters; no guessed taxonomy FK |
| planned_duration_seconds | NULL for study; integer60..43200 required for mock |
| started_at / ended_at | finite timestamptz, ordered, totalspan<=24hours |
| active_segments | required JSON array of up to256 ordered nonoverlapping integer millisecond pairs relative to started_at |
| duration_seconds | stored generated integer: floor(sum(active milliseconds)/1000); no client INSERT grant |
| created_at | server now(), no client INSERT grant |

No updated_at because accepted records are immutable for clients. No duplicated
submitted flag, running_since, event log, Focus preferences or scoring data.
All stored sessions require at least 1 second; empty/zero-duration intervals cannot
produce a stored completed record. Pause gaps allowed, overlap/out-of-order/negative/fractional/outside
span rejected. Mock active time cannot exceed its plan. Finite past dates accepted;
no current_date/now CHECK that becomes invalid as time passes. Timestamps are
client anchors, not server-attested study evidence. Day totals use raw intervals,
not rounded duration_seconds. No profile row prerequisite: user FK is auth.users.

Text trimming follows the existing profile convention: ASCII space/tab/newline/
carriage-return/form-feed/vertical-tab. Client normalizes whitespace and checks
Unicode scalar length matching PostgreSQL char_length, not UTF-16 code units.
The bounds are approved product decisions, not official examination requirements.

CHECKs: study_sessions_mode, time_bounds, title, subject, mode_fields, duration.
The immutable helper also raises CHECK-violation SQLSTATE23514 for malformed
interval arrays or span. Catalog expectation is **6 named CHECKs**, plus generated
duration NOT NULL and PK/FK. The helper uses
no table access; SECURITY INVOKER, empty search_path and bounded traversal.

Index `(user_id, started_at DESC, id DESC)` supports owner/window history and keyset
pagination. No unnecessary mode index at v1 volume. The24h span bounds query
lookback without requiring an ended_at index. Analyze plans after realistic volume.

## Privilege and idempotency contract

- anon/PUBLIC: no table privileges, no helper execution, no public history endpoint.
- authenticated: SELECT/DELETE with owner RLS; column INSERT only for id, mode,
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

## Actual JWT/REST acceptance plan (after owner deployment)

Use existing owner-confirmed A/B accounts with passwords through local getpass and
local public config. Do not print response bodies, JWT, headers/passwords/keys. No
service-role client or SQL SET ROLE substitute. Write a dedicated opt-in verifier
at implementation time with named assertions, safe status/count diagnostics, and
finally-cleanup of only run-owned random session UUIDs registered before dispatch.
Dedicated verifier has completed full Owner-run acceptance. See the latest
production/JWT section below for the final narrower execution scope and safety rules.

1. Confirm project, login A/B, current identities and existing profile snapshots
   without logging values. Final verifier requires A/B visible Study history empty;
   existing rows cause STOP and are never automatically deleted.
2. A INSERT study completed interval example[[0, 60000],[120000, 180000]]; SELECT
   owner row and require duration_seconds120 and exact bounds/fields, not just HTTP200.
3. A INSERT normal study with NULL plan and custom mock with plan 60,
   active<=60000ms; no exams/profile row required. All expected returned values checked.
4. Boundary accepts:1second completed, 24h span, 256 valid intervals, title80, subject40,
   mock60 and43200, finite historical timestamps, consecutive touching intervals.
5. Reject: invalid mode;empty/whitespace/overlong required title;study plan;
   mock missing title/plan, plan59/43201;negative/reversed/nonfinite dates, span>24h;
   completed zero;mock exact active milliseconds beyond plan, including subsecond excess.
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
throw it away. Production is now Owner-applied; this destructive rollback remains
a reference only and is not authorized by the JWT acceptance task.

## Aggregate query / repository contract

No aggregate RPC is added in v1. Home and Study share one `fetchCurrentStudyWindow`
result for today plus the previous six **KST** dates. Server SELECT is owner-scoped,
window-bounded and keyset-paginated; no lifetime-history download. Take one fixed
window anchor per fetch; next midnight/foreground invalidates it.

- Let S = first KST midnight and E = midnight following the last day, converted to
  UTC instants. Fetch `started_at >= S - 24 hours AND started_at < E AND ended_at > S`.
  The 24-hour CHECK makes this complete for all potentially overlapping sessions.
- Projection: id, mode, started_at, ended_at, active_segments, duration_seconds.
  Owner derives from current SDK session; apply explicit user_id filter plus RLS.
  Order started_at DESC, id DESC. Next cursor is `started_at < cursorStart OR
  (started_at = cursorStart AND id < cursorId)`, in addition to original bounds.
- Page size 100; maximum 2,000 records per window plus one overflow sentinel.
  Stop at 20 full pages and request one sentinel row; if present, return explicit
  summary-limit error, retain last complete cached summary, never show partial sum
  as complete or zero. No automatic infinite retry. This is a client resource guard,
  not a new DB record quota. Frequent overflow or poor device performance triggers
  separately reviewed server aggregation; do not silently loosen to lifetime fetch.
- Convert offsets to instants using integer millisecond arithmetic; clip to [S,E).
  Deduplicate local/server UUIDs, union active intervals across sessions/devices,
  then split the union at each KST midnight. Sum milliseconds and floor only for
  display. Seven returned date entries include zero days. Mode-filtered union is
  separate; overlapping mode totals are not a stacked/additive total.
- Example: active23:50–23:55 and00:05–00:20 gives5min on day1 and15min on day2.
  A second device recording00:10–00:15 must not increase day2 above15min.
- Current-owner locally completed unsynced records merge into the same UUID/interval
  set. Running/paused/cancelled records do not enter summary. Retry uses fixed UUID;
  no separate local+server addition. Account epoch guards cover the whole fetch.
- This bounded SELECT design suits v1; history browsing can separately page records
  without accumulating all past pages in the summary provider. Concurrent late
  uploads are reconciled on refresh; no transactional multi-page snapshot is promised.

Timestamptz preserves instants; KST is an explicit display/grouping timezone, not
canonical wall-clock text. Generated columns derive rather than accept a supplied
value ([PostgreSQL17 generated columns](https://www.postgresql.org/docs/17/ddl-generated-columns.html)).
Elapsed subtraction then EXTRACT(epoch FROM interval) uses immutable operations,
confirmed against the [PG17 catalog](https://github.com/postgres/postgres/blob/REL_17_STABLE/src/include/catalog/pg_proc.dat)
and checked by preflight; do not replace it with timezone-sensitive timestamp extraction.
[Datetime semantics](https://www.postgresql.org/docs/17/functions-datetime.html) and
[RLS semantics](https://www.postgresql.org/docs/17/ddl-rowsecurity.html) underpin the contract.

## Static validation evidence

- PASS: migration/proposal byte equality; SQL and PL/pgSQL grammar; pre/postflight
  restricted to read-only SELECT/transaction/session-setting statements.
- PASS: offline scope checks for 11 columns,6 CHECKs,3 owner policies,narrow grants,
  interval/generated-duration guards and unchanged hashes of all3 applied migrations.
- PASS: 2 checker tests,including11 rejected contract mutations (overlap/boundary,
  limits,UPDATE grants,owner policy,definer escalation,status and protected-table drift).
- PASS: copy-ready SQL blocks equal source files; Wiki local links; credential-shaped
  added-value scan; git diff --check. No Flutter/native implementation changed.
- Parser: repository-pinned pglast8.4 (PG18.4 grammar). PG17 documentation/catalog
  reviewed; actual PG17 execution and live A/B JWT acceptance NOT RUN. Local PostgreSQL
  server was not available. Static checks do not replace deployment acceptance.
- Reproduce with Python environment containing supabase/review/requirements.txt:
  `python supabase/review/check_study_storage.py` and
  `python -m unittest discover -s supabase/review -p test_check_study_storage.py -v`.
- Flutter tests/builds not rerun: no Flutter change. Day7 COMPLETE preserved; Day8
  remains pending Owner application and real JWT validation,then implementation.

## Production migration accepted / JWT verifier ready (2026-09-14)

Product Owner reports migration and postflight PASS: columns, constraints, index,
RLS, owner SELECT/INSERT/DELETE, grants, immutable helper, profile preservation and
interval calculation. study_rows=0; profile_rows=0;
profile_digest=d41d8cd98f00b204e9800998ecf8427e; interval_example_pass=true.
Authenticated SELECT/DELETE/id INSERT/helper EXECUTE true; UPDATE and INSERT of
user_id/duration_seconds/created_at false. Anon checked privileges all false;
service_role normal; existing public RLS/constraint baseline unchanged.
This is Owner-run evidence, not a migration or live test executed by Codex.

[Dedicated verifier](../tool/verify_study_sessions_jwt.py) is ready with
`--preflight-only` and hidden getpass input; no password files or credential logging.
CLI requires an interactive terminal and external public config, pins the project,
and refuses redirects. It checks A/B login identity, distinct UUIDs and exact owner
counts. Per the final request, **any existing A/B Study row causes STOP**, not automatic
fixture deletion. Existing profiles may exist: they are snapshotted/read only.

Full execution covers normal study/generated120seconds, mock60/43200 boundaries,
24h/256interval boundaries, malformed/overlapping/outside/zero/negative intervals,
forbidden generated/owner/created fields, modes/plans/text, B SELECT/DELETE denial,
A-row preservation, own UPDATE denial and owner DELETE. Counts and returned rows
are checked, not HTTP status alone. Failures show stage/case,status and controlled
codes only; no raw body/header/credential. Auth users are verified via /auth/v1/user
and only the verifier login sessions are logged out with scope=local.

Random IDs are checked absent and registered before INSERT so uncertain network
success is included in finally-cleanup. Only those IDs are ever deleted, through A/B
JWTs. Cleanup failure makes the entire run fail; full A/B counts must return to their
baseline and profile snapshots must match. Unrelated concurrent records are not deleted.
Preflight-only makes no Study/profile mutation and reports cleanup SKIP.

**Count evidence boundary:** real JWT counts cover A/B's RLS-visible rows only.
Global study_rows=0 is the Owner postflight baseline, not something a restricted
JWT can prove for all users. The verifier labels this explicitly. Owner can rerun
the existing read-only catalog count after acceptance to confirm global0. No service
key, SQL role elevation or public count endpoint is introduced to bypass this boundary.

Python syntax and13 offline tests PASS: full flow,preflight-only,existing-row STOP,
missing counts,uncertain-write cleanup,cleanup failure,generated-value mismatch,
RLS leak,profile preservation,redaction,wrong project,identical users and transport
count/redirect handling. These use fake transport; actual Study JWT acceptance is
**PENDING** until Owner executes. The earlier broader idempotency/aggregation plan
remains separate coverage; this verifier does not claim to test Flutter aggregation.
Credential-pattern scan,diff checks and unchanged migration/Flutter scope PASS.
No live production request,fixture creation,Flutter/DND/mock UI,push,PR or merge here.

## Generated-column rejection correction (2026-09-14)

Owner runtime: login_preflight,normal_study,mock_exam,interval_validation PASS.
Direct duration_seconds INSERT returned HTTP400/428C9; the old verifier expected
only403/42501 and stopped. Cleanup,A/B baseline restoration,profile/school/D-Day
preservation and retained Auth users all PASS (Owner-reported). Full acceptance
still pending; later stages were not reached in that run.

The duration_seconds test now accepts exactly (400,428C9) generated_always or
(403,42501) insufficient_privilege. user_id and created_at are ordinary defaulted
columns,not generated columns: their tests accept only (403,42501),including B
attempting A ownership. Their actual runtime responses were not in the supplied
trace and remain to be verified on rerun. No blanket400 allowance; unrelated
validation still requires400/23514. Every accepted rejection still requires row
absence through both identities. Cleanup logic is unchanged.

References: [PostgreSQL error codes](https://www.postgresql.org/docs/16/errcodes-appendix.html)
and [PostgREST error mapping](https://docs.postgrest.org/en/v14/references/errors.html).
These document428C9/42501 semantics and authenticated42501→403; they are not a
claim of an additional production request by Codex.

17 offline tests PASS,including exact field/status/code matrix,unrelated-error
rejection,absent-row enforcement and both generated-rejection paths through full
cleanup. Syntax,credential-pattern and diff checks PASS. No migration/schema,
production,Auth-user or Flutter change; no push/PR/merge.

## Full JWT acceptance accepted / Flutter implementation (2026-09-14)

Owner explicitly confirms all real A/B JWT acceptance stages PASS after the generated
column rejection fix, including fixture cleanup and Auth retention. Earlier pending
checkpoints above are historical. No production schema change or repeat acceptance
mutation was performed by the Flutter implementation task. Study core now uses this
immutable contract. Flutter guest native runtime is PASS; A/B Flutter save/restore/
isolation/pending verification remains separately pending. See current-status.md.
