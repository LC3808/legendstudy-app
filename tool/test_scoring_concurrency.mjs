/** Native PostgreSQL 17 only; creates/destroys a private Unix-socket cluster in /tmp.
 * No DSN accepted, TCP disabled, synthetic users/data only. Never connects to production.
 */
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {execFileSync} from 'node:child_process';
import {setTimeout as delay} from 'node:timers/promises';
import assert from 'node:assert/strict';
const root=process.env.LEGENDSTUDY_REPO ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const bin=process.env.SCORING_PG_BIN, driver=process.env.SCORING_PG_MODULE;
assert.ok(bin && path.isAbsolute(bin) && driver,'Set SCORING_PG_BIN and SCORING_PG_MODULE for external test dependencies');
const {default:pg}=await import(pathToFileURL(driver));
const {Client}=pg;
assert.match(execFileSync(path.join(bin,'postgres'),['--version'],{encoding:'utf8'}),/PostgreSQL\) 17\./);
const temporary=fs.mkdtempSync('/tmp/legendstudy-scoring-concurrency-');
fs.chmodSync(temporary,0o700);
const data=path.join(temporary,'data');
const socket=path.join(temporary,'sock');fs.mkdirSync(socket,{mode:0o700});
const connections=[];let started=false,groups=0;
const run=(name,args)=>execFileSync(path.join(bin,name),args,{encoding:'utf8',stdio:['ignore','pipe','pipe'],timeout:30000});
const uuid=n=>`10000000-0000-4000-8000-${String(n).padStart(12,'0')}`;
const A=uuid(1),B=uuid(2),source=uuid(3),content=uuid(4),subject=uuid(5);
const key1=uuid(6),key2=uuid(7),key3=uuid(8),cut1=uuid(9),cut2=uuid(10),cut3=uuid(11);
const pass=name=>{groups++;console.log('SCORING_CONCURRENT PASS '+name);};
let admin;
async function connection(){
 const c=new Client({host:socket,port:65431,user:'scoring_test_admin',database:'postgres',ssl:false,connectionTimeoutMillis:5000});
 await c.connect();connections.push(c);
 await c.query("set statement_timeout='10s'; set lock_timeout='8s';");
 c.pid=(await c.query('select pg_backend_pid() as pid')).rows[0].pid;
 return c;
}
async function begin(c,owner=null){
 await c.query('begin');
 if(owner){await c.query('set local role authenticated');await c.query("select set_config('request.jwt.claim.sub',$1,true)",[owner]);}
}
function pending(promise){return promise.then(value=>({value}),error=>({error}));}
async function blocked(waiter,blocker){
 const deadline=Date.now()+5000;
 while(Date.now()<deadline){
  const row=(await admin.query('select $2::int = any(pg_blocking_pids($1)) as blocked',[waiter.pid,blocker.pid])).rows[0];
  if(row.blocked) return;
  await delay(25);
 }
 throw new Error('Expected independent session lock wait was not observed');
}
async function success(p){const r=await p;if(r.error)throw r.error;return r.value;}
async function rejected(p,code){const r=await p;assert.equal(r.error?.code,code,'expected exact SQLSTATE');}
async function rpc(c,id,key=key1,cut=cut1){return (await c.query(
 'select public.submit_mock_attempt($1,null,$2,$3,\'mcq5-v1\',$4::jsonb) as result',
 [id,key,cut,JSON.stringify([{question_number:1,choice:1},{question_number:2,choice:5}])])).rows[0].result;}
async function draftKey(id,version,variant='common'){
 await admin.query(`insert into public.answer_key_versions(id,exam_subject_id,content_item_id,paper_variant,version,question_count,max_score,source_name,source_url,source_digest,fetched_at)
 values($1,$2,$3,$4,$5,3,9,'Synthetic concurrency','https://example.invalid/key',repeat('0',64),now())`,[id,subject,content,variant,version]);
 await admin.query('insert into public.exam_questions(answer_key_version_id,question_number,correct_answer,points) values($1,1,1,2),($1,2,2,3),($1,3,3,4)',[id]);
}
const publishKey=(c,id)=>c.query("update public.answer_key_versions set status='published',is_current=true,verified_at=statement_timestamp() where id=$1",[id]);
async function draftCut(id,version){await admin.query(`insert into public.grade_cutoff_versions(id,exam_subject_id,content_item_id,paper_variant,version,basis,certainty,max_score,minimum_scores,source_name,source_url,source_digest,fetched_at)
 values($1,$2,$3,'common',$4,'raw_absolute','confirmed',9,array[9,8,7,6,5,4,3,1,0]::smallint[],'Synthetic concurrency','https://example.invalid/cutoff',repeat('1',64),now())`,[id,subject,content,version]);}
