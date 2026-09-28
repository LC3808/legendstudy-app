# Disposable PostgreSQL runtime validation package

**Phase 2A: EXECUTED / PASS on disposable PostgreSQL17.11 (2026-09-28).**
[Sanitized result](runtime-result.json), [canonical runtime report](../../../../wiki/essay-lab-runtime-validation.md).
KEEP19. Production NOT_APPLIED; actual submit/billing endpoints NOT_READY.
Prior Final Review was NOT_RUN; that historical result is preserved. One runtime SQL bug fixed:
`current_time` conflicted with PostgreSQL CURRENT_TIME; renamed `assessment_time` only.

`run.py` refuses missing explicit consent, non-numeric-loopback hosts, databases not named
`essay_review_*`, populated databases and PostgreSQL before17. It never drops/resets a DB,
prints a DSN, calls AI or accesses real Owner/student data. All answer text is synthetic.
Use a **dedicated disposable cluster**, not a shared developer DB: auth role stubs are cluster roles.

Reproduction prerequisites:
1. Provision an empty disposable PostgreSQL17 DB named `essay_review_<unique>`, numeric
   loopback127.0.0.1 or::1; no Production tunnel. Supply a local superuser for fixture bootstrap.
2. Install `psycopg[binary]` in the test environment. Set `ESSAY_REVIEW_TEST_DSN` privately,
   never in Git/logs. Set `ESSAY_REVIEW_DISPOSABLE=YES`.
3. Run `python3 supabase/review/essay_lab_product/runtime/run.py`.
4. Save sanitized check names/results. Fixtures remain in the disposable DB for diagnosis;
   dispose of that cluster through its environment manager, never by resetting Production.

Applies actual existing initial content/foundation migration files as a **test baseline**, then
both current review drafts. The old initial migration's historical Day3 prohibition is not a
new production approval; this package is specifically an isolated future runtime validation.
Auth stub emulates `auth.uid()` and roles only; full Supabase/PostgREST/JWT behavior still needs
real local Supabase integration. No public RPC implementation is being claimed by this package.

## Required matrix and executable coverage

| Gate | Fixture/assertion | Remaining production-path gate |
|---|---|---|
| 1 clean apply | Actual baseline migrations + both drafts | Real Supabase local integration |
| 2 FK | Missing profile rejected; composite FKs in schema | Real endpoint owner/payload validation |
| 3 UNIQUE | Different posting key cannot double consume same decision/grant | Endpoint key reuse/payload mismatch |
| 4 CHECK | Invalid draft/device/revision rejected | Official evidence finalization |
| 5 owner RLS | UserA session/answer/result/issues/rewrite read, draft save | Full JWT/PostgREST |
| 6 anon denial | Private attempts query denied | All REST surfaces |
| 7 UserB isolation | Each UserA private relation invisible | Direct-write attack matrix |
| 8 service boundary | Service-role result INSERT tested/rolled back; clients denied | Narrow worker role + authorized submit RPC mandatory |
| 9 attempt immutable | Even table owner UPDATE raises | Erasure endpoint fencing |
| 10 evaluation immutable | Summary/dimension/progress updates rejected | Finalization result+settlement atomicity |
| 11 billing idempotency | Duplicate consume posting rejected | Refund cumulative bound validation |
| 12 duplicate request | Two connections, different UUIDs, same attempt/regime → one logical row | Same client UUID with changed payload must409 |
| 13 failure/refund | reserve→release, consume→refund; no failed-request consume | Provider-timeout/late-result reconciler |
| 14 concurrent request | Barrier + real independent PostgreSQL transactions | Backend lease fencing |
| 15 concurrent spend | One unit, full ordered locks, two commands → one winner; balance0 | Use the real billing RPC once implemented |
| 16 issue history | OPEN→IMPROVED→RESOLVED→RECURRED retained and queried | Matcher/normalization semantic review |
| 17 versions | Same attempt r1/X and r2/Y; growth query selects r1 only | Calibration not inferred from fixture |
| 18 deletion | Predecessor deletion preserves later observations; user erasure keeps detached ledger | External assets/provider/backup retention |

