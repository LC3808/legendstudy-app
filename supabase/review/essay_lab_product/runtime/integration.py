"""Real isolated Supabase Auth JWT + PostgREST tests. Never use linked/Production config.
Requires explicit consent and a private Supabase-local CLI status JSON outside Git.
No credentials, JWTs, DSNs, emails or answer bodies are printed.
"""
import os,json,uuid,time,hashlib,hmac,base64,subprocess
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.error import HTTPError
from urllib.parse import urlparse
import psycopg
from psycopg import sql

def main():
 if os.environ.get('ESSAY_REVIEW_DISPOSABLE')!='YES':raise SystemExit('REFUSED: explicit consent required')
 cfg=json.loads(Path(os.environ['ESSAY_REVIEW_SUPABASE_STATUS_FILE']).read_text())
 base=cfg['API_URL'].rstrip('/')
 if urlparse(base).hostname not in ('127.0.0.1','::1') or urlparse(cfg['DB_URL']).hostname not in ('127.0.0.1','::1'):raise SystemExit('REFUSED: numeric loopback required')
 project=os.environ['ESSAY_REVIEW_LOCAL_PROJECT_ID']
 if not project.startswith(('essay-review-','essay-p2b-')):raise SystemExit('REFUSED: dedicated local project required')
 container=json.loads(subprocess.check_output(['docker','inspect','supabase_db_'+project],text=True))[0]
 if container['Config']['Labels'].get('com.supabase.cli.project')!=project:raise SystemExit('REFUSED: local project mismatch')
 if not any(int(p['HostPort'])==urlparse(cfg['DB_URL']).port for p in container['NetworkSettings']['Ports'].get('5432/tcp',[])):raise SystemExit('REFUSED: local DB port mismatch')
 anon=cfg['ANON_KEY'];admin=cfg['SERVICE_ROLE_KEY'];tests=[]
 def http(path,body=None,token=None,method=None):
  req=Request(base+path,data=json.dumps(body).encode() if body is not None else None,headers={'apikey':anon,'Authorization':'Bearer '+(token or anon),'Content-Type':'application/json'},method=method or ('POST' if body is not None else 'GET'))
  try:
   with urlopen(req,timeout=20) as res:
    raw=res.read();return res.status,json.loads(raw) if raw else None
  except HTTPError as exc:
   raw=exc.read()
   try:return exc.code,json.loads(raw)
   except ValueError:return exc.code,None
 def ok(flag,name):
  if not flag:raise AssertionError(name)
  tests.append(name)
 def api(name,payload,token):return http('/rest/v1/rpc/'+name,payload,token)
 def make_user():
  email=str(uuid.uuid4())+'@example.invalid';password=str(uuid.uuid4())+'Aa!9'
  code,result=http('/auth/v1/admin/users',{'email':email,'password':password,'email_confirm':True},admin)
  ok(code in (200,201),'local_auth_user_created')
  code,result=http('/auth/v1/token?grant_type=password',{'email':email,'password':password})
  ok(code==200 and 'access_token' in result,'real_auth_password_JWT_issued')
  return result['user']['id'],result['access_token']
 A,ta=make_user();B,tb=make_user()
 c=psycopg.connect(cfg['DB_URL'],autocommit=True)
 def put(table,**values):c.execute(sql.SQL('insert into public.{} ({}) values ({})').format(sql.Identifier(table),sql.SQL(',').join(map(sql.Identifier,values)),sql.SQL(',').join(sql.Placeholder() for _ in values)),list(values.values()))
 def uid(n):return f'10000000-0000-0000-0000-{n:012d}'
 for u in [A,B]:c.execute('insert into public.profiles(id) values(%s) on conflict do nothing',(u,))
 Q=uid(30);criterion=uid(32);evidence=uid(31)
 if not c.execute('select 1 from public.essay_questions where id=%s',(Q,)).fetchone():
  put('source_posts',id=uid(10),source='synthetic',external_post_id='integration',url='https://example.edu/integration',title='Synthetic')
  put('content_items',id=uid(11),source_post_id=uid(10),source_content_key='integration',slug='integration',content_type='university_essay',title='Synthetic',source_url='https://example.edu/integration',is_active=True)
  put('resources',id=uid(12),content_item_id=uid(11),source_post_id=uid(10),source_resource_key='integration',title='Synthetic',source_url='https://example.edu/integration.pdf',is_active=True)
  put('universities',id=uid(20),slug='integration',name='Synthetic',is_active=True)
  put('essay_exams',id=uid(21),university_id=uid(20),admission_year=2024,exam_key='integration',exam_name='Synthetic',exam_kind='admission',provenance='official',verification_status='verified',verified_at='2026-01-01',official_source_url='https://example.edu/integration',evidence_note='Synthetic',is_active=True)
  put('essay_questions',id=Q,essay_exam_id=uid(21),question_key='1',label='Synthetic',display_order=1,metadata_version='v1',is_published=True)
  for i,role in enumerate(['scoring_criteria','question','passage','exam_intent'],31):
   put('essay_exam_resources',essay_exam_id=uid(21),resource_id=uid(12),role=role,provenance='official',verification_status='verified',verified_at='2026-01-01',official_source_url='https://example.edu/integration',source_locator='p1',evidence_note='Synthetic',is_active=True)
   put('essay_question_evidence',id=uid(i),question_id=Q,essay_exam_id=uid(21),resource_id=uid(12),role=role,source_locator='p1',mapping_version='v1',source_sha256='a'*64)
  put('essay_evaluation_criteria',id=criterion,question_id=Q,criterion_key='reasoning',definition_version='v1',label='논리와 구성',description='Synthetic',origin='official',source_evidence_id=evidence,display_order=1,verified_at='2026-01-01')
 s=str(uuid.uuid4());code,diagnostic=api('essay_open_session',{'p_id':s,'p_question':Q},ta)
 ok(code==200,'S7_authorized_open_RPC')
 code,rev=api('essay_save_draft',{'p_session':s,'p_revision':1,'p_body':'Synthetic REST submission'},ta);ok(code==200,'S7_authorized_draft_RPC')
 key=str(uuid.uuid4());params={'p_session':s,'p_revision':rev,'p_key':key,'p_body_hash':hashlib.sha256(b'Synthetic REST submission').hexdigest()}
 code,a=api('essay_submit_attempt',params,ta);ok(code==200,'S7_authorized_submit_RPC')
 ok(api('essay_submit_attempt',params,ta)==(200,a),'REST_submit_duplicate')
 ok(api('essay_submit_attempt',dict(params,p_body_hash='b'*64),ta)[0]==409,'S11_RPC_payload_mismatch')
 ok(api('essay_submit_attempt',params,tb)[0]==403,'S8_unauthorized_submit')
 ok(api('essay_save_draft',{'p_session':s,'p_revision':1,'p_body':'stale'},ta)[0]==409,'REST_stale_draft')
 ok(http('/rest/v1/essay_attempts?select=id',token=anon)[0] in (401,403),'S1_anon_private_denial')
 code,rows=http('/rest/v1/essay_attempts?select=id',token=ta);ok(code==200 and any(x['id']==a for x in rows),'S2_owner_read')
 code,rows=http('/rest/v1/essay_attempts?select=id',token=tb);ok(code==200 and rows==[],'S3_other_user_isolation')
 for table,name in [('essay_attempts','S4_direct_attempt_insert'),('essay_evaluations','S5_direct_evaluation_write'),('credit_transactions','S6_direct_ledger_write')]:
  ok(http('/rest/v1/'+table,{},ta)[0] in (401,403),name+'_denied')
  patch_code,patch_result=http('/rest/v1/'+table+'?id=eq.'+a,{'id':str(uuid.uuid4())},ta,'PATCH')
  ok(patch_code in (401,403),name+'_update_denied')
 ok(api('essay_finalize_success',{'p_evaluation':str(uuid.uuid4()),'p_run':str(uuid.uuid4()),'p_token':str(uuid.uuid4()),'p_output':{}},ta)[0] in (401,403),'S9_client_finalize_denied')
 # A signed JWT cannot have its identity/role edited by a client.
 parts=ta.split('.');claims=json.loads(base64.urlsafe_b64decode(parts[1]+'='*(-len(parts[1])%4)));claims['sub']=B;parts[1]=base64.urlsafe_b64encode(json.dumps(claims).encode()).decode().rstrip('=')
 ok(http('/rest/v1/essay_attempts?select=id',token='.'.join(parts))[0]==401,'S10_JWT_identity_spoof_denied')
 def server_token(role):
  enc=lambda x:base64.urlsafe_b64encode(json.dumps(x,separators=(',',':')).encode()).decode().rstrip('=')
  head=enc({'alg':'HS256','typ':'JWT'});payload=enc({'role':role,'iss':'supabase','aud':'authenticated','iat':int(time.time()),'exp':int(time.time())+600})
  sig=base64.urlsafe_b64encode(hmac.new(cfg['JWT_SECRET'].encode(),(head+'.'+payload).encode(),hashlib.sha256).digest()).decode().rstrip('=')
  return head+'.'+payload+'.'+sig
 worker=server_token('essay_worker');finance=server_token('essay_finance')
 account=str(uuid.uuid4());grant=str(uuid.uuid4());put('credit_accounts',id=account,user_id=A);put('credit_grants',id=grant,account_id=account,origin='admin_grant')
 put('credit_transactions',account_id=account,grant_id=grant,transaction_type='admin_grant',balance_delta=2,reserved_delta=0,idempotency_key=str(uuid.uuid4()),reason_code='synthetic')
 code,ev=api('essay_request_evaluation',{'p_attempt':a,'p_key':str(uuid.uuid4())},ta);ok(code==200,'REST_billing_reserve')
 code,lease=api('essay_claim',{'p_evaluation':ev},worker);ok(code==200,'REST_narrow_worker_claim')
 ok(http('/rest/v1/essay_attempts?select=id',token=worker)[0] in (401,403),'REST_worker_arbitrary_answer_read_denied')
 ok(http('/rest/v1/credit_transactions',{},worker)[0] in (401,403),'REST_worker_credit_creation_denied')
 out={'contract_version':'1.2','summary':'핵심 내용을 이해했습니다.','strengths':['논거를 제시했습니다.'],'checklist':['연결을 확인하세요.'],'dimensions':[{'criterion_id':criterion,'level':4,'explanation':'논거의 연결이 분명합니다.','evidence_ids':[evidence]}],'improvements':[]}
 fin={'p_evaluation':ev,'p_run':lease['run_id'],'p_token':lease['lease_token'],'p_output':out}
 ok(api('essay_finalize_success',fin,worker)[0]==200,'REST_worker_finalize_atomic')
 ok(api('essay_finalize_success',fin,worker)[0]==200,'REST_finalize_retry_idempotent')
 consume=c.execute("select t.id from public.credit_transactions t join public.essay_billing_decisions b on b.id=t.decision_id where b.evaluation_id=%s and t.transaction_type='consume'",(ev,)).fetchall();ok(len(consume)==1,'REST_one_consume')
 refund={'p_consume':str(consume[0][0]),'p_key':str(uuid.uuid4()),'p_amount':1}
 ok(api('essay_refund',refund,worker)[0] in (401,403),'REST_worker_refund_denied')
 ok(api('essay_refund',refund,finance)[0]==200,'REST_finance_refund')
 ok(api('essay_refund',dict(refund,p_key=str(uuid.uuid4())),finance)[0]==409,'REST_refund_bound')
 ok(api('essay_erase',{'p_session':s},tb)[0]==403,'REST_cross_user_erase_denied')
 ok(api('essay_erase',{'p_session':s},ta)[0] in (200,204),'REST_owner_erase')
 # Retain a separate A record: account-switch isolation must not pass merely because erasure emptied A.
 retained=str(uuid.uuid4())
 assert api('essay_open_session',{'p_id':retained,'p_question':Q},ta)[0]==200
 code,revision=api('essay_save_draft',{'p_session':retained,'p_revision':1,'p_body':'Synthetic retained A answer'},ta)
 assert code==200
 assert api('essay_submit_attempt',{'p_session':retained,'p_revision':revision,'p_key':str(uuid.uuid4()),'p_body_hash':hashlib.sha256(b'Synthetic retained A answer').hexdigest()},ta)[0]==200
 code,own=http('/rest/v1/essay_attempts?select=id',token=ta);assert code==200 and len(own)==1
 ok(http('/auth/v1/logout',{},ta)[0] in (200,204),'S12_auth_logout')
 ok(http('/rest/v1/essay_attempts?select=id',token=anon)[0] in (401,403),'S12_logout_client_clears_session')
 code,rows=http('/rest/v1/essay_attempts?select=id',token=tb);ok(code==200 and rows==[],'S12_account_switch_isolation')
 print(json.dumps({'supabase_integration':'PASS','environment':'LOCAL','real_auth_JWT':True,'postgrest':True,'tests':tests,'worker_JWT':'server-signed synthetic local role; never issued to client','app_lab_E2E':'NOT_VERIFIED','no_production':True,'actual_AI_calls':0},indent=2))
if __name__=='__main__':main()
