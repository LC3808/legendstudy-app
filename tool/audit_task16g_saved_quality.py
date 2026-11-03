#!/usr/bin/env python3
"""Read-only, offline audit of Owner-authorized TASK16-C/G private evidence.
No network, credentials, source edits or Provider calls. This records observations,
not a blanket quality PASS. Student originals/results remain outside Git.
"""
import argparse
import hashlib
import json
from fractions import Fraction
from math import comb
from pathlib import Path


def audit(c: Path, g: Path):
    def read(base, name):
        return json.loads((base / name).read_text())
    sources = read(c, 'manifest.json')
    for source in sources:
        assert hashlib.sha256(Path(source['path']).read_bytes()).hexdigest() == source['sha256']
    # Independent exact arithmetic, not an LLM judging its own output.
    prob = {n: Fraction(comb(4, n) * comb(3, 4-n), comb(7, 4)) for n in range(1, 5)}
    ew = sum(Fraction(k, n) * prob[n] / 4 for k in range(1, 5) for n in prob)
    pu = sum(prob[n] / 4 for k in range(1, 5) for n in prob if comb(k+n, k) <= 10)
    assert sum(prob.values()) == 1 and ew == Fraction(69, 56) and pu == Fraction(19, 28)
    boundary = [n for n in range(1, 201) if n < 100 and n > 25]
    assert (min(boundary), max(boundary)) == (26, 99)
    saved = {}
    for name in ['evaluate-1-result', 'evaluate-2-result', 'evaluate-2-alternative-result', 'evaluate-2-boundary-pinned-result']:
        result = read(c, name + '.json')['evaluation']
        saved[name] = {'steps': len(result['steps']), 'overall': result['overall'],
                       'error_categories': [v['category'] for v in result['errors']],
                       'hint_levels': [v['level'] for v in result['hints']]}
    current = read(g, 'quality-closeout.json')
    for run in current['raw_results']:
        v = run['result']
        saved[run['id']] = {'steps': len(v['steps']), 'criteria': len(v['criteria']),
                           'overall': v['overall'],
                           'error_categories': [e['category'] for e in v['errors']]}
    for row in current['raw_results']:
        v = read(g, 'quality-' + row['id'] + '.json')['result']
        assert len(v['tasks']) <= 5
        if not v['disclosed']:
            assert 'full_solution' not in v
    return {'source_hashes_unchanged': len(sources), 'provider_calls': 0,
            'q2_exact_check': {'expectation': str(ew), 'probability': str(pu), 'n': [26, 99]},
            'observed_ocr_error_examples': read(c, 'ocr-findings.json'),
            'accuracy_percentage': None, 'accuracy_reason': 'No independent full gold transcription',
            'saved_evaluations': saved,
            'mixed_preflight': read(g, 'quality-mixed-preflight.json'),
            'quality_release': 'HOLD'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--c-evidence', type=Path, required=True)
    parser.add_argument('--g-evidence', type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(audit(args.c_evidence, args.g_evidence), ensure_ascii=False, indent=2))
