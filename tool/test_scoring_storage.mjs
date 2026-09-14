/** Offline only: in-memory PostgreSQL, synthetic fixtures, NO network/production DSN. */
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import assert from 'node:assert/strict';
const modulePath=process.env.PGLITE_MODULE;
if(!modulePath) throw new Error('Set PGLITE_MODULE to an externally installed @electric-sql/pglite dist/index.js');
const {PGlite}=await import(pathToFileURL(modulePath));
const root=process.env.LEGENDSTUDY_REPO ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const migration=process.env.SCORING_SQL ?? path.join(root,'supabase/migrations/20260914000200_mock_exam_scoring.sql');
const verification=process.env.SCORING_VERIFICATION ?? path.join(root,'supabase/verification');
const db=new PGlite();
let passed=0;
function pass(name){passed++;console.log('SCORING_LOCAL PASS '+name);}
async function reject(fn,codes=['23514']) {
 let failed=false;
 try{await fn();}catch(e){assert.ok(codes.includes(e.code),`unexpected code ${e.code}`);failed=true;}
 assert.ok(failed,'expected rejection');
}
async function role(name,id,fn) {
 await db.exec(`begin; set local role ${name};`);
 await db.query("select set_config('request.jwt.claim.sub',$1,true)",[id??'']);
 try {const result=await fn();await db.exec('commit');return result;}
 catch(e){await db.exec('rollback');throw e;}
}
const uuid=n=>`00000000-0000-4000-8000-${String(n).padStart(12,'0')}`;
const A=uuid(1), B=uuid(2), source=uuid(3), content=uuid(4), subject=uuid(5),key=uuid(6),cutoff=uuid(7),study=uuid(8),attempt=uuid(9);
const answers=[{question_number:1,choice:1},{question_number:2,choice:5}];
const rpc=(id=attempt,ss=study,k=key,g=cutoff,ans=answers,engine='mcq5-v1')=>db.query(
 'select public.submit_mock_attempt($1,$2,$3,$4,$5,$6::jsonb) as result',[id,ss,k,g,engine,JSON.stringify(ans)]);
