#!/usr/bin/env python3
"""Revalidate the fixed Phase3 pool offline; never a publication input."""
import argparse
from collections import Counter,defaultdict
import hashlib
import json
from pathlib import Path
from audit_exam_canonical_phase2 import BASELINE,EVIDENCE,identity_for
from ingestion.exam_canonical import observe,serializable
from ingestion.exam_coverage_registry import CoverageRegistry,classify_with_registry,REGISTRY

PROVISIONAL=tuple('1480 1481 1488 1489 1494 1495 1497 1499 1500 1502 1503 1504 1505 1510 1511 1512 1514 1515 1523 1524 1609 1614 1615 1616 1617 1619 1620 1621 1636 1648'.split())
AMBIGUOUS=tuple('1479 1482 1483 1484 1485 1486 1487 1490 1496 1498 1501 1506 1507 1508 1509 1513 1516 1517 1525 1530 1574 1608 1618 1634 1635 1646 1647'.split())
CASES=('1474','1431','1447','1404')
NEXT_ACTION={
 'expected_coverage_unverified':'Obtain independently verified complete named inventory for this exact exam; no adjacent-year fallback.',
 'expected_paper_missing':'Inspect/recover the listed missing paper question+answer pairs; fewer files are not automatically a partial duplicate without a full sibling.',
 'elective_bundle_unproven':'Inspect actual Korean/math PDFs for every expected elective; record scoped file evidence without changing source type.',
 'admin_date_conflict':'Reconcile source assertion with dated official event evidence; do not overwrite DB identity.',
 'exam_identity_uncertain':'Confirm organizer/event/calendar against source papers and official revision.',
 'resource_subject_mapping_incomplete':'Inspect unmapped attachment subject headers; keep combined documents intact.',
 'question_answer_mapping_incomplete':'Verify question/answer relationship and current occurrence grouping; expected coverage cannot repair mapping.',
 'canonical_full_sibling_unverified':'Verify a full-set sibling before assigning a canonical replacement target.',
}

def run(baseline,evidence,registry):
    rows={r['external_post_id']:r for r in baseline['rows']}
    primary=set(PROVISIONAL+AMBIGUOUS)
    assert len(primary)==57 and len(PROVISIONAL)==30 and len(AMBIGUOUS)==27
    assert {r['external_post_id'] for r in rows.values() if r['state']=='WRITER_READY'}==primary
    # Scan existing snapshot siblings, but do not research/crawl historical waves.
    keys={(rows[p]['year'],rows[p]['audit_nominal_month'],rows[p]['grade'],rows[p]['exam_type']) for p in primary|set(CASES)}
    selected=sorted([p for p,r in rows.items() if (r['year'],r['audit_nominal_month'],r['grade'],r['exam_type']) in keys],key=int)
    candidates=[];identities={}
    for p in selected:
        row=rows[p];original=identity_for(row,evidence);identity=registry.resolve_identity(original)
        identities[p]=original
        candidates.append(dict(id=p,identity=identity,expected=registry.expected(identity),observed=observe(row['resources'],identity,require_active=row['state']=='ACTIVE'),source_changed=not evidence['source_evidence'].get(p,{}).get('resource_metadata_unchanged',True)))
    results=classify_with_registry(candidates);groups=defaultdict(list)
    for c in candidates:groups[c['identity'].key].append(c['id'])
    out=[]
    for c in candidates:
        p=c['id'];r=rows[p];entry=registry.lookup(c['identity']);result=results[p]
        hold=p in baseline['identity_review_ids'] or p=='1710'
        observed=serializable(c['observed']);observed.pop('resources')
        out.append(dict(resource_evidence_ref=BASELINE.name+'#rows.external_post_id='+p,post_id=p,source_url=r['source_url'],source_title=r['title'],state=r['state'],
            pool='PREVIOUS_PROVISIONAL_30' if p in PROVISIONAL else 'PREVIOUS_AMBIGUOUS_27' if p in AMBIGUOUS else 'REGRESSION_OR_SIBLING',
            existing_identity=r['existing_identity'],original_source_identity=serializable(identities[p]),exam_identity=serializable(c['identity']),
            registry_entry=entry['id'] if entry else None,expected_coverage_status=entry['status'] if entry else 'UNVERIFIED',
            expected_coverage=serializable(c['expected']),actual_coverage_summary=observed,resource_count=len(r['resources']),
            canonical_sibling_if_any=result['canonical_target'],siblings=[s for s in groups[c['identity'].key] if s!=p],
            evidence_summary=entry['evidence'] if entry else [],publication_hold=hold,
            next_actions=sorted({NEXT_ACTION.get(code,'Resolve '+code+' with scoped evidence.') for code in result['reasons'] if code!='expected_coverage_satisfied'}),**result))
    def pool(ids):return {cl:[r['post_id'] for r in out if r['post_id'] in ids and r['classification']==cl] for cl in ['FULL_SET','PARTIAL_DUPLICATE','REVIEW']}
    pp=pool(primary)
    summary=dict(input_review_required=57,unique_exam_identities=len({(rows[p]['year'],rows[p]['audit_nominal_month'],rows[p]['grade'],rows[p]['exam_type']) for p in primary}),primary_sibling_groups=57,primary_multi_post_sibling_groups=sum(len(groups[k])>1 for k in groups if any(p in primary for p in groups[k])),
      registry_entries=len(registry.entries),registry_statuses=dict(Counter(e['status'] for e in registry.entries.values())),
      primary=pp,previous_provisional_30=pool(PROVISIONAL),previous_ambiguous_27=pool(AMBIGUOUS),cases=pool(CASES),
      review_reason_counts=dict(sorted(Counter(code for r in out if r['post_id'] in primary and r['classification']=='REVIEW' for code in r['reasons']).items())),
      production_mutation=False,publication_authorized=False,writer_integration=False,production_gate_integration=False)
    assert sum(map(len,pp.values()))==57
    return dict(summary=summary,rows=out)

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    raw=BASELINE.read_bytes();e=json.loads(EVIDENCE.read_text())
    if hashlib.sha256(raw).hexdigest()!=e['baseline_sha256']:raise SystemExit('Baseline changed; audit evidence again.')
    result=run(json.loads(raw),e,CoverageRegistry.load())
    result['input_sha256']={str(x.name):hashlib.sha256(x.read_bytes()).hexdigest() for x in [BASELINE,EVIDENCE,REGISTRY]}
    a.output.write_text(json.dumps(result,ensure_ascii=False,indent=2,sort_keys=True)+'\n')
    print(json.dumps(result['summary'],ensure_ascii=False,indent=2))
if __name__=='__main__':main()
