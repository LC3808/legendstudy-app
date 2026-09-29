# Essay LAB submit timing — narrow forward correction

2026-09-29. Owner separately approved this correction after accepting the
[Scaffolding persistence result](essay-lab-scaffolding-persistence.md).
**Production DEPLOYED** — [apply evidence](essay-lab-scaffolding-production-apply.md). No AI, real student data, UI or billing change.

## Root cause and exact correction

Original migration003 used PostgreSQL `LEAST`, which ignores NULL arguments,
and numeric→integer cast, which rounds. Unknown active time could become a
measurement; at0.7 seconds the expression could return1 and violate the existing
`active_writing_seconds <= extract(epoch from submitted_at-started_at)` CHECK.

[Forward migration20260929000200](../supabase/migrations/20260929000200_essay_submit_timing_correction.sql)
replaces only this expression inside the existing `essay_submit_attempt`:

```sql
case when d.active_writing_seconds is null then null
else least(
  d.active_writing_seconds,
  greatest(0, floor(extract(epoch from now()-d.started_at))::int)
) end
```

NULL remains unknown; known integer active time is capped by floored elapsed time.
The RPC and submitted_at default use the same transaction `now()`. The separate
submitted_at>=started_at CHECK stays intact; future starts are not silently repaired.
No existing migration, submitted answer, history or CHECK is edited. Ownership,
fixed search_path, SECURITY DEFINER, signature and ACL are retained by CREATE OR
REPLACE. Temporary executor membership is revoked before commit. Submission
fingerprint, numbering, owner checks, CAS, idempotency, lock order and billing are
byte-for-byte unchanged. KEEP19; no added column/table/RPC.

## Deterministic tests

[Runner](../supabase/validation/essay_lab_product/submit_timing_runtime.py) reuses
the existing numeric-loopback, empty-database, explicit-consent guards. It cannot
prepare a remote or populated database. Only synthetic users/answers are used.

A **disposable-only** fixture RPC sets its own synthetic draft started_at to
transaction `now()-elapsed`, advances draft revision legally, then invokes the
actual public submit RPC in that same transaction. No sleep is used to approximate
time. The submit implementation/clock is not substituted. The fixture is removed
in cleanup and is absent from all migrations. Actual Auth-issued JWT/PostgREST
also invokes this fixture; additional submissions and every duplicate/stale/
payload/other-user request call `essay_submit_attempt` directly.

Matrix: elapsed0,0.1,0.5,0.7,0.99,1,1.1,2,2.99,10 seconds × activeNULL,0,1,2,20.
This includes unknown, zero, subsecond, exact integer, below/equal/above elapsed.
Assert exact persisted interval, active value, hash/count/number; duplicate returns
one attempt; changed payload/stale revision409 and other-user403. Direct unknown/
zero/known submissions also pass. Replacement preserves existing result/answer/
progress/ledger snapshots, CHECK definitions and owner/ACL/security settings.

[Sanitized runtime result](../supabase/validation/essay_lab_product/submit_timing_result.json)
records executed counts and exact tested source hashes. Existing Scaffolding
migration, adapter, runtime result and review contract are accepted and preserved.

Test-harness corrections during validation: native float argument did not resolve
the numeric fixture signature (42883), so use exact decimal strings. PostgREST
OpenAPI excluded the fixture for service_role as required by its restricted ACL;
cache readiness now probes a non-existent context through the authenticated RPC
and requires403, without adding privileges. Neither change affected product code.

## Executed results

| Suite | Result |
|---|---|
| Deterministic submit + boundary assertions | PostgreSQL306 / actual JWT306 PASS |
| Phase2A / Phase2B after correction |77 /55 PASS |
| Scaffolding1.3 |native80 / JWT79 PASS |
| Existing JWT regression |37 before /37 after Scaffolding migration PASS |
| Static migration/security/adapter + review |32 +55 PASS |
| New regression |None observed |

The pre-Scaffolding1.2 request is claimed before that migration and completed after
it. Correction is already present in both legacy JWT passes. No legacy result is
converted to1.3. Existing accepted Scaffolding artifacts remain byte-for-byte unchanged.

## Deployment boundary

The original correction task performed no Production operation. Owner subsequently
approved both forward migrations; the linked read-only Production report confirms
application. Original runtime artifacts remain unchanged historical evidence.
Privacy/provider/retention gates remain independent. Next: separately approved AI Pilot.
