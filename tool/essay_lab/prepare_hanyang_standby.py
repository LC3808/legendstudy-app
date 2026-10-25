"""Reuse official archives and existing IDs; local preparation only, no Provider."""
import json,re,hashlib,uuid,importlib.util,sys,base64,io
from pathlib import Path
import pdfplumber
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from essay_lab.live_worker import digest
from essay_lab.material_runtime import load_reviewed_material
R=Path('/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/hanyang-standby-20261025')
APP=Path('/Users/woojinchang/development/legendstudy-service-app-20261022');WEB=Path('/Users/woojinchang/development/legendstudy-release-20261024')
read=lambda p:json.loads(p.read_text());docs=read(R/'source-pages.private.json');old=read(R/'registry-all.private.json');resources=read(R/'resources.private.json')
for d in docs:d['pages']=[s.replace('\x00',' ') for s in d['pages']]
N=uuid.uuid5(uuid.NAMESPACE_URL,'https://github.com/LC3808/legendstudy-app/essay-source-registration/v1')
def identity(t):
 m=re.search(r'오후\s*([12])',t)
 return int(t[:4]),'mock' if '모의' in t else 'admission','상경계열' if '상경' in t else '인문계열',('오후 '+m[1]) if m else None
rows=[];pending=[];packages={};assets=[]
registry=read(R.parent/'group-1a-20261025/continuous-skku/registry-worker.private.json')
for qd in [d for d in docs if '문제' in d['title']]:
 year,kind,track,session=identity(qd['title']);matches=[e for e in old if (e['admission_year'],e['exam_kind'],e['field_or_division'],e['session_label'])==(year,kind,track,session)];assert len(matches)<=1;e=matches[0] if matches else None
 official=[d for d in docs if any(w in d['title'] for w in ['출제의도','평가기준']) and identity(d['title'])==(year,kind,track,session)]
 if not official and year==2024 and kind=='admission' and track=='인문계열':official=[d for d in docs if d['title'].startswith('2024') and '인문' in d['title'] and '통합' in d['title']]
 assert len(official)==1,(qd['title'],[d['title'] for d in official]);sd=official[0];count=2 if track=='상경계열' else 1
 key='source:'+hashlib.sha256(f'hanyang|{year}|{kind}|{track}|{session}|None'.encode()).hexdigest();eid=e['id'] if e else str(uuid.uuid5(N,'exam/'+key));eq=e['questions'] if e else [];assert not eq or len(eq)==count
 qs=[dict(id=q['id'],sourceKey=q['question_key'],label=q['label'],order=q['display_order']) for q in eq] if eq else [dict(id=str(uuid.uuid5(N,'question/'+key+':'+str(n))),sourceKey=key+':'+str(n),label='문제 '+str(n),order=n-1) for n in range(1,count+1)]
 documents=[]
 for d in [qd,sd]:
  rr=[x for x in resources if x['title']==d['title']];documents.append(dict(title=d['title'],sha256=d['sha256'],local_path=d['path'],page_count=len(d['pages']),resource_id=rr[0]['id'] if len(rr)==1 else None))
 row=dict(examId=eid,sourceKey=key,existingExam=bool(e),universityId='1090e1be-174e-5042-abd3-ca929c6e26f8',year=year,kind=kind,track=track,session=session,campus=None,examKey=e['exam_key'] if e else 'source-'+key[7:],name=e['exam_name'] if e else f'{year}학년도 한양대학교 '+('모의논술' if kind=='mock' else '수시논술')+' '+track+(' '+session if session else ''),sourceHashes=sorted({qd['sha256'],sd['sha256']}),questions=qs,documents=documents,question_source_hash=qd['sha256'],official_source_hash=sd['sha256'],parent_count=count,active=bool(e and e['runtime']))
 rows.append(row)
 if not eq:pending.append(row)
 if track=='상경계열':row['hold']='MIXED_MATH_SINGLE_RESERVATION_ROUTE_REQUIRED';continue
 if row['active']:continue
 qt='\n'.join(qd['pages']);st='\n'.join(sd['pages']);sa,sb=0,len(st)
 if '통합' in sd['title']:
  headers=list(re.finditer(r'(?m)^인\s*문\s*계\s*출제\s*의도\s*및\s*평가\s*지침\s*오후\s*[12]',st));assert len(headers)==2;ix=0 if session=='오후 1' else 1;sa=headers[ix].start();sb=headers[ix+1].start() if ix==0 else len(st)
 sub=st[sa:sb];score=re.search(r'(?m)^6\.\s*채점\s*기준',sub) or re.search(r'(?m)^1\.\s*평가의\s*내용',sub);assert score,sd['title'];ca=sa+score.start();example=re.search(r'(?m)^7\.\s*예시\s*답안',st[ca:sb]);cb=ca+example.start() if example else sb
 q=qs[0]
 def page(d,pos):
  offset=0
  for i,t in enumerate(d['pages'],1):
   offset+=len(t)+1
   if pos<offset:return i
  return len(d['pages'])
 refs=[]
 for role,d,text,a,b in [('question',qd,qt,0,len(qt)),('shared_passage',qd,qt,0,len(qt)),('intent',sd,st[sa:ca],sa,ca),('criteria',sd,st[ca:cb],ca,cb)]:refs.append(dict(questionId=q['id'],sourceHash=d['sha256'],startPage=page(d,a),endPage=page(d,b-1),role=role,verification='VERIFIED',evidenceText=text))
 images=[]
 with pdfplumber.open(qd['path']) as pdf:
  for i,p in enumerate(pdf.pages):
   im=p.to_image(resolution=100).original.convert('RGB');buf=io.BytesIO();im.save(buf,format='PNG');raw=buf.getvalue();images.append(dict(sha256=hashlib.sha256(raw).hexdigest(),data=base64.b64encode(raw).decode(),sourceHash=qd['sha256'],startPage=i+1,endPage=i+1))
 package=dict(schema='essay-material-package-v1',exam_id=eid,university_id=row['universityId'],package_version=1,verification_status='VERIFIED_MANIFEST',review_scope='selected_questions',exam_identity=dict(academic_year=year,exam_type=kind,track=track,title=row['name']),questions=[dict(question_id=q['id'],source_key=q['sourceKey'],source_page_references=refs,official_images=images)],rights_status={h:dict(providerTransmission='APPROVED',purpose='Owner Hanyang STANDBY 2026-10-25') for h in row['sourceHashes']})
 package['package_digest']=digest(package)
 prior=next((e for e in registry['exams'] if e['examId']==eid),None)
 if prior:assert {q['id'] for q in prior['questions']}=={q['id'] for q in qs}
 else:registry['exams'].append({k:row[k] for k in ('examId','universityId','year','kind','track','name','session','campus','questions','sourceHashes')})
 _,report=load_reviewed_material(package,registry,pinned_digest=package['package_digest'],binding={},regime='held',evaluation_type='humanities',activation_approved=False);assert report['ready'],report;packages[eid]=package
 assets.append(dict(exam_id=eid,path=qd['path'],sha256=qd['sha256'],source_hash=qd['sha256'],page_count=len(qd['pages']),question_pages=[1],derived=False))
