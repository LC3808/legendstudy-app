"""Opt-in real canonical Math contract tests in disposable Unix-socket PG17.

Private official packages, synthetic answers/results; no provider or production DSN.
"""
import inspect
import json
import os
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
import test_math_persistence as m
from psycopg import sql

R=Path(__file__).resolve().parents[1]
ROOT=Path(os.environ['TASK20_PACKAGES'])


def content_case(c,rpc,new,scalar,A,B):
    packages=[json.loads(p.read_text()) for p in sorted(ROOT.glob('*.private.json'))]
    assert len(packages)==6
    legacy=json.loads((ROOT.parent/'konkuk-q1-baseline.private.json').read_text())
    all_packages=packages+[legacy]
    # Current production has this Registry link; fixture adds only that known column.
    c.execute('alter table public.math_subproblems add column essay_question_id uuid references public.essay_questions(id)')
    univ=new()
    c.execute("insert into public.universities(id,slug,name,is_active) values(%s,'task20-fixture','Synthetic isolated university',false)",(univ,))
    for eid in sorted({p['exam_id'] for p in packages}):
        c.execute("insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind,verification_status,provenance,is_active) values(%s,%s,2026,%s,'Synthetic exam','admission','review','official',false)",(eid,univ,eid))
    for i,p in enumerate(all_packages):
        c.execute("insert into public.essay_questions(id,essay_exam_id,question_key,label,display_order,is_published,metadata_version) values(%s,%s,%s,%s,%s,false,1)",(p['essay_question_id'],p['exam_id'],p['essay_question_id'],'Synthetic fixture',i))
    for table,rows in legacy['existing_schema_rows'].items():
        for row in rows:
            c.execute(sql.SQL('insert into public.{} ({}) values ({})').format(sql.Identifier(table),sql.SQL(',').join(map(sql.Identifier,row)),sql.SQL(',').join(sql.Placeholder() for _ in row)),list(row.values()))
    preserved=['essay_evaluations','essay_attempts','credit_transactions']
    def hashes():
        return {t:scalar(sql.SQL("select md5(coalesce(jsonb_agg(to_jsonb(t) order by id)::text,'[]')) from public.{} t").format(sql.Identifier(t))) for t in preserved}
    before=hashes()
    script=(ROOT/'register.private.sql').read_text()
    c.execute(script)
    c.execute(script)
    assert hashes()==before
    checks=['registration_replay_no_duplicates','existing_humanities_answers_results_ledger_preserved']
    first=packages[0]
    rogue=new()
    c.execute("insert into public.math_subproblems(id,problem_id,leaf_key,display_order,statement,response_format,essay_question_id) values(%s,%s,'duplicate-fixture',99,'Synthetic','FULL_SOLUTION',%s)",(rogue,first['ids']['problem'],first['essay_question_id']))
    try:
        c.execute(script)
        raise AssertionError('duplicate question binding accepted')
    except m.psycopg.Error as error:
        c.execute('rollback')
        assert 'TASK20_QUESTION_ALREADY_BOUND' in str(error)
    c.execute('delete from public.math_subproblems where id=%s',(rogue,))
    checks.append('concurrent_duplicate_question_binding_rejected')
    for table in packages[0]['existing_schema_rows']:
        assert scalar(sql.SQL('select count(*) from public.{}').format(sql.Identifier(table)))==sum(len(p['existing_schema_rows'][table]) for p in all_packages)
        for role in ['anon','authenticated']:
            assert not scalar("select has_table_privilege(%s,%s,'SELECT')",(role,'public.'+table))
    checks.append('all_private_table_acls_preserved')
    for p in all_packages:
        try:
            rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=p['ids']['leaf'],kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic')])
            raise AssertionError('DRAFT accepted')
        except m.psycopg.Error: pass
    c.execute('create table math_private.runtime_control(singleton boolean primary key, evaluations_enabled boolean)')
    c.execute('insert into math_private.runtime_control values(true,true)')
    baseline=json.loads((ROOT.parent/'functions-before.json').read_text())
    for f in baseline:c.execute(f['definition'])
    c.execute('create trigger task20_admission before insert on public.math_evaluations for each row execute function math_private.evaluation_admission()')
    # Existing Q1 is fixture-activated before the additive candidate.
    for table,key in [('math_problem_sets','set'),('math_problems','problem'),('math_evaluation_profiles','profile'),('math_canonical_solutions','solution')]:
        c.execute(sql.SQL("update public.{} set state='ACTIVE' where id=%s").format(sql.Identifier(table)),(legacy['ids'][key],))
    assert len(scalar('select math_private.release_catalog(null)'))==1
    c.execute((ROOT.parent/'activate.private.sql').read_text())
    released=scalar('select math_private.release_catalog(null)')
    assert len(released)==7
    assert {str(x['essay_question_id']) for x in released}=={p['essay_question_id'] for p in all_packages}
    checks.extend(['exact_activation_sql','seven_question_catalog','legacy_q1_binding_preserved'])
    reports=[]
    for p in all_packages:
        leaf=p['ids']['leaf']
        rpc('essay_admin_grant',[A,2,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
        payload=dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic contract test answer')
        attempt=str(rpc('math_submit_attempt',[payload]));assert str(rpc('math_submit_attempt',[payload]))==attempt
        evkey=new();ev=str(rpc('math_request_evaluation',[attempt,evkey]));assert str(rpc('math_request_evaluation',[attempt,evkey]))==ev
        cl=rpc('math_claim_evaluation',[ev],role='math_evaluation_worker')
        assert str(scalar('select leaf_id from public.math_evaluations where id=%s',(ev,)))==leaf
        criteria=p['existing_schema_rows']['math_scoring_criteria']
        output=dict(contract_version='math-eval-v1',extraction_id=None,
            steps=[dict(id=new(),position=1,kind='COMPUTATION',representation='Synthetic',status='VALID',explanation='Contract only',regions=[])],
            edges=[],errors=[],causes=[],core=[],hints=[],references=[],paths=[],
            criteria=[dict(criterion_id=x['id'],verdict='satisfied',explanation='Synthetic verdict') for x in criteria],
            rubric={d:'ADEQUATE' for d in p['existing_schema_rows']['math_evaluation_profiles'][0]['required_dimensions']},
            overall=dict(status='ANSWER_CORRECT_AND_REASONING_SUFFICIENT',answer_status='CORRECT',coverage='ATTEMPTED',explanation='Mock contract only'),
            provenance=dict(provider='synthetic',model='mock',model_version='1',prompt_version='1'),progression=None,generated_solution=None)
        rpc('math_finalize_evaluation',[ev,cl['lease_token'],output],role='math_evaluation_worker')
        assert rpc('math_evaluation_detail',[ev])['output']['contract_version']=='math-eval-v1'
        try:
            rpc('math_evaluation_detail',[ev],uid=B)
            raise AssertionError('foreign read')
        except m.psycopg.Error: pass
        rewrite=str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=leaf,kind='FULL_RESOLVE',input_kind='TYPED',typed_answer='Synthetic rewrite',predecessor_id=attempt,prior_evaluation_id=ev)]))
        rev=str(rpc('math_request_evaluation',[rewrite,new()]));rcl=rpc('math_claim_evaluation',[rev],role='math_evaluation_worker')
        output['steps'][0]['id']=new()
        output['progression']=dict(prior_evaluation_id=ev,target_step_id=None,downstream='REASSESSED',summary='Synthetic rewrite')
        rpc('math_finalize_evaluation',[rev,rcl['lease_token'],output],role='math_evaluation_worker')
        credits=scalar('select d.credits_required from public.essay_billing_decisions d join public.math_billing_bindings b on b.billing_decision_id=d.id where b.math_evaluation_id=%s',(rev,))
        assert credits==0
        assert rpc('math_evaluation_detail',[rev])['output']['contract_version']=='math-eval-v1'
        reports.append(dict(question_id=p['essay_question_id'],leaf_id=leaf,status='PASS',checks=['draft_denied','registry_link','submission_replay','evaluation_replay','criteria_finalize','result_read','foreign_read_denied','free_rewrite_zero_credit','rewrite_result_read']))
    provider_reports=[]
    if os.environ.get('TASK20_REPLAY_PROVIDER')=='1':
        result_files=sorted(ROOT.parent.glob('*.result.json'))
        assert len(result_files)==12
        for file in result_files:
            result=json.loads(file.read_text()); inp=result['input'];out=result['physical']
            rpc('essay_admin_grant',[A,1,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
            at=str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=inp['leafId'],kind='INITIAL',input_kind='TYPED',typed_answer=inp['canonicalPackage']['attempt']['typed_answer'])]))
            ev=str(rpc('math_request_evaluation',[at,new()]));cl=rpc('math_claim_evaluation',[ev],role='math_evaluation_worker')
            rpc('math_finalize_evaluation',[ev,cl['lease_token'],out],role='math_evaluation_worker')
            detail=rpc('math_evaluation_detail',[ev])
            assert detail['output']['contract_version']=='math-eval-v1'
            provider_reports.append(dict(case=file.name,status='PASS'))
    final_hashes=hashes()
    evaluations=scalar('select md5(jsonb_agg(to_jsonb(e) order by id)::text) from public.math_evaluations e')
    c.execute((ROOT.parent/'rollback-release.sql').read_text())
    assert len(scalar('select math_private.release_catalog(null)'))==1
    assert hashes()==final_hashes
    assert evaluations==scalar('select md5(jsonb_agg(to_jsonb(e) order by id)::text) from public.math_evaluations e')
    checks.extend(['exact_rollback_sql','rollback_preserves_results_and_ledger','rollback_keeps_legacy_q1'])
    report=dict(scope='isolated PostgreSQL17 canonical contract; NOT Production E2E',checks=checks,questions=reports,provider_result_replays=provider_reports,production_writes=0,provider_calls=0)
    (ROOT/'contract-test.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report))


source=inspect.getsource(m.verify).split(" print('MATH_FULL_NON_SUPERUSER_INSTALL_PASS')")[0]
source+="\n o.execute_as_production(c,admin,(R/'supabase/migrations/20261002000200_math_runtime_surface.sql').read_text())\n"
source+="\n o.execute_as_production(c,admin,(R/'supabase/migrations/20261002000300_math_learning_runtime.sql').read_text())\n"
source+='\n content_case(c,rpc,new,scalar,A,B)\n'
ns=dict(m.__dict__);ns['content_case']=content_case
exec(source,ns)
m.h.verify_hqp=ns['verify']
m.h.main(bootstrap_user='supabase_admin')
