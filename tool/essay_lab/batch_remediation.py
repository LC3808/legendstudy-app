"""Classify root causes once per shared university/type/year repair group.

This is a deterministic work manifest, not a substitute for source validation.
Missing-profile routes never inflate physical Math counts. Review gates and
actual missing evidence are tracked separately; no status/rights are promoted.
"""
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path


def causes(row):
    reasons=set(row['reasons']); out=[]
    if not row['profile_mapped']: out.append('PROFILE_SCOPE')
    if row['route']=='math': out.append('MATH_INPUT_ADAPTER')
    elif row['route']=='special': out.append('SPECIAL_TYPE_ROUTING')
    if reasons & {'SOURCE_READ_FAILED','SOURCE_PAGE_READ_FAILED','EMPTY_PAGE_TEXT','INVALID_PAGE_RANGE'}: out.append('PDF_EXTRACTION_OR_PAGE_MAPPING')
    if 'GLYPH_REVIEW_REQUIRED' in reasons: out.append('GLYPH_OR_VISUAL_GROUNDING')
    if 'QUESTION_SCOPE_REQUIRES_SPLIT' in reasons: out.append('QUESTION_BOUNDARIES')
    if 'CRITERIA_CONTAINS_EXAMPLE_ANSWER' in reasons: out.append('EVIDENCE_ROLE_BOUNDARIES')
    if any(r.startswith('MISSING_EVIDENCE:') for r in reasons): out.append('MISSING_EVIDENCE_ROLE')
    if reasons & {'MAPPING_REVIEW_REQUIRED','PROVIDER_RIGHTS_REQUIRED'}: out.append('SOURCE_REVIEW_AND_RIGHTS_GATE')
    if 'OUTSIDE_REQUESTED_YEAR_SCOPE_PRESERVED' in reasons: out.append('PRESERVED_LEGACY_YEAR')
    return out or ['CONTENT_VALIDATION']


def build_manifest(assembly, inheritance):
    questions=assembly['questions'];exams={e['examId']:e for e in assembly['registry']['exams']}
    assert len({r['question_id'] for r in questions})==len(questions)
    rows=[];groups=defaultdict(list);by_university={}
    for row in questions:
        if row['evaluation_scope']!='NEEDS_REVIEW':continue
        exam=exams[row['exam_id']]; root=causes(row)
        item={k:row[k] for k in ('question_id','exam_id','university','route','draft_sha256')}
        item.update(year=exam['year'],kind=exam['kind'],track=exam['track'],root_causes=root,
                    derived_symptoms=[x for x in row['reasons'] if x.startswith('MISSING_CLEAN_')],
                    evaluation_scope='NEEDS_REVIEW',activation_granted=False)
        rows.append(item)
        for cause in root:groups[(row['university'],row['route'],exam['year'],exam['kind'],exam['track'],cause)].append(row['question_id'])
    for university in sorted({r['university'] for r in questions}):
        allrows=[r for r in questions if r['university']==university];held=[r for r in rows if r['university']==university]
        by_university[university]={
            'exams':len({r['exam_id'] for r in allrows}), 'questions':len(allrows),
            'profile_connected':sum(bool(r['profile_mapped']) for r in allrows),
            'evaluation_scopes':dict(Counter(r['evaluation_scope'] for r in allrows)),
            'needs_review':len(held),
            'official_evidence_connected':None, 'input_validation_pass':None,
            'public_questions':None, 'provider_e2e_pass':None,
            'complete':False,
            'root_causes':dict(Counter(c for r in held for c in r['root_causes']))}
        # Unknown runtime/evidence counts must not be inferred from draft FULL.

    unmapped=inheritance['unmapped'];unmapped_groups=defaultdict(list)
    for r in unmapped:unmapped_groups[(r['university'],r['year'],exams[r['exam_id']]['kind'],r['track'],r['reason'])].append(r['question_id'])
    return {'version':'batch-root-causes-v2','total_questions':len(questions),'needs_review':len(rows),
        'root_cause_counts_nonexclusive':dict(Counter(c for r in rows for c in r['root_causes'])),
        'by_university':by_university,'questions':rows,
        'repair_groups':[dict(university=k[0],route=k[1],year=k[2],kind=k[3],track=k[4],cause=k[5],question_ids=v) for k,v in groups.items()],
        'unmapped_questions':len(unmapped),'unmapped_groups':[dict(university=k[0],year=k[1],kind=k[2],track=k[3],reason=k[4],question_ids=v) for k,v in unmapped_groups.items()],
        'preserved_full_without_profile':[r['question_id'] for r in questions if not r['profile_mapped'] and r['evaluation_scope']=='FULL_EVALUATION'],
        'provider_calls':0,'production_writes':0,'activation_granted':False}


def main():
    p=argparse.ArgumentParser()
    for arg in ('assembly','inheritance','output'):p.add_argument('--'+arg,type=Path,required=True)
    a=p.parse_args();result=build_manifest(json.loads(a.assembly.read_text()),json.loads(a.inheritance.read_text()))
    a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k not in ('questions','repair_groups','unmapped_groups')},ensure_ascii=False))

if __name__=='__main__':main()
