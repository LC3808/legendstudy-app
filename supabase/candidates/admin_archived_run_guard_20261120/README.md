# Archived run execution guard — 2026-11-20

**APPLIED — Owner-authorized correction, 2026-11-20.**
Target is LegendStudy `stlhijzpjfgwwdgunlsd` only. The observed target run is
currently **hidden=false**, so a successful fix does not make its live KPI zero.
No existing request is archived/restored/retried by the migration.

Remote migration: `20261120130743_admin_archived_run_guard_20261120`.
Installed SHA256: `6a8370d24aba9d8b6f65940836603528f9d7f35c9755aed1d86a934ef81fcc4e`.
Synthetic20/20 passed; eleven installed function MD5s match the tested postimages,
ten existing RPC ACLs/owners and 63-table counts/hashes remained unchanged.
Actual READ ONLY admin live KPI: processing1 / retry_pending1 / archived0,
consistent with the visible reserved target. Its reserved credit delta remains1.
[Production receipt](../../../wiki/evidence/admin-archived-run-production-20261120.json).
The CLI placeholder timestamp130940 was renamed to actual remote version130743;
the tracked migration is byte-identical to the installed SQL, with no duplicate.

`install.sql` checks ten exact current function preimages, replaces only those
RPC definitions, and creates a Worker-only read guard. Existing table rows,
run state, snapshots, checkpoints, billing reservation and ledgers are untouched.
Existing RPC owners/signatures/ACLs remain unchanged. `build_patch.py` reproduces
the patch from `preimage.json`; it never connects to a database.

- `admin_essay_operations(...5 args).live.processing/retry_pending` exclude
  `hidden=true`; `live.archived` counts all archived runs regardless of period or
  state. Period/history/cost/ledger aggregates remain intact.
- Both management and legacy visibility RPCs use account → run locking.
  Archive rejects an active run/retry lease. For reserved runs it also rejects
  missing dispatch key/token, pending/reconciling checkpoints, or any final
  checkpoint (`RECONCILIATION_REQUIRED`). Completed evidence is preserved.
- `essay_exam_claim` returns a bounded `{state:'archived', run_id,
  dispatch_allowed:false}` after ownership checks; `essay_exam_session_claim`
  inherits it. Worker must ACK this result without Provider calls.
- New `essay_exam_dispatch_guard(p_subject,p_run)` returns only `{run_id,state}`
  and performs lifecycle/ownership checks. Only `essay_worker` may execute it.
  It supports pre-enqueue denial; atomic claim closes the later race.
- Retry and replay of an existing retry action reject `RUN_ARCHIVED` before
  returning a generation. Student status/observation advertise retry=false.
- New checkpoint `begin` is denied while archived. Existing writer read/write
  remains available for evidence preservation. The finish/settlement RPC is
  unchanged; ambiguous or finalizing reserved runs cannot be newly archived.
- Restore only changes the visibility projection and its existing audit path.
  It creates no lease, retry generation, queue message, refund or ledger entry.

Run synthetic PostgreSQL checks using the isolated Unix-socket cluster from
`supabase/validation/admissions_dday/README.md`:

```sh
python3 supabase/candidates/admin_archived_run_guard_20261120/test_postgres.py
```

The test runner refuses other clusters, rebuilds only `admin_archive_test`, and
uses `postgres NOSUPERUSER BYPASSRLS` matching inspected Production attributes.
Authenticated/anon/essay_worker remain NOBYPASSRLS; real role/ACL checks are run.
Auth/lifecycle/profile dependencies are minimal synthetic fixtures. No real
student data is used. `result.json` records test outcomes and exact file hashes.

Before apply: capture current hidden/run/checkpoint/retry/credit/payment table
hashes and original RPC ACLs, verify preimages and target project again. Apply
through `apply_migration`. Check all original rows/ACLs unchanged and compare
installed function hashes to the local receipt. A visible target still counts.
Use synthetic tests and deployed-source identity to verify archived exclusion;
do not temporarily archive a real request to make the metric disappear.

`rollback.sql` guards all eleven installed function hashes, restores ten exact
preimages, and drops the new guard. Revert Worker pre-enqueue usage first. This
rollback changes no operational rows or hidden flags; it also restores the old
list-only archive semantics, which must be clearly reported if executed.
