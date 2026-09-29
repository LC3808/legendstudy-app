"""Fresh Supabase-local Auth/JWT/PostgREST matrix; never a remote project.
Reuses the existing container/loopback/empty-public-schema guard before any DDL.
"""
import base64, contextlib, hashlib, hmac, io, json, os, sys, time, uuid
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.error import HTTPError
import psycopg
from scaffolding_runtime import ROOT,RUNTIME,MIGRATION,PARAMS,Rejected,cases
sys.path.insert(0,str(RUNTIME))
import prepare_supabase, integration


def main():
 prepare_supabase.main()  # Empty public schema + loopback/container/explicit consent, no reset.
 cfg=json.loads(Path(os.environ['ESSAY_REVIEW_SUPABASE_STATUS_FILE']).read_text())
 c=psycopg.connect(cfg['DB_URL'],autocommit=True)
 c.execute((ROOT/'supabase/migrations/20260928000400_essay_helper_execute_boundary.sql').read_text())
 buf=io.StringIO()
 with contextlib.redirect_stdout(buf):integration.main()
 before=json.loads(buf.getvalue())
 base=cfg['API_URL'].rstrip('/');anon=cfg['ANON_KEY']
 def http(path,body=None,token=None,method=None):
  req=Request(base+path,data=json.dumps(body).encode() if body is not None else None,headers={'apikey':anon,'Authorization':'Bearer '+(token or anon),'Content-Type':'application/json'},method=method or ('POST' if body is not None else 'GET'))
  try:
   with urlopen(req,timeout=20) as res:
    raw=res.read();return res.status,json.loads(raw) if raw else None
  except HTTPError as e:
   try:payload=json.loads(e.read())
   except ValueError:payload={}
   return e.code,payload
 def make_user():
  email=str(uuid.uuid4())+'@example.invalid';password=str(uuid.uuid4())+'Aa!9'
  code,_=http('/auth/v1/admin/users',{'email':email,'password':password,'email_confirm':True},cfg['SERVICE_ROLE_KEY']);assert code in (200,201)
  code,result=http('/auth/v1/token?grant_type=password',{'email':email,'password':password});assert code==200
  return result['user']['id'],result['access_token']
 A,ta=make_user();B,tb=make_user()
 for u in (A,B):c.execute('insert into public.profiles(id) values(%s) on conflict do nothing',(u,))
 enc=lambda x:base64.urlsafe_b64encode(json.dumps(x,separators=(',',':')).encode()).decode().rstrip('=')
 head=enc({'alg':'HS256','typ':'JWT'});payload=enc({'role':'essay_worker','iss':'supabase','aud':'authenticated','iat':int(time.time()),'exp':int(time.time())+1200})
 sig=base64.urlsafe_b64encode(hmac.new(cfg['JWT_SECRET'].encode(),(head+'.'+payload).encode(),hashlib.sha256).digest()).decode().rstrip('=');worker=head+'.'+payload+'.'+sig
 def rpc(name,args,*,user=None,role='authenticated'):
  token=worker if role=='essay_worker' else (tb if user==B else ta)
  code,result=http('/rest/v1/rpc/'+name,dict(zip(PARAMS[name],args)),token)
  if code not in (200,204):raise Rejected(str(code)+':'+str((result or {}).get('code','')))
  return result
 # Real v1.2 job claimed before migration. Keep lease/input immutable across upgrade.
 Q='10000000-0000-0000-0000-000000000030';C='10000000-0000-0000-0000-000000000032';E='10000000-0000-0000-0000-000000000031'
 s=rpc('essay_open_session',[str(uuid.uuid4()),Q]);text='Synthetic in-flight legacy answer'
 rev=rpc('essay_save_draft',[s,1,text]);a=rpc('essay_submit_attempt',[s,rev,str(uuid.uuid4()),hashlib.sha256(text.encode()).hexdigest()])
 account=str(uuid.uuid4());grant=str(uuid.uuid4())
 c.execute('insert into public.credit_accounts(id,user_id) values(%s,%s)',(account,A))
 c.execute("insert into public.credit_grants(id,account_id,origin) values(%s,%s,'admin_grant')",(grant,account))
 c.execute("insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,'admin_grant',3,0,%s,'synthetic')",(account,grant,str(uuid.uuid4())))
 ev=rpc('essay_request_evaluation',[a,str(uuid.uuid4()),'essay-v1.2']);lease=rpc('essay_claim',[ev],role='essay_worker')
 snapshot=c.execute('select input_snapshot from public.essay_evaluations where id=%s',(ev,)).fetchone()[0]
 c.execute(MIGRATION.read_text());c.execute("notify pgrst,'reload schema'")
 # Same public function signatures; no new API schema visibility is required for calls.
 out={'contract_version':'1.2','summary':'합성 기존 평가','strengths':[],'checklist':[],'dimensions':[{'criterion_id':C,'level':3,'explanation':'합성 기준','evidence_ids':[E]}],
      'improvements':[{'issue_key':'legacy','category':'reasoning','status':'open','title':'합성 과제','explanation':'합성 설명','action':'확인하세요.','priority':1,'evidence_ids':[E]}]}
 assert rpc('essay_finalize_success',[ev,lease['run_id'],lease['lease_token'],out],role='essay_worker')==ev
 assert c.execute('select input_snapshot from public.essay_evaluations where id=%s',(ev,)).fetchone()[0]==snapshot
 assert c.execute('select scaffolding_observation from public.essay_improvement_progress where evaluation_id=%s',(ev,)).fetchone()==(None,)
 buf=io.StringIO()
 with contextlib.redirect_stdout(buf):integration.main()
 after=json.loads(buf.getvalue())
 checks=cases(c,rpc,A,B)
 checks.append('real_v12_inflight_before_migration_completed_after_with_NULL')
 def ok(flag,name):
  if not flag:raise AssertionError(name)
  checks.append(name)
 path='/rest/v1/essay_improvement_progress?select=id,scaffolding_observation'
 code,rows=http(path,token=ta);ok(code==200 and any(r['scaffolding_observation'] is not None for r in rows),'JWT_owner_reads_new_observations')
 own_id=next(r['id'] for r in rows if r['scaffolding_observation'] is not None)
 code,rows=http(path,token=tb);ok(code==200 and rows==[],'JWT_other_user_no_observations')
 ok(http(path)[0] in (401,403),'JWT_anon_denied')
 for token,label in [(ta,'client'),(worker,'worker')]:
  ok(http('/rest/v1/essay_improvement_progress',{'scaffolding_observation':{}},token)[0] in (401,403),label+'_direct_observation_insert_denied')
  ok(http('/rest/v1/essay_improvement_progress?id=eq.'+own_id,{'scaffolding_observation':{}},token,'PATCH')[0] in (401,403),label+'_direct_observation_update_denied')
 ok(http('/rest/v1/rpc/scaffold_validate',{},ta)[0] in (401,403,404),'private_helper_not_exposed')
 c.close()
 print(json.dumps({'environment':'LOCAL_SUPABASE','real_auth_JWT':True,'postgrest':True,'runtime':'PASS','legacy_regression_before':len(before['tests']),'legacy_regression_after':len(after['tests']),'scaffolding_checks':checks,'scaffolding_check_count':len(checks),'production_apply':False,'AI_executed':False},indent=2))
if __name__=='__main__':main()
