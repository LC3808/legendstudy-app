"""Offline publication preflight. No imports, network, DB or READY promotion.
An evidence checklist can validate completeness, not replace human source review.
Only a fully reviewed package exits 0; report status remains explicit otherwise.
"""
import argparse,json,re,uuid
from pathlib import Path
from urllib.parse import urlparse
R=Path(__file__).resolve().parents[1]
def validate(package,registry):
 errors=[]
 def check(ok,reason):
  if not ok:errors.append(reason)
 def source(ref,label):
  check(isinstance(ref,dict),label+':missing evidence')
  if not isinstance(ref,dict):return
  check(ref.get('issuer')=='KICE',label+':issuer not KICE')
  u=urlparse(ref.get('url',''))
  check(u.scheme=='https' and bool(u.netloc),label+':invalid source URL')
  official=urlparse(ref.get('official_url',ref.get('url','')))
  host=official.hostname or ''
  domains=('kice.re.kr','suneung.re.kr','moe.go.kr','korea.kr','law.go.kr')
  check(official.scheme=='https' and any(host==d or host.endswith('.'+d) for d in domains),label+':missing official origin')
  check(bool(re.fullmatch(r'[a-f0-9]{64}',str(ref.get('sha256','')))),label+':missing digest')
  check((type(ref.get('page')) is int and ref['page']>0) or (isinstance(ref.get('section'),str) and bool(ref['section'].strip())),label+':missing page/section')
  check(ref.get('reviewed') is True,label+':not source-reviewed')
 check(package.get('verification_status')=='READY','NOT_READY: evidence verification incomplete')
 check(package.get('engine')=='mixed-v2','unsupported engine')
 exams=[e for e in registry if e['content_item_id']==package.get('content_item_id')]
 check(len(exams)==1,'unknown Registry exam')
 if exams:
  e=exams[0]
  check((e['academic_year'],e['exam_month'],e['exam_type'])==(package.get('academic_year'),package.get('exam_month'),package.get('exam_type')),'exam/year mismatch')
  subjects=[s for s in e['subjects'] if s['id']==package.get('exam_subject_id') and s['is_active']]
  check(len(subjects)==1,'unknown/inactive Registry subject')
  if subjects:check(subjects[0]['code']==package.get('subject_code'),'subject mismatch')
 check(package.get('mapping_reviewed') is True,'elective/common/odd-even mapping unverified')
 check(bool(package.get('paper_variant')),'missing paper variant')
 check(package.get('corrections_reviewed') is True,'correction review incomplete')
 source(package.get('correction_evidence'),'correction check')
 qs=package.get('questions',[])
 check(isinstance(qs,list) and 1<=len(qs)<=100,'invalid question count')
 if not isinstance(qs,list):qs=[]
 check(package.get('question_count')==len(qs),'question count mismatch')
 seen=set();points=0
 for i,q in enumerate(qs,1):
  if not isinstance(q,dict):errors.append(f'{i}:invalid question');continue
  check(q.get('number')==i,f'{i}:non-contiguous question')
  identity=q.get('question_id')
  try: valid_id=isinstance(identity,str) and str(uuid.UUID(identity))==identity
  except (ValueError,AttributeError):valid_id=False
  check(valid_id and identity not in seen,f'{i}:missing/duplicate question identity')
  if isinstance(identity,str):seen.add(identity)
  t=q.get('answer_type');check(t in ('multiple_choice','numeric'),f'{i}:invalid type')
  a=q.get('accepted_answers');ac=q.get('all_credit')
  check(type(ac) is bool,f'{i}:invalid all-credit')
  valid=isinstance(a,list) and all(type(v) is int for v in a)
  check(valid,f'{i}:invalid accepted answers')
  if valid:
   check(len(set(a))==len(a) and (len(a)==0 if ac else len(a)>0),f'{i}:duplicate/empty accepted answers')
   check(all((1<=v<=5 if t=='multiple_choice' else 0<=v<=999) for v in a),f'{i}:answer out of range')
  p=q.get('points');check(type(p) is int and 1<=p<=100,f'{i}:invalid points')
  if type(p) is int:points+=p
  source(q.get('answer_evidence'),f'{i}:answer');source(q.get('points_evidence'),f'{i}:points')
  for field in ('unit','domain','item_type'):
   if q.get(field) is not None:source(q.get(field+'_evidence'),f'{i}:{field}')
 check(points==package.get('max_score') and 1<=points<=1000,'points total mismatch')
 if package.get('academic_year')==2022 and package.get('exam_month')==11 and package.get('subject_code')=='life_science_2':
  check(len(qs)>=20 and qs[19].get('all_credit') is True,'2022 CSAT biology II correction not applied')
 if package.get('academic_year')==2023 and package.get('exam_month')==6 and package.get('subject_code')=='earth_science_2':
  check(len(qs)>=14 and qs[13].get('all_credit') is True,'2023 June earth science II correction not applied')
 return errors

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('package',type=Path);a=ap.parse_args()
 p=json.loads(a.package.read_text());r=json.loads((R/'data/mock_expansion/task03/registry_snapshot.json').read_text())
 errors=validate(p,r);print(json.dumps({'status':'READY' if not errors else 'NOT_READY','errors':errors},ensure_ascii=False,indent=2));return bool(errors)
if __name__=='__main__':raise SystemExit(main())
