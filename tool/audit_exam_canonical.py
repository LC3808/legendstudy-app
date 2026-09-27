#!/usr/bin/env python3
"""Offline evidence audit only. Never imported by a writer or connected to a DB.

Input contains source labels/keys and read-only Production projections. Output is
an Owner review artifact, never publication authority. Historical profiles outside
the explicitly inspected range fail closed. Raw subject labels are never rewritten.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path

SOCIAL = set('경제 동아시아사 사회문화 생활과윤리 세계사 세계지리 윤리와사상 정치와법 한국지리'.split())
SCIENCE = ('물리학', '화학', '생명과학', '지구과학')
CORE = {'국어', '수학', '영어', '한국사'}
ANSWER = {'answer', 'answer_explanation'}

def group_key(row):
    # Existing year/month/grade/type identity; only reviewed nominal-month
    # evidence is used in this report. The original identity is always retained.
    return (row['year'], row['audit_nominal_month'], row['grade'], row['exam_type'])

def comparison_label(label, row):
    label = (label or '').replace(' ', '')
    if row['grade'] == 3 and row['year'] >= 2021:
        if label.startswith('국어'): return '국어'
        if label.startswith('수학'): return '수학'
        if row['audit_nominal_month'] == 3 and label in SCIENCE: return label+'1'
    if row['grade'] == 1 or (row['grade'] == 2 and row['year'] >= 2026):
        return {'통합사회':'사회', '통합과학':'과학', '사회탐구':'사회', '과학탐구':'과학'}.get(label, label)
    if row['grade'] == 2 and row['year'] <= 2025 and label in SCIENCE:
        return label + '1'
    return label

def coverage(row):
    result = defaultdict(set)
    for resource in row['resources']:
        label = comparison_label(resource['subject'], row)
        if label:
            result[label].add(resource['kind'])
    return result

def expected_subjects(row):
    """Reviewed source-scope profiles, not a count heuristic or future taxonomy.

