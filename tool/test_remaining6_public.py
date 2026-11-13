"""Exact KAU2 publication/reversal in disposable PG17, real RPCs, synthetic results; no Provider."""
import copy,hashlib,inspect,json,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import test_math_persistence as m
R=Path(__file__).resolve().parents[1]
PUB=R/'supabase/candidates/remaining6_20261113'
PRIVATE=R/'.local/remaining6-20261113'
SOURCE=R/'.local/remaining6-20261113'
FRESH=Path('/private/tmp/remaining6-20261113')
from psycopg.types.json import Jsonb
import prepare_remaining6_public as prep

def content_case(c,rpc,new,scalar,A,B):
 c.execute('alter table public.math_subproblems add column essay_question_id uuid references public.essay_questions(id)')
 c.execute("insert into public.universities(id,slug,name) values('881976e7-8e3d-53e3-8bd8-4ebe5d3a0445','kau','한국항공대학교')")
 for item in json.loads((FRESH/'registry.json').read_text()):
  for table,key in [('essay_exams','exam'),('essay_questions','question')]:
   row=item[key]
   c.execute('insert into public.'+table+' select (jsonb_populate_record(null::public.'+table+',%s)).* on conflict(id) do nothing',(Jsonb(row),))
 # Represent every existing allowlisted identity with synthetic content, never invoke a Provider.
 existing=json.loads((FRESH/'math-before.json').read_text());assert len(existing)==451
 uid=new();c.execute("insert into public.universities(id,slug,name) values(%s,'old-math-fixture','Synthetic old university')",(uid,))
 for old in existing:
  eid=old['essay_exam_id'];qid=old['essay_question_id'];leaf=old['leaf_id'];ps=new();pr=new()
  c.execute("insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind,is_active) values(%s,%s,2026,%s,'Synthetic old exam','admission',false) on conflict(id) do nothing",(eid,uid,'fixture-'+eid))
  c.execute("insert into public.essay_questions(id,essay_exam_id,question_key,label,display_order,metadata_version,is_published) values(%s,%s,%s,'Synthetic old question',0,'fixture-v1',true) on conflict(id) do nothing",(qid,eid,'fixture-'+qid))
  c.execute("insert into public.math_problem_sets(id,essay_exam_id,logical_id,version,label,state) values(%s,%s,%s,1,'Synthetic old math','ACTIVE')",(ps,eid,ps))
  c.execute("insert into public.math_problems(id,problem_set_id,logical_id,version,display_order,statement,state) values(%s,%s,%s,1,0,'Synthetic old problem','ACTIVE')",(pr,ps,pr))
  c.execute("insert into public.math_subproblems(id,problem_id,leaf_key,display_order,statement,response_format,essay_question_id) values(%s,%s,'q1',0,'Synthetic old leaf','FULL_SOLUTION',%s)",(leaf,pr,None if leaf=='3bab07d3-c047-53c2-89ad-9fa20ec7b3f3' else qid))
 c.execute('''create table math_private.task20_hanyang_source_pages(question_id uuid primary key references public.essay_questions(id),exam_id uuid not null references public.essay_exams(id),manifest jsonb not null,images jsonb not null check(jsonb_array_length(images) between 1 and 24),content_sha256 text not null);
 alter table math_private.task20_hanyang_source_pages enable row level security;
 revoke all on math_private.task20_hanyang_source_pages from public,anon,authenticated;''')
 c.execute((R/'tool/fixtures/kau-connection-worker-20261111.sql').read_text())
 c.execute('revoke all on function math_private.hanyang_worker_references(jsonb) from public,anon,authenticated')
 c.execute('create table math_private.runtime_control(singleton boolean primary key, evaluations_enabled boolean)')
 c.execute('insert into math_private.runtime_control values(true,true)')
 # Match current production wrappers, including the existing coaching disclosure gate.
 c.execute("create table math_private.coaching_disclosures(evaluation_id uuid primary key references public.math_evaluations(id),student_id uuid not null,client_key uuid not null,delivered_at timestamptz not null default clock_timestamp()); alter table math_private.coaching_disclosures owner to math_executor; alter table math_private.coaching_disclosures enable row level security; revoke all on math_private.coaching_disclosures from public,anon,authenticated")
 c.execute((R/'supabase/candidates/task16g_learning_loop/session_core.sql').read_text().split('-- Called ONLY')[0])
 live=json.loads((FRESH/'functions-before.json').read_text())
 session_function=next(f for f in live if f['proname']=='session_reevaluation');c.execute(session_function['definition'])
 c.execute('revoke all on function math_private.session_reevaluation(uuid,uuid) from public;grant execute on function math_private.session_reevaluation(uuid,uuid) to math_executor')
 live_names={'math_submit_attempt','math_request_evaluation','math_claim_evaluation','math_finalize_evaluation','math_evaluation_detail','math_learning','math_evaluation_detail_task16f_legacy','math_learning_task16f_legacy'}
 runtime=[f for f in live if f['nspname']=='public' and f['proname'] in live_names];assert len(runtime)==8
 for f in runtime:c.execute(f['definition'])
 c.execute('revoke all on function public.math_evaluation_detail_task16f_legacy(uuid),public.math_learning_task16f_legacy(jsonb) from public; grant execute on function public.math_evaluation_detail_task16f_legacy(uuid),public.math_learning_task16f_legacy(jsonb) to math_executor')
 for f in runtime:
  signature='public.'+f['proname']+('('+('uuid, uuid' if f['proname']=='math_request_evaluation' else 'uuid, uuid, jsonb' if f['proname']=='math_finalize_evaluation' else 'jsonb' if f['proname'] in ['math_submit_attempt','math_learning','math_learning_task16f_legacy'] else 'uuid')+')')
  assert scalar('select md5(pg_get_functiondef(%s::regprocedure))',(signature,))==f['md5'],f['proname']
 records=json.loads((PUB/'math-functions-before.json').read_text())
 for r in records:c.execute(r['before'])
 c.execute('create trigger public_scope_admission before insert on public.math_evaluations for each row execute function math_private.evaluation_admission()')
 prior_catalog=scalar('select math_private.release_catalog(null)');assert len(prior_catalog)==451
 old_registry=scalar("select jsonb_build_object('exams',(select jsonb_agg(to_jsonb(e) order by id) from public.essay_exams e),'questions',(select jsonb_agg(to_jsonb(q) order by id) from public.essay_questions q))")
 def read_checks(name):
  out=[];body=(PUB/name).read_text().replace('begin read only;','').replace('commit;','');cursor=c.execute(body)
  while True:
   if cursor.description:
    for label,passed in cursor.fetchall():assert passed,label;out.append(label)
   if not cursor.nextset():break
  return out
 c.execute('begin isolation level repeatable read')
 preflight=read_checks('math-preflight.sql');assert len(preflight)==16
 packages=[json.loads(p.read_text()) for p in sorted(SOURCE.glob('*.package.private.json'))]
 assert len(packages)==2
 c.execute(prep.transaction_sql(PRIVATE/'math-apply-public.private.sql',prep.sha(PRIVATE/'math-apply-public.private.sql')))
 checks=read_checks('math-verify.sql');assert len(checks)==16
 assert len(scalar('select math_private.release_catalog(null)'))==453
 c.execute('commit')
 assert scalar("select count(*) from public.essay_questions q join public.essay_exams e on e.id=q.essay_exam_id where e.university_id='881976e7-8e3d-53e3-8bd8-4ebe5d3a0445' and q.is_published")==0
 for old in old_registry['exams']:assert scalar('select to_jsonb(e) from public.essay_exams e where id=%s',(old['id'],))==old
 for old in old_registry['questions']:assert scalar('select to_jsonb(q) from public.essay_questions q where id=%s',(old['id'],))==old
 for role in ['anon','authenticated','service_role']:
  for table in [x[0] for x in c.execute("select tablename from pg_tables where schemaname='public' and tablename like 'math_%'")]:
   for priv in ['SELECT','INSERT','UPDATE','DELETE']:assert not scalar('select has_table_privilege(%s,%s,%s)',(role,'public.'+table,priv))
 questions=[]
 for p in packages:
     leaf=p['ids']['leaf']
     rpc('essay_admin_grant',[A,1,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
     payload=dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic contract answer, not a model evaluation')
     attempt=str(rpc('math_submit_attempt',[payload]));assert str(rpc('math_submit_attempt',[payload]))==attempt
     key=new();ev=str(rpc('math_request_evaluation',[attempt,key]));assert str(rpc('math_request_evaluation',[attempt,key]))==ev
     cl=rpc('math_claim_evaluation',[ev],role='math_evaluation_worker')
     out=dict(contract_version='math-eval-v1',extraction_id=None,
              steps=[dict(id=new(),position=1,kind='COMPUTATION',representation='Synthetic',status='VALID',explanation='Contract only',regions=[])],
              edges=[],errors=[],causes=[],core=[],hints=[],references=[],paths=[],
              criteria=[dict(criterion_id=x['id'],verdict='satisfied',explanation='Synthetic') for x in p['existing_schema_rows']['math_scoring_criteria']],
              rubric={d:'ADEQUATE' for d in p['existing_schema_rows']['math_evaluation_profiles'][0]['required_dimensions']},
              overall=dict(status='ANSWER_CORRECT_AND_REASONING_SUFFICIENT',answer_status='CORRECT',coverage='ATTEMPTED',explanation='Synthetic only'),
              provenance=dict(provider='synthetic',model='mock',model_version='1',prompt_version='1'),progression=None,generated_solution=None)
     rpc('math_finalize_evaluation',[ev,cl['lease_token'],out],role='math_evaluation_worker')
     assert rpc('math_evaluation_detail',[ev])['coaching_required'] is True
     # Synthetic fixture disclosure models the pre-existing reveal gate; no billing-policy change.
     c.execute('insert into math_private.coaching_disclosures(evaluation_id,student_id,client_key) values(%s,%s,%s)',(ev,A,new()))
     assert rpc('math_evaluation_detail',[ev])['output']['contract_version']=='math-eval-v1'
     try:
         rpc('math_evaluation_detail',[ev],uid=B)
         raise AssertionError('Foreign result allowed')
     except m.psycopg.Error:pass
     # Existing learning envelope: exact selected leaf and prior evaluation survive.
     def learning(action,value):
         return rpc('math_learning',[dict(dto_version='math-learning-v1',action=action,payload=value)])['result']
     rewrite_payload=dict(client_submission_id=new(),leaf_id=leaf,kind='FULL_RESOLVE',predecessor_id=attempt,
                          prior_evaluation_id=ev,input_kind='TYPED',typed_answer='Synthetic rewritten work')
     revised=str(learning('create_resolve_attempt',rewrite_payload)['attempt_id'])
     assert str(learning('create_resolve_attempt',rewrite_payload)['attempt_id'])==revised
     assert scalar('select lineage_id from public.math_attempts where id=%s',(revised,))==scalar('select lineage_id from public.math_attempts where id=%s',(attempt,))
     revision_key=new();req=dict(attempt_id=revised,client_submission_id=revision_key)
     revision=str(learning('request_reevaluation',req)['evaluation_id'])
     assert str(learning('request_reevaluation',req)['evaluation_id'])==revision
     claimed=rpc('math_claim_evaluation',[revision],role='math_evaluation_worker')
     revision_out=copy.deepcopy(out)
     revision_out['steps'][0]['id']=new()
     revision_out['progression']=dict(prior_evaluation_id=ev,target_step_id=None,downstream=None,
         summary='Synthetic linkage only',delta=[dict(kind='NO_MATERIAL_CHANGE',explanation='Mock contract')])
     rpc('math_finalize_evaluation',[revision,claimed['lease_token'],revision_out],role='math_evaluation_worker')
     assert rpc('math_evaluation_detail',[revision])['coaching_required'] is True
     c.execute('insert into math_private.coaching_disclosures(evaluation_id,student_id,client_key) values(%s,%s,%s)',(revision,A,new()))
     assert rpc('math_evaluation_detail',[revision])['output']['progression']['prior_evaluation_id']==ev
     questions.append(dict(question_id=p['essay_question_id'],checks=['submission_idempotent','evaluation_idempotent','criteria_finalize','coaching_required_before_synthetic_disclosure','result_read','foreign_result_denied','rewrite_idempotent','lineage_preserved','reevaluation_idempotent','rewritten_coaching_required_before_synthetic_disclosure','rewritten_result_read'],status='PASS'))

 history=lambda:{t:scalar("select md5(coalesce(jsonb_agg(to_jsonb(x) order by id)::text,'[]')) from public."+t+" x") for t in ['essay_attempts','essay_evaluations','credit_transactions','math_attempts','math_evaluations']}
 before=history();c.execute((PUB/'math-rollback-admission.sql').read_text())
 assert history()==before
 assert scalar('select math_private.release_catalog(null)')==prior_catalog
 assert rpc('math_evaluation_detail',[revision])['output']['contract_version']=='math-eval-v1'
 rpc('essay_admin_grant',[A,1,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 p=packages[0];at=rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=p['ids']['leaf'],kind='INITIAL',input_kind='TYPED',typed_answer='Rollback admission probe')])
 try:rpc('math_request_evaluation',[at,new()]);raise AssertionError('Rollback admitted new evaluation')
 except m.psycopg.Error as error:assert 'MATH_QUESTION_NOT_RELEASED' in str(error)
 for r in records:assert scalar('select md5(pg_get_functiondef(%s::regprocedure))',(r['signature'],))==r['before_md5']
 assert len(scalar('select math_private.release_catalog(null)'))==451
 assert scalar("select count(*) from public.essay_questions q join public.essay_exams e on e.id=q.essay_exam_id where e.university_id='881976e7-8e3d-53e3-8bd8-4ebe5d3a0445' and q.is_published")==0
 report=dict(scope='isolated PG17; existing 451 synthetic catalog fixtures + exact KAU2 official packages; actual existing submit/result/rewrite RPCs with synthetic outputs',math_preflight=preflight,checks=checks,questions=questions,rollback={'old_catalog_exact':True,'histories_exact':True,'new_evaluation_denied':True,'existing_result_read':True,'function_hashes_exact':True,'new_registry_closed':True},existing_registry_exact=True,combined_registry_math_transaction=True,table_acls_unchanged=True,live_runtime_function_hashes={f['proname']:f['md5'] for f in runtime},coaching_disclosure='existing guard verified before synthetic fixture disclosure; actual paid reveal NOT TESTED',provider_calls=0,production_writes=0,browser_ui='NOT TESTED',device_ui='NOT TESTED',ai_quality='NOT TESTED')
 (PUB/'math-isolated-results.json').write_text(json.dumps(report,indent=2)+'\n');print('KAU_2_PUBLIC_FLOW_ROLLBACK_PASS',len(checks),sum(len(q['checks']) for q in questions))

def main():
 source=inspect.getsource(m.verify).split(" print('MATH_FULL_NON_SUPERUSER_INSTALL_PASS')")[0]
 for name in ['20261002000200_math_runtime_surface.sql','20261002000300_math_learning_runtime.sql']:source+="\n o.execute_as_production(c,admin,(R/'supabase/migrations/"+name+"').read_text())\n"
 source+='\n content_case(c,rpc,new,scalar,A,B)\n';ns=dict(m.__dict__);ns['content_case']=content_case;exec(source,ns);m.h.verify_hqp=ns['verify'];m.h.main(bootstrap_user='supabase_admin')
if __name__=='__main__':main()
