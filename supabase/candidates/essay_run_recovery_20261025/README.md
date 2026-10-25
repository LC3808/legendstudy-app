# Approved single-run recovery — APPLIED 2026-10-25

Project: stlhijzpjfgwwdgunlsd. Run: b2cbc55f-edc7-423d-bfdc-f5d039b215e5.
Owner explicitly approved precheck → apply → postcheck and resuming this same request.
Production precheck 8/8 and pre-dispatch postcheck 6/6 passed. Do not reapply.

The transaction appended one audit checkpoint and generation 1 for incomplete internal indices 1/2 (Q3/Q2). It did not modify original checkpoints, snapshot, successful Q1, reservation or policies. Exact baseline/expiry guards reject changed state and reapplication.

Same request resumed and completed all three questions. Original reservation settled for 1 Credit; no extra reservation. Free rewrite completed for 0 Credit with no Ledger entries.

`postcheck.sql` describes the pre-dispatch state and is intentionally not a completed-run acceptance query. See Wiki for final read-only verification and run IDs.

`rollback.sql` was NOT approved or executed. It invokes existing finalization/release only after its guards pass; it never deletes checkpoints or history. The completed request cannot be released with this recovery fallback. Obtain Owner approval for any further Production SQL mutation.

Isolated verification: `python3 tool/test_essay_run_recovery_sql.py`; PostgreSQL17 required. No Production credentials in this directory.
