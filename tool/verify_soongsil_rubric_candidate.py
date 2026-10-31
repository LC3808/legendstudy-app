"""Read-only, PDF-coordinate audit of the 2026 humanities Q1 candidate.

Requires pdfplumber. No database/network access, approval, or artifact mutation.
Coordinates are manually checked against physical PDF page 6 (printed page 21).
Whitespace is ignored for cell comparison; punctuation and character order are not.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

import pdfplumber


def compact(text):
    return re.sub(r'\s+', '', text)


def differences(a, b, path=''):
    if isinstance(a, dict) and isinstance(b, dict):
        return [p for k in sorted(a.keys() | b.keys()) for p in (
            differences(a[k], b[k], path + '/' + k) if k in a and k in b
            else [path + '/' + k])]
    if isinstance(a, list) and isinstance(b, list) and len(a) == len(b):
        return [p for i, (x, y) in enumerate(zip(a, b))
                for p in differences(x, y, path + '/' + str(i))]
    return [] if a == b else [path]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pdf', type=Path, required=True)
    parser.add_argument('--artifacts', type=Path, required=True)
    args = parser.parse_args()
    read = lambda name: json.loads((args.artifacts / name).read_text())
    old = read('prior-v2.private.json')
    candidate = read('candidate-v3.private.json')
    rubric = read('structured-rubric.private.json')
    digest = hashlib.sha256(args.pdf.read_bytes()).hexdigest()
    assert digest == rubric['source']['pdf_hash']
    assert digest == 'dd97f6d0b480955f80fd2568c3b59bd8e04f2e918895ce7061e1cb2e143441ff'
    assert old['exam_id'] == candidate['exam_id'] == '0d4fcaa4-2be0-52a0-9590-c61f65c5f199'
    assert old['questions'][0]['question_id'] == rubric['question_id'] == '5df22bef-ce93-5333-9334-023ba98468e4'
    scores = ['8~10', '6~7', '4~5', '1~3', '0']
    assert [r['score'] for r in rubric['rows']] == scores
    # Left description column and right score column independently, in visual row order.
    bounds = [(137, 170), (170, 216), (216, 236), (236, 256), (256, 275)]
    with pdfplumber.open(args.pdf) as pdf:
        identity = compact(pdf.pages[0].extract_text())
        assert '2026학년도숭실대학교' in identity and '인문계열/문제1(1-1)' in identity
        page = pdf.pages[5]
        for row, (top, bottom) in zip(rubric['rows'], bounds):
            description = page.crop((85, top, 423, bottom)).extract_text() or ''
            score = page.crop((428, top, 465, bottom)).extract_text() or ''
            assert compact(description) == compact(row['description']), (row['score'], description)
            assert compact(score) == row['score'], score
        bonus = page.crop((85, 280, 465, 300)).extract_text() or ''
        assert compact(bonus) == compact(rubric['bonus'])
        assert old['questions'][0]['source_page_references'][4]['evidenceText'] in page.extract_text()
    expected = '채점 기준 | 배점\n' + '\n'.join(
        f"{r['description']} | {r['score']}" for r in rubric['rows']) + '\n' + rubric['bonus']
    assert candidate['questions'][0]['source_page_references'][4]['evidenceText'] == expected
    changed = differences(old, candidate)
    assert set(changed) == {'/package_digest', '/package_version', '/verification_status',
                          '/questions/0/source_page_references/4/evidenceText',
                          '/questions/0/source_page_references/4/verification'}
    body = {k: v for k, v in candidate.items() if k != 'package_digest'}
    local_hash = hashlib.sha256(json.dumps(body, ensure_ascii=False, sort_keys=True,
                                          separators=(',', ':'), allow_nan=False).encode()).hexdigest()
    assert local_hash == candidate['package_digest']
    print(json.dumps(dict(pdf='PASS', five_rows='PASS', bonus='PASS', identity='PASS',
                         field_scope='PASS', changed_fields=changed,
                         candidate_digest=local_hash,
                         digest_format='LOCAL_SORTED_COMPACT_JSON_NOT_POSTGRES_JSONB',
                         activation='NOT_AUTHORIZED; production baseline must be checked separately'),
                     ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
