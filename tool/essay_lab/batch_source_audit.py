"""Audit every existing question's local official sources; never grant activation.

This supplements batch_inventory, not the evaluator. PDF page mappings with
NEEDS_REVIEW remain unreviewed even when extraction succeeds. Original files and
question identities are never changed; extracted source text stays in private output.
"""
import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
from io import BytesIO
from pypdf import PdfReader


def in_requested_year_scope(row):
    year = row['admission_year']
    return 2022 <= year <= 2026 or (year == 2027 and row['exam_kind'] == 'mock')


def extract_source(path):
    try:
        raw = Path(path).read_bytes()
        reader = PdfReader(BytesIO(raw))
        pages = [page.extract_text(extraction_mode='layout') for page in reader.pages]
        return {'sha256': hashlib.sha256(raw).hexdigest(), 'pages': pages}
    except Exception as error:
        # A malformed PDF must not prevent auditing the other universities.
        # Keep this source failed; extraction errors never grant readiness.
        return {'error': type(error).__name__}


def evidence_check(ref, source):
    problems = []
    if source.get('error'):
        return {'role': ref['role'], 'problems': ['SOURCE_READ_FAILED'], 'text': ''}
    if source['sha256'] != ref.get('source_hash'):
        problems.append('SOURCE_HASH_MISMATCH')
    interval = ref.get('pages')
    if not (isinstance(interval, list) and len(interval) == 2
            and all(type(n) is int for n in interval)
            and 1 <= interval[0] <= interval[1] <= len(source['pages'])):
        return {'role': ref['role'], 'problems': problems + ['INVALID_PAGE_RANGE'], 'text': ''}
    text = '\n'.join(source['pages'][interval[0]-1:interval[1]]).strip()
    if not text:
        problems.append('EMPTY_PAGE_TEXT')
    pua = sum(0xE000 <= ord(c) <= 0xF8FF or 0xF0000 <= ord(c) <= 0xFFFFD
              or 0x100000 <= ord(c) <= 0x10FFFD for c in text)
    if pua or '\ufffd' in text:
        problems.append('GLYPH_REVIEW_REQUIRED')
    return {'role': ref['role'], 'source_hash': ref.get('source_hash'),
            'pages': interval, 'characters': len(text), 'pua_count': pua,
            'problems': problems, 'text': text}


def audit(rows, mapped, sources):
    output = []
    for row in rows:
        refs = row.get('evidence', [])
        checks = [evidence_check(ref, sources.get(ref.get('source_path'), {'error': 'Missing'}))
                  for ref in refs]
        problems = sorted({p for check in checks for p in check['problems']})
        roles = {check['role'] for check in checks if not check['problems']}
        for role in ('question', 'intent', 'criteria'):
            if role not in roles:
                problems.append('MISSING_CLEAN_' + role.upper())
        profile = mapped.get(row['question_id'])
        if not profile:
            problems.append('PROFILE_NOT_INHERITED')
        scope = in_requested_year_scope(row)
        if not scope:
            problems.append('OUTSIDE_REQUESTED_YEAR_SCOPE_PRESERVED')
        output.append({'university': row['university'], 'exam_id': row['exam_id'],
            'question_id': row['question_id'], 'year': row['admission_year'],
            'exam_kind': row['exam_kind'], 'track': row['field_or_division'],
            'in_requested_year_scope': scope,
            'profile': ({k: profile[k] for k in ('profile_id', 'profile_version', 'profile_digest')}
                        if profile else None),
            'source_checks': checks, 'extraction_checks_pass': not problems,
            'problems': problems, 'semantic_review': 'NOT_GRANTED_BY_EXTRACTION',
            'runtime_input_pass': False, 'activation_candidate': False})
    return output


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--profiles-root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    rows = json.loads((args.profiles_root / 'question-readiness-512.json').read_text())
    inherited = json.loads((args.profiles_root / 'reference-recovery-20261023/base-inheritance-512.json').read_text())
    mapped = {x['question_id']: x for x in inherited['mapped']}
    assert len(rows) == len({x['question_id'] for x in rows})
    paths = sorted({r['source_path'] for q in rows for r in q.get('evidence', []) if r.get('source_path')})
    with ThreadPoolExecutor(max_workers=4) as pool:
        sources = dict(zip(paths, pool.map(extract_source, paths)))
    output = audit(rows, mapped, sources)
    summary = {}
    groups = {}
    for row in output:
        profile = row['profile'] or {}
        key = (row['university'], row['year'], row['exam_kind'], row['track'],
               profile.get('profile_id'), profile.get('profile_version'))
        groups.setdefault(key, []).append(row)
    for university in sorted({r['university'] for r in output}):
        group = [r for r in output if r['university'] == university]
        summary[university] = {'questions': len(group),
            'requested_year_scope': sum(r['in_requested_year_scope'] for r in group),
            'extraction_checks_pass': sum(r['extraction_checks_pass'] for r in group),
            'problems': dict(Counter(p for r in group for p in r['problems']))}
    manifests = [dict(university=k[0], year=k[1], exam_kind=k[2], track=k[3],
        profile_id=k[4], profile_version=k[5], question_ids=[r['question_id'] for r in group],
        exam_ids=sorted({r['exam_id'] for r in group}), activation_granted=False)
        for k, group in groups.items()]
    result = dict(questions=output, groups=manifests, by_university=summary,
        sources=len(sources), provider_calls=0, production_writes=0,
        limitation='Extraction PASS is not semantic review, runtime input PASS, FULL_EVALUATION or E2E.')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    # Official excerpts are private evidence; never commit this output wholesale.
    with args.output.open('w') as f:
        args.output.chmod(0o600)
        json.dump(result, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print(json.dumps({'sources': len(sources), 'groups': len(manifests),
                      'by_university': summary}, ensure_ascii=False))


if __name__ == '__main__':
    main()
