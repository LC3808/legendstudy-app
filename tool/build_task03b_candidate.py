"""Offline, deterministic reviewed-data builder. No network, DB or promotion API."""
import collections,copy,hashlib,json,uuid
from pathlib import Path
R=Path(__file__).resolve().parents[1];D=R/'data/mock_expansion/task03b';STAMP='2026-11-11T02:53:00+00:00'
def read(p):return json.loads(p.read_text())
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def ident(s):return str(uuid.uuid5(uuid.NAMESPACE_URL,'legendstudy:task03b:'+s))
def norm(s):return s.replace('II','2').replace('I','1').replace('·','').replace(' ','')
def main():
 baseline=read(R/'data/mock_expansion/task03a/verified_papers.json');report=read(R/'data/mock_expansion/task03a/verification_report.json');reg=read(R/'data/mock_expansion/task03/registry_snapshot.json');manifest=read(R/'data/mock_expansion/task03a/source_manifest.json')
 preservation=read(D/'preservation_manifest.json')
 for path,digest in preservation['files'].items():assert hashlib.sha256((R/path).read_bytes()).hexdigest()==digest,path
 ps=copy.deepcopy(baseline['papers']);images=read(D/'2025_image_papers.json')['papers'];aliases=[]
 e=next(e for e in reg if (e['academic_year'],e['exam_month'])==(2025,11));cor=next(m for m in manifest['sources'] if (m['academic_year'],m['exam_month'],m.get('kind'))==(2025,11,'corrections'))
 el={'화법과 작문':'화작','언어와 매체':'언매','확률과 통계':'확통','미적분':'미적','기하':'기하'}
 for p in images:
  label=norm(p['subject'])+('('+el[p['elective']]+')' if p['elective'] else '')
  subjects=[s for s in e['subjects'] if norm(s['label'])==label];assert len(subjects)==1,(label,subjects)
  s=subjects[0];variant=' · '.join(x for x in [p['elective'],p['variant']] if x);qs=copy.deepcopy(p['questions'])
  for q in qs:q['question_id']=str(uuid.uuid5(uuid.NAMESPACE_URL,f"legendstudy:{e['content_item_id']}:{s['code']}:{variant}:q{q['number']}"))
  ev=dict(issuer='KICE',url=p['source'],sha256=p['sha256'],page=p['page'],member=p['member'],pdf_sha256=p['pdf_sha256'],reviewed=True)
  ps.append(dict(content_item_id=e['content_item_id'],academic_year=2025,exam_month=11,exam_type=e['exam_type'],exam_subject_id=s['id'],subject_code=s['code'],subject_label=s['label'],paper_variant=variant,verification_status='READY',engine='mixed-v2',mapping_reviewed=True,corrections_reviewed=True,correction_evidence=dict(issuer='KICE',url=cor['url'],sha256=cor['sha256'],page=1,reviewed=True),answer_evidence=ev,points_evidence=ev,question_count=p['question_count'],max_score=p['max_score'],grade_status='unavailable',extraction_checks=p['extraction_checks'],questions=qs,legendstudy_crosscheck=p.get('legendstudy_crosscheck')))
 coverage=copy.deepcopy(report['subjects'])
 for row in coverage:
  if (row['academic_year'],row['exam_month'])==(2025,11):row.update(verification_status='READY',ready=True,reason='Official image answers/points reviewed, odd/common answers independently match LegendStudy explanation PDFs',paper_count=sum(p['exam_subject_id']==row['exam_subject_id'] for p in ps))
  elif row['verification_status']=='PARTIAL':
   exam=next(e for e in reg if e['content_item_id']==row['content_item_id']);targets=[s for s in exam['subjects'] if s['code']==row['subject_code'] and '(' in s['label']];assert len(targets)==(2 if row['subject_code']=='korean' else 3)
   aliases.append(dict(content_item_id=row['content_item_id'],exam_subject_id=row['exam_subject_id'],subject_label=row['subject_label'],classification='ELECTIVE_UMBRELLA_NOT_IDENTICAL_DUPLICATE',mapping_status='VERIFIED_ONE_TO_MANY',targets=[dict(exam_subject_id=s['id'],label=s['label'],canonical_code=s['code']) for s in targets],action='PRESERVE_ID_NO_MERGE_NO_DIRECT_KEY',reason='Use existing explicit elective keys. Generic-only exams retain their original ID and paper_variant contract.'))
   row['reason']='Verified elective umbrella (1:N), not an identical duplicate. Original ID retained, explicit elective keys only; no direct key.'
  elif row['verification_status']=='NOT_READY':row['reason']='Official name/answers/points verified; canonical subject_id/code and official numeric code remain unverified. No guessed mapping or seed.'
 summary=dict(subjects=len(coverage),status_counts=dict(collections.Counter(x['verification_status'] for x in coverage)),verified_papers=len(ps),verified_questions=sum(len(p['questions']) for p in ps),baseline_ready_preserved=372,new_ready_subjects=24,exams_with_ready=len({p['content_item_id'] for p in ps}),production_applied=False)
 exams=[]
 for e in reg:
  rs=[x for x in coverage if x['content_item_id']==e['content_item_id']];counts=dict(collections.Counter(x['verification_status'] for x in rs));exams.append(dict(academic_year=e['academic_year'],exam_month=e['exam_month'],subjects=len(rs),counts=counts,status='READY' if counts.get('READY')==len(rs) else 'PARTIAL'))
 write(D/'verified_papers.json',dict(schema_version=1,scope='LOCAL_REVIEW_CANDIDATE_NOT_DEPLOYED',evidence_inheritance=baseline['evidence_inheritance'],papers=ps));write(D/'verification_report.json',dict(summary=summary,exams=exams,subjects=coverage));write(D/'alias_mapping.json',dict(registry_mutation=False,aliases=aliases))
 # Preserve all 1,026 official facts; SQL reference contract cannot express < or unassigned.
 official=read(R/'data/mock_expansion/task03a/cutoff_review.json')['official_rows'];review=read(D/'raw_percentile_review.json');refs=[];ref_evidence=[];excluded=[]
 for t in review['tables']:
  ti=review['tables'].index(t);e=next(e for e in reg if e['content_item_id']==t['content_item_id']);ss=[s for s in e['subjects'] if s['label']==t['subject_label']]
  if t['subject_label'] in ['국어','수학']:
   explicit=[s for s in e['subjects'] if s['label'].startswith(t['subject_label']+'(')]
   if explicit:ss=explicit
  assert ss,(t['subject_label'],e)
  for g in range(1,10):
   o=next(o for o in official if (o['academic_year'],o['exam_month'],o['subject_label'],o['grade'])==(t['academic_year'],t['exam_month'],t['subject_label'],g))
   if o['comparison']!='gte':excluded.append(dict(o,reason='Existing reference scalar cannot encode less-than/unassigned; retain fact, do not mislabel threshold.'));continue
   vals={c['metric']:c['verified_value'] for c in review['cells'] if c['table']==ti and c['grade']==g}
   for s in ss:
    row=dict(id=ident('reference:'+s['id']+':'+str(g)),content_item_id=e['content_item_id'],exam_subject_id=s['id'],elective_key='',elective_label='',grade=g,revision=1,is_current=False,status='draft',raw_score=vals.get('raw_score'),raw_score_min=None,raw_score_max=None,standard_score=o['score'],percentile=vals.get('percentile'),assessment_method='relative',raw_certainty='unspecified',standard_certainty='confirmed',source_url=o['source_url'],raw_source_url=t['source_image_url'] if vals.get('raw_score') is not None else None,standard_source_url=o['source_url'],source_digest=o['source_sha256'],source_name='평가원 표준점수 / 레전드스터디 원점수·백분위 참고',fetched_at=t['fetched_at'],verified_at=STAMP,correction_note='TASK03-B: raw/percentile source transcription only; not an official raw-to-grade conversion. LegendStudy image SHA256='+t['source_sha256']+'; official cell='+o['source_cell'])
    refs.append(row);ref_evidence.append(dict(id=row['id'],official=o,legendstudy_source=t,grade_calculation_eligible=False))
 keys=[];questions=[];key_evidence=[]
 for p in ps:
  k=ident('key:'+p['exam_subject_id']+':'+p['paper_variant']+':v1');ev=p['answer_evidence'];pe=p['points_evidence'];correction=any(q['all_credit'] for q in p['questions'])
  keys.append(dict(id=k,content_item_id=p['content_item_id'],exam_subject_id=p['exam_subject_id'],paper_variant=p['paper_variant'],version=1,status='draft',is_current=False,question_count=p['question_count'],max_score=p['max_score'],source_name='KICE reviewed official answer table',source_url=ev['url'],source_digest=ev['sha256'],points_source_name='KICE official point table',points_source_url=pe['url'],points_source_digest=pe['sha256'],fetched_at=STAMP,verified_at=STAMP,corrected_at=STAMP if correction else None,correction_note=('Source final correction applied; '+p['correction_evidence']['url']) if correction else None,scoring_version='mixed-v2',verification_status='READY'))
  for q in p['questions']:questions.append(dict(answer_key_version_id=k,question_number=q['number'],answer_type=q['answer_type'],correct_answer=None,points=q['points'],accepted_answers=q['accepted_answers'],all_credit=q['all_credit'],question_id=q['question_id'],unit=None,domain=None,item_type=None))
  key_evidence.append(dict(id=k,content_item_id=p['content_item_id'],exam_subject_id=p['exam_subject_id'],paper_variant=p['paper_variant'],academic_year=p['academic_year'],exam_month=p['exam_month'],answer_evidence=ev,points_evidence=pe,correction_evidence=p['correction_evidence']))
 write(D/'load_data.json',dict(batch='task03b-20261111',answer_key_versions=keys,exam_questions=questions,grade_cutoff_references=refs,grade_cutoff_versions=[]))
 write(D/'load_evidence.json',dict(keys=key_evidence,references=ref_evidence,excluded_reference_facts=excluded))
 print(summary);print('load',len(keys),len(questions),len(refs),'excluded official facts',len(excluded))
if __name__=='__main__':main()
