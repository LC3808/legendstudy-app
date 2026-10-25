"""Reuse local official files and existing IDs; generate metadata-only Owner SQL.

No network, uploads, evaluation, publication, or Production execution.
"""
import argparse
import hashlib
import importlib.util
import json
import re
import uuid
from pathlib import Path

NAMESPACE = uuid.uuid5(uuid.NAMESPACE_URL, 'https://github.com/LC3808/legendstudy-app/essay-source-registration/v1')
UNIVERSITY = 'b401cc24-dd17-575e-8ac6-0fd8c9c8405d'


def identity(title):
    year = int(title[:4])
    track = '사회계' if '사회' in title else '인문·체육계'
    session = '오전' if '(오전)' in title else '오후' if '(오후)' in title else None
    return year, 'mock' if '모의' in title else 'admission', track, session


def prepare(root, output, registration_tool):
    read = lambda name: json.loads((root / name).read_text())
    docs = read('continuous-source-pages.private.json')
    existing = read('continuous-khu-registry.private.json')
    resources = read('continuous-inventory.private.json')['resources']
    objects = {r['name'] for r in read('continuous-storage.private.json')}
    groups = {}
    for d in docs:
        groups.setdefault(identity(d['title']), []).append(d)
    rows, pending, baseline = [], [], []
    for (year, kind, track, session), sources in sorted(groups.items(), key=lambda x: str(x[0])):
        qdocs = [d for d in sources if '문제' in d['title']]
        sdocs = [d for d in sources if any(t in d['title'] for t in ('답안', '해설'))]
        if len(qdocs) != 1 or len(sdocs) != 1:
            raise ValueError(('AMBIGUOUS_SOURCE_PAIR', year, kind, track, session))
        qd, sd = qdocs[0], sdocs[0]
        # Count only explicit bracketed prompts, not Roman numerals in boilerplate.
        markers = set(re.findall(r'\[\s*논제\s*(III|II|I|Ⅲ|Ⅱ|Ⅰ|[123])\s*\]', '\n'.join(qd['pages'])))
        numbers = {dict(I=1, II=2, III=3, **{'Ⅰ': 1, 'Ⅱ': 2, 'Ⅲ': 3, '1': 1, '2': 2, '3': 3})[m] for m in markers}
        if numbers not in ({1, 2}, {1, 2, 3}):
            raise ValueError(('PROMPT_IDENTITIES_REQUIRED', qd['title'], numbers))
        matches = [e for e in existing if e['admission_year'] == year and e['exam_kind'] == kind
                   and ('사회' in (e['field_or_division'] or '') if track == '사회계' else '인문' in (e['field_or_division'] or ''))
                   and (session is None or session in (e['session_label'] or ''))]
        if len(matches) > 1:
            raise ValueError(('EXAM_IDENTITY_AMBIGUOUS', year, kind, track, session))
        e = matches[0] if matches else None
        key = 'source:' + hashlib.sha256(f'khu|{year}|{kind}|{track}|{session}|None'.encode()).hexdigest()
        eid = e['id'] if e else str(uuid.uuid5(NAMESPACE, 'exam/' + key))
        questions = e['questions'] if e else []
        if questions and len(questions) != len(numbers):
            raise ValueError(('PARENT_COUNT_MISMATCH', eid, len(questions), len(numbers)))
        qs = [dict(id=q['id'], sourceKey=q['question_key'], label=q['label'], order=q['display_order']) for q in questions]
        if not qs:
            qs = [dict(id=str(uuid.uuid5(NAMESPACE, 'question/' + key + ':' + str(n))), sourceKey=key + ':' + str(n), label=f'논제 {n}', order=n-1) for n in sorted(numbers)]
        documents = []
        for d in {d['sha256']: d for d in (qd, sd)}.values():
            matched = [r for r in resources if r['title'] == d['title']]
            if len(matched) > 1:
                raise ValueError(('RESOURCE_AMBIGUOUS', d['title']))
            documents.append(dict(title=d['title'], sha256=d['sha256'], local_path=d['path'], page_count=len(d['pages']), resource_id=matched[0]['id'] if matched else None, existing_storage=d['sha256']+'.pdf' in objects))
        row = dict(examId=eid, sourceKey=key, existingExam=e is not None, universityId=UNIVERSITY,
                   year=year, kind=kind, track=e['field_or_division'] if e else track,
                   session=e['session_label'] if e else session, campus=e['campus'] if e else None,
                   examKey=e['exam_key'] if e else 'source-'+key.removeprefix('source:'),
                   name=e['exam_name'] if e else f'{year}학년도 경희대학교 {"모의논술" if kind == "mock" else "수시논술"} {track} {session or ""}'.strip(),
                   sourceHashes=sorted({qd['sha256'], sd['sha256']}), questions=qs,
                   documents=documents, question_source_hash=qd['sha256'], official_source_hash=sd['sha256'],
                   parent_count=len(numbers), answer_unit_status='TEXT_PARENTS_READY' if len(numbers)==2 else 'PRESERVE_THREE_PARENTS_MAP_SUBANSWERS',
                   standby=False, provider_calls=0)
        rows.append(row)
        if not questions:
            pending.append(row)
            if e:
                baseline.append(e)
    output.mkdir(parents=True, exist_ok=True)
    (output/'connection-manifest.private.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2)+'\n')
    spec=importlib.util.spec_from_file_location('registration', registration_tool)
    module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    plan=dict(exams=pending)
    # Snapshot guard prevents modification of an existing partially registered exam.
    lit=lambda x: "'"+json.dumps(x,ensure_ascii=False,separators=(',',':')).replace("'","''")+"'::jsonb"
    guard=f"not exists(select 1 from jsonb_array_elements({lit(baseline)}) b where not exists(select 1 from public.essay_exams e where e.id=(b->>'id')::uuid and e.exam_key=b->>'exam_key' and e.exam_name=b->>'exam_name' and e.field_or_division=b->>'field_or_division' and e.is_active=(b->>'is_active')::boolean and e.verification_status=b->>'verification_status') or exists(select 1 from public.essay_questions q where q.essay_exam_id=(b->>'id')::uuid))"
    ids=lit([r['examId'] for r in pending if not r['existingExam']])
    new_guard=f"not exists(select 1 from public.essay_exams where id::text in (select jsonb_array_elements_text({ids})))"
    sql=module.sql_document(plan)
    sql=sql.replace('begin;\ndo $body$', "begin;\nset local lock_timeout='5s';\nlock table public.essay_exams,public.essay_questions in share row exclusive mode;\ndo $guard$ begin if not ("+guard+' and '+new_guard+") then raise exception 'KH_REGISTRY_BASELINE_CHANGED';end if;end $guard$;\ndo $body$",1)
    (output/'apply.sql').write_text(sql)
    (output/'precheck.sql').write_text(f'select ({guard}) existing_empty_exams_preserved, ({new_guard}) new_ids_absent;\n')
    checks=[]
    for row in pending:
        expected=lit(sorted(q['id'] for q in row['questions']))
        checks.append(f"((select jsonb_agg(id::text order by id::text) from public.essay_questions where essay_exam_id='{row['examId']}')={expected})")
    (output/'postcheck.sql').write_text('select '+ ' and '.join(checks)+' as exact_question_sets;\n')
    (output/'rollback.sql').write_text(module.rollback_document(plan))
    counts=dict(target_exams=len(rows), new_exams=sum(not r['existingExam'] for r in pending), existing_empty_exams=sum(r['existingExam'] for r in pending), new_questions=sum(len(r['questions']) for r in pending), production_applied=False, provider_calls=0)
    (output/'summary.json').write_text(json.dumps(counts,indent=2)+'\n')
    return counts


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('root',type=Path)
    parser.add_argument('output',type=Path)
    parser.add_argument('--registration-tool',type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(prepare(args.root,args.output,args.registration_tool)))
