"""Build additive DRAFT Math packages from private, visually reviewed sources.

No network/DB/provider calls. Official text remains in ignored .local artifacts.
One existing Registry question maps to one leaf; subparts remain in its rubric.
"""
import argparse
import hashlib
import json
from pathlib import Path
import uuid

EXAMS = {'konkuk': '25dc068b-4672-56e1-b8df-08ee8800e2f6',
         'kyunghee': '0a331c3e-d46b-5af3-b787-e3342e8a1ae8'}
DIMENSIONS = ['logical_development', 'computation_accuracy', 'final_conclusion']
SOURCE_HASHES = {
    'konkuk': '17acea6adb3f17ce38dd5d31e99ca2149ebde592987cf606a41106613bf6334a',
    'konkuk-report': '74884de48371355d76021a2e9c714e78a46b113f5a51149cedf3b34ab6a4d988',
    'kyunghee': '8ef3db4bd42d2cd1cfa4663277a5aaf726aedbd01b457719a8a151b8a1767706',
}


def build(q):
    assert q['slug'] in EXAMS and q['steps'] and q['statement']
    assert sum(c[0] for c in q['criteria']) == q['points']
    raw = json.dumps(q, ensure_ascii=False)
    assert not any(0xE000 <= ord(c) <= 0xF8FF for c in raw), 'UNREVIEWED_PRIVATE_GLYPH'
    ns = uuid.UUID(q['question_id'])
    uid = lambda name: str(uuid.uuid5(ns, 'task20-20261106-v1:' + name))
    ids = {key: uid(key) for key in ['set', 'problem', 'leaf', 'profile', 'criterion', 'solution']}
    rows = {}
    rows['math_problem_sets'] = [dict(id=ids['set'], essay_exam_id=EXAMS[q['slug']],
        logical_id=ids['set'], version=1, label=f"{q['slug']} 2026 자연 Q{q['n']}", state='DRAFT')]
    rows['math_problems'] = [dict(id=ids['problem'], problem_set_id=ids['set'], logical_id=ids['problem'],
        version=1, display_order=q['n'], statement=q['statement'], state='DRAFT')]
    rows['math_subproblems'] = [dict(id=ids['leaf'], problem_id=ids['problem'], leaf_key=f"q{q['n']}",
        display_order=q['n'], statement='모든 하위 문항의 풀이과정을 포함하여 답안을 작성하시오.',
        response_format='FULL_SOLUTION', allow_common_rubric=False, essay_question_id=q['question_id'])]
    sources = []
    for role, key in [('QUESTION','question'), ('SCORING','scoring'), ('INTENT','intent'), ('SOLUTION','solution')]:
        name = 'konkuk-report' if q['slug']=='konkuk' and role in ['SCORING','INTENT'] else q['slug']
        digest = SOURCE_HASHES[name]
        sources.append(dict(id=uid('source:'+role), problem_id=ids['problem'], source_role=role,
            source_url='urn:sha256:'+digest, locator=f"PDF physical pages {','.join(map(str,q[key+'_pages']))}; Q{q['n']} only; {key}",
            provenance='OFFICIAL', verification='HASH_VERIFIED', content_sha256=digest))
    rows['math_source_artifacts'] = sources
    rows['math_evaluation_profiles'] = [dict(id=ids['profile'], logical_id=ids['profile'], version=1,
        scope='LEAF', leaf_id=ids['leaf'], response_format='FULL_SOLUTION', rubric_version='math-rubric-v1',
        required_dimensions=DIMENSIONS, reasoning_required=True, state='DRAFT')]
    rows['math_scoring_criteria'] = [dict(id=ids['criterion'] if i==0 else uid(f'criterion:{i}'),
        leaf_id=ids['leaf'], source_id=uid('source:SCORING'), criterion_key=f"official-q{q['n']}-{i+1}",
        description=body, official_points=points, rubric_dimensions=DIMENSIONS)
        for i,(points,body) in enumerate(q['criteria'])]
    rows['math_canonical_solutions'] = [dict(id=ids['solution'], leaf_id=ids['leaf'], source_id=uid('source:SOLUTION'),
        logical_id=ids['solution'], version=1, origin='OFFICIAL', state='DRAFT', body='\n'.join(q['steps']))]
    rows['math_canonical_solution_steps'] = [dict(id=uid(f'step:{i}'), solution_id=ids['solution'],
        position=i+1, body=body, criterion_id=None) for i,body in enumerate(q['steps'])]
    return dict(exam_id=EXAMS[q['slug']], essay_question_id=q['question_id'], ids=ids,
        state='DRAFT', publication_allowed=False, provider_allowed=False, existing_schema_rows=rows)


