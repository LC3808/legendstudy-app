"""Owner-only admission proposal rehearsal: disposable PG17, no remote/Provider calls."""
import os,inspect,json,hashlib
os.environ['NATURAL_PREFLIGHT_SCOPE']='kau'
import test_natural_preflight as stage
from psycopg import sql
R=stage.R; B=R/'supabase/candidates/kau_owner_review_20261112'; P=R/'.local/kau-owner-review-20261112'

def review_case(c,rpc,new,scalar,A,B_user,old,packages):
 checks=[]
 def ok(name,value=True):
  assert value,name
  checks.append(name);print(name,'PASS',flush=True)
 def deny(name,fn,expected):
  try:fn()
  except stage.m.psycopg.Error as e:
   c.execute('rollback');assert expected in str(e),(name,str(e));ok(name);return
  raise AssertionError(name+' unexpectedly permitted')
 c.execute((stage.PRIVATE/'apply-draft.private.sql').read_text())
 owner=json.loads((P/'owner.private.json').read_text())['owner_subject']
 c.execute('insert into auth.users(id) values(%s)',(owner,));c.execute('insert into public.profiles(id) values(%s)',(owner,))
 for f in json.loads((B/'production-runtime-functions.json').read_text()):
  if f['name'] in ('math_request_evaluation','math_claim_evaluation','math_claim_extraction'):c.execute(f['definition'])
 before=json.loads((B/'function-diff.json').read_text())
 signatures=[v['signature'] for v in before.values()]
 def security():return [scalar('select jsonb_build_array(proowner,proacl::text) from pg_proc where oid=%s::regprocedure',(s,)) for s in signatures]
 def data():return {t:scalar("select md5(coalesce(jsonb_agg(to_jsonb(x) order by to_jsonb(x)::text)::text,'')) from "+t+' x') for t in ['public.essay_questions','public.essay_exams','public.math_problem_sets','public.math_problems','public.math_subproblems','public.math_source_artifacts','public.math_evaluation_profiles','public.math_scoring_criteria','public.math_canonical_solutions','public.math_solution_steps','math_private.task20_hanyang_source_pages','public.credit_transactions']}
 acl=security();baseline=data();catalog=rpc('math_catalog',[50],uid=owner)
 install=(P/'install-closed.private.sql').read_text();c.execute(install)
 ok('closed_install_preserves_content_registry_credit',data()==baseline)
 ok('four_function_owners_acl_preserved',security()==acl)
 ok('closed_catalog_unchanged',rpc('math_catalog',[50],uid=owner)==catalog)
 ok('closed_by_default',scalar('select enabled from math_private.kau_review_control') is False)
 for role in ['anon','authenticated','service_role']:
  ok(role+'_no_control_table_access',not scalar("select has_table_privilege(%s,'math_private.kau_review_control','SELECT')",(role,)))
  ok(role+'_no_direct_helper_execute',not scalar("select has_function_privilege(%s,'math_private.kau_review_allowed(uuid,uuid)','EXECUTE')",(role,)))
 def submit(p,uid=owner,key=None):return str(rpc('math_submit_attempt',[dict(client_submission_id=key or new(),leaf_id=p['ids']['leaf'],kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic contract only')],uid=uid))
 for p in packages:deny(p['essay_question_id']+'_closed_submit',lambda p=p:submit(p),'KAU_REVIEW_DENIED')
 def content(state):
  for p in packages:
   for t in ['math_problem_sets','math_problems','math_evaluation_profiles','math_canonical_solutions']:
    c.execute(sql.SQL('update public.{} set state=%s where id=%s').format(sql.Identifier(t)),(state,p['existing_schema_rows'][t][0]['id']))
 def enable():c.execute("update math_private.kau_review_control set enabled=true,valid_until=clock_timestamp()+interval '1 hour'")
 # Activation here is disposable fixture setup only. No activation SQL is distributed.
 content('ACTIVE');enable()
 ok('owner_catalog_exactly_seven_added',len(rpc('math_catalog',[50],uid=owner))==len(catalog)+7)
 ok('other_catalog_unchanged',rpc('math_catalog',[50],uid=A)==catalog)
 deny('anonymous_catalog_denied',lambda:rpc('math_catalog',[50],uid=None,role='anon'),'insufficient_privilege')
 attempts=[]
 for p in packages:
  attempts.append(submit(p));ok(p['essay_question_id']+'_owner_submit')
  deny(p['essay_question_id']+'_other_submit',lambda p=p:submit(p,A),'KAU_REVIEW_DENIED')
 ok('hold_five_absent',all(scalar('select count(*) from public.math_subproblems where essay_question_id=%s',(q['registry_id'],))==0 for q in json.loads((stage.BASE/'question-review.json').read_text())['questions'] if q['university']=='한국항공대학교' and q['state']=='HOLD'))
 rpc('essay_admin_grant',[owner,10,'admin_grant',new(),'test_account',None],uid=B_user,role='essay_finance')
 p=packages[0];at=attempts[0];ev=str(rpc('math_request_evaluation',[at,new()],uid=owner))
 c.execute((B/'close.sql').read_text())
 deny('queued_evaluation_claim_after_close_denied',lambda:rpc('math_claim_evaluation',[ev],role='math_evaluation_worker'),'KAU_REVIEW_DENIED')
 ok('denied_claim_stays_requested',scalar('select state from public.math_evaluations where id=%s',(ev,))=='REQUESTED')
 deny('extraction_claim_after_close_denied',lambda:rpc('math_claim_extraction',[at],role='math_extraction_worker'),'KAU_REVIEW_DENIED')
 deny('new_evaluation_after_close_denied',lambda:rpc('math_request_evaluation',[attempts[1],new()],uid=owner),'KAU_REVIEW_DENIED')
 enable();claim=rpc('math_claim_evaluation',[ev],role='math_evaluation_worker');ok('enabled_owner_worker_claim',bool(claim['lease_token']))
 out=dict(contract_version='math-eval-v1',extraction_id=None,steps=[dict(id=new(),position=1,kind='COMPUTATION',representation='Synthetic',status='VALID',explanation='Contract only',regions=[])],edges=[],errors=[],causes=[],core=[],hints=[],references=[],paths=[],criteria=[dict(criterion_id=x['id'],verdict='satisfied',explanation='Synthetic') for x in p['existing_schema_rows']['math_scoring_criteria']],rubric={d:'ADEQUATE' for d in p['existing_schema_rows']['math_evaluation_profiles'][0]['required_dimensions']},overall=dict(status='ANSWER_CORRECT_AND_REASONING_SUFFICIENT',answer_status='CORRECT',coverage='ATTEMPTED',explanation='Synthetic only'),provenance=dict(provider='synthetic',model='mock',model_version='1',prompt_version='1'),progression=None,generated_solution=None)
 c.execute((B/'close.sql').read_text())
 rpc('math_finalize_evaluation',[ev,claim['lease_token'],out],role='math_evaluation_worker')
 result_row=scalar('select to_jsonb(e) from public.math_evaluations e where id=%s',(ev,))
 detail=rpc('math_evaluation_detail',[ev],uid=owner);ok('admitted_claim_can_finish_after_close',bool(detail))
 deny('foreign_result_denied',lambda:rpc('math_evaluation_detail',[ev],uid=A),'no_data_found')
 ok('closed_owner_result_still_readable',rpc('math_evaluation_detail',[ev],uid=owner)==detail)
 enable();key=new();saved=submit(p,key=key);c.execute((B/'close.sql').read_text());ok('existing_idempotent_replay_unchanged',submit(p,key=key)==saved)
 enable();c.execute("update math_private.kau_review_control set valid_until=clock_timestamp()-interval '1 second'")
 deny('expired_owner_submit_denied',lambda:submit(p),'KAU_REVIEW_DENIED')
 enable();c.execute('update account_private.dispatch_health set enabled=true');rpc('account_deletion_request',uid=owner)
 deny('pending_deletion_denied',lambda:submit(p),'ACCOUNT')
 ok('pending_deletion_gate_false',not scalar('select math_private.kau_review_allowed(%s,%s)',(owner,p['ids']['leaf'])))
 sid=new();rpc('account_reauth_attest',[owner,sid],role='account_lifecycle_worker');rpc('account_deletion_cancel',uid=owner,extra={'session_id':sid})
 deny('restore_refuses_active_content',lambda:c.execute((B/'restore-functions.sql').read_text()),'REVIEW_REQUIRES_SEVEN_DRAFT')
 content('DRAFT');c.execute((B/'restore-functions.sql').read_text())
 ok('restore_exact_four_definitions',all(scalar('select pg_get_functiondef(%s::regprocedure)',(v['signature'],))==v['before'] for v in before.values()))
 ok('restore_preserves_acl',security()==acl)
 ok('restore_keeps_control_disabled',scalar('select enabled from math_private.kau_review_control') is False)
 ok('restore_keeps_result',scalar('select to_jsonb(e) from public.math_evaluations e where id=%s',(ev,))==result_row and rpc('math_evaluation_detail',[ev],uid=owner)['output']==detail['output'])
 ok('restore_catalog_unchanged',rpc('math_catalog',[50],uid=owner)==catalog)
 report=dict(status='PASS',count=len(checks),checks=checks,scope='Disposable PG17 synthetic subjects; exact candidate SQL; live admission definitions plus existing local persistence/finalizer fixture',production_writes=0,provider_calls=0,web_app_e2e='NOT TESTED',install_sha256=hashlib.sha256(install.encode()).hexdigest())
 (B/'isolated-results.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

def main():
 source=inspect.getsource(stage.content_case).split(' checks=[]')[0]+'\n review_case(c,rpc,new,scalar,A,B,old,packages)\n'
 ns=dict(stage.__dict__);ns['review_case']=review_case;exec(source,ns);stage.content_case=ns['content_case'];stage.main()
if __name__=='__main__':main()
