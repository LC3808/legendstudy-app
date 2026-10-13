// Local real-Postgres integration check for the IAP ledger — items that pglite
// cannot cover: (A) the real `credit_summary` read RPC before/after a grant, and
// (B) TRUE concurrency across two INDEPENDENT connections for the same store
// transaction. Reuses the REAL migration SQL for every function (sliced from the
// canonical migrations); only minimal table DDL is inlined (sibling-fixture
// pattern). Requires the `pg` package and a LOCAL throwaway Postgres cluster —
// NEVER point PG* at a cloud/production database.
//
// Setup (throwaway local cluster; see the Phase A runbook):
//   export LC_ALL=C LANG=C
//   initdb -D "$PGDATA" -U postgres -E UTF8 --no-locale
//   pg_ctl -D "$PGDATA" -o "-p 55433 -c unix_socket_directories=/tmp -c listen_addresses=127.0.0.1" -l pg.log start
//   PGHOST=127.0.0.1 PGPORT=55433 PGUSER=postgres PGDATABASE=postgres \
//     NODE_PATH=<dir with pg> node supabase/verification/iap/pg_integration.mjs
//   pg_ctl -D "$PGDATA" stop && rm -rf "$PGDATA"   # cleanup
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
// Resolve `pg` from an absolute path (PG_MODULE) so the script runs from the
// repo root without a local node_modules (same pattern the sibling pglite
// fixtures use for PGLITE_MODULE). Connection comes from standard PG* env vars.
const pg = (await import(process.env.PG_MODULE)).default;
const { Client } = pg;
const USER = '11111111-1111-4111-8111-111111111111';

const read = p => readFile(p, 'utf8');
const between = (s, a, b) => s.slice(s.indexOf(a), b ? s.indexOf(b) : undefined);
const upto = (s, a, end = 'end$$;') => { const i = s.indexOf(a); return s.slice(i, s.indexOf(end, i) + end.length); };

const serverOps = await read('supabase/migrations/20260928000300_essay_server_operations.sql');
const commercial = await read('supabase/migrations/20260929000300_essay_credit_commercial_core.sql');
const lifecycle = await read('supabase/migrations/20261001000300_account_deletion_lifecycle.sql');
const runtime = await read('supabase/migrations/20261004000100_payment_runtime.sql');
let iap = await read('supabase/migrations/20261009000200_iap_verified_credit.sql');
iap = iap.replace('begin;', '').replace('commit;', '');

const fnClock = between(serverOps, 'create function essay_private.clock()', 'create function essay_private.hash');
const fnUid = between(serverOps, 'create function essay_private.uid()', 'create function essay_private.clock');
const fnPostGrant = between(commercial, 'create function essay_private.credit_post_grant', 'create function public.essay_claim_signup_credit');
const fnLifecycle = between(lifecycle, 'create function account_private.lock_subject', 'create function account_private.guard_request');
const fnSummary = upto(runtime, 'create function public.credit_summary');

