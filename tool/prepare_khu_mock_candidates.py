"""Reuse existing Math schema for four KHU mock questions. Offline, original PDFs immutable."""
import argparse,base64,hashlib,json,re,unicodedata
from pathlib import Path
import fitz
from essay_lab.natural_expansion import build_review_package
from essay_lab.four_university_connection import ORDER
from essay_lab.task20_priority_packages import registration_sql
from prepare_ewha_mock_candidates import image_bytes,clean,service_criteria
R=Path(__file__).resolve().parents[1]
OUT=R/'supabase/candidates/khu_mock_science_20261112'
PRIVATE=R/'.local/khu-mock-science-20261112'
EXAM='c47c6ed4-a3fc-5758-b773-9d7ce4762725'
IDS=['f7733560-15d9-530e-aaae-6d04da444d51','f1ae8fd9-d4cb-5fb5-944b-9283e77cd59d','8d2b2a5b-38e1-5c2a-a7c4-92396a2eeeb5','c6b54603-e483-5a5d-b4c3-d4044b40a0d2']
FILES=[('2022학년도 경희대 모의논술_자연계 문제.pdf','dd083814f7aa1d7290c22ab8a38f4b0eea19513b27a8470ebc4ad01700e3756e',3),('2022학년도 경희대 모의논술_자연계 예시답안,해설.pdf','ab8ab45af576121d66187f81b85244175813f5acf12f9560c874bc35710da005',7)]
def digest(v):return hashlib.sha256(v).hexdigest()
def save(path,v):path.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def prepare(root):
 OUT.mkdir(exist_ok=True,parents=True);PRIVATE.mkdir(exist_ok=True,parents=True)
 docs=[];original=[]
 for name,sha,pages in FILES:
  matches=[p for p in root.rglob('*.pdf') if unicodedata.normalize('NFC',p.name)==name];assert len(matches)==1
  p=matches[0];raw=p.read_bytes();assert digest(raw)==sha
  doc=fitz.open(stream=raw,filetype='pdf');assert len(doc)==pages
  docs.append(doc);original.append((p,sha,p.stat().st_mtime_ns))
 pd,sd=docs;comment=clean(sd[6].get_text())
 boundaries=[comment.index('[논제'+n+'](1)') for n in ['I','2','3','4']]+[comment.index('제시문출처')]
 packages=[];receipts=[]
 concepts=['인수분해·절대부등식·4차방정식과 조건에 맞는 최댓값; 함수의 극대·극소 판정', '다항식 인수분해·경우 분류·중복/누락 없는 경우의 수; 수학적 확률', '이등변삼각형·삼각함수 덧셈정리·닮음·넓이; 수열/급수의 극한', '원주각·중심각·이등변삼각형·피타고라스; 미분계수·증감·최댓값/최솟값']
 for i,qid in enumerate(IDS):
  number=i+1;label=f'문제 {number}';official=comment[boundaries[i]:boundaries[i+1]].strip()
  evidence=dict(problem=[1,2 if i<2 else 3],intent=[7],rubric=[7],solution=[[1,2],[3],[4,5],[6]][i])
  virtual={k:[n+(0 if k=='problem' else 3) for n in pages] for k,pages in evidence.items()}
  texts=[clean(p.get_text()) for p in pd]+[clean(p.get_text()) for p in sd]
  texts[9]=official # Exact per-question official description, not neighbouring criteria.
  pack=build_review_package(dict(exam_id=EXAM,admission_year=2022,field_or_division='자연계',source={'file':FILES[0][0],'sha256':FILES[0][1]}),dict(question_id=qid,number=number,label=label,display_order=i,evidence=virtual),texts)
  rows=pack['existing_schema_rows'];rows['math_problem_sets'][0]['label']=f'경희대 2022 모의 자연계 {label}'
  for row in rows['math_source_artifacts']:
   role={'QUESTION':'problem','INTENT':'intent','SCORING':'rubric','SOLUTION':'solution'}[row['source_role']];name,sha,_=FILES[0 if role=='problem' else 1]
   row.update(source_url='urn:sha256:'+sha,content_sha256=sha,locator=f"{name} / {label} PDF {','.join(map(str,evidence[role]))}쪽")
  criterion=rows['math_scoring_criteria'][0]
  criterion.update(criterion_key=f'q{number}-service-guidance-page-7',official_points=None,description=service_criteria(label,official)+'\n[서비스 내부 점검 — 공식 배점 아님]\n핵심 개념: '+concepts[i]+'\n각 소문항의 조건 적용과 풀이 근거를 구분한다. 공식 예시답안의 대응 소문항과 대조하되 동치인 다른 올바른 풀이도 허용한다. 조건 누락·경우 중복·계산/논리 오류를 답안 근거와 연결하며 수치 감점은 임의 생성하지 않는다.')
  refs={k:dict(file=FILES[0 if k=='problem' else 1][0],sha256=FILES[0 if k=='problem' else 1][1],pages=v) for k,v in evidence.items()}
  images=[]
  for j,doc in enumerate(docs):
   sha=FILES[j][1]
   for n in sorted({n for ref in refs.values() if ref['sha256']==sha for n in ref['pages']}):
    raw=image_bytes(doc[n-1]);images.append(dict(data=base64.b64encode(raw).decode(),sha256=digest(raw),source_sha256=sha,physical_page=n,roles=[k for k,v in refs.items() if v['sha256']==sha and n in v['pages']]))
  manifest=json.dumps(refs,ensure_ascii=False,sort_keys=True);wire=json.dumps(images,sort_keys=True,separators=(',',':'));assert len(wire.encode())<1800000
  payload=dict(question_id=qid,exam_id=EXAM,manifest_text=manifest,images_text=wire,sha256=digest((manifest+wire).encode()))
  pack['existing_schema_rows']={t:rows[t] for t in ORDER};pack['remaining']=['ISOLATED_CONTRACT','PRODUCTION_PREFLIGHT','WEB_APP_SCOPE']
  save(PRIVATE/(qid+'.package.private.json'),pack);save(PRIVATE/(qid+'.worker.private.json'),payload);packages.append(pack)
  receipts.append(dict(question_id=qid,exam_id=EXAM,leaf_id=pack['ids']['leaf'],source_key='source:a31bdaa7716d4150af88cd0cbd85f34745dd283f5c0b072b26f0f5c0b007f5b7:'+str(number),evidence=refs,official_description=official,service_concepts=concepts[i],official_points=None,package_sha256=digest(json.dumps(pack,sort_keys=True).encode()),worker_sha256=payload['sha256'],rows=sum(map(len,rows.values())),status='LOCAL_PACKAGE_ONLY'))
 (PRIVATE/'math-registration.private.sql').write_text(registration_sql(packages))
 for path,sha,mtime in original:assert digest(path.read_bytes())==sha and path.stat().st_mtime_ns==mtime
 save(OUT/'khu-mock-package-receipt.json',dict(questions=receipts,source_files_unchanged=2,provider_calls=0,production_writes=0,published=0))
 print(json.dumps(dict(packages=len(packages),rows=sum(x['rows'] for x in receipts),provider_calls=0)))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--source-root',type=Path,required=True);prepare(p.parse_args().source_root)
