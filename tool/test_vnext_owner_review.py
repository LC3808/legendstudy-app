"""No provider execution: private report fidelity and text-rendering regressions."""
import json
from pathlib import Path
import tempfile
import unittest
from tool.essay_lab import vnext_validation as v
from tool.essay_lab import vnext_owner_review as review
from tool.test_vnext_validation import prepared,Fake,envelope,KEY,SLOT

class OwnerReview(unittest.TestCase):
    def setup_result(self,rejected=False,large=False):
        t=tempfile.TemporaryDirectory(prefix='essay-l2c2-test',dir='/private/tmp');self.addCleanup(t.cleanup);root=Path(t.name)
        p,o=prepared();value,claim,payload,binding=p
        value.update(question={'id':'synthetic'},criteria=claim['input']['criteria'],answer=claim['answer'])
        payload['input']=[{'content':[{'text':v.encoded(value).decode()}]}]
        if large:payload['input'][0]['content'].append({'type':'input_image','image_url':'data:image/png;base64,'+'A'*300000})
        binding['payload_hash']=v.digest(payload)
        prep=v.child_dir(v.child_dir(root,'prepared'),SLOT)
        for name,data in zip(('input','claim','payload','binding'),p):v.freeze(prep/f'{name}.json',v.encoded(data))
        o['strengths']=['실제 학생 행동 → WHY → 기준 → 재사용 전략의 합성 원문']
        if rejected:o['sentence_feedback'][0]['linked_issue_key']='missing'
        result=v.run_slot(root,SLOT,p,KEY,Fake(envelope(o)),synthetic=True)
        return root,o,result
    def test_all_fields_and_owner_checks_no_rephrasing(self):
        root,o,r=self.setup_result();path=review.build(root);body=path.read_text()
        for text in [o['summary'],*o['strengths'],o['improvements'][0]['explanation'],o['improvements'][0]['action'],o['sentence_feedback'][0]['quote']]:self.assertIn(text,body)
        for text in review.POSITIVE_CHECKS+review.CORRECTIVE_CHECKS+review.LOGIC_CHECKS:self.assertIn(text,body)
        self.assertIn('PENDING_OWNER_REVIEW',body);self.assertIn('PRIMARY_MODEL_SELECTED=NO',body)
        self.assertEqual(path.stat().st_mode & 0o777,0o400)
    def test_rejected_output_is_not_normalized_or_repaired(self):
        root,o,r=self.setup_result(True);body=review.build(root).read_text()
        self.assertIn('구조 검증 실패',body);self.assertIn(o['summary'],body);self.assertIn('missing',body)
        self.assertFalse((root/'results'/SLOT/'normalized.json').exists())
    def test_large_frozen_request_does_not_use_response_cap(self):
        root,_,_=self.setup_result(large=True);self.assertTrue(review.build(root).is_file())
    def test_provider_markup_stays_fenced(self):
        value='![tracking](https://invalid.example/pixel)\n```\n<script>bad()</script>'
        rendered=review.field(value)
        self.assertTrue(rendered.startswith('\n````text\n'));self.assertIn(value,rendered)
    def test_input_drift_rejected(self):
        root,_,_=self.setup_result();p=root/'prepared'/SLOT/'input.json';p.chmod(0o600);p.write_text('{}');p.chmod(0o400)
        with self.assertRaisesRegex(v.Invalid,'REVIEW_INPUT_DRIFT'):review.build(root)

if __name__=='__main__':unittest.main()
