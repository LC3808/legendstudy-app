"""Offline connection-only follow-up. No Provider, DB, network or PDF authoring.

Preserves the hash-pinned v1 official contents and student PDFs. Only internal
version IDs and source locators change. Public/student approval is never inferred.
"""
from __future__ import annotations
import argparse
import base64
import copy
import json
from pathlib import Path
import shutil
import uuid
from essay_lab.natural_expansion import digest, encode, require, validate_plan
from essay_lab.task20_priority_packages import registration_sql

VERSION = 'kau-connection-20261111-v1'
ROLES = {'QUESTION': 'problem', 'SCORING': 'rubric', 'INTENT': 'intent', 'SOLUTION': 'solution'}


def connect(package, exam, question):
    require(package['exam_id'] == exam['exam_id'] and package['essay_question_id'] == question['question_id'], 'IDENTITY_DRIFT')
    require(package['state'] == 'DRAFT' and not package['publication_allowed'], 'NOT_PRIVATE_DRAFT')
    original = package['existing_schema_rows']
    ids = {row['id']: str(uuid.uuid5(uuid.UUID(row['id']), VERSION)) for rows in original.values() for row in rows}
    def rekey(value):
        if isinstance(value, dict): return {k: rekey(v) for k, v in value.items()}
        if isinstance(value, list): return [rekey(v) for v in value]
        return ids.get(value, value) if isinstance(value, str) else value
    result = rekey(copy.deepcopy(package))
    for row in result['existing_schema_rows']['math_source_artifacts']:
        role = ROLES[row['source_role']]
        require(row['content_sha256'] == exam['source']['sha256'], 'SOURCE_HASH_DRIFT')
        # Existing Worker uses this suffix to bind the exact physical page array.
        row['locator'] = exam['source']['file'] + ' PDF ' + ','.join(map(str, question['evidence'][role])) + '쪽'
    order = ['math_problem_sets','math_problems','math_subproblems','math_source_artifacts',
             'math_evaluation_profiles','math_scoring_criteria','math_canonical_solutions','math_canonical_solution_steps']
    result['existing_schema_rows'] = {key:result['existing_schema_rows'][key] for key in order}
    result['connection_version'] = VERSION
    result['remaining'] = ['ISOLATED_CONNECTION_CONTRACT', 'OWNER_SOURCE_ISSUE_REVIEW', 'OWNER_PUBLICATION_APPROVAL']
    result['technical_ready'] = False  # A generated candidate alone proves no runtime result.
    result['provider_allowed'] = False
    # Reverse only the two authorized changes and demand byte-equivalent raw values.
    reverse = {v: k for k, v in ids.items()}
    def restore(value):
        if isinstance(value, dict): return {k: restore(v) for k, v in value.items()}
        if isinstance(value, list): return [restore(v) for v in value]
        return reverse.get(value, value) if isinstance(value, str) else value
    check = restore(result['existing_schema_rows'])
    for a, b in zip(check['math_source_artifacts'], original['math_source_artifacts']): a['locator'] = b['locator']
    require(check == original, 'OFFICIAL_CONTENT_CHANGED')
    return result


def validate_worker(payload, exam, question):
    require(payload['exam_id'] == exam['exam_id'] and payload['question_id'] == question['question_id'], 'WORKER_IDENTITY_DRIFT')
    require(digest((payload['manifest_text'] + payload['images_text']).encode()) == payload['sha256'], 'WORKER_DIGEST_DRIFT')
    refs = json.loads(payload['manifest_text']); images = json.loads(payload['images_text'])
    require(set(refs) == set(ROLES.values()), 'WORKER_ROLE_MISSING')
    require(1 <= len(images) <= 24 and len(payload['images_text'].encode()) < 1800000, 'WORKER_SIZE_LIMIT')
    require(len({i['physical_page'] for i in images}) == len(images), 'WORKER_DUPLICATE_PAGE')
    for role, ref in refs.items():
        require(ref['sha256'] == exam['source']['sha256'] and ref['pages'] == question['evidence'][role], 'WORKER_SOURCE_DRIFT')
        require(sorted(i['physical_page'] for i in images if role in i['roles']) == ref['pages'], 'WORKER_PAGE_DRIFT')
    for image in images:
        data = base64.b64decode(image['data'], validate=True)
        require(data.startswith(b'\x89PNG\r\n\x1a\n') and digest(data) == image['sha256'], 'WORKER_IMAGE_HASH_DRIFT')
        require(image['source_sha256'] == exam['source']['sha256'], 'WORKER_IMAGE_SOURCE_DRIFT')
    return len(images)


