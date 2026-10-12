"""Real existing private package binding; synthetic new answer, no Provider calls."""
import copy,json,os,unittest
from hashlib import sha256
from pathlib import Path
from tool.essay_lab.accepted_source_runtime import prepare,hosted_question
from tool.essay_lab.live_worker import package,Invalid
@unittest.skipUnless(os.environ.get('ESSAY_ACCEPTED_PACKAGES'),'Private accepted packages not supplied')
class AcceptedSourceTests(unittest.TestCase):
 def test_exact_two_registered_questions_exclude_original_student(self):
  for case,count in [('hanyang',5),('sookmyung',2)]:
   root=Path(os.environ['ESSAY_ACCEPTED_PACKAGES']);bound=prepare(case,root);cache=bound['cache']
   hosted=hosted_question(case,root,{},regime='unconfigured')
   self.assertEqual(hosted.question_id,bound['question_id']);self.assertFalse(hosted.approved_processing)
   old=json.loads((root/case/'package.json').read_text())
   body='새로 작성한 검증용 답안입니다.'
   claim={'answer':body,'input':{'contract_version':'1.3','attempt_id':'test-attempt','answer_hash':sha256(body.encode()).hexdigest(),
    'evidence':[e['binding'] for e in cache['evidence']],'criteria':[c['binding'] for c in cache['criteria']],
    'scaffolding_context':{'items':[]}}}
   value=package(claim,cache);wire=json.dumps(value,ensure_ascii=False)
   self.assertEqual(value['answer'],body);self.assertNotIn(old['answer'],wire)
   self.assertEqual(len(value['official_images']),count)
   self.assertNotIn(old['image_sha256'][-1],wire)
   self.assertFalse(bound['provider_transmission_allowed'])
   changed=copy.deepcopy(cache);changed['official_images'][0]['sha256']='0'*64
   with self.assertRaises(Invalid):package(claim,changed)
   changed=copy.deepcopy(cache);changed['official_images'][0]['evidence_ids']=['foreign']
   with self.assertRaises(Invalid):package(claim,changed)
 def test_wrong_registry_exam_never_binds(self):
  for case in ('hanyang','sookmyung'):
   with self.assertRaises(Invalid):prepare(case,os.environ['ESSAY_ACCEPTED_PACKAGES'],{'exams':[]})
if __name__=='__main__':unittest.main()
