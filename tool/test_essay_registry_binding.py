"""Real previously reviewed private SKKU package; no Provider/DB/network calls."""
import copy,json,os,unittest
from pathlib import Path
from tool.essay_lab.service_content import prepare,bind_registration,cache_for_claim
R=Path(__file__).resolve().parents[1]
class RegistryBindingTests(unittest.TestCase):
 def setUp(self):
  root=Path(os.environ['ESSAY_PRIVATE_PACKAGE'])
  self.plan=prepare(json.loads((root/'package.json').read_text()),json.loads((R/'tool/essay_lab/evidence/skku_2025_humanities1_manifest.json').read_text()),(root/'q2-data-1.png').read_bytes())
  self.registration=next(e for e in json.loads((R/'supabase/reviews/essay-source-registration/manifest.json').read_text())['exams'] if e['examId']==self.plan['exam_id'])
 def test_real_source_three_questions_nine_criteria_no_content_mutation(self):
  bound=bind_registration(self.plan,self.registration)
  self.assertEqual(len(bound['questions']),3);self.assertEqual(len(bound['criteria']),9)
  self.assertEqual({q['id'] for q in bound['questions']},{q['id'] for q in self.registration['questions']})
  self.assertEqual([q['evaluator_evidence'] for q in bound['private_content']],[q['evaluator_evidence'] for q in self.plan['private_content']])
  self.assertEqual([x['requires_figure'] for x in bound['private_content']],[False,True,True])
  self.assertFalse(bound['publication_allowed']);self.assertFalse(bound['provider_transmission_allowed'])
 def test_wrong_exam_pdf_ambiguous_label_denied(self):
  for field,value in [('examId','wrong'),('sourceHashes',[]),('questions',self.registration['questions']*2)]:
   r=copy.deepcopy(self.registration);r[field]=value
   with self.assertRaises(ValueError):bind_registration(self.plan,r)
 def test_figure_questions_keep_existing_worker_gate(self):
  bound=bind_registration(self.plan,self.registration)
  for q in bound['private_content'][1:]:
   with self.assertRaisesRegex(ValueError,'VISUAL_WORKER_CONTRACT_REQUIRED'):cache_for_claim(bound,q['question_id'],{})
if __name__=='__main__':unittest.main()
