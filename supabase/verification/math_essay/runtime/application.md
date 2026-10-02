# MATH-2D Owner review/application notes

Production NOT_APPLIED. No remote ledger connection or write performed by MATH-2D.

Migration: [20261002000200_math_runtime_surface.sql](../../../migrations/20261002000200_math_runtime_surface.sql).
SHA-256: `b40bf7224a84658308ff1640b639acb857e379998211131d97a688a9711fe049`.
Base MATH-2C hash remains `73fae66a4a9198885c6bf505ac87d9a3abcc453dd1017e666a217bac486c7d51`.

## Before separately authorized application

1. Verify reviewed APP commit and both hashes; apply only explicitly authorized prerequisites. MATH-2C is required. ADR-2 is an activation prerequisite, not silently installed by this migration.
2. Read current ledger/catalog, function owners/ACL/search_path and memberships. The MATH-2C dated ledger23/ADR-2-absent snapshot is not a fresh MATH-2D Production verification.
3. Check no collision with the four new wrapper names and no multiple CONFIRMED runs for a candidate. This unactivated foundation is expected empty. Unexpected historical data/topology requires review; do not delete/backfill it to pass installation.
4. Apply exactly the runtime migration transaction after MATH-2C. Six existing Math function definitions are replaced; no Humanities, HQP, Credit finance body, role or table changes. One partial unique index added. Temporary SET and public CREATE are scoped to existing math_executor and restored. New wrappers delegate through exact internal postgres EXECUTE grants; no browser/worker table access is added.
5. Read [catalog.sql](catalog.sql) and compare [physical_catalog.json](physical_catalog.json), [ownership.json](ownership.json). Four wrapper ACLs must be owner plus designated client only. Math role membership/schema CREATE must equal the preflight baseline. Separately track only this exact migration after Owner SQL success; no broad push/repair.
6. Keep workers/Storage/Math off pending actual JWT admission, lifecycle/erasure integration, provider and feature activation authorization. No consumer binding implies deployment.

## Rollback

[rollback.sql](rollback.sql) is an isolated-tested empty-Math-install rollback. It refuses any attempt, refuses unexpected dependencies (no CASCADE), drops only the four wrappers and one new index, restores exact six MATH-2C definitions and internal EXECUTE ACLs. It must run before any base MATH-2C rollback. Production rollback requires separate Owner review; preserve obligations and use forward correction after real use.

## Validation provenance

C01–C30 all PASS plus stale/contract/concurrency negatives;131 unchanged Math checks and102 unchanged HQP/Humanities assertions after runtime migration. Eight runtime installation/security/failure/rollback checks, plus14 base installation checks. All installation/rollback executions use non-superuser postgres with the approved platform topology. Actual Storage API/provider/gateway runtime NOT_ASSESSABLE, no real student data. Exact result files are in this directory.

```sh
python tool/test_math_runtime.py --pg-bin /path/to/postgresql17/bin
python tool/test_math_runtime_installation.py --pg-bin /path/to/postgresql17/bin
python tool/test_math_runtime_legacy.py --pg-bin /path/to/postgresql17/bin
```
