# HQP-3 Owner apply package — READY / NOT APPLIED

Canonical migration: [20261001000200_human_quality_persistence.sql](../../migrations/20261001000200_human_quality_persistence.sql).
SHA-256: `598aacc93d6749f2b890dfc440564a179e9185c1978e05b09ba8df9304449fd5`.

This package authorizes no Production action by the agent. Owner review/application is the next gate. No real JWT write verification has occurred. [Isolated evidence](validation.json), [catalog pre/postflight](catalog.sql), [rollback](rollback.sql), [implementation contract](../../../wiki/human-quality-persistence-implementation.md).

## Prerequisites and exact bounded order

1. Owner verifies canonical APP task branch/approved commit and file hash (`shasum -a 256 supabase/migrations/20261001000200_human_quality_persistence.sql`). Correct project is the already verified LegendStudy shared backend, never a similarly named project. Existing canonical dependency chain through scaffolding/commercial/owner-status and LSA-2C must match. HQP does not require provider005. Run catalog.sql read-only and retain its sanitized preflight privately for comparison. Expect no HQP objects/version, existing Quality auth verified. Last verified remote ledger has22 entries; recheck rather than assuming it is still22.
2. STOP for existing/conflicting HQP name/version, unexpected drift, unreviewed hash, changed existing functions/ACLs, or unidentified project. Do not use db push, migrate up, automatic replay or unrelated tracking repair. The migration deliberately uses CREATE (not IF NOT EXISTS/OR REPLACE) to fail on conflicts.
3. After explicit Owner approval, SQL Editor executes **only this exact file**, including BEGIN/COMMIT; 5s lock_timeout/30s statement_timeout. No operator registration, student rows or test fixtures. If execution fails/has unknown outcome, STOP and inspect catalog; do not blindly replay.
4. Run catalog.sql postflight: two new tables, four private helpers, three public RPCs, seven indexes (including constraint/PK indexes), two UPDATE triggers, exact security below. Existing tables/policies/function definitions/ACLs unchanged. New FK internal RI triggers on referenced objects are expected. SQL success is not migration tracking.
5. Owner separately records **only** this version using the existing explicit-version CLI procedure, after successful schema/hash verification:

   ```sh
   supabase migration repair 20261001000200 --status applied --linked --project-ref stlhijzpjfgwwdgunlsd
   ```

   This is a future Owner step, NOT executed by HQP-3. No manual INSERT into ledger. No repair of provider005 or day_targets. If schema succeeds but tracking fails, record SCHEMA_APPLIED_TRACKING_PENDING; never replay the SQL for that reason.
6. Re-run catalog; expected only new ledger version20261001000200, count22→23 if preflight still22. Compare the tracked migration statements against the exact approved file; CLI success is not proof of statement equality. provider005 remains absent; day_targets20260930000100 remains separately absent. Unrelated ledger differences require STOP.
7. A separately authorized Production verification must check real operator/non-operator/anon JWT behavior; isolated role simulation is not gateway evidence. Do not create a Production evaluation or QA fixture to obtain coverage. Human Review write UI and real-student Pilot remain gated.

## Security matrix

| Object | PUBLIC / anon | authenticated | service_role | Owner / RLS |
|---|---|---|---|---|
| human_quality_judgments | ALL NONE | ALL NONE | ALL NONE | postgres; RLS ON, zero policies |
| human_quality_findings | ALL NONE | ALL NONE | ALL NONE | postgres; RLS ON, zero policies |
| ql_submit_human_judgment(jsonb) | EXECUTE NONE | EXECUTE; internal operator gate | NONE | postgres SECURITY DEFINER, search_path empty |
| ql_review_state(uuid[]) | EXECUTE NONE | EXECUTE; internal operator gate | NONE | same |
| ql_list_human_judgments(uuid,integer,timestamptz,uuid) | EXECUTE NONE | EXECUTE; internal operator gate | NONE | same |
| essay_private.hq_rubric_valid(jsonb), hq_finding_valid(jsonb), hq_projection(jsonb), hq_immutable() | EXECUTE NONE | NONE | NONE | postgres; invoker helpers with empty search_path |

ALL NONE includes SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER/MAINTAIN. Existing quality_operators service registration privileges are unchanged. No browser service role. Do not grant HQP CRUD to the existing essay_executor role; evaluation cascade uses FK mechanisms. DB owner remains an administrative trust boundary, not an ordinary operator.

## Constraints and indexes

Evaluation CASCADE; findings judgment CASCADE; reviewer auth.users SET NULL; reviewed generated rewrite SET NULL. Supersession composite same-evaluation FK with immediate NO ACTION; unique predecessor, no self-edge. Server requires already existing current head, so insertion cannot create cycles. No UPDATE RPC; immutable triggers permit only exact erasure-induced FK nulling. Privacy deletion is allowed; no blanket DELETE trigger.

Unique submission UUID, canonical server-computed request/binding hash; exact authorized retry returns same ID. Changed payload/key reuse conflicts. Findings same-subject validation occurs inside writer transaction; schema CHECKs enforce exact typed shapes/vocabularies. Every required rubric key/version/overall/note bound is enforced. SQL owner can make privileged inserts; no client/import bypass surface is granted.

Explicit indexes: human_quality_history(evaluation_id,created_at DESC,id DESC), human_quality_findings_judgment(judgment_id). Constraint indexes: both PKs, judgments client_submission_id, supersedes_judgment_id, (id,evaluation_id). Reviewer/category analytics indexes deferred. No existing Essay index change.

## Validation and rollback

Run locally with PG17 and Python psycopg installed:

```sh
python3 tool/test_human_quality.py --pg-bin /path/to/postgresql17/bin
```

Runner initializes and destroys its own temporary cluster, Unix socket only, listen_addresses empty; no DSN/live-catalog input. Uses actual canonical migrations (including feedback admin, product, server, scaffolding, commercial and Quality read), actual synthetic submit/finalize fixtures. Shim only supplies auth.users/auth.uid and API roles/default grants; JWT signature validation is NOT simulated or proven. No real credentials/data.

105 checks PASS: T1–T69 coverage (T11/T12 share preservation assertion), E1-A–E/E2-A–F, actual two-connection duplicate/correction races, remaining-domain-data rollback preservation and additional bounds/immutable/side-effect checks. T57 tests the pure production projection helper with hypothetical incompatible versions; writer still rejects all unknown versions. Existing relation/column/constraint/policy/user-trigger/function/body/ACL snapshots match before/after. No new Production catalog query.

Owner-approved rollback executes only rollback.sql, no CASCADE. It removes three RPCs, two tables (and their own indexes/triggers), four helpers. It erases stored QA if any exists at that later time; that loss requires Owner approval. Unexpected dependencies abort the transaction. Isolated dependency-refusal and successful bounded rollback tested. Rollback does not automatically change the ledger; record a separate Owner recovery decision, never silently repair unrelated history.

## Policy boundary

Account deletion policy is request→14 days→automatic personal-data erasure. Existing handler calls immediate deleteUser; implementing pending/access restriction/cancellation/scheduler/notification is a separate task. HQP automatically follows final hard evaluation deletion only. Reviewer deletion removes identity while preserving QA of still-existing student evaluations. Invalidation/reevaluation do not delete or transfer QA.

No analytics retention/archive/tombstone or copied answer/feedback is created. Notes cannot be semantically screened by length caps: operator UI guidance must prohibit copied answer/feedback/PII/secrets/raw chain-of-thought. Notes erase with subject. Retention/de-identification design is a separate future gate.
