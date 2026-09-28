# Essay LAB Phase 2A — PostgreSQL Runtime Validation

2026-09-28 · **Runtime PASS / KEEP19 / Production NOT_APPLIED.**
Starting HEAD `ce2f754`, branch `codex/day-7-school-neis`. Final commit is the Git commit
containing this report, not a permanent current-HEAD declaration.

[Final schema review](essay-lab-final-schema-review.md) is accepted and preserved.
[Runtime contract](../supabase/review/essay_lab_product/runtime/README.md) and
[sanitized machine result](../supabase/review/essay_lab_product/runtime/runtime-result.json)
contain executable scope, input hashes, individual checks and remaining gates.

## Recommendation and meaning

| Gate | Result |
|---|---|
| PostgreSQL runtime | PASS — PostgreSQL17.11, actual independent transactions |
| RLS / history / billing-idempotency / concurrency | PASS within SQL-role + reference-protocol scope |
| 19-table schema | RUNTIME_VALIDATED; no table added/removed/merged |
| Production migration promotion | NO — actual server operations/integration and Owner review remain |
| Production endpoint ready | NO |
| Production connection / mutation / migration | NO / NO / NO |
| App/LAB shared auth.users.id | NOT_VERIFIED by this task |
| Real student data rollout | BLOCKED |

Runtime PASS verifies schema and the explicit **test/reference transaction protocol**. It does
not implement production endpoints, payment, AI worker, UI or shared login. No AI was called.
No Owner/student data or private Pilot bodies were used. All answer text is synthetic.

## Environment and guards

No existing PostgreSQL server or Docker daemon was available. Owner-authorized environment
preparation installed PostgreSQL17.11 and psycopg3.3.6. A separately initialized private `/tmp`
cluster listened only on numeric loopback, with empty `essay_review_*` databases. No production
tunnel, Supabase Production query or shared developer DB was used. Homebrew's default clusters
were not started. A second disposable16.15 instance served only the negative version guard.
Both test servers were stopped after validation; no login service was enabled. Binaries remain
installed; disposable synthetic files remain outside Git. No DSN/password in committed artifacts.

| Guard | Actual result |
|---|---|
| Missing explicit consent | REFUSED before connection |
| Non-loopback host | REFUSED before connection |
| Wrong DB prefix | REFUSED before connection |
| Populated PostgreSQL17 database | REFUSED; schema footprint unchanged |
| PostgreSQL16.15 | REFUSED before baseline/DDL; empty schema unchanged |

## Defects and minimal fixes

**P2A-01 — SCHEMA_BUG, SQLSTATE42883.** Clean DDL apply succeeded, but inserting the second
improvement observation failed inside `essay_product_progress_guard`:
`operator does not exist: timestamp with time zone >= time with time zone`.
PL/pgSQL `current_time` was interpreted as PostgreSQL CURRENT_TIME in the comparison.
Rename that local variable and its two references to `assessment_time`. No constraint, RLS,
immutability or idempotency protection removed. The actual chronological progress fixture now passes.
The static guard test uses the corrected identifier. This illustrates why parsing alone was insufficient.

**P2A-02 — TEST_FIXTURE_BUG.** The expanded Q7 test initially expected14 rows. The query correctly
joins only the viewed session's five attempts/six completed evaluations, producing12 rows for two
view stages; the separate session must not be included. Expect12 and assert both stages. No query or
schema relaxation. An intermediate Python quote syntax error was fixed before that runner executed.

Initial baseline failure and expanded-fixture failure were retained in local diagnostic logs;
only the final successful sanitized result is committed, with these failures explicitly recorded.
Original Phase1 and Final Review static reports remain unchanged historical records.

## Runtime coverage

77 named runtime assertions, five refusal cases, and30 offline static tests PASS. The77 include
12 individual query assertions and aggregate checks; they are not77 independent scenarios.
Static inventory remains19 tables /40 FKs /24 policies /9 PL/pgSQL functions. The static CLI's own
`runtime: NOT_RUN` field means that command does not connect; actual runtime evidence is separate.

