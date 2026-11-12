"""Offline Ewha source/package adapter. No network, DB, Provider or publication.

Original PDFs are read only. Public manifests contain identities/hashes/locators;
raw extracted text and source images stay in ignored .local. Reuses Math v1 and
Essay contract 1.3; does not implement an evaluator or infer a university rubric.
"""
from __future__ import annotations
import argparse,base64,copy,hashlib,json,re,unicodedata,uuid
from pathlib import Path
import fitz
from essay_lab.natural_expansion import build_review_package
from essay_lab.live_worker import digest as object_digest,package as essay_package
from essay_lab.package_registry import bind_registered_package
from essay_lab.task20_priority_packages import registration_sql
from essay_lab.four_university_connection import ORDER
R=Path(__file__).resolve().parents[1]
OUT=R/'supabase/candidates/ewha_essay_20261112'
PRIVATE=R/'.local/ewha-essay-20261112'
NS=uuid.uuid5(uuid.NAMESPACE_URL,'https://github.com/LC3808/legendstudy-app/essay-source-registration/v1')
UID='fdc7e693-15a2-47fc-b080-4f14e9274d95'
VERSION='ewha-official-20261112-v1'
def sha(b):return hashlib.sha256(b).hexdigest()
def clean(s):return re.sub('[\x00-\x08\x0b-\x1f]',' ',s)
def compact(s):return re.sub(r'\s+','',clean(s))
def dump(p,x):p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n')
def resolve(root,name):
 matches=[p for p in root.iterdir() if unicodedata.normalize('NFC',p.name)==name]
 if len(matches)!=1:raise ValueError('SOURCE_MISSING_OR_AMBIGUOUS:'+name)
 return matches[0]
def slices(doc,section,title,stop):
 """Retain physical page geometry. Stop before official examples in Essay input."""
 result=[];active=False
 for n in range(section['start'],section['end']+1):
  page=doc[n-1];lines=[]
  for b in page.get_text('dict')['blocks']:
   for line in b.get('lines',[]):
    text=''.join(s['text'] for s in line['spans']);lines.append((line['bbox'],text))
  hits=[(bb,t) for bb,t in lines if title in compact(t) and len(compact(t))<60]
  headers=[bb[3] for bb,t in lines if bb[1]<80 and ('학년도' in t or re.fullmatch(r'20\d\d|[ⅠⅡⅢ]|인문계열.*|자연계열.*',compact(t)))]
  top=max([35]+[y+5 for y in headers])
  if not active:
   if not hits:continue
   top=min(bb[1] for bb,t in hits)-2;active=True
  ends=[bb[1] for bb,t in lines if stop in compact(t) and len(compact(t))<60 and bb[1]>top+2]
  bottom=min(ends)-2 if ends else page.rect.height-35
  assert bottom>top
  clip=fitz.Rect(25,top,page.rect.width-25,bottom)
  text=clean(page.get_text(clip=clip)).strip()
  # The next page may contain only a running header before the example-answer
  # heading. Retain image-based official tables even when text is unavailable.
  raster=any((fitz.Rect(x['bbox']) & clip).get_area()>500 for x in page.get_image_info())
  if text or raster:result.append(dict(page=n,clip=list(clip),text=text or '[공식 원문 이미지 참조]'))
  if ends:break
 if not result:raise ValueError('OFFICIAL_SECTION_NOT_FOUND:'+title)
 return result

def image_bytes(page,clip=None):
 rect=fitz.Rect(clip) if clip else page.rect
 scale=1100/max(rect.width,rect.height)
 return page.get_pixmap(matrix=fitz.Matrix(scale,scale),clip=rect,colorspace=fitz.csGRAY).tobytes('png')

