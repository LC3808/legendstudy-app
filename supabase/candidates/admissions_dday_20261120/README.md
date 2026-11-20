# Admissions D-Day — Owner approval package

**NOT APPLIED.** Target: LegendStudy Supabase `stlhijzpjfgwwdgunlsd` only.
Canonical policy, source review and implementation: [Wiki](../../../wiki/admissions-dday-implementation-20261120.md).

Prepared order (do not run on Production before Owner approval):

1. `preflight.sql` — read only; save receipt. Stop if names collide or exact existing `my_application_save` MD5 differs.
2. `install.sql` — transaction, additive tables/RPC/triggers plus one shared catalog lock before the existing save owner lock. Captured current duplicate prevention remains intact. No existing personal row writes on installation.
3. `seed_reviewed.sql` — 15 public official schedule/candidate records, 10 verified/published and5 PENDING. Same-content replay allowed; drift aborts transaction. Source data is `reviewed_schedules.json`.
4. `activate_existing.sql` — separate explicit personal projection activation. Adds only eligible automatic `day_targets`, excludes 정시 and unknown dates; source headers/manual rows remain unchanged.
5. `postflight.sql` — compare original header/event/Essay hashes and all non-generated D-Day hashes to preflight. Inspect RLS/ACL/source/connection counts. New schedule counts are not a substitute for permission tests.
6. Only after DB postflight and regression PASS, deploy WEB and verify real authorized UI without editing actual student applications. Flutter release is separate.

As-of 2026-11-20 21:23 KST read-only forecast: existing14 headers,8 matching 수시 headers,12 owner/event D-Days (4 essay+8 initial result). Dates already past at activation are not initially created. Counts must be recalculated at rollout.

`preimage_my_application_save.sql` is the exact read-only captured Production definition. `rollback.sql` is a **soft operational rollback**, requiring an explicit execution decision: checks installed save hash, unpublishes events with revision history, removes only generated active projections, restores the save preimage, disables its application sync trigger and admin publisher. It retains all evidence/tombstones and personal read/dismissal compatibility. It does not force-write lifecycle-restricted accounts or alter manual D-Days. Do not drop these tables after student use, as that would erase deletion preferences.

Validation uses local synthetic PostgreSQL17 data and real roles, never a hosted test write:

`python3 supabase/validation/admissions_dday/test_postgres.py`

See that folder's README for disposable database connection settings and limitations. Source SHA256 receipts are in `result.json`; do not claim tests for a later modified installer without rerunning relevant checks.
