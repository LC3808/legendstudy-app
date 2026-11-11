"""Offline comparison against official XLSX, no DB/network or production writes."""
import json,zipfile,re,hashlib,xml.etree.ElementTree as E,collections
from pathlib import Path
R=Path(__file__).resolve().parents[1];D=R/'.local/task03a/official';n={'m':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
M=json.loads((D/'manifest.json').read_text());out=[];index={}
def norm(v):return re.sub(r'[\s·]','',str(v)).replace('Ⅱ','2').replace('Ⅰ','1')
def main():
 for m in M:
  if m.get('kind') not in ['cutoffs','corrected_cutoffs'] or not m['filename'].endswith('.xlsx'):continue
  if m['academic_year']==2022 and m['exam_month']==11 and m['kind']!='corrected_cutoffs':continue
  assert hashlib.sha256((D/m['filename']).read_bytes()).hexdigest()==m['sha256'],'SOURCE_DIGEST_CHANGED'
  z=zipfile.ZipFile(D/m['filename']);ss=[''.join(x.itertext()) for x in E.fromstring(z.read('xl/sharedStrings.xml')).findall('m:si',n)];cells={}
  for row in E.fromstring(z.read('xl/worksheets/sheet2.xml')).findall('.//m:row',n):
   for c in row.findall('m:c',n):
    v=c.find('m:v',n)
    if v is not None:cells[c.get('r')]=ss[int(v.text)] if c.get('t')=='s' else v.text
  assert cells['D2']=='영역/과목별 등급 구분 표준점수'
  for addr,v in cells.items():
   if not addr.startswith('A') or v!='등급':continue
   row=int(addr[1:]);names={col:cells[col+str(row)] for col in ['B','E','H','K'] if col+str(row) in cells}
   for col,subject in names.items():
    # Only existing 19 subject categories; vocational metadata is retained in source only.
    if row>93:continue
    for offset in range(3,12):
     rr=row+offset;grade=int(cells['A'+str(rr)]);v=cells[col+str(rr)];num=re.fullmatch(r'(\d+)(미만)?',v)
     assert num or v in ['ㅡ','-'],(m['filename'],col,rr,v)
     item=dict(academic_year=m['academic_year'],exam_month=m['exam_month'],subject_label=norm(subject),metric='standard_score',grade=grade,score=int(num[1]) if num else None,comparison=('lt' if num[2] else 'gte') if num else 'not_assigned',certainty='confirmed',source_url=m['url'],source_sha256=m['sha256'],source_sheet='등급구분점수',source_cell=col+str(rr),source_text=v,correction_applied=m['kind']=='corrected_cutoffs')
     out.append(item);index[(m['academic_year'],m['exam_month'],norm(subject),grade)]=item
 pending=json.loads((R/'data/grade_cutoffs/task03_pending/ocr_candidates.json').read_text());reviews=[]
 for t in pending['tables']:
  rows=[]
  for r in t['rows']:
   official=index.get((t['academic_year'],t['exam_month'],norm(t['subject_label']),r['grade']))
   candidate=r['cells'].get('standard_score',{}).get('parsed')
   v=candidate.get('value') if isinstance(candidate,dict) else None
   status='MATCH' if official and official['comparison']=='gte' and v==official['score'] else 'MISSING_OCR' if official and v is None else 'MISMATCH' if official else 'NO_OFFICIAL_MAPPING'
   rows.append(dict(grade=r['grade'],standard_score_review=status,ocr_value=v,official_value=official['score'] if official else None,official_comparison=official['comparison'] if official else None,official_source_cell=official['source_cell'] if official else None,raw_score_review='NOT_VERIFIED',percentile_review='NOT_VERIFIED'))
  reviews.append(dict(academic_year=t['academic_year'],exam_month=t['exam_month'],subject_label=t['subject_label'],local_file=t['local_file'],source_sha256=t['source_sha256'],rows=rows))
 # Visual review of the ten mismatches, preserving original OCR observations.
 for t in reviews:
  for r in t['rows']:
   if r['standard_score_review']=='MISMATCH':
    r['visual_review']='SOURCE_DISAGREES_WITH_OFFICIAL_UNASSIGNED_GRADE' if r['official_comparison']=='not_assigned' else 'OCR_MISREAD_SOURCE_MATCHES_OFFICIAL'
    r['visual_source_value']=r['ocr_value'] if r['official_comparison']=='not_assigned' else r['official_value']
 report=dict(production_mutation=False,metric='standard_score_only',official_rows=out,ocr_comparison=reviews,summary=dict(official_tables=len(out)//9,official_rows=len(out),ocr_tables=len(reviews),ocr_rows=sum(len(t['rows']) for t in reviews),statuses=dict(collections.Counter(r['standard_score_review'] for t in reviews for r in t['rows']))))
 (D/'cutoff_review.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));print(json.dumps(report['summary'],ensure_ascii=False));print('MISMATCH',[(t['academic_year'],t['exam_month'],t['subject_label'],r) for t in reviews for r in t['rows'] if r['standard_score_review']!='MATCH'][:30])

if __name__=='__main__':main()
