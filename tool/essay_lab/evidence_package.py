"""One-exam, offline evidence extraction. No DB/network/model access.

PDF body and figure output belong under ignored .local/, not public Git or DB.
The checked source snapshot is the immutable READ ONLY Production inventory.
"""
import argparse
import copy
import hashlib
import io
import json
import re
from importlib.metadata import version
from pathlib import Path

from .evidence_preview import ROLES, evidence_manifest

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tool/essay_lab/evidence/skku_2025_humanities1_source.json'
EXAM_ID = 'e15a43a8-5a50-501a-8a60-a632316240e8'
RESOURCE_ID = '796e82b5-1049-5005-ab6d-189b997ecd85'
PDF_SHA = '43371e05adaecbd324cadd2e28895d2b76e7d1598c9e857d1bd75aaa34d53e0d'
VERSIONS = {'pdfplumber': '0.11.9', 'pdfminer.six': '20251230',
            'pypdfium2': '5.13.0', 'Pillow': '12.3.0'}


def encode(value):
    return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + '\n').encode()


def digest(value):
    return hashlib.sha256(value).hexdigest()


def clean(text):
    lines = text.splitlines()
    return '\n'.join(line for line in lines
                     if not re.fullmatch(r'- \d+ -', line)
                     and line != '2025학년도 성균관대학교 선행학습 영향평가 자체평가보고서').strip()


def between(text, start, end=None):
    if text.count(start) != 1:
        raise ValueError('Section anchor missing/ambiguous: ' + start)
    text = text.split(start, 1)[1]
    if end:
        if text.count(end) != 1:
            raise ValueError('Section end missing/ambiguous: ' + end)
        text = text.split(end, 1)[0]
    return text.strip()


def validate_source(s):
    e = s['exam']
    if (e['id'] != EXAM_ID or e['admission_year'] != 2025
            or e['exam_key'] != 'regular-humanities-1'
            or s['university']['slug'] != 'sungkyunkwan'
            or e['university_id'] != s['university']['id']
            or not e['is_active'] or e['verification_status'] != 'verified'
            or e['provenance'] != 'official'
            or not all(s[k]['is_active'] for k in ('university', 'resource', 'content_item'))
            or s['resource']['id'] != RESOURCE_ID or s['pdf_sha256'] != PDF_SHA
            or s['resource']['content_item_id'] != s['content_item']['id']
            or s['source_post']['external_post_id'] != '1689'
            or s['transaction_read_only'] != 'on'):
        raise ValueError('Source identity/visibility/provenance mismatch')
    inventory = evidence_manifest(EXAM_ID, s['mappings'], [RESOURCE_ID])
    expected = {'question', 'passage', 'exam_intent', 'scoring_criteria',
                'example_answer', 'explanation'}
    if {k for k, v in inventory['resources_by_role'].items() if v} != expected:
        raise ValueError('Official verified inventory changed; inspect before rebuild')
    if len(s['mappings']) != 6:
        raise ValueError('Unexpected mapping scope')
    return inventory


