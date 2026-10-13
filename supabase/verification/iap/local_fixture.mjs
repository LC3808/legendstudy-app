// Local, isolated pglite fixture builder for the IAP ledger test.
//
// Builds the canonical Credit-ledger prerequisites into the `IAP_TEST_DB`
// directory so the unmodified `behavior.mjs` in this folder can run offline,
// with NO cloud/production database. It reuses the REAL migration SQL for the
// function bodies (sliced from the canonical migrations) and inlines only the
// minimal table DDL, mirroring the sibling verification fixtures
// (e.g. admin_members/directory.mjs). It is test-only; it is not the production
// schema and must never point at a live database.
//
// Usage (see iap-sandbox-phaseA-runbook for the full runbook):
//   PGLITE_MODULE=<abs>/@electric-sql/pglite/dist/index.js \
//   PGCRYPTO_MODULE=<abs>/@electric-sql/pglite/dist/contrib/pgcrypto.js \
//   IAP_TEST_DB=/abs/path/to/empty/dir \
//   node supabase/verification/iap/local_fixture.mjs && \
//   node supabase/verification/iap/behavior.mjs
import { readFile } from 'node:fs/promises';
const { PGlite } = await import(process.env.PGLITE_MODULE);
const DIR = process.env.IAP_TEST_DB;
if (!DIR || DIR.includes('://')) throw new Error('IAP_TEST_DB must be an isolated directory path');

const slice = (sql, from, to) => sql.slice(sql.indexOf(from), to ? sql.indexOf(to) : undefined);
const serverOps = await readFile('supabase/migrations/20260928000300_essay_server_operations.sql', 'utf8');
const commercial = await readFile('supabase/migrations/20260929000300_essay_credit_commercial_core.sql', 'utf8');
const clockFn = slice(serverOps, 'create function essay_private.clock()', 'create function essay_private.hash');
const postGrantFn = slice(commercial, 'create function essay_private.credit_post_grant', 'create function public.essay_claim_signup_credit');

const db = new PGlite(DIR);
try {
  await db.exec(`
    do $$begin
      if not exists(select 1 from pg_roles where rolname='anon') then create role anon; end if;
      if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated; end if;
      if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role; end if;
      if not exists(select 1 from pg_roles where rolname='postgres') then create role postgres; end if;
    end$$;
    create schema if not exists auth;
    create schema if not exists essay_private;
    create schema if not exists account_private;
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    create table if not exists auth.users(id uuid primary key, created_at timestamptz not null default now());
    create table if not exists public.profiles(id uuid primary key);
    create table if not exists public.credit_accounts(
      id uuid primary key default gen_random_uuid(),
      user_id uuid unique references public.profiles(id) on delete set null,
      created_at timestamptz not null default now());
    create table if not exists public.credit_grants(
      id uuid primary key default gen_random_uuid(),
      account_id uuid not null references public.credit_accounts(id) on delete restrict,
      origin text not null check(origin in ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program')),
      external_reference text unique,
      expires_at timestamptz,
      created_at timestamptz not null default now());
    create table if not exists public.credit_transactions(
      id uuid primary key default gen_random_uuid(),
      account_id uuid not null references public.credit_accounts(id) on delete restrict,
      grant_id uuid not null,
      decision_id uuid,
      transaction_type text not null,
      balance_delta integer not null,
      reserved_delta integer not null,
      idempotency_key text not null unique,
      reversal_of uuid,
      reason_code text not null,
      actor_reference text,
      created_at timestamptz not null default now(),
      constraint credit_transactions_check check(
        (transaction_type in ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program','refund') and balance_delta>0 and reserved_delta=0)
        or (transaction_type='reserve' and balance_delta=0 and reserved_delta>0 and decision_id is not null)
        or (transaction_type='consume' and balance_delta<0 and reserved_delta=balance_delta and decision_id is not null)
        or (transaction_type='release' and balance_delta=0 and reserved_delta<0 and decision_id is not null)
        or (transaction_type='expiration' and balance_delta<0 and reserved_delta=0)
        or (transaction_type='adjustment' and balance_delta<>0 and reserved_delta=0)));
  `);
  await db.exec(clockFn);      // real essay_private.clock()
  await db.exec(postGrantFn);  // real essay_private.credit_post_grant()
  // account_private.allowed() requires auth.users rows for the subjects that
  // behavior.mjs operates on (the canonical fixture carries these identities).
  await db.exec(`insert into auth.users(id) values
    ('11111111-1111-4111-8111-111111111111'),
    ('22222222-2222-4222-8222-222222222222') on conflict do nothing;`);
  console.log('IAP local ledger fixture ready ->', DIR);
} finally {
  await db.close();
}
