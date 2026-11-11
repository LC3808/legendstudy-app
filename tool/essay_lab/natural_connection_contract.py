"""Only called by the disposable local PG harness. No external DSN or Provider."""
import copy
import hashlib
import json
from pathlib import Path
from psycopg.types.json import Jsonb
from essay_lab.natural_connection import validate_worker

def verify_worker(c, scalar, root, packages, plan, repository):
    fixture=repository/'tool/fixtures/kau-connection-worker-20261111.sql'
    definition=fixture.read_text()
    assert hashlib.md5(definition.encode()).hexdigest()=='54acd2a1914f360e6ecd62e39acc8222'
    # This schema and exact read-only function exist in production; copy only into
    # the disposable local PG fixture. No remote function is altered.
    c.execute('''create table math_private.task20_hanyang_source_pages(
      question_id uuid primary key references public.essay_questions(id),
      exam_id uuid not null references public.essay_exams(id), manifest jsonb not null,
      images jsonb not null check(jsonb_array_length(images) between 1 and 24), content_sha256 text not null);
      alter table math_private.task20_hanyang_source_pages enable row level security;
      revoke all on math_private.task20_hanyang_source_pages from public,anon,authenticated;''')
    c.execute(definition)
    c.execute('revoke all on function math_private.hanyang_worker_references(jsonb) from public,anon,authenticated')
    c.execute((root/'worker-source.private.sql').read_text())
    before=scalar("select md5(pg_get_functiondef('math_private.hanyang_worker_references(jsonb)'::regprocedure))")
    assert before=='54acd2a1914f360e6ecd62e39acc8222'
    results=[]
    for p in packages:
        exam=next(e for e in plan['exams'] if e['exam_id']==p['exam_id'])
        q=next(q for q in exam['questions'] if q['question_id']==p['essay_question_id'])
        payload=json.loads((root/(q['question_id']+'.worker.private.json')).read_text())
        pages=validate_worker(payload,exam,q)
        ctx=scalar('''select jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),
          'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id))
          from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id=%s''',(p['ids']['leaf'],))
        def resolve(value):return scalar('select math_private.hanyang_worker_references(%s)',(Jsonb(value),))
        out=resolve(ctx)
        assert len(out['official_images'])==pages and out['official_evidence_gaps']==[]
        assert all('data' not in i for i in out['official_image_index'])
        assert len(json.dumps(dict(ctx,**out),ensure_ascii=False).encode())<2097152
        for mutate in [lambda z:z.pop('sources'),
                       lambda z:z['leaf'].update(essay_question_id='00000000-0000-0000-0000-000000000000'),
                       lambda z:z['problem'].update(problem_set_id='00000000-0000-0000-0000-000000000000'),
                       lambda z:z['sources'][0].update(content_sha256='0'*64),
                       lambda z:z['sources'][0].update(locator='physical pages 1,2'),
                       lambda z:z['sources'][0].update(locator='PDF 99쪽')]:
            changed=copy.deepcopy(ctx);mutate(changed);assert resolve(changed)=={}
        for role in ['anon','authenticated']:
            assert not scalar("select has_table_privilege(%s,'math_private.task20_hanyang_source_pages','SELECT')",(role,))
            assert not scalar("select has_function_privilege(%s,'math_private.hanyang_worker_references(jsonb)','EXECUTE')",(role,))
        criteria=p['existing_schema_rows']['math_scoring_criteria']
        assert all(r['official_points'] is None for r in criteria)
        assert len({r['source_id'] for r in criteria})==1
        results.append(dict(question_id=q['question_id'],pages=pages,status='PASS',
                            checks=['exact_source_context','image_hash_pages','no_student_source_access','missing_source_denied',
                                    'foreign_question_denied','foreign_exam_denied','changed_hash_denied','old_locator_denied','changed_pages_denied',
                                    'original_page_criteria_no_inferred_points']))
    assert scalar("select md5(pg_get_functiondef('math_private.hanyang_worker_references(jsonb)'::regprocedure))")==before
    report=dict(scope='DISPOSABLE_LOCAL_PG17_EXISTING_WORKER_FUNCTION',worker_definition_md5=before,
                questions=results,provider_calls=0,production_writes=0)
    (root/'worker-contract-report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(dict(worker_questions=len(results),worker_checks=120,status='PASS',provider_calls=0,production_writes=0)))
