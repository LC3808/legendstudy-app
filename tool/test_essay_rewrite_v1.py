import json,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
from essay_lab import rewrite_pilot_v1 as r

class RewriteTests(unittest.TestCase):
    def test_character_count_includes_spaces_not_newlines(self):
        self.assertEqual(r.text_length('가 나.\n다'),5)
        self.assertEqual(r.text_length('가'),1)
    def test_provenance_not_official(self):
        self.assertEqual(set(r.schema()['properties']),{'rewritten_answer'})
    def test_exclusive_attempt_guard(self):
        with tempfile.TemporaryDirectory() as p:
            f=Path(p)/'attempt.json';r.write_new(f,b'{}')
            with self.assertRaises(FileExistsError):r.write_new(f,b'{}')
    @unittest.skipUnless((r.PRIVATE/'hanyang/original.txt').exists(),'private fixture missing')
    def test_independent_deterministic_inputs(self):
        for case in r.CASES:
            p,m,images=r.assemble(case);q,n,_=r.assemble(case)
            self.assertEqual(p,q);self.assertEqual(m,n)
            self.assertEqual(m['origin'],'ai_generated')
            self.assertFalse(m['reference_answer_supplied'])
            for term in r.FORBIDDEN:self.assertNotIn(term.lower(),p.lower())
            other='숙명' if case=='hanyang' else '한양';self.assertNotIn(other,p)
            self.assertNotIn('ground_truth.json',p);self.assertNotIn('official-2025-guide.pdf',p)
            self.assertTrue(all(x.suffix=='.png' for x in images))
    @unittest.skipUnless((r.PRIVATE/'hanyang/original.txt').exists(),'private fixture missing')
    def test_transcription_label_rejected(self):
        with tempfile.TemporaryDirectory() as p:
            f=Path(p)/'hanyang';f.mkdir();(f/'original.txt').write_text('합격자 우수답안')
            with patch.object(r,'PRIVATE',Path(p)),self.assertRaises(AssertionError):r.assemble('hanyang')
    @unittest.skipUnless((r.PRIVATE/'sookmyung/original.txt').exists(),'private fixture missing')
    def test_cross_case_transcription_rejected(self):
        with tempfile.TemporaryDirectory() as p:
            f=Path(p)/'sookmyung';f.mkdir();(f/'original.txt').write_text('한양 결과')
            with patch.object(r,'PRIVATE',Path(p)),self.assertRaises(AssertionError):r.assemble('sookmyung')
    def test_no_evaluation_call(self):
        import inspect
        code=inspect.getsource(r)
        self.assertNotIn('hy.execute(',code);self.assertNotIn('sm.execute(',code)
        self.assertNotIn("read_text()).get('ground_truth'",code)

class FrozenRewriteTests(unittest.TestCase):
    @unittest.skipUnless(all((r.PRIVATE/c/'frozen_receipt.json').exists() for c in r.CASES),'both private outputs not installed')
    def test_both_results_frozen_and_one_attempt_each(self):
        for c in r.CASES:
            out=r.PRIVATE/c;receipt=json.loads((out/'frozen_receipt.json').read_text())
            self.assertEqual(receipt['run_count'],1)
            for n,h in receipt['files'].items():self.assertEqual(r.sha((out/n).read_bytes()),h)
            self.assertEqual(len(list(out.glob('attempt*.json'))),1)
    @unittest.skipUnless(all((r.PRIVATE/c/'validated_receipt.json').exists() for c in r.CASES),'both private outputs not installed')
    def test_reported_lengths_are_measured(self):
        for c in r.CASES:
            out=r.PRIVATE/c;v=json.loads((out/'raw_output.json').read_text())
            receipt=json.loads((out/'validated_receipt.json').read_text())
            self.assertEqual(receipt['rewrite_length'],r.text_length(v['rewritten_answer']))
            lo,hi=r.CASES[c]['range'];self.assertEqual(receipt['length_compliant'],lo<=receipt['rewrite_length']<=hi)
    @unittest.skipUnless(all((c['evaluation']/'raw_output.json').exists() for c in r.CASES.values()),'private evaluations not installed')
    def test_original_evaluations_immutable(self):
        for c in r.CASES.values():self.assertEqual(r.sha((c['evaluation']/'raw_output.json').read_bytes()),c['output_sha'])
    def test_private_exclusion(self):
        import subprocess
        for c in r.CASES:
            for n in ['original.txt','raw_output.json','prompt.txt','owner_report.md']:
                p=r.PRIVATE/c/n
                self.assertEqual(subprocess.run(['git','check-ignore',str(p)],cwd=r.ROOT,capture_output=True).returncode,0)
                self.assertNotEqual(subprocess.run(['git','ls-files','--error-unmatch',str(p)],cwd=r.ROOT,capture_output=True).returncode,0)
    @unittest.skipUnless(all((r.PRIVATE/c/'raw_output.json').exists() for c in r.CASES),'private outputs not installed')
    def test_student_language_and_provenance(self):
        for c in r.CASES:
            v=json.loads((r.PRIVATE/c/'raw_output.json').read_text());self.assertEqual(set(v),{'rewritten_answer'})
            for term in r.FORBIDDEN+['rubric','criterion','feedback','benchmark','calibration']:
                self.assertNotIn(term.lower(),v['rewritten_answer'].lower())

if __name__=='__main__':unittest.main()
