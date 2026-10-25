import json,re,sys
from pathlib import Path
from copy import deepcopy
sys.path.insert(0,'/Users/woojinchang/development/legendstudy-service-app-20261022/tool')
from essay_lab.live_worker import digest
from essay_lab.material_runtime import load_reviewed_material
R=Path('/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/group-1a-20261025');O=R/'text-expansion'
read=lambda p:json.loads(p.read_text())
registry=read(R/'production-worker-registry.private.json');locators=read(R/'central-whole-exam-source-locators.json')
packages={};reports=[]
def clean(t):return re.sub(r'(?m)^\s*(?:\d+|CHUNG-ANG UNIVERSITY|20\d\d학년도 중앙대학교 논술가이드북.*)\s*$','',t.replace('\x00',' ')).strip()
def textpages(doc):return [x['text'] for x in read(R/'central-source-cache'/(doc['resource_id']+'.pages.private.json'))]
def pageat(ps,pos):
 acc=0
 for i,t in enumerate(ps):
  if pos<acc+len(t)+1:return i+1
  acc+=len(t)+1
 return len(ps)
for row in locators:
 if '인문' not in row['track']:continue
 try:
  e=next(x for x in registry['exams'] if x['examId']==row['exam_id']);qd=next(d for d in row['documents'] if d['role']=='question');sd=next(d for d in row['documents'] if d['role']=='official_solution');qp=textpages(qd);sp=textpages(sd);qt='\n'.join(qp);st='\n'.join(sp)
  p=dict(schema='essay-material-package-v1',exam_id=e['examId'],university_id=e['universityId'],package_version=1,verification_status='VERIFIED_MANIFEST',review_scope='selected_questions',exam_identity=dict(academic_year=e['year'],exam_type=e['kind'],track=e['track'],title=e['name']),questions=[],rights_status={})
  qmarks=list(re.finditer(r'\[문제\s*([123])\]',qt));assert len(qmarks)==3 and {m[1] for m in qmarks}=={'1','2','3'},'QUESTION_MARKERS_AMBIGUOUS'
  marks=list(re.finditer(r'\[문제\s*([123])\]\s*\d+점\s*만점',st))
  if len(marks)==3:
   scoreparts={int(m[1]):(m.end(), marks[i+1].start() if i<2 else len(st)) for i,m in enumerate(marks)}
  else:
   hs=list(re.finditer(r'6\.\s*채점\s*기준',st));assert len(hs)==3,'SCORING_SECTION_AMBIGUOUS'
   scoreparts={i+1:(m.end(),m.end()+re.search(r'7\.\s*예시\s*답안',st[m.end():]).start()) for i,m in enumerate(hs)}
  intents=list(re.finditer(r'3\.\s*출제\s*의도',st))
  if len(intents)==3:
   intentparts={i+1:(m.end(),m.end()+re.search(r'4\.\s*출제',st[m.end():]).start()) for i,m in enumerate(intents)}
  else:
   m=re.search(r'(?:[1234]\.\s*예시\s*답안|예시\s*답안)',st);assert m,'INTENT_SECTION_END_MISSING'
   start=re.search(r'1\.\s*제시문\s*출전',st)
   intentparts={i:(start.start() if start else 0,m.start()) for i in (1,2,3)}
  for qi,q in enumerate(e['questions']):
   number=int(q['label'].split()[-1]);m=next(m for m in qmarks if int(m[1])==number);mi=qmarks.index(m);end=qmarks[mi+1].start() if mi<2 else len(qt)
   prompt=clean(qt[m.end():end]);assert prompt,'EMPTY_PROMPT'
   length_end=re.search(r'\[\s*\d+점[^\]]*\]',prompt)
   if length_end:
    end=m.end()+len(qt[m.end():end])-len(qt[m.end():end].lstrip())+length_end.end()
    prompt=prompt[:length_end.end()]
   a,b=scoreparts[number];scoring=clean(st[a:b]);scoring=re.split(r'\[문제\s*'+str(number)+r'\]\s*채점 기준 요약표',scoring)[0]
   # Repeated report format may append a following exam card only after example answer; cut that boundary.
   scoring=re.split(r'7\.\s*예시\s*답안',scoring)[0]
   assert '내용' in scoring and re.search(r'점|평가',scoring),'SCORING_CONTENT_REQUIRED'
   assert not re.search(r'\[문제\s*'+str(number%3+1)+r'\]\s*\d+점',scoring),'FOREIGN_SCORING'
   numbered=re.split(r'(?m)^\s*\d\)\s*',scoring)
   criteria=[]
   for para in numbered[1:]:
    first=clean(para)
    # Keep complete official clauses, including wrapped sentences; never truncate at PDF line breaks.
    if len(first)>=15:criteria.append(first)
   assert len(criteria)>=2,'CRITERIA_SPLIT_REQUIRED'
   ia,ib=intentparts[number]
   if row['exam_id']=='f3c52b3d-8768-5a11-a64a-fc93be3317c0':
    im=list(re.finditer(r'\[문제\s*([123])\]',sp[0]));assert len(im)==3
    ia=im[number-1].end();ib=im[number].start() if number<3 else re.search(r'2\.\s*제시문',sp[0]).start()
   refs=[]
   def ref(role,text,d,first,last):refs.append(dict(questionId=q['id'],sourceHash=d['source_hash'],startPage=first,endPage=last,role=role,verification='VERIFIED',evidenceText=clean(text)))
   ref('question',prompt,qd,pageat(qp,m.start()),pageat(qp,end-1));ref('shared_passage','\n'.join(qp[2:8]) if row['exam_id']=='f3c52b3d-8768-5a11-a64a-fc93be3317c0' else qt,qd,3 if row['exam_id']=='f3c52b3d-8768-5a11-a64a-fc93be3317c0' else 1,8 if row['exam_id']=='f3c52b3d-8768-5a11-a64a-fc93be3317c0' else len(qp));ref('intent',st[ia:ib],sd,pageat(sp,ia),pageat(sp,ib-1))
   for c in criteria:ref('criteria',c,sd,pageat(sp,a),pageat(sp,b-1))
   ref('scoring',scoring,sd,pageat(sp,a),pageat(sp,b-1))
   p['questions'].append(dict(question_id=q['id'],source_key=q['sourceKey'],source_page_references=refs))
  for d in [qd,sd]:
   p['rights_status'][d['source_hash']]=dict(providerTransmission='APPROVED',purpose='Candidate for Owner 1-A whole-exam service approval; not yet active')
   if d['source_hash'] not in e['sourceHashes']:e['sourceHashes'].append(d['source_hash'])
  p['package_digest']=digest(p);hosted,report=load_reviewed_material(p,registry,pinned_digest=p['package_digest'],binding={},regime='held',evaluation_type='humanities',activation_approved=False)
  assert report['ready'] and set(hosted)=={q['id'] for q in e['questions']},report
  packages[e['examId']]=p;reports.append(dict(exam_id=e['examId'],year=e['year'],track=e['track'],questions=len(hosted),input_contract_pass=True,profile='EXACT_EXAM_OFFICIAL_CRITERIA_DIRECT',connection_review='WHOLE_EXAM_ID_SOURCE_CONTRACT_ONLY',activation_granted=False,criteria_counts=[len(x.frozen_cache['criteria']) for x in hosted.values()]))
 except Exception as error:reports.append(dict(exam_id=row['exam_id'],input_contract_pass=False,reason=str(error)))
(O/'central-packages.private.json').write_text(json.dumps(packages,ensure_ascii=False));(O/'central-registry.private.json').write_text(json.dumps(registry,ensure_ascii=False));(O/'central-validation.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2));print(json.dumps(reports,ensure_ascii=False))
