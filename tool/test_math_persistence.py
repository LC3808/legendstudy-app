#!/usr/bin/env python3
"""MATH-2C behavioral acceptance; disposable Unix-only PG17 and synthetic data only."""
import sys,json,uuid,hashlib,runpy
from pathlib import Path
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'tool'))
import test_human_quality as h,test_account_deletion_ownership as o
import psycopg
from psycopg.types.json import Jsonb

def verify(c,rpc,new,scalar,first,second,zero,A,B,OP,session,previous,args,sock):
 for version in ['20260913000200','20260914000100','20260914000200','20260923000100','20260926000100','20260930000100','20260917000200','20261001000200']:
  c.execute(next((R/'supabase/migrations').glob(version+'_*.sql')).read_text())
 c.execute('alter table auth.users add column email_confirmed_at timestamptz default now()')
 admin=o.prepare(c,sock)
 o.execute_as_production(c,admin,(R/'supabase/migrations/20261001000300_account_deletion_lifecycle.sql').read_text())
 rub={k:'OK' for k in ['diagnosis','core_priority','actionability','evidence_adherence','stance_preservation','hallucination_absence']};rub.update(sentence_feedback='NA',progression='NA',generated_rewrite='NA')
 basepayload=dict(dto_version='hq-write-v1',evaluation_id=zero,expected_output_sha256=scalar('select output_sha256 from public.essay_evaluations where id=%s',(zero,)),client_submission_id=new(),rubric_version='hq-rubric-v1',overall_disposition='PASS',rubric_result=rub,findings=[],official_source_reviewed=True)
 basejudgment=rpc('ql_submit_human_judgment',[basepayload],uid=OP)['judgment_id'];basewire=rpc('ql_list_human_judgments',[zero],uid=OP);basefact=scalar('select to_jsonb(j) from public.human_quality_judgments j where id=%s',(basejudgment,))
 basecredit=scalar("select jsonb_agg(jsonb_build_array(pg_get_functiondef(p.oid),p.proacl::text,p.proowner) order by p.oid) from pg_proc p where p.pronamespace='essay_private'::regnamespace")
 oldql=scalar("select jsonb_agg(jsonb_build_array(pg_get_functiondef(oid),proacl::text) order by oid) from pg_proc where pronamespace='public'::regnamespace and proname in ('ql_list_cases','ql_case_detail','ql_review_state')")
 o.execute_as_production(c,admin,(R/'supabase/migrations/20261002000100_math_essay_persistence.sql').read_text())
 print('MATH_FULL_NON_SUPERUSER_INSTALL_PASS')
 assert basewire==rpc('ql_list_human_judgments',[zero],uid=OP)
 assert basefact==scalar("select to_jsonb(j)-'math_evaluation_id' from public.human_quality_judgments j where id=%s",(basejudgment,))
 assert basecredit==scalar("select jsonb_agg(jsonb_build_array(pg_get_functiondef(p.oid),p.proacl::text,p.proowner) order by p.oid) from pg_proc p where p.pronamespace='essay_private'::regnamespace")
 print('R01_R04_R05_LEGACY_FACT_HASH_WIRE_EXACT_PASS')
 print('R15_ESSAY_PRIVATE_BODIES_OWNERS_ACLS_PRESERVED')
 assert oldql==scalar("select jsonb_agg(jsonb_build_array(pg_get_functiondef(oid),proacl::text) order by oid) from pg_proc where pronamespace='public'::regnamespace and proname in ('ql_list_cases','ql_case_detail','ql_review_state')")
 print('QL_PRESERVATION_PASS')
 exam=scalar('select id from public.essay_exams limit 1');ps=new();pr=new();leaf=new();profile=new()
 c.execute("insert into public.math_problem_sets(id,essay_exam_id,logical_id,version,label,state) values(%s,%s,%s,1,'Synthetic','ACTIVE')",(ps,exam,new()))
 c.execute("insert into public.math_problems(id,problem_set_id,logical_id,version,display_order,statement,state) values(%s,%s,%s,1,1,'Synthetic question','ACTIVE')",(pr,ps,new()))
 c.execute("insert into public.math_subproblems(id,problem_id,leaf_key,display_order,statement,response_format) values(%s,%s,'singleton',1,'Synthetic','SHORT_ANSWER')",(leaf,pr))
 c.execute("insert into public.math_source_artifacts(problem_id,source_role,source_url,locator,provenance,verification) values(%s,'QUESTION','https://example.edu/synthetic','p1','OFFICIAL','REFERENCE_ONLY')",(pr,))
 c.execute("insert into public.math_evaluation_profiles(id,logical_id,version,scope,leaf_id,response_format,rubric_version,required_dimensions,reasoning_required,state) values(%s,%s,1,'LEAF',%s,'SHORT_ANSWER','math-rubric-v1',array['final_conclusion'],false,'ACTIVE')",(profile,new(),leaf))
 rpc('essay_admin_grant',[A,5,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 at=str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL',input_kind='TYPED',typed_answer='2')]))
 ev=str(rpc('math_request_evaluation',[at,new()]));cl=rpc('math_claim_evaluation',[ev],role='math_evaluation_worker')
 out=dict(contract_version='math-eval-v1',extraction_id=None,steps=[],edges=[],errors=[],causes=[],core=[],hints=[],references=[],paths=[],criteria=[],rubric={'final_conclusion':'ADEQUATE'},overall={'status':'ANSWER_CORRECT_AND_REASONING_SUFFICIENT','answer_status':'CORRECT','coverage':'ATTEMPTED','explanation':'Synthetic'},provenance={'provider':'synthetic','model':'mock','model_version':'1','prompt_version':'1'},progression=None,generated_solution=None)
 print('CLAIM',list(cl))
 rpc('math_finalize_evaluation',[ev,cl['lease_token'],out],role='math_evaluation_worker')
 print('SHORT_ANSWER_FINALIZE_PASS')
 assert rpc('math_evaluation_detail',[ev])['output']['core']==[]
 r={k:'OK' for k in ['diagnosis','core_priority','actionability','evidence_adherence','valid_path_preservation','hallucination_absence']};r.update({k:'NA' for k in ['extraction_fidelity','step_reasoning','hint_quality','progression','generated_solution']})
 p=dict(dto_version='hq-math-write-v1',math_evaluation_id=ev,expected_output_sha256=scalar('select output_sha256 from public.math_evaluations where id=%s',(ev,)),client_submission_id=new(),rubric_version='hq-math-rubric-v1',overall_disposition='PASS',rubric_result=r,findings=[],reference_context_reviewed=True)
 j=rpc('qlm_submit_human_judgment',[p],uid=OP);print('MATH_HQ_SUBMIT_PASS')
 assert rpc('qlm_submit_human_judgment',[p],uid=OP)['replayed']
 assert len(rpc('qlm_list_human_judgments',[ev],uid=OP)['judgments'])==1
 assert rpc('qlm_review_state',[[ev]],uid=OP)['cases'][0]['human_review_state']=='REVIEWED_ACCEPTABLE'
 print('MATH_HQ_READ_RETRY_PASS')
 checks=verify_math_cases(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock)
 (R/'supabase/verification/math_essay/behavior_validation.json').write_text(json.dumps({'scope':'isolated PG17 canonical chain; synthetic auth roles/claims; no provider or Storage runtime','migration_sha256':hashlib.sha256((R/'supabase/migrations/20261002000100_math_essay_persistence.sql').read_bytes()).hexdigest(),'checks':checks,'count':len(checks),'legacy_fact_hash_wire_exact':True,'essay_private_definitions_acl_preserved':True,'ql_read_v1_preserved':True,'production_writes':0},indent=2)+'\n')

import copy,concurrent.futures,json,uuid,time
import psycopg
from psycopg.types.json import Jsonb

def verify_math_cases(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock):
 checks=[]
 def ok(n,cond=True):
  assert cond,n;checks.append(n);print(n,'PASS',flush=True)
 def deny(n,fn,states=('42501','23514','23503','23505','22023','22P02','P0002','23502','PT402')):
  try:fn()
  except psycopg.Error as e:assert e.sqlstate in states,(n,e.sqlstate,str(e));ok(n);return
  raise AssertionError(n+' allowed')
 def attempt(kind='INITIAL',parent=None,prior=None,target=None,input_kind='TYPED',lf=leaf,user=A):
  return str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=lf,kind=kind,input_kind=input_kind,typed_answer='Synthetic 2' if input_kind=='TYPED' else None,predecessor_id=parent,prior_evaluation_id=prior,target_step_id=target)],uid=user))
 def request(a):return str(rpc('math_request_evaluation',[a,new()]))
 def claim(e):return rpc('math_claim_evaluation',[e],role='math_evaluation_worker')
 def finalize(e,token,v):return rpc('math_finalize_evaluation',[e,token,v],role='math_evaluation_worker')
 def decide(e):return scalar('select d.credits_required from public.essay_billing_decisions d join public.math_billing_bindings b on b.billing_decision_id=d.id where b.math_evaluation_id=%s',(e,))
 def hp(e=ev,disp='PASS',findings=None):
  z=copy.deepcopy(p);z.update(math_evaluation_id=e,expected_output_sha256=scalar('select output_sha256 from public.math_evaluations where id=%s',(e,)),client_submission_id=new(),overall_disposition=disp,findings=findings or []);return z
 def submit(z,user=OP):return rpc('qlm_submit_human_judgment',[z],uid=user)
 def finding(kind,ref,category='OTHER'):return dict(issue_category=category,severity='MINOR',target_kind=kind,target_ref=ref,note='Synthetic')
 def race(z):
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as cc:
   with cc.transaction():
    cc.execute('set local role authenticated');cc.execute("select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claims',%s,true)",(OP,json.dumps({'sub':OP,'role':'authenticated','exp':int(time.time())+600})))
    return cc.execute('select public.qlm_submit_human_judgment(%s)',(Jsonb(z),)).fetchone()[0]
 # Current read/ACL separation, retry bytes.
 ok('R24_short_answer_zero_graph',rpc('math_evaluation_detail',[ev])['output']['steps']==[])
 ok('R18_duplicate_finalize',str(finalize(ev,cl['lease_token'],out))==ev)
 changed=copy.deepcopy(out);changed['overall']['explanation']='changed';deny('R19_changed_retry',lambda:finalize(ev,cl['lease_token'],changed))
 for role in ['anon','authenticated','service_role']:
  for table in [x[0] for x in c.execute("select tablename from pg_tables where schemaname='public' and tablename like 'math_%'")]:
   for priv in ['SELECT','INSERT','UPDATE','DELETE']:assert not scalar('select has_table_privilege(%s,%s,%s)',(role,'public.'+table,priv))
 ok('R12_table_ACLs')
 for f,roles in [('math_claim_extraction',['math_extraction_worker']),('math_claim_evaluation',['math_evaluation_worker'])]:
  for role in ['anon','authenticated','service_role','math_extraction_worker','math_evaluation_worker']:
   assert scalar("select has_function_privilege(%s,%s,'EXECUTE')",(role,'public.'+f+'(uuid)'))==(role in roles)
 ok('R12_worker_separation')
 deny('R12_student_foreign_read',lambda:rpc('math_evaluation_detail',[ev],uid=B))
 deny('R12_nonoperator',lambda:submit(hp(),B));deny('R12_anon',lambda:rpc('qlm_submit_human_judgment',[hp()],uid=None,role='anon'))
 z=hp();z['reviewer_user_id']=A;deny('R12_forged_reviewer',lambda:submit(z))
 # HQ shape, target, corrections, projection.
 for mutate,label in [(lambda z:z.update(rubric_version='hq-rubric-v1'),'foreign_rubric'),(lambda z:z['rubric_result'].pop('diagnosis'),'missing'),(lambda z:z['rubric_result'].update(extra='OK'),'unknown'),(lambda z:z['rubric_result'].update(diagnosis='BAD'),'verdict'),(lambda z:z['rubric_result'].update(extraction_fidelity='OK'),'NA'),(lambda z:z['rubric_result'].update(diagnosis='FAIL'),'blocking'),(lambda z:z.update(summary_note='x'*2001),'summary'),(lambda z:z.update(findings=[finding('OVERALL',None)]),'PASS_finding')]:
  z=hp();mutate(z);deny('R07_'+label,lambda z=z:submit(z))
 z=hp(disp='PASS_WITH_NOTES',findings=[finding('OVERALL',None)]);j=submit(z)['judgment_id'];ok('R08_overall_positive')
 z['client_submission_id']=new();z['findings'][0]['note']='x'*1001;deny('R07_note_bound',lambda:submit(z))
 for kind,ref in [('SOLUTION_STEP',{'step_id':new()}),('ROOT_ERROR',{'error_id':new()}),('EXTRACTION_REGION',{'extraction_run_id':new(),'region_id':new()}),('ALTERNATIVE_PATH',{'path_kind':'REFERENCE','solution_version_id':new()}),('ALTERNATIVE_PATH',{'path_kind':'STUDENT','evaluated_path_key':'foreign'})]:deny('R08_foreign_'+kind,lambda kind=kind,ref=ref:submit(hp(disp='PASS_WITH_NOTES',findings=[finding(kind,ref)])))
 corr=hp(disp='FAIL');corr['supersedes_judgment_id']=j;j2=submit(corr)['judgment_id'];ok('R03_correction',scalar('select count(*) from public.human_quality_judgments where id in (%s,%s)',(j,j2))==2)
 bad=hp();bad['supersedes_judgment_id']=j;deny('R03_second_successor',lambda:submit(bad))
 deny('R03_cycle_update',lambda:c.execute('update public.human_quality_judgments set supersedes_judgment_id=%s where id=%s',(j2,j)))
 ok('R11_disagreement',rpc('qlm_review_state',[[ev]],uid=OP)['cases'][0]['human_review_state']=='DISAGREEMENT')
 z=hp();withkey=z['client_submission_id']
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:rr=list(pool.map(race,[z,z]))
 ok('R06_concurrent_retry',rr[0]['judgment_id']==rr[1]['judgment_id'] and scalar('select count(*) from public.human_quality_judgments where client_submission_id=%s',(withkey,))==1)
 z['summary_note']='changed';deny('R06_changed_payload',lambda:submit(z))
 c.execute('delete from public.quality_operators where user_id=%s',(OP,));deny('R06_revoked_retry',lambda:submit(p));c.execute('insert into public.quality_operators values(%s)',(OP,))
 deny('R02_neither',lambda:c.execute("insert into public.human_quality_judgments select (jsonb_populate_record(null::public.human_quality_judgments,to_jsonb(j)||jsonb_build_object('id',%s::text,'client_submission_id',%s::text,'math_evaluation_id',null))).* from public.human_quality_judgments j where id=%s",(new(),new(),j)))
 # Legacy HQ rows and exact wire projection captured before/after candidate install by caller.
 # Typed binding rejects updates and cross-domain reassignment in both directions.
 mb=scalar('select billing_decision_id from public.math_billing_bindings where math_evaluation_id=%s',(ev,));essay_ev=str(scalar("select id from public.essay_evaluations where status='completed' limit 1"));essay_decision=scalar('select id from public.essay_billing_decisions where evaluation_id=%s',(essay_ev,));acc=scalar('select account_id from public.math_billing_bindings where math_evaluation_id=%s',(ev,))
 deny('R13_duplicate_binding',lambda:c.execute('insert into public.math_billing_bindings values(%s,%s,%s)',(ev,mb,acc)))
 deny('R13_Essay_bound_rejected',lambda:c.execute('insert into public.math_billing_bindings values(%s,%s,%s)',(ev,essay_decision,acc)))
 deny('R14_Math_to_Essay_reassignment',lambda:c.execute('update public.essay_billing_decisions set evaluation_id=%s where id=%s',(essay_ev,mb)),states=('P0001',))
 deny('R14_binding_immutable',lambda:c.execute('update public.math_billing_bindings set account_id=%s where math_evaluation_id=%s',(acc,ev)))
 # Single key concurrent evaluation request locks the same account/attempt.
 def request_race(pair):
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as cc:
   with cc.transaction():
    cc.execute('set local role authenticated');cc.execute("select set_config('request.jwt.claim.sub',%s,true)",(A,));return str(cc.execute('select public.math_request_evaluation(%s,%s)',pair).fetchone()[0])
 ra=attempt();rk=new()
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool: requests=list(pool.map(request_race,[(ra,rk),(ra,rk)]))
 ok('R14_concurrent_request_binding',requests[0]==requests[1] and scalar('select count(*) from public.math_billing_bindings where math_evaluation_id=%s',(requests[0],))==1)
 rc=claim(requests[0]);rpc('math_fail_evaluation',[requests[0],rc['lease_token'],'TIMEOUT'],role='math_evaluation_worker')
 # Existing finance-only refund and reversal/account/posting guards remain active.
 consume=str(scalar("select id from public.credit_transactions where transaction_type='consume' and decision_id=%s limit 1",(essay_decision,)));refund_key='synthetic-refund/'+new()
 refund=rpc('essay_refund',[consume,refund_key,1],role='essay_finance');ok('R15_refund_idempotency',rpc('essay_refund',[consume,refund_key,1],role='essay_finance')==refund)
 deny('R15_refund_overrun',lambda:rpc('essay_refund',[consume,'synthetic-refund/'+new(),1],role='essay_finance'),states=('PT409','22023','P0001'))
 deny('R15_ledger_immutable',lambda:c.execute('update public.credit_transactions set balance_delta=balance_delta where id=%s',(consume,)),states=('P0001','23514'))
 # Exact boundary: an initial result exactly 336h old cannot grant an included revision.
 oldtime=scalar('select completed_at from public.math_evaluations where id=%s',(ev,));c.execute("update public.math_evaluations set completed_at=clock_timestamp()-interval '336 hours' where id=%s",(ev,))
 expired_attempt=attempt('SHORT_ANSWER_RESOLVE',at,ev);expired=request(expired_attempt);ok('R16_exact_336h_expired',decide(expired)==1);expired_claim=claim(expired);rpc('math_fail_evaluation',[expired,expired_claim['lease_token'],'TIMEOUT'],role='math_evaluation_worker');c.execute('update public.math_evaluations set completed_at=%s where id=%s',(oldtime,ev))

 # Lineage + included reevaluation + no second inclusion.
 a2=attempt('SHORT_ANSWER_RESOLVE',at,ev);e2=request(a2);ok('R16_included',decide(e2)==0);cl2=claim(e2);out2=copy.deepcopy(out);out2['progression']=dict(prior_evaluation_id=ev,target_step_id=None,downstream='REASSESSED',summary='Synthetic');finalize(e2,cl2['lease_token'],out2)
 a3=attempt('SHORT_ANSWER_RESOLVE',a2,e2);e3=request(a3);ok('R16_second_revision_paid',decide(e3)==1)
 cl3=claim(e3);rpc('math_fail_evaluation',[e3,cl3['lease_token'],'TIMEOUT'],role='math_evaluation_worker');rpc('math_fail_evaluation',[e3,cl3['lease_token'],'TIMEOUT'],role='math_evaluation_worker')
 ok('R17_release_once',scalar("select count(*) from public.credit_transactions t join public.math_billing_bindings b on b.billing_decision_id=t.decision_id where b.math_evaluation_id=%s and transaction_type='release'",(e3,))==1)
 # immutable content/profile selection and failed resolver
 deny('content_immutable',lambda:c.execute("update public.math_problems set statement='changed' where id=%s",(pr,)))
 deny('attempt_immutable',lambda:c.execute("update public.math_attempts set typed_answer='changed' where id=%s",(at,)))
 deny('profile_same_rank',lambda:c.execute("insert into public.math_evaluation_profiles select (jsonb_populate_record(null::public.math_evaluation_profiles,to_jsonb(p)||jsonb_build_object('id',%s::text,'logical_id',%s::text))).* from public.math_evaluation_profiles p where id=%s",(new(),new(),profile)))
 c.execute("update public.math_evaluation_profiles set state='SUPERSEDED' where id=%s",(profile,));deny('profile_absent_closed',lambda:attempt());ok('version_pin_preserved',str(scalar('select profile_id from public.math_evaluations where id=%s',(ev,)))==profile);c.execute("update public.math_evaluation_profiles set state='ACTIVE' where id=%s",(profile,))
 # Evidence ingestion + confirmation is not a new attempt / no charge.
 ae=attempt(input_kind='EVIDENCE');tx=scalar('select count(*) from public.credit_transactions');ar=rpc('math_register_artifact',[ae,dict(position=1,media_type='application/pdf',byte_size=100)])['artifact_id']
 deny('R21_unverified_bytes_block_delete',lambda:c.execute('delete from public.math_attempts where id=%s',(ae,)))
 deny('R21_wrong_namespace',lambda:c.execute("update public.math_attempt_artifacts set object_key='../escape' where id=%s",(ar,)))
 deny('R17_input_notready',lambda:request(ae));c.execute("update public.math_attempt_artifacts set storage_state='PRESENT' where id=%s",(ar,))
 x=rpc('math_claim_extraction',[ae],role='math_extraction_worker');raw=dict(regions=[dict(artifact_id=ar,page=1,reading_order=1,raw_text='2',normalized_math='2',confidence=.8,uncertain=True,x=0,y=0,width=.5,height=.5)],provider='synthetic',model='mock',model_version='1')
 raw['regions'].append(dict(raw['regions'][0],page=2,reading_order=2,uncertain=False))
 rpc('math_finalize_extraction',[x['run_id'],x['lease_token'],raw],role='math_extraction_worker');region=str(scalar('select id from public.math_extraction_regions where run_id=%s',(x['run_id'],)))
 deny('R17_uncertainty_not_confirmed',lambda:rpc('math_confirm_extraction',[ae,x['run_id'],Jsonb([])]))
 confirmed=str(rpc('math_confirm_extraction',[ae,x['run_id'],Jsonb([dict(region_id=region,raw_text='2',normalized_math='2')])]))
 ok('cross_page_extraction_pin',scalar('select count(distinct page) from public.math_extraction_regions where run_id=%s',(confirmed,))==2)
 ok('R24_confirmation_not_resolve',scalar('select count(*) from public.math_attempts where id=%s',(ae,))==1 and scalar('select count(*) from public.credit_transactions')==tx)
 ee=request(ae);cle=claim(ee);oe=copy.deepcopy(out);oe['extraction_id']=confirmed;finalize(ee,cle['lease_token'],oe)
 z=hp(ee,'PASS_WITH_NOTES',[finding('EXTRACTION_REGION',dict(extraction_run_id=confirmed,region_id=str(scalar('select id from public.math_extraction_regions where run_id=%s',(confirmed,))))) ]);z['rubric_result']['extraction_fidelity']='OK';submit(z);ok('R08_selected_region_positive')
 z['client_submission_id']=new();z['findings'][0]['target_ref']=dict(extraction_run_id=x['run_id'],region_id=region);deny('R08_original_candidate_denied',lambda:submit(z))
 # FULL_SOLUTION/PROOF share one graph, synthetic reference and criteria.
 rpc('essay_admin_grant',[A,20,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 full=new();fp=new();src=str(scalar('select id from public.math_source_artifacts where problem_id=%s limit 1',(pr,)));sol=new();crit=new()
 c.execute("insert into public.math_subproblems(id,problem_id,leaf_key,display_order,statement,response_format) values(%s,%s,'full',2,'Synthetic proof','PROOF')",(full,pr))
 c.execute("insert into public.math_evaluation_profiles(id,logical_id,version,scope,leaf_id,response_format,rubric_version,required_dimensions,reasoning_required,state) values(%s,%s,1,'LEAF',%s,'PROOF','math-rubric-v1',array['logical_development','justification_completeness','final_conclusion'],true,'ACTIVE')",(fp,new(),full))
 c.execute("insert into public.math_canonical_solutions(id,leaf_id,source_id,logical_id,version,origin,state,body) values(%s,%s,%s,%s,1,'OFFICIAL','ACTIVE','Synthetic reference')",(sol,full,src,new()))
 c.execute("insert into public.math_scoring_criteria(id,leaf_id,source_id,criterion_key,description,rubric_dimensions) values(%s,%s,%s,'proof','Synthetic',array['logical_development'])",(crit,full,src))
 af=attempt(lf=full);ef=request(af);cf=claim(ef);s1,s2,s3,er1,er2,core,h0,h1,h2=[new() for _ in range(9)]
 of=copy.deepcopy(out);of.update(steps=[dict(id=s,position=i,kind='JUSTIFICATION',representation='Synthetic reasoning',status=status,explanation='Synthetic',regions=[]) for i,s,status in [(1,s1,'VALID'),(2,s2,'CALCULATION_ERROR'),(3,s3,'PROPAGATED_ERROR')]],edges=[dict(from_=s1,to=s2),dict(from_=s2,to=s3)],errors=[dict(id=er1,step_id=s2,classification='ROOT',category='SIGN',materiality='MATERIAL_ERROR',explanation='Synthetic root'),dict(id=er2,step_id=s3,classification='PROPAGATED',category='CONCLUSION',materiality='MATERIAL_ERROR',explanation='Synthetic propagated')],causes=[dict(root=er1,consequence=er2)],core=[dict(id=core,position=1,error_id=er1,step_id=s2,title='Synthetic',diagnosis='Synthetic',why='Synthetic',next_action='Synthetic')],hints=[dict(id=hid,core_id=core,level=level,body='Synthetic hint',leakage_class=leak,validated=True) for hid,level,leak in [(h0,0,'CORE_ONLY'),(h1,1,'SAFE_DIRECTION'),(h2,2,'CONCEPT_REVEAL')]],references=[sol],paths=[dict(key='novel',verdict='ALTERNATIVE_VALID_PATH',explanation='Synthetic')],criteria=[dict(criterion_id=crit,verdict='partially_satisfied',explanation='Synthetic')],rubric=dict(logical_development='NEEDS_IMPROVEMENT',justification_completeness='ADEQUATE',final_conclusion='INSUFFICIENT'))
 of['edges']=[{'from':x.pop('from_'),'to':x['to']} for x in of['edges']]
 def assert_unpublished(label):
  ok(label,scalar("select state='PROCESSING' from public.math_evaluations where id=%s",(ef,)) and scalar('select count(*) from public.math_solution_steps where evaluation_id=%s',(ef,))==0 and scalar("select count(*) from public.credit_transactions t join public.math_billing_bindings b on b.billing_decision_id=t.decision_id where b.math_evaluation_id=%s and transaction_type='consume'",(ef,))==0)
 for change,label in [(lambda x:x.update(extraction_id=new()),'extraction_pin'),(lambda x:x['edges'].append({'from':s3,'to':s1}),'cycle'),(lambda x:x['edges'].append({'from':s1,'to':s1}),'self'),(lambda x:x['edges'].append(x['edges'][0]),'duplicate'),(lambda x:x['edges'].append({'from':new(),'to':s1}),'foreign'),(lambda x:x['causes'][0].update(root=er2),'causal'),(lambda x:x['core'][0].update(error_id=new()),'core'),(lambda x:x['rubric'].update(extra='ADEQUATE'),'rubric'),(lambda x:x['criteria'][0].update(criterion_id=new()),'criterion'),(lambda x:x['references'].append(new()),'reference')]:
  v=copy.deepcopy(of);change(v);deny('R19_'+label,lambda v=v:finalize(ef,cf['lease_token'],v));assert_unpublished('R18_rollback_'+label)
 deny('R19_stale_fence',lambda:finalize(ef,new(),of))
 c.execute("update public.math_evaluations set lease_until=clock_timestamp()-interval '1 second' where id=%s",(ef,));deny('R19_expired_lease',lambda:finalize(ef,cf['lease_token'],of));c.execute("update public.math_evaluations set lease_until=clock_timestamp()+interval '5 minutes' where id=%s",(ef,))
 # posting fault injected by a synthetic trigger in disposable DB only.
 c.execute("create function public.math_test_posting_fault() returns trigger language plpgsql as $$begin if new.transaction_type='consume' then raise check_violation;end if;return new;end$$;create trigger math_test_fault before insert on public.credit_transactions for each row execute function public.math_test_posting_fault()")
 deny('R18_posting_fault',lambda:finalize(ef,cf['lease_token'],of));assert_unpublished('R18_posting_rollback');c.execute('drop trigger math_test_fault on public.credit_transactions;drop function public.math_test_posting_fault()')
 finalize(ef,cf['lease_token'],of);ok('graph_complete',scalar('select count(*) from public.math_solution_steps where evaluation_id=%s',(ef,))==3)
 tx=scalar('select count(*) from public.credit_transactions');before=rpc('math_evaluation_detail',[ef]);ok('hint_hidden',len(before['output']['hints'])==1)
 hintkey=new();rpc('math_reveal_hint',[h1,hintkey]);rpc('math_reveal_hint',[h1,hintkey]);ok('hint_delivery_once_no_charge',scalar('select count(*) from public.math_hint_exposures where hint_id=%s',(h1,))==1 and scalar('select count(*) from public.credit_transactions')==tx)
 z=hp(ef,'PASS_WITH_NOTES',[finding('SOLUTION_STEP',dict(step_id=s2)),finding('ROOT_ERROR',dict(error_id=er1)),finding('ALTERNATIVE_PATH',dict(path_kind='REFERENCE',solution_version_id=sol)),finding('ALTERNATIVE_PATH',dict(path_kind='STUDENT',evaluated_path_key='novel'))]);z['rubric_result'].update(step_reasoning='OK',hint_quality='OK');submit(z);ok('R08_all_graph_targets_positive')
 z['client_submission_id']=new();z['findings']=[finding('ROOT_ERROR',dict(error_id=er2))];deny('R08_propagated_not_root',lambda:submit(z))
 ast=attempt('STEP_RETRY',af,ef,s2,lf=full);est=request(ast);cst=claim(est);ost=copy.deepcopy(of)
 # New immutable evaluation graph IDs, unchanged original.
 mapping={v:new() for v in [s1,s2,s3,er1,er2,core,h0,h1,h2]};ost=json.loads(json.dumps(ost))
 for oldid,newid in mapping.items():ost=json.loads(json.dumps(ost).replace(oldid,newid))
 ost['progression']=dict(prior_evaluation_id=ef,target_step_id=s2,downstream='REASSESSED',summary='Synthetic')
 deny('STEP_RETRY_downstream_not_reassessed',lambda:finalize(est,cst['lease_token'],ost));ost['progression']['downstream']='NOT_REASSESSED';finalize(est,cst['lease_token'],ost);ok('STEP_RETRY_lineage',str(scalar('select prior_evaluation_id from public.math_attempts where id=%s',(ast,)))==ef)
 arfull=attempt('FULL_RESOLVE',ast,est,lf=full);erfull=request(arfull);crfull=claim(erfull);orfull=json.loads(json.dumps(ost));orfull['progression']=dict(prior_evaluation_id=est,target_step_id=None,downstream='REASSESSED',summary='Synthetic full resolve')
 for value in mapping.values():orfull=json.loads(json.dumps(orfull).replace(value,new()))
 finalize(erfull,crfull['lease_token'],orfull);ok('FULL_RESOLVE_lineage',str(scalar('select predecessor_id from public.math_attempts where id=%s',(arfull,)))==ast)
 c.execute('delete from public.math_attempts where id=%s',(arfull,))
 # Existing Math graph hard erasure cascades HQ; invalidation preserves reviews.
 beforehq=scalar('select count(*) from public.human_quality_judgments where math_evaluation_id=%s',(ef,));c.execute("update public.math_evaluations set state='INVALIDATED' where id=%s",(ef,));ok('R10_invalidation_history',scalar('select count(*) from public.human_quality_judgments where math_evaluation_id=%s',(ef,))==beforehq)
 # erase dependent retry first; no automatic refund of settled consumption
 consumed=scalar("select count(*) from public.credit_transactions where transaction_type='consume'");c.execute('delete from public.math_attempts where id=%s',(ast,));c.execute('delete from public.math_attempts where id=%s',(af,));ok('R10_math_E1',scalar('select count(*) from public.human_quality_judgments where math_evaluation_id=%s',(ef,))==0);ok('R17_settled_not_refunded',scalar("select count(*) from public.credit_transactions where transaction_type='consume'")==consumed)

 # All response formats; exact hierarchy and NULL-safe common uniqueness.
 exam=str(scalar('select essay_exam_id from public.math_problem_sets where id=(select problem_set_id from public.math_problems where id=%s)',(pr,)))
 for order,fmt in [(3,'SHORT_REASONING'),(4,'FULL_SOLUTION')]:
  lf=new();c.execute("insert into public.math_subproblems(id,problem_id,leaf_key,display_order,statement,response_format,allow_common_rubric) values(%s,%s,%s,%s,'Synthetic',%s,true)",(lf,pr,fmt,order,fmt))
  ids=[]
  for scope,leaf_fk,problem_fk,exam_fk in [('COMMON_MATH_RUBRIC',None,None,None),('EXAM',None,None,exam),('PROBLEM',None,pr,None),('LEAF',lf,None,None)]:
   pid=new();ids.append(pid);c.execute("insert into public.math_evaluation_profiles(id,logical_id,version,scope,leaf_id,problem_id,essay_exam_id,response_format,rubric_version,required_dimensions,reasoning_required,state) values(%s,%s,1,%s,%s,%s,%s,%s,'math-rubric-v1',array['final_conclusion'],false,'ACTIVE')",(pid,new(),scope,leaf_fk,problem_fk,exam_fk,fmt))
   ok('profile_resolution_'+fmt+'_'+scope,str(scalar('select math_private.resolve_profile(%s)',(lf,)))==pid)
  deny('profile_common_NULL_unique_'+fmt,lambda:c.execute("insert into public.math_evaluation_profiles select (jsonb_populate_record(null::public.math_evaluation_profiles,to_jsonb(p)||jsonb_build_object('id',%s::text,'logical_id',%s::text))).* from public.math_evaluation_profiles p where id=%s",(new(),new(),ids[0])))
  for pid in reversed(ids[1:]):c.execute("update public.math_evaluation_profiles set state='SUPERSEDED' where id=%s",(pid,))
  ok('profile_common_fallback_'+fmt,str(scalar('select math_private.resolve_profile(%s)',(lf,)))==ids[0])
  afmt=attempt(lf=lf);efmt=request(afmt);cfmt=claim(efmt);finalize(efmt,cfmt['lease_token'],out);ok('response_format_'+fmt)

 # Concurrent finalize/reconcile is fenced by the common lifecycle/account lock order.
 def finish_race(job):
  mode,eid,token=job
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as cc:
   try:
    with cc.transaction():
     cc.execute("set local statement_timeout='5s';set local role math_evaluation_worker")
     if mode=='final':cc.execute('select public.math_finalize_evaluation(%s,%s,%s)',(eid,token,Jsonb(out)))
     else:cc.execute("select public.math_fail_evaluation(%s,%s,'TIMEOUT')",(eid,token))
    return True
   except psycopg.Error as ex:assert ex.sqlstate=='22023',(mode,ex.sqlstate,str(ex));return False
 arace=attempt();erace=request(arace);crace=claim(erace)
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:rr=list(pool.map(finish_race,[('final',erace,crace['lease_token']),('fail',erace,crace['lease_token'])]))
 ok('R18_finalize_reconcile_concurrency',sum(rr)==1)
 financial=c.execute("select e.state,d.status,(select count(*) from public.credit_transactions where decision_id=d.id and transaction_type='consume'),(select count(*) from public.credit_transactions where decision_id=d.id and transaction_type='release') from public.math_evaluations e join public.math_billing_bindings b on b.math_evaluation_id=e.id join public.essay_billing_decisions d on d.id=b.billing_decision_id where e.id=%s",(erace,)).fetchone()
 ok('R18_winner_atomic',financial in [('COMPLETED','settled',1,0),('FAILED','released',0,1)])

 # lifecycle actual ADR2 predicate, no actual worker or Storage API.
 c.execute('update account_private.dispatch_health set enabled=true');rpc('account_deletion_request',uid=A)
 deny('R20_pending_attempt',lambda:attempt());deny('R20_pending_read',lambda:rpc('math_evaluation_detail',[ev]));deny('R20_pending_finalize',lambda:finalize(ev,cl['lease_token'],out));deny('R20_pending_quality_subject',lambda:rpc('qlm_case_detail',[ev],uid=OP))
 sid=new();rpc('account_reauth_attest',[A,sid],role='account_lifecycle_worker');rpc('account_deletion_cancel',uid=A,extra={'session_id':sid});ok('R20_cancel_restores',rpc('math_evaluation_detail',[ev])['evaluation_id']==ev)
 # Mandatory shared finding parent dispatcher, even via privileged fixture.
 legacy_j=str(scalar('select id from public.human_quality_judgments where evaluation_id is not null limit 1'))
 deny('R09_Math_shape_on_Essay',lambda:c.execute("insert into public.human_quality_findings(judgment_id,issue_category,severity,target_kind,target_ref) values(%s,'OTHER','MINOR','SOLUTION_STEP',%s)",(legacy_j,Jsonb({'step_id':new()}))))
 deny('R09_Essay_shape_on_Math',lambda:c.execute("insert into public.human_quality_findings(judgment_id,issue_category,severity,target_kind,target_ref) values(%s,'STANCE_CHANGE','MINOR','DIMENSION',%s)",(j,Jsonb({'dimension_id':new()}))))
 z=hp();z['supersedes_judgment_id']=legacy_j;deny('R03_cross_domain_parent',lambda:submit(z))
 z=hp(ee);z['supersedes_judgment_id']=j;z['rubric_result']['extraction_fidelity']='OK';deny('R03_cross_evaluation_parent',lambda:submit(z))
 # Both-domain UUID collision remains typed, never inferred from UUID alone.
 essay_same=str(scalar('select evaluation_id from public.human_quality_judgments where id=%s',(legacy_j,)))
 c.execute('begin')
 try:
  c.execute("insert into public.math_evaluations select (jsonb_populate_record(null::public.math_evaluations,to_jsonb(e)||jsonb_build_object('id',%s::text,'idempotency_key',%s::text))).* from public.math_evaluations e where id=%s",(essay_same,new(),ev))
  c.execute('insert into public.math_evaluation_sources select %s,source_id from public.math_evaluation_sources where evaluation_id=%s',(essay_same,ev))
  zz=hp();zz['math_evaluation_id']=essay_same;submit(zz);c.execute('set local role postgres');ok('R02_same_UUID_domains',scalar('select count(*) from public.human_quality_judgments where evaluation_id=%s or math_evaluation_id=%s',(essay_same,essay_same))>=2)
  deny('R02_both_bindings',lambda:c.execute("insert into public.human_quality_judgments select (jsonb_populate_record(null::public.human_quality_judgments,to_jsonb(j)||jsonb_build_object('id',%s::text,'client_submission_id',%s::text,'evaluation_id',%s::text))).* from public.human_quality_judgments j where id=%s",(new(),new(),essay_same,j)))
 finally:c.execute('rollback')
 n1,n2=new(),new()
 deny('R03_multirow_cycle',lambda:c.execute("insert into public.human_quality_judgments select (jsonb_populate_record(null::public.human_quality_judgments,to_jsonb(j)||jsonb_build_object('id',v.id::text,'client_submission_id',gen_random_uuid()::text,'supersedes_judgment_id',v.parent::text))).* from public.human_quality_judgments j cross join (values(%s::uuid,%s::uuid),(%s::uuid,%s::uuid)) v(id,parent) where j.id=%s",(n1,n2,n2,n1,j)))
 # Fresh decision/evaluation mismatch rolls back as a unit.
 def mismatched_binding():
  with c.transaction():
   eid,key,did=new(),new(),new();otheracc=scalar('select id from public.credit_accounts where user_id=%s',(B,))
   c.execute("insert into public.math_evaluations select (jsonb_populate_record(null::public.math_evaluations,to_jsonb(e)||jsonb_build_object('id',%s::text,'idempotency_key',%s::text,'state','REQUESTED','completed_at',null,'output_sha256',null,'result',null))).* from public.math_evaluations e where id=%s",(eid,key,ev))
   c.execute("insert into public.essay_billing_decisions(id,account_id,idempotency_key,policy_key,policy_version,reason,credits_required,status) values(%s,%s,%s,'essay_cycle','v2','paid_cycle',1,'authorized')",(did,otheracc,key))
   c.execute('insert into public.math_billing_bindings values(%s,%s,%s)',(eid,did,otheracc))
 beforedec=scalar('select count(*) from public.essay_billing_decisions');deny('R13_account_mismatch',mismatched_binding);ok('R13_request_unit_rollback',scalar('select count(*) from public.essay_billing_decisions')==beforedec)
 eid,key,did=new(),new(),new();c.execute("insert into public.essay_billing_decisions(id,account_id,idempotency_key,policy_key,policy_version,reason,credits_required,status) values(%s,%s,%s,'essay_cycle','v2','paid_cycle',1,'authorized')",(did,acc,key))
 def detached_binding():
  with c.transaction():
   c.execute("insert into public.math_evaluations select (jsonb_populate_record(null::public.math_evaluations,to_jsonb(e)||jsonb_build_object('id',%s::text,'idempotency_key',%s::text,'state','REQUESTED','completed_at',null,'output_sha256',null,'result',null))).* from public.math_evaluations e where id=%s",(eid,key,ev))
   c.execute('insert into public.math_billing_bindings values(%s,%s,%s)',(eid,did,acc))
 deny('R13_detached_decision_reuse',detached_binding)

 # E2 survivor: a reviewer without owned Math/Essay work is deleted; no identity snapshot.
 reviewer=new();c.execute('insert into auth.users(id) values(%s)',(reviewer,));c.execute('insert into public.profiles(id) values(%s)',(reviewer,));c.execute('insert into public.quality_operators(user_id) values(%s)',(reviewer,))
 jr=submit(hp(disp='PASS_WITH_NOTES',findings=[finding('OVERALL',None)]),reviewer)['judgment_id'];c.execute('delete from auth.users where id=%s',(reviewer,));ok('R10_Math_E2',scalar('select reviewer_user_id is null from public.human_quality_judgments where id=%s',(jr,)) and scalar('select count(*) from public.human_quality_findings where judgment_id=%s',(jr,))==1)
 history=rpc('qlm_list_human_judgments',[ev,100,None,None],uid=OP);ok('R11_deleted_reviewer',next(x for x in history['judgments'] if x['id']==jr)['reviewer_state']=='DELETED_OR_UNAVAILABLE')
 ok('R24_no_direct_PII',not set(rpc('qlm_case_detail',[ev],uid=OP)).intersection({'student_id','user_id','email','phone','name'}))
 # Combined student/reviewer: own Math QA erased, reviews of others retained without identity.
 both=new();c.execute('insert into auth.users(id) values(%s)',(both,));c.execute('insert into public.profiles(id) values(%s)',(both,));c.execute('insert into public.quality_operators(user_id) values(%s)',(both,))
 rpc('essay_admin_grant',[both,3,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 ab=attempt(user=both);eb=str(rpc('math_request_evaluation',[ab,new()],uid=both));cb=claim(eb);finalize(eb,cb['lease_token'],out)
 own_review=submit(hp(eb))['judgment_id'];surviving=submit(hp(disp='PASS_WITH_NOTES',findings=[finding('OVERALL',None)]),both)['judgment_id']
 c.execute('delete from public.math_attempts where id=%s',(ab,));c.execute('delete from auth.users where id=%s',(both,))
 ok('R10_combined_E1_E2',scalar('select count(*) from public.human_quality_judgments where id=%s',(own_review,))==0 and scalar('select reviewer_user_id is null from public.human_quality_judgments where id=%s',(surviving,)) and scalar('select count(*) from public.human_quality_findings where judgment_id=%s',(surviving,))==1)
 # Personal bytes inventory must survive failures. There is no Storage API deployed by this migration.
 deny('R22_Auth_last_before_Math_cleanup',lambda:c.execute('delete from auth.users where id=%s',(A,)),states=('23503','23514'))
 c.execute("update public.math_attempt_artifacts set storage_state='ERASURE_PENDING' where id=%s",(ar,));deny('R21_timeout_inventory_retained',lambda:c.execute('delete from public.math_attempts where id=%s',(ae,)))
 c.execute("update public.math_attempt_artifacts set storage_state='ABSENT_VERIFIED',absence_verified_at=clock_timestamp() where id=%s",(ar,));c.execute('delete from public.math_attempts where id=%s',(ae,));ok('R22_bytes_then_metadata',scalar('select count(*) from public.math_attempt_artifacts where id=%s',(ar,))==0 and scalar('select count(*) from public.human_quality_judgments where math_evaluation_id=%s',(ee,))==0)
 # Actual mixed lifecycle/Math/HQ/Essay calls, bounded statement timeout.
 math_retry_key=str(scalar('select idempotency_key from public.math_evaluations where id=%s',(ev,)))
 essay_retry=c.execute("select attempt_id,idempotency_key from public.essay_evaluations where status='completed' order by requested_at,id limit 1").fetchone()
 def mixed(index):
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as cc:
   try:
    with cc.transaction():
     cc.execute("set local statement_timeout='5s';set local role authenticated")
     uid=OP if index%4==0 else A
     cc.execute("select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claims',%s,true)",(uid,json.dumps({'sub':uid,'role':'authenticated','exp':int(time.time())+600})))
     if index%4==0:cc.execute('select public.qlm_case_detail(%s)',(ev,))
     elif index%4==1:cc.execute('select public.math_request_evaluation(%s,%s)',(at,math_retry_key))
     elif index%4==2:cc.execute('select public.account_deletion_request()')
     else:cc.execute("select public.essay_request_evaluation(%s,%s,'essay-v1.3')",essay_retry)
    return 'ALLOW'
   except psycopg.Error as ex:
    assert ex.sqlstate in ('42501',),(index,ex.sqlstate,str(ex));return 'DENY'
 with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:results=list(pool.map(mixed,range(24)))
 ok('R20_mixed_concurrency_no_deadlock',len(results)==24)
 sid=new();rpc('account_reauth_attest',[A,sid],role='account_lifecycle_worker');rpc('account_deletion_cancel',uid=A,extra={'session_id':sid})

 return checks

if __name__=='__main__':
 h.verify_hqp=verify
 h.main(bootstrap_user='supabase_admin')
