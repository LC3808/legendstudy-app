"""Exact Stage-1 SQL rehearsal in disposable Unix-only PG17; no remote DSN/Provider."""
import copy,hashlib,inspect,json,os,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import test_math_persistence as m
from psycopg import sql
from psycopg.types.json import Jsonb
from prepare_natural_preflight import OUT,PRIVATE,BASE,R
scope_mode='kyunghee'
assert scope_mode in ('all','kau','konkuk','kyunghee')
if scope_mode=='kau':
 OUT=R/'supabase/candidates/natural_expansion_20261111/kau-production-preflight'
 PRIVATE=R/'.local/kau-production-preflight-20261112'
if scope_mode=='kyunghee':
 OUT=R/'supabase/candidates/natural_tech_ready_20261112/kyunghee-production-preflight'
 PRIVATE=R/'.local/kyunghee-production-preflight-20261112'
from essay_lab.four_university_connection import ORDER
from essay_lab.task20_priority_packages import registration_sql


def content_case(c,rpc,new,scalar,A,B):
 review=json.loads((BASE/'question-review.json').read_text())['questions']
 packages=[json.loads(p.read_text()) for p in sorted(PRIVATE.glob('*.package.private.json'))]
 expected=json.loads((OUT/'scope.json').read_text())['counts']['new_draft']
 assert len(packages)==expected
 c.execute('alter table public.math_subproblems add column essay_question_id uuid references public.essay_questions(id)')
 for uid in sorted({q['university_id'] for q in review}):
  c.execute("insert into public.universities(id,slug,name,is_active) values(%s,%s,'Synthetic university',false)",(uid,'fixture-'+uid))
 for eid in sorted({q['exam_id'] for q in review}):
  q=next(q for q in review if q['exam_id']==eid)
  c.execute("insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind,verification_status,provenance,is_active) values(%s,%s,%s,%s,'Synthetic exam','admission','review','official',false)",(eid,q['university_id'],q['admission_year'],'fixture-'+eid))
 for q in review:
  c.execute('insert into public.essay_questions(id,essay_exam_id,question_key,label,display_order,is_published,metadata_version) values(%s,%s,%s,%s,%s,false,1)',(q['registry_id'],q['exam_id'],q['registry_key'],q['question_label'],q['display_order']))
 # Seven existing binding identities, including NULL legacy FK. Only synthetic content.
 old=[]
 for q in [q for q in review if 'PRESERVED' in q['state']]:
  p=copy.deepcopy(packages[0]);mapping={r['id']:new() for rows in p['existing_schema_rows'].values() for r in rows}
  mapping[p['ids']['leaf']]=q['operating_math_bindings'][0]['leaf_id']
  text=json.dumps(p)
  for a,b in mapping.items():text=text.replace(a,b)
  text=text.replace(p['essay_question_id'],q['registry_id']).replace(p['exam_id'],q['exam_id']);p=json.loads(text)
  p['existing_schema_rows']={t:p['existing_schema_rows'][t] for t in ORDER}
  for rows in p['existing_schema_rows'].values():
   for row in rows:
    if 'state' in row:row['state']='ACTIVE'
  if q['operating_math_bindings'][0].get('legacy_alias'):p['existing_schema_rows']['math_subproblems'][0]['essay_question_id']=None
  c.execute(registration_sql([p]));old.append(p)
 c.execute('''create table math_private.task20_hanyang_source_pages(question_id uuid primary key references public.essay_questions(id),exam_id uuid not null references public.essay_exams(id),manifest jsonb not null,images jsonb not null check(jsonb_array_length(images) between 1 and 24),content_sha256 text not null);
 alter table math_private.task20_hanyang_source_pages enable row level security;
 revoke all on math_private.task20_hanyang_source_pages from public,anon,authenticated;''')
 c.execute((R/'tool/fixtures/kau-connection-worker-20261111.sql').read_text())
 c.execute('revoke all on function math_private.hanyang_worker_references(jsonb) from public,anon,authenticated')
 for f in json.loads((R/'supabase/candidates/natural_expansion_20261111/production-preflight/production-functions.json').read_text()):c.execute(f['definition'])
 c.execute((R/'.local/kau-production-preflight-20261112/apply-draft.private.sql').read_text())

 PUB=R/'supabase/candidates/kyunghee_public_20261112'
 records=json.loads((PUB/'functions-before.json').read_text())
 c.execute('create table math_private.runtime_control(singleton boolean primary key, evaluations_enabled boolean)')
 c.execute('insert into math_private.runtime_control values(true,true)')
 # Preserve the previous actual Konkuk public scope in this disposable database.
 for r in json.loads((R/'supabase/candidates/konkuk_public_20261112/functions-before.json').read_text()):c.execute(r['before'])
 c.execute((R/'.local/konkuk-production-preflight-20261112/apply-draft.private.sql').read_text())
 c.execute((R/'.local/konkuk-production-preflight-20261112/activate-public.private.sql').read_text())
 for f in json.loads((OUT/'production-functions.json').read_text()):c.execute(f['definition'])
 for r in records:c.execute(r['before'])
 c.execute('create trigger public_scope_admission before insert on public.math_evaluations for each row execute function math_private.evaluation_admission()')
 c.execute((PRIVATE/'apply-draft.private.sql').read_text())
 prior_catalog=scalar('select math_private.release_catalog(null)')
 # Model the actual Production private-function boundary, not a verifier grant.
 c.execute('alter function math_private.resolve_profile(uuid) owner to math_executor')
 c.execute('revoke all on function math_private.resolve_profile(uuid) from public,postgres')
 c.execute('create role public_release_verifier nologin nosuperuser noinherit bypassrls')
 c.execute('grant usage on schema public,math_private to public_release_verifier')
 c.execute('grant select on all tables in schema public,math_private to public_release_verifier')
 c.execute('grant execute on function math_private.release_catalog(uuid),math_private.hanyang_worker_references(jsonb) to public_release_verifier')
 assert not scalar("select has_function_privilege('public_release_verifier','math_private.resolve_profile(uuid)','execute')")
 c.execute((PRIVATE/'activate-public.private.sql').read_text())
 checks=[]
 c.execute('set role public_release_verifier')
 cursor=c.execute((PUB/'verify.sql').read_text())
 while True:
  if cursor.description:
   for name,passed in cursor.fetchall():assert passed,name;checks.append(name)
  if not cursor.nextset():break
 c.execute('reset role')
 assert len(checks)==21
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
     assert rpc('math_evaluation_detail',[revision])['output']['progression']['prior_evaluation_id']==ev
     questions.append(dict(question_id=p['essay_question_id'],checks=['submission_idempotent','evaluation_idempotent','criteria_finalize','result_read','foreign_result_denied','rewrite_idempotent','lineage_preserved','reevaluation_idempotent','rewritten_result_read'],status='PASS'))

 history=lambda:{t:scalar("select md5(coalesce(jsonb_agg(to_jsonb(x) order by id)::text,'[]')) from public."+t+" x") for t in ['essay_attempts','essay_evaluations','credit_transactions','math_attempts','math_evaluations']}
 before=history();c.execute((PUB/'rollback-admission.sql').read_text())
 assert history()==before
 assert scalar('select math_private.release_catalog(null)')==prior_catalog
 assert rpc('math_evaluation_detail',[revision])['output']['contract_version']=='math-eval-v1'
 rpc('essay_admin_grant',[A,1,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 p=packages[0];at=rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=p['ids']['leaf'],kind='INITIAL',input_kind='TYPED',typed_answer='Rollback admission probe')])
 try:rpc('math_request_evaluation',[at,new()]);raise AssertionError('Rollback admitted new evaluation')
 except m.psycopg.Error as error:assert 'MATH_QUESTION_NOT_RELEASED' in str(error)
 for r in records:assert scalar('select md5(pg_get_functiondef(%s::regprocedure))',(r['signature'],))==r['before_md5']
 report=dict(scope='isolated PG17; actual production function definitions and exact 92-row insert / 28-state activation / 2 allowlist changes',checks=checks,questions=questions,rollback={'old_catalog_exact':True,'histories_exact':True,'new_evaluation_denied':True,'existing_result_read':True,'function_hashes_exact':True},provider_calls=0,production_writes=0)
 (PUB/'isolated-results.json').write_text(json.dumps(report,indent=2)+'\n');print('KYUNGHEE_PUBLIC_7_FLOW_21_CHECKS_ROLLBACK_PASS')

def main():
 source=inspect.getsource(m.verify).split(" print('MATH_FULL_NON_SUPERUSER_INSTALL_PASS')")[0]
 for name in ['20261002000200_math_runtime_surface.sql','20261002000300_math_learning_runtime.sql']:source+="\n o.execute_as_production(c,admin,(R/'supabase/migrations/"+name+"').read_text())\n"
 source+='\n content_case(c,rpc,new,scalar,A,B)\n';ns=dict(m.__dict__);ns['content_case']=content_case;exec(source,ns);m.h.verify_hqp=ns['verify'];m.h.main(bootstrap_user='supabase_admin')
if __name__=='__main__':main()
