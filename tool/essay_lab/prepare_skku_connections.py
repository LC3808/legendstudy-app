"""Owner-authorized local connection preparation only; no Provider or DB writes.
Artifacts remain private; Production application is a separate scoped step.
"""
import json,re,hashlib,base64,io,sys
from pathlib import Path
import pdfplumber
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
sys.path.insert(0,'/Users/woojinchang/development/legendstudy-service-app-20261022/tool')
from essay_lab.live_worker import digest
from essay_lab.material_runtime import load_reviewed_material
R=Path('/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/group-1a-20261025');O=R/'continuous-skku';D={d['sha256']:d for d in json.loads((O/'source-pages.private.json').read_text())};rows=json.loads((O/'manifest.json').read_text());registry=json.loads((R/'continuous-social/registry.private.json').read_text());packages={};assets=[];reports=[];(O/'question-pdfs').mkdir(exist_ok=True)
for row in rows:
 if row['active']:continue
 try:
  qd,sd=D[row['question_source_hash']],D[row['official_source_hash']];qt,st='\n'.join(qd['pages']),'\n'.join(sd['pages']);combined=qd['sha256']==sd['sha256'];qs=list(re.finditer(r'2\.\s*문항\s*및\s*자료',qt));ends=list(re.finditer(r'3\.\s*출제\s*의도',qt));scores=list(re.finditer(r'6\.\s*채점\s*기준',st));examples=list(re.finditer(r'7\.\s*예시\s*답안',st));intents=list(re.finditer(r'3\.\s*출제\s*의도',st));mock=False
  if len(scores)!=3:
   scores=list(re.finditer(r'【\s*채점\s*지침\s*】',st));mock=True
  if len(scores)!=3:raise ValueError('OFFICIAL_SCORING_LOCATOR_MISSING')
  if combined:
   assert len(qs)==len(ends)==3,'QUESTION_SECTION_BOUNDS'
   target=O/'question-pdfs'/(row['examId']+'.pdf');regions=[];starts=[];count=0
   with pdfplumber.open(qd['path']) as pdf:
    a=[(i,m['top']) for i,p in enumerate(pdf.pages) for m in p.search(r'2\.\s*문항\s*및\s*자료')];b=[(i,m['top']) for i,p in enumerate(pdf.pages) for m in p.search(r'3\.\s*출제\s*의도')];assert len(a)==len(b)==3;c=canvas.Canvas(str(target),invariant=1)
    for start,end in zip(a,b):
     starts.append(count+1)
     for i in range(start[0],end[0]+1):
      p=pdf.pages[i];top=max(0,start[1]-2) if i==start[0] else 0;bottom=end[1]-3 if i==end[0] else p.height
      if bottom-top<20:continue
      image=p.crop((0,top,p.width,bottom)).to_image(resolution=150).original;c.setPageSize((p.width,bottom-top));c.drawImage(ImageReader(image),0,0,width=p.width,height=bottom-top);c.showPage();count+=1;regions.append(dict(source_page=i+1,bbox=[0,top,p.width,bottom]))
    c.save()
   asset=dict(exam_id=row['examId'],path=str(target),sha256=hashlib.sha256(target.read_bytes()).hexdigest(),source_hash=qd['sha256'],page_count=count,question_pages=starts,derived=True,source_regions=regions)
  else:asset=dict(exam_id=row['examId'],path=qd['path'],sha256=qd['sha256'],source_hash=qd['sha256'],page_count=len(qd['pages']),question_pages=[1,1,1],derived=False)
  def page(d,pos):
   offset=0
   for i,t in enumerate(d['pages'],1):
    offset+=len(t)+1
    if pos<offset:return i
   return len(d['pages'])
  e=next((e for e in registry['exams'] if e['examId']==row['examId']),None)
  if e is None:registry['exams'].append({k:row[k] for k in ('examId','universityId','year','kind','track','name','session','campus','questions','sourceHashes')})
  else:assert {q['id'] for q in e['questions']}=={q['id'] for q in row['questions']};e['sourceHashes']=sorted(set(e['sourceHashes'])|set(row['sourceHashes']))
  p=dict(schema='essay-material-package-v1',exam_id=row['examId'],university_id=row['universityId'],package_version=1,verification_status='VERIFIED_MANIFEST',review_scope='selected_questions',exam_identity=dict(academic_year=row['year'],exam_type=row['kind'],track=row['track'],title=e['name'] if e else row['name']),questions=[],rights_status={})
  for n,q in enumerate(row['questions']):
   if combined:qa,qb=qs[n].end(),ends[n].start()
   else:
    start=re.search(r'(?m)^\s*[\[【]\s*문제\s*'+str(n+1)+r'\s*[\]】]',qt)
    if not start:raise ValueError('QUESTION_PROMPT_MISSING_'+str(n+1))
    qa=start.start();nxt=re.search(r'(?m)^\s*[\[【]\s*문제\s*'+str(n+2)+r'\s*[\]】]',qt[start.end():]);qb=start.end()+nxt.start() if nxt else len(qt)
    asset['question_pages'][n]=page(qd,qa)
   refs=[]
   def ref(role,text,d,a,b):refs.append(dict(questionId=q['id'],sourceHash=d['sha256'],startPage=page(d,a),endPage=page(d,b-1),role=role,verification='VERIFIED',evidenceText=text.strip()))
   ref('question',qt[qa:qb],qd,qa,qb);ref('shared_passage',qt,qd,0,len(qt));score=scores[n]
   if mock:
    end=scores[n+1].start() if n<2 else len(st);body=st[score.end():end];stop=re.search(r'【\s*예시\s*답안\s*】|■\s*예시\s*답안',body);cb=score.end()+stop.start() if stop else end;ref('intent',st[:scores[0].start()],sd,0,scores[0].start());ref('criteria',st[score.end():cb],sd,score.end(),cb)
   else:
    assert len(intents)==len(examples)==3;ref('intent',st[intents[n].end():score.start()],sd,intents[n].end(),score.start());ref('criteria',st[score.end():examples[n].start()],sd,score.end(),examples[n].start())
   entry=dict(question_id=q['id'],source_key=q['sourceKey'],source_page_references=refs)
   if n>0:
    images=[]
    with pdfplumber.open(qd['path']) as pdf:
     for i in range(page(qd,qa)-1,page(qd,qb-1)):
      image=pdf.pages[i].to_image(resolution=110).original.convert('RGB');buf=io.BytesIO();image.save(buf,format='PNG',optimize=True);raw=buf.getvalue();images.append(dict(sha256=hashlib.sha256(raw).hexdigest(),data=base64.b64encode(raw).decode(),sourceHash=qd['sha256'],startPage=i+1,endPage=i+1))
    entry['official_images']=images
   p['questions'].append(entry)
  for h in row['sourceHashes']:p['rights_status'][h]=dict(providerTransmission='APPROVED',purpose='Owner approved continuous STANDBY 2026-10-25')
  p['package_digest']=digest(p);hosted,report=load_reviewed_material(p,registry,pinned_digest=p['package_digest'],binding={},regime='held',evaluation_type='humanities',activation_approved=False)
  if not report['ready']:raise ValueError(str(report))
  packages[row['examId']]=p;assets.append(asset);reports.append(dict(exam_id=row['examId'],name=row['name'],status='PREPARED_NOT_DEPLOYED'))
 except Exception as error:reports.append(dict(exam_id=row['examId'],name=row['name'],status='CONNECTION_PENDING',reason=str(error)))
for name,value in [('packages.private.json',packages),('registry-worker.private.json',registry),('question-pdfs/assets.private.json',assets),('connection-status.json',reports)]: (O/name).write_text(json.dumps(value,ensure_ascii=False,indent=2))
print(json.dumps(reports,ensure_ascii=False))