for name,data in [('manifest.json',rows),('packages.private.json',packages),('registry-worker.private.json',registry),('assets.private.json',assets)]: (R/name).write_text(json.dumps(data,ensure_ascii=False,indent=2))
spec=importlib.util.spec_from_file_location('registration',WEB/'scripts/essay-materials/prepare_registration.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);o=R/'registry-sql';o.mkdir(exist_ok=True);sql=m.sql_document(dict(exams=pending));sql=sql.replace("and id<>eid and exam_key not like 'source-%'","and id<>eid and field_or_division=e->>'track' and session_label is not distinct from e->>'session'");(o/'apply.sql').write_text(sql)
ids=','.join("'"+r['examId']+"'::uuid" for r in pending);(o/'precheck.sql').write_text(f'select not exists(select 1 from public.essay_questions where essay_exam_id in ({ids})) as candidate_questions_absent;')
sets={r['examId']:sorted(q['id'] for q in r['questions']) for r in rows};literal=json.dumps(sets).replace("'","''");(o/'postcheck.sql').write_text("select not exists(select 1 from jsonb_each('"+literal+"'::jsonb) e where (select jsonb_agg(id::text order by id::text) from public.essay_questions where essay_exam_id=e.key::uuid) is distinct from e.value) as exact_question_sets;")
(o/'rollback.sql').write_text('-- Preserve metadata/IDs. Registration grants no runtime permission. Disable new public/runtime scope via connection rollback; never delete student records.\nselect true as metadata_preserved;\n')
print(json.dumps(dict(targets=len(rows),humanities=sum(r['track']=='인문계열' for r in rows),mixed=sum(r['track']=='상경계열' for r in rows),new_packages=len(packages),new_registry=len(pending),questions=sum(len(r['questions']) for r in pending))))
