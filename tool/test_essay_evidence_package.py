"""Metadata tests everywhere; actual private PDF regression when locally present."""
import copy
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from essay_lab.evidence_package import (SOURCE, ROOT, EXAM_ID, RESOURCE_ID, PDF_SHA,
    build, validate_source, validate, encode, digest, manifest, question_context)

PDF = ROOT / '.local/essay-pilot-2025/pdfs/1689-00.pdf'
MANIFEST = SOURCE.with_name('skku_2025_humanities1_manifest.json')


class InventoryTests(unittest.TestCase):
    def setUp(self):
        self.s = json.loads(SOURCE.read_text())

    def test_exact_scoped_identity(self):
        i = validate_source(self.s)
        self.assertEqual(i['essay_exam_id'], EXAM_ID)
        self.assertEqual(set(i['missing_roles']), {'model_answer', 'high_scoring_answer', 'guidebook', 'other'})
        self.assertEqual(self.s['pdf_sha256'], PDF_SHA)

    def test_unverified_inactive_or_nonofficial_excluded(self):
        for field, value in [('is_active', False), ('verification_status', 'review'), ('provenance', 'ai_generated')]:
            s = copy.deepcopy(self.s)
            s['mappings'][0][field] = value
            with self.assertRaises(ValueError): validate_source(s)

    def test_missing_locator_or_official_reference_rejected(self):
        for field in ['source_locator', 'official_source_url']:
            s = copy.deepcopy(self.s); s['mappings'][0][field] = ''
            with self.assertRaises(ValueError): validate_source(s)

    def test_other_exam_or_resource_rejected(self):
        for field in ['essay_exam_id', 'resource_id']:
            s = copy.deepcopy(self.s); s['mappings'][0][field] = 'other'
            with self.assertRaises(ValueError): validate_source(s)

    def test_duplicate_role_rejected(self):
        self.s['mappings'].append(copy.deepcopy(self.s['mappings'][0]))
        with self.assertRaises(ValueError): validate_source(self.s)

    def test_hidden_parent_rejected(self):
        for table in ['university', 'exam', 'resource', 'content_item']:
            s = copy.deepcopy(self.s); s[table]['is_active'] = False
            with self.assertRaises(ValueError): validate_source(s)

    def test_public_manifest_contains_no_body(self):
        m = json.loads(MANIFEST.read_text())
        self.assertEqual(m['evidence_items'], 21)
        self.assertEqual(m['ai_generated_items'], 0)
        self.assertEqual(len(m['questions']), 3)
        self.assertTrue(all('text' not in e for e in m['locators']))


@unittest.skipUnless(PDF.exists() and importlib.util.find_spec('pdfplumber'),
                     'Private source PDF/pdfplumber unavailable; real-source tests NOT_RUN')
class RealPDFTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.s = json.loads(SOURCE.read_text())
        cls.p, cls.fig = build(cls.s, PDF)
        cls.e = {e['id']: e for e in cls.p['evidence']}

    def test_byte_identical_rebuild_and_manifest(self):
        p, fig = build(self.s, PDF)
        self.assertEqual(encode(p), encode(self.p))
        self.assertEqual(fig, self.fig)
        self.assertEqual(manifest(p, fig), json.loads(MANIFEST.read_text()))

    def test_mapping_order_does_not_change_package(self):
        s = copy.deepcopy(self.s); s['mappings'].reverse()
        p, fig = build(s, PDF)
        self.assertEqual(encode(p), encode(self.p))
        self.assertEqual(fig, self.fig)

    def test_changed_pdf_fails_closed(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'changed.pdf'; path.write_bytes(b'%PDF-changed')
            with self.assertRaisesRegex(ValueError, 'hash'): build(self.s, path)

    def test_integrity_rejects_content_edit(self):
        p = copy.deepcopy(self.p); p['evidence'][0]['text'] += 'invented'
        with self.assertRaisesRegex(ValueError, 'integrity'): validate(p)

    def test_official_score_and_grade_not_conflated(self):
        self.assertEqual([q['max_score'] for q in self.p['questions']], [40, 40, 20])
        for q in self.p['questions']:
            self.assertIsNone(q['grade_numeric_conversion'])
            self.assertEqual(len(q['criteria']), 9)
            text = self.e[q['evidence']['scoring_criteria']]['text']
            self.assertNotIn('40점', text)
            self.assertNotIn('20점', text)
            for label in 'ABCDEF': self.assertIn(label+':', text)

    def test_continuation_pages_not_truncated(self):
        self.assertEqual(self.e['q1-explanation']['pdf_pages'], [6, 7])
        self.assertEqual(self.e['q2-criteria']['pdf_pages'], [12, 13])
        self.assertEqual(self.e['q3-example-answer']['pdf_pages'], [17, 18])
        self.assertIn('공동체 발전에 부정적인 영향을 미치게 될 것이다.', self.e['q3-example-answer']['text'])

    def test_dependency_closure_preserves_assumptions(self):
        context = question_context(self.p, '문제 3')
        ids = {e['id'] for e in context['evidence']}
        self.assertTrue({'q1-prompt', 'q2-prompt', 'q2-data-1', 'q2-data-2'}.issubset(ids))
        self.assertTrue({f'q1-passage-{i}' for i in range(1, 5)}.issubset(ids))
        self.assertNotIn('q1-example-answer', ids)
        self.assertIn('다른 모든 조건은 A, B, C국에서 동일', self.e['q2-prompt']['text'])

    def test_graph_preserved_without_inferred_bar_numbers(self):
        e = self.e['q2-data-1']
        self.assertEqual(e['asset']['sha256'], digest(self.fig))
        self.assertTrue(self.fig.startswith(b'\x89PNG'))
        self.assertNotIn('4.5', e['text'])
        self.assertTrue(self.p['questions'][1]['requires_figure'])
        self.assertFalse(self.p['questions'][0]['requires_figure'])

    def test_table_headers_footnotes_and_values(self):
        e = self.e['q2-data-2']
        self.assertEqual(e['table_columns'], ['항목', '회원국 평균', 'A국', 'B국', 'C국'])
        self.assertIn('34.1 55.3 39.3 40.5', e['text'])
        for i in range(3, 8): self.assertIn(f'주{i})', e['text'])

    def test_evidence_traceable_and_no_generated_answers(self):
        self.assertTrue(validate(self.p))
        self.assertEqual(len(self.e), 21)
        self.assertTrue(all(e['resource_id'] == RESOURCE_ID and e['provenance'] == 'official' for e in self.e.values()))
        self.assertFalse(any(e['role'] in ('model_answer', 'high_scoring_answer') for e in self.e.values()))


if __name__ == '__main__': unittest.main()