def prepare(plan, registry, previous, pinned, output):
    require('.local' in output.resolve().parts and not output.exists(), 'FRESH_PRIVATE_OUTPUT_REQUIRED')
    validate_plan(plan, registry)
    prior = {p['question_id']: p for p in pinned['packages']}
    packages = []; entries = []; pdfs = []; inputs = {}; records = []; worker_sql = []
    checked = []
    # Validate every pinned private artifact before producing a new directory.
    for exam in plan['exams']:
        pdf = next(p for p in pinned['problem_pdfs'] if p['exam_id'] == exam['exam_id'])
        path = previous / (exam['exam_id'] + '.problem-only.private.pdf')
        require(digest(path.read_bytes()) == pdf['sha256'], 'STUDENT_PDF_DRIFT')
        for question in exam['questions']:
            qid = question['question_id']; source = previous / (qid + '.package.private.json')
            require(digest(source.read_bytes()) == prior[qid]['package_sha256'], 'PINNED_PACKAGE_DRIFT')
            payload = json.loads((previous / (qid + '.worker.private.json')).read_text())
            validate_worker(payload, exam, question)
            checked.append((exam, question, connect(json.loads(source.read_text()), exam, question), payload))
    output.mkdir(parents=True)
    def lit(s): return "'" + s.replace("'", "''") + "'"
    for exam, question, package, payload in checked:
        qid = question['question_id']; body = encode(package)
        (output / (qid + '.package.private.json')).write_text(body)
        shutil.copyfile(previous / (qid + '.worker.private.json'), output / (qid + '.worker.private.json'))
        packages.append(package)
        records.append(dict(exam_id=exam['exam_id'], question_id=qid, leaf_id=package['ids']['leaf'],
                            state='DRAFT', publication_allowed=False, package_sha256=digest(body.encode()),
                            row_count=sum(map(len, package['existing_schema_rows'].values())),
                            student_pdf_pages=prior[qid]['student_pdf_pages'], official_content_preserved=True))
        values = ','.join(lit(payload[k]) + ('::jsonb' if k.endswith('_text') else '') for k in ['question_id','exam_id','manifest_text','images_text','sha256'])
        # Fail on conflicts rather than overwrite private official evidence.
        worker_sql.append('insert into math_private.task20_hanyang_source_pages(question_id,exam_id,manifest,images,content_sha256) values (' + values + ');')
        inputs[qid] = dict(examId=exam['exam_id'], mode='image')
    for exam in plan['exams']:
        selected = [r for r in records if r['exam_id'] == exam['exam_id']]
        pdf = next(p for p in pinned['problem_pdfs'] if p['exam_id'] == exam['exam_id'])
        shutil.copyfile(previous / (exam['exam_id'] + '.problem-only.private.pdf'), output / (exam['exam_id'] + '.problem-only.private.pdf'))
        entries.append(dict(examId=exam['exam_id'], universityId=exam['university_id'],
                            questionIds=[r['question_id'] for r in selected],
                            mathQuestions={r['question_id']:r['leaf_id'] for r in selected}, mode='math',
                            label=f"한국항공대 {exam['admission_year']} {exam['field_or_division']}", packageDigest=digest(encode(selected).encode())))
        for r in selected:
            pdfs.append(dict(examId=exam['exam_id'], questionId=r['question_id'], assetId=pdf['sha256'],
                             pageCount=pdf['pages'], startPage=r['student_pdf_pages'][0],
                             verification='HASH_VERIFIED', studentDisplay='OWNER_APPROVAL_REQUIRED', storageRead='NOT_APPLIED'))
    manifest = dict(version=VERSION, packages=records, student_pdfs=pinned['problem_pdfs'],
                    provider_calls=0, production_writes=0, official_content_preserved=True, publication_allowed=False)
    for name, data in [('manifest.json',manifest),('web-expansion-candidate.json',{'exams':entries}),('web-pdf-candidate.json',pdfs),('web-input-candidate.json',inputs)]:
        (output/name).write_text(encode(data))
    (output/'register-draft.private.sql').write_text(registration_sql(packages))
    (output/'worker-source.private.sql').write_text('-- Candidate INSERT only. No production approval. Existing table/helper required.\nbegin;\n'+'\n'.join(worker_sql)+'\ncommit;\n')
    return manifest


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    for name in ['plan','registry','previous','pinned','output']: parser.add_argument('--'+name,required=True,type=Path)
    args=parser.parse_args()
    result=prepare(json.loads(args.plan.read_text()),json.loads(args.registry.read_text()),args.previous,json.loads(args.pinned.read_text()),args.output)
    print(json.dumps(dict(packages=len(result['packages']),rows=sum(p['row_count'] for p in result['packages']),publication_allowed=False)))
