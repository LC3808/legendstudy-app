import unittest
from copy import deepcopy
from tool.essay_lab.evidence_text_quality import audit, correction_candidate, sha, text_findings


class EvidenceQualityTests(unittest.TestCase):
    def codes(self, text):
        return {f['code'] for f in text_findings(text)}

    def test_interleaved_label_and_split_are_review_candidates_not_repaired(self):
        text = '이유를 제시하\n준거 1 는 것이다.'
        self.assertIn('C_MID_SENTENCE_LABEL', self.codes(text))
        self.assertEqual(text, '이유를 제시하\n준거 1 는 것이다.')
        self.assertTrue(all(f['status'] == 'MANUAL_PDF_REVIEW' for f in text_findings(text)))

    def test_split_and_layout_line(self):
        self.assertIn('D_POSSIBLE_SPLIT_WORD', self.codes('과\n학의 발전'))
        self.assertIn('ABNORMAL_LINE_BREAK', self.codes('이것은 긴 문장으로 PDF 너비에 따라 임의로 끊어지는 추출 결과를\n검사한다.'))

    def test_duplicate_sentence_and_heading(self):
        self.assertIn('F_REPEATED_SENTENCE', self.codes(('정확한 근거를 활용하여 주장의 타당성을 충분하게 설명해야 합니다.\n')*2))
        self.assertIn('DUPLICATE_CRITERION_HEADING', self.codes('6. 채점 기준\n6. 채점 기준'))

    def test_table_and_subquestion_order(self):
        self.assertIn('B_FLATTENED_TABLE', self.codes('하위\n채점 기준 배점\n문항'))
        self.assertIn('E_SUBQUESTION_ORDER', self.codes('[문항 1]의 (2)\n[문항 1]의 (1)'))
        self.assertNotIn('E_SUBQUESTION_ORDER', self.codes('[문항 1]의 (2)\n[문항 2]의 (1)'))

    def package(self):
        return dict(exam_id='e', package_version=3, package_digest='prior', questions=[
            dict(question_id='q', source_page_references=[dict(role='criteria', startPage=6,
                 sourceHash='pdf', evidenceText='old', verification='VERIFIED')])])

    def test_missing_material_and_no_source_body_in_report(self):
        result = audit(self.package())
        self.assertEqual(result['findings'][0]['roles'], ['question'])
        self.assertNotIn('evidenceText', str(result))
        self.assertEqual(audit(self.package(), ('criteria', 'intent', 'example_answer'))['findings'][0]['roles'],
                         ['example_answer', 'intent'])

    def manifest(self):
        return dict(prior_digest='prior', reviewer='offline-review', replacements=[dict(
            question_id='q', reference_index=0, before_sha256=sha('old'), source_hash='pdf',
            page=6, visual_pdf_verified=True, after_text='new')])

    def test_candidate_preserves_original_and_cannot_claim_verified(self):
        original = self.package(); before = deepcopy(original)
        out = correction_candidate(original, self.manifest())
        self.assertEqual(original, before)
        self.assertEqual(out['exam_id'], original['exam_id'])
        self.assertEqual(out['questions'][0]['question_id'], 'q')
        self.assertEqual(out['package_version'], 4)
        self.assertEqual(out['verification_status'], 'CANDIDATE_OWNER_REVIEW')
        self.assertNotEqual(out['package_digest'], 'prior')

    def test_rejects_wrong_hash_page_or_missing_review(self):
        for field, value in [('before_sha256', 'bad'), ('page', 5), ('source_hash', 'other'),
                             ('visual_pdf_verified', False), ('after_text', '')]:
            manifest = self.manifest(); manifest['replacements'][0][field] = value
            with self.assertRaises(ValueError):
                correction_candidate(self.package(), manifest)

    def test_rejects_duplicate_replacements(self):
        manifest = self.manifest(); manifest['replacements'] *= 2
        with self.assertRaises(ValueError):
            correction_candidate(self.package(), manifest)


if __name__ == '__main__':
    unittest.main()
