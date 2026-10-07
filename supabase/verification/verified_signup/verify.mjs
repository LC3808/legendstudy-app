// Run with PGLITE_MODULE pointing at an existing local @electric-sql/pglite module.
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
const { PGlite } = await import(process.env.PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
await db.exec(`create schema auth; create schema essay_private;
create role authenticated; create role essay_executor;
create table auth.users(id uuid primary key,created_at timestamptz,email_confirmed_at timestamptz);
create function essay_private.credit_signup_eligible(p_user uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from auth.users where id=p_user and created_at >= '2026-09-29T00:00:00Z'::timestamptz)
 $$;
revoke all on function essay_private.credit_signup_eligible(uuid) from public;
grant execute on function essay_private.credit_signup_eligible(uuid) to essay_executor;`);
const catalog = () => db.query(`select oid,proowner,proacl::text,prosecdef,provolatile,proconfig from pg_proc where oid='essay_private.credit_signup_eligible(uuid)'::regprocedure`);
const before=(await catalog()).rows;
const sql=await readFile(new URL('../../migrations/20261007150000_verified_signup_eligibility.sql',import.meta.url),'utf8');
await db.exec(sql);
assert.deepEqual((await catalog()).rows,before); // Identity, ownership, privileges and function properties unchanged.
for (const [suffix,created,confirmed,expected] of [
 [1,'2026-10-07',null,false], [2,'2026-10-07','2026-10-07',true],
 [3,'2026-09-01','2026-10-07',false], [4,'2026-09-29','2026-09-29',true],
]) {
 const id=`00000000-0000-4000-8000-00000000000${suffix}`;
 await db.query('insert into auth.users values($1,$2,$3)',[id,created,confirmed]);
 const r=await db.query('select essay_private.credit_signup_eligible($1) eligible',[id]);assert.equal(r.rows[0].eligible,expected);
}
assert.equal((await db.query("select essay_private.credit_signup_eligible('00000000-0000-4000-8000-000000000009') eligible")).rows[0].eligible,false);
await db.exec("update auth.users set email_confirmed_at=now() where id='00000000-0000-4000-8000-000000000001'");
for(let i=0;i<3;i++) assert.equal((await db.query("select essay_private.credit_signup_eligible('00000000-0000-4000-8000-000000000001') eligible")).rows[0].eligible,true);
await assert.rejects(db.exec(sql),/ALREADY_PRESENT_REVIEW_REQUIRED/);
await db.exec('rollback');
await db.exec("create or replace function essay_private.credit_signup_eligible(p_user uuid) returns boolean language sql stable security definer set search_path='' as $$select true$$");
await assert.rejects(db.exec(sql),/BODY_MISMATCH/);
await db.exec('rollback');
await db.close();
console.log('VERIFIED_SIGNUP_ELIGIBILITY: PASS (11 assertions; no hosted DB)');
