import copy,json,unittest
from pathlib import Path
from tool.essay_lab import sookmyung_run_a as r

@unittest.skipUnless((r.SOURCE/"blind_input.json").exists(), "Private accepted fixture unavailable")
class InputTest(unittest.TestCase):
 def fixture(self):return json.loads((r.SOURCE/'blind_input.json').read_text())
 def test_existing_input_valid(self):r.check_input(self.fixture())
 def test_labels_rejected(self):
  for label in r.FORBIDDEN:
   d=self.fixture();d['question']+=label
   with self.assertRaises(AssertionError):r.check_input(d)
 def test_additional_evidence_rejected(self):
  d=self.fixture();d['official_evidence']['example_answer']={'text':'x'}
  with self.assertRaises(AssertionError):r.check_input(d)
 def test_wrong_question_rejected(self):
  d=self.fixture();d['target_question']='1-2'
  with self.assertRaises(AssertionError):r.check_input(d)
 def test_image_path_rejected(self):
  d=self.fixture();d['student_answer']['asset']='../ground_truth.json'
  with self.assertRaises(AssertionError):r.check_input(d)
 def test_assembly_deterministic_and_pinned(self):
  a,m=r.assemble();b,n=r.assemble();self.assertEqual(a,b);self.assertEqual(m,n)
  self.assertEqual(m['image_count'],3);self.assertEqual(m['input_files']['blind_input.json'],'35c2b5513b4ad8a0cbd1bbae589dfc5828e55bacebe291e434f013c478583ed1')

class OutputTest(unittest.TestCase):
 def output(self):
  return {'overall_feedback':'feedback','criterion_feedback':[{'criterion_id':c,'feedback':'specific feedback','evidence_references':['E2']} for c in r.CRITERIA],'strengths':['strength'],'improvements':['improvement'],'revision_priorities':['action'],'evidence_references':[{'evidence_id':'E2',**r.REFERENCE['E2']}],'uncertainty':'uncertainty'}
 def test_output_valid(self):r.validate_output(self.output())
 def test_reference_mismatch_rejected(self):
  d=self.output();d['evidence_references'][0]['source_locator']='invented'
  with self.assertRaises(AssertionError):r.validate_output(d)
 def test_missing_criterion_rejected(self):
  d=self.output();d['criterion_feedback'].pop()
  with self.assertRaises(AssertionError):r.validate_output(d)
 def test_unknown_output_field_rejected(self):
  d=self.output();d['score']=100
  with self.assertRaises(AssertionError):r.validate_output(d)
 def test_first_write_never_overwritten(self):
  import tempfile
  with tempfile.TemporaryDirectory() as p:
   f=Path(p)/'first';r.write_new(f,b'first')
   with self.assertRaises(FileExistsError):r.write_new(f,b'second')
   self.assertEqual(f.read_bytes(),b'first')
 def test_startup_notices_not_model_failures(self):
  events=[{'type':'item.completed','item':{'type':'error','message':'Code Mode is unavailable because code-mode host is disabled.'}},{'type':'turn.completed'}]
  self.assertEqual(len(r.validate_events(events)),1)
 def test_tool_or_transport_failure_rejected(self):
  for e in [{'type':'item.completed','item':{'type':'command_execution'}},{'type':'turn.failed'},{'type':'item.completed','item':{'type':'error','message':'Unknown failure'}}]:
   with self.assertRaises(AssertionError):r.validate_events([e,{'type':'turn.completed'}])
 def test_no_ground_truth_read_in_runner(self):
  source=Path(r.__file__).read_text()
  self.assertNotIn("SOURCE/'ground_truth.json'",source)
  self.assertNotIn('resume',source.split('cmd=')[1].split('for feature')[0])

@unittest.skipUnless((r.OUT/'validated_receipt.json').exists(), 'Private Run A unavailable')
class FrozenRunTest(unittest.TestCase):
 def test_frozen_output_and_trace(self):
  receipt=json.loads((r.OUT/'frozen_receipt.json').read_text())
  for n,h in receipt['files'].items():self.assertEqual(r.sha((r.OUT/n).read_bytes()),h)
  r.validate_output(json.loads((r.OUT/'raw_output.json').read_text()))
  r.validate_events([json.loads(l) for l in (r.OUT/'events.jsonl').read_text().splitlines()])
 def test_reveal_after_freeze(self):
  from datetime import datetime
  frozen=json.loads((r.OUT/'frozen_receipt.json').read_text())
  reveal=json.loads((r.OUT/'ground_truth_reveal.json').read_text())
  self.assertGreater(datetime.fromisoformat(reveal['revealed_at']),datetime.fromisoformat(frozen['frozen_at']))
  self.assertEqual(reveal['output_hash_before_reveal'],frozen['output_sha256'])

if __name__=='__main__':unittest.main()
