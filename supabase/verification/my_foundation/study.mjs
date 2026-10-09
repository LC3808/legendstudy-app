import {readFileSync} from 'node:fs';import assert from 'node:assert/strict';
const {PGlite}=await import(process.env.PGLITE_MODULE);const db=new PGlite();
await db.exec(`create role anon;create role authenticated;create role service_role;create schema auth;create schema account_private;create schema student_private;
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
create table auth.users(id uuid primary key);create table account_deletion_requests(subject_id uuid,state text);`);
const lifecycle=readFileSync('supabase/migrations/20261001000300_account_deletion_lifecycle.sql','utf8');
await db.exec(lifecycle.slice(lifecycle.indexOf('create function account_private.lock_subject'),lifecycle.indexOf('create function account_private.guard_request')));
await db.exec(readFileSync('supabase/migrations/20260914000100_study_sessions.sql','utf8'));
// Same additive column/check as deployed APP include_in_study_total migration; no timer logic stub.
await db.exec(`alter table study_sessions add column include_in_study_total boolean not null default true;alter table study_sessions add constraint study_sessions_timer_included check(mode='mock_exam' or include_in_study_total);`);
await db.exec(readFileSync('supabase/migrations/20261008000700_shared_study_summary.sql','utf8'));
const a='00000000-0000-4000-8000-000000000001',b='00000000-0000-4000-8000-000000000002';let key=10;
await db.exec(`insert into auth.users values('${a}'),('${b}')`);
const add=(start,end,segments,owner=a,include=true)=>db.query('insert into study_sessions(id,user_id,mode,title,planned_duration_seconds,started_at,ended_at,active_segments,include_in_study_total) values($1,$2,$3,$4,$5,$6,$7,$8,$9)',[`00000000-0000-4000-8000-${String(++key).padStart(12,'0')}`,owner,include?'study':'mock_exam',include?null:'test',include?null:3600,start,end,JSON.stringify(segments),include]);
await add('2026-10-07T14:30:00Z','2026-10-07T15:30:00Z',[[0,3600000]]); // midnight KST crossing, 30m each day
await add('2026-10-07T15:00:00Z','2026-10-07T16:00:00Z',[[0,3600000]]); // second device overlap, union today 60m
await add('2026-10-07T16:00:00Z','2026-10-07T17:00:00Z',[[0,900000],[2700000,3600000]]); // pauses: 30m
await add('2026-10-07T17:00:00Z','2026-10-07T18:00:00Z',[[0,3600000]],a,false);
await add('2026-10-07T17:00:00Z','2026-10-07T18:00:00Z',[[0,3600000]],b);
await add('2026-10-03T02:00:00Z','2026-10-03T03:00:00Z',[[0,3600000]]); // prior week Saturday
const query=async(owner)=> (await db.query("select student_private.study_summary($1,'2026-10-08T10:00:00Z') value",[owner])).rows[0].value;
let s=await query(a);assert.equal(s.today_ms,5400000);assert.equal(s.week_ms,7200000);assert.equal(s.last30_ms,10800000);assert.equal(s.daily7.length,7);assert.equal(s.daily7[6].milliseconds,5400000);
assert.equal((await query(b)).today_ms,3600000);
await db.exec(`set role anon`);await assert.rejects(db.query('select my_study_summary()'),e=>e.code==='42501');
await db.exec(`reset role;set role authenticated;select set_config('request.jwt.claim.sub','${a}',false)`);
await assert.rejects(db.query('select student_private.study_summary($1,now())',[b]),e=>e.code==='42501');
await db.exec(`reset role;insert into account_deletion_requests values('${a}','DELETION_PENDING');set role authenticated;`);
await assert.rejects(db.query('select my_study_summary()'),e=>e.code==='42501');
await db.exec(`reset role;delete from study_sessions;`);assert.equal((await query(a)).last30_ms,0);
console.log('STUDY_SQL PASS: KST midnight, Monday week, 30d, 7d, overlap/paused/excluded sessions, owner isolation, anonymous/private/lifecycle deny and empty totals');await db.close();
