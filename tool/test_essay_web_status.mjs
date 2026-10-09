// Isolated projection/ACL checks. Lifecycle helper is a fixture, not a Production substitute.
// Run with PGLITE_MODULE pointing to an externally installed @electric-sql/pglite module.
const {PGlite}=await import(process.env.PGLITE_MODULE || '@electric-sql/pglite');
import fs from 'node:fs';
import assert from 'node:assert/strict';
const db=new PGlite();
await db.exec(`create role anon;create role authenticated;create role service_role;
create schema auth;create schema math_private;
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
create table math_private.runtime_control(singleton boolean primary key,evaluations_enabled boolean not null);
insert into math_private.runtime_control values(true,false);
alter table math_private.runtime_control enable row level security;
create function math_private.require_active(uuid[]) returns void language plpgsql as $$begin
if $1[1] is null or $1[1]<>'00000000-0000-4000-8000-000000000001'::uuid then raise insufficient_privilege;end if;end$$;`);
const migration=fs.readFileSync(new URL('../supabase/migrations/20261008001000_essay_web_runtime_status.sql',import.meta.url),'utf8');
await db.exec(migration);
let checks=0;
async function scalar(sql){return (await db.query(sql)).rows[0].value;}
for(const role of ['anon','service_role']){assert.equal(await scalar(`select has_function_privilege('${role}','public.essay_web_runtime_status()','EXECUTE') as value`),false);checks++;}
assert.equal(await scalar(`select has_function_privilege('authenticated','public.essay_web_runtime_status()','EXECUTE') as value`),true);checks++;
await db.exec('set role authenticated');
await assert.rejects(db.query('select public.essay_web_runtime_status()'),e=>e.code==='42501');checks++;
await db.exec("set request.jwt.claim.sub='00000000-0000-4000-8000-000000000001'");
assert.deepEqual(await scalar('select public.essay_web_runtime_status() as value'),{version:'essay-web-runtime-v1',math_evaluations_enabled:false});checks++;
await assert.rejects(db.query('select * from math_private.runtime_control'),e=>e.code==='42501');checks++;
await db.exec('reset role;update math_private.runtime_control set evaluations_enabled=true;set role authenticated');
assert.equal((await scalar('select public.essay_web_runtime_status() as value')).math_evaluations_enabled,true);checks++;
await db.exec("set request.jwt.claim.sub='00000000-0000-4000-8000-000000000002'");
await assert.rejects(db.query('select public.essay_web_runtime_status()'),e=>e.code==='42501');checks++;
await db.exec('reset role');await assert.rejects(db.exec(migration),/ESSAY_WEB_RUNTIME_COLLISION/);await db.exec('rollback');checks++;
assert.equal(await scalar('select evaluations_enabled as value from math_private.runtime_control'),true);checks++;
console.log(JSON.stringify({checks,passed:checks,scope:'isolated read projection; stubbed existing lifecycle helper',production_writes:0}));await db.close();
