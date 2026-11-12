"""Prepare Ewha's 36 existing Essay 1.3 packages without calling a Provider.

Produces private source-bearing packages and guarded SQL only. Does not execute SQL,
change a runtime, or modify originals. Activation is a scoped extension of the
existing runtime_policy CASE; private material images require a compatible adapter.
"""
from __future__ import annotations
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path

APP = Path(__file__).resolve().parents[1]
REGIME = 'essay-v1.3/policy/54412ff80de2f20a2d72b711f7b0798c29d680e82b4621ae56ec2b07479de6c6'
AUTHORITY = 'Owner Ewha mock24 service connection and service-derived criteria approval 2026-11-12; Provider calls prohibited in this task'
ROLE = {'question': 'question', 'passage': 'shared_passage', 'exam_intent': 'intent', 'scoring_criteria': 'criteria'}


def dump(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def jsonb_text(value):
    """PostgreSQL JSONB text for this corpus (no floating-point values)."""
    if isinstance(value, dict):
        keys = sorted(value, key=lambda s: (len(s.encode('utf8')), s.encode('utf8')))
        return '{' + ', '.join(json.dumps(k, ensure_ascii=False) + ': ' + jsonb_text(value[k]) for k in keys) + '}'
    if isinstance(value, list):
        return '[' + ', '.join(map(jsonb_text, value)) + ']'
    if isinstance(value, float):
        raise ValueError('FLOAT_NOT_ALLOWED_IN_PINNED_PACKAGE')
    return json.dumps(value, ensure_ascii=False)


def digest(value):
    return hashlib.sha256(jsonb_text(value).encode()).hexdigest()


def prepare(app=APP):
    source = app / 'supabase/candidates/ewha_mock_public_20261112'
    private = app / '.local/ewha-mock-public-20261112'
    out = app / '.local/ewha-mock-public-20261112'
    public = app / 'supabase/candidates/ewha_mock_public_20261112'
    plan = json.loads((source / 'source-plan.json').read_text())
    receipts = {r['id']: r for r in json.loads((source / 'package-receipt.json').read_text())['questions']}
    registry = {'exams': []}; packages = {}; documents = {}; statuses = []
    for exam in plan['exams']:
        if not all((private / (q['id'] + '.essay.private.json')).exists() for q in exam['questions']):
            continue
        assert exam['kind'] == 'mock' and not exam['existingExam']
        name = f"{exam['year']} 모의 {exam['track']}"
        registry['exams'].append(dict(exam, name=name))
        package = dict(schema='essay-material-package-v1', exam_id=exam['examId'], university_id=exam['universityId'],
                       package_version=1, verification_status='VERIFIED_MANIFEST', review_scope='selected_questions',
                       exam_identity=dict(academic_year=exam['year'], exam_type=exam['kind'], track=exam['track'], title=name),
                       rights_status={}, questions=[])
        for role in ('problem', 'solution'):
            doc = exam[role]
            documents[doc['sha256']] = dict(sha256=doc['sha256'], title=doc['filename'], page_count=doc['pages'],
                                           object_key=doc['sha256'] + '.pdf', resource_id=None, role=role)
            package['rights_status'][doc['sha256']] = dict(providerTransmission='APPROVED', authority=AUTHORITY,
                studentUse='APPROVED_QUESTION_ONLY' if role == 'problem' else 'INTERNAL_ONLY')
        for q in exam['questions']:
            stored = json.loads((private / (q['id'] + '.essay.private.json')).read_text())
            cache = stored['cache']; assignment = stored['assignment']; receipt = receipts[q['id']]
            assert assignment['examId'] == exam['examId'] and assignment['sourceKey'] == q['sourceKey']
            assert not q['production_registry_exists']
            assert hashlib.sha256(json.dumps(cache, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()).hexdigest() == assignment['cacheSha256']
            page_map = {'question': q['evidence']['problem'], 'passage': q['evidence']['problem'],
                        'exam_intent': [g['page'] for g in receipt['rubric_geometry']], 'scoring_criteria': [g['page'] for g in receipt['rubric_geometry']]}
            by_id = {e['binding']['id']: e for e in cache['evidence']}
            refs = []
            for evidence in cache['evidence']:
                binding = evidence['binding']; pages = page_map[binding['role']]
                refs.append(dict(questionId=q['id'], sourceHash=binding['hash'], startPage=min(pages), endPage=max(pages),
                                 role=ROLE[binding['role']], verification='VERIFIED', evidenceText=evidence['text']))
            images = []; used = {r: 0 for r in page_map}
            for image in cache['official_images']:
                bound = by_id[image['evidence_ids'][0]]['binding']; role = bound['role']; pages = page_map[role]
                page = pages[used[role]]; used[role] += 1
                images.append(dict(sha256=image['sha256'], data=image['data'], sourceHash=bound['hash'], startPage=page, endPage=page))
            assert all(used[r] == len(page_map[r]) for r in ('question', 'exam_intent', 'scoring_criteria'))
            package['questions'].append(dict(question_id=q['id'], source_key=q['sourceKey'], source_page_references=refs,
                                            official_images=images))
            statuses.append(dict(exam_id=exam['examId'], question_id=q['id'], source_key=q['sourceKey'], year=exam['year'],
                track=exam['track'], number=q['number'], engine='Essay 1.3', images=len(images),
                criteria_literal_chars=len(next(e['text'] for e in cache['evidence'] if e['binding']['role']=='scoring_criteria')),
                expected_worker_adapter='official_images supports question,passage,exam_intent,scoring_criteria',
                production_applied=False, provider_calls=0))
        package['package_digest'] = digest(package)
        packages[exam['examId']] = package
    assert len(packages) == 4 and len(statuses) == 12 and len(documents) == 8
    dump(out/'essay-packages.private.json', packages)
    dump(out/'essay-registry.private.json', registry)
    dump(out/'essay-documents.private.json', documents)
    manifest = dict(exams=[dict(exam_id=e['examId'], name=e['name'], year=e['year'], track=e['track'],
        question_ids=[q['id'] for q in e['questions']], package_digest=packages[e['examId']]['package_digest'],
        evaluation_type='humanities') for e in registry['exams']], questions=statuses,
        counts=dict(exams=4, questions=12, documents=8, material_rows=16, provider_calls=0),
        production_applied=False, actual_ai_quality='NOT TESTED',
        required_operations=['8 private document rows; 4 material review rows; 4 revision rows',
          'existing essay_exam_private.runtime_policy(uuid) scoped CASE append: 4 exam IDs',
          'Worker Registry append with same 4 exams and 12 questions',
          'exact official-image adapter compatibility; no relabelling and no omitted rubric images'],
        publication_dependencies=['canonical Registry + question-only PDF access + existing WEB/APP route mapping',
          'current material adapter rejects official rubric/intent images; resolve before activating'])
    dump(public/'essay-manifest.json', manifest)
    return manifest


def sql_candidates(app, baseline_path):
    root = app/'.local/ewha-mock-public-20261112'; dest = app/'supabase/candidates/ewha_mock_public_20261112'
    packages = json.loads((root/'essay-packages.private.json').read_text())
    docs = json.loads((root/'essay-documents.private.json').read_text())
    baseline = json.loads(baseline_path.read_text())
    if isinstance(baseline, dict): baseline = baseline['functions']
    policy = next(f for f in baseline if f.get('proname', f.get('name')) == 'runtime_policy' and f.get('nspname', 'essay_exam_private') == 'essay_exam_private')
    reader = next(f for f in baseline if f.get('proname', f.get('name')) == 'essay_material_runtime_package')
    assert policy['definition'].count('else null::jsonb end') == 1, 'POLICY_FORMAT_CHANGED'
    lit = lambda s: "'" + str(s).replace("'", "''") + "'"
    js = lambda x: lit(json.dumps(x, ensure_ascii=False, separators=(',', ':'))) + '::jsonb'
    ids = ','.join(lit(e)+'::uuid' for e in packages)
    expected = {e: sorted(q['question_id'] for q in p['questions']) for e,p in packages.items()}
    hashes = ','.join(lit(h) for h in docs)
    checks = [
      ('exact_policy_baseline', f"md5(pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure))={lit(policy['md5'])}"),
      ('reader_unchanged', f"md5(pg_get_functiondef('public.essay_material_runtime_package(uuid,text)'::regprocedure))={lit(reader['md5'])}"),
      ('registry_exact',f"not exists(select 1 from jsonb_each({js(expected)}) e where (select coalesce(jsonb_agg(id::text order by id::text),'[]'::jsonb) from public.essay_questions where essay_exam_id=e.key::uuid) is distinct from e.value)"),
      ('review_absent',f"not exists(select 1 from essay_material_private.reviews where exam_id in ({ids}))"),
      ('revision_absent',f"not exists(select 1 from essay_material_private.revisions where exam_id in ({ids}))"),
      ('runtime_absent',f"not exists(select 1 from unnest(array[{ids}]) e where essay_exam_private.runtime_policy(e) is not null)"),
      ('no_student_runs',f"not exists(select 1 from essay_exam_private.runs where exam_id in ({ids}))"),
      ('private_bucket',"exists(select 1 from storage.buckets where id='essay-material-originals' and not public)"),
      ('documents_compatible',f"not exists(select 1 from jsonb_each({js(docs)}) d join essay_material_private.documents x on x.sha256=d.key where x.page_count is distinct from (d.value->>'page_count')::int or x.object_key is distinct from d.value->>'object_key')")]
    def select(rows): return 'select '+',\n'.join('('+v+') as '+k for k,v in rows)+';\n'
    (dest/'essay-precheck.sql').write_text(select(checks))
    start = "begin;set local lock_timeout='5s';set local statement_timeout='90s';select pg_advisory_xact_lock(4925261025);\n"
    apply = start + "do $ewha$ declare p jsonb;b jsonb;definition text;clause text;begin\n"
    apply += "if not ("+' and '.join('('+v+')' for k,v in checks)+") then raise exception 'EWHA_ESSAY_BASELINE_CHANGED';end if;\n"
    apply += f'perform 1 from public.essay_exams where id in ({ids}) order by id for update;\n'
    for h,d in docs.items():
        apply += f"insert into essay_material_private.documents(sha256,resource_id,title,page_count,object_key) values({lit(h)},null,{lit(d['title'])},{d['page_count']},{lit(d['object_key'])}) on conflict(sha256) do nothing;\n"
    apply += "definition:=pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure);\n"
    for eid,p in packages.items():
        apply += f'p:={js(p)};\n'
        apply += "if p->>'package_digest' is distinct from encode(sha256(convert_to((p-'package_digest')::text,'UTF8')),'hex') then raise exception 'PACKAGE_DIGEST_MISMATCH';end if;\n"
        body = dict(documents=sorted(p['rights_status']), runtimeApproval=dict(status='APPROVED',revision=1,
                     authority=AUTHORITY,question_ids=expected[eid]))
        apply += f"b:={js(body)}||jsonb_build_object('package',p);\n"
        apply += f"insert into essay_material_private.reviews(exam_id,revision,state,body,approval_requested) values({lit(eid)},1,'NEEDS_REVIEW',b,false);insert into essay_material_private.revisions(exam_id,revision,state,body) values({lit(eid)},1,'NEEDS_REVIEW',b);\n"
        policy_value = dict(regime=REGIME,package_digest=p['package_digest'],evaluation_type='humanities')
        apply += f"clause:=format(' when p_exam=%L::uuid then %L::jsonb ',{lit(eid)},{js(policy_value)}::text);\n"
        apply += "definition:=replace(definition,'else null::jsonb end',clause||'else null::jsonb end');\n"
    apply += 'execute definition;end $ewha$;commit;\n'
    (root/'essay-apply.private.sql').write_text('-- Private copyrighted source payload. Prepared only; do not apply until image adapter is ready.\n'+apply)
    post = [checks[1],checks[2],checks[-2],
      ('exact_reviews',f"(select count(*)=4 and bool_and(revision=1) from essay_material_private.reviews where exam_id in ({ids}))"),
      ('exact_revisions',f"(select count(*)=4 and bool_and(revision=1) from essay_material_private.revisions where exam_id in ({ids}))"),
      ('packages_readable',f"not exists(select 1 from jsonb_each({js(expected)}) e where (select jsonb_agg(q->>'question_id' order by q->>'question_id') from jsonb_array_elements(public.essay_material_runtime_package(e.key::uuid,essay_exam_private.runtime_policy(e.key::uuid)->>'package_digest')->'questions') q) is distinct from e.value)"),
      ('same_regime',f"(select bool_and(essay_exam_private.runtime_policy(e)->>'regime'={lit(REGIME)}) from unnest(array[{ids}]) e)")]
    (dest/'essay-postcheck.sql').write_text(select(post))
    (dest/'essay-public-readiness.sql').write_text('-- Existing whole-exam public service uses WEB scope, pinned runtime and Worker allowlist. Legacy Registry flags stay false.\n'+select(post))
    rollback = start + "do $ewha$ declare p jsonb;definition text;clause text;begin definition:=pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure);\n"
    for eid,p in packages.items():
        pv = dict(regime=REGIME,package_digest=p['package_digest'],evaluation_type='humanities')
        rollback += f"p:=essay_exam_private.runtime_policy({lit(eid)});if p is not null then if p is distinct from {js(pv)} then raise exception 'EWHA_ROLLBACK_POLICY_CHANGED';end if;clause:=format(' when p_exam=%L::uuid then %L::jsonb ',{lit(eid)},p::text);if position(clause in definition)=0 then raise exception 'EWHA_ROLLBACK_FORMAT_CHANGED';end if;definition:=replace(definition,clause,'');end if;\n"
    rollback += 'execute definition;end $ewha$;commit;\n'
    (dest/'essay-rollback.sql').write_text('-- Disable only these 4 runtime routes; retain all materials, revisions and student histories.\n'+rollback)
    return dict(material_rows_maximum=16, scoped_policy_entries=4, prechecks=len(checks),postchecks=len(post),production_writes=0)


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--app',type=Path,default=APP)
    parser.add_argument('--baseline-functions',type=Path);args=parser.parse_args()
    print(json.dumps(prepare(args.app)['counts']))
    if args.baseline_functions:print(json.dumps(sql_candidates(args.app,args.baseline_functions)))