| Boundary | Actual test |
|---|---|
| Clean apply | Existing initial content baseline → Essay foundation → both current review drafts |
| FK | Missing profile, cross-question dimension, wrong attempt/session, cross-account grant denied |
| UNIQUE | Duplicate client request key, semantic logical request, consume with a different posting key, repeated same-stage view denied |
| CHECK | Invalid draft/device/revision and dimension level6 denied |
| Owner RLS | Own15 populated private relations readable; draft CAS save succeeds; stale revision denied |
| Other-user RLS | UserA rows invisible across15 relations; draft and target forgery denied/no affected rows |
| Anonymous | All16 private/operational relations deny read/insert; direct delete also denied |
| Client write boundary | Session/attempt/AI result/dimension/progress/rewrite/event/ledger direct insert/update/delete denied |
| Provider telemetry | Owner and other user denied |
| Service boundary | Result INSERT succeeds and test rolls back; ledger DELETE denied |
| Immutability | Submitted answer, terminal result/dimension/progress/rewrite/provider run, ledger, grant and settled decision updates denied |
| Version coexistence | Same answer keeps v1.2/modelX and v2/modelY; growth uses r1 only |
| Improvement history | OPEN→IMPROVED→RESOLVED→RECURRED plus later IMPROVED all remain |
| Model retention | Removing operational run does not erase model context frozen on evaluation |
| Deletion | Prior answer erasure detaches predecessor pointer but preserves later observations; user learning cascade leaves detached account/ledger |

Owner “submit CREATE” still requires the future authorized server endpoint; direct table INSERT
was not granted to make a test pass. The fixture's minimal auth.uid()/SQL roles are not a full
Supabase JWT/PostgREST authentication test. Service-role bypass is not narrow worker authorization.

## Twelve executed history queries

No bodies are copied into reports. Row counts are assertions, with semantic assertions noted.

| Query | Result / rows | Checked meaning |
|---|---|---|
| Q1 | PASS /6 | Immutable answer timeline, including separate practice cycle |
| Q2 | PASS /6 | Dimension history, v1.2/X and v2/Y retained |
| Q3 | PASS /6 | Local issue observations, first four states preserved |
| Q4 | PASS /5 | Same criterion/regime levels2→3→3→4→4 |
| Q5 | PASS /1 | University-scoped reviewed normalized category |
| Q6 | PASS /1 | Included revision level2→3; issue OPEN→IMPROVED |
| Q7 | PASS /12 | First-result and second-result example views with related times |
| Q8 | PASS /7 | Model versions and timeout/success provider history |
| Q9 | PASS /6 | Paid/refund/release postings and zero-charge decision |
| Q10 | PASS /1 | Failed request, reservation released, no consume |
| Q11 | PASS /1 | Reviewed cross-session resolved→open recurrence candidate |
| Q12 | PASS /1 | University submissions6, rewrites4, time/length facts |

These synthetic results prove query representation, not real educational improvement or calibrated
model quality. Different university criterion identities and evaluation regimes remain distinct.

## Billing, retry and concurrency

First assessment: promotional credit1→reserve→consume; remaining0. First revision has a settled
`included_revision` decision with0 credits and paid-cycle parent; policy/version recorded. SQL does
not price by attempt_no. A refund appends+1 without changing the original consume. A failed request
reserves then releases, leaves no consume and restores availability. Additional revision uses an
explicit paid decision in the concurrency fixture.

| Actual two-connection race | Result |
|---|---|
| Same logical evaluation, separate request UUIDs | Winner1 / duplicate1; logical evaluation1; consume1 |
| Last available credit1, two distinct requests | Winner1 / loser1; available0; both-success NO; negative NO |
| Lock order | account → session → grants sorted by ID → request |
| Deadlock | None observed in these bounded runs; not a proof for every interleaving |

Workers start at `Barrier(2)` on independent PostgreSQL connections. Lock/statement timeouts bound
failures. The losing last-credit request produces no consume. The successful reference transaction
publishes its synthetic result and settlement together. Duplicate-request fixture records run1
unknown/timeout and run2 success/selected, one completed evaluation and exactly one consume.
This records retry history; it does not call a provider or implement a production late-result reconciler.

Example view1 is after first evaluation; view2 of that same example is after second evaluation.
A new event UUID in the same meaningful stage still hits UNIQUE. Event retention can remove those
views without erasing submitted answers. No autosave/click stream or permanent growth narrative added.

## Remaining production gates and next action

1. Owner/ChatGPT review of this runtime result.
2. Implement authorized submit/finalize/billing/erasure server transactions and narrow worker rights.
3. Test real Supabase JWT/PostgREST and actual endpoints, including payload mismatch, fencing,
   late success, rollback between result/settlement, grant expiry, cumulative refunds and competing
   included-revision claims. Aggregate balances are protected by locking protocol, not row CHECK alone.
4. Verify App/LAB same auth.users.id before real student data; complete privacy/rights/retention review.
5. Only then separately authorize migration promotion, Production apply and validation, followed by UI.

No Production SQL is requested from Owner now. No further AI, UI or migration work performed.
Owner iOS files and pre-existing untracked files preserved; focused diff/secret/Wiki checks PASS.
