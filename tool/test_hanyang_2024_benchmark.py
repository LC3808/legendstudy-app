"""Guard the real source mismatch and unexecuted benchmark; no model/DB calls."""
import hashlib
import json
from pathlib import Path
import unittest
from uuid import UUID

ROOT=Path(__file__).resolve().parents[1]
EVIDENCE=ROOT/'tool/essay_lab/evidence'

class Hanyang2024PreparationTest(unittest.TestCase):
    def setUp(self):
        self.source=json.loads((EVIDENCE/'hanyang_2024_benchmark_source.json').read_text())
        self.contract=json.loads((EVIDENCE/'evaluation_contract_v1_1.json').read_text())

    def test_v1_preserved_and_output_keys_compatible(self):
        data=(EVIDENCE/'evaluation_contract_v1.json').read_bytes()
        self.assertEqual(hashlib.sha256(data).hexdigest(),self.contract['base_sha256'])
        self.assertEqual(list(json.loads(data)['output_draft']),self.contract['output_keys_preserved'])

    def test_real_wrong_answer_cannot_be_claimed_ready(self):
        s=self.source
        self.assertEqual(s['status'],'BLOCKED_TARGET_ANSWER_MISMATCH')
        self.assertTrue(s['mismatch']['all_embedded_images_equal'])
        self.assertTrue(s['mismatch']['container_hashes_differ'])
        self.assertEqual(s['run_count'],0)
        self.assertFalse(s['blind_input_generated'])
        self.assertFalse(s['production_mapping_apply'])
        self.assertNotIn(s['mismatch']['resource_id'],[m['resource_id'] for m in s['mapping_preview']])

    def test_existing_ids_and_sessions_not_conflated(self):
        ids=[d['resource_id'] for d in self.source['documents']]
        self.assertEqual(len(ids),len(set(ids)))
        for rid in ids:UUID(rid)
        self.assertNotEqual(self.source['target']['exam_key'],self.source['afternoon2']['exam_key'])
        self.assertEqual(self.source['target']['admission_year'],2024)

    def test_official_source_claims_bounded(self):
        verified=[d for d in self.source['documents'] if d['official_url_status']=='VERIFIED_BINARY_MATCH']
        self.assertEqual(len(verified),2)
        for d in verified:self.assertTrue(d['official_source_url'].startswith('https://go.hanyang.ac.kr/web/pds/pds_view.do?bn='))
        for d in self.source['documents']:
            if d not in verified:self.assertIsNone(d['official_source_url'])

    def test_contract_minimal_policy_not_claimed_benchmarked(self):
        self.assertEqual(self.contract['version'],'1.1')
        self.assertEqual(self.contract['status'],'PREPARED_NOT_BENCHMARKED')
        self.assertIn('하나의 개선 과제로', ' '.join(self.contract['rules']))
        self.assertIn('한국어',' '.join(self.contract['rules']))
        self.assertIn('hallucination',self.contract['student_hidden_terms'])
        self.assertEqual(self.contract['presentation']['strengths'],'잘한 점')

    def test_owner_pdf_bytes_when_available(self):
        for d in self.source['documents']:
            path=Path('/Users/woojinchang/Downloads')/d['filename']
            if not path.exists():self.skipTest('private Owner files unavailable')
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),d['sha256'])

    def test_actual_embedded_images_when_available(self):
        try:from pypdf import PdfReader
        except ImportError:self.skipTest('pypdf unavailable')
        paths=[Path('/Users/woojinchang/Downloads')/name for name in [
          '2024학년도 한양대 수시 논술_인문계열(오후1) 합격자 예시답안.pdf',
          '2024학년도 한양대 수시 논술_상경계 우수답안 (1).pdf']]
        if not all(p.exists() for p in paths):self.skipTest('private source unavailable')
        hashes=[[hashlib.sha256(i.data).hexdigest() for p in PdfReader(f).pages for i in p.images] for f in paths]
        self.assertEqual(hashes[0],hashes[1])
        self.assertEqual(hashes[0],self.source['mismatch']['embedded_image_sha256'])

if __name__=='__main__':unittest.main()