Source categories claim all-subject; profiles require each named paper/answer.
KICE/CSAT optional domains and late G3 extra domains require separate review.
"""
    year, month, grade, kind = group_key(row)
    if kind != 'national_mock' or not 2020 <= year <= 2026:
        return None
    if grade == 1 or (grade == 2 and year >= 2026):
        return CORE | {'사회', '과학'}
    if grade == 2:
        return CORE | SOCIAL | {s+'1' for s in SCIENCE}
    if grade == 3:
        core = (CORE-{'수학'}) | {'수학가형', '수학나형'} if year == 2020 else CORE
        science = {s+n for s in SCIENCE for n in (['1'] if month == 3 else ['1','2'])}
        return core | SOCIAL | science
    return None

def inspect(row):
    cov = coverage(row)
    reasons=[]
    expected=expected_subjects(row)
    if set(row['parser_quarantine']) & {'resource_subject_unknown', 'resource_kind_unknown', 'resource_identity_missing', 'resource_identity_duplicate'}:
        reasons.append('PARSER_RESOURCE_EVIDENCE_REVIEW')
    if row['identity_drift']:
        reasons.append('NOMINAL_ADMINISTERED_MONTH_CONFLICT')
    if expected is None:
        reasons.append('EXAM_DOMAIN_PROFILE_REVIEW')
    if row['exam_type'] in {'evaluation_mock','csat'}:
        reasons.append('ADDITIONAL_LANGUAGE_VOCATIONAL_COVERAGE_UNPROVEN')
    if row['grade']==2 and row['exam_type']=='national_mock' and row['audit_nominal_month']>=10:
        reasons.append('LATE_G2_ADDITIONAL_DOMAIN_REVIEW')
    if row['grade']==3 and row['exam_type']=='national_mock' and row['audit_nominal_month']>=10:
        reasons.append('LATE_G3_ADDITIONAL_DOMAIN_REVIEW')
    missing=sorted((expected or set())-cov.keys())
    if missing:
        reasons.append('EXPECTED_SUBJECT_EVIDENCE_GAP')
    unpaired=sorted(s for s,kinds in cov.items()
                    if kinds & ({'question'} | ANSWER)
                    and ('question' not in kinds or not kinds & ANSWER))
    if unpaired:
        reasons.append('QUESTION_ANSWER_OR_OCCURRENCE_SPLIT_REVIEW')
    # A named paper attached without its own occurrence cannot be silently full.
    unscoped=sorted(r['key'] for r in row['resources']
              if r['kind'] in ({'question'} | ANSWER) and not r['subject'])
    if unscoped:
        reasons.append('PAPER_WITHOUT_SUBJECT_OCCURRENCE')
    # Comparison aliases never repair a split accordion in the App.
    raw=defaultdict(set)
    for r in row['resources']:
        if r['subject']:
            raw[r['subject']].add(r['kind'])
    split=sorted(s for s,k in raw.items() if k & ({'question'} | ANSWER)
                 and ('question' not in k or not k & ANSWER))
    if split and 'QUESTION_ANSWER_OR_OCCURRENCE_SPLIT_REVIEW' not in reasons:
        reasons.append('QUESTION_ANSWER_OR_OCCURRENCE_SPLIT_REVIEW')
    if row['grade'] == 3 and row['year'] >= 2021:
        question_labels = [s.replace(' ', '') for s,k in raw.items() if 'question' in k]
        for base, variants in [('국어', ('화작', '언매')), ('수학', ('기하', '미적', '확통'))]:
            labels = [s for s in question_labels if s.startswith(base)]
            if labels and base not in labels and not all(any(v in s for s in labels) for v in variants):
                reasons.append('ELECTIVE_VARIANT_COVERAGE_REVIEW')
                break
    if '전과목' not in (row.get('category') or ''):
        reasons.append('SOURCE_FULL_SET_INTENT_UNCONFIRMED')
    if any(not r['active'] for r in row['resources']) and row['state']=='ACTIVE':
        reasons.append('INACTIVE_RESOURCE')
    return {'expected_subjects':sorted(expected or []),'missing_subjects':missing,
            'unpaired_subjects':unpaired,'raw_occurrence_split':split,
            'unscoped_paper_keys':unscoped,'review_reasons':reasons,
            'coverage':{s:sorted(v) for s,v in sorted(cov.items())}}

def audit(data):
    rows=sorted(data['rows'],key=lambda r:int(r['external_post_id']))
    assert len(rows)==len({r['external_post_id'] for r in rows})
    groups=defaultdict(list)
    for r in rows: groups[group_key(r)].append(r)
    analyses={r['external_post_id']:inspect(r) for r in rows}
    output=[]
    for r in rows:
        pid=r['external_post_id'];a=analyses[pid];siblings=groups[group_key(r)]
        papers={s for s,k in a['coverage'].items() if 'question' in k}
        broader=[]
        for other in siblings:
            oid=other['external_post_id'];oa=analyses[oid]
            other_papers={s for s,k in oa['coverage'].items() if 'question' in k}
            if papers and papers < other_papers:
                broader.append(oid)
        full=[s['external_post_id'] for s in siblings if not analyses[s['external_post_id']]['review_reasons']]
        classification='AMBIGUOUS'
        if broader:
            classification='PARTIAL_DUPLICATE'
        elif not a['review_reasons'] and full==[pid]:
            classification='FULL_SET_CANONICAL'
        elif len(full)>1:
            a={**a,'review_reasons':a['review_reasons']+['MULTIPLE_FULL_SET_SOURCES']}
        # Preserve holds even where coverage is broad/full. No audit can release52.
        eligible=(classification=='FULL_SET_CANONICAL' and r['state']=='WRITER_READY'
                  and pid not in data['identity_review_ids'] and pid!='1710')
        output.append({**{k:v for k,v in r.items() if k!='resources'},**a,
                       'resource_count':len(r['resources']),
                       'normalized_exam_identity':list(group_key(r)),
                       'sibling_post_ids':[s['external_post_id'] for s in siblings if s is not r],
                       'broader_source_ids':sorted(broader,key=int),
                       'full_set_candidate':classification=='FULL_SET_CANONICAL',
                       'classification':classification,
                       'canonical_review_eligible':eligible,
                       'automatic_publication_allowed':False})
    summary={state:dict(Counter(r['classification'] for r in output if r['state']==state))
             for state in sorted({r['state'] for r in output})}
    return {'scope':data['scope'],'raw_exam_posts':len(rows),
            'existing_identity_groups':len({tuple(r['existing_identity']) for r in rows}),
            'review_identity_groups':len(groups),'classification_counts':dict(Counter(r['classification'] for r in output)),
            'state_counts':summary,'after_canonical_ready':sum(r['canonical_review_eligible'] for r in output),
            'publication_authorized':False,'rows':output}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--input',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args()
    result=audit(json.loads(args.input.read_text()))
    args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k!='rows'},ensure_ascii=False,indent=2))
if __name__=='__main__':main()