const requestA=fn=>role('authenticated',A,fn);
try {
 const version=(await db.query('show server_version')).rows[0].server_version;
 assert.match(version,/^17\./,'test must use PostgreSQL 17');
 console.log('SCORING_LOCAL PostgreSQL '+version+' (in-memory; not JWT/REST)');
 await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
 create schema auth; create table auth.users(id uuid primary key);
 create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
 grant usage on schema public,auth to anon,authenticated,service_role; grant execute on function auth.uid() to public;`);
 for(const name of fs.readdirSync(path.join(root,'supabase/migrations')).sort()) {
  if(name >= '20260914000200') continue;
  await db.exec(fs.readFileSync(path.join(root,'supabase/migrations',name),'utf8'));
 }
 await db.exec(fs.readFileSync(path.join(verification,'mock_exam_scoring_preflight.sql'),'utf8'));
 await db.exec(fs.readFileSync(migration,'utf8'));
 await db.exec(fs.readFileSync(path.join(verification,'mock_exam_scoring_postflight.sql'),'utf8'));
 pass('preflight_migration_postflight_compiles');
 await db.exec(fs.readFileSync(path.join(verification,'mock_exam_scoring_rollback.sql'),'utf8'));
 assert.equal((await db.query("select to_regclass('public.mock_exam_attempts') as t")).rows[0].t,null);
 await db.exec(fs.readFileSync(migration,'utf8'));
 pass('empty_rollback_reapply');
 await db.query('insert into auth.users values($1),($2)',[A,B]);
 await db.query("insert into public.source_posts(id,source,external_post_id,url,title) values($1,'synthetic','scoring-test','https://example.invalid/source','Synthetic fixture')",[source]);
 await db.query("insert into public.content_items(id,source_post_id,source_content_key,slug,content_type,title,source_url,is_active) values($1,$2,'scoring-test','scoring-test','exam','Synthetic fixture','https://example.invalid/source',true)",[content,source]);
 await db.query('insert into public.exams(content_item_id) values($1)',[content]);
 await db.query("insert into public.exam_subjects(id,content_item_id,source_subject_key,is_active) values($1,$2,'synthetic',true)",[subject,content]);
 async function draft(id,version=1,variant='common',n=3,total=9){
  return db.query(`insert into public.answer_key_versions(id,exam_subject_id,content_item_id,paper_variant,version,question_count,max_score,
    source_name,source_url,source_digest,fetched_at) values($1,$2,$3,$4,$5,$6,$7,'Synthetic test','https://example.invalid/key',repeat('0',64),now())`,[id,subject,content,variant,version,n,total]);
 }
 async function publish(id){return db.query("update public.answer_key_versions set status='published',is_current=true,verified_at=statement_timestamp() where id=$1",[id]);}
 await role('service_role',null,()=>draft(key));
 assert.equal((await role('anon',null,()=>db.query('select id from public.answer_key_versions'))).rows.length,0);
 assert.equal((await role('anon',null,()=>db.query('select availability from public.mock_exam_scoring_availability'))).rows[0].availability,'timer_only');
 await reject(()=>publish(key));
 await db.query('insert into public.exam_questions(answer_key_version_id,question_number,correct_answer,points) values($1,1,1,2),($1,2,2,3),($1,3,3,4)',[key]);
 await publish(key);
 assert.equal((await role('anon',null,()=>db.query('select question_number from public.exam_questions'))).rows.length,3);
 assert.equal((await role('anon',null,()=>db.query('select availability from public.mock_exam_scoring_availability'))).rows[0].availability,'scoring_available');
 pass('publication_completeness_public_visibility');
 await reject(()=>db.query('update public.exam_questions set points=5 where answer_key_version_id=$1',[key]));
 await reject(()=>db.query('delete from public.exam_questions where answer_key_version_id=$1',[key]));
 await reject(()=>db.query("update public.answer_key_versions set source_name='Changed' where id=$1",[key]));
 await reject(()=>db.query("insert into public.exam_questions values($1,4,'numeric',2,3)",[key]));
 pass('published_immutable_unsupported_rejected');
 await reject(()=>db.exec(fs.readFileSync(path.join(verification,'mock_exam_scoring_rollback.sql'),'utf8')));
 await db.exec('rollback');
 pass('nonempty_rollback_refused');
 await db.query(`insert into public.grade_cutoff_versions(id,exam_subject_id,content_item_id,paper_variant,version,basis,certainty,max_score,minimum_scores,
 source_name,source_url,source_digest,fetched_at) values($1,$2,$3,'common',1,'raw_absolute','confirmed',9,array[9,8,7,6,5,4,3,1,0]::smallint[],
 'Synthetic test','https://example.invalid/cutoff',repeat('1',64),now())`,[cutoff,subject,content]);
 await db.query("update public.grade_cutoff_versions set status='published',is_current=true,verified_at=statement_timestamp() where id=$1",[cutoff]);
 await requestA(()=>db.query(`insert into public.study_sessions(id,mode,title,planned_duration_seconds,started_at,ended_at,active_segments)
 values($1,'mock_exam','Synthetic fixture',60,'2026-09-14T00:00Z','2026-09-14T00:01Z','[[0,60000]]')`,[study]));
 await requestA(()=>db.query("insert into public.profiles(id,display_name,grade_level,neis_office_code,neis_school_code,target_date,target_label) values($1,'Synthetic profile',1,'J10','7530932','2026-10-01','Synthetic target')",[A]));
 const profileBefore=(await db.query("select md5(to_jsonb(p)::text) as digest from public.profiles p where id=$1",[A])).rows[0].digest;
 const result=(await requestA(()=>rpc())).rows[0].result;
 assert.equal(result.raw_score,2);assert.equal(result.max_score,9);assert.equal(result.correct_count,1);
 assert.equal(result.unanswered_count,1);assert.equal(result.grade,8);assert.equal(result.grade_status,'confirmed');
 assert.equal(result.answers[0].awarded_points,2);assert.equal(result.answers[2].submitted_answer,null);
 pass('mixed_points_blank_server_scoring');
 assert.deepEqual((await requestA(()=>rpc())).rows[0].result,result);
 await reject(()=>requestA(()=>rpc(attempt,study,key,cutoff,[])),['23505']);
 pass('idempotent_retry_conflict');
 await reject(()=>requestA(()=>db.query('insert into public.mock_exam_attempts(id,user_id,raw_score) values($1,$2,100)',[uuid(10),A])),['42501']);
 await reject(()=>requestA(()=>db.query('update public.mock_exam_attempts set raw_score=9 where id=$1',[attempt])),['42501']);
 await reject(()=>requestA(()=>db.query('delete from public.mock_exam_answers where attempt_id=$1',[attempt])),['42501']);
 await reject(()=>role('anon',null,()=>rpc()),['42501']);
 pass('direct_mutation_and_anon_rpc_denied');
 // Trusted malformed partial attempt must fail its deferred consistency check.
 await reject(()=>db.exec(`insert into public.mock_exam_attempts select '${uuid(90)}'::uuid,user_id,null,exam_subject_id,paper_variant,answer_key_version_id,grade_cutoff_version_id,scoring_version,submitted_at,created_at,raw_score,max_score,question_count,correct_count,unanswered_count,grade,grade_status,request_payload from public.mock_exam_attempts where id='${attempt}'`));
 pass('deferred_partial_result_rejected');
 const read=()=>db.query('select id,raw_score from public.mock_exam_attempts where id=$1',[attempt]);
 assert.equal((await role('authenticated',B,read)).rows.length,0);
 assert.equal((await role('authenticated',B,()=>db.query('delete from public.mock_exam_attempts where id=$1 returning id',[attempt]))).rows.length,0);
 assert.equal((await role('authenticated',B,()=>db.query('select * from public.mock_exam_answers where attempt_id=$1',[attempt]))).rows.length,0);
 await reject(()=>role('authenticated',B,()=>rpc(uuid(11))),['23514']);
 assert.equal((await requestA(read)).rows.length,1);
 pass('owner_isolation_local_role_simulation');
 for(const invalid of [[{question_number:1,choice:1},{question_number:1,choice:2}], [{question_number:4,choice:1}],
  [{question_number:1,choice:0}],[{question_number:1,choice:6}],[{question_number:1,choice:'1'}],
  [{question_number:1,choice:1,raw_score:9}],{},null]) {
   await reject(()=>requestA(()=>rpc(uuid(12),null,key,null,invalid)),['22023']);
 }
 await reject(()=>requestA(()=>rpc(uuid(12),null,uuid(999))),['23514']);
 await reject(()=>requestA(()=>rpc(uuid(12),null,key,null,[],'fake-engine')),['22023']);
 pass('malformed_duplicate_unknown_answers_version');
 const empty=(await requestA(()=>rpc(uuid(12),null,key,null,[]))).rows[0].result;
 assert.equal(empty.raw_score,0);assert.equal(empty.grade,null);assert.equal(empty.grade_status,'unavailable');
 pass('no_cutoff_unavailable');
 // Every threshold and neighbour, using synthetic 100-point single-question vectors.
 for(const certainty of ['confirmed','estimated']) for(const raw of [0,19,20,29,30,39,40,49,50,59,60,69,70,79,80,89,90,100]){
   const bands=[90,80,70,60,50,40,30,20,0];
   const qs=raw===0?[[1,1,100]]:raw===100?[[1,1,100]]:[[1,1,raw],[2,2,100-raw]];
   const ans=raw===0?[null]:raw===100?[1]:[1,null];
   const got=(await db.query('select public.scoring_mcq5($1,$2,$3::smallint[],$4) as r',[JSON.stringify(qs),JSON.stringify(ans),bands,certainty])).rows[0].r;
   assert.equal(got.raw_score,raw);assert.equal(got.grade,bands.findIndex(v=>raw>=v)+1);assert.equal(got.grade_status,certainty);
 }
 for(const bands of [[9,8,7,6,5,4,3,3,0],[9,8,7,6,5,4,3,1,null],[9,8,7,6,5,4,3,1,1],[10,8,7,6,5,4,3,1,0]])
   assert.equal((await db.query('select public.scoring_cutoffs_valid($1::smallint[],9) as ok',[bands])).rows[0].ok,false);
 pass('grade_boundaries_and_ordering');
 const vectorFile=process.env.SCORING_VECTORS ?? path.join(root,'supabase/review/mock_scoring_vectors.json');
 for(const v of JSON.parse(fs.readFileSync(vectorFile,'utf8')).vectors){
  const r=(await db.query('select public.scoring_mcq5($1,$2,$3::smallint[],$4) as r',[JSON.stringify(v.questions),JSON.stringify(v.answers),v.minimum_scores,v.certainty])).rows[0].r;
  for(const [k,value] of Object.entries(v.expected)) assert.deepEqual(r[k],value,v.name+':'+k);
 }
 pass('shared_synthetic_vectors');
 const v2=uuid(13);await draft(v2,2);
 await db.query('insert into public.exam_questions select $1,question_number,answer_type,correct_answer,points from public.exam_questions where answer_key_version_id=$2',[v2,key]);
 await db.query('update public.exam_questions set correct_answer=2 where answer_key_version_id=$1 and question_number=1',[v2]);
 await reject(()=>publish(v2),['23505']);
 await db.query('update public.answer_key_versions set is_current=false where id=$1',[key]);await publish(v2);
 await reject(()=>requestA(()=>rpc(uuid(17),null,key,cutoff)),['23514']);
 const v2Result=(await requestA(()=>rpc(uuid(17),null,v2,cutoff))).rows[0].result;
 assert.equal(v2Result.raw_score,0);assert.equal(v2Result.answer_key_version_id,v2);
 assert.deepEqual((await requestA(()=>rpc())).rows[0].result,result);
 pass('current_key_new_submission_stale_rejection_original_retry');
 const cutoff2=uuid(18);
 await db.query(`insert into public.grade_cutoff_versions(id,exam_subject_id,content_item_id,paper_variant,version,basis,certainty,max_score,minimum_scores,source_name,source_url,source_digest,fetched_at)
 select $1,exam_subject_id,content_item_id,paper_variant,2,basis,certainty,max_score,array[9,8,7,6,5,4,2,1,0]::smallint[],source_name,source_url,source_digest,fetched_at from public.grade_cutoff_versions where id=$2`,[cutoff2,cutoff]);
 await db.exec('begin');
 await db.query('update public.grade_cutoff_versions set is_current=false where id=$1',[cutoff]);
 await db.query("update public.grade_cutoff_versions set status='published',is_current=true,verified_at=statement_timestamp() where id=$1",[cutoff2]);
 await db.exec('commit');
 await reject(()=>requestA(()=>rpc(uuid(19),null,v2,cutoff)),['23514']);
 const cutoff2Result=(await requestA(()=>rpc(uuid(19),null,v2,cutoff2,[{question_number:1,choice:2}]))).rows[0].result;
 assert.equal(cutoff2Result.raw_score,2);assert.equal(cutoff2Result.grade,7);
 assert.equal(cutoff2Result.grade_cutoff_version_id,cutoff2);
 assert.deepEqual((await requestA(()=>rpc())).rows[0].result,result);
 assert.deepEqual((await requestA(()=>rpc(uuid(17),null,v2,cutoff))).rows[0].result,v2Result);
 assert.equal((await db.query('select count(*)::int as n from public.mock_exam_attempts where id=$1',[uuid(19)])).rows[0].n,1);
 pass('current_cutoff_new_submission_stale_rejection_original_retry');
 await db.query("update public.answer_key_versions set status='withdrawn' where id=$1",[key]);
 assert.equal((await requestA(()=>rpc())).rows[0].result.raw_score,2);
 await reject(()=>requestA(()=>rpc(uuid(14),null,key)),['23514']);
 pass('correction_preserves_result_withdrawn_retry');
 await requestA(()=>db.query('delete from public.study_sessions where id=$1',[study]));
 const unlinked=(await requestA(()=>db.query('select id,study_session_id,raw_score from public.mock_exam_attempts where id=$1',[attempt]))).rows[0];
 assert.equal(unlinked.study_session_id,null);assert.equal(unlinked.raw_score,2);
 assert.equal((await requestA(()=>rpc())).rows[0].result.study_session_id,null);
 assert.equal((await requestA(()=>db.query('select * from public.mock_exam_answers where attempt_id=$1',[attempt]))).rows.length,3);
 pass('study_delete_set_null_attempt_survives_retry');
 await requestA(()=>db.query('delete from public.mock_exam_attempts where id=$1',[attempt]));
 assert.equal((await db.query('select * from public.mock_exam_answers where attempt_id=$1',[attempt])).rows.length,0);
 pass('attempt_delete_answers_cascade');
 // Scope checks: complete second variant must never accept common cutoffs.
 const other=uuid(15);await draft(other,1,'other');
 await db.query('insert into public.exam_questions select $1,question_number,answer_type,correct_answer,points from public.exam_questions where answer_key_version_id=$2',[other,key]);await publish(other);
 await reject(()=>requestA(()=>rpc(uuid(16),null,other,cutoff2)),['23514']);
 await db.query('update public.content_items set is_active=false where id=$1',[content]);
 assert.equal((await role('anon',null,()=>db.query('select id from public.answer_key_versions'))).rows.length,0);
 await reject(()=>requestA(()=>rpc(uuid(16),null,other,null)),['23514']);
 pass('variant_and_inactive_parent');
 assert.equal((await db.query("select md5(to_jsonb(p)::text) as digest from public.profiles p where id=$1",[A])).rows[0].digest,profileBefore);
 assert.equal((await db.query('select count(*)::int as n from auth.users')).rows[0].n,2);
 pass('profiles_untouched_auth_users_retained');
 console.log(`SCORING_LOCAL ${passed} groups PASS; production JWT/RPC still NOT RUN`);
} catch(e){console.error('SCORING_LOCAL FAIL',e.code??'',e.message,e.where??'');process.exitCode=1;}
finally{await db.close();}
