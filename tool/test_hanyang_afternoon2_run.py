import copy,json,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
from essay_lab import hanyang_afternoon2_run as r

class Afternoon2Tests(unittest.TestCase):
    def sample(self):
        refs=json.loads(r.SOURCE.read_text())['references']
        return {'overall_feedback':'전체 평가','criterion_feedback':[{'criterion_id':i,'feedback':'구체적 진단','evidence_references':['E2']} for i in r.IDS],'strengths':['강점'],'improvements':['보완'],'revision_priorities':['행동'],'evidence_references':[dict(evidence_id=k,**v) for k,v in refs.items()]}
    def test_contract_unchanged(self):
        s=json.loads(r.SOURCE.read_text());self.assertEqual(r.sha(r.CONTRACT.read_bytes()),s['contract_sha256'])
    def test_gate_and_target(self):
        s=json.loads(r.SOURCE.read_text());self.assertEqual(s['gate'],'PASS');self.assertEqual(s['selected_answer_page'],2);self.assertIn('afternoon-2',str(s['target']))
    def test_valid_output(self):r.validate_output(self.sample())
    def test_missing_criterion_rejected(self):
        v=self.sample();v['criterion_feedback'].pop()
        with self.assertRaises(AssertionError):r.validate_output(v)
    def test_fake_locator_rejected(self):
        v=self.sample();v['evidence_references'][0]['source_locator']='invented'
        with self.assertRaises(AssertionError):r.validate_output(v)
    def test_unknown_reference_rejected(self):
        v=self.sample();v['criterion_feedback'][0]['evidence_references']=['X']
        with self.assertRaises(AssertionError):r.validate_output(v)
    def test_no_ground_truth_read_in_execute(self):
        import inspect
        self.assertNotIn('ground_truth.json',inspect.getsource(r.execute))
    def test_duplicate_attempt_blocked(self):
        with tempfile.TemporaryDirectory() as p:
            f=Path(p)/'attempt.json';r.write_new(f,b'{}')
            with self.assertRaises(FileExistsError):r.write_new(f,b'{}')
    @unittest.skipUnless((r.PACKAGE/'manifest.json').exists(),'private package not installed')
    def test_blind_deterministic_assembly(self):
        p,a=r.assemble();q,b=r.assemble();self.assertEqual(p,q);self.assertEqual(a,b)
        for term in r.FORBIDDEN:self.assertNotIn(term.lower(),p.lower())
        self.assertNotIn('Downloads',p);self.assertNotIn('answer_provenance',p)
        self.assertEqual(a['image_count'],6)
    @unittest.skipUnless((r.PACKAGE/'manifest.json').exists(),'private package not installed')
    def test_asset_tampering_rejected(self):
        with tempfile.TemporaryDirectory() as p:
            import shutil
            shutil.copytree(r.PACKAGE,p,dirs_exist_ok=True);Path(p,'student_1.png').write_bytes(b'bad')
            with patch.object(r,'PACKAGE',Path(p)),self.assertRaises(AssertionError):r.assemble()

class FrozenResultTests(unittest.TestCase):
    def test_sanitized_result_and_contract(self):
        v=json.loads((r.ROOT/'tool/essay_lab/evidence/hanyang_afternoon2_benchmark_v1_1.json').read_text())
        self.assertEqual(v['run_count'],1);self.assertEqual(v['scorecard']['overall'],'PARTIAL')
        self.assertEqual(v['input_manifest']['contract_sha256'],r.sha(r.CONTRACT.read_bytes()))
        self.assertLess(v['frozen_at'],v['revealed_at'])
        self.assertFalse(v['safety']['production_mutation'])
    @unittest.skipUnless((r.OUT/'frozen_receipt.json').exists(),'private run not installed')
    def test_frozen_integrity_and_output(self):
        f=json.loads((r.OUT/'frozen_receipt.json').read_text())
        for n,h in f['files'].items():self.assertEqual(r.sha((r.OUT/n).read_bytes()),h)
        r.validate_output(json.loads((r.OUT/'raw_output.json').read_text()))
        g=json.loads((r.OUT/'reveal.json').read_text());self.assertLess(f['frozen_at'],g['revealed_at'])
    @unittest.skipUnless((r.OUT/'raw_output.json').exists(),'private run not installed')
    def test_student_terminology_and_exact_duplicates(self):
        v=json.loads((r.OUT/'raw_output.json').read_text())
        strings=[v['overall_feedback']]+[c['feedback'] for c in v['criterion_feedback']]+v['strengths']+v['improvements']+v['revision_priorities']
        text=' '.join(strings).lower()
        import re
        for term in json.loads(r.CONTRACT.read_text())['student_hidden_terms']:
            self.assertIsNone(re.search(r'\b'+re.escape(term.lower())+r'\b',text),term)
        for key in ['improvements','revision_priorities']:self.assertEqual(len(v[key]),len(set(v[key])))
    @unittest.skipUnless((r.PACKAGE/'student_1.png').exists(),'private source not installed')
    def test_original_answer_pixels_preserved(self):
        from pypdf import PdfReader
        from PIL import Image
        source=json.loads(r.SOURCE.read_text())
        original=PdfReader(source['files'][1]['local_path']).pages[1].images[0].image.convert('RGB')
        actual=Image.open(r.PACKAGE/'student_1.png').convert('RGB')
        self.assertEqual(original.size,actual.size);self.assertEqual(original.tobytes(),actual.tobytes())
    def test_private_files_ignored(self):
        import subprocess
        for p in [r.OUT/'raw_output.json',r.PACKAGE/'student_1.png',r.PACKAGE/'ground_truth.json']:
            result=subprocess.run(['git','check-ignore',str(p)],cwd=r.ROOT,capture_output=True)
            self.assertEqual(result.returncode,0)
            tracked=subprocess.run(['git','ls-files','--error-unmatch',str(p)],cwd=r.ROOT,capture_output=True)
            self.assertNotEqual(tracked.returncode,0)

if __name__=='__main__':unittest.main()
