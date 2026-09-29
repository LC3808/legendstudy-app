import copy,hashlib,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
from tool.essay_lab import scaffolding_pilot_run_a as runner
from tool.essay_lab.scaffolding_pilot_validation import inspect_output,rpc_payload_gap
class PilotTests(unittest.TestCase):
 def fixture(self):
  text='🙂 가 \n문장.'
  return text,{'contract_version':'1.3','attempt_id':'blind-attempt-a','answer_hash':hashlib.sha256(text.encode()).hexdigest(),'previous_improvement_reviews':[],'summary':'합성','strengths':[],'dimensions':[{'criterion_id':'c','level':3,'explanation':'합성','evidence_ids':['E2']}],'improvements':[],'core_improvement_keys':[],'sentence_feedback':[],'checklist':[],'uncertainty_note':''}
 def test_reporting_field_is_not_rpc_compatible(self):
  _,v=self.fixture();gap=rpc_payload_gap(v)
  self.assertEqual(gap['extra_provider_keys'],['uncertainty_note'])
  self.assertTrue(gap['pilot_alias_mapping_required'])
 def test_empty_supported(self):
  t,v=self.fixture();self.assertEqual(inspect_output(v,t,['c'])['structural_validation'],'PASS')
 def sentence(self):
  t,v=self.fixture();v['improvements']=[{'issue_key':'x','status':'open','previous_progress_id':None,'claim_scope':'local_sentence','evidence_ids':[]}];v['sentence_feedback']=[{'observation_key':'s','linked_issue_key':'x','start':0,'end':5,'quote':t[:5],'category':'expression','priority':'wording','diagnosis':'합성','direction':'합성'}];return t,v
 def test_exact_codepoints_and_whitespace(self):
  t,v=self.sentence();self.assertEqual(inspect_output(v,t,['c'])['structural_validation'],'PASS')
 def test_fabricated_and_normalized_rejected(self):
  t,v=self.sentence()
  for q in ['없는 문장','🙂 가 ',t[:5].strip()]:
   w=copy.deepcopy(v);w['sentence_feedback'][0]['quote']=q;self.assertEqual(inspect_output(w,t,['c'])['quote_accuracy'],'FAIL')
 def test_duplicate_rejected(self):
  t,v=self.sentence();v['sentence_feedback']*=2;self.assertIn('duplicate_spans',inspect_output(v,t,['c'])['errors'])
 def test_hash_and_history_rejected(self):
  t,v=self.fixture();v['answer_hash']='x';v['previous_improvement_reviews']=[{}];self.assertGreaterEqual(len(inspect_output(v,t,['c'])['errors']),2)
 def test_limits_rejected(self):
  t,v=self.sentence();v['core_improvement_keys']=['x']*4;v['sentence_feedback']*=6
  e=inspect_output(v,t,['c'])['errors'];self.assertIn('sentence_limit',e);self.assertIn('core_limit_subset',e)
 def test_one_attempt_marker_blocks_process(self):
  with tempfile.TemporaryDirectory() as tmp:
   out=Path(tmp);(out/'sookmyung').mkdir();(out/'sookmyung/attempt.json').write_text('{}')
   with patch.object(runner,'OUT',out),patch.object(runner,'assemble',return_value=('prompt',{},[],b'answer')),patch.object(runner.subprocess,'run') as run:
    with self.assertRaises(FileExistsError):runner.execute('sookmyung')
    run.assert_not_called()
 def test_accepted_input_only_and_private(self):
  for case in runner.LABELS:
   prompt,manifest,images,answer=runner.assemble(case)
   self.assertFalse(manifest['prior_evaluation_supplied']);self.assertFalse(manifest['quality_label_supplied']);self.assertNotIn('local_reviews',runner.schema(case)['properties'])
   self.assertEqual(hashlib.sha256(answer).hexdigest(),runner.TRANSCRIPTION[case])
if __name__=='__main__':unittest.main()
