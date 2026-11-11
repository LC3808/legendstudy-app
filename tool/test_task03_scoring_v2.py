"""Disposable PostgreSQL 17 only. TCP disabled; no DSN/config/production access."""
import json,os,subprocess,tempfile,uuid
from pathlib import Path
R=Path(__file__).resolve().parents[1];PG=Path('/opt/homebrew/opt/postgresql@17/bin')
def main():
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 def run(args,**kw):return subprocess.run(list(map(str,args)),text=True,capture_output=True,env=env,**kw)
 with tempfile.TemporaryDirectory(prefix='task03-pg-') as td:
  d=Path(td);sock=d/'s';sock.mkdir();db=d/'db'
  r=run([PG/'initdb','-D',db,'-U','postgres','--auth=trust','--encoding=UTF8']);assert r.returncode==0,r.stderr
  r=run([PG/'pg_ctl','-D',db,'-l',d/'log','-o',f"-k {sock} -c listen_addresses=''",'-w','start']);assert r.returncode==0,r.stderr
  def sql(s,error=None):
   r=run([PG/'psql','-XqAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','postgres'],input=s)
   if error:assert r.returncode and error in r.stderr,r.stderr;return
   assert r.returncode==0,r.stderr
   return r.stdout.strip()
  def uid(n):return f'00000000-0000-4000-8000-{n:012}'
  def lit(v):return "'"+json.dumps(v,separators=(',',':')).replace("'","''")+"'::jsonb"
  a,b,source,content,subject,key,attempt=[uid(n) for n in range(1,8)]
  def rpc(keyid,attemptid,answers,engine='mixed-v2',who=a):
   return f"set role authenticated;set request.jwt.claim.sub='{who}';select public.submit_mock_attempt('{attemptid}',null,'{keyid}',null,'{engine}',{lit([{'question_number':i+1,'choice':v} for i,v in enumerate(answers)])});"
  try:
   sql("create role anon;create role authenticated;create role service_role bypassrls;create schema auth;create table auth.users(id uuid primary key);create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;grant usage on schema public,auth to anon,authenticated,service_role;grant execute on function auth.uid() to public;")
   for f in sorted((R/'supabase/migrations').glob('*.sql')):
    if f.name<='20260914000200_mock_exam_scoring.sql':sql(f.read_text())
   legacy=sql("select public.scoring_mcq5('[[1,1,2],[2,2,3]]','[1,null]',null,'unavailable');")
   sql(f"insert into auth.users values('{a}'),('{b}');insert into source_posts(id,source,external_post_id,url,title) values('{source}','synthetic','v2','https://example.invalid/v2','Synthetic');insert into content_items(id,source_post_id,source_content_key,slug,content_type,title,source_url,is_active) values('{content}','{source}','v2','v2','exam','Synthetic','https://example.invalid/v2',true);insert into exams(content_item_id) values('{content}');insert into exam_subjects(id,content_item_id,source_subject_key,is_active) values('{subject}','{content}','synthetic',true);")
   old_key,old_attempt=uid(40),uid(41)
   sql(f"insert into answer_key_versions(id,exam_subject_id,content_item_id,paper_variant,version,question_count,max_score,source_name,source_url,source_digest,fetched_at) values('{old_key}','{subject}','{content}','legacy',1,2,5,'Synthetic','https://example.invalid/legacy',repeat('1',64),now());insert into exam_questions(answer_key_version_id,question_number,correct_answer,points) values('{old_key}',1,1,2),('{old_key}',2,2,3);update answer_key_versions set status='published',is_current=true,verified_at=now() where id='{old_key}';")
   old_result=json.loads(sql(rpc(old_key,old_attempt,[1,None],engine='mcq5-v1')))
   before=sql(f"select to_jsonb(a) from mock_exam_attempts a where id='{old_attempt}';")
   sql((R/'supabase/candidates/task03_scoring_v2/candidate.sql').read_text())
   assert sql(f"select to_jsonb(a) from mock_exam_attempts a where id='{old_attempt}';")==before
   migrated=json.loads(sql(rpc(old_key,old_attempt,[1,None],engine='mcq5-v1')))
   for field,value in old_result.items():
    if field=='answers':
     for old,new in zip(value,migrated[field]):
      assert all(new[k]==v for k,v in old.items())
    else:assert migrated[field]==value,(field,value,migrated[field])

   shared=json.loads((R/'supabase/candidates/task03_scoring_v2/synthetic_vectors.json').read_text())
   for v in shared['vectors']:
    cut='null' if v['minimum_scores'] is None else "array"+str(v['minimum_scores'])+"::smallint[]"
    result=json.loads(sql(f"select public.scoring_mixed_v2({lit(shared['questions'])},{lit(v['answers'])},{cut},'{v['certainty']}');"))
    assert result==v['expected'],(v['name'],result)
   # Official local fixtures use the same existing SQL engine; no production DSN.
   from task03a_packages import papers,engine_questions,vectors
   official_count=0
   for paper in papers():
    qs=engine_questions(paper)
    for name,answers,expected in vectors(paper):
     result=json.loads(sql(f"select public.scoring_mixed_v2({lit(qs)},{lit(answers)},null,'unavailable');"))
     assert result['raw_score']==expected,(paper['academic_year'],paper['exam_month'],paper['subject_label'],name,result)
     assert result['max_score']==paper['max_score'] and result['grade'] is None
     official_count+=1
   print(f'PASS: {official_count} official-paper SQL scoring vectors')
   assert sql("select public.scoring_mcq5('[[1,1,2],[2,2,3]]','[1,null]',null,'unavailable');")==legacy

   sql(f"insert into answer_key_versions(id,exam_subject_id,content_item_id,paper_variant,version,question_count,max_score,source_name,source_url,source_digest,fetched_at,scoring_version) values('{key}','{subject}','{content}','synthetic-mixed',1,4,10,'Synthetic','https://example.invalid/v2',repeat('0',64),now(),'mixed-v2');")
   for i,t,ans,ac,pts in [(1,'multiple_choice',[1,3],False,2),(2,'numeric',[0],False,3),(3,'numeric',[999],False,3),(4,'multiple_choice',[],True,2)]:
    sql(f"insert into exam_questions(answer_key_version_id,question_number,answer_type,correct_answer,points,accepted_answers,all_credit,question_id) values('{key}',{i},'{t}',null,{pts},array{ans}::smallint[],{str(ac).lower()},'{uid(20+i)}');")
   publish=f"update answer_key_versions set status='published',is_current=true,verified_at=now() where id='{key}';"
   sql(publish,'KEY_NOT_READY')
   sql(f"update answer_key_versions set verification_status='PARTIAL' where id='{key}';")
   sql(publish,'KEY_NOT_READY')
   sql("set role anon;select public.scoring_mixed_v2('[]','[]',null,'unavailable');",'permission denied')
   assert sql(f"set role anon;select count(*) from answer_key_versions where id='{key}';")=='0'
   sql(f"update answer_key_versions set verification_status='READY' where id='{key}';"+publish)
   assert sql("set role anon;select verification_status from mock_exam_scoring_availability where scoring_version='mixed-v2';")=='READY'
   perfect_blank=json.loads(sql(rpc(key,uid(42),[3,0,999,None])))
   assert (perfect_blank['raw_score'],perfect_blank['correct_count'],perfect_blank['unanswered_count'])==(10,4,1)
   result=json.loads(sql(rpc(key,attempt,[3,0,1,None])))
   assert (result['raw_score'],result['correct_count'],result['unanswered_count'])==(7,3,1),result
   assert result['answers'][1]['submitted_answer']==0 and result['answers'][3]['all_credit_snapshot']
   assert result['answers'][0]['accepted_answers_snapshot']==[1,3]
   assert result['answers'][1]['question_id']==uid(22)
   assert all(x['unit'] is None and x['domain'] is None and x['item_type'] is None for x in result['answers'])
   assert json.loads(sql(rpc(key,attempt,[3,0,1,None])))==result
   sql(rpc(key,attempt,[3,0,2,None]),'ATTEMPT_CONFLICT')
   assert sql(f"set role authenticated;set request.jwt.claim.sub='{b}';select count(*) from mock_exam_answers;")=='0'
   sql(rpc(key,uid(8),[3,1000,1,None]),'INVALID_ANSWERS')
   sql(rpc(key,uid(8),[0,0,1,None]),'INVALID_ENGINE_INPUT')
   sql(f"update exam_questions set points=4 where answer_key_version_id='{key}';",'KEY_IMMUTABLE')
   sql(f"update answer_key_versions set is_current=false where id='{key}';")
   assert json.loads(sql(rpc(key,attempt,[3,0,1,None])))==result
   sql(rpc(key,uid(8),[3,0,1,None]),'KEY_UNAVAILABLE')
   # Publish and submit real paper fixtures only inside this disposable database.
   # Exact Registry IDs are reused locally; no source/customer records are read remotely.
   statements=[];loaded_exams=set();loaded_subjects=set();real_keys=[]
   def quote(value):return "'"+str(value).replace("'","''")+"'"
   for paper in papers():
    cid=paper['content_item_id'];sid=paper['exam_subject_id']
    if cid not in loaded_exams:
     loaded_exams.add(cid)
     statements.append(f"insert into content_items(id,source_post_id,source_content_key,slug,content_type,title,source_url,is_active) values('{cid}','{source}','{cid}','{cid}','exam','Official isolated fixture','https://example.invalid/isolated',true);insert into exams(content_item_id) values('{cid}');")
    if sid not in loaded_subjects:
     loaded_subjects.add(sid)
     statements.append(f"insert into exam_subjects(id,content_item_id,source_subject_key,is_active) values('{sid}','{cid}','{sid}',true);")
    kid=str(uuid.uuid5(uuid.NAMESPACE_URL,'isolated-task03a:'+sid+':'+paper['paper_variant']))
    real_keys.append((kid,paper))
    ev=paper['answer_evidence']
    statements.append(f"insert into answer_key_versions(id,exam_subject_id,content_item_id,paper_variant,version,question_count,max_score,source_name,source_url,source_digest,fetched_at,scoring_version,verification_status) values('{kid}','{sid}','{cid}',{quote(paper['paper_variant'])},1,{paper['question_count']},{paper['max_score']},'KICE isolated fixture',{quote(ev['url'])},'{ev['sha256']}',now(),'mixed-v2','READY');")
    for q in paper['questions']:
     statements.append(f"insert into exam_questions(answer_key_version_id,question_number,answer_type,correct_answer,points,accepted_answers,all_credit,question_id) values('{kid}',{q['number']},{quote(q['answer_type'])},null,{q['points']},array{q['accepted_answers']}::smallint[],{str(q['all_credit']).lower()},'{q['question_id']}');")
    statements.append(f"update answer_key_versions set status='published',is_current=true,verified_at=now() where id='{kid}';")
   sql('begin;'+''.join(statements)+'commit;')
   assert int(sql("set role anon;select count(*) from mock_exam_scoring_availability where scoring_version='mixed-v2' and verification_status='READY';"))==len(real_keys)
   for kid,paper in real_keys:
    answers=vectors(paper)[0][1]
    aid=str(uuid.uuid5(uuid.NAMESPACE_URL,'isolated-attempt:'+kid))
    result=json.loads(sql(rpc(kid,aid,answers)))
    assert result['raw_score']==paper['max_score'] and result['grade'] is None
    assert len(result['answers'])==paper['question_count']
    assert [r['question_id'] for r in result['answers']]==[q['question_id'] for q in paper['questions']]
   assert sql(f"set role authenticated;set request.jwt.claim.sub='{b}';select count(*) from mock_exam_attempts;")=='0'
   print(f'PASS: {len(real_keys)} official keys published/read via anon availability and submitted via authenticated RPC in disposable DB; owner isolation preserved')
   print('PASS: candidate compiles; legacy engine unchanged; READY gate; mixed/MCA/all-credit/zero/999; immutable per-question snapshots; retry/owner/stale/invalid guards')
  finally:run([PG/'pg_ctl','-D',db,'-m','immediate','-w','stop'])
if __name__=='__main__':main()
