import unittest
from tool.essay_lab.exam_group_inventory import summarize


class ExamCoverageTests(unittest.TestCase):
    def fixture(self):
        return dict(exams=[dict(exam_id='e', slug='u', registered_questions=2,
            approved_question_ids=['q1'], runtime_policy=True)],
            questions=[dict(exam_id='e', question_id=q) for q in ['q1', 'q2']],
            materials=[])

    def test_partial_approval_cannot_be_whole_exam(self):
        result = summarize(self.fixture(), [])
        self.assertEqual(result['by_university']['u']['whole_exam_approvals'], 0)
        self.assertEqual(result['by_university']['u']['approved_questions'], 1)

    def test_foreign_approval_rejected(self):
        data = self.fixture()
        data['exams'][0]['approved_question_ids'] = ['foreign']
        with self.assertRaises(ValueError):
            summarize(data, [])

    def test_prior_pass_does_not_grant_publication(self):
        data = self.fixture()
        data['exams'][0]['approved_question_ids'] = ['q1', 'q2']
        prior = [dict(question_id=q, profile_mapped=True, input_pass=True)
                 for q in ['q1', 'q2']]
        result = summarize(data, prior)
        self.assertTrue(result['exams'][0]['whole_exam_approval'])
        self.assertFalse(result['exams'][0]['public_whole_exam_verified'])
        self.assertIsNone(result['exams'][0]['current_input_pass'])


if __name__ == '__main__':
    unittest.main()
