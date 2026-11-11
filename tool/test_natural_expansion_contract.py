"""Opt-in offline PG17 rehearsal. Synthetic accounts/results, no Provider or DSN.

NATURAL_EXPANSION_PACKAGES=.local/natural-expansion-20261111/kau
python tool/test_natural_expansion_contract.py --pg-bin /opt/homebrew/opt/postgresql@17/bin
"""
import inspect
import json
import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_math_persistence as m
from psycopg import sql

R = Path(__file__).resolve().parents[1]


def content_case(c, rpc, new, scalar, A, B):
    root = Path(os.environ['NATURAL_EXPANSION_PACKAGES']).resolve()
    assert '.local' in root.parts
    packages = [json.loads(p.read_text()) for p in sorted(root.glob('*.package.private.json'))]
    assert len(packages) == 12 and all(p['state']=='DRAFT' and not p['publication_allowed'] for p in packages)
    plan = json.loads((R/'supabase/candidates/natural_expansion_20261111/kau-source-plan.json').read_text())
    c.execute('alter table public.math_subproblems add column essay_question_id uuid references public.essay_questions(id)')
    university = plan['exams'][0]['university_id']
    c.execute("insert into public.universities(id,slug,name,is_active) values(%s,'kau-review','Synthetic KAU',false)",(university,))
    for e in plan['exams']:
        c.execute("insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind,verification_status,provenance,is_active) values(%s,%s,%s,%s,'Synthetic review','admission','review','official',false)", (e['exam_id'],university,e['admission_year'],e['exam_key']))
        for q in e['questions']:
            c.execute('insert into public.essay_questions(id,essay_exam_id,question_key,label,display_order,is_published,metadata_version) values(%s,%s,%s,%s,%s,false,1)',(q['question_id'],e['exam_id'],q['question_id'],q['label'],q['display_order']))
    preserve=['essay_attempts','essay_evaluations','credit_transactions']
    def hashes():
        return {t:scalar(sql.SQL("select md5(coalesce(jsonb_agg(to_jsonb(t) order by id)::text,'[]')) from public.{} t").format(sql.Identifier(t))) for t in preserve}
    before=hashes();script=(root/'register-draft.private.sql').read_text()
    c.execute(script);c.execute(script)
    assert hashes()==before
    tables=packages[0]['existing_schema_rows']
    for table in tables:
        assert scalar(sql.SQL('select count(*) from public.{}').format(sql.Identifier(table)))==sum(len(p['existing_schema_rows'][table]) for p in packages)
        for role in ['anon','authenticated']:
            assert not scalar("select has_table_privilege(%s,%s,'SELECT')",(role,'public.'+table))
    checks=['draft_insert_and_replay','prior_essay_answers_results_ledger_preserved','private_table_acls_preserved']
    p=packages[0];rogue=new()
    problem=p['existing_schema_rows']['math_problems'][0]['id']
    c.execute("insert into public.math_subproblems(id,problem_id,leaf_key,display_order,statement,response_format,essay_question_id) values(%s,%s,'collision',99,'Synthetic','FULL_SOLUTION',%s)",(rogue,problem,p['essay_question_id']))
    try:
        c.execute(script)
        raise AssertionError('Duplicate binding accepted')
    except m.psycopg.Error as error:
        c.execute('rollback');assert 'TASK20_QUESTION_ALREADY_BOUND' in str(error)
    c.execute('delete from public.math_subproblems where id=%s',(rogue,))
    try:
        c.execute("update public.math_problems set statement='Synthetic changed content' where id=%s",(problem,))
        raise AssertionError('Immutable content overwritten')
    except m.psycopg.Error as error:
        assert 'IMMUTABLE_CONTENT_VERSION' in str(error)
    from essay_lab.task20_priority_packages import registration_sql
    import copy
    changed=copy.deepcopy(packages)
    changed[0]['existing_schema_rows']['math_problems'][0]['statement']='Synthetic changed content'
    try:
        c.execute(registration_sql(changed))
        raise AssertionError('Changed content accepted')
    except m.psycopg.Error as error:
        c.execute('rollback');assert 'TASK20_CONTENT_DRIFT' in str(error)
    checks+=['duplicate_binding_rejected','immutable_content_preserved','changed_package_rejected']
    if (root/'worker-source.private.sql').exists():
        from essay_lab.natural_connection_contract import verify_worker
        verify_worker(c,scalar,root,packages,plan,R)
    questions=[]
    for p in packages:
        leaf=p['ids']['leaf']
        try:
            rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic')])
            raise AssertionError('DRAFT submit allowed')
        except m.psycopg.Error:pass
        # In this disposable DB only, exercise existing runtime using synthetic responses.
        # No activation file is generated and no publication metadata is changed.
        for t in ['math_problem_sets','math_problems','math_evaluation_profiles','math_canonical_solutions']:
            c.execute(sql.SQL("update public.{} set state='ACTIVE' where id=%s").format(sql.Identifier(t)),(p['existing_schema_rows'][t][0]['id'],))
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
        questions.append(dict(question_id=p['essay_question_id'],checks=['draft_submit_denied','submission_idempotent','evaluation_idempotent','criteria_finalize','result_read','foreign_result_denied'],status='PASS'))
    report=dict(scope='DISPOSABLE_PG17_SYNTHETIC_CONTRACT_NOT_PROVIDER_OR_UI_E2E',checks=checks,questions=questions,production_writes=0,provider_calls=0)
    (root/'contract-report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(dict(natural_packages=12,contract_checks=len(checks),question_checks=72,status='PASS',production_writes=0,provider_calls=0)))


def main():
    source=inspect.getsource(m.verify).split(" print('MATH_FULL_NON_SUPERUSER_INSTALL_PASS')")[0]
    source+="\n o.execute_as_production(c,admin,(R/'supabase/migrations/20261002000200_math_runtime_surface.sql').read_text())\n"
    source+="\n o.execute_as_production(c,admin,(R/'supabase/migrations/20261002000300_math_learning_runtime.sql').read_text())\n"
    source+='\n content_case(c,rpc,new,scalar,A,B)\n'
    ns=dict(m.__dict__);ns['content_case']=content_case
    exec(source,ns)
    m.h.verify_hqp=ns['verify']
    m.h.main(bootstrap_user='supabase_admin')


if __name__=='__main__':main()
