"""Owner-authorized local connection preparation only; no Provider or DB writes.
Artifacts remain private; Production application is a separate scoped step.
"""
import sys,json,re,base64,hashlib,io
from pathlib import Path
import pdfplumber
sys.path.insert(0,'/Users/woojinchang/development/legendstudy-service-app-20261022/tool')
from essay_lab.live_worker import digest
from essay_lab.material_runtime import load_reviewed_material
R=Path('/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/group-1a-20261025');O=R/'continuous-social'
docs={d['sha256']:d for d in json.loads((R/'continuous-source-pages.private.json').read_text())};rows=json.loads((O/'manifest.json').read_text());assets={a['exam_id']:a for a in json.loads((O/'question-pdfs/assets.private.json').read_text())};registry=json.loads((R/'continuous-text/registry.private.json').read_text());packages={};reports=[];units={}
for row in rows:
 try:
  qd,sd=docs[row['question_source_hash']],docs[row['official_source_hash']]
  for d in {qd['sha256']:qd,sd['sha256']:sd}.values():
   if not d.get('geometric_social'):
    with pdfplumber.open(d['path']) as pdf:d['pages']=[(p.extract_text(layout=False) or '').replace('\0','') for p in pdf.pages]
    d['geometric_social']=True
  qt,st='\n'.join(qd['pages']),'\n'.join(sd['pages']);year=row['year'];h=rf'\d\.\s*{year}학년도\s*(?:수시모집\s*)?(?:모의논술고사|논술고사)\s*'
  scores=list(re.finditer(h+r'채점\s*기준',st));examples=list(re.finditer(h+r'예시\s*답안',st));intents=list(re.finditer(h+r'(?:출제\s*의도|문항\s*해설)',st))
  if not intents:raise ValueError('OFFICIAL_EXPLANATION_LOCATOR_MISSING')
  if len(scores) not in (0,3):raise ValueError('SCORING_SECTION_IDENTITY_AMBIGUOUS')
  if not any(e['examId']==row['examId'] for e in registry['exams']):registry['exams'].append({k:row[k] for k in ('examId','universityId','year','kind','track','name','session','campus','questions','sourceHashes')})
  p=dict(schema='essay-material-package-v1',exam_id=row['examId'],university_id=row['universityId'],package_version=1,verification_status='VERIFIED_MANIFEST',review_scope='selected_questions',exam_identity=dict(academic_year=year,exam_type=row['kind'],track=row['track'],title=row['name']),questions=[],rights_status={})
  def page(d,pos):
   count=0
   for i,s in enumerate(d['pages'],1):
    count+=len(s)+1
    if pos<count:return i
   return len(d['pages'])
  graph=False
  for n,q in enumerate(row['questions']):
   roman=['(?:Ⅰ|I|1)','(?:Ⅱ|II|2)','(?:Ⅲ|III|3)'][n];match=re.search(r'\[\s*논제\s*'+roman+r'\s*\]',qt)
   if not match:raise ValueError('QUESTION_MARKER_MISSING')
   tail=qt[match.end():];boundary=re.search((r'(?m)^\s*\[\s*논제\s*'+['(?:Ⅱ|II|2)','(?:Ⅲ|III|3)','(?!)'][n]+r'\s*\]|')+h+r'출제\s*의도|<\s*끝\s*>',tail);end=match.end()+boundary.start() if boundary else len(qt)
   prompt=qt[match.start():end].strip();refs=[]
   def ref(role,text,d,a,b):refs.append(dict(questionId=q['id'],sourceHash=d['sha256'],startPage=page(d,a),endPage=page(d,max(a,b-1)),role=role,verification='VERIFIED',evidenceText=text.strip()))
   ref('question',prompt,qd,match.start(),end);ref('shared_passage',qt,qd,0,len(qt))
   if scores:
    score=scores[n];previous=scores[n-1].end() if n else 0;intent=next((v for v in intents if previous<v.start()<score.start()),None);example=next((v for v in examples if v.start()>score.end()),None)
    if not intent or not example:raise ValueError('OFFICIAL_SECTION_BOUNDS_MISSING')
    ref('intent',st[intent.end():score.start()],sd,intent.end(),score.start());ref('criteria',st[score.end():example.start()],sd,score.end(),example.start())
   else:
    ref('intent',st[intents[0].end():],sd,intents[0].end(),len(st));ref('criteria',prompt,qd,match.start(),end)
   entry=dict(question_id=q['id'],source_key=q['sourceKey'],source_page_references=refs)
   if n==2:
    markers=list(dict.fromkeys(re.findall(r'\(([123abc])\)',prompt)));units[q['id']]=dict(exam_id=row['examId'],labels=markers,prompt=prompt)
    graph=bool(re.search(r'그린\s*후|그림을.{0,15}그리고|그래프.{0,30}표시하시오',prompt,re.S))
    images=[]
    with pdfplumber.open(qd['path']) as pdf:
     a,b=page(qd,match.start()),page(qd,end-1)
     for i in range(a-1,b):
      image=pdf.pages[i].to_image(resolution=110).original.convert('RGB');buf=io.BytesIO();image.save(buf,format='PNG',optimize=True);raw=buf.getvalue();images.append(dict(sha256=hashlib.sha256(raw).hexdigest(),data=base64.b64encode(raw).decode(),sourceHash=qd['sha256'],startPage=i+1,endPage=i+1))
    entry['official_images']=images
   p['questions'].append(entry)
  for hsh in row['sourceHashes']:p['rights_status'][hsh]=dict(providerTransmission='APPROVED',purpose='Owner approved continuous STANDBY connection 2026-10-25')
  p['package_digest']=digest(p);hosted,report=load_reviewed_material(p,registry,pinned_digest=p['package_digest'],binding={},regime='held',evaluation_type='humanities',activation_approved=False)
  if not report['ready']:raise ValueError(str(report))
  packages[row['examId']]=p;reports.append(dict(exam_id=row['examId'],name=row['name'],status='PREPARED_NOT_DEPLOYED',graph_answer_required=graph,questions=len(hosted),bytes=len(json.dumps(p).encode())))
 except Exception as error:reports.append(dict(exam_id=row['examId'],status='CONNECTION_PENDING',reason=str(error)))
for name,value in [('packages.private.json',packages),('registry.private.json',registry),('response-units.private.json',units),('connection-status.json',reports)]: (O/name).write_text(json.dumps(value,ensure_ascii=False,indent=2))
(R/'continuous-source-pages.private.json').write_text(json.dumps(list(docs.values()),ensure_ascii=False))
print(json.dumps(reports,ensure_ascii=False))
