# Shared MY / Application / Study / Student 360 foundation

Owner consolidated request 2026-10-08. Implementation candidates are not Production activation.
Canonical APP base: Store RC `claude/final-store-release-2026-10-08`; LAB base: latest Manus main.

## Preservation review (before new storage)

1. Occurred time is supplied separately from server recorded time. Corrections append an event with a supersedes relation; header edits retain before/after snapshots.
2. Application event facts remain immutable; completed APP Study segments remain untouched. No invented backfill.
3. Current application details may change only with revision checks and an event snapshot. Existing profile/target history limitations remain explicit; no reconstructed past school/target facts.
4. Every owner is the existing auth.users identity via profiles; no Web student identity.
5. Targets are interests; Applications are self-reported decisions; outcomes are events. No automatic target-to-application conversion. Essay does not require an Application.
6. Self reads/writes use auth.uid, lifecycle fences and RLS. Admin reads require admin_users through admin_operator; quality-only access is denied. Application/event deletion cascades through the existing profile/Auth lifecycle. No answer text in summaries; no cohort disclosure.
7. Study totals and comparable Essay deltas are derived views, not new facts or scores. Report DTOs reuse these facts; no report database/PDF engine.

## Production inventory (Owner read-only result)

Profiles: display_name exists; school identity is neis_office_code + neis_school_code; **no school_name column**. Name resolves through existing NEIS proxy. academic_status allows student/retaker/other; grade is nullable 1..3. No parent/teacher enum is invented.
Targets: UNIQUE NULLS NOT DISTINCT(user_id, university_id, admission_year); nullable intended_division already exists. Existing APP inserts omit division/year and delete by target row ID. Same-university multi-division requires replacing the unique constraint: Owner §74 STOP applies. Migration 20261008000500 is a candidate, NOT approved/applied. It builds normalized replacement uniqueness before dropping the old constraint and does not rewrite rows; rollback must stop once multiple divisions make the old uniqueness impossible. APP runtime regression is pending the pinned Flutter SDK.
Study: completed study_sessions with validated active_segments, include_in_study_total and user FK; no Web timer database. APP unions overlapping absolute intervals across sessions/devices before KST bucketing; week starts Monday. Unsynced local work/live drafts cannot be claimed by Web.
Application tables: absent at preflight, now applied by Owner as006. Application/event data uses existing profiles/Auth ON DELETE CASCADE; deletion function bodies are not modified. Verified personal/postconditions hashes match canonical lifecycle migration.

## Status

Signup predecessor is closed separately: Owner observed one signup grant, balance 3, linked delivery, no expiry and both UI balances. No Credit worker/ledger changes belong to this task.
School LAB 3c432cd: Production deployed; Owner verified school auto-student, optional grade, grade save and reload persistence. APP school flow unchanged. No profile schema change.
Target candidate: SQL preservation/duplicate/RLS/cascade tests PASS; LAB focused 20 PASS. APP Flutter runtime NOT_RUN: pinned SDK unavailable and official download host denied by environment proxy. Candidate remains held.

## Preserved prior presentation status

Editing: Profile/school Save returns once on success; failed/partial save stays. School results directly below search. Chart uses actual
max, zero unpainted, oldest→newest, no horizontal scrolling. Login default HOME,
trusted explicit protected return preserved. Owner corrections now add logout HOME,
verified avatar read-after-write. Owner-approved Design System v2 now uses Orange /
Deep Navy / Cool Neutral, white grouped surfaces and plain section headings.
Guest MY exposes Login and hides private dashboard modules. Materials pages contain
5 items with explicit load-more after Owner device follow-up; Settings logout follows
service/policy groups. Home has an own-nickname greeting and small daily semantic
icons. Greeting uses compact16px hierarchy and a noninteractive planned bell slot.
D-Day name/date metadata sits above D-n; study label/value share a wrapping row.
Brand accent is now Owner-confirmed #FFA300; no peach selections. Meal's explicit
trailing control opens up to3 actual provided-day chips, lazily bounded past/future
context; preview14/19KST/7day policy unchanged. All major groups share a white surface, stronger cool-neutral border and the unchanged approved Home shadow; nested/items remain flat; Meal selection has
no checkmark. Timer/Trend daily summary shows displayed7day total + daily max,
with the neutral mean caption directly above its dashed line. Mock has official year/grade/month→actual subject/
variant/key and separate free title/time/manual-score practice. Free scores are
local personal records, excluded from official MY/LAB/admissions. MY confirmed correct-count snapshots push LAB and preserve Back.
[Canonical design](design-system.md) maps the approved proposal to implementation.


## Candidate verification update

Owner preflight confirms helper/admin/lifecycle hashes and no005+ migration collision.
LAB lint/typecheck/full537 tests/boundary/static build PASS; browser fixture desktop1440
and mobile390 PASS (one-step multi-division, Application create/outcome/correction/reload, Study totals).
PostgreSQL17 NOSUPERUSER postgres, eight-way same-key save/event concurrency, exact
activation package/ledger/replay rejection and Auth cascade PASS. PGlite Target,
Application, Study and Student360 suites PASS. APP Flutter tests remain NOT_RUN.
Migrations006–008 are now PRODUCTION_APPLIED. Target005 remains unapplied/held.


## Production activation postflight — 2026-10-08

Owner applied exact APP35ab994 foundation package (006–008 only). Owner postflight:
8 RPC body MD5 values match candidate SQL; all postgres-owned SECURITY DEFINER with
empty search_path, anon execute false, authenticated execute true. Both new tables
have RLS true and authenticated INSERT/UPDATE/DELETE false. FK cascades to profiles
and application/events confirmed; university remains restrictive. No reapplication.
LAB507ed7b preserves latest Manus typography857ec9c and holds the Target interface;
Cloudflare60564c64-3fe4-49fe-8075-d117f4f24865 succeeded, live domain serves new adapters.
Local merged release536 tests/lint/typecheck/boundary/build and1440/390 browser fixture PASS.
Actual Production anonymous read RPCs my_applications/my_study_summary/my_essay_summary/
admin_student360 all return401/42501. Owner authenticated Application/Study/Admin
acceptance is pending; availability/ACL verification is not read/write acceptance.
Target005 still requires Owner §74 resolution and APP Flutter regression (NOT_RUN).
No migration history, Payment/Toss, IAP, signup worker or deletion runtime changed.
