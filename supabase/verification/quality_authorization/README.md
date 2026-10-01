# LSA-2C Owner application package — NOT APPLIED

Canonical contract: [Worker/Provider Wiki](../../../wiki/essay-lab-worker-provider-l2.md#lsa-2c-shared-quality-authorization--2026-10-01).
SQL: [20261001000100](../../migrations/20261001000100_quality_read_authorization.sql). SHA-256: `079f03a0bb65612292ce0d1343f395cc1b4acbdcc9cfe696b1072dd49f248764`.

## Exact bounded application and separate tracking

Only the Owner may execute after reviewing this package. Nothing below ran in Production.
Do not use `db push`, even from the canonical checkout: provider005 and day_targets tracking
are separate pending entries. Do not replay historical migrations or merge the LAB branch.

1. Use canonical `codex/essay-scaffolding-vnext`, verify the exact reviewed SQL hash above,
   project `stlhijzpjfgwwdgunlsd`, and [catalog preflight](catalog.sql). Expect no new Quality
   objects/signatures/version. STOP on unexpected objects, timestamp collision, schema drift,
   changed hash or dependencies. Live prerequisite is the verified 21-version baseline;
   provider005 is neither required nor applied. `20260930000100` remains separately untracked.
2. In that project's Owner SQL Editor, execute **only the exact migration file** (BEGIN/COMMIT
   included). It fails on an existing object instead of silently replacing a different definition.
   No registration UUID is embedded. If it errors, STOP; no auto retry/repair. The DDL transaction
   has 5s lock and 30s statement bounds. Transaction success is SQL application, not ledger tracking.
3. Run catalog postflight; confirm the four objects, exact ACL matrix below, and unchanged Essay
   RLS/ACLs against preflight. If SQL succeeded but tracking later fails, record
   `SCHEMA_APPLIED_TRACKING_PENDING`; **do not replay the migration**.
4. After Owner separately confirms successful SQL and this one version's tracking, from the
   canonical App checkout use the supported **explicit-version** command:

   ```sh
   supabase migration repair 20261001000100 --status applied --linked --project-ref stlhijzpjfgwwdgunlsd
   ```

   This future Owner step records only LSA-2C, not a broad history repair. No command without
   that explicit version, no `--status reverted`, no direct INSERT into migration history.
   This command was checked through local CLI help only; it has **not been executed**.
5. Re-run catalog. Expected remote count 21→22, exactly new version `20261001000100`; existing
   21 entries/statement ASTs unchanged. Compare the new stored statements to the reviewed SQL
   AST (ignoring parser source locations), and verify provider005 + `20260930000100` still absent.
   A CLI success message alone is not tracking verification. If statements differ, STOP.
6. Privately confirm two exact `auth.users.id` values: intended operator and a normal user.
   No wildcard/domain enrollment. Review [Owner registration](owner_register.sql), replace the
   two fail-closed placeholders locally, execute once, preserve the privileged-write approval
   record. No Owner UUID/email is committed. Then verify real operator/student/anon gateway
   calls without publishing JWTs or answer bodies. SQL role simulation does not prove gateway
   JWT signature or expiration handling.

## Security matrix (prepared end state)

| Object | Client rights | Definer / gate | Scope |
|---|---|---|---|
| quality_operators | anon/authenticated NONE (SELECT/INSERT/UPDATE/DELETE all NO) | RLS ON, policies NONE; owner postgres | auth.users PK/FK CASCADE; created_at; service_role S/I/D only for offline registration |
| is_quality_operator() | PUBLIC NO, anon NO, authenticated EXECUTE YES, service_role NO | SECURITY DEFINER; empty search_path; postgres | auth.uid + matching unexpired authenticated request claims + allowlist |
| ql_list_cases(integer,timestamptz,uuid) | same function ACL | SECURITY DEFINER, internal operator gate YES | default50/max100; no full answers |
| ql_case_detail(uuid) | same function ACL | SECURITY DEFINER, internal operator gate YES | full student answer YES; direct account identifiers NO |

No service-role secret in the browser or runtime. auth.uid is the canonical identity;
request claims are trusted only after API gateway JWT validation. SQL clients able to SET
arbitrary claims are trusted backend actors, not an alternative client authorization path.
Quality access does not confer existing Essay privileged-write authorization.

## Rollback and testing

[rollback.sql](rollback.sql) removes only the four new Quality objects, in dependency order,
without CASCADE. Unexpected dependency aborts/rolls back the transaction. Registration rows
are lost if rollback is approved; preserve required administrative records beforehand.
Essay/auth/profile/credit/evidence history is untouched. Ledger reversal is a separate Owner
review; never automatically mark anything reverted. Forward SQL is single-apply, not idempotent.

`python tool/test_quality_authorization.py --pg-bin /opt/homebrew/opt/postgresql@17/bin`
requires Python psycopg and local PG17. It creates a temporary Unix-socket-only cluster,
loads actual App migrations and strict finalize RPCs, uses synthetic answers/UUIDs, runs
T1–T15 and rolls back, including a dependency-failure test. No Production DSN or provider.
See [sanitized evidence](validation.json). Live gateway verification is intentionally pending.

## Launch classification

- LAUNCH_BLOCKER: until Owner application + real authorization verification, no live Quality UI.
  Canonical path/mapping/bypass questions are resolved at isolated-test level, not deployed.
- LAUNCH_REQUIRED: reviewed authorization package; real operator/student/anon verification;
  list global-order index decision before growth. Candidate only:
  `essay_evaluations(requested_at DESC,id DESC)`. No index added here. Current live EXPLAIN
  (without ANALYZE) is Limit→Sort→Seq Scan. LIMIT bounds output/enrichment, **not base scan**;
  tiny estimated row count is not a latency/load test. Owner approval needed for any index.
- POST_LAUNCH: read audit, sampling/anomaly detection/statistics. Generic RBAC and School tenant
  authorization remain separate future design. Privileged writes need audit when introduced.
