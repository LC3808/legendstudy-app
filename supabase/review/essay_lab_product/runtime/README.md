# Disposable PostgreSQL runtime validation package

**PREPARED / NOT_RUN. Not Production SQL.** Local PostgreSQL/psql unavailable and Docker
server unavailable at Final Review. No installation/start of a new database server attempted.

`run.py` refuses missing explicit consent, non-numeric-loopback hosts, databases not named
`essay_review_*`, populated databases and PostgreSQL before17. It never drops/resets a DB,
prints a DSN, calls AI or accesses real Owner/student data. All answer text is synthetic.
Use a **dedicated disposable cluster**, not a shared developer DB: auth role stubs are cluster roles.

Next phase prerequisites:
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
| 2 FK | Missing profile rejected; composite FKs in schema | Broaden cross-question/account attacks |
| 3 UNIQUE | Different posting key cannot double consume same decision/grant | Endpoint key reuse/payload mismatch |
| 4 CHECK | Invalid draft/device/revision rejected | Official evidence finalization |
| 5 owner RLS | UserA session/answer/result/issues/rewrite read, draft save | Full JWT/PostgREST |
| 6 anon denial | Private attempts query denied | All REST surfaces |
| 7 UserB isolation | Each UserA private relation invisible | Direct-write attack matrix |
| 8 service boundary | Server fixtures create results; clients denied | Narrow worker role + authorized submit RPC mandatory |
| 9 attempt immutable | Even table owner UPDATE raises | Erasure endpoint fencing |
| 10 evaluation immutable | Summary/dimension/progress updates rejected | Finalization result+settlement atomicity |
| 11 billing idempotency | Duplicate consume posting rejected | Refund cumulative bound validation |
| 12 duplicate request | Two connections, different UUIDs, same attempt/regime → one logical row | Same client UUID with changed payload must409 |
| 13 failure/refund | reserve→release, consume→refund; no failed-request consume | Provider-timeout/late-result reconciler |
| 14 concurrent request | Barrier + real independent PostgreSQL transactions | Backend lease fencing |
| 15 concurrent spend | One unit, account FOR UPDATE, two commands → one winner; balance0 | Use the real billing RPC once implemented |
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
- Spend A/B start at a barrier. Each transaction locks the same credit account BEFORE reading
  ledger availability. Winner inserts its authorization + reserve + consume and commits; loser
  wakes, observes0, declines. Test asserts one winner and no negative balance.
- Reposting consume with a different idempotency string hits the `(decision,grant,type)` UNIQUE.
  Multi-grant future payments permit one posting per allocation; one basic credit uses one grant.
- Lock order account→session→grants(sorted)→request must be identical in real RPCs. Reconcile
  unknown/timeout before releasing; a released worker cannot later publish/settle.

No CHECK constraint enforces aggregate nonnegative balance. Unrestricted service/DB-owner SQL
can bypass the reference protocol. **Runtime PASS here would not approve a service endpoint that
skips locking.** Next phase must replace/reference these transactions with actual RPC calls and
add late success, rollback between result/settlement, expired grants, simultaneous included-benefit
claims and cumulative refund tests. Until then the full runtime/production gate remains closed.

Student “own attempt CREATE: ALLOW” means **authenticated authorized submit endpoint**, not raw
INSERT into immutable fact tables. Direct INSERT remains denied. The endpoint must validate owner,
draft revision, numbering/hash and idempotency. No fake permissive submission RPC is added just to
make this review's RLS matrix green. Shared App/LAB account UUID must be verified separately.
