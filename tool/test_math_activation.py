#!/usr/bin/env python3
"""Disposable PG17 activation checks; no network, provider or Production DSN."""
from pathlib import Path
import sys,json,hashlib,subprocess,tempfile,os
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'tool'))
ns={'__file__':str(R/'tool/test_math_learning.py'),'__name__':'activation_fixture'}
s=(R/'tool/test_math_learning.py').read_text().split("source=ns['source'].replace")[0]
exec(compile(s,str(R/'tool/test_math_learning.py'),'exec'),ns)
base=ns['cases'];m=ns['m'];M=R/'supabase/migrations/20261004000200_math_storage_erasure_activation.sql'
V=R/'supabase/verification/math_essay/activation';V.mkdir(exist_ok=True)
def cases(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock):
 old=base(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock)
 c.execute('create schema if not exists storage;create table if not exists storage.objects(id uuid default gen_random_uuid(),bucket_id text,name text)')
 c.execute('create table if not exists storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[])')
 # Storage fixture is metadata only. Byte API is independently exercised in Deno.
 c.execute('alter table storage.objects add column if not exists name text')
 c.execute('alter table storage.objects enable row level security')
 c.execute('grant usage on schema storage to authenticated;grant select,insert,update,delete on storage.objects to authenticated')
 admin=m.psycopg.connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True)
 memberships=c.execute('select * from pg_auth_members order by roleid,member,grantor').fetchall()
 before=m.o.snapshot(c)
 try:
  m.o.execute_as_production(c,admin,M.read_text().replace('commit;', "do $$begin raise exception 'ACTIVATION_INJECTED';end$$;commit;"))
  raise AssertionError('injection did not fail')
 except m.psycopg.errors.RaiseException as ex: assert 'ACTIVATION_INJECTED' in str(ex)
 assert m.o.snapshot(c)==before
 assert scalar("select count(*) from storage.buckets where id='math-private'")==0
 print('activation_transaction_rollback PASS',flush=True)
 m.o.execute_as_production(c,admin,M.read_text())
 assert c.execute('select * from pg_auth_members order by roleid,member,grantor').fetchall()==memberships
 print('activation_non_superuser_memberships PASS',flush=True)
 admin.close()
 checks=[]
 def ok(name,yes=True):assert yes,name;checks.append(name);print(name,'PASS',flush=True)
 def deny(name,fn):
  try:fn()
  except Exception:ok(name);return
  raise AssertionError(name+' allowed')
 expected={'math_storage_owner':{'postgres','authenticated'},'math_storage_worker_read':{'postgres','math_extraction_worker'},'math_artifact_storage':{'postgres','math_extraction_worker'},'math_account_erasure':{'postgres','account_lifecycle_worker'},'math_recover_evaluation':{'postgres','math_evaluation_worker'},'math_catalog':{'postgres','authenticated'}}
 inventory=[]
 for name,executors in expected.items():
  owner,definer,config,acl=c.execute("select pg_get_userbyid(proowner),prosecdef,proconfig,array(select pg_get_userbyid(grantee) from aclexplode(proacl) where privilege_type='EXECUTE' order by grantee) from pg_proc where pronamespace='public'::regnamespace and proname=%s",(name,)).fetchone()
  ok('acl_'+name,owner=='postgres' and definer and set(acl)==executors and config==['search_path=""'])
  inventory.append(dict(name=name,owner=owner,executors=sorted(acl),search_path=''))
 (V/'ownership.json').write_text(json.dumps(inventory,indent=2)+'\n')
 ok('bucket_private',scalar("select public=false from storage.buckets where id='math-private'"))
 ok('admission_denies_browser',not scalar("select has_function_privilege('authenticated','public.math_artifact_storage(uuid,uuid,text,bigint,text)','EXECUTE')"))
 ok('cleanup_denies_browser',not scalar("select has_function_privilege('authenticated','public.math_account_erasure(uuid,uuid,text)','EXECUTE')"))
 user=new();c.execute('insert into auth.users(id) values(%s)',(user,));c.execute('insert into public.profiles(id) values(%s)',(user,))
 attempt=str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL',input_kind='EVIDENCE')],uid=user))
 artifact=rpc('math_register_artifact',[attempt,dict(position=1,media_type='image/png',byte_size=3)],uid=user)['artifact_id']
 desc=rpc('math_artifact_storage',[user,artifact,'describe',None,None],role='math_extraction_worker');path=desc['object_key']
 ok('owner_upload',rpc('math_storage_owner',['math-private',path,True],uid=user))
 ok('foreign_denied',rpc('math_storage_owner',['math-private',path,True],uid=B)==False)
 deny('foreign_admission',lambda:rpc('math_artifact_storage',[B,artifact,'describe',None,None],role='math_extraction_worker'))
 deny('no_object_receipt',lambda:rpc('math_artifact_storage',[user,artifact,'admit',3,'a'*64],role='math_extraction_worker'))
 c.execute("insert into storage.objects(bucket_id,name) values('math-private',%s)",(path,))
 rpc('math_artifact_storage',[user,artifact,'admit',3,'a'*64],role='math_extraction_worker')
 ok('present',scalar('select storage_state from public.math_attempt_artifacts where id=%s',(artifact,))=='PRESENT')
 ok('immutable_upload',rpc('math_storage_owner',['math-private',path,True],uid=user)==False)
 request=rpc('account_deletion_request',uid=user)
 deny('pending_upload',lambda:rpc('math_storage_owner',['math-private',path,True],uid=user))
 rid=str(scalar('select id from public.account_deletion_requests where subject_id=%s',(user,)));token=new()
 c.execute("update public.account_deletion_requests set state='ERASING',phase='STORAGE',lease_token=%s,lease_until=clock_timestamp()+interval '5 minutes' where id=%s",(token,rid))
 rpc('math_account_erasure',[rid,token,'prepare'],role='account_lifecycle_worker')
 deny('bytes_before_rows',lambda:rpc('math_account_erasure',[rid,token,'complete'],role='account_lifecycle_worker'))
 ok('metadata_retained_on_failure',scalar('select count(*) from public.math_attempt_artifacts where id=%s',(artifact,))==1)
 c.execute("delete from storage.objects where bucket_id='math-private' and name=%s",(path,)) # fixture simulates successful Storage API only
 ok('cleanup_after_absence',rpc('math_account_erasure',[rid,token,'complete'],role='account_lifecycle_worker'))
 ok('attempt_erased',scalar('select count(*) from public.math_attempts where id=%s',(attempt,))==0)
 ok('cleanup_retry',rpc('math_account_erasure',[rid,token,'complete'],role='account_lifecycle_worker'))
 deny('stale_cleanup',lambda:rpc('math_account_erasure',[rid,new(),'complete'],role='account_lifecycle_worker'))
 # Exercise populated evaluation/learning/quality CASCADE and existing billing release.
 arid=str(scalar("select id from public.account_deletion_requests where subject_id=%s and state='ERASING'",(A,)));atok=new()
 c.execute("update public.account_deletion_requests set phase='STORAGE',lease_token=%s,lease_until=clock_timestamp()+interval '5 minutes' where id=%s",(atok,arid))
 rpc('math_account_erasure',[arid,atok,'prepare'],role='account_lifecycle_worker')
 ok('full_math_erasure',rpc('math_account_erasure',[arid,atok,'complete'],role='account_lifecycle_worker'))
 ok('full_attempt_absence',scalar('select count(*) from public.math_attempts where student_id=%s',(A,))==0)
 ok('kill_switch_default_off',scalar('select evaluations_enabled from math_private.runtime_control')==False)
 # Real PG wire -> LAB physical adapter -> canonical PG finalize, no mock RPC server.
 user2=new();c.execute('insert into auth.users(id) values(%s)',(user2,));c.execute('insert into public.profiles(id) values(%s)',(user2,))
 rpc('essay_admin_grant',[user2,3,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 typed=str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL',input_kind='TYPED',typed_answer='2')],uid=user2))
 count=scalar('select count(*) from public.credit_transactions')
 deny('kill_switch_blocks_before_credit',lambda:rpc('math_request_evaluation',[typed,new()],uid=user2))
 ok('kill_switch_no_charge',count==scalar('select count(*) from public.credit_transactions'))
 c.execute('update math_private.runtime_control set evaluations_enabled=true')
 initial=str(rpc('math_request_evaluation',[typed,new()],uid=user2))
 def finalize_physical(evaluation,previous=None):
  claim=rpc('math_evaluation',[dict(dto_version='math-worker-v1',action='claim',payload=dict(evaluation_id=evaluation))],role='math_evaluation_worker')['result']
  candidate=dict(steps=[],edges=[],errors=[],causes=[],core=[],hints=[],references=[],paths=[],criteria=[],rubric=dict(rubric_version='math-rubric-v1',dimensions=dict(final_conclusion='ADEQUATE')),overall=dict(status='COMPLETE',diagnostic='ANSWER_CORRECT_AND_REASONING_SUFFICIENT',answer='CORRECT',coverage='ATTEMPTED'),provenance=dict(model_provider='synthetic',model_name='fixture',prompt_version='1',contract_version='math-eval-v1'),progression=None if previous is None else dict(prior_evaluation_id=previous,core_corrected=False,root_error_removed=False,new_independent_error=False,answer_now_correct=False,justification_improved=False,no_material_change=True),generated_solution=None,selected_extraction=None)
  lab=os.environ.get('MATH_LAB_WORKTREE','/private/tmp/legendstudy-math-activation-lab')
  with tempfile.TemporaryDirectory(prefix='math-wire-',dir='/private/tmp') as temp:
   source=Path(temp)/'input.json';target=Path(temp)/'output.json';source.write_text(json.dumps(dict(claim=claim,candidate=candidate)))
   subprocess.run(['/opt/homebrew/opt/node@22/bin/node','scripts/math-physical-roundtrip.mjs',str(source),str(target)],cwd=lab,check=True,capture_output=True)
   wire=json.loads(target.read_text())
  result=rpc('math_evaluation',[dict(dto_version='math-worker-v1',action='finalize',payload=dict(evaluation_id=evaluation,lease_token=claim['lease_token'],output=wire))],role='math_evaluation_worker')
  return result
 balance=lambda:scalar("select coalesce(sum(balance_delta),0) from public.credit_transactions t join public.credit_accounts a on a.id=t.account_id where a.user_id=%s",(user2,))
 before=balance();finalize_physical(initial);ok('physical_initial_credit_minus_one',balance()==before-1)
 resolved=rpc('math_learning',[dict(dto_version='math-learning-v1',action='create_resolve_attempt',payload=dict(client_submission_id=new(),leaf_id=leaf,kind='SHORT_ANSWER_RESOLVE',predecessor_id=typed,prior_evaluation_id=initial,input_kind='TYPED',typed_answer='2 again'))],uid=user2)['result']['attempt_id']
 reevaluation=rpc('math_learning',[dict(dto_version='math-learning-v1',action='request_reevaluation',payload=dict(attempt_id=resolved,client_submission_id=new()))],uid=user2)['result']['evaluation_id']
 before=balance();finalize_physical(reevaluation,initial);ok('physical_reevaluation_credit_zero',balance()==before)
 state=rpc('math_learning',[dict(dto_version='math-learning-v1',action='read_learning_state',payload=dict(evaluation_id=initial))],uid=user2)['result']
 ok('gateway_owner_completed_projection',state['evaluation_state']=='COMPLETED')
 abandoned=str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL',input_kind='TYPED',typed_answer='abandoned synthetic')],uid=user2))
 pending=str(rpc('math_request_evaluation',[abandoned,new()],uid=user2))
 pendingstate=rpc('math_learning',[dict(dto_version='math-learning-v1',action='read_learning_state',payload=dict(evaluation_id=pending))],uid=user2)['result']
 ok('gateway_owner_requested_projection',pendingstate['evaluation_state']=='REQUESTED')
 deny('recover_browser_denial',lambda:rpc('math_recover_evaluation',[pending],uid=user2))
 ok('recover_current_denied',rpc('math_recover_evaluation',[pending],role='math_evaluation_worker')==False)
 before=balance();c.execute("update public.math_evaluations set requested_at=clock_timestamp()-interval '6 minutes' where id=%s",(pending,))
 c.execute('update math_private.runtime_control set evaluations_enabled=false')
 ok('recover_abandoned_when_paused',rpc('math_recover_evaluation',[pending],role='math_evaluation_worker'))
 ok('recover_no_debit',balance()==before)
 ok('recover_retry',rpc('math_recover_evaluation',[pending],role='math_evaluation_worker')==False)
 ok('recover_completed_unchanged',rpc('math_recover_evaluation',[initial],role='math_evaluation_worker')==False)
 (V/'validation.json').write_text(json.dumps(dict(checks=checks,migration_sha256=hashlib.sha256(M.read_bytes()).hexdigest(),storage_api='separate Deno fixture; Hosted not run',production_writes=0),indent=2)+'\n')
 return old
source=ns['ns']['source'].replace(" o.execute_as_production(c,admin,M.read_text())"," o.execute_as_production(c,admin,(R/'supabase/migrations/20261002000200_math_runtime_surface.sql').read_text())\n o.execute_as_production(c,admin,(R/'supabase/migrations/20261002000300_math_learning_runtime.sql').read_text())")
space=dict(m.__dict__);space.update(V=V,M=M,verify_math_cases=cases);exec(source,space)
m.h.verify_hqp=space['verify'];m.h.main(bootstrap_user='supabase_admin')
