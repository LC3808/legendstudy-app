#!/usr/bin/env python3
"""Disposable PostgreSQL test of exam billing candidate, real legacy ledger DDL.
Synthetic records only. No remote connection argument or provider transport.
"""
import argparse, ast, concurrent.futures, json, os, subprocess, tempfile, uuid
from pathlib import Path
R=Path(__file__).resolve().parents[1]
C=R/'supabase/candidates/essay_exam_unit'
def uid():return str(uuid.uuid4())
def literal(value):return "'"+str(value).replace("'","''")+"'"
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--pg-bin',type=Path,required=True);args=ap.parse_args()
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 def run(command,**kwargs):return subprocess.run(list(map(str,command)),env=env,text=True,capture_output=True,**kwargs)
 versions=next(ast.literal_eval(n.value) for n in ast.parse((R/'tool/test_math_ownership_bootstrap.py').read_text()).body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='VERSIONS' for t in n.targets))
 checks=[]
 with tempfile.TemporaryDirectory(prefix='essay-exam-credit-',dir='/private/tmp') as td:
  root=Path(td);sock=root/'socket';sock.mkdir();data=root/'db';started=False
  p=run([args.pg_bin/'initdb','-D',data,'-U','postgres','--auth=trust','--no-locale','--encoding=UTF8']);assert p.returncode==0,p.stderr
  try:
   p=run([args.pg_bin/'pg_ctl','-D',data,'-l',root/'server.log','-o',f"-k {sock} -p 5432 -c listen_addresses=''",'-w','start']);assert p.returncode==0,p.stderr;started=True
   def sql(s,error=None):
    p=run([args.pg_bin/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','postgres','-d','postgres'],input=s)
    if error:assert p.returncode!=0 and error in p.stderr,(error,p.stderr);return p.stderr
    assert p.returncode==0,p.stderr
    return p.stdout.strip()
   sql("create role anon;create role authenticated;create role service_role bypassrls;create schema auth;create table auth.users(id uuid primary key,created_at timestamptz default now());create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to anon,authenticated,service_role;alter default privileges in schema public grant all on tables to anon,authenticated,service_role;alter default privileges in schema public grant all on functions to anon,authenticated,service_role;")
   for v in versions:sql(next((R/'supabase/migrations').glob(v+'_*.sql')).read_text())
   fingerprint="select md5(string_agg(pg_get_functiondef(oid),E'\\n' order by oid)) from pg_proc where pronamespace='essay_private'::regnamespace"
   before=sql(fingerprint)
   sql(C.joinpath('install.sql').read_text());sql(C.joinpath('rollback.sql').read_text());assert sql(fingerprint)==before
   checks.append('empty_rollback_restores_legacy_functions')
   sql(C.joinpath('install.sql').read_text())
   for role in ['anon','authenticated','service_role']:
    sql(f"set role {role};select * from essay_exam_private.runs",'permission denied')
    sql(f"set role {role};select essay_exam_private.finish('{uid()}',null,true)",'permission denied')
   checks.append('all_api_roles_denied')
   user,account,grant,university,exam,otherexam,q1,q2,q3=[uid() for _ in range(9)]
   sql(f"insert into auth.users(id) values('{user}');insert into public.profiles(id) values('{user}');")
   account=sql(f"select id from public.credit_accounts where user_id='{user}'")
   sql(f"insert into public.universities(id,slug,name) values('{university}','fixture','Fixture');insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind) values('{exam}','{university}',2025,'fixture','Fixture','mock'),('{otherexam}','{university}',2025,'other','Other','mock');insert into public.essay_questions(id,essay_exam_id,question_key,label,display_order,metadata_version) values('{q1}','{exam}','q1','Q1',1,'fixture'),('{q2}','{exam}','q2','Q2',2,'fixture'),('{q3}','{otherexam}','q3','Q3',1,'fixture');")
   snapshot={'examId':exam,'kind':'MOCK_ESSAY','answers':[{'questionId':q,'body':'Synthetic student answer','revision':1,'rubricVersion':'r1','evidenceVersion':'e1'} for q in [q1,q2]]}
   def reserve(key,s=None,parent=None,acct=account):return f"select essay_exam_private.reserve('{acct}','{exam}','{key}',{literal(json.dumps(snapshot if s is None else s))}::jsonb,{literal(parent) if parent else 'null'})"
   def balance():return sql(f"select sum(balance_delta)||','||sum(reserved_delta) from public.credit_transactions where account_id='{account}'")
   key=uid()
   # Separate psql sessions contend on the same account lock, not an in-memory fake.
   with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:ids=list(pool.map(lambda _:sql(reserve(key)),range(8)))
   assert len(set(ids))==1;initial=ids[0];assert balance()=='3,1';checks.append('eight_concurrent_retries_one_reservation')
   bad=json.loads(json.dumps(snapshot));bad['answers'][0]['body']='Different';sql(reserve(key,bad),'IDEMPOTENCY_CONFLICT')
   bad['answers'][0]['questionId']=q3;sql(reserve(uid(),bad),'QUESTION_NOT_IN_EXAM');assert balance()=='3,1';checks.append('idempotency_conflict_and_cross_exam_no_posting')
   result={'summary':'Synthetic fixture summary','questions':[{'questionId':q,'rubricVersion':'r1','evidenceVersion':'e1','evaluation':{'fixture':True}} for q in [q1,q2]]}
   def finish(i,r=result,failed=False):return f"select essay_exam_private.finish('{i}',{literal(json.dumps(r)) if r is not None else 'null'}::jsonb,{str(failed).lower()})"
   incomplete=dict(result,questions=result['questions'][:1]);sql(finish(initial,incomplete),'INCOMPLETE_EXAM_RESULT');assert balance()=='3,1'
   sql(finish(initial));sql(finish(initial));assert balance()=='2,0';checks.append('partial_result_no_charge_complete_exactly_one_credit')
   sql(finish(initial,dict(result,summary='Changed')),'FINALIZATION_CONFLICT')
   sql(f"update essay_exam_private.runs set snapshot='{{}}' where id='{initial}'",'EXAM_RUN_IMMUTABLE');checks.append('completed_history_immutable')
   changed=json.loads(json.dumps(snapshot));changed['answers'][0].update(body='Rewritten',revision=2)
   revised=sql(reserve(uid(),changed,initial));assert balance()=='2,0'
   sql(reserve(uid(),changed,initial),'REEVALUATION_ALREADY_USED')
   sql(finish(revised,None,True));assert balance()=='2,0'
   revised=sql(reserve(uid(),changed,initial));sql(finish(revised));assert balance()=='2,0';checks.append('free_reevaluation_once_failed_attempt_retry')
   sql(reserve(uid(),changed,initial),'REEVALUATION_ALREADY_USED')
   independent=sql(reserve(uid()));assert balance()=='2,1'
   bad=json.loads(json.dumps(snapshot));bad['answers']=bad['answers'][:1]
   sql(finish(independent));sql(reserve(uid(),bad,independent),'FROZEN_QUESTION_SET')
   stale=json.loads(json.dumps(snapshot));stale['answers'][0]['body']='Changed without revision';sql(reserve(uid(),stale,independent),'STALE_REVISION_OR_CONTEXT')
   stale=json.loads(json.dumps(snapshot));stale['answers'][0]['rubricVersion']='r2';sql(reserve(uid(),stale,independent),'STALE_REVISION_OR_CONTEXT')
   checks.append('independent_submissions_and_frozen_set_versions')
   remaining=sql(reserve(uid()));assert balance()=='1,1';sql(reserve(uid()),'INSUFFICIENT_CREDIT')
   sql(finish(remaining,None,True));sql(finish(remaining,None,True));assert balance()=='1,0';checks.append('insufficient_credit_and_idempotent_release')
   # Different idempotency keys must not overspend the last available credit.
   def compete(_):
    try:return sql(reserve(uid()))
    except AssertionError as e:
     assert 'INSUFFICIENT_CREDIT' in str(e);return None
   with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:winners=[x for x in pool.map(compete,range(8)) if x]
   assert len(winners)==1 and balance()=='1,1'
   # A late persistence error rolls back the ledger posting and decision together.
   sql("create function essay_exam_private.inject_failure() returns trigger language plpgsql as $$begin raise exception 'INJECTED_PERSISTENCE_FAILURE';end$$;create trigger z_failure before update on essay_exam_private.runs for each row execute function essay_exam_private.inject_failure();")
   sql(finish(winners[0]),'INJECTED_PERSISTENCE_FAILURE');assert balance()=='1,1'
   sql('drop trigger z_failure on essay_exam_private.runs;drop function essay_exam_private.inject_failure()')
   sql(finish(winners[0],None,True));assert balance()=='1,0'
   checks.append('distinct_request_race_and_late_failure_transaction_rollback')
   # Fixture time shift only; no clock bypass exists in the candidate functions.
   sql(f"alter table essay_exam_private.runs disable trigger exam_run_immutable;update essay_exam_private.runs set completed_at=clock_timestamp()-interval '15 days' where id='{independent}';alter table essay_exam_private.runs enable trigger exam_run_immutable;")
   sql(reserve(uid(),snapshot,independent),'REEVALUATION_NOT_INCLUDED');assert balance()=='1,0'
   foreign_user=uid()
   sql(f"insert into auth.users(id) values('{foreign_user}');insert into public.profiles(id) values('{foreign_user}')")
   foreign_account=sql(f"select id from public.credit_accounts where user_id='{foreign_user}'")
   sql(reserve(uid(),snapshot,initial,foreign_account),'REEVALUATION_NOT_INCLUDED')
   checks.append('expired_and_cross_account_reevaluation_denied')
   # Compose the existing reviewed Worker, persistent exam journal and actual
   # candidate Ledger functions. The Provider/reviewer fixture is synthetic;
   # PostgreSQL postings and retry behavior are real disposable local DB calls.
   from dataclasses import replace
   from tool.test_essay_reviewed_runtime import RuntimeTests
   from tool.essay_lab.durable_exam import DurableExamRunner
   from tool.essay_lab.durable_journal import DurableJournal
   from tool.essay_lab.live_worker import Unknown
   def runtime_run(run_id,lost=False):
    questions=[];workers={};requests=[]
    for index,qid in enumerate([q1,q2]):
     worker,_,req,_,claim,_=RuntimeTests().fixture()
     eid=f'{run_id}-{index}';worker.permit=replace(worker.permit,evaluation_id=eid)
     workers[eid]=worker;requests.append(req)
     questions.append(dict(questionId=qid,rubricVersion='r1',evidenceVersion='e1',evaluationId=eid,claim=claim))
    def build(channel,checkpoint):
     worker=workers[channel.evaluation_id];worker.rpc=channel;worker.checkpoint=checkpoint;return worker
    def finalize(record):
     result=sql(f"select essay_exam_private.finish('{run_id}',{literal(json.dumps(record['result']))}::jsonb,{str(record['failed']).lower()})")
     if lost:raise Unknown()
     return result
    result=DurableExamRunner(DurableJournal(root/'runtime-journal')).execute(
     run_id=run_id,subject_id=user,exam_id=exam,questions=questions,
     authorize=lambda _:True,build_worker=build,summarize=lambda _: 'Synthetic reviewed exam summary',finalize=finalize)
    return result,sum(len(req) for req in requests)
   coupled=sql(reserve(uid()));assert balance()=='1,1'
   try:runtime_run(coupled,lost=True)
   except Unknown:pass
   else:raise AssertionError('Expected lost settlement response')
   assert balance()=='0,0'
   assert runtime_run(coupled)==('completed',0);assert balance()=='0,0'
   checks.append('durable_runtime_lost_settlement_replay_no_new_provider_or_charge')
   rewritten=json.loads(json.dumps(snapshot))
   for answer in rewritten['answers']:answer.update(body='Synthetic revised answer',revision=2)
   included=sql(reserve(uid(),rewritten,coupled));assert balance()=='0,0'
   assert runtime_run(included)==('completed',2);assert balance()=='0,0'
   checks.append('durable_runtime_included_reevaluation_zero_additional_credit')
   sql(C.joinpath('rollback.sql').read_text(),'NONEMPTY_EXAM_ROLLBACK_DENIED');assert balance()=='0,0'
   assert sql(fingerprint)==before;checks.append('nonempty_rollback_denied_legacy_functions_unchanged')
   print(json.dumps({'checks':checks,'count':len(checks),'productionWrites':0,'providerCalls':0,'localDatabase':'PostgreSQL 17, canonical legacy ledger migrations','deploymentReady':False},indent=2))
  finally:
   if started:run([args.pg_bin/'pg_ctl','-D',data,'-m','fast','-w','stop'])
if __name__=='__main__':main()
