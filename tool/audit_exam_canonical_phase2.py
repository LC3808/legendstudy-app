#!/usr/bin/env python3
"""Reproduce Phase2 offline; output is review evidence, never writer input."""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re
from audit_exam_canonical import audit, expected_subjects
from ingestion.exam_canonical import (ExamIdentity, ExpectedCoverage, observe,
    paper_code, classify_group, serializable, FOREIGN, VOCATIONAL)
from ingestion.subjects import BY_CODE

SAMPLES = Path(__file__).parent / 'ingestion' / 'samples'
BASELINE = SAMPLES / 'exam-canonical-audit-2026-09-27.json'
EVIDENCE = SAMPLES / 'exam-canonical-phase2-evidence.json'


def identity_for(row, evidence):
    pid=row['external_post_id'];source=evidence['source_evidence'].get(pid,{})
    override=evidence.get('reviewed_identity_assertions',{}).get(pid,{})
    organizer=override.get('organizer',source.get('organizer'))
    refs=['source:'+pid] if source else []
    if not organizer and row['year']==2021 and row['exam_type']=='national_mock':
        month=row['audit_nominal_month'];grade=row['grade']
        organizer=({3:'SEOUL',4:'GYEONGGI',7:'INCHEON',10:'SEOUL'} if grade==3
                   else {3:'SEOUL',6:'BUSAN',9:'INCHEON',11:'GYEONGGI'}).get(month)
        if organizer:refs.append('external:calendar_2021')
    if not organizer and row['year']==2021 and row['exam_type'] in {'evaluation_mock','csat'}:
        organizer='KICE';refs.append('external:calendar_2021')
    refs += override.get('evidence',[])
    dates=source.get('date_assertions',[])
    date=override.get('administered_date',dates[0] if len(dates)==1 else None)
    admin_month=int(date[5:7]) if date else None
    if admin_month is None:
        match=re.search(r'[\[(](?:20\d{2}년\s*)?(\d{1,2})월\s*시행',row['title'])
        if match:admin_month=int(match[1])
    return ExamIdentity(row['grade'],row['year'],row['audit_nominal_month'],
                        row['exam_type'],organizer,None if override.get('event_kind')=='paper_distribution' else date,admin_month,row['academic_year'],
                        'high' if source and organizer else 'unverified',
                        override.get('calendar_conflict',len(dates)>1),tuple(sorted(set(refs))),
                        override.get('event_kind','exam'),date)


def expected_for(row, identity):
    # Phase1 named sets remain diagnostic lower bounds, not certified complete
    # inventories. The verified registry is deliberately exact-year and scoped.
    labels=expected_subjects(row) or set()
    papers={paper_code(label,identity)[0] for label in labels}-{None}
    verified=False; refs=['phase1:provisional_source_profile']; unresolved=[]
    excluded=[]
    variants=()
    if identity.grade==3 and identity.exam_year>=2021:
        variants=(('korean',('화작','언매')),('math',('기하','미적','확통')))
    if identity.exam_family in {'evaluation_mock','csat'}:
        papers={'korean','math','english','korean_history'}
        if identity.exam_year<=2020:
            papers.remove('math');papers |= {'historical:수학가형','historical:수학나형'}
        papers |= {s.code for s in BY_CODE.values() if s.category in {'사회탐구','과학탐구'}}
        unresolved=['vocational_domain_uncertain','second_foreign_domain_uncertain']
        if identity.exam_year<2020:
            papers=set();unresolved.append('historical_taxonomy_profile_unverified')
    elif identity.grade in {2,3} and identity.nominal_month>=10:
        unresolved=['late_exam_additional_domains_unverified']
    if (identity.exam_year,identity.grade,identity.exam_family)==(2026,1,'national_mock') and identity.nominal_month in {3,6,9,10}:
        papers={'korean','math','english','korean_history','integrated_social','integrated_science'}
        verified=True;refs=['external:ebs_2026_scope'];excluded=['VOCATIONAL','SECOND_FOREIGN_HANMUN'];unresolved=[]
    if (identity.exam_year,identity.nominal_month,identity.grade,identity.exam_family,identity.organizer)==(2023,6,3,'evaluation_mock','KICE'):
        papers|={'foreign:'+n for n in FOREIGN}|{'vocational:'+n for n in VOCATIONAL}
        verified=True;refs=['external:kice_2023_june'];unresolved=[]
    return ExpectedCoverage(identity.key,frozenset(papers),verified,tuple(refs),
                            tuple(excluded),variants,tuple(unresolved))


def primary_reason(row):
    if row['exam_type'] in {'evaluation_mock','csat'}:return 'KICE_EXTRA_DOMAINS'
    if row['grade']==3 and row['audit_nominal_month']>=10:return 'G3_YEAR_END'
    if row['grade']==2 and row['audit_nominal_month']>=10:return 'G2_YEAR_END'
    if row['identity_drift']:return 'IDENTITY_CONFLICT'
    return 'RESOURCE_MAPPING'


