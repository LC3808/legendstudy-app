# Admissions D-Day isolated database validation

This suite uses synthetic users/applications only, real PostgreSQL roles/RLS and
concurrent independent sessions. It never accepts a remote DSN and refuses to run
unless `SHOW data_directory` is `/private/tmp/legendstudy-dday-pg`.

Initialize a disposable PostgreSQL 17 cluster (macOS Homebrew example):

```sh
/opt/homebrew/opt/postgresql@17/bin/initdb -D /private/tmp/legendstudy-dday-pg -A trust --no-locale -E UTF8
/opt/homebrew/opt/postgresql@17/bin/pg_ctl -D /private/tmp/legendstudy-dday-pg -l /private/tmp/legendstudy-dday-pg.log -o '-p 55441 -k /private/tmp -c listen_addresses=' start
python3 supabase/validation/admissions_dday/test_postgres.py
```

The runner recreates only `admissions_dday_test` in that disposable cluster,
loads the actual application and D-Day migrations, adds the inspected lifecycle
gates and captured current `my_application_save` preimage, then installs the
candidate as a `NOSUPERUSER postgres` role. The limited
Auth/profile/university/admin helper fixture is explicit in `fixture.sql`; this
does not simulate the hosted PostgREST JWT verifier or the full account erasure
worker. Production checks and approval remain separate.

The suite exercises real `authenticated`/`anon` permissions, owner isolation,
application CRUD reconciliation, explicit track/unit matching, dismissal and
restoration, direct old-client D-Day deletion, immutable evidence, lifecycle
cascades, concurrent publication/application creation and repeated request keys.
It also installs the reviewed seed twice, activates anonymous sample headers,
checks row preservation and seed drift refusal, and finishes with the exact soft
rollback. The rollback restores the captured application RPC, keeps manual
D-Days and evidence, and prevents the client entry RPC from recreating schedules.

`reviewed_scope_fixture.json` contains public university identifiers and the 14
input scopes from the research summary. User/application identifiers are newly
generated locally; no real student's identifiers or event history are copied.
On 2026-11-20 KST these scopes yield 12 verified application-event links across
8 applications, 5 pending links and 10 distinct active targets. Later runs
calculate visible targets against their actual KST date; past, never-activated
schedules remain hidden. Seed installation itself does not create projections.

`result.json` records the actual run, exact source hashes, preservation hashes,
reviewed-seed and rollback outcomes. It is evidence for the isolated fixture,
not a claim of Production installation. Rollback retains inaccessible rows for
accounts already in deletion lifecycle until account erasure; it does not
bypass existing lifecycle gates.

`DDAY_TEST_PG_BIN` may select a PostgreSQL installation; it cannot change the
socket, port, database name or required data directory. Stop the test server when
finished; no source data is held there:

```sh
/opt/homebrew/opt/postgresql@17/bin/pg_ctl -D /private/tmp/legendstudy-dday-pg stop
```
