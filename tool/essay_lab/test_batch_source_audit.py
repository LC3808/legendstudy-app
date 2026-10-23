import unittest
from unittest.mock import patch
from .batch_source_audit import audit, evidence_check, extract_source, in_requested_year_scope


class SourceAuditTests(unittest.TestCase):
    def test_malformed_font_does_not_abort_other_sources(self):
        with patch('pathlib.Path.read_bytes', return_value=b'pdf'), \
                patch('tool.essay_lab.batch_source_audit.PdfReader', side_effect=KeyError('DescendantFonts')):
            self.assertEqual(extract_source('malformed.pdf'), {'error': 'KeyError'})

    def test_preserve_2021_and_exclude_nonmock_2027(self):
        for year, kind, expected in [(2021, 'mock', False), (2022, 'admission', True),
                                      (2027, 'mock', True), (2027, 'admission', False)]:
            self.assertEqual(in_requested_year_scope(dict(admission_year=year, exam_kind=kind)), expected)

    def test_hash_and_page_boundary_fail_closed(self):
        source = dict(sha256='actual', pages=['question'])
        ref = dict(role='question', source_hash='foreign', pages=[1, 2])
        result = evidence_check(ref, source)
        self.assertEqual(result['problems'], ['SOURCE_HASH_MISMATCH', 'INVALID_PAGE_RANGE'])
        self.assertEqual(result['text'], '')

    def test_successful_extraction_never_grants_runtime_or_activation(self):
        refs = [dict(role=role, source_hash='hash', pages=[1, 1], source_path='source')
                for role in ('question', 'intent', 'criteria')]
        row = dict(admission_year=2026, exam_kind='admission', university='swu',
                   exam_id='exam', question_id='q', field_or_division='humanities', evidence=refs)
        profile = dict(profile_id='p', profile_version=6, profile_digest='digest')
        result = audit([row], {'q': profile}, {'source': dict(sha256='hash', pages=['official'])})[0]
        self.assertTrue(result['extraction_checks_pass'])
        self.assertFalse(result['runtime_input_pass'])
        self.assertFalse(result['activation_candidate'])
        self.assertEqual(result['semantic_review'], 'NOT_GRANTED_BY_EXTRACTION')

    def test_glyphs_require_visual_review(self):
        result = evidence_check(dict(role='criteria', source_hash='hash', pages=[1, 1]),
                                dict(sha256='hash', pages=['formula \ue000']))
        self.assertIn('GLYPH_REVIEW_REQUIRED', result['problems'])


if __name__ == '__main__':
    unittest.main()
