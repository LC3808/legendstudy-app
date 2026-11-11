"""Exact Stage-1 SQL rehearsal in disposable Unix-only PG17; no remote DSN/Provider."""
import copy,hashlib,inspect,json,os,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import test_math_persistence as m
from psycopg import sql
from psycopg.types.json import Jsonb
from prepare_natural_preflight import OUT,PRIVATE,BASE,R
scope_mode=os.environ.get('NATURAL_PREFLIGHT_SCOPE','all')
assert scope_mode in ('all','kau','konkuk')
if scope_mode=='kau':
 OUT=R/'supabase/candidates/natural_expansion_20261111/kau-production-preflight'
 PRIVATE=R/'.local/kau-production-preflight-20261112'
if scope_mode=='konkuk':
 OUT=R/'supabase/candidates/natural_tech_ready_20261112/konkuk-production-preflight'
 PRIVATE=R/'.local/konkuk-production-preflight-20261112'
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
 for f in json.loads((OUT/'production-functions.json').read_text()):c.execute(f['definition'])
 if scope_mode=='konkuk':c.execute((R/'.local/kau-production-preflight-20261112/apply-draft.private.sql').read_text())
 checks=[]
 def ok(name,value=True):assert value,name;checks.append(name);print(name,'PASS',flush=True)
 def denied(name,fn,expected):
  try:fn()
  except m.psycopg.Error as e:
   c.execute('rollback');assert expected in str(e),(name,str(e));ok(name);return
  raise AssertionError(name+' unexpectedly allowed')
 def rows(script):
  cursor=c.execute(script);result=[]
  while True:
   if cursor.description:result.extend(cursor.fetchall())
   if not cursor.nextset():break
  return result
 def full_snapshot():
  tables=[x[0] for x in c.execute("select schemaname||'.'||tablename from pg_tables where schemaname in ('public','math_private','essay_private','account_private') order by 1")]
  return {t:scalar('select md5(coalesce(string_agg(md5(to_jsonb(x)::text),\'\' order by to_jsonb(x)::text),\'\')) from '+t+' x') for t in tables}
 def preflight():
  r=rows((OUT/'preflight.sql').read_text());return [(x[0],x[1]) for x in r if len(x)==2]
 ok('preflight_all_pass',all(v is True for _,v in preflight()))
 before=full_snapshot();catalog=rpc('math_catalog',[50]);ok('existing_seven_catalog',len(catalog)==7)
 # Preserve a real local existing attempt/evaluation and result through apply/retire.
 p=old[0];rpc('essay_admin_grant',[A,1,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 attempt=str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=p['ids']['leaf'],kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic existing answer')]))
 ev=str(rpc('math_request_evaluation',[attempt,new()]));claim=rpc('math_claim_evaluation',[ev],role='math_evaluation_worker')
 out=dict(contract_version='math-eval-v1',extraction_id=None,steps=[dict(id=new(),position=1,kind='COMPUTATION',representation='Synthetic',status='VALID',explanation='Contract only',regions=[])],edges=[],errors=[],causes=[],core=[],hints=[],references=[],paths=[],criteria=[dict(criterion_id=x['id'],verdict='satisfied',explanation='Synthetic') for x in p['existing_schema_rows']['math_scoring_criteria']],rubric={d:'ADEQUATE' for d in p['existing_schema_rows']['math_evaluation_profiles'][0]['required_dimensions']},overall=dict(status='ANSWER_CORRECT_AND_REASONING_SUFFICIENT',answer_status='CORRECT',coverage='ATTEMPTED',explanation='Synthetic only'),provenance=dict(provider='synthetic',model='mock',model_version='1',prompt_version='1'),progression=None,generated_solution=None)
 rpc('math_finalize_evaluation',[ev,claim['lease_token'],out],role='math_evaluation_worker')
 old_result=rpc('math_evaluation_detail',[ev]);before=full_snapshot();apply=(PRIVATE/'apply-draft.private.sql').read_text()
 # Independent preflight failures must leave every existing row intact.
 qid=packages[0]['essay_question_id']
 c.execute('update public.essay_questions set is_published=true where id=%s',(qid,))
 denied('publication_drift_rejected',lambda:c.execute(apply),'PREFLIGHT_FAILED')
 c.execute('update public.essay_questions set is_published=false where id=%s',(qid,))
 c.execute('grant select on public.math_problems to authenticated')
 denied('acl_drift_rejected',lambda:c.execute(apply),'PREFLIGHT_FAILED')
 c.execute('revoke select on public.math_problems from authenticated')
 c.execute('alter table public.math_problems disable row level security')
 denied('rls_drift_rejected',lambda:c.execute(apply),'PREFLIGHT_FAILED')
 c.execute('alter table public.math_problems enable row level security')
 f=next(f for f in json.loads((OUT/'production-functions.json').read_text()) if f['name']=='release_catalog')
 c.execute(f['definition'].replace('declare result jsonb;','declare result jsonb; -- synthetic drift\n'))
 denied('function_drift_rejected',lambda:c.execute(apply),'PREFLIGHT_FAILED');c.execute(f['definition'])
 ok('negative_preflight_preserves_all_rows',full_snapshot()==before)
 # Force failure after content inserts, within the exact atomic apply script.
 c.execute("create function math_private.synthetic_fail() returns trigger language plpgsql as $$begin raise exception 'SYNTHETIC_LATE_FAILURE';end$$; create trigger synthetic_fail before insert on math_private.task20_hanyang_source_pages for each row execute function math_private.synthetic_fail()")
 denied('late_worker_failure_atomic_rollback',lambda:c.execute(apply),'SYNTHETIC_LATE_FAILURE')
 ok('late_failure_zero_partial_rows',full_snapshot()==before)
 c.execute('drop trigger synthetic_fail on math_private.task20_hanyang_source_pages;drop function math_private.synthetic_fail()')
 c.execute("create function math_private.synthetic_mutate() returns trigger language plpgsql as $$begin update public.universities set name='Synthetic unexpected side effect';return new;end$$; create trigger synthetic_mutate before insert on math_private.task20_hanyang_source_pages for each row execute function math_private.synthetic_mutate()")
 denied('preservation_guard_detects_existing_data_change',lambda:c.execute(apply),'PRESERVATION_DRIFT')
 ok('preservation_failure_atomic_rollback',full_snapshot()==before)
 c.execute('drop trigger synthetic_mutate on math_private.task20_hanyang_source_pages;drop function math_private.synthetic_mutate()')
 c.execute(apply);ok(f'exact_{expected}_apply_commit')
 ok('postcheck_all_pass',all(x[1] is True for x in rows((OUT/'verify.sql').read_text()) if len(x)==2))
 ok('old_catalog_preserved',rpc('math_catalog',[50])==catalog)
 ok('old_result_preserved',rpc('math_evaluation_detail',[ev])==old_result)
 applied=full_snapshot();denied('duplicate_apply_rejected',lambda:c.execute(apply),'PREFLIGHT_FAILED');ok('duplicate_apply_no_changes',full_snapshot()==applied)
 for q in [q for q in review if q['state'] in ('HOLD','NOT READY')]:
  assert scalar('select count(*) from public.math_subproblems where essay_question_id=%s',(q['registry_id'],))==0
 ok('hold5_not_ready16_not_inserted')
 if scope_mode=='kau':
  deferred=[q for q in review if q['university']!='한국항공대학교' and q['state'] in ('SERVICE READY (LOCAL)','DATA READY')]
  ok('deferred_46_not_inserted',len(deferred)==46 and all(scalar('select count(*) from public.math_subproblems where essay_question_id=%s',(q['registry_id'],))==0 for q in deferred))
 if scope_mode=='konkuk':
  deferred=[q for q in review if q['university'] not in ('건국대학교','한국항공대학교') and q['state'] in ('SERVICE READY (LOCAL)','DATA READY')]
  ok('deferred_22_not_inserted',len(deferred)==22 and all(scalar('select count(*) from public.math_subproblems where essay_question_id=%s',(q['registry_id'],))==0 for q in deferred))
  kau_ids=[q['registry_id'] for q in review if q['university']=='한국항공대학교' and q['state']=='SERVICE READY (LOCAL)']
  ok('prior_kau7_draft_and_worker_preserved',all(scalar("select count(*) from public.math_subproblems l join public.math_problems p on p.id=l.problem_id where l.essay_question_id=%s and p.state='DRAFT'",(qid,))==1 and scalar('select count(*) from math_private.task20_hanyang_source_pages where question_id=%s',(qid,))==1 for qid in kau_ids))
 for p in packages:
  for uid,label in [(A,'owner'),(B,'other')]:
   denied(p['essay_question_id']+'_'+label+'_draft_denied',lambda p=p,uid=uid:rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=p['ids']['leaf'],kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic')],uid=uid),'CONTENT_UNAVAILABLE')
  ctx=scalar('''select jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)) from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id=%s''',(p['ids']['leaf'],))
  resolved=scalar('select math_private.hanyang_worker_references(%s)',(Jsonb(ctx),));w=json.loads((PRIVATE/(p['essay_question_id']+'.worker.private.json')).read_text())
  assert resolved['official_evidence_gaps']==[] and len(resolved['official_images'])==len(json.loads(w['images_text']))
  ok(p['essay_question_id']+'_existing_worker_exact')
 # Demonstrate why WEB allowlist alone cannot authorize private production QA.
 p=packages[0]
 for t in ['math_problem_sets','math_problems','math_evaluation_profiles','math_canonical_solutions']:
  c.execute(sql.SQL("update public.{} set state='ACTIVE' where id=%s").format(sql.Identifier(t)),(p['existing_schema_rows'][t][0]['id'],))
 rogue=rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=p['ids']['leaf'],kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic gap probe')],uid=B)
 ok('stage2_gap_other_subject_can_submit_ACTIVE',bool(rogue))
 denied('stage1_rollback_refuses_later_activation',lambda:c.execute((OUT/'rollback-retire.sql').read_text()),'ROLLBACK_SCOPE_CHANGED')
 for t in ['math_problem_sets','math_problems','math_evaluation_profiles','math_canonical_solutions']:
  c.execute(sql.SQL("update public.{} set state='DRAFT' where id=%s").format(sql.Identifier(t)),(p['existing_schema_rows'][t][0]['id'],))
 histories={t:scalar('select md5(jsonb_agg(to_jsonb(x) order by id)::text) from public.'+t+' x') for t in ['essay_attempts','essay_evaluations','credit_transactions','math_attempts','math_evaluations']}
 c.execute((OUT/'rollback-retire.sql').read_text());ok('exact_retire_commit')
 retired=full_snapshot();c.execute((OUT/'rollback-retire.sql').read_text());ok('retire_replay_no_changes',retired==full_snapshot())
 ok('retired_postcheck_all_pass',all(x[1] is True for x in rows((OUT/'verify-retired.sql').read_text()) if len(x)==2))
 ok('histories_preserved_after_retire',histories=={t:scalar('select md5(jsonb_agg(to_jsonb(x) order by id)::text) from public.'+t+' x') for t in histories})
 ok('old_result_read_after_retire',rpc('math_evaluation_detail',[ev])==old_result)
 ok('old_catalog_after_retire',rpc('math_catalog',[50])==catalog)
 for p in packages:denied(p['essay_question_id']+'_retired_denied',lambda p=p:rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=p['ids']['leaf'],kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic')]),'CONTENT_UNAVAILABLE')
 report=dict(sql_sha256={name:hashlib.sha256(path.read_bytes()).hexdigest() for name,path in [('apply',PRIVATE/'apply-draft.private.sql'),('preflight',OUT/'preflight.sql'),('verify',OUT/'verify.sql'),('rollback',OUT/'rollback-retire.sql'),('verify_retired',OUT/'verify-retired.sql')]},scope='EXACT_STAGE1_SQL_UNIX_ONLY_PG17; synthetic users/history, copied production function definitions',checks=checks,count=len(checks),production_writes=0,provider_calls=0,stage2_owner_only_gate='GAP_CONFIRMED; no implementation or activation authorized')
 (OUT/'isolated-results.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(dict(checks=len(checks),status='PASS')))

def main():
 source=inspect.getsource(m.verify).split(" print('MATH_FULL_NON_SUPERUSER_INSTALL_PASS')")[0]
 for name in ['20261002000200_math_runtime_surface.sql','20261002000300_math_learning_runtime.sql']:source+="\n o.execute_as_production(c,admin,(R/'supabase/migrations/"+name+"').read_text())\n"
 source+='\n content_case(c,rpc,new,scalar,A,B)\n';ns=dict(m.__dict__);ns['content_case']=content_case;exec(source,ns);m.h.verify_hqp=ns['verify'];m.h.main(bootstrap_user='supabase_admin')
if __name__=='__main__':main()
