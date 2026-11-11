"""Offline candidate metadata patch with exact prior values; no deploy or publication."""
import argparse,copy,json
from pathlib import Path
parser=argparse.ArgumentParser(description='Prepare ignored source metadata review patch; never edits the WEB checkout')
parser.add_argument('--web-root',required=True,type=Path)
parser.add_argument('--registry',required=True,type=Path)
parser.add_argument('--candidate-root',required=True,type=Path)
a=parser.parse_args();W=a.web_root.resolve();out=a.candidate_root.resolve();assert '.local' in out.parts
slug=out.name
catalog=json.loads((W/'src/data/essay-public-catalog.json').read_text())['universities']
plan=json.loads((out/'source-plan.json').read_text());live=json.loads(a.registry.read_text());original=json.loads((W/'src/data/essay-source-registry.json').read_text());result=copy.deepcopy(original);changes=[]
for e in plan['exams']:
 key=e['exam_key'].replace('source-','source:',1);matches=[s for s in result['exams'] if s['key']==key or s.get('dbExamId')==e['exam_id']];assert len(matches)<=1
 rr=sorted([r for r in live if r['exam_id']==e['exam_id'] and r['question_id']],key=lambda r:r['display_order'])
 catalog_matches=[u for u in catalog if u['universityId']==e['university_id']];assert len(catalog_matches)==1
 source_slug=catalog_matches[0]['sourceUniversityId']
 if matches:assert matches[0]['sourceUniversityId']==source_slug
 new=dict(key=key,dbExamId=e['exam_id'],universityId=e['university_id'],sourceUniversityId=source_slug,year=e['admission_year'],kind=e['exam_kind'],track=e['field_or_division'],session=e['session_label'],campus=e['campus'],verification='VERIFIED',verificationScope='existing_registry_identity_and_official_page_mapping_not_publication',sourceHashes=sorted({ref['sha256'] for q in e['questions'] for ref in q['refs'].values()}),evaluationReady=False,questions=[])
 for r in rr:
  q=next((q for q in e['questions'] if q['question_id']==r['question_id']),None)
  loc=None if q is None else q['refs']['problem']['file']+' PDF '+','.join(map(str,q['refs']['problem']['pages']))+'쪽'
  new['questions'].append(dict(key=r['question_key'],dbQuestionId=r['question_id'],label=r['label'],sourceLocator=loc,lengthLabel=None,inputMode='image',accountDraftReady=False))
 if matches:
  prior=matches[0]
  assert prior['universityId']==new['universityId'] and prior['year']==new['year'] and prior['track']==new['track']
  assert [q['label'] for q in prior['questions']]==[q['label'] for q in new['questions']]
  assert not prior.get('evaluationReady')
  for k in ['kind','session','campus']:assert prior.get(k)==new.get(k)
  new['sourceHashes']=sorted(set(prior.get('sourceHashes',[])+new['sourceHashes']))
  merged_questions=[]
  for old_q,new_q in zip(prior['questions'],new['questions']):
   merged={**old_q,**new_q,'key':old_q['key']}
   if new_q['sourceLocator'] is None:merged['sourceLocator']=old_q.get('sourceLocator')
   merged['lengthLabel']=old_q.get('lengthLabel')
   merged_questions.append(merged)
  new={**prior,**new,'questions':merged_questions}
  result['exams'][result['exams'].index(prior)]=new
 else:result['exams'].append(new)
 changes.append(dict(key=key,prior=matches[0] if matches else None,candidate=new))
(out/'web-source-registry-candidate.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
(out/'web-source-registry-patch.json').write_text(json.dumps(dict(exams=changes,publication_allowed=False),ensure_ascii=False,indent=2)+'\n')
leaf_file=out/'web-leaf-contract-candidate.json'
a=json.loads((leaf_file if leaf_file.exists() else out/'web-expansion-candidate.json').read_text());(out/'web-leaf-contract-candidate.json').write_text(json.dumps(a,ensure_ascii=False,indent=2)+'\n')
a['blockedExams']=[e for e in a['exams'] if not e['completeExam']];a['exams']=[e for e in a['exams'] if e['completeExam']]
(out/'web-expansion-candidate.json').write_text(json.dumps(a,ensure_ascii=False,indent=2)+'\n')
print(dict(slug=slug,source_exams=len(changes),complete_expansion=len(a['exams']),blocked_partial_exams=len(a['blockedExams'])))