def run(baseline, evidence):
    old=audit(baseline);previous={r['external_post_id']:r for r in old['rows']}
    candidates=[]
    for row in baseline['rows']:
        pid=row['external_post_id'];identity=identity_for(row,evidence)
        candidates.append({'id':pid,'identity':identity,'expected':expected_for(row,identity),
                           'observed':observe(row['resources'],identity,require_active=row['state']=='ACTIVE'),
                           'protected':pid in baseline['identity_review_ids'] or pid=='1710',
                           'source_changed':not evidence['source_evidence'].get(pid,{}).get('resource_metadata_unchanged',True)})
    classifications=classify_group(candidates)
    groups=defaultdict(list)
    for c in candidates:
        # Potential siblings use the existing nominal identity even if organizer
        # is unknown. Unverified grouping never authorizes subset/ranking.
        groups[c['identity'].key[:4]].append(c['id'])
    rows=[]
    for row,c in zip(baseline['rows'],candidates):
        pid=c['id'];oldrow=previous[pid]
        if pid not in evidence['source_evidence']:continue
        result=classifications[pid]
        rows.append({'external_post_id':pid,'title':row['title'],'source_url':row['source_url'],
                     'state':row['state'],'phase1_classification':oldrow['classification'],
                     'primary_ambiguity':primary_reason(row),'existing_identity':row['existing_identity'],
                     'identity':serializable(c['identity']),'source_evidence':evidence['source_evidence'][pid],
                     'expected':serializable(c['expected']),'observed':serializable(c['observed']),
                     'resource_count':len(row['resources']),
                     'resource_kinds':dict(sorted(Counter(r['kind'] for r in row['resources']).items())),
                     'sibling_source_posts':sorted([i for i in groups[c['identity'].key[:4]] if i!=pid],key=int),
                     'parser_quarantine':row['parser_quarantine'],**result})
    rows.sort(key=lambda r:int(r['external_post_id']))
    wr=[r for r in rows if r['state']=='WRITER_READY' and r['phase1_classification']=='AMBIGUOUS']
    active=[r for r in rows if r['state']=='ACTIVE' and r['phase1_classification']=='AMBIGUOUS']
    previous_ready=[r for r in rows if r['state']=='WRITER_READY' and r['phase1_classification']=='FULL_SET_CANONICAL']
    ready=[r['external_post_id'] for r in rows if r['state']=='WRITER_READY' and r['classification']=='FULL_SET']
    def classes(rs):return {k:[r['external_post_id'] for r in rs if r['classification']==k] for k in ['FULL_SET','PARTIAL_DUPLICATE','REVIEW']}
    summary={'unique_source_posts_analyzed':len(rows),'baseline_sibling_scan_posts':len(baseline['rows']),
             'ambiguous_input_unique_posts':len(wr)+len(active),
             'ambiguous_input_identity_groups':len({tuple(r['identity'][k] for k in ['exam_year','nominal_month','grade','exam_family']) for r in wr+active}),
             'multi_post_groups_with_target':sum(len(groups[k])>1 for k in {c['identity'].key[:4] for c in candidates if c['id'] in {r['external_post_id'] for r in wr+active}}),
             'writer_primary_reasons':dict(sorted(Counter(r['primary_ambiguity'] for r in wr).items())),
             'active_primary_reasons':dict(sorted(Counter(r['primary_ambiguity'] for r in active).items())),
             'writer_ambiguous':classes(wr),'active_ambiguous':classes(active),
             'previous_ready':classes(previous_ready),'final_canonical_ready_pool':ready,
             'writer_review_reason_counts':dict(sorted(Counter(x for r in wr for x in r['reasons']).items())),
             'writer_partial_pool':[r['external_post_id'] for r in rows if r['state']=='WRITER_READY' and r['classification']=='PARTIAL_DUPLICATE'],
             'writer_review_pool':[r['external_post_id'] for r in rows if r['state']=='WRITER_READY' and r['classification']=='REVIEW'],
             'publication_authorized':False,'production_mutation':False}
    return {'summary':summary,'rows':rows}


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True)
    p.add_argument('--baseline',type=Path,default=BASELINE);p.add_argument('--evidence',type=Path,default=EVIDENCE)
    args=p.parse_args();raw=args.baseline.read_bytes();evidence=json.loads(args.evidence.read_text())
    if hashlib.sha256(raw).hexdigest()!=evidence['baseline_sha256']:raise SystemExit('Baseline fingerprint mismatch; review evidence before rerun.')
    result=run(json.loads(raw),evidence)
    args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2,sort_keys=True)+'\n')
    print(json.dumps(result['summary'],ensure_ascii=False,indent=2))
if __name__=='__main__':main()
