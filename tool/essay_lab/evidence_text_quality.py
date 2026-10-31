"""Offline companion to batch_source_audit. Findings are REVIEW candidates, not fixes.

No network, database, evaluator or activation imports. Source text never appears in
the public report. Correction manifests and candidate packages stay in private output.
"""
import argparse
from collections import Counter
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import re


def sha(text):
    return hashlib.sha256(text.encode()).hexdigest()


def text_findings(text):
    findings = []
    def flag(code, line):
        findings.append(dict(code=code, line=line, status='MANUAL_PDF_REVIEW'))
    lines = text.splitlines()
    for i, line in enumerate(lines):
        before = lines[i-1].rstrip() if i else ''
        if before and re.match(r'^준거\s*\d+\s+[^•·Ÿ\s]', line):
            flag('C_MID_SENTENCE_LABEL', i+1)
        if before and re.search(r'[가-힣]$', before) and re.match(r'^[가-힣]', line):
            flag('D_POSSIBLE_SPLIT_WORD', i+1)
        if before and len(before) > 30 and not re.search(r'[.!?。]$', before) and line.strip():
            flag('ABNORMAL_LINE_BREAK', i+1)
        if re.search(r'[가-힣]\s+\d+\s*[~–-]\s*\d+\s+[가-힣]', line) or (
                before and re.fullmatch(r'\s*\d+\s*[~–-]\s*\d+\s*', line)
                and re.search(r'[가-힣]$', before)):
            flag('B_SCORE_IN_SENTENCE', i+1)
        for low, high in re.findall(r'(\d+)\s*[~–-]\s*(\d+)', line):
            if int(low) > int(high):
                flag('INVALID_SCORE_RANGE', i+1)
        if re.search(r'[가-힣]\s+[SABCDEF]\s+[가-힣]', line):
            flag('B_GRADE_IN_SENTENCE', i+1)
        if re.fullmatch(r'\s*(?:하위|문항|배점|채점 기준 배점|평가 영역 평가 항목 내용)\s*', line):
            flag('B_FLATTENED_TABLE', i+1)
    counts = Counter(re.sub(r'\s+', ' ', s).strip() for s in re.split(r'(?<=[.!?])\s+|\n', text))
    if any(n > 1 and len(s) >= 25 for s, n in counts.items()):
        flag('F_REPEATED_SENTENCE', 0)
    headings = [s.strip() for s in lines if re.match(r'^(?:\d+\.\s*)?(?:평가|채점)\s*기준\s*$', s)]
    if len(headings) != len(set(headings)):
        flag('DUPLICATE_CRITERION_HEADING', 0)
    groups = {}
    for q, sub in re.findall(r'\[문항\s*(\d+)\]의\s*\((\d+)\)', text):
        groups.setdefault(q, []).append(int(sub))
    if any(any(a > b for a, b in zip(seq, seq[1:])) for seq in groups.values()):
        flag('E_SUBQUESTION_ORDER', 0)
    return findings


def audit(package, required_roles=('question', 'criteria')):
    rows = []
    for question in package['questions']:
        refs = question['source_page_references']
        roles = {r['role'] for r in refs if r.get('evidenceText', '').strip()}
        missing = sorted(set(required_roles) - roles)
        if missing:
            rows.append(dict(question_id=question['question_id'], code='G_REQUIRED_MATERIAL_MISSING',
                             roles=missing, status='MANUAL_PDF_REVIEW'))
        for index, ref in enumerate(refs):
            for finding in text_findings(ref.get('evidenceText', '')):
                rows.append(dict(question_id=question['question_id'], reference_index=index,
                                 role=ref['role'], source_hash=ref['sourceHash'],
                                 page=ref['startPage'], **finding))
    return dict(exam_id=package['exam_id'], university_id=package.get('university_id'),
                package_version=package['package_version'], package_digest=package['package_digest'],
                findings=rows, note='Candidates only. Columns, omissions and semantic order require visual PDF review.')


def correction_candidate(package, manifest):
    """Fail closed on source drift; keep all unrelated evidence and identities unchanged."""
    if manifest['prior_digest'] != package['package_digest'] or not manifest.get('reviewer'):
        raise ValueError('UNREVIEWED_OR_WRONG_PRIOR')
    out = deepcopy(package)
    seen = set()
    for change in manifest['replacements']:
        key = (change['question_id'], change['reference_index'])
        if type(key[1]) is not int or key[1] < 0:
            raise ValueError('INVALID_REFERENCE_INDEX')
        if key in seen:
            raise ValueError('DUPLICATE_REPLACEMENT')
        seen.add(key)
        ref = next(q for q in out['questions'] if q['question_id'] == key[0])['source_page_references'][key[1]]
        if (sha(ref['evidenceText']) != change['before_sha256'] or ref['sourceHash'] != change['source_hash']
                or ref['startPage'] != change['page'] or not change.get('visual_pdf_verified')
                or not change.get('after_text', '').strip()):
            raise ValueError('SOURCE_OR_REVIEW_MISMATCH')
        ref['evidenceText'] = change['after_text']
        ref['verification'] = 'CANDIDATE_OWNER_REVIEW'
    if not seen:
        raise ValueError('EMPTY_CORRECTION')
    out['package_version'] = int(package['package_version']) + 1
    out['verification_status'] = 'CANDIDATE_OWNER_REVIEW'
    out.pop('package_digest')
    out['package_digest'] = sha(json.dumps(out, ensure_ascii=False, sort_keys=True, separators=(',', ':'), allow_nan=False))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packages', nargs='+', type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--require-role', action='append', dest='roles',
                        help='Reviewed package-specific required role; repeat as needed.')
    args = parser.parse_args()
    report = [audit(json.loads(p.read_text()), args.roles or ('question', 'criteria')) for p in args.packages]
    with args.output.open('x') as output:
        json.dump(report, output, ensure_ascii=False, indent=2)


if __name__ == '__main__':
    main()
