"""G1 synthetic operation tests on a guarded, prevalidated LOCAL database only.
Prerequisite: submit_timing_runtime.py on an empty disposable environment.
No production fallback, AI, real accounts, SDK or Console operations.
"""
import base64,hashlib,hmac,json,os,sys,time,uuid
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from urllib.request import Request,urlopen
from urllib.error import HTTPError
import psycopg
from psycopg.conninfo import conninfo_to_dict
import scaffolding_runtime as s
ROOT=s.ROOT;MIGRATION=ROOT/'supabase/migrations/20260929000300_essay_credit_commercial_core.sql'
uid=lambda:str(uuid.uuid4())

def cases(c,rpc,make_user,A,B):
 checks=[]
 def ok(x,n):
  if not x:raise AssertionError(n)
  checks.append(n)
 def scalar(q,args=()):return c.execute(q,args or None).fetchone()[0]
 def deny(fn,n,code=None):
  try:fn()
  except (s.Rejected,psycopg.Error) as e:
   if code and code not in str(e):raise
   checks.append(n);return
  raise AssertionError(n+' unexpectedly allowed')
 def race(f,g):
  gate=Barrier(2)
  def call(fn):
   gate.wait()
   try:return ('ok',fn())
   except s.Rejected as e:return ('denied',str(e))
  with ThreadPoolExecutor(2) as pool:
   a=pool.submit(call,f);b=pool.submit(call,g);return [a.result(),b.result()]
 Q=str(scalar("select question_id from public.essay_question_evidence group by question_id having count(distinct role)=4 order by question_id limit 1"))
 C=str(scalar('select id from public.essay_evaluation_criteria where question_id=%s order by id limit 1',(Q,)))
 E=str(scalar("select id from public.essay_question_evidence where question_id=%s and role='scoring_criteria'",(Q,)))
 def session(user=A,key=None):return rpc('essay_open_session',[key or uid(),Q],user=user)
 def submit(sess,user=A):
  rev=scalar('select revision from public.essay_drafts where session_id=%s',(sess,));body='Synthetic G1 '+uid()
  rev=rpc('essay_save_draft',[sess,rev,body,'web_desktop','practice',0],user=user)
  return rpc('essay_submit_attempt',[sess,rev,uid(),hashlib.sha256(body.encode()).hexdigest()],user=user)
 def request(a,key=None,user=A,regime='essay-v1.3'):return rpc('essay_request_evaluation',[a,key or uid(),regime],user=user)
 def claim(e):return rpc('essay_claim',[e],role='essay_worker')
 def finish(e,l=None):
  l=l or claim(e);snap=scalar('select input_snapshot from public.essay_evaluations where id=%s',(e,))
  out={'contract_version':snap['contract_version'],'summary':'Synthetic','strengths':[],'checklist':[],'dimensions':[{'criterion_id':C,'level':3,'explanation':'Synthetic','evidence_ids':[E]}],'improvements':[]}
  if snap['contract_version']=='1.3':out.update(attempt_id=snap['attempt_id'],answer_hash=snap['answer_hash'],core_improvement_keys=[],previous_improvement_reviews=[],sentence_feedback=[],local_reviews=[])
  return rpc('essay_finalize_success',[e,l['run_id'],l['lease_token'],out],role='essay_worker')
 def decision(e):return c.execute('select policy_version,reason,credits_required,status,included_by_decision_id,id from public.essay_billing_decisions where evaluation_id=%s',(e,)).fetchone()
 def grant(user,qty=10,origin='admin_grant',key=None,reason=None,role='essay_finance'):
  reasons={'admin_grant':'test_account','promotion':'operational_promotion','compensation':'customer_compensation','b2b_program':'program_allocation','purchase':'purchase','signup_bonus':'signup_bonus_v1'}
  return rpc('essay_admin_grant',[user,qty,origin,key or uid(),reason or reasons[origin],None],role=role)
 def balance(user):return scalar('select coalesce(sum(t.balance_delta-t.reserved_delta),0) from public.credit_transactions t join public.credit_accounts a on a.id=t.account_id where a.user_id=%s',(user,))
 # Real pre-migration session with claimed v1 request. No production rows used.
 c.execute('insert into public.credit_accounts(user_id) values(%s) on conflict do nothing',(A,));acc=scalar('select id from public.credit_accounts where user_id=%s',(A,));g=uid()
 c.execute("insert into public.credit_grants(id,account_id,origin) values(%s,%s,'admin_grant')",(g,acc));c.execute("insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,'admin_grant',100,0,%s,'synthetic')",(acc,g,uid()))
 legacy=session();old=request(submit(legacy));lease=claim(old)
 def facts():return [scalar("select coalesce(jsonb_agg(to_jsonb(t) order by id),'[]') from public."+t+' t') for t in ['credit_grants','credit_transactions','essay_billing_decisions','essay_evaluations','essay_attempts']]
 before=facts();c.execute(MIGRATION.read_text());c.execute("notify pgrst,'reload schema'")
 ok(facts()==before,'migration_preserves_financial_and_learning_facts')
 if getattr(rpc,'await_schema',None):rpc.await_schema()
 finish(old,lease);ok(decision(old)[0]=='v1','inflight_v1_completed')
 costs=[1]
 for i in range(3):
  e=request(submit(legacy));finish(e);costs.append(decision(e)[2])
 ok(costs==[1,0,1,1],'existing_session_v1_keeps_original_entitlement')
 deny(lambda:rpc('essay_claim_signup_credit',[]),'existing_auth_not_signup_eligible','403')
 # New users are eligible; provisioning trigger and retry endpoint share exact same key.
 U=make_user();V=make_user();ok(balance(U)==3,'signup_auto_three')
 r=rpc('essay_claim_signup_credit',[],user=U)
 ok(rpc('essay_claim_signup_credit',[],user=U)==r and balance(U)==3,'signup_retry_no_duplicate')
 rr=race(lambda:rpc('essay_claim_signup_credit',[],user=U),lambda:rpc('essay_claim_signup_credit',[],user=U))
 ok(all(x==('ok',r) for x in rr) and balance(U)==3,'signup_concurrent_once')
 ok(scalar("select count(*) from public.credit_grants g join public.credit_accounts a on a.id=g.account_id where a.user_id=%s and g.origin='signup_bonus'",(U,))==1,'signup_one_grant_DB')
 # SQL attempt to bypass per-account signup uniqueness must fail.
 deny(lambda:c.execute("insert into public.credit_grants(account_id,origin,external_reference) select id,'signup_bonus',%s from public.credit_accounts where user_id=%s",('signup_bonus/'+uid(),U)),'signup_DB_unique_enforced')
 beforebal=balance(U);k=uid();g=grant(U,key=k)
 ok(balance(U)==beforebal+10,'manual_ten')
 ok(grant(U,key=k)==g and balance(U)==beforebal+10,'manual_retry_same_payload')
 for label,fn in [('quantity',lambda:grant(U,11,key=k)),('recipient',lambda:grant(V,key=k)),('origin',lambda:grant(U,origin='promotion',key=k)),('zero',lambda:grant(U,0)),('negative',lambda:grant(U,-1)),('reason',lambda:grant(U,reason='arbitrary')),('missing_user',lambda:grant(uid())),('purchase',lambda:grant(U,origin='purchase')),('signup',lambda:grant(U,origin='signup_bonus'))]:deny(fn,'manual_reject_'+label)
 for role in ['authenticated','essay_worker','service_role']:deny(lambda:grant(U,role=role),'grant_role_denied_'+role)
 for origin in ['promotion','compensation','b2b_program']:
  gx=grant(U,2,origin);ok(scalar('select origin from public.credit_grants where id=%s',(gx,))==origin,'origin_'+origin)
 manual_key=uid();rr=race(lambda:grant(U,key=manual_key),lambda:grant(U,key=manual_key));ok(rr[0]==rr[1] and rr[0][0]=='ok','manual_concurrent_once')
 # Inject failure on ledger insertion: no orphan grant, same key can retry after rollback.
 c.execute("create function public.g1_test_fault() returns trigger language plpgsql as $$begin raise exception 'synthetic';end$$")
 c.execute("create trigger g1_test_fault before insert on public.credit_transactions for each row when(new.transaction_type='admin_grant') execute function public.g1_test_fault()")
 badkey=uid();deny(lambda:grant(U,key=badkey),'grant_atomic_failure')
 ok(scalar('select count(*) from public.credit_grants where external_reference=%s',('manual/'+badkey,))==0,'grant_ledger_rollback_no_orphan')
 c.execute('drop trigger g1_test_fault on public.credit_transactions');grant(U,key=badkey)
 # Six sequential successes, failure+retry at EVERY paid/included slot.
 sess=session();key=uid();ok(session(key=key)==session(key=key),'session_reentry_same_key')
 ok(scalar('select billing_policy_version from public.essay_practice_sessions where id=%s',(sess,))=='v2','new_session_v2')
 costs=[];parents=[];lastpaid=None
 for i in range(6):
  a=submit(sess);k=uid();e=request(a,k);d=decision(e)
  ok(request(a,k)==e and request(a)==e,'logical_dedupe_'+str(i))
  deny(lambda:request(submit(session()),k),'payload_mismatch_'+str(i),'409')
  l=claim(e);rpc('essay_finalize_failure',[e,l['run_id'],l['lease_token']],role='essay_worker')
  ok(decision(e)[3]=='released' and scalar("select count(*) from public.credit_transactions where decision_id=%s and transaction_type='consume'",(d[5],))==0,'failure_release_'+str(i))
  ok(request(a,k)==e,'failed_same_key_is_same_logical_request_'+str(i))
  e=request(a);l=claim(e);finish(e,l);ok(finish(e,l)==e,'finalize_retry_'+str(i));d=decision(e);costs.append(d[2])
  if d[2]:lastpaid=d[5]
  else:ok(d[4]==lastpaid,'included_parent_'+str(i));parents.append(d[4])
 ok(costs==[1,0,1,0,1,0] and len(set(parents))==3,'v2_six_alternating_successes')
 # v1.2 evaluation on new v2 cycle: billing independent of model/contract.
 se=session();e=request(submit(se),regime='essay-v1.2');finish(e);e2=request(submit(se),regime='essay-v1.2');finish(e2);ok(decision(e2)[:3]==('v2','included_revision',0),'v12_contract_v2_billing')
 # Included race: one authorized claim, other conflict while evaluation in progress.
 se=session();e=request(submit(se));finish(e);a=submit(se);b=submit(se)
 rr=race(lambda:request(a),lambda:request(b));ok(sum(x[0]=='ok' for x in rr)==1,'concurrent_included_one_winner')
 winner=next(x[1] for x in rr if x[0]=='ok');ok(decision(winner)[2]==0,'concurrent_included_zero_cost');finish(winner)
 # Exact last credit under account lock, separate sessions.
 grant(B,1);sb1=session(B);sb2=session(B);a=submit(sb1,B);b=submit(sb2,B)
 rr=race(lambda:request(a,user=B),lambda:request(b,user=B));ok(sum(x[0]=='ok' for x in rr)==1 and balance(B)==0,'last_credit_one_winner')
 e=next(x[1] for x in rr if x[0]=='ok');l=claim(e)
 # Timeout keeps reservation until reconcile; stale result cannot publish.
 rpc('essay_timeout',[e,l['run_id'],l['lease_token']],role='essay_worker');deny(lambda:finish(e,l),'timeout_stale_fenced')
 # Existing timeout keeps lease until expiry; advance disposable clock, never sleep/provider call.
 c.execute("grant essay_executor to current_user")
 c.execute("create or replace function essay_private.clock() returns timestamptz language sql volatile set search_path='' as $$select pg_catalog.clock_timestamp()+interval '180 seconds'$$")
 l2=claim(e);finish(e,l2);deny(lambda:finish(e,l),'late_success_fenced');ok(balance(B)==0,'retry_single_consume')
 c.execute("create or replace function essay_private.clock() returns timestamptz language sql volatile set search_path='' as $$select pg_catalog.clock_timestamp()$$")
 c.execute("revoke essay_executor from current_user")
 consume=str(scalar("select t.id from public.credit_transactions t join public.essay_billing_decisions d on d.id=t.decision_id where d.evaluation_id=%s and t.transaction_type='consume'",(e,)));refundkey=uid()
 refund=rpc('essay_refund',[consume,refundkey,1],role='essay_finance');ok(rpc('essay_refund',[consume,refundkey,1],role='essay_finance')==refund and balance(B)==1,'refund_idempotent')
 deny(lambda:rpc('essay_refund',[consume,uid(),1],role='essay_finance'),'excess_refund_denied')
 # Result/consume rollback still atomic under v2.
 se=session();e=request(submit(se));l=claim(e)
 c.execute("create trigger g1_test_fault after insert on public.credit_transactions for each row when(new.transaction_type='consume') execute function public.g1_test_fault()")
 deny(lambda:finish(e,l),'v2_finalize_rollback_fault');ok(scalar('select status from public.essay_evaluations where id=%s',(e,))=='processing' and scalar('select count(*) from public.essay_evaluation_dimensions where evaluation_id=%s',(e,))==0,'v2_no_result_without_settlement')
 c.execute('drop trigger g1_test_fault on public.credit_transactions');c.execute('drop function public.g1_test_fault()');finish(e,l)
 saved=scalar("select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t")
 deny(lambda:rpc('essay_erase',[sess],user=B),'other_user_erasure_denied')
 rpc('essay_erase',[sess]);ok(scalar('select count(*) from public.essay_attempts where session_id=%s',(sess,))==0,'learning_cycle_erasure')
 ok(scalar("select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t")==saved,'financial_ledger_survives_erasure')
 for role in ['anon','authenticated','essay_worker','service_role']:
  ok(not scalar("select has_function_privilege(%s,'public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz)','execute')",(role,)),'manual_ACL_'+role)
 ok(scalar('select count(*) from information_schema.tables where table_schema=\'public\' and table_name like \'credit_%\'')==3,'no_balance_table_added')
 return checks

