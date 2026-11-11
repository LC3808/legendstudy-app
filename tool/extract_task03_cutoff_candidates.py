"""Offline OCR staging only. Never produces publishable rows or touches a DB.
Input: cached public source manifest + Apple Vision observations (not an authority).
Missing/ambiguous cells remain null and are listed for visual review.
"""
import json,re,hashlib
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text())
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def center(v):return v['x']+v['w']/2
def cy(v):return v['y']+v['h']/2
def number(text):
 t=text.replace(' ','').replace('–','~').replace('～','~')
 if re.fullmatch(r'\d{1,3}',t):return {'value':int(t)}
 m=re.fullmatch(r'(\d{1,3})[~-](\d{1,3})',t)
 if m and int(m[1])<=int(m[2]):return {'min':int(m[1]),'max':int(m[2])}
 return None

def main():
 root=R/'.local/task03';out=R/'data/grade_cutoffs/task03_pending';out.mkdir(exist_ok=True)
 manifest=read(root/'image_manifest.json');registry=read(R/'data/mock_expansion/task03/registry_snapshot.json')
 scope=read(R/'data/mock_expansion/task03/exam_scope.json')['exams']
 exams={x['source_url'].rsplit('/',1)[1]:x for x in scope}
 registers={x['content_item_id']:x for x in registry}
 seen=set();tables=[];duplicates=[];banners=[]
 for asset in manifest:
  obs=read(root/'ocr'/asset['local_file'].replace('.png','.json'))
  if not any(re.fullmatch(r'[1-9]등급',v['text'].replace(' ','')) for v in obs):
   banners.append(asset['local_file']);continue
  digest=hashlib.sha256((root/'assets'/asset['local_file']).read_bytes()).hexdigest()
  assert digest==asset['sha256']
  identity=(asset['post_id'],digest)
  if identity in seen:duplicates.append(asset['local_file']);continue
  seen.add(identity)
  titles=[v['text'] for v in obs if v['y']>.87]
  assert len(titles)==1,(asset['local_file'],titles)
  title=titles[0];label=title.replace(' ','')
  for prefix in ['물리학','화학','생명과학','지구과학']:
   if label.startswith(prefix):
    suffix=label[len(prefix):].replace('|','I').replace('1','I').replace('!','I').replace('"','I')
    assert suffix in ['I','II'],(title,suffix)
    label=prefix+str(len(suffix))
  exam=exams[asset['post_id']];subjects=registers[exam['id']]['subjects']
  matches=[s for s in subjects if s['label']==label]
  # Whole-group Registry is retained for comparison; each elective is explicitly named.
  issues=[]
  if len(matches)!=1:issues.append('REGISTRY_MAPPING_REVIEW')
  columns=[]
  for token,key in [('원점수','raw_score'),('표준점수','standard_score'),('백분위','percentile')]:
   headers=[v for v in obs if v['text'].replace(' ','')==token and v['y']>.7]
   if len(headers)==1:columns.append((key,center(headers[0])))
  for token,key in [('화법과','raw_speech_writing'),('언어와','raw_language_media'),('확률과','raw_probability_statistics'),('미적분','raw_calculus'),('기하','raw_geometry')]:
   headers=[v for v in obs if v['text'].replace(' ','')==token and v['y']>.7]
   if len(headers)==1:columns.append((key,center(headers[0])))
  columns.sort(key=lambda c:c[1]);rows=[]
  grade_labels=[v for v in obs if re.fullmatch(r'[1-9]등급',v['text'].replace(' ',''))]
  for g in sorted(grade_labels,key=lambda v:int(v['text'][0])):
   cells={};tokens=[v for v in obs if abs(cy(v)-cy(g))<.025 and center(v)>.2 and v is not g]
   for name,x in columns:
    candidates=[v for v in tokens if min(columns,key=lambda c:abs(center(v)-c[1]))[0]==name and abs(center(v)-x)<.13]
    parsed=number(candidates[0]['text']) if len(candidates)==1 else None
    cells[name]={'parsed':parsed,'source_tokens':[v['text'] for v in candidates]}
    if len(candidates)>1 or (candidates and parsed is None and candidates[0]['text'] not in ['-','—']):issues.append(f"OCR_CELL_REVIEW:{g['text']}:{name}")
   rows.append({'grade':int(g['text'][0]),'cells':cells})
  if len(rows)!=8:issues.append('GRADE_ROWS_REVIEW')
  if label=='생명과학2' and exam['academic_year']==2022 and exam['exam_month']==11:issues.append('POST_CORRECTION_CUTOFF_REVIEW')
  tables.append({'content_item_id':exam['id'],'exam_subject_id':matches[0]['id'] if len(matches)==1 else None,
   'academic_year':exam['academic_year'],'exam_month':exam['exam_month'],'subject_label':label,
   'source_title_ocr':title,'source_page_url':exam['source_url'],'source_image_url':asset['url'],
   'source_sha256':digest,'fetched_at':asset['fetched_at'],'local_file':asset['local_file'],
   'review_status':'PENDING','publishable':False,'verified_at':None,
   'raw_certainty':'unspecified','standard_certainty':'unspecified','issues':sorted(set(issues)), 'rows':rows})
 write(out/'image_sources.json',manifest)
 write(out/'ocr_candidates.json',{'review_status':'PENDING','production_mutation':False,
  'warning':'OCR staging, not verified cutoff data. Blank cells and absent grades must not be filled by inference.',
  'duplicate_images_excluded':duplicates,'banners_excluded':banners,'tables':tables})
 print(json.dumps({'images':len(manifest),'tables':len(tables),'rows':sum(len(t['rows']) for t in tables),'duplicates':duplicates,'tables_with_flags':sum(bool(t['issues']) for t in tables)},ensure_ascii=False))
if __name__=='__main__':main()
