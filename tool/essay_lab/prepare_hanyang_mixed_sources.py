"""Build exact Q1/Q2 source locators from retained official PDFs, never evaluate.

This is preparation only: no DB writes, approval, Provider calls or activation.
The original Registry IDs and complete parent answer units are preserved.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path


def prepare(source, output):
    docs = json.loads((source / 'source-pages.private.json').read_text())
    manifest = json.loads((source / 'manifest.json').read_text())
    by_hash = {d['sha256']: d for d in docs}
    rows = []
    for exam in manifest:
        if exam['track'] != '상경계열':
            continue
        question = by_hash[exam['question_source_hash']]
        official = by_hash[exam['official_source_hash']]
        for doc in (question, official):
            if hashlib.sha256(Path(doc['path']).read_bytes()).hexdigest() != doc['sha256']:
                raise ValueError('SOURCE_CHANGED: ' + doc['title'])
        qp = [t.replace('\x00', ' ') for t in question['pages']]
        sp = [t.replace('\x00', ' ') for t in official['pages']]
        qstart = [next(i for i, t in enumerate(qp) if re.search(r'\[문제\s*' + str(n), t)) for n in (1, 2)]
        # Modern official reports use individual cards; older guides use track headings.
        card = [i for i, t in enumerate(sp) if re.search(r'문항카드\s*[12]', t)]
        if len(card) == 2:
            sstart = card
        else:
            sstart = [0, next(i for i, t in enumerate(sp) if i > 0 and
                (re.search(r'상\s*경\s*계(?:\s*열)?\s*2번', t) or
                 re.search(r'상경계열\s*문제\s*2번', t)))]
        units = []
        for index, q in enumerate(sorted(exam['questions'], key=lambda q: q['order'])):
            qa, qb = qstart[index], qstart[index + 1] if index == 0 else len(qp)
            sa, sb = sstart[index], sstart[index + 1] if index == 0 else len(sp)
            section = '\n'.join(sp[sa:sb])
            criterion = re.search(r'(?m)^\s*(?:6\.\s*채점\s*기준|2\.\s*(?:분석적\s*평가|종합\s*평가)|1\.\s*평가의\s*내용)', section)
            if criterion is None:
                raise ValueError('CRITERIA_SECTION_REQUIRED: ' + official['title'])
            end = re.search(r'(?m)^\s*(?:7\.\s*예시\s*답안|3\.\s*출제\s*근거)', section[criterion.start():])
            criteria = section[criterion.start():criterion.start() + end.start() if end else len(section)]
            units.append({
                'question_id': q['id'], 'source_key': q['sourceKey'],
                'engine': 'essay' if index == 0 else 'math',
                'answer_unit': 'whole_parent_including_subquestions',
                'question': {'sha256': question['sha256'], 'first_page': qa + 1, 'last_page': qb, 'text': '\n'.join(qp[qa:qb])},
                'official': {'sha256': official['sha256'], 'first_page': sa + 1, 'last_page': sb,
                             'intent': section[:criterion.start()], 'criteria': criteria},
            })
        if len(units) != 2 or len({u['question_id'] for u in units}) != 2:
            raise ValueError('EXACT_TWO_PARENT_UNITS_REQUIRED')
        rows.append({'exam_id': exam['examId'], 'name': exam['name'], 'year': exam['year'],
                     'kind': exam['kind'], 'units': units,
                     'standby': False, 'blocking_contract': 'MIXED_MATH_SINGLE_RESERVATION_ROUTE_REQUIRED'})
    if len(rows) != 8:
        raise ValueError('EXACT_EIGHT_EXAMS_REQUIRED')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(rows, ensure_ascii=False, indent=2))
    print(json.dumps({'exams': len(rows), 'parent_units': sum(len(r['units']) for r in rows),
                      'provider_calls': 0, 'activation': False}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    prepare(args.source, args.output)
