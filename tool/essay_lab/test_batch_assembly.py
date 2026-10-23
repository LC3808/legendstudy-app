import unittest
from copy import deepcopy

from .batch_assembly import compile_all, registry_from_rows, source_risks
from .university_profile import profile_digest


class BatchAssemblyTests(unittest.TestCase):
    def setUp(self):
        self.row = dict(slug='u', exam_id='e', university_id='u', admission_year=2024,
            exam_kind='admission', field_or_division='인문', session_label=None,
            campus=None, exam_name='Exam', exam_key='source-e', question_id='q',
            question_key='source:q', label='문제 1', display_order=0)
        self.profile = dict(schema='university-evaluation-profile-v1', profile_id='uep/u/human',
            version=1, university_id='u', engine_route='humanities', review_status='REVIEWED',
            scopes=[dict(exam_id='e',year=2024,kind='admission',track='인문',question_ids=['q'])],
            rules=[], criteria_mappings=[])
        self.profile['content_sha256'] = profile_digest(self.profile)
        self.source = dict(question_id='q', problems=[], profile=dict(profile_id='uep/u/human',
            profile_version=1,profile_digest=self.profile['content_sha256']), source_checks=[
                dict(role=role,source_hash='a'*64,pages=[1,1],text='official '+role)
                for role in ('question','intent','criteria')])

    def run_batch(self, rows=None, sources=None, reviews=(), approved=()):
        return compile_all(rows or [self.row], sources or [self.source], [self.profile], approved, reviews)

    def test_clean_extraction_and_profile_do_not_grant_runtime_admission(self):
        result = self.run_batch()
        self.assertTrue(result['questions'][0]['profile_mapped'])
        self.assertFalse(result['questions'][0]['input_pass'])
        self.assertFalse(result['questions'][0]['activation_candidate'])
        self.assertEqual(result['compiled'], {})

    def test_changed_source_invalidates_content_review_without_stopping_siblings(self):
        baseline = self.run_batch()
        review = dict(question_id='q',draft_sha256=baseline['drafts']['q']['content_sha256'],
                      status='REVIEWED',review_evidence={'file':'existing-review'})
        self.source['source_checks'][0]['text'] += ' changed'
        sibling = dict(self.row,question_id='sibling',question_key='source:sibling')
        result = self.run_batch(rows=[self.row,sibling], reviews=[review])
        self.assertEqual(len(result['questions']), 2)
        self.assertIn('COMPILATION:CONTENT_REVIEW_DRIFT', result['questions'][0]['reasons'])
        self.assertFalse(any(r['input_pass'] for r in result['questions']))

    def test_duplicate_registry_ids_are_rejected(self):
        with self.assertRaisesRegex(ValueError, 'DUPLICATE_CANONICAL_QUESTION'):
            registry_from_rows([self.row,self.row], [self.source])

    def test_profile_digest_drift_is_not_inherited(self):
        self.profile['scopes'][0]['year'] = 2025
        result = self.run_batch()
        self.assertFalse(result['questions'][0]['profile_mapped'])

    def test_neighbor_question_and_answer_contamination_are_flagged(self):
        entry = dict(source_page_references=[
            dict(role='question',evidenceText='문제 1 target\n문제 2 neighbor'),
            dict(role='criteria',evidenceText='채점 기준\n예시 답안')])
        self.assertEqual(source_risks(entry),
            ['CRITERIA_CONTAINS_EXAMPLE_ANSWER','QUESTION_SCOPE_REQUIRES_SPLIT'])

    def test_historical_math_does_not_count_as_fresh_essay_input(self):
        self.row['question_id'] = 'cea40cf3-dc05-507a-a6eb-fd5e1e1847bb'
        self.source['question_id'] = self.row['question_id']
        result = self.run_batch()['questions'][0]
        self.assertTrue(result['preserved_math_e2e'])
        self.assertEqual(result['evaluation_scope'], 'FULL_EVALUATION')
        self.assertFalse(result['input_pass'])
        self.assertFalse(result['activation_candidate'])

    def test_preserved_runtime_cannot_bypass_live_identity(self):
        registry = registry_from_rows([self.row], [self.source])
        package = dict(exam_id='e',questions=[dict(question_id='q',source_key='source:foreign')])
        approved = [dict(package=package,policy={},registry=registry)]
        with self.assertRaisesRegex(ValueError, 'PRESERVED_CANONICAL_QUESTION_DRIFT'):
            self.run_batch(approved=approved)


if __name__ == '__main__':
    unittest.main()