const publishCut=(c,id)=>c.query("update public.grade_cutoff_versions set status='published',is_current=true,verified_at=statement_timestamp() where id=$1",[id]);
try{
 run('initdb',['-D',data,'-U','scoring_test_admin','--auth-local=trust','--auth-host=reject','--encoding=UTF8','--locale=C']);
 // Short socket path avoids the native Unix-domain pathname limit; no network listener.
 run('pg_ctl',['-D',data,'-l',path.join(temporary,'server.log'),'-o',`-k ${socket} -p 65431 -c listen_addresses='' -c unix_socket_permissions=0700 -c max_connections=10`,'-w','-t','20','start']);
 started=true;
 admin=await connection();const one=await connection(),two=await connection();
 console.log('SCORING_CONCURRENT PostgreSQL '+(await admin.query('show server_version')).rows[0].server_version+' private local cluster');
 await admin.query(`create role anon; create role authenticated; create role service_role bypassrls;
 create schema auth;create table auth.users(id uuid primary key);
 create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 grant usage on schema public,auth to anon,authenticated,service_role;grant execute on function auth.uid() to public;`);
 for(const f of fs.readdirSync(path.join(root,'supabase/migrations')).sort()){
  if(f>'20260914000200_mock_exam_scoring.sql')continue;
  await admin.query(fs.readFileSync(path.join(root,'supabase/migrations',f),'utf8'));
 }
 await admin.query('insert into auth.users values($1),($2)',[A,B]);
 await admin.query("insert into public.source_posts(id,source,external_post_id,url,title) values($1,'synthetic','concurrency','https://example.invalid/source','Synthetic')",[source]);
 await admin.query("insert into public.content_items(id,source_post_id,source_content_key,slug,content_type,title,source_url,is_active) values($1,$2,'concurrency','concurrency','exam','Synthetic','https://example.invalid/source',true)",[content,source]);
 await admin.query('insert into public.exams(content_item_id) values($1)',[content]);
 await admin.query("insert into public.exam_subjects(id,content_item_id,source_subject_key,is_active) values($1,$2,'synthetic',true)",[subject,content]);
 await draftKey(key1,1);await draftKey(key2,2);await draftKey(key3,3);
 await publishKey(admin,key1);
 await draftCut(cut1,1);await draftCut(cut2,2);await draftCut(cut3,3);await publishCut(admin,cut1);
 // Same UUID requests in independent sessions overlap on the advisory lock.
 await begin(one,A);const original=await rpc(one,uuid(20));
 await begin(two,A);let waiting=pending(rpc(two,uuid(20)));
 await blocked(two,one);await one.query('commit');
 assert.deepEqual(await success(waiting),original);await two.query('commit');
 assert.equal((await admin.query('select count(*)::int as n from public.mock_exam_attempts where id=$1',[uuid(20)])).rows[0].n,1);
 assert.equal((await admin.query('select count(*)::int as n from public.mock_exam_answers where attempt_id=$1',[uuid(20)])).rows[0].n,3);
 pass('same_id_overlapping_retry_one_result');
 // Submission wins key lock: demotion cannot commit until that submission commits.
 await begin(one,A);const beforeSwitch=await rpc(one,uuid(21));
 await begin(two);waiting=pending(two.query('update public.answer_key_versions set is_current=false where id=$1',[key1]));
 await blocked(two,one);await one.query('commit');await success(waiting);await publishKey(two,key2);await two.query('commit');
 await begin(one,A);assert.deepEqual(await rpc(one,uuid(21)),beforeSwitch);await one.query('commit');
 pass('submission_first_blocks_key_switch_old_retry');
 // Switch wins key lock: waiting new request rechecks current after the switch commits.
 await begin(one);await one.query('update public.answer_key_versions set is_current=false where id=$1',[key2]);await publishKey(one,key3);
 await begin(two,A);waiting=pending(rpc(two,uuid(22),key2));
 await blocked(two,one);await one.query('commit');await rejected(waiting,'23514');await two.query('rollback');
 await begin(two,A);const currentResult=await rpc(two,uuid(22),key3);await two.query('commit');assert.equal(currentResult.answer_key_version_id,key3);
 pass('key_switch_first_rechecks_waiting_submission');
 // Same ordering test for independent cutoff versions.
 await begin(one);await one.query('update public.grade_cutoff_versions set is_current=false where id=$1',[cut1]);await publishCut(one,cut2);
 await begin(two,A);waiting=pending(rpc(two,uuid(23),key3,cut1));
 await blocked(two,one);await one.query('commit');await rejected(waiting,'23514');await two.query('rollback');
 await begin(two,A);const currentCutResult=await rpc(two,uuid(23),key3,cut2);await two.query('commit');assert.equal(currentCutResult.grade_cutoff_version_id,cut2);
 pass('cutoff_switch_first_rechecks_waiting_submission');
 await begin(one,A);const cutoffBefore=await rpc(one,uuid(24),key3,cut2);
 await begin(two);waiting=pending(two.query('update public.grade_cutoff_versions set is_current=false where id=$1',[cut2]));
 await blocked(two,one);await one.query('commit');await success(waiting);await publishCut(two,cut3);await two.query('commit');
 await begin(one,A);assert.deepEqual(await rpc(one,uuid(24),key3,cut2),cutoffBefore);await one.query('commit');
 await begin(one,A);assert.deepEqual(await rpc(one,uuid(20)),original);await one.query('commit');
 pass('submission_first_blocks_cutoff_switch_both_old_versions_retry');
 // Two competing current promotions cannot both commit.
 const key4=uuid(30),key5=uuid(31);await draftKey(key4,4);await draftKey(key5,5);
 await begin(one);await one.query('update public.answer_key_versions set is_current=false where id=$1',[key3]);await publishKey(one,key4);
 await begin(two);waiting=pending(publishKey(two,key5));await blocked(two,one);await one.query('commit');await rejected(waiting,'23505');await two.query('rollback');
 assert.equal((await admin.query("select count(*)::int as n from public.answer_key_versions where paper_variant='common' and is_current")).rows[0].n,1);
 pass('competing_current_promotions_unique');
 // A draft question edit and publication serialize through the draft parent revision.
 const editing=uuid(32);await draftKey(editing,1,'edit-race');
 await begin(one);await one.query('update public.exam_questions set correct_answer=2 where answer_key_version_id=$1 and question_number=1',[editing]);
 await begin(two);waiting=pending(publishKey(two,editing));await blocked(two,one);await one.query('commit');await success(waiting);await two.query('commit');
 await begin(one,A);assert.equal((await rpc(one,uuid(33),editing,null)).raw_score,0);await one.query('commit');
 const publishing=uuid(34);await draftKey(publishing,1,'publish-race');
 await begin(one);await publishKey(one,publishing);
 await begin(two);waiting=pending(two.query('update public.exam_questions set correct_answer=2 where answer_key_version_id=$1 and question_number=1',[publishing]));
 await blocked(two,one);await one.query('commit');await rejected(waiting,'23514');await two.query('rollback');
 assert.equal((await admin.query('select correct_answer from public.exam_questions where answer_key_version_id=$1 and question_number=1',[publishing])).rows[0].correct_answer,1);
 pass('question_edit_publish_races_both_orders');
 console.log(`SCORING_CONCURRENT ${groups} groups PASS; independent READ COMMITTED sessions; not production JWT/REST`);
}catch(e){console.error('SCORING_CONCURRENT FAIL',e.code??'',e.message);process.exitCode=1;}
finally{
 for(const c of connections)try{await c.end();}catch{}
 if(fs.existsSync(path.join(data,'postmaster.pid')))started=true;
 if(started){try{run('pg_ctl',['-D',data,'-m','immediate','-w','-t','20','stop']);started=false;}catch{process.exitCode=1;console.error('SCORING_CONCURRENT FAIL temporary cluster stop; retained',temporary);}}
 if(!started){fs.rmSync(temporary,{recursive:true,force:true});console.log('SCORING_CONCURRENT private cluster/fixtures removed');}
}
