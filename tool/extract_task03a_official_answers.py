"""Local evidence extraction; never writes a database or promotes publication."""
import json,re,io,zipfile,hashlib,collections
from pathlib import Path
import pymupdf,pdfplumber
R=Path(__file__).resolve().parents[1];D=R/'.local/task03a/official'
M=json.loads((D/'manifest.json').read_text());out=[];fails=[]
def clean(s):return re.sub(r'\s+','',s or '').replace('Ⅰ','I').replace('Ⅱ','II').replace('·','')
def triples(table):
 # Some official tables split a numbered row into three physical rows.
 # Merge only vertically continued cells within each column triple;
 # never infer an answer/point or carry a completed number forward.
 rows=[]; pending={}
 for row in table:
  for c in range(0,len(row)-2,3):
   a,b,d=map(clean,row[c:c+3])
   if a.isdigit():
    assert c not in pending, 'UNFINISHED_ROW'
    pending[c]=int(a)
   if c not in pending:continue
   if not b and not d:continue
   assert b and d.isdigit(),(a,b,d)
   rows.append((c//3,pending.pop(c),b,int(d)))
 assert not pending,'UNFINISHED_ROW'
 return sorted(rows,key=lambda x:(x[1],x[0]))
def main():
 for m in M:
  if '정답' not in m['title'] or m.get('kind') not in ['answers',None]:continue
  f=D/m['filename'];blobs=[]
  assert hashlib.sha256(f.read_bytes()).hexdigest()==m['sha256'],'SOURCE_DIGEST_CHANGED'
  if f.suffix=='.pdf':blobs=[(None,f.read_bytes())]
  elif f.suffix=='.zip':
   z=zipfile.ZipFile(f);blobs=[(n,z.read(n)) for n in z.namelist() if n.lower().endswith('.pdf')]
  for member,b in blobs:
   d=pymupdf.open(stream=b,filetype='pdf');p=pdfplumber.open(io.BytesIO(b))
   for idx,page in enumerate(d):
    key=dict(academic_year=m['academic_year'],exam_month=m['exam_month'],source=m['url'],sha256=m['sha256'],pdf_sha256=hashlib.sha256(b).hexdigest(),file=m['filename'],member=member,page=idx+1)
    try:
     txt=clean(page.get_text());assert str(m['academic_year'])+'학년도' in txt,'NO_NATIVE_TEXT_OR_YEAR'
     assert ('모의평가' not in txt if m['exam_month']==11 else str(m['exam_month'])+'월모의평가' in txt),'EXAM_MONTH'
     assert '정답표' in txt,'NO_ANSWER_HEADER'
     tables=page.find_tables().tables;assert len(tables)==1,'TABLE_COUNT'
     a=triples(tables[0].extract());btab=p.pages[idx].extract_tables();assert len(btab)==1,'SECOND_TABLE_COUNT'
     btrip=triples(btab[0]);assert a==btrip,('EXTRACTOR_MISMATCH',a,btrip)
     assert a,'EMPTY_TABLE'
     subject= ('국어' if '국어영역정답표' in txt else '수학' if '수학영역정답표' in txt else '영어' if '영어영역정답표' in txt else '한국사' if '한국사영역정답표' in txt else re.search(r'정답표\((.*?)\)과목',txt)[1])
     variant='홀수형' if '(홀수)형' in txt else '짝수형' if '(짝수)형' in txt else '공통'
     if subject in ['국어','수학']:
      names=['화법과 작문','언어와 매체'] if subject=='국어' else ['확률과 통계','미적분','기하']
      assert all(clean(n) in txt for n in names),'ELECTIVE_HEADERS'
      groups=[(n,[v for v in a if v[0]<2 or v[0]==i+2]) for i,n in enumerate(names)]
     else:groups=[(None,a)]
     for elective,values in groups:
      qs=[]
      for col,n,ans,pts in sorted(values,key=lambda x:x[1]):
       if ans in '①②③④⑤':t='multiple_choice';answers=['①②③④⑤'.index(ans)+1];ac=False
       elif ans.isdigit():t='numeric';answers=[int(ans)];ac=False
       elif ans in ['정답없음','모두정답']:t='multiple_choice';answers=[];ac=True
       else:raise ValueError(('UNKNOWN_ANSWER',ans))
       assert (t=='numeric')==(subject=='수학' and (16<=n<=22 or 29<=n<=30)),'TYPE_POSITION'
       qs.append(dict(number=n,answer_type=t,accepted_answers=answers,all_credit=ac,points=pts))
      count=45 if subject in ['국어','영어'] else 30 if subject=='수학' else 20
      if '제2외국어' in txt:count=30
      assert [q['number'] for q in qs]==list(range(1,count+1)),'QUESTION_NUMBERS'
      maximum=100 if subject in ['국어','수학','영어'] else 50
      assert sum(q['points'] for q in qs)==maximum,'POINT_TOTAL'
      out.append(dict(key,subject=subject,elective=elective,variant=variant,question_count=count,max_score=maximum,questions=qs,extraction_checks=['pymupdf_pdfplumber_exact_cells','year_exam_header','subject_elective_header','contiguous_question_numbers','point_total','answer_type_position']))
    except Exception as e:fails.append(dict(key,error=str(e)));print('FAIL',key['academic_year'],key['exam_month'],member or m['title'],idx+1,str(e)[:100],flush=True)
   p.close()
  (D/'extracted.json').write_text(json.dumps(dict(papers=out,failures=fails),ensure_ascii=False,indent=2))
 print('DONE',len(out),len(fails),collections.Counter((p['academic_year'],p['exam_month']) for p in out),flush=True)

if __name__=='__main__':main()