def main():
 if os.environ.get('ESSAY_REVIEW_DISPOSABLE')!='YES':raise SystemExit('REFUSED consent')
 mode=sys.argv[1];tokens={};cfg=None
 if mode=='--native':
  dsn=os.environ['ESSAY_REVIEW_TEST_DSN'];cc=conninfo_to_dict(dsn)
  if cc.get('host')!='127.0.0.1' or not cc.get('dbname','').startswith('essay_review_'):raise SystemExit('REFUSED local DB')
  c=psycopg.connect(dsn,autocommit=True)
  c.execute('alter table auth.users add column if not exists created_at timestamptz not null default now()')
  def user():
   u=uid();c.execute('insert into auth.users(id) values(%s)',(u,));c.execute('insert into public.profiles(id) values(%s)',(u,));return u
  A=user();B=user();rpc=s.native_rpc(c,A)
 elif mode=='--supabase':
  import subprocess
  from urllib.parse import urlparse
  cfg=json.loads(Path(os.environ['ESSAY_REVIEW_SUPABASE_STATUS_FILE']).read_text());project=os.environ['ESSAY_REVIEW_LOCAL_PROJECT_ID']
  if not project.startswith('essay-review-') or urlparse(cfg['API_URL']).hostname!='127.0.0.1' or urlparse(cfg['DB_URL']).hostname!='127.0.0.1':raise SystemExit('REFUSED local project')
  info=json.loads(subprocess.check_output(['docker','inspect','supabase_db_'+project]))[0]
  if info['Config']['Labels'].get('com.supabase.cli.project')!=project:raise SystemExit('REFUSED container')
  if not any(str(urlparse(cfg['DB_URL']).port)==x['HostPort'] for x in info['NetworkSettings']['Ports']['5432/tcp']):raise SystemExit('REFUSED port')
  c=psycopg.connect(cfg['DB_URL'],autocommit=True)
  def http(path,body=None,token=None):
   req=Request(cfg['API_URL']+path,data=json.dumps(body).encode() if body is not None else None,headers={'apikey':cfg['ANON_KEY'],'Authorization':'Bearer '+(token or cfg['ANON_KEY']),'Content-Type':'application/json'})
   try:
    with urlopen(req,timeout=20) as r:return r.status,json.loads(r.read() or b'null')
   except HTTPError as e:return e.code,json.loads(e.read())
  def user():
   email=uid()+'@example.invalid';pw=uid()+'Ab!9';code,_=http('/auth/v1/admin/users',{'email':email,'password':pw,'email_confirm':True},cfg['SERVICE_ROLE_KEY']);assert code in (200,201)
   code,v=http('/auth/v1/token?grant_type=password',{'email':email,'password':pw});assert code==200
   u=v['user']['id'];tokens[u]=v['access_token'];c.execute('insert into public.profiles(id) values(%s) on conflict do nothing',(u,));return u
  A=user();B=user()
  def role_token(role):
   enc=lambda x:base64.urlsafe_b64encode(json.dumps(x,separators=(',',':')).encode()).decode().rstrip('=')
   body=enc({'alg':'HS256','typ':'JWT'})+'.'+enc({'sub':A,'role':role,'aud':'authenticated','iat':int(time.time()),'exp':int(time.time())+1800})
   return body+'.'+base64.urlsafe_b64encode(hmac.new(cfg['JWT_SECRET'].encode(),body.encode(),hashlib.sha256).digest()).decode().rstrip('=')
  rt={role:role_token(role) for role in ['essay_worker','essay_finance','service_role']}
  params=dict(s.PARAMS,essay_claim_signup_credit=[],essay_admin_grant=['p_user','p_quantity','p_origin','p_key','p_reason','p_expires'],essay_refund=['p_consume','p_key','p_amount'])
  def rpc(name,args,*,user=None,role='authenticated'):
   code,v=http('/rest/v1/rpc/'+name,dict(zip(params[name],args)),rt[role] if role!='authenticated' else tokens[user or A])
   if code not in (200,204):raise s.Rejected(str(code)+':'+str(v.get('code','')))
   return v
  def ready():
   for _ in range(100):
    try:rpc('essay_claim_signup_credit',[])
    except s.Rejected as e:
     if '403' in str(e):return
     if '404' not in str(e):raise
    time.sleep(.05)
   raise AssertionError('schema cache')
  rpc.await_schema=ready
 else:raise SystemExit('mode')
 if c.execute("select count(*) from information_schema.columns where table_schema='public' and table_name='essay_practice_sessions' and column_name='billing_policy_version'").fetchone()[0]:raise SystemExit('REFUSED G1 already applied')
 # Provision pre-activation users for unchanged legacy scaffolding regression.
 X=user();Y=user()
 checks=cases(c,rpc,user,A,B)
 # TEST-ONLY default emulates old pinned sessions for the unchanged v1 suite.
 # Production migration always ends with v2 default; never changes an existing session.
 c.execute("alter table public.essay_practice_sessions alter column billing_policy_version set default 'v1'")
 def legacy_rpc(name,args,**kw):
  kw.setdefault('user',X)
  return rpc(name,args,**kw)
 try:legacy_checks=s.cases(c,legacy_rpc,X,Y)
 finally:c.execute("alter table public.essay_practice_sessions alter column billing_policy_version set default 'v2'")
 if cfg:
  for role,token in [('anon',None),('owner',tokens[A]),('other',tokens[B])]:
   code,rows=http('/rest/v1/credit_grants?select=id',token=token)
   assert (code in (401,403) if role=='anon' else code==200)
   if role!='anon':
    expected={str(r[0]) for r in c.execute('select g.id from public.credit_grants g join public.credit_accounts a on a.id=g.account_id where a.user_id=%s',(A if role=='owner' else B,))}
    assert {r['id'] for r in rows}==expected
   checks.append('JWT_grant_read_'+role)
  code,rows=http('/rest/v1/credit_transactions',{'balance_delta':100},tokens[A]);assert code in (401,403);checks.append('JWT_direct_ledger_write_denied')
 c.close();print(json.dumps({'environment':mode,'checks':checks,'count':len(checks),'post_G1_legacy_scaffolding_checks':legacy_checks,'post_G1_legacy_scaffolding_count':len(legacy_checks),'runtime':'PASS','real_JWT':bool(cfg),'postgrest':bool(cfg),'production_apply':False,'AI_executed':False,'migration_sha256':hashlib.sha256(MIGRATION.read_bytes()).hexdigest()},indent=2))
if __name__=='__main__':main()
