"""L1 status projection: synthetic local-only suite layered on guarded G1 runtime.
Runs G1 and post-G1 Scaffolding regressions; no AI or Production connection.
"""
import contextlib,io,json,hashlib,os,sys,time
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.error import HTTPError
import g1_runtime as g
from psycopg import sql
MIGRATION=g.ROOT/'supabase/migrations/20260929000400_essay_owner_evaluation_status.sql'
status_checks=[]
g.s.PARAMS.update(essay_evaluation_status=['p_evaluation'],essay_reconcile=['p_evaluation'])

def cases(c,rpc,make_user,A,B):
 def ok(value,label):
  if not value:raise AssertionError(label)
  status_checks.append(label)
 def deny(fn,label,code=None):
  try:fn()
  except g.s.Rejected as e:
   if code:assert code in str(e),label
   status_checks.append(label);return
  raise AssertionError(label+' allowed')
 def scalar(q,args=None):return c.execute(q,args).fetchone()[0]
 def facts():return [scalar('select coalesce(jsonb_agg(to_jsonb(t)),\'[]\') from public.'+t+' t') for t in ['essay_evaluations','essay_ai_processing_runs','essay_billing_decisions','credit_transactions']]
 prior=facts();c.execute(MIGRATION.read_text());c.execute("notify pgrst,'reload schema'")
 ok(facts()==prior,'migration_no_history_mutation')
 for _ in range(100):
  try:rpc('essay_evaluation_status',[g.uid()])
  except g.s.Rejected as e:
   if 'PT404' in str(e):break
   if 'PGRST202' not in str(e):raise
   time.sleep(.05)
 else:raise AssertionError('schema cache')
 Q=str(scalar("select question_id from public.essay_question_evidence group by question_id having count(distinct role)=4 order by question_id limit 1"))
 C=str(scalar('select id from public.essay_evaluation_criteria where question_id=%s order by id limit 1',(Q,)))
 E=str(scalar("select id from public.essay_question_evidence where question_id=%s and role='scoring_criteria'",(Q,)))
 def session(user=A):return rpc('essay_open_session',[g.uid(),Q],user=user)
 def submit(se,user=A):
  body='Synthetic status '+g.uid();rev=scalar('select revision from public.essay_drafts where session_id=%s',(se,))
  rev=rpc('essay_save_draft',[se,rev,body,'web_desktop','practice',0],user=user)
  return rpc('essay_submit_attempt',[se,rev,g.uid(),hashlib.sha256(body.encode()).hexdigest()],user=user)
 def request(a,user=A):return rpc('essay_request_evaluation',[a,g.uid(),'essay-v1.3'],user=user)
 def claim(e):return rpc('essay_claim',[e],role='essay_worker')
 def finish(e,l):
  sn=scalar('select input_snapshot from public.essay_evaluations where id=%s',(e,))
  out={'contract_version':'1.3','attempt_id':sn['attempt_id'],'answer_hash':sn['answer_hash'],'summary':'Synthetic','strengths':[],'checklist':[],'dimensions':[{'criterion_id':C,'level':3,'explanation':'Synthetic','evidence_ids':[E]}],'improvements':[],'core_improvement_keys':[],'previous_improvement_reviews':[],'sentence_feedback':[],'local_reviews':[]}
  return rpc('essay_finalize_success',[e,l['run_id'],l['lease_token'],out],role='essay_worker')
 def status(e,user=A):
  result=rpc('essay_evaluation_status',[e],user=user)
  assert set(result)=={'state','credit_state','credit_mode','release_confirmed','no_credit_consumed'}
  return result
 def expect(e,state,credit,free=False,released=False,user=A):
  x=status(e,user);ok(x['state']==state and x['credit_state']==credit and x['no_credit_consumed']==free and x['release_confirmed']==released,state+'_'+credit)
 def clock(seconds):
  c.execute('grant essay_executor to current_user')
  c.execute(sql.SQL("create or replace function essay_private.clock() returns timestamptz language sql volatile set search_path='' as {} ").format(sql.Literal("select pg_catalog.clock_timestamp()+interval '%s seconds'"%seconds)))
  c.execute('revoke essay_executor from current_user')
 # Deterministic expiry using disposable-only clock replacement, no sleeps/provider.
 for version in ['v1','v2']:
  c.execute(sql.SQL('alter table public.essay_practice_sessions alter column billing_policy_version set default {}').format(sql.Literal(version)))
  se=session();c.execute("alter table public.essay_practice_sessions alter column billing_policy_version set default 'v2'")
  e=request(submit(se));expect(e,'processing','reserved')
  deny(lambda:status(e,B),'other_owner_'+version,'404')
  l=claim(e);expect(e,'processing','reserved')
  rpc('essay_timeout',[e,l['run_id'],l['lease_token']],role='essay_worker');expect(e,'reconciling','reserved')
  deny(lambda:finish(e,l),'stale_timeout_'+version,'409')
  clock(180);expect(e,'reconciling','reserved');l2=claim(e);expect(e,'processing','reserved');finish(e,l2)
  expect(e,'completed','settled');deny(lambda:finish(e,l),'late_success_'+version,'409');clock(0)
  en=request(submit(se));expect(en,'processing','included',True)
  ln=claim(en);rpc('essay_timeout',[en,ln['run_id'],ln['lease_token']],role='essay_worker');expect(en,'reconciling','included')
  clock(180);ln2=claim(en);finish(en,ln2);expect(en,'completed','settled',True);clock(0)
  ef=request(submit(se));lf=claim(ef);expect(ef,'processing','reserved')
  rpc('essay_finalize_failure',[ef,lf['run_id'],lf['lease_token']],role='essay_worker');expect(ef,'failed','released',True,True)
  er=request(submit(se));lr=claim(er);clock(180);expect(er,'reconciling','reserved')
  rpc('essay_reconcile',[er],role='essay_worker');expect(er,'failed','released',True,True)
  deny(lambda:finish(er,lr),'released_late_success_'+version,'409');clock(0)
  eq=request(submit(se));clock(901);expect(eq,'reconciling','reserved');rpc('essay_reconcile',[eq],role='essay_worker');clock(0)
  expect(eq,'failed','released',True,True)
  prior=facts();status(e);status(eq);ok(facts()==prior,'read_RPC_never_mutates_'+version)
  rpc('essay_erase',[se]);deny(lambda:status(e),'erased_'+version,'404')
 # Included failure returns verified zero-credit release, never a new charge.
 se=session();e=request(submit(se));finish(e,claim(e));e=request(submit(se));l=claim(e)
 rpc('essay_finalize_failure',[e,l['run_id'],l['lease_token']],role='essay_worker');expect(e,'failed','released',True,True)
 # B has exactly one refunded unit after G1; second paid request rejected, no evaluation row.
 se=session(B);e=request(submit(se,B),B);expect(e,'processing','reserved',user=B)
 a=submit(session(B),B);count=scalar('select count(*) from public.essay_evaluations')
 deny(lambda:request(a,B),'insufficient_is_request_PT402','402');ok(scalar('select count(*) from public.essay_evaluations')==count,'insufficient_creates_no_failure_evaluation')
 deny(lambda:status(g.uid()),'nonexistent_404','404')
 for role in ['anon','essay_worker','essay_finance','service_role']:
  ok(not scalar("select has_function_privilege(%s,'public.essay_evaluation_status(uuid)','EXECUTE')",(role,)),'ACL_denied_'+role)
 ok(not scalar("select has_table_privilege('authenticated','public.essay_ai_processing_runs','SELECT')"),'telemetry_table_still_private')
 if sys.argv[1]=='--native':deny(lambda:rpc('essay_evaluation_status',[e],role='anon'),'native_anon_denied')
 ok(set(status(e,B))=={'state','credit_state','credit_mode','release_confirmed','no_credit_consumed'},'exact_allowlist_no_raw_telemetry')
 clock(0)

if __name__=='__main__':
 original=g.cases
 def combined(c,rpc,user,A,B):
  result=original(c,rpc,user,A,B);cases(c,rpc,user,A,B);return result
 g.cases=combined
 capture=io.StringIO()
 with contextlib.redirect_stdout(capture):g.main()
 result=json.loads(capture.getvalue())
 if sys.argv[1]=='--supabase':
  cfg=json.loads(Path(os.environ['ESSAY_REVIEW_SUPABASE_STATUS_FILE']).read_text())
  req=Request(cfg['API_URL']+'/rest/v1/rpc/essay_evaluation_status',data=json.dumps({'p_evaluation':g.uid()}).encode(),headers={'apikey':cfg['ANON_KEY'],'Content-Type':'application/json'})
  try:urlopen(req,timeout=20);raise AssertionError('anon allowed')
  except HTTPError as e:assert e.code in (401,403)
  status_checks.append('actual_anon_PostgREST_denied')
 result.update(status_projection_checks=status_checks,status_projection_count=len(status_checks),status_migration_sha256=hashlib.sha256(MIGRATION.read_bytes()).hexdigest())
 print(json.dumps(result,indent=2))
