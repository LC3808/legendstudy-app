"""Offline whole-exam joins. Title matches are candidates, never runtime approvals."""
import json,re,unicodedata,argparse
from pathlib import Path
from collections import Counter

def normalized(s):return unicodedata.normalize('NFC',s).replace('경제경영','경영경제').replace('자연계열','자연').replace(' ','')
def central_key(title):
 m=re.fullmatch(r'(20\d\d)학년도 중앙대 (모의논술|논술)_(.+?) (문제|해설.*)\.pdf',unicodedata.normalize('NFC',title))
 if not m:return None
 return int(m[1]),'mock' if m[2]=='모의논술' else 'admission',normalized(m[3]),'question' if m[4]=='문제' else 'official_solution'
def assemble(root,prior):
 snapshot=json.loads((root/'runtime-inventory.json').read_text());resources=json.loads((root/'chungang-resource-candidates.json').read_text())
 links=json.loads((root/'exam-resources.json').read_text());old=json.loads((prior/'batch-assembled-512.private.json').read_text())
 previous={q['question_id']:q for q in old['questions']};out=[];packages={}
 for exam in snapshot['exams']:
  if exam['slug'] not in ('chungang','kyunghee'):continue
  ids=sorted(q['question_id'] for q in snapshot['questions'] if q['exam_id']==exam['exam_id'])
  assert len(ids)==exam['registered_questions'] and len(ids)==len(set(ids))
  candidates=[];fail=[]
  if exam['slug']=='chungang':
   key=(exam['year'],exam['kind'],normalized(exam['track']))
   for r in resources:
    k=central_key(r['title'])
    if k and k[:3]==key:candidates.append({'resource_id':r['id'],'role':k[3],'title':r['title'],'source_post_id':r['source_post_id']})
   roles=Counter(x['role'] for x in candidates)
   pair=roles=={'question':1,'official_solution':1} and len({x['source_post_id'] for x in candidates})==1
   fail+=['OFFICIAL_PDF_CONTENT_AND_QUESTION_SCOPE_REVIEW','CENTRAL_PROFILE_NOT_IN_EXISTING_28_PROFILE_LIBRARY']
   if not pair:fail+=['SOURCE_PAIR_AMBIGUOUS_OR_MISSING']
  else:
   candidates=[{k:r[k] for k in ('resource_id','role','title','source_locator','verification_status')} for r in links if r['exam_id']==exam['exam_id']]
   pair=False
  draft_questions=[];inputs=[]
  for qid in ids:
   prior_q=previous.get(qid,{})
   draft=old['drafts'].get(qid)
   if draft:
    pkg=draft['package'];assert pkg['exam_id']==exam['exam_id']
    found=[q for q in pkg['questions'] if q['question_id']==qid];assert len(found)==1
    draft_questions+=found
   inputs.append({'question_id':qid,'draft_present':bool(draft),'profile_mapped':bool(prior_q.get('profile_mapped')),'prior_input_pass':bool(prior_q.get('input_pass')),'blockers':prior_q.get('reasons',['NO_PRIOR_ASSEMBLED_INPUT'])})
  if not ids:fail+=['NO_REGISTERED_QUESTIONS']
  if any(not q['draft_present'] for q in inputs):fail+=['WHOLE_EXAM_DRAFT_INCOMPLETE']
  if any(not q['profile_mapped'] for q in inputs):fail+=['PROFILE_MAPPING_INCOMPLETE']
  if ids and not all(q['prior_input_pass'] for q in inputs):fail+=['WHOLE_EXAM_INPUT_NOT_VALIDATED']
  if draft_questions:packages[exam['exam_id']]={'exam_id':exam['exam_id'],'canonical_question_ids':ids,'questions':draft_questions,'state':'DRAFT_NO_ACTIVATION'}
  out.append({'exam_id':exam['exam_id'],'university':exam['slug'],'year':exam['year'],'kind':exam['kind'],'track':exam['track'],'question_ids':ids,'source_candidates':candidates,'exact_metadata_source_pair':pair,'questions':inputs,'blockers':sorted(set(fail)),'public_candidate':False,'e2e_pass':False})
 summary={}
 for uni in ('chungang','kyunghee'):
  rows=[r for r in out if r['university']==uni];qs=[q for r in rows for q in r['questions']]
  summary[uni]={'exams':len(rows),'questions':len(qs),'exact_metadata_source_pairs':sum(r['exact_metadata_source_pair'] for r in rows),'exams_with_existing_source_links':sum(bool(r['source_candidates']) for r in rows),'profiles_mapped':sum(q['profile_mapped'] for q in qs),'draft_questions_reused':sum(q['draft_present'] for q in qs),'complete_draft_exam_sets':sum(bool(r['question_ids']) and all(q['draft_present'] for q in r['questions']) for r in rows),'prior_input_pass':sum(q['prior_input_pass'] for q in qs),'public_candidates':0,'common_input_errors':dict(Counter(b for q in qs for b in q['blockers']))}
 return {'exams':out,'summary':summary,'provider_calls':0,'production_writes':0},packages
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('root',type=Path);p.add_argument('prior',type=Path);a=p.parse_args();report,packages=assemble(a.root,a.prior)
 (a.root/'central-kyunghee-whole-exam-joins.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 (a.root/'central-kyunghee-whole-exam-drafts.private.json').write_text(json.dumps(packages,ensure_ascii=False)+'\n')
 print(json.dumps(report['summary'],ensure_ascii=False))