def literal(v):
    if v is None: return 'NULL'
    if isinstance(v, bool): return 'true' if v else 'false'
    if isinstance(v, int): return str(v)
    if isinstance(v, list): return 'ARRAY['+','.join(literal(x) for x in v)+']::text[]'
    return "'"+v.replace("'", "''")+"'"


def registration_sql(packages):
    statements = ["begin;", "set local lock_timeout='5s';", "set local statement_timeout='60s';"]
    for p in packages:
        statements.append("do $check$ begin if not exists(select 1 from public.essay_questions where id="+
            literal(p['essay_question_id'])+" and essay_exam_id="+literal(p['exam_id'])+
            ") then raise exception 'TASK20_REGISTRY_DRIFT'; end if; end $check$;")
        statements.append("do $collision$ begin if exists(select 1 from public.math_subproblems where essay_question_id="+
            literal(p['essay_question_id'])+" and id<>"+literal(p['ids']['leaf'])+
            ") then raise exception 'TASK20_QUESTION_ALREADY_BOUND'; end if; end $collision$;")
        for table, records in p['existing_schema_rows'].items():
            for row in records:
                # Existing IDs must be byte-equivalent; never overwrite or ignore drift.
                expected=json.dumps(row,ensure_ascii=False,separators=(',',':'))
                statements.append(f"do $row$ declare prior jsonb; begin select to_jsonb(t) into prior from public.{table} t where id={literal(row['id'])}; if prior is not null then if not prior @> {literal(expected)}::jsonb then raise exception 'TASK20_CONTENT_DRIFT'; end if; else insert into public.{table} ({','.join(row)}) values ({','.join(literal(v) for v in row.values())}); end if; end $row$;")
    return '\n'.join(statements+['commit;',''])


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--input',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--source',action='append',default=[],help='name=/absolute/path.pdf')
    args=parser.parse_args()
    assert '.local' in args.output.resolve().parts, 'PRIVATE_OUTPUT_REQUIRED'
    supplied=dict(s.split('=',1) for s in args.source)
    assert set(supplied)==set(SOURCE_HASHES), 'ALL_THREE_SOURCES_REQUIRED'
    for key,path in supplied.items():
        assert hashlib.sha256(Path(path).read_bytes()).hexdigest()==SOURCE_HASHES[key], 'SOURCE_HASH_DRIFT'
    qs=json.loads(args.input.read_text())['questions']
    assert sorted((q['slug'],q['n']) for q in qs)==[('konkuk',2),('konkuk',3),('konkuk',4),('kyunghee',1),('kyunghee',2),('kyunghee',3)]
    packages=[build(q) for q in qs]
    args.output.mkdir(parents=True,exist_ok=True)
    manifest=[]
    for q,p in zip(qs,packages):
        body=json.dumps(p,ensure_ascii=False,indent=2)+'\n'
        filename=f"{q['slug']}-q{q['n']}.private.json"
        (args.output/filename).write_text(body)
        manifest.append(dict(slug=q['slug'],question=q['n'],exam_id=p['exam_id'],question_id=p['essay_question_id'],
            leaf_id=p['ids']['leaf'],package_sha256=hashlib.sha256(body.encode()).hexdigest(),
            row_count=sum(map(len,p['existing_schema_rows'].values())),points=q['points'],state='DRAFT'))
    (args.output/'register.private.sql').write_text(registration_sql(packages))
    (args.output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps(dict(packages=len(packages),rows=sum(m['row_count'] for m in manifest),production_writes=0)))


if __name__=='__main__': main()
