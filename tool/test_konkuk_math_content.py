#!/usr/bin/env python3
"""Opt-in private content + canonical Math SQL in disposable PG17, no remote DSN.
Reuses existing prerequisite harness; no Production, actual Storage, or Provider.
"""
import inspect,json,os,sys
from pathlib import Path
from psycopg import sql
from psycopg.types.json import Jsonb
sys.path.insert(0,str(Path(__file__).resolve().parent))
import test_math_persistence as m
R=Path(__file__).resolve().parents[1]
private=json.loads(Path(os.environ['KONKUK_PRIVATE_INPUT']).read_text())
assert private['provider_allowed'] is False and private['state']=='DRAFT'

def content_case(c,rpc,new,scalar,A,B):
    x=private; rows=x['existing_schema_rows']; checks=[]
    def ok(name,flag=True): assert flag,name;checks.append(name)
    university='77fe30b2-f693-4612-a6d3-50e8be5c8f6c'
    c.execute("insert into public.universities(id,slug,name,is_active) values(%s,'konkuk','건국대학교',false)",(university,))
    c.execute("insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind,verification_status,provenance,is_active) values(%s,%s,2026,'konkuk-local-representative','건국대 대표 문항 로컬 테스트','admission','review','official',false)",(x['exam_id'],university))
    def insert_all():
      with c.transaction():
       for table,items in rows.items():
        for row in items:
         prior=scalar(sql.SQL('select coalesce((select to_jsonb(t) from public.{} t where id=%s),null)').format(sql.Identifier(table)),(row['id'],))
         if prior:
          assert all(prior[k]==v for k,v in row.items()),'CONFLICT';continue
         c.execute(sql.SQL('insert into public.{} ({}) values ({})').format(sql.Identifier(table),sql.SQL(',').join(map(sql.Identifier,row)),sql.SQL(',').join(sql.Placeholder() for _ in row)),list(row.values()))
    if os.environ.get('KONKUK_DRAFT_SQL'):
      script=Path(os.environ['KONKUK_DRAFT_SQL']).read_text()
      rollback=Path(os.environ['KONKUK_ROLLBACK_SQL']).read_text()
      c.execute(script); c.execute(script);ok('exact_sql_replay')
      c.execute(rollback)
      ok('unused_draft_rollback',all(scalar(sql.SQL('select count(*) from public.{}').format(sql.Identifier(t)))==0 for t in rows))
      c.execute(script)
    insert_all();insert_all();ok('exact_replay_no_duplicate')
    for table in rows:
      ok(table+'_count',scalar(sql.SQL('select count(*) from public.{}').format(sql.Identifier(table)))==len(rows[table]))
    for role in ['anon','authenticated']:
      ok(role+'_private_tables',all(not scalar('select has_table_privilege(%s,%s,\'SELECT\')',(role,'public.'+t)) for t in rows))
    # DRAFT rejects attempts; fixture-only activation occurs only inside disposable DB.
    leaf=x['ids']['leaf']
    try:rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL',input_kind='TYPED',typed_answer='synthetic')]);raise AssertionError('DRAFT accepted')
    except m.psycopg.Error:ok('draft_submission_denied')
    for table in ['math_problem_sets','math_problems','math_evaluation_profiles','math_canonical_solutions']:
      c.execute(sql.SQL("update public.{} set state='ACTIVE'").format(sql.Identifier(table)))
    rpc('essay_admin_grant',[A,3,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
    history=[]
    for revision in [1,2]:
      p=dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL' if revision==1 else 'FULL_RESOLVE',input_kind='TYPED',typed_answer='Synthetic local answer, not real student content')
      if history:p.update(predecessor_id=history[0][0],prior_evaluation_id=history[0][1])
      attempt=str(rpc('math_submit_attempt',[p]));ok('attempt_replay_'+str(revision),str(rpc('math_submit_attempt',[p]))==attempt)
      key=new();ev=str(rpc('math_request_evaluation',[attempt,key]));ok('evaluation_replay_'+str(revision),str(rpc('math_request_evaluation',[attempt,key]))==ev)
      claim=rpc('math_claim_evaluation',[ev],role='math_evaluation_worker')
      ok('bound_leaf_'+str(revision),str(scalar('select leaf_id from public.math_evaluations where id=%s',(ev,)))==leaf)
      out=dict(contract_version='math-eval-v1',extraction_id=None,steps=[dict(id=new(),position=1,kind='COMPUTATION',representation='Synthetic answer',status='VALID',explanation='Mock only',regions=[])],edges=[],errors=[],causes=[],core=[],hints=[],references=[],paths=[],criteria=[dict(criterion_id=x['ids']['criterion'],verdict='satisfied',explanation='Mock contract check')],rubric={v:'ADEQUATE' for v in rows['math_evaluation_profiles'][0]['required_dimensions']},overall=dict(status='ANSWER_CORRECT_AND_REASONING_SUFFICIENT',answer_status='CORRECT',coverage='ATTEMPTED',explanation='Mock only'),provenance=dict(provider='synthetic',model='mock',model_version='1',prompt_version='1'),progression=None if revision==1 else dict(prior_evaluation_id=history[0][1],target_step_id=None,downstream='REASSESSED',summary='Mock rewrite'),generated_solution=None)
      rpc('math_finalize_evaluation',[ev,claim['lease_token'],out],role='math_evaluation_worker')
      credits=scalar('select d.credits_required from public.essay_billing_decisions d join public.math_billing_bindings b on b.billing_decision_id=d.id where b.math_evaluation_id=%s',(ev,))
      ok('credit_'+str(revision),credits==(1 if revision==1 else 0))
      ok('result_'+str(revision),rpc('math_evaluation_detail',[ev])['output']['contract_version']=='math-eval-v1')
      try:rpc('math_evaluation_detail',[ev],uid=B);raise AssertionError('foreign access')
      except m.psycopg.Error:ok('foreign_denied_'+str(revision))
      history.append((attempt,ev))
    ok('lineage',scalar('select count(distinct lineage_id) from public.math_attempts where leaf_id=%s',(leaf,))==1)
    report=dict(status='PASS',checks=checks,production_writes=0,provider_calls=0,actual_storage_verified=False,scope='canonical isolated SQL, private official content, synthetic answers/results and local test Credits')
    Path(os.environ['KONKUK_REPORT']).write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

# Reuse canonical non-superuser installation, without rerunning its completed acceptance matrix.
source=inspect.getsource(m.verify).split(" print('MATH_FULL_NON_SUPERUSER_INSTALL_PASS')")[0]
source+='\n content_case(c,rpc,new,scalar,A,B)\n'
ns=dict(m.__dict__);ns['content_case']=content_case
exec(source,ns)
m.h.verify_hqp=ns['verify'];m.h.main(bootstrap_user='supabase_admin')