Additional executable checks: 12 history queries, growth2→3→3→4→4, included revision change,
failed-no-charge lookup, invalidation annotation single-use, terminal AI/grant/decision immutability,
behavior retention independent of core learning, model retry history.

## Exact concurrency protocol under test

Runner uses test-only inline SQL, **not a shipped billing engine**:
- Duplicate evaluations use partial UNIQUE `(attempt_id,regime_key)` for live/completed student
  requests; client UUID remains globally unique. Operator re-evaluation requires explicit path.
- Spend A/B start at a barrier. Each transaction locks account→session→sorted grants→request
  BEFORE reading ledger availability. Winner atomically publishes a synthetic result plus authorization/reserve/consume and commits; loser
  wakes, observes0, declines. Test asserts one winner and no negative balance.
- Reposting consume with a different idempotency string hits the `(decision,grant,type)` UNIQUE.
  Multi-grant future payments permit one posting per allocation; one basic credit uses one grant.
- Lock order account→session→grants(sorted)→request must be identical in real RPCs. Reconcile
  unknown/timeout before releasing; a released worker cannot later publish/settle.

No CHECK constraint enforces aggregate nonnegative balance. Unrestricted service/DB-owner SQL
can bypass the reference protocol. **Runtime PASS here would not approve a service endpoint that
skips locking.** Next phase must replace/reference these transactions with actual RPC calls and
add late success, rollback between result/settlement, expired grants, simultaneous included-benefit
claims and cumulative refund tests. The schema/reference runtime gate is PASS; the production endpoint/promotion gate remains closed.

Student “own attempt CREATE: ALLOW” means **authenticated authorized submit endpoint**, not raw
INSERT into immutable fact tables. Direct INSERT remains denied. The endpoint must validate owner,
draft revision, numbering/hash and idempotency. No fake permissive submission RPC is added just to
make this review's RLS matrix green. Shared App/LAB account UUID must be verified separately.

## Executed safety checks and result boundaries

`guard_checks.py` invokes the SAME runner with missing consent, a non-loopback host, wrong
DB prefix, populated PG17 and empty PG16.15 (negative version check only). All five REFUSED,
public/auth schema footprints unchanged. It requires consent and two private environment variables:
`ESSAY_REVIEW_TEST_DSN` (populated disposable17), `ESSAY_REVIEW_OLD_VERSION_DSN` (empty disposable16).
Both connections independently require numeric loopback/disposable prefix. Run with the same Python
as `run.py`; no DSNs/passwords are printed or stored in committed results. PG16 receives no baseline
or review SQL. Host/prefix/consent refusals occur before a network connection.

Runtime uses two separate connections and `Barrier(2)`, bounded lock/statement timeouts. Same
logical request test atomically records timeout+success synthetic runs, one completed result and
one consume. Distinct-request test starts with exactly one unit: winner1/loser1/balance0. No observed
deadlock; this is not a proof for all schedules. Rejected contender returns no result/consume;
actual endpoint rejection/recovery behavior is a subsequent implementation gate.

Q1–Q12 each assert expected row counts; selected queries also assert version/model, growth,
issue-state, stage, included-revision and cross-session recurrence values. RLS covers15 populated
private relations + operator-only telemetry denial; anon16 relations denied. Synthetic auth.uid()
models SQL role isolation only, not signed JWT/PostgREST authentication.

Homebrew PostgreSQL17/16 binaries were installed; ONLY separate /tmp clusters were started on
loopback, then stopped. No login service enabled, no production tunnel, no existing DB reset.
Test data remain outside Git in disposable local storage. Static validator intentionally still
reports its own `runtime: NOT_RUN`; actual runtime evidence is `runtime-result.json`.
