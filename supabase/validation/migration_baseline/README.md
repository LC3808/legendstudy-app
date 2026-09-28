# Migration baseline reconciliation — READ ONLY / NOT READY

Canonical decisions and exact per-version plan: [Wiki](../../../wiki/production-migration-baseline-reconciliation.md).

- inventory.json: all16 ordered files, hashes, purpose, DDL/function/RLS/data changes and dependencies.
- catalog.json: actual Production metadata only, public function bodies hashed.
- catalog_followup.json: observed default ACLs, view definition/options and pure Study lexical digest.
- compare.py: OFFLINE parser/comparator; no network, psycopg, SQL execution or repair. Later schema changes
  are attributed to their author; effective current ACLs account for observed Supabase defaults. It does not
  prove the historical environment had the same defaults. Schema equivalence is scoped to migration-owned
  state, excluding legitimate later additions and mutable application records.
- deparse_review.json: exactly4 reviewed cast/interval formatting pairs; changed input cannot inherit PASS.
- manifest.json:16 final decisions,1569 structural checks, baseline/apply NO; full data effects UNKNOWN for3.
- cli_semantics.json: installed official CLI local source/help inspection, not migration command execution.
- catalog.readonly.sql/query_hashes.json: frozen approved catalog-only SELECT in READ ONLY/ROLLBACK.
  Existing Essay preflight SQL was reused for before/after aggregate fingerprints. The one focused study
  body/default-ACL/view follow-up ran READ ONLY; raw function body is not committed.

Run with Python+pglast8.4: `python -m unittest discover -s supabase/validation/migration_baseline -p 'test_*.py'`.
No migrations were replayed even locally. No data backfill was simulated as proof of historical execution.
Do not run list/repair/push/dry-run on Production from this package. No approved write list exists yet.
