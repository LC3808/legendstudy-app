"""Gate D tests are synthetic/network-blocked; no live authorization."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from tool.essay_lab import strong_answer_calibration as c
from tool.essay_lab import strong_answer_review as review
from tool.test_hanyang_recovery import Factory
from tool.test_essay_live_worker import fixture
from tool.test_vnext_validation import envelope, KEY

class Lifecycle(unittest.TestCase):
    def setUp(self):
        t=tempfile.TemporaryDirectory(prefix='essay-l2c3-test',dir='/private/tmp');self.addCleanup(t.cleanup);self.root=Path(t.name)
        claim,_,self.output=fixture();claim['input']['attempt_id']=c.SLOT;self.output['attempt_id']=c.SLOT
        payload={'model':c.POLICY['model']}
        binding=dict(slot=c.SLOT,policy=c.POLICY,payload_hash=c.old.digest(payload),claim_hash=c.old.digest(claim))
        self.prepared=({},claim,payload,binding)
        p=patch('http.client.HTTPSConnection',side_effect=AssertionError('NETWORK_FORBIDDEN'));p.start();self.addCleanup(p.stop)
    def execute(self,f):return c.run(self.root,self.prepared,KEY,c.DiagnosticHTTP(factory=f),synthetic=True)
    def test_zero_core_and_zero_sentences_valid(self):
        self.output['core_improvement_keys']=[];self.output['sentence_feedback']=[]
        out=self.execute(Factory([envelope(self.output)]));self.assertEqual(out['parser'],'PASS');self.assertEqual(out['core_count'],0)
    def test_zero_core_non_core_root_retained(self):
        self.output['core_improvement_keys']=[]
        out=self.execute(Factory([envelope(self.output)]));self.assertEqual(out['sentence_root'],'PASS')
        normalized=json.loads((self.root/'results'/c.SLOT/'normalized.json').read_text());self.assertTrue(normalized['improvements'])
    def test_consumed_no_repeat(self):
        f=Factory([envelope(self.output)]);self.execute(f)
        with self.assertRaises(c.Invalid):self.execute(f)
        self.assertEqual(f.calls,1)
    def test_unknown_no_repeat(self):
        f=Factory(error_at='headers');out=self.execute(f);self.assertEqual(out['state'],'UNKNOWN_CONSUMED')
        with self.assertRaises(c.Invalid):self.execute(f)
        self.assertEqual(f.calls,1)
    def test_raw_frozen_before_parser(self):
        parser=c.old.parse_provider
        def check(raw,claim):
            self.assertTrue((self.root/'started'/f'{c.SLOT}.json').exists());self.assertTrue((self.root/'results'/c.SLOT/'raw-response.bin').exists());return parser(raw,claim)
        with patch.object(c.old,'parse_provider',side_effect=check):self.assertEqual(self.execute(Factory([envelope(self.output)]))['parser'],'PASS')
    def test_orphan_root_rejected(self):
        self.output['sentence_feedback'][0]['linked_issue_key']='missing'
        out=self.execute(Factory([envelope(self.output)]));self.assertEqual(out['validation_error'],'SENTENCE_ROOT')
        self.assertFalse((self.root/'results'/c.SLOT/'normalized.json').exists())
    def test_substitution_rejected(self):
        data=json.loads(envelope(self.output));data['model']='other'
        self.assertEqual(self.execute(Factory([c.old.encoded(data)]))['request_outcome'],'MODEL_MISMATCH')
    def test_live_closed(self):
        with self.assertRaises(c.Invalid):c.dispatch()
        self.assertIsNone(c.EXECUTION_AUTHORIZATION)
    def test_gate_c_requires_owner_pass(self):
        with patch.object(c.recovery,'protection'),patch.object(c.recovery,'gate_a'),patch.object(c.old,'phase_a'),patch.object(c.old,'read_private',return_value=c.old.encoded(dict(status='WAIT_OWNER_REVIEW'))):
            with self.assertRaises(c.Invalid):c.gate_c()
    def test_secret_echo_withheld(self):
        out=self.execute(Factory([KEY.encode()]));self.assertEqual(out['request_outcome'],'SECRET_ECHO_WITHHELD')
        self.assertFalse((self.root/'results'/c.SLOT/'raw-response.bin').exists())

@unittest.skipUnless(c.old.PACKAGES.exists(),'private source unavailable')
class Blindness(unittest.TestCase):
    def test_provenance_and_exact_body(self):
        value,claim,payload,binding=c.assemble()
        self.assertEqual(c.old.sha256(value['answer'].encode()).hexdigest(),c.EXAMPLE_HASH)
        self.assertEqual(binding['answer_provenance']['semantic_role'],'official_example')
        self.assertEqual(value['answer'],claim['answer'])
        self.assertEqual(value['answer_hash'],claim['input']['answer_hash'])
    def test_labels_and_review_absent_from_payload(self):
        value,_,payload,binding=c.assemble();text=payload['input'][0]['content'][0]['text']
        for label in ('official_example','example-1','model_answer','calibration','strong','high_quality','Owner','PRIMARY','expected_core'):
            self.assertNotIn(label,text)
        self.assertNotIn('answer_provenance',payload)
        self.assertTrue(all(e['semantic_role'] not in c.old.evidence.EXAMPLES for e in value['evidence']))
    def test_evidence_prompt_schema_preserved_new_assembly_hash(self):
        original=c.old.assemble('sookmyung-openai-vnext-l2c2-1');new=c.assemble()
        for key in ('evidence','criteria','question','image_order'):self.assertEqual(original[0][key],new[0][key])
        for key in ('instructions','reasoning','max_output_tokens','text','model'):self.assertEqual(original[2][key],new[2][key])
        self.assertNotEqual(original[3]['package_hash'],new[3]['package_hash'])
        self.assertEqual(original[3]['package_hash'],new[3]['base_package_hash'])
        self.assertEqual(c.old.digest(new[3]['assembly']),new[0]['evidence_package_hash'])
        self.assertEqual(new,c.assemble())
    def test_tampered_source_rejected(self):
        read=c.old.blob
        with patch.object(c.old,'blob',side_effect=lambda p:b'changed' if str(p).endswith('example-1.txt') else read(p)):
            with self.assertRaises(c.Invalid):c.assemble()
    def test_report_emphasizes_owner_judgment(self):
        self.assertGreaterEqual(len(review.CHECKS),8)
        self.assertTrue(any('CORE=0' in s for s in review.CHECKS))

if __name__=='__main__':unittest.main()
