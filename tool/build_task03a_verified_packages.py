"""Offline review artifact builder. Never publishes or connects to a database."""
from pathlib import Path
import json,uuid,copy,hashlib,collections
R=Path(__file__).resolve().parents[1];D=R/'.local/task03a/official';O=R/'data/mock_expansion/task03a';O.mkdir(exist_ok=True)
def read(p):return json.loads(p.read_text())
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n')
M=read(D/'manifest.json');E=read(D/'extracted.json');reg=read(R/'data/mock_expansion/task03/registry_snapshot.json')
cor={(x['academic_year'],x['exam_month']):x for x in M if x.get('kind')=='corrections'}
def evidence(m,page=1):return dict(issuer='KICE',url=m['url'],sha256=m['sha256'],page=page,reviewed=True)
def norm(v):return v.replace('II','2').replace('I','1').replace('․','').replace('·','').replace(' ','')
labels={'korean':'국어','math':'수학','english':'영어','korean_history':'한국사','physics_1':'물리학1','physics_2':'물리학2','life_science_1':'생명과학1','life_science_2':'생명과학2','earth_science_1':'지구과학1','earth_science_2':'지구과학2','chemistry_1':'화학1','chemistry_2':'화학2','economics':'경제','east_asian_history':'동아시아사','society_culture':'사회문화','life_ethics':'생활과윤리','world_history':'세계사','world_geography':'세계지리','ethics_thought':'윤리와사상','politics_law':'정치와법','korean_geography':'한국지리'}
electives={'언매':'언어와 매체','화작':'화법과 작문','기하':'기하','미적':'미적분','확통':'확률과 통계'}
bio=dict(issuer='KICE',url='https://www.korea.kr/news/policyNewsView.do?newsId=156486634',sha256=hashlib.sha256((D/'2022-biology-correction.html').read_bytes()).hexdigest(),section='생명과학Ⅱ 20번 문항 정답 취소 및 전원 정답 처리 질의응답',reviewed=True)
packages=[];coverage=[]
for e in reg:
 ek=(e['academic_year'],e['exam_month'])
 for s in e['subjects']:
  code=s['code'];label=s['label'];elective=next((v for k,v in electives.items() if k in label),None)
  duplicate=code in ('korean','math') and not elective and any(t['code']==code and '(' in t['label'] for t in e['subjects'])
  matches=[p for p in E['papers'] if (p['academic_year'],p['exam_month'])==ek and norm(p['subject'])==labels.get(code) and (not elective or p['elective']==elective)]
  if not code:status='NOT_READY';reason='Registry subject_code is null; foreign-language mapping not approved'
  elif duplicate:status='PARTIAL';reason='Generic Registry alias overlaps explicit electives; no duplicate publication'
  elif not matches:status='PARTIAL';reason='Official image-only answer PDFs require independent transcription verification'
  else:status='READY';reason='Official cells agree in two independent parsers; year/subject/elective/count/points/corrections checked'
  row=dict(content_item_id=e['content_item_id'],academic_year=ek[0],exam_month=ek[1],exam_subject_id=s['id'],subject_code=code,subject_label=label,verification_status=status,ready=status=='READY',reason=reason,paper_count=0)
  if status=='READY':
   seen=set()
   for p in matches:
    variant=' · '.join(v for v in (p['elective'],p['variant']) if v)
    assert variant not in seen,(ek,label,variant);seen.add(variant)
    src=dict(issuer='KICE',url=p['source'],sha256=p['sha256'],page=p['page'],member=p['member'],pdf_sha256=p['pdf_sha256'],reviewed=True)
    correction=evidence(cor[ek]);qs=copy.deepcopy(p['questions'])
    if ek==(2022,11) and code=='life_science_2':
     correction=bio;q=qs[19];q.update(original_accepted_answers=q['accepted_answers'],accepted_answers=[],all_credit=True,answer_evidence=bio)
    if ek==(2023,6) and code=='earth_science_2':
     correction=evidence(cor[ek],2);q=qs[13];q.update(original_accepted_answers=q['accepted_answers'],accepted_answers=[],all_credit=True,answer_evidence=correction)
    for q in qs:q['question_id']=str(uuid.uuid5(uuid.NAMESPACE_URL,f"legendstudy:{e['content_item_id']}:{code}:{variant}:q{q['number']}"))
    packages.append(dict(content_item_id=e['content_item_id'],academic_year=ek[0],exam_month=ek[1],exam_type=e['exam_type'],exam_subject_id=s['id'],subject_code=code,subject_label=label,paper_variant=variant,verification_status='READY',engine='mixed-v2',mapping_reviewed=True,corrections_reviewed=True,correction_evidence=correction,answer_evidence=src,points_evidence=src,question_count=p['question_count'],max_score=p['max_score'],grade_status='unavailable',extraction_checks=p['extraction_checks'],questions=qs))
   row['paper_count']=len(matches)
  coverage.append(row)
summary=dict(subjects=len(coverage),status_counts=dict(collections.Counter(x['verification_status'] for x in coverage)),verified_papers=len(packages),verified_questions=sum(len(x['questions']) for x in packages),exams_with_ready=len({(x['academic_year'],x['exam_month']) for x in coverage if x['ready']}),production_applied=False)
exams=[]
for e in reg:
 rows=[x for x in coverage if x['content_item_id']==e['content_item_id']];counts=dict(collections.Counter(x['verification_status'] for x in rows))
 exams.append(dict(academic_year=e['academic_year'],exam_month=e['exam_month'],status='READY' if counts.get('READY')==len(rows) else 'PARTIAL',subjects=len(rows),counts=counts))
write(O/'verified_papers.json',dict(schema_version=1,scope='LOCAL_REVIEW_CANDIDATE_NOT_DEPLOYED',evidence_inheritance='question override > paper answer_evidence/points_evidence',papers=packages))
write(O/'verification_report.json',dict(summary=summary,exams=exams,subjects=coverage,extraction_failures=E['failures']))
write(O/'source_manifest.json',dict(sources=M,additional_sources=[bio],legendstudy_inventory='../task03/source_inventory_all.json',verification_method='Independent native-table extraction (PyMuPDF and pdfplumber), structural checks, sampled visual review; not a claim of manual review of every cell.'))
write(O/'cutoff_review.json',read(D/'cutoff_review.json'))
print(summary)
for e in exams:print(e)
