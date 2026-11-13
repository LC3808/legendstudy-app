"""Official Science bindings using existing reviewed Essay result contract; no network."""
import argparse,base64,hashlib,json,unicodedata
from pathlib import Path
import fitz
from prepare_ewha_mock_candidates import clean,image_bytes
from prepare_ewha_mock_essay_public import digest,dump
from essay_lab.material_runtime import load_reviewed_material
R=Path(__file__).resolve().parents[1];O=R/'supabase/candidates/khu_mock_science_20261112';P=R/'.local/khu-mock-science-20261112'
ROLE={'problem':'question','intent':'intent','rubric':'criteria','solution':'example_answer'}
def sha(b):return hashlib.sha256(b).hexdigest()
def prepare(root,registry_rows,web_registry,math_model):
 all_paths={unicodedata.normalize('NFC',p.name):p for p in root.rglob('*.pdf')};docs={};document_rows={}
 def source(name,pages):
  p=all_paths[name];raw=p.read_bytes();h=sha(raw)
  if h not in docs:docs[h]=fitz.open(stream=raw,filetype='pdf');document_rows[h]=dict(sha256=h,title=name,page_count=len(docs[h]),object_key=h+'.pdf',resource_id=None)
  assert min(pages)>0 and max(pages)<=len(docs[h]);return dict(file=name,sha256=h,pages=pages)
 def existing(ref):
  result=source(ref['file'],ref['pages']);assert result['sha256']==ref['sha256'];return result
 status=json.loads((R/'supabase/candidates/remaining_51_20261112/remaining-51-status.json').read_text())['questions'];science=[q for q in status if q.get('cause_type')=='SCIENCE_RUNTIME_AND_PERSISTENCE'];assert len(science)==18
 swu={q['question_id']:q for q in json.loads((R/'supabase/candidates/swu_public_20261112/science-not-ready.json').read_text())}
 packages={};registry={'exams':[]};receipts=[]
 rows=json.loads(registry_rows.read_text());web=json.loads(web_registry.read_text())
 for eid in sorted({q['exam_id'] for q in science}):
  erows=[r for r in rows if r['exam']['id']==eid];e=erows[0]['exam'];qe=[q for q in science if q['exam_id']==eid]
  we=next((x for x in web['exams'] if x.get('dbExamId')==eid or {q['key'] for q in x['questions']}=={r['question']['question_key'] for r in erows}),{'sourceHashes':[]})
  reg=dict(examId=eid,universityId=e['university_id'],year=e['admission_year'],kind=e['exam_kind'],track=e['field_or_division'],session=e['session_label'],campus=e['campus'],name=e['exam_name'],sourceHashes=list(we['sourceHashes']),questions=[dict(id=r['question']['id'],sourceKey=r['question']['question_key'],label=r['question']['label'],order=r['question']['display_order']) for r in erows]);registry['exams'].append(reg)
  pack=dict(schema='essay-material-package-v1',exam_id=eid,university_id=e['university_id'],package_version=1,verification_status='VERIFIED_MANIFEST',review_scope='selected_questions',exam_identity=dict(academic_year=reg['year'],exam_type=reg['kind'],track=reg['track'],title=reg['name']),rights_status={},questions=[])
  for qr in reg['questions']:
   qid=qr['id'];q=next((q for q in qe if q['question_id']==qid),None);math=q is None
   if math:
    mp=json.loads((R/'.local/kyunghee-production-preflight-20261112'/(qid+'.package.private.json')).read_text());mw=json.loads((R/'.local/kyunghee-production-preflight-20261112'/(qid+'.worker.private.json')).read_text());refs={k:existing(v) for k,v in json.loads(mw['manifest_text']).items()};subject=None
   elif qid in swu:
    refs={k:existing(v) for k,v in swu[qid]['refs'].items()};subject='biology' if q['label'].endswith('2') else 'integrated_science'
   else:
    subject=next(v for k,v in [('물리','physics'),('화학','chemistry'),('생명','biology')] if k in q['label']);second='Ⅳ' in q['label'] or 'IV' in q['label'];ix=int(second)
    if q['year']==2026:
     name='2026학년도 경의대 수시 논술_의약학 문제,해설.pdf'
     data={'physics':[([3,4],[16],[17],[17,18]),([3,4],[20],[20],[21,22])],'chemistry':[([5,6],[25],[25],[26,27]),([5,6],[29],[30],[30,31])],'biology':[([7,8],[33],[34],[35]),([7,8],[37],[38],[39])]}[subject][ix]
     refs={k:source(name,v) for k,v in zip(ROLE,data)}
    else:
     korean={'physics':'물리','chemistry':'화학','biology':'생명과학'}[subject];base=f'2027학년도 경희대 모의논술_의약학({korean}) '
     pp=[2,4] if subject=='physics' and second else [2,3]
     data={'physics':[([1],[2],[3]),([4],[5],[5])],'chemistry':[([1],[1],[2]),([3],[3],[4,5])],'biology':[([1],[2],[2]),([3],[4],[4])]}[subject][ix]
     refs={'problem':source(base+'문제.pdf',pp),**{k:source(base+'해설,답안.pdf',v) for k,v in zip(['intent','rubric','solution'],data)}}
   reg['sourceHashes']=sorted(set(reg['sourceHashes'])|{refs['problem']['sha256']})
   mappings=[]
   for key,ref in refs.items():
    text='\n'.join(clean(docs[ref['sha256']][n-1].get_text()) for n in ref['pages']).strip() or '[공식 원문 이미지 참조]'
    if key=='rubric' and not math:
     text=f"{qr['label']} 공식 평가 근거 — 연결된 원문과 이미지의 해당 문항 기준.\n"+text+'\n[서비스 내부 안내: 대학 공식 배점과 별개]\n공식 기준의 개념·조건·추론·자료 해석 중 이 문항에서 요구한 항목만 평가한다. 계산·단위는 공식 문항에서 요구할 때 검토한다. 다른 소문항이나 과목의 기준을 적용하지 않는다. 누락·잘못된 인과·자료와 결론의 불일치는 답안의 근거를 들어 설명한다. 아래 결과 수준 1~5는 서비스 수준이며 대학의 점수나 감점이 아니다.'
    mappings.append(dict(questionId=qid,sourceHash=ref['sha256'],startPage=min(ref['pages']),endPage=max(ref['pages']),role=ROLE[key],verification='VERIFIED',evidenceText=text))
   mappings.append(dict(mappings[0],role='shared_passage'))
   # Example solution remains an explicit reference role, not relabelled as criteria.
   # Existing adapter forwards question/intent/criteria images; criterion text links
   # official answer pages through a separate clearly labelled reference paragraph.
   solution=mappings[3];criterion=mappings[2]
   criterion['evidenceText']+='\n[공식 예시답안 참고 — 채점기준과 구분]\n'+solution['evidenceText']
   # Separate page ranges make solution images available with their actual source.
   mappings.append(dict(solution,role='criteria',evidenceText='공식 예시답안과의 근거 비교(서비스 평가 요소, 공식 배점 없음). 동치인 올바른 풀이를 허용한다.\n'+solution['evidenceText']))
   images=[]
   for h in {v['sha256'] for v in refs.values()}:
    for n in sorted({n for v in refs.values() if v['sha256']==h for n in v['pages']}):
     raw=image_bytes(docs[h][n-1]);images.append(dict(sha256=sha(raw),data=base64.b64encode(raw).decode(),sourceHash=h,startPage=n,endPage=n))
    pack['rights_status'][h]=dict(providerTransmission='APPROVED',authority='Owner 2026-11-12 service implementation; rights handled separately by Owner',studentUse='EXISTING_QUESTION_ONLY_MANIFEST')
   assert len(images)<=10
   entry=dict(question_id=qid,source_key=qr['sourceKey'],source_page_references=mappings,official_images=images)
   if math:
    math_rows=mp['existing_schema_rows'];entry.update(evaluation_engine='math',math_context=dict(exam_id=eid,question_id=qid,leaf=math_rows['math_subproblems'][0],problem=math_rows['math_problems'][0],profile=math_rows['math_evaluation_profiles'][0],criteria=math_rows['math_scoring_criteria'],solutions=math_rows['math_canonical_solutions'],official_images=images,provider_binding=dict(provider='openai',model=math_model)))
   else:
    entry.update(evaluation_engine='science',science_context=dict(contract='science-reasoning-v1',capability='SCIENCE_REASONING',subject=subject,question_id=qid,source_sha256=refs['problem']['sha256'],criteria_basis='OFFICIAL_WITH_EXPLICIT_SERVICE_GUIDANCE'))
   pack['questions'].append(entry)
   receipts.append(dict(exam_id=eid,question_id=qid,subject=subject,engine=entry['evaluation_engine'],references=refs,images=len(images),official_scoring_preserved=True,university_points_not_inferred=True))
  pack['package_digest']=digest(pack);packages[eid]=pack
 for eid,pack in packages.items():
  hosted,report=load_reviewed_material(pack,registry,pinned_digest=pack['package_digest'],binding={},regime='offline-only',evaluation_type='science',activation_approved=True)
  assert report['ready'] and len(hosted)==len(pack['questions'])
 dump(P/'science-packages.private.json',packages);dump(P/'science-registry.private.json',registry);dump(P/'science-documents.private.json',document_rows)
 dump(O/'science-package-receipt.json',dict(exams=5,science_questions=18,existing_math_children=4,questions=receipts,provider_calls=0,production_writes=0,published=0))
 print(dict(exams=5,science=18,existing_math=4,provider_calls=0))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--source-root',type=Path,required=True);p.add_argument('--registry-rows',type=Path,required=True);p.add_argument('--web-registry',type=Path,required=True);p.add_argument('--math-model',required=True);a=p.parse_args();prepare(a.source_root,a.registry_rows,a.web_registry,a.math_model)