const admin = new Client();
await admin.connect();
try {
  // Idempotent reset so the script can be rerun on the same throwaway cluster.
  await admin.query(`drop schema if exists essay_private cascade; drop schema if exists account_private cascade; drop schema if exists auth cascade;
    drop table if exists public.credit_transactions, public.credit_grants, public.credit_accounts, public.payment_orders, public.profiles, public.account_deletion_requests cascade;`);
  await admin.query(`
    do $$begin
      if not exists(select 1 from pg_roles where rolname='anon') then create role anon; end if;
      if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated; end if;
      if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role; end if;
    end$$;
    create schema auth; create schema essay_private; create schema account_private;
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    create function auth.role() returns text language sql stable as $$select current_setting('request.jwt.claim.role',true)$$;
    create table auth.users(id uuid primary key, created_at timestamptz not null default now());
    create table public.profiles(id uuid primary key);
    create table public.account_deletion_requests(subject_id uuid, state text);
    create table public.credit_accounts(id uuid primary key default gen_random_uuid(), user_id uuid unique references public.profiles(id) on delete set null, created_at timestamptz not null default now());
    create table public.credit_grants(id uuid primary key default gen_random_uuid(), account_id uuid not null references public.credit_accounts(id) on delete restrict,
      origin text not null check(origin in ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program')), external_reference text unique, expires_at timestamptz, created_at timestamptz not null default now());
    create table public.credit_transactions(id uuid primary key default gen_random_uuid(), account_id uuid not null references public.credit_accounts(id) on delete restrict, grant_id uuid not null, decision_id uuid,
      transaction_type text not null, balance_delta integer not null, reserved_delta integer not null, idempotency_key text not null unique, reversal_of uuid, reason_code text not null, actor_reference text, created_at timestamptz not null default now(),
      constraint credit_transactions_check check(
        (transaction_type in ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program','refund') and balance_delta>0 and reserved_delta=0)
        or (transaction_type='reserve' and balance_delta=0 and reserved_delta>0 and decision_id is not null)
        or (transaction_type='consume' and balance_delta<0 and reserved_delta=balance_delta and decision_id is not null)
        or (transaction_type='release' and balance_delta=0 and reserved_delta<0 and decision_id is not null)
        or (transaction_type='expiration' and balance_delta<0 and reserved_delta=0)
        or (transaction_type='adjustment' and balance_delta<>0 and reserved_delta=0)));
    create table public.payment_orders(grant_id uuid, state text);
  `);
  await admin.query(fnUid); await admin.query(fnClock); await admin.query(fnPostGrant);
  await admin.query(fnLifecycle); await admin.query(fnSummary); await admin.query(iap);
  await admin.query(`insert into auth.users(id) values($1)`, [USER]);
  await admin.query(`insert into public.profiles(id) values($1)`, [USER]);

  const summary = async (client) => {
    await client.query(`select set_config('request.jwt.claim.sub',$1,false)`, [USER]);
    await client.query(`select set_config('request.jwt.claim.role','authenticated',false)`);
    return (await client.query('select public.credit_summary() as s')).rows[0].s;
  };
  const grant = async (client, tx) => {
    await client.query(`select set_config('request.jwt.claim.role','service_role',false)`);
    const paid = (await client.query('select clock_timestamp() at')).rows[0].at;
    return (await client.query('select public.iap_post_verified_purchase($1,$2,$3,$4,$5) as status',
      [USER, 'apple', 'com.legendstudy.essay.credit3', tx, paid])).rows[0].status;
  };

  // A. credit_summary before/after a real grant; must equal the canonical ledger.
  const before = await summary(admin);
  assert.equal(before.spendable, 0); assert.equal(before.paid, 0);
  assert.equal(await grant(admin, 'APPLE.TX.A'), 'granted');
  const after = await summary(admin);
  const ledger = (await admin.query(`select coalesce(sum(t.balance_delta),0)::int amount from public.credit_transactions t join public.credit_grants g on g.id=t.grant_id join public.credit_accounts a on a.id=g.account_id where a.user_id=$1`, [USER])).rows[0].amount;
  assert.equal(after.spendable, 3); assert.equal(after.paid, 3); assert.equal(after.free, 0); assert.equal(after.other, 0);
  assert.equal(after.spendable, ledger);
  console.log(`A PASS credit_summary: spendable 0 -> ${after.spendable} (paid ${after.paid}), == ledger sum ${ledger}`);

  // B. True concurrency: two independent connections race the same transaction.
  const c1 = new Client(), c2 = new Client();
  await c1.connect(); await c2.connect();
  const TX = 'APPLE.TX.CONCURRENT';
  const race = async (client) => {
    await client.query('begin');
    await client.query(`select set_config('request.jwt.claim.role','service_role',true)`);
    const paid = (await client.query('select clock_timestamp() at')).rows[0].at;
    try {
      const s = (await client.query('select public.iap_post_verified_purchase($1,$2,$3,$4,$5) as status', [USER, 'apple', 'com.legendstudy.essay.credit3', TX, paid])).rows[0].status;
      await client.query('commit'); return s;
    } catch (e) { await client.query('rollback'); return 'error:' + e.message; }
  };
  const results = (await Promise.all([race(c1), race(c2)])).sort();
  const grantsForTx = (await admin.query(`select count(*)::int n from public.credit_grants where external_reference = 'iap/apple/'||encode(sha256(convert_to($1,'UTF8')),'hex')`, [TX])).rows[0].n;
  const paidAfter = (await summary(admin)).paid;
  await c1.end(); await c2.end();
  assert.deepEqual(results, ['already_processed', 'granted']);
  assert.equal(grantsForTx, 1);
  assert.equal(paidAfter, 6); // 3 (A) + 3 (one concurrent grant); the duplicate granted nothing
  console.log(`B PASS concurrency: 2 independent connections -> ${JSON.stringify(results)}, single grant (count ${grantsForTx}), paid ${paidAfter}`);
  console.log('ALL INTEGRATION CHECKS PASS');
} finally {
  await admin.end();
}