def build(s, pdf_path):
    import pdfplumber
    s = copy.deepcopy(s)
    s['mappings'].sort(key=lambda m: (m['role'], m['resource_id']))
    inventory = validate_source(s)
    if digest(Path(pdf_path).read_bytes()) != PDF_SHA:
        raise ValueError('Source PDF hash mismatch')
    if any(version(k) != v for k, v in VERSIONS.items()):
        raise ValueError('Extraction dependencies changed; review/version required')
    with pdfplumber.open(pdf_path) as pdf:
        if len(pdf.pages) != 18:
            raise ValueError('Unexpected PDF length')
        # No curriculum tables/bibliography extraction. These15 pages contain the
        # requested question/intent/rubric/answer/solution sections only.
        needed = [1, 2, 3, 4, 6, 7, 8, 9, 10, 12, 13, 14, 16, 17, 18]
        pages = {n: clean(pdf.pages[n-1].extract_text()) for n in needed}
        # Right-hand rubric score column is separate from A-F descriptions.
        # Scores are taken from prompts, NOT assigned to grade A by reading order.
        rubric_pages = {n: clean(pdf.pages[n-1].crop(
            (0, 0, 487, pdf.pages[n-1].height)).extract_text()) for n in [7, 12, 13, 17]}
        image = pdf.pages[8].crop((130, 412, 476, 635)).to_image(resolution=144).original
        stream = io.BytesIO()
        image.save(stream, format='PNG', optimize=False)
        figure = stream.getvalue()
    mapped = {m['role']: m for m in s['mappings']}
    evidence = []

    def add(key, role, text, source_pages, section, asset=None):
        m = mapped[role]
        item = dict(id=key, role=role, provenance='official', verification_status='verified',
                    resource_id=RESOURCE_ID, text=text, text_sha256=digest(text.encode()),
                    source_locator=f"PDF pages {','.join(map(str, source_pages))}; section {section}",
                    pdf_pages=source_pages, printed_pages=[p+122 for p in source_pages],
                    source_mapping_locator=m['source_locator'],
                    official_source_url=m['official_source_url'])
        if asset:
            item['asset'] = asset
        evidence.append(item)
        return key

    questions = []
    for q, first, intent, solution, criterion, answer, last in [
            (1, 1, 4, 6, 7, 8, 8), (2, 9, 10, 12, 12, 13, 13),
            (3, 14, 14, 16, 17, 17, 18)]:
        label = f'문제 {q}'
        prefix = f'q{q}'
        end = '\n<제시문 1>\n' if q == 1 else '\n<자료 1>' if q == 2 else '\n3. 출제 의도'
        prompt = between(pages[first], '2. 문항 및 자료\n', end)
        ids = {'prompt': add(prefix+'-prompt', 'question', prompt, [first], label)}
        points = re.findall(r'\((\d+)점\)', prompt)
        if len(points) != 1:
            raise ValueError('Question score missing/ambiguous')
        intent_text = between(pages[intent], '3. 출제 의도\n', '\n4. 출제 근거')
        ids['exam_intent'] = add(prefix+'-intent', 'exam_intent', intent_text, [intent], label+'/출제 의도')
        soltext = '\n'.join(pages[n] for n in range(solution, criterion+1))
        soltext = between(soltext, '5. 문항 해설\n', '\n6. 채점 기준')
        ids['explanation'] = add(prefix+'-explanation', 'explanation', soltext,
                                 list(range(solution, criterion+1)), label+'/문항 해설')
        crittext = '\n'.join(rubric_pages[n] for n in range(criterion, answer+1) if n in rubric_pages)
        crittext = between(crittext, '6. 채점 기준\n', '\n7. 예시 답안' if q in (2, 3) else None)
        ids['scoring_criteria'] = add(prefix+'-criteria', 'scoring_criteria', crittext,
                                     [criterion, answer] if q == 2 else [criterion], label+'/채점 기준')
        ans = between('\n'.join(pages[n] for n in range(answer, last+1)), '7. 예시 답안\n')
        ids['example_answer'] = add(prefix+'-example-answer', 'example_answer', ans,
                                    list(range(answer, last+1)), label+'/예시 답안')
        # Offsets point to exact original rubric text; no new criteria or scores.
        criteria = []
        for match in re.finditer(r'(?:^[①②③]|^[A-F]:)', crittext, re.M):
            criteria.append({'criterion_id': prefix+'-'+match.group().strip(':'),
                             'evidence_id': ids['scoring_criteria'], 'start': match.start()})
        for i, c in enumerate(criteria):
            c['end'] = criteria[i+1]['start'] if i+1 < len(criteria) else len(crittext)
        questions.append(dict(question_label=label, structuring_provenance='legendstudy_derived',
                              max_score=int(points[0]), score_evidence_id=ids['prompt'],
                              grade_numeric_conversion=None, evidence=ids, criteria=criteria,
                              passage_refs=[], context_refs=[]))
    text = between('\n'.join(pages[n] for n in [1, 2, 3, 4]), '\n<제시문 1>\n', '\n3. 출제 의도')
    parts = re.split(r'\n<제시문 [234]>\n', text)
    if len(parts) != 4:
        raise ValueError('Passage boundaries changed')
    passage_pages = [[1], [2], [2, 3], [3, 4]]
    pids = [add(f'q1-passage-{i}', 'passage', part.strip(), passage_pages[i-1], f'제시문 {i}')
            for i, part in enumerate(parts, 1)]
    charttext = '<자료 1>' + between(pages[9], '\n<자료 1>')
    chart = add('q2-data-1', 'passage', charttext, [9], '자료 1 사회 활동 경험 / graph and footnote',
                dict(path='q2-data-1.png', sha256=digest(figure), mime_type='image/png',
                     bbox_pdf_points=[130, 412, 476, 635], resolution_dpi=144,
                     requirement='Original figure required; no inferred numeric bar values'))
    table = add('q2-data-2', 'passage', pages[10].split('\n3. 출제 의도')[0], [10], '자료 2 사회지표 및 주3-7')
    evidence[-1]['table_columns'] = ['항목', '회원국 평균', 'A국', 'B국', 'C국']
    evidence[-1]['table_structure_provenance'] = 'legendstudy_derived'
    questions[1]['context_refs'] = ['q1-prompt']
    questions[2]['context_refs'] = ['q1-prompt', 'q2-prompt']
    questions[0]['passage_refs'] = pids
    questions[1]['passage_refs'] = pids + [chart, table]
    questions[2]['passage_refs'] = pids + [chart, table]
    for q in questions:
        q['completeness'] = 'HIGH'
        q['requires_figure'] = q['question_label'] != '문제 1'
    package = dict(schema_version='1', generated_at=s['snapshot_at'],
                   generated_at_semantics='Immutable source snapshot time; not rebuild clock',
                   exam={**s['exam'], 'university_name': s['university']['name']},
                   sources=[dict(resource=s['resource'], content_item=s['content_item'],
                                 source_post=s['source_post'], pdf_sha256=PDF_SHA, pdf_pages=18)],
                   production_inventory=inventory, questions=questions,
                   evidence=sorted(evidence, key=lambda e: e['id']),
                   review_queue=[], extraction=dict(dependencies=VERSIONS,
                   policy='Verbatim extraction; only headers/footers removed; rubric score column separated; no summaries',
                   body_distribution='private-local-only', source_snapshot_sha256=digest(encode(s))),
                   evidence_content_counts=dict(official=len(evidence), legendstudy_derived=0, ai_generated=0),
                   structure_counts=dict(legendstudy_derived_questions=len(questions), legendstudy_derived_table_layouts=1),
                   absent_roles=inventory['missing_roles'])
    package['evidence_package_version'] = 'v1-sha256:'+digest(encode(package))
    validate(package)
    return package, figure


