"""Compile exact review candidates; no network, activation, or production connector."""
import collections,hashlib,json
from pathlib import Path
R=Path(__file__).resolve().parents[1];OUT=R/'supabase/candidates/natural_tech_ready_20261112'
def read(p):return json.loads(p.read_text())
def build():
 old=R/'supabase/candidates/natural_expansion_20261111/four-university';review=read(old/'question-review.json')['questions'];kau=read(R/'supabase/candidates/natural_expansion_20261111/kau-production-preflight/scope.json')['questions'];kauby={q['registry_id']:q for q in kau};items=[]
 slugs={'한국항공대학교':'kau','건국대학교':'konkuk','경희대학교':'kyunghee','성균관대학교':'sungkyunkwan'}
 for q in review:
  s=slugs[q['university']];state=q['state'];status='PRESERVED' if 'PRESERVED' in state else 'HOLD' if state=='HOLD' else 'NOT_READY' if state=='NOT READY' else 'PARTIAL' if state=='DATA READY' else 'TECH_READY'
  items.append(dict(university=s,university_id=q['university_id'],exam_id=q['exam_id'],question_id=q['registry_id'],question_key=q['registry_key'],year=q['admission_year'],label=q['question_label'],display_order=q['display_order'],status=status,partial_exam=kauby.get(q['registry_id'],{}).get('partial_exam',status=='PARTIAL'),production_draft_applied=s=='kau' and status=='TECH_READY',pdf_approval_pending=s=='sungkyunkwan' and status=='TECH_READY'))
 for s in ['sogang','soongsil','sookmyung','dongguk','kwangwoon','seoul-women']:
  rows=read(OUT/(s+'-production-readonly.json'));plan=read(OUT/(s+'-source-plan.json'));included={q['question_id'] for e in plan['exams'] for q in e['questions']};exp=read(OUT/s/'web-expansion-candidate.json');whole={e['examId'] for e in exp['exams']};pdf=read(OUT/s/'web-pdf-existing-reuse.json');pdfby={q['questionId']:q for q in pdf}
  for q in rows:
   status='PRESERVED' if q['math_bindings'] else 'NOT_READY' if q['question_id'] not in included else 'TECH_READY' if q['exam_id'] in whole else 'HOLD' if q['question_id']=='815bc344-cdbb-5b7f-82c1-dc528de46f51' else 'PARTIAL'
   p=pdfby.get(q['question_id'],{});items.append(dict(university=s,university_id=q['university_id'],exam_id=q['exam_id'],question_id=q['question_id'],question_key=q['question_key'],year=q['admission_year'],label=q['label'],display_order=q['display_order'],status=status,partial_exam=status=='PARTIAL',production_draft_applied=False,pdf_approval_pending=bool(p) and p.get('studentDisplay')!='APPROVED'))
 manifests={s:read((old/s if s in ['konkuk','kyunghee','sungkyunkwan'] else OUT/s)/'manifest.json')['packages'] for s in ['konkuk','kyunghee','sungkyunkwan','sogang','soongsil','sookmyung','dongguk','kwangwoon','seoul-women']}
 for q in items:
  s=q['university'];qid=q['question_id']
  if s=='kau':
   x=kauby[qid];q['leaf_id']=x.get('math_connection',{}).get('leaf_id');q['private_package_directory']='.local/kau-production-preflight-20261112'
  else:
   pkg=next((p for p in manifests[s] if p['question_id']==qid),None)
   q['leaf_id']=pkg['leaf_id'] if pkg else None;q['package_sha256']=pkg['package_sha256'] if pkg else None
   q['private_package_directory']=f'.local/four-university-20261111/{s}' if s in ['konkuk','kyunghee','sungkyunkwan'] else f'.local/natural-tech-20261112/{s}'
  q['review_enabled']=False;q['published_new']=False
 counts=dict(collections.Counter(q['status'] for q in items));assert counts=={'TECH_READY':186,'HOLD':6,'PRESERVED':13,'NOT_READY':22,'PARTIAL':7},counts
 assert len({q['question_id'] for q in items})==len(items)==234
 selected=[q for q in items if q['status']=='TECH_READY'];assert len({q['leaf_id'] for q in selected})==186 and all(q['leaf_id'] for q in selected)
 for q in selected:
  p=R/q['private_package_directory']/(q['question_id']+'.package.private.json');raw=p.read_bytes();data=json.loads(raw);assert data['ids']['leaf']==q['leaf_id'] and data['essay_question_id']==q['question_id'];q['package_sha256']=hashlib.sha256(raw).hexdigest()
 scope=dict(version='natural-owner-review-scope-20261112-v1',university_order=['kau','konkuk','kyunghee','sungkyunkwan','sogang','soongsil','sookmyung','dongguk','kwangwoon','seoul-women'],target_exams=len({q['exam_id'] for q in items}),target_questions=len(items),counts=counts,review_ready=False,production_execution_approved=False,provider_allowed=False,publication_allowed=False,questions=items)
 (OUT/'integrated-review-scope.json').write_text(json.dumps(scope,ensure_ascii=False,indent=2)+'\n');print(json.dumps({k:v for k,v in scope.items() if k!='questions'}));return scope
if __name__=='__main__':build()
