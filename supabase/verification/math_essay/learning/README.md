# MATH-2E Owner verification package

Status: implemented / isolated PG17 verified. **Not applied, deployed or activated in Production.** Consumer binding: [exact RPC contract](contract.md). Canonical semantics remain MATH-4/5/6/7; this runtime does not generate hints or judge mathematics.

## Artifact and prerequisites

- Migration: `20261002000300_math_learning_runtime.sql`; exact SHA-256 in [migration.sha256](migration.sha256).
- Apply only after separately approved canonical MATH-2C `20261002000100` and MATH-2D `20261002000200`, with their package prerequisites and correct owners/ACL. Do not edit/replay their hashed migrations.
- [Ownership allowlist](ownership.json): postgres-owned public `math_learning(jsonb)`, two private projection helpers, existing math_executor-owned `validate_output(uuid,jsonb)` replacement only. Approved transaction-local SET + CREATE on **math_private** restored; no new role or membership. Final three Math ADMIN-only memberships remain ADMIN=true/INHERIT=false/SET=false.
- No finance function, Essay/HQP function, ADR-2 migration or policy change. No new table. Existing private table RLS/ACL preserved.
- New uniqueness `(math_evaluations.id,output_sha256)` supports a typed generated-reference exposure FK. Existing `math_solution_exposures.solution_id` is conditionally nullable; exactly one reference-solution FK or generated-output binding required. Both erase with evaluation. No detached hash archive.
- Two delivery-history indexes support hint lookup and evaluation solution-exposure lookup. No speculative analytics indexes.
- Validator admits optional bounded MATH-4 `review_status` and `progression.delta`; it does not derive correctness/delta. Old payloads remain valid and old rows unchanged.

## Owner sequence — instructions only, not executed

| Action | Expected | STOP / abort |
|---|---|---|
| Verify APP commit and SHA file with `shasum -a 256 supabase/migrations/20261002000300_math_learning_runtime.sql` | Exact committed bytes | Any mismatch; no apply |
| Inspect ledger and run [catalog.sql](catalog.sql) read-only | C/D installed; E absent; known approved ownership; no new-name collision | Missing prerequisite, unknown owner/grant/membership or collision; do not bootstrap broader privileges |
| Confirm all C/D activation gates remain explicitly gated | No accidental provider/student activation | R21, trusted worker JWT/runtime and ADR-2 Math erasure integration unresolved means no general feature activation |
| Owner separately authorizes and applies **only E** as non-superuser postgres in its explicit transaction | Commit succeeds, membership/schema privileges restored | Error rolls whole transaction back; do not skip checks |
| Run [postflight.sql](postflight.sql), compare [ownership.json](ownership.json) | Exact function owner/security/search_path/EXECUTE; unchanged private table ACL/RLS; no installed learning data | Unexpected difference: stop deployment |
| Owner records only the exact E migration through approved tracking procedure | Exact version once, unrelated ledger unchanged | No broad db push, pending replay, manual history insert or unrelated repair |
| Separately authorize gateway verification and consumer deployment | JWT boundaries verified; contract bound | Isolated role simulation is not real JWT/Storage proof |

Remote metadata observed before implementation: 23 migrations; ADR-2/C/D/E absent; provider005 not applied and day_targets tracking separate. This observation is not a permanent apply baseline: re-read immediately before Owner apply. No automatic prerequisite application.

## Security and rollback

`math_learning(jsonb)` EXECUTE: postgres/authenticated only; authenticated still requires owned subject and active lifecycle. anon/PUBLIC/service_role have none. Projection helpers postgres-only INVOKER; output validator math_executor-only DEFINER. All empty search_path. Worker role grants/membership remain unchanged. No direct student write, no service role in browser.

[rollback.sql](rollback.sql) refuses any Math attempt and unexpected dependencies; removes only E objects and restores original validator bytes/owner/ACL. No CASCADE. Once personal learning obligations exist, forward recovery is required; do not delete them to make rollback pass. The empty-install rollback is not Production rollback authorization.

## Reproducible isolated evidence

Use Python with psycopg3 and PostgreSQL17 binaries; runners create Unix-only throwaway clusters, never accept a remote DSN:

```sh
python tool/test_math_learning.py --pg-bin /path/to/postgresql17/bin
python tool/test_math_learning_installation.py --pg-bin /path/to/postgresql17/bin
python tool/test_math_learning_legacy.py --pg-bin /path/to/postgresql17/bin
```

- [validation.json](validation.json): L01–L40 individually + extra rejection/erasure/rollback checks. Actual concurrent sessions: hint retry, solution retry, included entitlement, resolve retry, lifecycle vs resolve, lifecycle vs reevaluation. No tested deadlock.
- [regression.json](regression.json): unchanged 131 Math persistence/finance/HQ assertions. [runtime/validation.json](runtime/validation.json): C01–C30.
- [legacy_validation.json](legacy_validation.json): unchanged 102 Humanities/HQP assertions after C/D/E, including ql-read-v1/hq-read-v1 and E1/E2.
- [ownership_validation.json](ownership_validation.json): E non-superuser apply, 5 injected bootstrap/late failures, function preservation, table ACL/RLS, exact empty rollback and dependency refusal. [runtime_ownership_validation.json](runtime_ownership_validation.json): 8 D checks; [installation_validation.json](installation_validation.json): 14 C checks.
- Auth roles/claims are local shims; no real JWT sign-in/provider/Storage runtime. Production application writes=0; provider calls=0.

R21 remains **PRODUCTION_ACTIVATION_GATE**. No Storage bucket, Edge Function, scheduler, secret or LAB code is added. Math lifecycle predicates are exercised with the isolated ADR-2 dependency; Production ADR-2 state is not implied. Existing C/D future erasure/Storage activation gates remain open.