def question_context(package, label):
    """Resolve all shared passages exactly once, not just the question's page."""
    q = next(q for q in package['questions'] if q['question_label'] == label)
    ids = set(q['evidence'].values()) | set(q['passage_refs']) | set(q['context_refs'])
    return {'question': q, 'evidence': [e for e in package['evidence'] if e['id'] in ids]}


def validate(p):
    unsigned = {k: v for k, v in p.items() if k != 'evidence_package_version'}
    if p['evidence_package_version'] != 'v1-sha256:'+digest(encode(unsigned)):
        raise ValueError('Package integrity mismatch')
    evidence = {e['id']: e for e in p['evidence']}
    if len(evidence) != len(p['evidence']):
        raise ValueError('Duplicate evidence IDs')
    for e in evidence.values():
        if (e['provenance'] != 'official' or e['verification_status'] != 'verified'
                or e['resource_id'] != RESOURCE_ID or not e['source_locator']
                or not e['source_mapping_locator'] or not e['text'].strip()
                or e['text_sha256'] != digest(e['text'].encode())
                or any(n < 1 or n > 18 for n in e['pdf_pages'])):
            raise ValueError('Invalid evidence provenance/text/locator')
    for q in p['questions']:
        for ref in list(q['evidence'].values()) + q['passage_refs'] + q['context_refs']:
            if ref not in evidence:
                raise ValueError('Dangling evidence reference')
        for c in q['criteria']:
            text = evidence[c['evidence_id']]['text']
            if not 0 <= c['start'] < c['end'] <= len(text):
                raise ValueError('Criterion offset invalid')
    return True


def manifest(p, figure):
    """Public handoff metadata. Never includes extracted source body."""
    sizes = {q['question_label']: sum(len(e['text']) for e in question_context(p, q['question_label'])['evidence'])
             for q in p['questions']}
    texts = [e['text'] for e in p['evidence']]
    return dict(evidence_package_version=p['evidence_package_version'],
                package_sha256=digest(encode(p)), generated_at=p['generated_at'],
                essay_exam_id=p['exam']['id'], resource_id=RESOURCE_ID, pdf_sha256=PDF_SHA,
                source_mapping_count=6, evidence_items=len(texts),
                derived_content_items=0, derived_question_structures=3, derived_table_layouts=1, ai_generated_items=0,
                total_unique_text_characters=sum(map(len, texts)), characters_by_question=sizes,
                repeated_exact_evidence_blocks=len(texts)-len(set(texts)),
                shared_text_saved_characters=sum(sizes.values())-sum(map(len, texts)),
                package_json_bytes=len(encode(p)), figure_bytes=len(figure), figure_sha256=digest(figure),
                questions=[dict(question_label=q['question_label'], max_score=q['max_score'],
                                completeness=q['completeness'], requires_figure=q['requires_figure'],
                                evidence_ids=sorted(set(q['evidence'].values()) | set(q['passage_refs']) | set(q['context_refs'])))
                           for q in p['questions']],
                locators=[dict(id=e['id'], role=e['role'], source_locator=e['source_locator'],
                               source_mapping_locator=e['source_mapping_locator'], text_sha256=e['text_sha256'])
                          for e in p['evidence']], review_queue=[])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pdf', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--check-manifest', type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if not output.is_relative_to(ROOT / '.local'):
        parser.error('Evidence body output must stay under ignored .local/')
    s = json.loads(SOURCE.read_text())
    p, fig = build(s, args.pdf)
    m = manifest(p, fig)
    if args.check_manifest and m != json.loads(args.check_manifest.read_text()):
        raise ValueError('Reviewed manifest drift')
    output.mkdir(parents=True, exist_ok=True)
    (output / 'package.json').write_bytes(encode(p))
    (output / 'q2-data-1.png').write_bytes(fig)
    (output / 'manifest.json').write_bytes(encode(m))
    print(json.dumps({k: v for k, v in m.items() if k not in ('locators', 'questions')}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
