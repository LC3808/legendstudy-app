# Essay LAB Production preflight — READ ONLY / APPLY BLOCKED

2026-09-28. Owner approved promoted package2819b67 for read-only inspection only.
**READY_FOR_PRODUCTION_APPLY: NO.** The sole observed blocker is absent Production
`supabase_migrations` schema / `schema_migrations` table. Existing canonical objects are present;
missing history does not mean their migrations were not applied. Do not replay old migrations,
initialize/repair history, or deploy automatically. No Owner SQL action is requested.

## Actual observations

[Sanitized catalog and result](../supabase/validation/essay_lab_product/production_preflight_result.json)
contains metadata/aggregates only. No auth.users contents, student bodies, UUIDs, email, credentials or DSN.
Existing authenticated Supabase CLI linked LegendStudy Management API query path was used;
no browser/login test or other project's database was queried. CLI printed its normal
“Initialising login role” connection message; no role-management SQL was submitted by this task.
Every submitted SQL batch was BEGIN READ ONLY / ROLLBACK. No DDL/DML, mutable RPC or apply was issued.

| Gate | Result | Evidence |
|---|---|---|
| Migration history | FAIL | History schema/table absent; foundation version, ordering, same-version content and divergence unverifiable |
| Object collision | PASS | All19 targets and private schema absent;4 columns' parent tables absent |
| Prerequisites | PASS | Five public parents exist; UUID IDs, mapping composite PK, parent FKs and RLS match references; set_updated_at exists |
| Canonical data | PASS | Universities5 / exams21 / exam-resources134; resources10556; all3 orphan counts0 |
| Role prerequisites | PASS | anon/authenticated/service_role/authenticator exist; postgres CREATEROLE/BYPASSRLS, public CREATE, auth USAGE and uid EXECUTE observed;3 new roles absent |
| RLS / trigger collision | PASS | No target relations, hence no relation-scoped policy/trigger collision |
| Function collision | PASS | All28 helper/RPC names absent across signatures, including12 RPCs |
| PostgreSQL compatibility | PASS |17.6 UTF8, plpgsql and UUID/SHA256 builtins present; installed extensions recorded |
| Read-only guard | PASS | Parsed SELECT/transaction/local settings only; nested dynamic SELECT strings manually reviewed, fixed public table names |
| Lock risk | LOW | Four nullable columns alter newly created empty tables, not existing large tables; no existing-table rewrite |

No unexpected Essay product/queue objects. Similar public relation inventory contains only the existing
essay_exams and essay_exam_resources. Canonical counts and aggregate fingerprints matched before/after;
final supplement counts also matched. No actual user rows queried. Migration role capability review is
catalog/static evidence, not a Production role-creation experiment.

Follow-up: [baseline adoption final check](production-migration-baseline-reconciliation.md) READY;13 historical candidates, actual history write awaits separate authorization.

## Blocker resolution boundary

Next: separately authorize an operator-led migration-history baseline reconciliation plan. Compare each
existing repository migration with actual applied-state evidence before recording any version. Never mark
all repository versions applied based on object presence alone, and never use db push while history is absent.
That work is not performed or authorized by this read-only task. Foundation objects exist, but its history
version20260927000200 cannot be attested. All3 new versions have absent product objects; their history
entries cannot be checked because the history catalog itself is absent.

## Future apply plan — conditional, not executed

After reconciled history and a fresh preflight PASS, seek separate Production apply authorization.
Use the existing Supabase CLI migration deployment flow with an operator-controlled staging directory
containing only reconciled historical migrations plus the next approved file. Do not ask Owner to paste SQL.
First dry-run must show exactly the intended next version; stop on any old/unexpected pending migration.
Serialize canonical ingestion/admin writes during apply and baseline comparison; keep Essay clients/workers disabled.

1. Deploy001 (20260928000100): CLI records the version through its migration mechanism. Check15 tables,
   empty new rows, RLS/constraints and unchanged canonical counts/fingerprints.
2. Add/deploy002 (20260928000200): check19 total tables, zero new rows, ledger/decision constraints and
   expected ownership/grants; verify exactly001/002 recorded. Do not enable any product writes yet.
3. Add/deploy003 (20260928000300): run the prepared full post_apply.readonly.sql and catalog contract:
   19 tables,4 columns,12 RPCs,47 object fingerprints, FK/UNIQUE/CHECK/indexes/triggers/RLS/policies,
   direct client write restrictions, narrow worker/finance EXECUTE, bootstrap grants revoked,
   all new tables empty, orphans0 and unchanged canonical baseline. Verify all3 history versions.
4. Any failure: stop with earlier successful versions intact, writers disabled; inspect transaction/history
   outcome and propose reviewed roll-forward correction. No destructive rollback or blind rerun.

Installed CLI help was checked without deploying. In each staged operator workspace, the future commands are
`supabase db push --linked --skip-vault --dry-run`, then (only after the approved checkpoint)
`supabase db push --linked --skip-vault`. Never pass include-all/include-seed/include-roles.
The skip-vault flag prevents unrelated config-to-vault updates. Do not run even the dry-run until history
is reconciled and the staged workspace's LegendStudy link is verified. This plan is not an auto-deploy runner.
Parent FK creation can take brief metadata locks; avoid concurrent schema maintenance. Catalog read-only
checks cannot guarantee future lock wait duration. No load/concurrency experiment was run on Production.
Post-apply validation is ready, but NOT executed here. Existing local runtime/JWT results remain historical;
no repeat AI, login, UI or student data seeding. Shared identity PASS does not close provider/privacy/retention gates.

## Validation / stop

Offline promotion6 + preflight4 tests, Wiki handoff, diff and Owner-file hash preservation checks.
Migration SQL unchanged. Production mutation/apply NO. Stop pending Owner/ChatGPT blocker review.