def prepare(plan,root):
 assert plan['publication_allowed'] is False and plan['provider_allowed'] is False
 assert root.is_dir() and '.local' in PRIVATE.parts
 OUT.mkdir(parents=True,exist_ok=True);PRIVATE.mkdir(parents=True,exist_ok=True)
 cache_docs={};preservation=[]
 for f in plan['files']:
  path=resolve(root,f['filename']);raw=path.read_bytes()
  assert sha(raw)==f['sha256'];d=fitz.open(stream=raw,filetype='pdf');assert len(d)==f['pages']
  cache_docs[f['sha256']]=d;preservation.append((path,f['sha256'],path.stat().st_mtime_ns))
 exams=plan['exams'];assert len({e['examId'] for e in exams})==len(exams)
 ids=[q['id'] for e in exams for q in e['questions']];assert len(ids)==len(set(ids))==87
 receipts=[];math_packages=[]
 for e in exams:
  p=e['problem'];s=e['solution'];pd=cache_docs[p['sha256']];sd=cache_docs[s['sha256']]
  for q in e['questions']:
   row={k:copy.deepcopy(q[k]) for k in ('id','sourceKey','label','number','production_registry_exists','evidence')}
   row.update(exam_id=e['examId'],year=e['year'],kind=e['kind'],track=e['track'],publication_allowed=False,provider_allowed=False)
   if not q['official_rubric_available']:
    row.update(status='SOURCE_READY_RUBRIC_MISSING',reason='Official solution/intent exists; explicit scoring criteria absent. Do not derive rubric from examples.');receipts.append(row);continue
   section=q['solution_section'];rubrics=slices(sd,section,'채점기준','예시답안')
   if e['track'].startswith('자연'):
    # Reuse existing schema builder, then replace source pointers with the two
    # actual PDF identities; virtual indexing never escapes into source locators.
    pt=[clean(x.get_text()) for x in pd];st=[clean(x.get_text()) for x in sd];offset=len(pt)
    ev=copy.deepcopy(q['evidence']);virtual={'problem':ev['problem'],'intent':[offset+x for x in ev['intent']],'rubric':[offset+x['page'] for x in rubrics],'solution':[offset+x for x in ev['solution']]}
    spec=dict(question_id=q['id'],number=q['number'],label=q['label'],display_order=q['order'],evidence=virtual)
    package=build_review_package(dict(exam_id=e['examId'],admission_year=e['year'],field_or_division=e['track'],source={'file':p['filename'],'sha256':p['sha256']}),spec,pt+st)
    rows=package['existing_schema_rows'];rows['math_problem_sets'][0]['label']=f"이화여대 {e['year']} {e['track']} {q['label']}"
    for x in rows['math_source_artifacts']:
     role={'QUESTION':'problem','INTENT':'intent','SCORING':'rubric','SOLUTION':'solution'}[x['source_role']];src=p if role=='problem' else s;pages=ev[role] if role!='rubric' else [v['page'] for v in rubrics]
     x.update(source_url='urn:sha256:'+src['sha256'],content_sha256=src['sha256'],locator=f"{src['filename']} / {q['label']} PDF {','.join(map(str,pages))}쪽")
    for i,x in enumerate(rows['math_scoring_criteria']):
     x.update(criterion_key=f"q{q['number']}-official-page-{rubrics[i]['page']}",description=f"{s['filename']} {q['label']} 공식 채점 기준 PDF {rubrics[i]['page']}쪽 원문 이미지와 아래 추출문. 원문 배점 유지.\n{rubrics[i]['text']}")
    refs={role:dict(file=(p if role=='problem' else s)['filename'],sha256=(p if role=='problem' else s)['sha256'],pages=pages) for role,pages in ev.items()};refs['rubric']['pages']=[v['page'] for v in rubrics]
    images=[]
    for src,d in [(p,pd),(s,sd)]:
     for n in sorted({n for v in refs.values() if v['sha256']==src['sha256'] for n in v['pages']}):
      b=image_bytes(d[n-1]);images.append(dict(data=base64.b64encode(b).decode(),sha256=sha(b),source_sha256=src['sha256'],physical_page=n,roles=[k for k,v in refs.items() if v['sha256']==src['sha256'] and n in v['pages']]))
    manifest=json.dumps(refs,ensure_ascii=False,sort_keys=True);wire=json.dumps(images,sort_keys=True,separators=(',',':'))
    assert 1<=len(images)<=24 and len(wire.encode())<1800000
    payload=dict(question_id=q['id'],exam_id=e['examId'],manifest_text=manifest,images_text=wire,sha256=sha((manifest+wire).encode()))
    package.update(technical_ready=False,remaining=['CANONICAL_REGISTRATION_APPROVAL','PDF_DISPLAY_ACCESS','PRODUCTION_PREFLIGHT','WEB_APP_ADMISSION_SCOPE'])
    package['existing_schema_rows']={t:rows[t] for t in ORDER}
    dump(PRIVATE/(q['id']+'.package.private.json'),package);dump(PRIVATE/(q['id']+'.worker.private.json'),payload);math_packages.append(package)
    row.update(status='LOCAL_PACKAGE_READY',worker_contract='existing Math v1 official references',package_sha256=object_digest(package),worker_sha256=payload['sha256'],images=len(images),image_bytes=len(wire.encode()),leaf_id=package['ids']['leaf'],schema_rows=sum(map(len,rows.values())))
   else:
    ident=lambda x:str(uuid.uuid5(uuid.UUID(q['id']),VERSION+':'+x))
    evidence=[];images=[];criteria=[]
    # Full official student PDF supplies shared passages; the question selector
    # is explicit and unchanged. No solution PDF is exposed to students.
    for role,src,pages in [('question',p,q['evidence']['problem']),('passage',p,q['evidence']['problem'])]:
     text=f"대상 {q['label']}. 공식 문제지의 해당 문항에 답하시오.\n"+'\n'.join(clean(pd[n-1].get_text()) for n in pages)
     evidence.append(dict(binding=dict(id=ident(role),role=role,hash=src['sha256'],version=VERSION,locator=f"{src['filename']} PDF {pages} / {q['label']}"),text=text,text_sha256=sha(text.encode())))
    for role,items in [('exam_intent',slices(sd,section,'출제의도','출제근거')),('scoring_criteria',rubrics)]:
     text='\n'.join(x['text'] for x in items);eid=ident(role)
     evidence.append(dict(binding=dict(id=eid,role=role,hash=s['sha256'],version=VERSION,locator=f"{s['filename']} PDF {[x['page'] for x in items]} / {q['label']}"),text=text,text_sha256=sha(text.encode())))
     for i,item in enumerate(items):
      b=image_bytes(sd[item['page']-1],item['clip']);images.append(dict(sha256=sha(b),data=base64.b64encode(b).decode(),evidence_ids=[eid]))
    criteria.append(dict(binding=dict(id=ident('criterion:official-rubric'),version=VERSION),label=f"{s['filename']} {q['label']} 공식 채점 기준 전체. PDF {[x['page'] for x in rubrics]}쪽의 연결된 원문 이미지와 아래 추출문을 함께 참조한다. 원문 배점을 유지하고 새 기준을 생성하지 않는다.\n"+'\n'.join(x['text'] for x in rubrics)))
    for n in q['evidence']['problem']:
     b=image_bytes(pd[n-1]);images.append(dict(sha256=sha(b),data=base64.b64encode(b).decode(),evidence_ids=[ident('question'),ident('passage')]))
    assert len(images)<=10
    cache=dict(contract_version='1.3',evidence=evidence,criteria=criteria,official_images=images)
    assignment={k:e[k] for k in ('examId','universityId','year','kind','track','session','campus')};assignment.update(evaluationType='business' if e['track']=='인문계열Ⅱ' and q['number']==3 else 'humanities',questionId=q['id'],sourceKey=q['sourceKey'],questionSourceHash=p['sha256'],cacheSha256=object_digest(cache))
    bind_registered_package({'exams':exams},assignment,cache,binding={},regime='UNCONFIGURED_LOCAL',approved_processing=False,reviewed_cache=False)
    answer='오프라인 계약 검사 전용 답안입니다.';claim={'answer':answer,'input':{'contract_version':'1.3','attempt_id':'offline','answer_hash':sha(answer.encode()),'evidence':[x['binding'] for x in evidence],'criteria':[x['binding'] for x in criteria],'scaffolding_context':{'items':[]}}}
    essay_package(claim,cache)
    dump(PRIVATE/(q['id']+'.essay.private.json'),dict(cache=cache,assignment=assignment,claim=claim))
    row.update(status='LOCAL_PACKAGE_READY',worker_contract='existing Essay 1.3 '+assignment['evaluationType'],package_sha256=object_digest(cache),images=len(images),criteria=len(criteria))
   row['rubric_representation']='official_image_and_literal_extraction_no_generated_criteria'
   row['rubric_geometry']=[{k:v for k,v in x.items() if k!='text'} for x in rubrics];receipts.append(row)
 (PRIVATE/'math-registration.private.sql').write_text(registration_sql(math_packages))
 for path,h,mtime in preservation:assert sha(path.read_bytes())==h and path.stat().st_mtime_ns==mtime
 counts=dict(source_exams=len(exams),source_questions=len(ids),production_registry_exams=sum(e['existingExam'] for e in exams),production_registry_questions=sum(q['production_registry_exists'] for e in exams for q in e['questions']),local_package_questions=sum(x['status']=='LOCAL_PACKAGE_READY' for x in receipts),math_packages=len(math_packages),essay_packages=sum(x.get('worker_contract','').startswith('existing Essay') for x in receipts),rubric_missing=sum(x['status']=='SOURCE_READY_RUBRIC_MISSING' for x in receipts),published=0,publication_ready_now=0,provider_calls=0,source_files_unchanged=len(preservation))
 dump(OUT/'package-receipt.json',dict(status='LOCAL_ONLY_NOT_TECH_READY',counts=counts,questions=receipts));print(json.dumps(counts))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--source-root',type=Path,required=True);a=p.parse_args();prepare(json.loads((OUT/'source-plan.json').read_text()),a.source_root)
