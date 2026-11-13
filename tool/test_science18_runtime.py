"""No Provider: actual 18 source packages, strict output and durable rewrite contracts."""
import copy,hashlib,json,unittest
from pathlib import Path
from essay_lab.live_worker import package,validate_output,Invalid
from essay_lab.material_runtime import load_reviewed_material,prepare_claimed_material
from essay_lab.exam_runtime import ExamQuestionChannel
from essay_lab.evaluation_policy import question_engine
R=Path(__file__).resolve().parents[1];P=R/'.local/khu-mock-science-20261112'
class ScienceRuntimeTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.packages=json.loads((P/'science-packages.private.json').read_text());cls.registry=json.loads((P/'science-registry.private.json').read_text())
 def bind(self,p):return load_reviewed_material(p,self.registry,pinned_digest=p['package_digest'],binding={},regime='synthetic',evaluation_type='science',activation_approved=True)[0]
 def test_all18_existing_result_and_rewrite_contracts(self):
  count=0
  for eid,p in self.packages.items():
   hosted=self.bind(p)
   for qid,q in hosted.items():
    cache=q.frozen_cache
    if cache.get('evaluation_engine')=='math':continue
    count+=1;self.assertEqual(question_engine('science',cache['evaluation_engine']),'science')
    parent=None
    for cycle,level in enumerate([5,1,3]):
     claim=dict(run_id=f'synthetic-{cycle}',subject_id='owner',lease_token='lease',parent_id='parent' if parent else None,parent_result=parent,snapshot=dict(ownerId='owner',runtime=dict(package_digest=p['package_digest'],binding={},regime='synthetic',evaluation_type='science'),answers=[dict(questionId=qid,body=f'합성 계약 답안 {cycle}',rubricVersion='v1',evidenceVersion='v1')]))
     questions,caches=prepare_claimed_material(claim,p,self.registry);frozen=questions[0]['claim'];self.assertEqual(questions[0]['engine'],'science');request=package(frozen,cache);self.assertEqual(request['science_context']['question_id'],qid)
     out=dict(contract_version='1.3',attempt_id=frozen['input']['attempt_id'],answer_hash=frozen['input']['answer_hash'],summary='합성 결과 — AI 품질 검증 아님',strengths=[],checklist=[],dimensions=[dict(criterion_id=c['binding']['id'],level=level,explanation='합성 형식 검사',evidence_ids=[cache['evidence'][0]['binding']['id']]) for c in cache['criteria']],improvements=[],core_improvement_keys=[],previous_improvement_reviews=[],sentence_feedback=[])
     validate_output(out,frozen);channel=ExamQuestionChannel(qid,frozen,lambda *_:None);channel('essay_claim',dict(p_evaluation=qid));channel('essay_finalize_success',dict(p_evaluation=qid,p_run=frozen['run_id'],p_token=frozen['lease_token'],p_output=out));resumed=ExamQuestionChannel(qid,frozen,lambda *_:None);resumed.restore(channel.snapshot());self.assertEqual(resumed.output,out)
     parent=dict(questions=[dict(questionId=qid,evaluation=out)])
     bad=copy.deepcopy(out);bad['dimensions'][0]['criterion_id']='foreign';self.assertRaises(Invalid,validate_output,bad,frozen)
     foreign=copy.deepcopy(frozen);foreign['answer']='changed';self.assertRaises(Invalid,package,foreign,cache)
  self.assertEqual(count,18)
 def test_science_source_identity_and_engine_guards(self):
  p=next(p for p in self.packages.values() if all(q['evaluation_engine']=='science' for q in p['questions']))
  for mutate in [lambda e:e.update(evaluation_engine='essay'),lambda e:e['science_context'].update(question_id='foreign'),lambda e:e['science_context'].update(source_sha256='0'*64),lambda e:e['science_context'].update(subject='math'),lambda e:e.update(math_context={'fake':True})]:
   bad=copy.deepcopy(p);mutate(bad['questions'][0]);self.assertRaises(Invalid,self.bind,bad)
  self.assertRaises(Invalid,question_engine,'science','essay');self.assertRaises(Invalid,question_engine,'humanities','science')
 def test_existing_math_context_preserved(self):
  count=0
  for p in self.packages.values():
   hosted=self.bind(p)
   for entry in p['questions']:
    if entry['evaluation_engine']!='math':continue
    count+=1;self.assertEqual(hosted[entry['question_id']].frozen_cache['leaf']['essay_question_id'],entry['question_id']);self.assertEqual(hosted[entry['question_id']].frozen_cache['provider_binding']['model'],'gpt-5.6-sol')
  self.assertEqual(count,4)
if __name__=='__main__':unittest.main()
