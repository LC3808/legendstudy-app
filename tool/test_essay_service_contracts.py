#!/usr/bin/env python3
"""Actual canonical Math + journal DDL in disposable PG17. No network/Provider."""
import inspect,json,uuid,psycopg,re
from pathlib import Path
import test_math_installation as harness
R=Path(__file__).resolve().parents[1]
def uid():return str(uuid.uuid4())
def verify(c):
 with psycopg.connect(host=c.info.host,user="supabase_admin",dbname="postgres",autocommit=True) as admin:
  admin.execute("grant anon,authenticated to postgres with inherit false,set true")
 c.execute(harness.candidate)
 c.execute((R/'supabase/candidates/essay_exam_unit/install.sql').read_text())
 c.execute((R/'supabase/candidates/essay_exam_unit/provider-policy.sql').read_text())
 c.execute((R/'supabase/candidates/essay_exam_unit/api.sql').read_text())
 c.execute((R/'supabase/migrations/20261015121723_essay_continuous_cycles.sql').read_text())
 c.execute('create schema account_private;create table public.account_deletion_requests(subject_id uuid,state text)')
 lifecycle=(R/'supabase/migrations/20261001000300_account_deletion_lifecycle.sql').read_text()
 for name in ['account_private.lock_subject','account_private.allowed']:
  c.execute(re.search(r'create (?:or replace )?function '+re.escape(name)+r'\(.*?\$\$;',lifecycle,re.S|re.I).group(0))
 before=c.execute("select schemaname,tablename,policyname,roles,qual,with_check from pg_policies order by 1,2,3").fetchall()
 for file in sorted((R/'supabase/migrations').glob('202610210717*.sql')):c.execute(file.read_text())
 assert before==c.execute("select schemaname,tablename,policyname,roles,qual,with_check from pg_policies order by 1,2,3").fetchall()
 c.execute((R/'supabase/verification/essay_service_contracts/rollback.sql').read_text())
 assert c.execute("select to_regprocedure('public.essay_browse_catalog(text)')").fetchone()[0] is None
 for file in sorted((R/'supabase/migrations').glob('202610210717*.sql')):c.execute(file.read_text())
 checks=['existing_rls_unchanged','unused_contract_rollback_reinstall']
 def reject(sql,params,contains):
  try:c.execute(sql,params);raise AssertionError('unexpected success: '+contains)
  except Exception as e:
   assert contains in str(e),(contains,str(e))
 def call(subject,exam,key,answers):
  return c.execute('select essay_exam_private.confirmed_answers(%s,%s,%s,%s::jsonb)',(subject,exam,key,json.dumps(answers))).fetchone()[0]
 u,e,q,student,other,s,p,l,a,cr,cf=[uid() for _ in range(11)]
 # Exact public Catalog identity, unpublished fixtures, synthetic content only.
 u='a9e38cdc-9593-4c60-b8a6-698133f48518'
 c.execute("insert into public.universities(id,slug,name,is_active) values(%s,'gachon','가천대학교',false)",(u,))
 c.execute("insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind) values(%s,%s,2027,'synthetic','모의','mock')",(e,u))
 c.execute("insert into public.essay_questions(id,essay_exam_id,question_key,label,display_order,metadata_version) values(%s,%s,'synthetic','문항1',1,'test')",(q,e))
 # Role access via security definer and denial on underlying unpublished rows.
 for role in ['anon','authenticated']:
  c.execute('set role '+role)
  rows=c.execute("select public.essay_browse_catalog('gachon')").fetchone()[0]
  assert len(rows)==1 and rows[0]['questions']==[{'id':q,'label':'문항1'}] and rows[0]['evaluationReady'] is False
  assert set(rows[0])=={'examId','universityId','year','kind','track','title','questionCount','questions','evaluationReady'}
  assert c.execute('select count(*) from public.essay_questions where id=%s',(q,)).fetchone()[0]==0
  assert c.execute("select public.essay_browse_catalog('unknown')").fetchone()[0]==[]
  reject('select essay_exam_private.confirmed_answers(%s,%s,%s,%s::jsonb)',(student,e,uid(),'[]'),'permission denied')
  c.execute('reset role')
 checks+=['anon_authenticated_metadata_only','private_rows_and_resolver_denied','unknown_catalog_empty']
 for person in [student,other]:
  c.execute('insert into auth.users(id) values(%s)',(person,));c.execute('insert into public.profiles(id) values(%s)',(person,))
 c.execute("insert into public.math_problem_sets(id,essay_exam_id,logical_id,version,label,state) values(%s,%s,%s,1,'fixture','DRAFT')",(s,e,uid()))
 c.execute("insert into public.math_problems(id,problem_set_id,logical_id,version,display_order,statement,state) values(%s,%s,%s,1,1,'fixture','DRAFT')",(p,s,uid()))
 c.execute("insert into public.math_subproblems(id,problem_id,leaf_key,display_order,statement,response_format,essay_question_id) values(%s,%s,'fixture',1,'fixture','FULL_SOLUTION',%s)",(l,p,q))
 c.execute("insert into public.math_attempts(id,student_id,leaf_id,kind,lineage_id,input_kind,client_submission_id,submission_sha256) values(%s,%s,%s,'INITIAL',%s,'EVIDENCE',%s,%s)",(a,student,l,a,uid(),'a'*64))
 artifacts=[]
 for pos in range(1,7):
  ar=uid();artifacts.append(ar)
  c.execute("insert into public.math_attempt_artifacts(id,attempt_id,position,namespace,bucket,object_key,media_type,content_sha256,byte_size,storage_state) values(%s,%s,%s,'raw','math-private',%s,'image/png',%s,100,'PRESENT')",(ar,a,pos,f'{student}/{a}/raw/{ar}','b'*64))
 c.execute("insert into public.math_extraction_runs(id,attempt_id,kind,state) values(%s,%s,'CANDIDATE','COMPLETED')",(cr,a))
 c.execute("insert into public.math_extraction_runs(id,attempt_id,kind,state,predecessor_id,confirmed_at) values(%s,%s,'CONFIRMED','COMPLETED',%s,now())",(cf,a,cr))
 for pos,ar in enumerate(artifacts,1):
  c.execute("insert into public.math_extraction_regions(id,run_id,attempt_id,artifact_id,page,reading_order,raw_text,normalized_math,uncertain,x,y,width,height) values(%s,%s,%s,%s,1,%s,%s,'',false,0,0,1,1)",(uid(),cf,a,ar,pos,'confirmed '+str(pos)))
 answer={'questionId':q,'revision':1,'mathInput':{'attemptId':a,'confirmedRunId':cf}}
 out=call(student,e,uid(),[answer])[0]
 assert out['body']=='\n'.join('confirmed '+str(i) for i in range(1,7))
 assert [x['id'] for x in out['input']['artifacts']]==artifacts
 assert 'object_key' not in json.dumps(out)
 checks+=['six_images_ordered_confirmed_text','no_storage_path_in_snapshot']
 c.execute('begin')
 seventh=uid()
 c.execute("insert into public.math_attempt_artifacts(id,attempt_id,position,namespace,bucket,object_key,media_type,content_sha256,byte_size,storage_state) values(%s,%s,7,'raw','math-private',%s,'image/png',%s,100,'PRESENT')",(seventh,a,f'{student}/{a}/raw/{seventh}','b'*64))
 reject('select essay_exam_private.confirmed_answers(%s,%s,%s,%s::jsonb)',(student,e,uid(),json.dumps([answer])),'MATH_IMAGES_NOT_READY')
 c.execute('rollback')
 checks.append('seventh_image_denied')
 reject('select essay_exam_private.confirmed_answers(%s,%s,%s,%s::jsonb)',(other,e,uid(),json.dumps([answer])),'MATH_INPUT_NOT_OWNED_OR_MAPPED')
 reject('select essay_exam_private.confirmed_answers(%s,%s,%s,%s::jsonb)',(student,e,uid(),json.dumps([{**answer,'body':'injected'}])),'INVALID_MATH_INPUT')
 reject('update public.math_subproblems set essay_question_id=null where id=%s',(l,),'MATH_USED_IDENTITY_IMMUTABLE')
 c.execute("update public.math_attempt_artifacts set storage_state='REGISTERED' where id=%s",(artifacts[-1],))
 reject('select essay_exam_private.confirmed_answers(%s,%s,%s,%s::jsonb)',(student,e,uid(),json.dumps([answer])),'MATH_IMAGES_NOT_READY')
 checks+=['foreign_owner_denied','client_text_override_denied','used_mapping_immutable','partial_upload_denied']
 c.execute("update public.math_attempt_artifacts set storage_state='PRESENT' where id=%s",(artifacts[-1],))
 # Real submit/reserve/finish/history; package/model approval is a labelled synthetic fixture.
 def fixture(name,args,value):
  literal="'"+json.dumps(value).replace("'","''")+"'::jsonb"
  c.execute(f'create or replace function {name}({args}) returns jsonb language sql as $$select {literal}$$')
 binding={'policy_version':'fixture','provider':'openai','model':'fixture','model_version':'fixture','prompt_version':'fixture','contract_version':'1.3'}
 fixture('essay_private.provider_policy','p_regime text',binding)
 regime=c.execute("select 'essay-v1.3/policy/'||encode(sha256(convert_to(%s::jsonb::text,'UTF8')),'hex')",(json.dumps(binding),)).fetchone()[0]
 fixture('public.essay_material_runtime_package','p_exam uuid,p_digest text',{'university_id':u,'package_version':1,'package_digest':'f'*64,'exam_identity':{'track':'humanities'},'questions':[{'question_id':q}]})
 key=uid()
 submit='select public.essay_exam_submit(%s,%s,%s,%s::jsonb,null)'
 reject(submit,(student,e,key,json.dumps([answer])),'EXAM_NOT_ACTIVATED')
 fixture('essay_exam_private.runtime_policy','p_exam uuid',{'evaluation_type':'humanities','regime':regime,'package_digest':'f'*64})
 run=str(c.execute(submit,(student,e,key,json.dumps([answer]))).fetchone()[0])
 assert str(c.execute(submit,(student,e,key,json.dumps([answer]))).fetchone()[0])==run
 account=c.execute('select id from public.credit_accounts where user_id=%s',(student,)).fetchone()[0]
 assert c.execute('select sum(reserved_delta) from public.credit_transactions where account_id=%s',(account,)).fetchone()[0]==1
 # New extraction after submission cannot change the original replay snapshot.
 c.execute("insert into public.math_extraction_runs(id,attempt_id,kind,state) values(%s,%s,'CANDIDATE','PROCESSING')",(uid(),a))
 assert str(c.execute(submit,(student,e,key,json.dumps([answer]))).fetchone()[0])==run
 reject(submit,(student,e,uid(),json.dumps([answer])),'MATH_CONFIRMATION_REQUIRED')
 version='material-1-'+'f'*64
 result={'summary':'Synthetic','questions':[{'questionId':q,'rubricVersion':version,'evidenceVersion':version,'evaluation':{'fixture':True}}]}
 c.execute('select essay_exam_private.finish(%s,%s::jsonb,false)',(run,json.dumps(result)))
 c.execute('select essay_exam_private.finish(%s,%s::jsonb,false)',(run,json.dumps(result)))
 assert c.execute('select sum(balance_delta),sum(reserved_delta) from public.credit_transactions where account_id=%s',(account,)).fetchone()==(2,0)
 c.execute("select set_config('request.jwt.claim.sub',%s,false)",(student,))
 c.execute('set role authenticated')
 history=c.execute('select public.essay_exam_history(%s)',(run,)).fetchone()[0]
 assert history['runs'][0]['answers'][0]['input']['reference']==answer['mathInput']
 c.execute('reset role')
 checks+=['activation_hold_preserved','same_key_one_reservation','replay_after_extraction_retry','stale_confirmation_denied','finish_once_local_credit','history_keeps_confirmed_input']

 reject((R/'supabase/verification/essay_service_contracts/rollback.sql').read_text(),None,'USED_CONTRACT_ROLLBACK_REQUIRES_REVIEW')
 c.execute('rollback')
 checks.append('used_contract_rollback_denied')
 return {'checks':checks,'count':len(checks),'production_writes':0,'provider_calls':0,'scope':'Local real PostgreSQL, synthetic fixtures; real journal, synthetic package/model; no live Provider E2E'}
# Reuse reviewed Unix-socket-only bootstrap, not its unrelated installation tests/output.
source=inspect.getsource(harness.main).replace("V/'installation_validation.json'","R/'supabase/verification/essay_service_contracts.json'")
namespace=dict(harness.__dict__,verify=verify)
exec(source,namespace)
if __name__=='__main__':namespace['main']()
