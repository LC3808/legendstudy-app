#!/usr/bin/env python3
"""MATH-2E learning behavioral/concurrency/failure checks after unchanged C/D regressions."""
import inspect,json,hashlib,copy,concurrent.futures,time
from pathlib import Path
import psycopg
from psycopg.types.json import Jsonb
R=Path(__file__).resolve().parents[1];V=R/'supabase/verification/math_essay/learning';M=R/'supabase/migrations/20261002000300_math_learning_runtime.sql'
# Load existing runtime definitions without invoking its CLI; leave historical artifacts intact.
s=(R/'tool/test_math_runtime.py').read_text().split("ns['verify_math_cases']=cases;")[0]
ns={'__file__':str(R/'tool/test_math_runtime.py'),'__name__':'learning_fixture'};exec(compile(s,str(R/'tool/test_math_runtime.py'),'exec'),ns)
base_cases=ns['cases'];m=ns['m']
def cases(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock):
 # Redirect only artifact destination; execute actual unchanged C01-C30 +131 Math behavior.
 ns['V']=V/'runtime';ns['V'].mkdir(exist_ok=True)
 old=base_cases(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock)
 checks=[];extras=[]
 def ok(n,cond=True):assert cond,n;checks.append(n);print(n,'PASS',flush=True)
 def deny(n,fn):
  try:fn()
  except psycopg.Error as ex:
   assert ex.sqlstate in ('42501','22023','23505','23514','23503','P0002','22P02','PT402'),(n,ex.sqlstate,str(ex));ok(n);return
  raise AssertionError(n+' allowed')
 def call(action,payload,uid=A,role='authenticated'):return rpc('math_learning',[dict(dto_version='math-learning-v1',action=action,payload=payload)],uid=uid,role=role)['result']
 def state(e):return call('read_learning_state',dict(evaluation_id=e))
 rpc('essay_admin_grant',[A,40,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 full=str(scalar("select id from public.math_subproblems where response_format='PROOF' limit 1"))
 sol=str(scalar('select id from public.math_canonical_solutions where leaf_id=%s limit 1',(full,)))
 ai=new();c.execute("insert into public.math_canonical_solutions(id,leaf_id,logical_id,version,origin,state,body) values(%s,%s,%s,1,'AI_PROPOSED','ACTIVE','Synthetic AI reference')",(ai,full,new()))
 def attempt(lf=leaf,user=A):return str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=lf,kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic new answer')],uid=user))
 def final(e,payload):
  claim=rpc('math_claim_evaluation',[e],role='math_evaluation_worker');rpc('math_finalize_evaluation',[e,claim['lease_token'],payload],role='math_evaluation_worker');return claim
 fa=attempt(full);fe=str(rpc('math_request_evaluation',[fa,new()]));step,err,core,h0,h1,h2=[new() for _ in range(6)]
 fo=copy.deepcopy(out);fo.update(steps=[dict(id=step,position=1,kind='JUSTIFICATION',representation='Synthetic',status='CALCULATION_ERROR',explanation='Synthetic',regions=[])],errors=[dict(id=err,step_id=step,classification='ROOT',category='SIGN',materiality='MATERIAL_ERROR',explanation='Synthetic')],core=[dict(id=core,position=1,error_id=err,step_id=step,title='Synthetic CORE',diagnosis='Synthetic',why='Synthetic',next_action='Synthetic')],hints=[dict(id=h,core_id=core,level=l,body='Private synthetic hint '+str(l),leakage_class=leak,validated=True) for h,l,leak in [(h0,0,'CORE_ONLY'),(h1,1,'SAFE_DIRECTION'),(h2,2,'CONCEPT_REVEAL')]],references=[sol,ai],rubric=dict(logical_development='NEEDS_IMPROVEMENT',justification_completeness='ADEQUATE',final_conclusion='INSUFFICIENT'),generated_solution=dict(body='Synthetic generated reference',origin='AI_GENERATED'))
 fo['criteria']=[dict(criterion_id=str(x[0]),verdict='partially_satisfied',explanation='Synthetic') for x in c.execute('select id from public.math_scoring_criteria where leaf_id=%s',(full,)).fetchall()]
 final(fe,fo)
 ok('L01',state(fe)['evaluation_id']==fe)
 deny('L02',lambda:call('read_learning_state',{'evaluation_id':fe},B))
 deny('L03',lambda:call('read_learning_state',{'evaluation_id':fe},role='anon'))
 ok('L04',any(x['level']==0 for x in state(fe)['hints']) and 'Private synthetic hint' not in json.dumps(state(fe)))
 tx=scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t');frozen=scalar('select output_sha256 from public.math_evaluations where id=%s',(fe,))
 def hint(h,l,key=None):return call('reveal_hint',dict(evaluation_id=fe,hint_id=h,level=l,client_submission_id=key or new()))
 key=new();hint(h1,1,key);ok('L05');hint(h2,2);ok('L06')
 deny('L07',lambda:hint(new(),1));deny('L08',lambda:hint(h0,3))
 before=scalar('select count(*) from public.math_hint_exposures');hint(h1,1,key);ok('L09',before==scalar('select count(*) from public.math_hint_exposures'))
 deny('L10',lambda:hint(h2,2,key));deny('L11',lambda:call('reveal_hint',dict(evaluation_id=ev,hint_id=h1,level=1,client_submission_id=new())))
 ok('L13',scalar('select count(*) from public.math_hint_exposures where client_key=%s',(key,))==1)
 ok('L14',frozen==scalar('select output_sha256 from public.math_evaluations where id=%s',(fe,)))
 ok('L15',tx==scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t'))
 # Early solution on a second fresh initial with no hint events; source IDs remain pinned.
 ea=attempt(full);ee=str(rpc('math_request_evaluation',[ea,new()]));eo=copy.deepcopy(fo)
 mapping={x:new() for x in [step,err,core,h0,h1,h2]};eo=json.loads(json.dumps(eo),object_hook=lambda d:{k:mapping.get(v,v) if isinstance(v,str) else v for k,v in d.items()});final(ee,eo)
 solution_key=new();payload=dict(evaluation_id=ee,target='REFERENCE',solution_id=sol,client_submission_id=solution_key)
 attempts_before=scalar('select count(*) from public.math_attempts');tx=scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t')
 revealed=call('reveal_solution',payload);ok('L16',revealed['exposure_id'] and not any(x['revealed'] for x in state(ee)['hints']))
 ok('L17',revealed['provenance']=='OFFICIAL_SOLUTION')
 ar=call('reveal_solution',dict(payload,solution_id=ai,client_submission_id=new()));gr=call('reveal_solution',dict(payload,target='GENERATED',solution_id=None,client_submission_id=new()));ok('L18',ar['provenance']==gr['provenance']=='AI_GENERATED_REFERENCE')
 ok('L19',call('reveal_solution',payload)==revealed)
 deny('solution_key_conflict',lambda:call('reveal_solution',dict(payload,solution_id=ai)))
 ok('L20',tx==scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t'))
 ok('L26',attempts_before==scalar('select count(*) from public.math_attempts'))
 def resolve(parent,prior,kind,lf=leaf,target=None,key=None,text='Different submitted work'):
  return call('create_resolve_attempt',dict(client_submission_id=key or new(),leaf_id=lf,kind=kind,predecessor_id=parent,prior_evaluation_id=prior,target_step_id=target,input_kind='TYPED',typed_answer=text))['attempt_id']
 retry=resolve(fa,fe,'STEP_RETRY',full,step);ok('L21',retry!=fa)
 whole=resolve(ea,ee,'FULL_RESOLVE',full);ok('L22',whole!=ea)
 sa=attempt();se=str(rpc('math_request_evaluation',[sa,new()]));final(se,out)
 short=resolve(sa,se,'SHORT_ANSWER_RESOLVE');ok('L23',short!=sa)
 deny('L24',lambda:resolve(sa,se,'PARTIAL_RESOLVE'))
 ok('L25','R24_confirmation_not_resolve' in old)
 ok('L27',scalar('select lineage_id from public.math_attempts where id=%s',(short,))==scalar('select lineage_id from public.math_attempts where id=%s',(sa,)))
 deny('L28',lambda:resolve(sa,se,'FULL_RESOLVE',full))
 deny('L29',lambda:resolve(fa,fe,'STEP_RETRY',full,new()))
 ok('L31',state(se)['included_reevaluation']['eligible'])
 deadline=scalar('select completed_at+interval \'336 hours\' from public.math_evaluations where id=%s',(se,));ok('L32',scalar('select math_private.learning_eligibility(%s,%s)',(se,deadline))['status']=='EXPIRED')
 # Failed included request frees authorization; valid HRR is a completed evaluation.
 rqkey=new();re=call('request_reevaluation',dict(attempt_id=short,client_submission_id=rqkey))['evaluation_id']
 rc=rpc('math_claim_evaluation',[re],role='math_evaluation_worker');rpc('math_fail_evaluation',[re,rc['lease_token'],'TIMEOUT'],role='math_evaluation_worker');ok('L34',state(se)['included_reevaluation']['eligible'])
 rk=new();re=call('request_reevaluation',dict(attempt_id=short,client_submission_id=rk))['evaluation_id']
 ok('L37',call('request_reevaluation',dict(attempt_id=short,client_submission_id=rk))['evaluation_id']==re)
 other=resolve(sa,se,'SHORT_ANSWER_RESOLVE');deny('L38',lambda:call('request_reevaluation',dict(attempt_id=other,client_submission_id=rk)))
 ro=copy.deepcopy(out);ro['overall']=dict(ro['overall'],status='NOT_DETERMINABLE',review_status='HUMAN_REVIEW_REQUIRED');ro['progression']=dict(prior_evaluation_id=se,target_step_id=None,downstream=None,summary='Synthetic uncertain result',delta=[dict(kind='NO_MATERIAL_CHANGE',explanation='Synthetic unchanged')]);final(re,ro)
 ok('L35',state(re)['valid_evaluation_available'] and state(re)['review_status']=='HUMAN_REVIEW_REQUIRED')
 deny('L33',lambda:call('request_reevaluation',dict(attempt_id=other,client_submission_id=new())))
 # STEP_RETRY retains mandatory NOT_REASSESSED; delta is worker fact, not runtime computation.
 er=call('request_reevaluation',dict(attempt_id=retry,client_submission_id=new()))['evaluation_id'];rr=rpc('math_claim_evaluation',[er],role='math_evaluation_worker');rp=copy.deepcopy(out);rp['rubric']=fo['rubric'];rp['criteria']=fo['criteria'];rp['overall']['coverage']='NOT_ATTEMPTED';rp['progression']=dict(prior_evaluation_id=fe,target_step_id=step,downstream='NOT_REASSESSED',summary='Synthetic step scope',delta=[dict(kind='ROOT_ERROR_REMOVED',prior_error_id=err,explanation='Synthetic')]);rpc('math_finalize_evaluation',[er,rr['lease_token'],rp],role='math_evaluation_worker');ok('L30',state(er)['downstream']=='NOT_REASSESSED')
 history=call('read_learning_history',dict(evaluation_id=ee,limit=20));ok('L40',history['attempts'][0]['attempt_id']==whole and history['attempts'][0]['reference_solution_revealed_before_resolve'])
 # Real multi-session calls (no sequential-only concurrency substitutes).
 def concurrent_call(action,payload):
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as cc:
   try:
    with cc.transaction():
     cc.execute("set local role authenticated;set local statement_timeout='8s'");cc.execute("select set_config('request.jwt.claim.sub',%s,true)",(A,))
     return cc.execute('select public.math_learning(%s)',(Jsonb(dict(dto_version='math-learning-v1',action=action,payload=payload)),)).fetchone()[0]['result']
   except psycopg.Error as ex:return {'error':ex.sqlstate}
 def race(action,payloads):
  with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:return list(pool.map(lambda v:concurrent_call(action,v),payloads))
 hk=new();vals=race('reveal_hint',[dict(evaluation_id=fe,hint_id=h1,level=1,client_submission_id=hk)]*4);ok('concurrent_hint',all('error' not in v for v in vals) and scalar('select count(*) from public.math_hint_exposures where client_key=%s',(hk,))==1)
 sk=new();vals=race('reveal_solution',[dict(payload,client_submission_id=sk)]*4);ok('concurrent_solution',len({v['exposure_id'] for v in vals})==1)
 ca=attempt();ce=str(rpc('math_request_evaluation',[ca,new()]));final(ce,out);c1=resolve(ca,ce,'SHORT_ANSWER_RESOLVE');c2=resolve(ca,ce,'SHORT_ANSWER_RESOLVE')
 vals=race('request_reevaluation',[dict(attempt_id=c1,client_submission_id=new()),dict(attempt_id=c2,client_submission_id=new())]);ok('L36',sum('evaluation_id' in v for v in vals)==1 and sum(v.get('error') in ('22023','PT402') for v in vals)==1)
 ak=new();av=dict(client_submission_id=ak,leaf_id=leaf,kind='SHORT_ANSWER_RESOLVE',predecessor_id=ca,prior_evaluation_id=ce,target_step_id=None,input_kind='TYPED',typed_answer='Synthetic')
 vals=race('create_resolve_attempt',[av]*4);ok('concurrent_resolve',len({v['attempt_id'] for v in vals})==1)
 # Failures are inside the same RPC transaction; trigger fixtures are isolated only.
 def inject(table,action,data):
  before=scalar('select jsonb_build_array((select count(*) from public.math_hint_exposures),(select count(*) from public.math_solution_exposures),(select count(*) from public.math_attempts),(select count(*) from public.math_evaluations),(select count(*) from public.credit_transactions))')
  c.execute("create function public.learning_test_fault() returns trigger language plpgsql as $$begin raise exception 'TEST_FAULT' using errcode='22023';end$$")
  c.execute('create trigger learning_test_fault before insert on public.'+table+' for each row execute function public.learning_test_fault()')
  try:deny('fault_'+table,lambda:call(action,data))
  finally:c.execute('drop trigger learning_test_fault on public.'+table);c.execute('drop function public.learning_test_fault()')
  after=scalar('select jsonb_build_array((select count(*) from public.math_hint_exposures),(select count(*) from public.math_solution_exposures),(select count(*) from public.math_attempts),(select count(*) from public.math_evaluations),(select count(*) from public.credit_transactions))');assert before==after
 inject('math_hint_exposures','reveal_hint',dict(evaluation_id=fe,hint_id=h1,level=1,client_submission_id=new()))
 inject('math_solution_exposures','reveal_solution',dict(payload,client_submission_id=new()))
 inject('math_attempts','create_resolve_attempt',dict(av,client_submission_id=new()))
 fresh=attempt();fre=str(rpc('math_request_evaluation',[fresh,new()]));final(fre,out);fra=resolve(fresh,fre,'SHORT_ANSWER_RESOLVE')
 inject('essay_billing_decisions','request_reevaluation',dict(attempt_id=fra,client_submission_id=new()))
 # New generated-reference FK and immutable delta validation are exercised, not inferred.
 gc_before=scalar('select count(*) from public.math_solution_exposures where evaluation_id=%s',(ee,))
 try:
  with c.transaction():
   c.execute('delete from public.math_evaluations where id=%s',(ee,))
   assert scalar('select count(*) from public.math_solution_exposures where evaluation_id=%s',(ee,))==0
   raise RuntimeError('fixture rollback')
 except RuntimeError:pass
 ok('generated_reference_e1_cascade',gc_before>0)
 bad=copy.deepcopy(rp);bad['progression']['delta'][0]['kind']='ARBITRARY_SCORE'
 deny('unknown_delta_kind',lambda:c.execute('select math_private.validate_output(%s,%s)',(er,Jsonb(bad))))
 bad=copy.deepcopy(rp);bad['progression']['delta'][0]['prior_error_id']=new()
 deny('foreign_delta_fact',lambda:c.execute('select math_private.validate_output(%s,%s)',(er,Jsonb(bad))))
 # Rollback package refuses any nonempty canonical learning installation.
 try:c.execute((V/'rollback.sql').read_text());raise AssertionError('nonempty rollback allowed')
 except psycopg.errors.RaiseException as ex:assert ex.diag.message_primary=='EMPTY_MATH_INSTALL_ONLY'
 finally:c.execute('rollback')
 ok('nonempty_rollback_refused')
 # Two worker/session races with lifecycle fence held before the learning request starts.
 def lifecycle_race(action,data):
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as cc:
   with cc.transaction():
    cc.execute('set local role authenticated');cc.execute("select set_config('request.jwt.claim.sub',%s,true)",(A,));cc.execute('select public.account_deletion_request()')
    pool=concurrent.futures.ThreadPoolExecutor(max_workers=1);f=pool.submit(concurrent_call,action,data);time.sleep(.1);assert not f.done()
   assert f.result()=={'error':'42501'};pool.shutdown()
  sid=new();rpc('account_reauth_attest',[A,sid],role='account_lifecycle_worker');rpc('account_deletion_cancel',uid=A,extra={'session_id':sid})
 lifecycle_race('create_resolve_attempt',dict(av,client_submission_id=new()));ok('resolve_lifecycle_race')
 lifecycle_race('request_reevaluation',dict(attempt_id=fra,client_submission_id=new()));ok('reevaluation_lifecycle_race')
 rpc('account_deletion_request',uid=A);deny('L12',lambda:hint(h1,1,key));deny('L39',lambda:call('reveal_solution',payload))
 sid=new();rpc('account_reauth_attest',[A,sid],role='account_lifecycle_worker');rpc('account_deletion_cancel',uid=A,extra={'session_id':sid})
 deny('unknown_version',lambda:rpc('math_learning',[dict(dto_version='bad',action='read_learning_state',payload={'evaluation_id':fe})]))
 deny('forged_owner',lambda:call('read_learning_state',dict(evaluation_id=fe,owner_id=A)))
 deny('forged_eligibility',lambda:call('request_reevaluation',dict(attempt_id=fra,client_submission_id=new(),free=True)))
 deny('service_role',lambda:call('read_learning_state',dict(evaluation_id=fe),role='service_role'))
 # Signup promotional grant with no grant expiry still uses the same finite review window.
 free=new();c.execute('insert into auth.users(id) values(%s)',(free,));c.execute('insert into public.profiles(id) values(%s)',(free,))
 c.execute("select essay_private.credit_post_grant(%s,3,'signup_bonus',%s,'signup_bonus_v1','system/signup_bonus',null)",(free,'synthetic_signup/'+new()))
 fpa=attempt(user=free);fpe=str(rpc('math_request_evaluation',[fpa,new()],uid=free));final(fpe,out)
 fs=call('read_learning_state',{'evaluation_id':fpe},free)['included_reevaluation']
 ok('free_credit_window_parity',fs['eligible'] and scalar("select expires_at is null from public.credit_grants g join public.credit_accounts a on a.id=g.account_id where a.user_id=%s",(free,)) and fs['expires_at']==str(scalar("select to_jsonb(completed_at+interval '336 hours') from public.math_evaluations where id=%s",(fpe,))))
 deny('history_bound',lambda:call('read_learning_history',dict(evaluation_id=fe,limit=51)))
 frozen_counts=scalar('select count(*) from public.math_solution_exposures')
 try:
  with c.transaction():
   call('reveal_solution',dict(payload,client_submission_id=new()))
   c.execute("do $$begin raise exception 'TEST_ROLLBACK' using errcode='22023';end$$")
 except psycopg.errors.InvalidParameterValue:pass
 ok('transaction_rollback',scalar('select count(*) from public.math_solution_exposures')==frozen_counts)
 c.execute("insert into public.account_deletion_requests(subject_id,requested_at,scheduled_deletion_at,state,lease_token,lease_until) values(%s,statement_timestamp()-interval '337 hours',statement_timestamp()-interval '1 hour','ERASING',gen_random_uuid(),clock_timestamp()+interval '5 minutes')",(A,))
 deny('erasing_learning_denied',lambda:call('create_resolve_attempt',dict(av,client_submission_id=new())))
 deny('erasing_hint_retry_denied',lambda:hint(h1,1,key))
 assert all(f'L{i:02}' in checks for i in range(1,41))
 (V/'validation.json').write_text(json.dumps(dict(migration_sha256=hashlib.sha256(M.read_bytes()).hexdigest(),checks=checks,L01_L40={f'L{i:02}':'PASS' for i in range(1,41)},production_writes=0,provider_calls=0),indent=2)+'\n')
 return old
source=ns['source'].replace(' o.execute_as_production(c,admin,M.read_text())',' o.execute_as_production(c,admin,(R/\'supabase/migrations/20261002000200_math_runtime_surface.sql\').read_text())\n o.execute_as_production(c,admin,M.read_text())')
space=dict(m.__dict__);space.update(V=V,M=M,verify_math_cases=cases);exec(source,space)
m.h.verify_hqp=space['verify'];m.h.main(bootstrap_user='supabase_admin')
