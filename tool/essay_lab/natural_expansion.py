"""Offline natural-essay reconciliation and private review-package preparation.

No network/DB/Provider calls. Reuses existing Registry IDs and math-v1 tables.
Raw PDF text/images and SQL must stay under ignored .local. Output is DRAFT,
never a publication/readiness certificate. See wiki/essay-natural-expansion-20261111.md.
"""
from __future__ import annotations

import argparse
import base64
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import uuid

from essay_lab.task20_priority_packages import DIMENSIONS, registration_sql


class ReviewError(ValueError):
    pass


def require(condition, reason):
    if not condition:
        raise ReviewError(reason)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def encode(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + '\n'


def canonical_key(key):
    return key.replace('source:', 'source-', 1) if key.startswith('source:') else key


def reconcile(source_exams, registry):
    """Fail closed on key, context, label or ID ambiguity. Never infer new IDs."""
    by_exam = defaultdict(list)
    for row in registry:
        if row['exam_id']:
            by_exam[(row['university_id'], row['exam_key'])].append(row)
    results = []
    seen = set()
    for source in source_exams:
        key = (source['universityId'], canonical_key(source['key']))
        require(key not in seen, 'DUPLICATE_SOURCE_EXAM')
        seen.add(key)
        rows = by_exam.get(key, [])
        item = dict(source_key=source['key'], university_id=source['universityId'],
                    source_university_id=source['sourceUniversityId'], year=source['year'],
                    kind=source['kind'], track=source['track'], campus=source['campus'],
                    session=source['session'], source_hashes=source['sourceHashes'],
                    source_question_count=len(source['questions']),
                    publication_allowed=False, evaluation_ready=False)
        if not rows:
            results.append(dict(item, status='UNRESOLVED_NO_INSERT', questions=[]))
            continue
        errors = []
        ids = {r['exam_id'] for r in rows}
        if len(ids) != 1:
            errors.append('AMBIGUOUS_EXAM')
        for db_key, source_key in [('admission_year', 'year'), ('exam_kind', 'kind'),
                                   ('field_or_division', 'track'), ('campus', 'campus'),
                                   ('session_label', 'session')]:
            if any(r[db_key] != source[source_key] for r in rows):
                errors.append('CONTEXT_DRIFT:' + db_key)
        if source.get('dbExamId') and ids != {source['dbExamId']}:
            errors.append('EXAM_ID_DRIFT')
        questions = []
        used = set()
        for question in source['questions']:
            matches = [r for r in rows if r['label'] == question['label'] and r['question_id']]
            if len(matches) != 1:
                errors.append('AMBIGUOUS_OR_MISSING_LABEL:' + question['label'])
                continue
            r = matches[0]
            if r['question_id'] in used:
                errors.append('DUPLICATE_QUESTION')
            used.add(r['question_id'])
            if question.get('dbQuestionId') and question['dbQuestionId'] != r['question_id']:
                errors.append('QUESTION_ID_DRIFT')
            questions.append(dict(question_id=r['question_id'], label=r['label'],
                                  display_order=r['display_order'],
                                  existing_math_bindings=r['math_bindings']))
        if len(used) != len([r for r in rows if r['question_id']]):
            errors.append('QUESTION_SET_DRIFT')
        # Ordinals are read from DB, not fabricated from source array positions.
        if len({q['display_order'] for q in questions}) != len(questions):
            errors.append('DUPLICATE_QUESTION_ORDER')
        results.append(dict(item, status='HOLD_IDENTITY_DRIFT' if errors else 'EXISTING_IDS_MATCHED',
                            errors=errors, exam_ids=sorted(ids), questions=questions))
    return results


def validate_plan(plan, registry):
    require(plan['publication_allowed'] is False, 'PUBLICATION_FORBIDDEN')
    require(plan['provider_allowed'] is False, 'PROVIDER_FORBIDDEN')
    selected = set()
    for exam in plan['exams']:
        require(exam['university_slug'] == 'kau', 'SCOPE_NOT_KAU')
        rows = [r for r in registry if r['exam_id'] == exam['exam_id']]
        require(len(rows) == len(exam['questions']), 'EXAM_QUESTION_SET_DRIFT')
        for q in exam['questions']:
            require(q['question_id'] not in selected, 'DUPLICATE_QUESTION')
            selected.add(q['question_id'])
            matches = [r for r in rows if r['question_id'] == q['question_id']]
            require(len(matches) == 1, 'QUESTION_ID_DRIFT')
            r = matches[0]
            for key in ['university_id', 'admission_year', 'exam_kind', 'field_or_division',
                        'session_label', 'campus', 'exam_key']:
                require(r[key] == exam[key], 'EXAM_CONTEXT_DRIFT:' + key)
            require(r['slug'] == exam['university_slug'], 'UNIVERSITY_DRIFT')
            require(r['label'] == q['label'] and r['display_order'] == q['display_order'], 'QUESTION_ORDER_DRIFT')
            require(not r['math_bindings'], 'QUESTION_ALREADY_BOUND')
            require(not r['is_active'] and not r['is_published'], 'EXISTING_PUBLICATION_REQUIRES_REVIEW')
            require(q['hold'] is False, 'OWNER_HOLD')
            require(set(q['evidence']) == {'problem', 'intent', 'rubric', 'solution'}, 'SOURCE_ROLE_MISSING')
            for pages in q['evidence'].values():
                require(pages and pages == sorted(set(pages)), 'INVALID_PAGE_ORDER')
                require(all(isinstance(p, int) and 1 <= p <= exam['source']['pages'] for p in pages), 'PAGE_OUT_OF_BOUNDS')
            crops = q['student_pages']
            require([p['physical_page'] for p in crops] == q['evidence']['problem'], 'STUDENT_PAGE_DRIFT')
            for page in crops:
                require(page['crop_bottom_pt'] is None or page['crop_bottom_pt'] > 0, 'INVALID_CROP')


def build_review_package(exam, q, page_text):
    """Existing math-v1 schema; raw extraction is retained only in private DRAFT."""
    uid = lambda key: str(uuid.uuid5(uuid.UUID(q['question_id']), 'natural-expansion-20261111-connection-source-v1:' + key))
    rows = {}
    def add(table, key, **values):
        rows.setdefault('math_' + table, []).append(dict(id=uid(key), **values))
    def version(key):
        return dict(logical_id=uid(key), version=1, state='DRAFT')
    def text(role):
        return '\n\n'.join(page_text[p - 1].replace('\x00', ' ') for p in q['evidence'][role])
    add('problem_sets', 'set', essay_exam_id=exam['exam_id'],
        label=f"한국항공대 {exam['admission_year']} {exam['field_or_division']} {q['label']}", **version('set'))
    add('problems', 'problem', problem_set_id=uid('set'), display_order=q['display_order'], statement=text('problem'), **version('problem'))
    add('subproblems', 'leaf', problem_id=uid('problem'), leaf_key='q' + str(q['number']),
        display_order=q['display_order'], statement='모든 소문항의 풀이 과정을 포함하세요.',
        response_format='FULL_SOLUTION', allow_common_rubric=False, essay_question_id=q['question_id'])
    for role, key in [('QUESTION', 'problem'), ('SCORING', 'rubric'), ('INTENT', 'intent'), ('SOLUTION', 'solution')]:
        add('source_artifacts', role, problem_id=uid('problem'), source_role=role,
            source_url='urn:sha256:' + exam['source']['sha256'],
            locator=f"{exam['source']['file']} PDF {','.join(map(str, q['evidence'][key]))}쪽",
            provenance='OFFICIAL', verification='HASH_VERIFIED', content_sha256=exam['source']['sha256'])
    add('evaluation_profiles', 'profile', scope='LEAF', leaf_id=uid('leaf'),
        response_format='FULL_SOLUTION', rubric_version='math-rubric-v1',
        required_dimensions=DIMENSIONS, reasoning_required=True, **version('profile'))
    for i, p in enumerate(q['evidence']['rubric']):
        add('scoring_criteria', f'criterion:{i}', leaf_id=uid('leaf'), source_id=uid('SCORING'),
            criterion_key=f"q{q['number']}-official-page-{p}", description=page_text[p - 1],
            official_points=None, rubric_dimensions=DIMENSIONS)
    add('canonical_solutions', 'solution', leaf_id=uid('leaf'), source_id=uid('SOLUTION'),
        origin='OFFICIAL', body=text('solution'), **version('solution'))
    # Source page ordering only. These are not inferred pedagogical solution steps.
    for i, p in enumerate(q['evidence']['solution']):
        add('canonical_solution_steps', f'step:{i}', solution_id=uid('solution'), position=i + 1,
            body=page_text[p - 1], criterion_id=None)
    raw = encode(rows)
    return dict(exam_id=exam['exam_id'], essay_question_id=q['question_id'],
                ids={'leaf': uid('leaf')}, existing_schema_rows=rows,
                state='DRAFT', publication_allowed=False, provider_allowed=False,
                extraction_has_private_glyphs=any(0xE000 <= ord(c) <= 0xF8FF for c in raw),
                technical_ready=False,
                remaining=['EXISTING_WORKER_SOURCE_CONTRACT', 'LOCAL_DB_REHEARSAL',
                           'WEB_APP_CONNECTION_CONTRACT', 'OWNER_SOURCE_ISSUE_REVIEW',
                           'OWNER_PUBLICATION_APPROVAL'])


def student_crop_limit(spec, height, heading_tops):
    limit = spec['crop_bottom_pt'] or height
    if heading_tops:
        require(spec['crop_bottom_pt'] is not None and limit < min(heading_tops) - 2,
                'ANSWER_LEAK_CROP_REQUIRED')
    require(0 < limit <= height, 'CROP_OUT_OF_BOUNDS')
    return limit


def prepare(plan, registry, source_paths, output):
    import pymupdf
    require('.local' in output.resolve().parts, 'PRIVATE_OUTPUT_REQUIRED')
    require(not output.exists(), 'FRESH_PRIVATE_OUTPUT_REQUIRED')
    validate_plan(plan, registry)
    # Preflight all original hashes before producing any artifacts.
    for exam in plan['exams']:
        src = exam['source']; path = Path(source_paths[src['sha256']])
        require(digest(path.read_bytes()) == src['sha256'], 'SOURCE_HASH_DRIFT')
        with pymupdf.open(path) as doc:
            require(len(doc) == src['pages'], 'SOURCE_PAGE_COUNT_DRIFT')
            for q in exam['questions']:
                for spec in q['student_pages']:
                    page = doc[spec['physical_page'] - 1]
                    student_crop_limit(spec, page.rect.height,
                                       [h.y0 for h in page.search_for('3. 출제 의도')])
    output.mkdir(parents=True, exist_ok=True)
    packages, manifest, pdfs, payloads = [], [], [], []
    for exam in plan['exams']:
        src = exam['source']
        with pymupdf.open(source_paths[src['sha256']]) as doc:
            texts = [p.get_text() for p in doc]
            student = pymupdf.open()
            for q in exam['questions']:
                first_student_page = len(student) + 1
                for spec in q['student_pages']:
                    page = doc[spec['physical_page'] - 1]
                    rect = page.rect
                    # All source pages containing an intent heading require explicit reviewed crop.
                    limit = student_crop_limit(spec, rect.height,
                                               [h.y0 for h in page.search_for('3. 출제 의도')])
                    clip = pymupdf.Rect(0, 0, rect.width, limit)
                    pix = page.get_pixmap(matrix=pymupdf.Matrix(2, 2), clip=clip)
                    new = student.new_page(width=rect.width, height=limit)
                    # Raster-only derivative: hidden source text/answers are never embedded.
                    new.insert_image(new.rect, stream=pix.tobytes('png'))
                refs = {role: dict(file=src['file'], sha256=src['sha256'], pages=pages)
                        for role, pages in q['evidence'].items()}
                images = []
                for number in sorted({p for pages in q['evidence'].values() for p in pages}):
                    page = doc[number - 1]
                    scale = 1000 / max(page.rect.width, page.rect.height)
                    data = page.get_pixmap(matrix=pymupdf.Matrix(scale, scale), colorspace=pymupdf.csGRAY).tobytes('png')
                    images.append(dict(data=base64.b64encode(data).decode(), sha256=digest(data),
                                       source_sha256=src['sha256'], physical_page=number,
                                       roles=[role for role, pages in q['evidence'].items() if number in pages]))
                m = json.dumps(refs, ensure_ascii=False, sort_keys=True)
                s = json.dumps(images, sort_keys=True, separators=(',', ':'))
                require(len(s.encode()) < 1800000, 'WORKER_IMAGE_SIZE_LIMIT')
                payload = dict(question_id=q['question_id'], exam_id=exam['exam_id'],
                               manifest_text=m, images_text=s, sha256=digest((m + s).encode()))
                (output / (q['question_id'] + '.worker.private.json')).write_text(encode(payload))
                payloads.append(dict(question_id=q['question_id'], images=len(images),
                                     image_bytes=len(s.encode()), sha256=payload['sha256']))
                package = build_review_package(exam, q, texts)
                packages.append(package)
                body = encode(package)
                (output / (q['question_id'] + '.package.private.json')).write_text(body)
                manifest.append(dict(exam_id=exam['exam_id'], question_id=q['question_id'],
                                     leaf_id=package['ids']['leaf'], package_sha256=digest(body.encode()),
                                     row_count=sum(map(len, package['existing_schema_rows'].values())),
                                     state='DRAFT', technical_ready=False, publication_allowed=False,
                                     extraction_has_private_glyphs=package['extraction_has_private_glyphs'],
                                     student_pdf_pages=list(range(first_student_page, len(student) + 1))))
            target = output / (exam['exam_id'] + '.problem-only.private.pdf')
            student.save(target, deflate=True)
            count = len(student)
            student.close()
            pdfs.append(dict(exam_id=exam['exam_id'], pages=count, sha256=digest(target.read_bytes()),
                             upload_status='NOT_UPLOADED', review_status='RENDERED_NEEDS_VISUAL_CHECK',
                             raster_only=True))
    # Same additive DRAFT renderer as TASK20; never emits activation/publication/Provider SQL.
    (output / 'register-draft.private.sql').write_text(registration_sql(packages))
    report = dict(packages=manifest, problem_pdfs=pdfs, worker_payloads=payloads,
                  production_writes=0, provider_calls=0, publication_allowed=False)
    (output / 'manifest.json').write_text(encode(report))
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--registry', type=Path, required=True)
    parser.add_argument('--source-registry', type=Path)
    parser.add_argument('--plan', type=Path)
    parser.add_argument('--source-paths', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    registry = json.loads(args.registry.read_text())
    if args.plan:
        require(args.source_paths is not None, 'SOURCE_PATHS_REQUIRED')
        report = prepare(json.loads(args.plan.read_text()), registry,
                         json.loads(args.source_paths.read_text()), args.output)
        print(encode(dict(draft_packages=len(report['packages']), private_problem_pdfs=len(report['problem_pdfs']),
                          production_writes=0, provider_calls=0)))
    else:
        require(args.source_registry is not None, 'SOURCE_REGISTRY_REQUIRED')
        source = json.loads(args.source_registry.read_text())
        result = reconcile(source['exams'], registry)
        args.output.write_text(encode(dict(source_registry_version=source['version'],
                                          registry_sha256=digest(args.registry.read_bytes()),
                                          source_registry_sha256=digest(args.source_registry.read_bytes()),
                                          exams=result, publication_allowed=False)))
        print(encode(dict(exams=len(result), matched=sum(r['status'] == 'EXISTING_IDS_MATCHED' for r in result))))


if __name__ == '__main__':
    main()
