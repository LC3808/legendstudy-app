#!/usr/bin/env python3
"""MATH-2D C01-C30 and unchanged Math/Humanities fixtures. Disposable PG17 only."""
import inspect,json,hashlib,copy,concurrent.futures,time
from pathlib import Path
import psycopg
from psycopg.types.json import Jsonb
import test_math_persistence as m
R=m.R;V=R/'supabase/verification/math_essay/runtime';M=R/'supabase/migrations/20261002000200_math_runtime_surface.sql'
source=inspect.getsource(m.verify)
needle=" o.execute_as_production(c,admin,(R/'supabase/migrations/20261002000100_math_essay_persistence.sql').read_text())"
source=source.replace(needle,needle+"\n o.execute_as_production(c,admin,M.read_text())")
source=source.replace("R/'supabase/verification/math_essay/behavior_validation.json'","V/'regression.json'")
ns=dict(m.__dict__);ns.update(V=V,M=M)
def cases(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock):
 old=m.verify_math_cases(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock)
 checks=[]
 def ok(n,cond=True):assert cond,n;checks.append(n);print(n,'PASS',flush=True)
 def deny(n,fn):
  try:fn()
  except psycopg.Error as e:
   assert e.sqlstate in ('42501','22023','23505','23514','P0002','22P02','23502'),(n,e.sqlstate,str(e));ok(n);return
  raise AssertionError(n+' allowed')
 def inp(action,payload,uid=A):return rpc('math_input',[{'dto_version':'math-input-v1','action':action,'payload':payload}],uid=uid)['result']
 def worker(surface,action,payload,role=None):return rpc('math_'+surface,[{'dto_version':'math-extraction-v1' if surface=='extraction' else 'math-worker-v1','action':action,'payload':payload}],role=role or 'math_'+('extraction' if surface=='extraction' else 'evaluation')+'_worker')['result']
 payload=dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL',input_kind='EVIDENCE')
 a=inp('create_attempt',payload)['attempt_id'];ok('C01',a)
 deny('C02',lambda:inp('read_input',{'attempt_id':a},B))
 meta=dict(position=1,media_type='image/png',byte_size=100,width=20,height=20,orientation=0)
 ar=inp('register_evidence',{'attempt_id':a,'metadata':meta})['artifact_id'];ok('C03',ar==inp('register_evidence',{'attempt_id':a,'metadata':meta})['artifact_id'])
 # Synthetic Storage-boundary fixture only; no upload/deletion API invoked.
 c.execute("update public.math_attempt_artifacts set storage_state='PRESENT' where id=%s",(ar,))
 x=worker('extraction','claim',{'attempt_id':a});ok('C04',x['run_id'] and x['evidence'][0]['artifact_id']==ar)
 deny('C05',lambda:inp('create_attempt',dict(payload,client_submission_id=new(),confidence=1,provider='forged')))
 raw=dict(regions=[dict(artifact_id=ar,page=1,reading_order=1,raw_text='2',normalized_math='2',confidence=.8,uncertain=True,x=0,y=0,width=.5,height=.5)],provider='synthetic',model='mock',model_version='1')
 args=dict(run_id=x['run_id'],lease_token=x['lease_token'],output=raw)
 tx=scalar('select count(*) from public.credit_transactions')
 run=worker('extraction','finalize',args)['run_id'];ok('C06',run==x['run_id']);ok('C07',worker('extraction','finalize',args)['run_id']==run)
 state=inp('read_input',{'attempt_id':a});region=state['candidate_regions'][0]['id']
 deny('C11',lambda:inp('confirm_extraction',dict(attempt_id=a,run_id=run,regions=[])))
 assert state['input_state']=='CONFIRMATION_REQUIRED'
 correction=dict(attempt_id=a,run_id=run,regions=[dict(region_id=region,raw_text='2',normalized_math='2')])
 confirmed=inp('confirm_extraction',correction)['confirmed_run_id'];ok('C08',confirmed)
 ok('C12',inp('read_input',{'attempt_id':a})['input_state']=='READY_FOR_EVALUATION')
 deny('C10',lambda:inp('confirm_extraction',correction,B))
 ok('C18',inp('confirm_extraction',correction)['confirmed_run_id']==confirmed and inp('create_attempt',payload)['attempt_id']==a)
 def concurrent_confirm(_):
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as cc:
   with cc.transaction():
    cc.execute("set local role authenticated;set local statement_timeout='5s'");cc.execute("select set_config('request.jwt.claim.sub',%s,true)",(A,))
    return cc.execute('select public.math_input(%s)',(Jsonb(dict(dto_version='math-input-v1',action='confirm_extraction',payload=correction)),)).fetchone()[0]['result']['confirmed_run_id']
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:ids=list(pool.map(concurrent_confirm,range(8)))
 ok('C19',set(ids)=={confirmed} and scalar("select count(*) from public.math_extraction_runs where predecessor_id=%s and kind='CONFIRMED'",(run,))==1)
 x2=worker('extraction','claim',{'attempt_id':a})
 deny('C09',lambda:inp('confirm_extraction',correction))
 assert inp('read_input',{'attempt_id':a})['input_state']=='EXTRACTION_PROCESSING'
 deny('new_candidate_blocks_request',lambda:inp('request_evaluation',dict(attempt_id=a,client_submission_id=new())))
 deny('stale_finalize',lambda:worker('extraction','finalize',dict(args,lease_token=new())))
 worker('extraction','fail',dict(run_id=x2['run_id'],lease_token=x2['lease_token'],error_code='TIMEOUT'))
 # Confirmation versus a newly claimed candidate: one serialized winner, never old READY.
 x3=worker('extraction','claim',{'attempt_id':a});worker('extraction','finalize',dict(run_id=x3['run_id'],lease_token=x3['lease_token'],output=raw))
 region3=inp('read_input',{'attempt_id':a})['candidate_regions'][0]['id']
 correction=dict(attempt_id=a,run_id=x3['run_id'],regions=[dict(region_id=region3,raw_text='2',normalized_math='2')])
 def version_race(which):
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as cc:
   try:
    with cc.transaction():
     cc.execute("set local statement_timeout='5s'")
     if which:
      cc.execute('set local role math_extraction_worker');return cc.execute('select public.math_claim_extraction(%s)',(a,)).fetchone()[0]
     cc.execute('set local role authenticated');cc.execute("select set_config('request.jwt.claim.sub',%s,true)",(A,))
     return cc.execute('select public.math_confirm_extraction(%s,%s,%s)',(a,x3['run_id'],Jsonb(correction['regions']))).fetchone()[0]
   except psycopg.Error as ex:assert ex.sqlstate=='22023';return 'STALE'
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:race=list(pool.map(version_race,[False,True]))
 ok('confirmation_vs_new_version',inp('read_input',{'attempt_id':a})['input_state']=='EXTRACTION_PROCESSING' and scalar("select count(*) from public.math_extraction_runs where predecessor_id=%s and kind='CONFIRMED'",(x3['run_id'],))<=1)
 typed=inp('create_attempt',dict(payload,client_submission_id=new(),input_kind='TYPED',typed_answer='2'))['attempt_id']
 typed_state=inp('read_input',{'attempt_id':typed});ok('C13',typed_state['input_state']=='READY_FOR_EVALUATION' and typed_state['candidate'] is None)
 ok('C29',tx==scalar('select count(*) from public.credit_transactions'))
 deny('C15',lambda:worker('evaluation','claim',{'evaluation_id':ev},role='math_extraction_worker'))
 deny('C16',lambda:worker('extraction','claim',{'attempt_id':a},role='math_evaluation_worker'))
 deny('C17',lambda:worker('evaluation','finalize',dict(evaluation_id=ev,lease_token=cl['lease_token'],output=out),role='authenticated'))
 def quality(action,payload,user=OP):return rpc('qlm_quality',[dict(dto_version='qlm-runtime-v1',action=action,payload=payload)],uid=user)['result']
 deny('C21',lambda:quality('detail',{'evaluation_id':ev},A))
 ok('C22',quality('detail',{'evaluation_id':ev})['dto_version']=='qlm-read-v1')
 assert quality('list',{'limit':1})['cases']
 assert quality('review_state',{'evaluation_ids':[ev]})['cases']
 assert quality('history',{'evaluation_id':ev})['judgments']
 good=copy.deepcopy(p);good['client_submission_id']=new();assert quality('submit_judgment',{'judgment':good})['judgment_id']
 ok('C23','R08_all_graph_targets_positive' in old and 'R08_propagated_not_root' in old)
 bad=copy.deepcopy(p);bad['client_submission_id']=new();bad['expected_output_sha256']='0'*64
 deny('C24',lambda:rpc('qlm_submit_human_judgment',[bad],uid=OP))
 ok('C25','R10_math_E1' in old);ok('C26','R10_combined_E1_E2' in old)
 rpc('essay_admin_grant',[A,5,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 e=inp('request_evaluation',dict(attempt_id=typed,client_submission_id=new()))['evaluation_id'];ok('C27',scalar('select count(*) from public.math_billing_bindings where math_evaluation_id=%s',(e,))==1)
 claim=worker('evaluation','claim',{'evaluation_id':e});worker('evaluation','finalize',dict(evaluation_id=e,lease_token=claim['lease_token'],output=out))
 assert inp('read_result',{'evaluation_id':e})['output']['core']==[]
 assert inp('history',{'limit':2})['attempts']
 ok('C28','R16_included' in old and 'R16_exact_336h_expired' in old)
 memberships=scalar("select count(*) from pg_auth_members where roleid='math_executor'::regrole and member<>'postgres'::regrole")
 ok('C30',memberships==0 and not scalar("select has_function_privilege('authenticated','public.math_extraction(jsonb)','EXECUTE')") and not scalar("select has_function_privilege('service_role','public.math_input(jsonb)','EXECUTE')"))
 rpc('account_deletion_request',uid=A)
 deny('C14',lambda:inp('read_input',{'attempt_id':typed}))
 sid=new();rpc('account_reauth_attest',[A,sid],role='account_lifecycle_worker');rpc('account_deletion_cancel',uid=A,extra={'session_id':sid})
 # Actual two-session lifecycle lock race; committed pending wins before blocked input read.
 with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as cc:
  with cc.transaction():
   cc.execute('set local role authenticated');cc.execute("select set_config('request.jwt.claim.sub',%s,true)",(A,));cc.execute('select public.account_deletion_request()')
   def blocked():
    with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as dd:
     try:
      with dd.transaction():
       dd.execute("set local role authenticated;set local statement_timeout='5s'");dd.execute("select set_config('request.jwt.claim.sub',%s,true)",(A,));dd.execute('select public.math_input(%s)',(Jsonb(dict(dto_version='math-input-v1',action='read_input',payload={'attempt_id':typed})),))
     except psycopg.Error as ex:return ex.sqlstate
     return 'ALLOW'
   pool=concurrent.futures.ThreadPoolExecutor(max_workers=1);future=pool.submit(blocked);time.sleep(.1);assert not future.done()
  ok('C20',future.result()=='42501');pool.shutdown()
 sid=new();rpc('account_reauth_attest',[A,sid],role='account_lifecycle_worker');rpc('account_deletion_cancel',uid=A,extra={'session_id':sid})
 for role in ['anon','service_role']:
  deny('denied_'+role,lambda role=role:rpc('math_input',[dict(dto_version='math-input-v1',action='history',payload={})],role=role))
 deny('unknown_version',lambda:rpc('math_input',[dict(dto_version='wrong',action='history',payload={})]))
 deny('changed_confirmation',lambda:inp('confirm_extraction',dict(correction,regions=[dict(region_id=region,raw_text='3',normalized_math='3')])) )
 assert all('C'+str(i).zfill(2) in checks for i in range(1,31))
 (V/'validation.json').write_text(json.dumps(dict(migration_sha256=hashlib.sha256(M.read_bytes()).hexdigest(),checks=checks,C01_C30={f'C{i:02}':'PASS' for i in range(1,31)},math_2c_regression=len(old),production_writes=0,provider_calls=0,storage_runtime='NOT_ASSESSABLE'),indent=2)+'\n')
 return old
ns['verify_math_cases']=cases;exec(source,ns)
m.h.verify_hqp=ns['verify'];m.h.main(bootstrap_user='supabase_admin')
