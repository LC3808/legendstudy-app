import unittest
from manus_structure_compare import compare, UNIVERSITIES


class SurveyBoundaries(unittest.TestCase):
    def test_sittings_and_answer_units_do_not_become_new_ids_or_approvals(self):
        surveys = {s: {'exams': [], 'questions': [], 'guidance_2027': []} for s in UNIVERSITIES}
        surveys['성균관대']['exams'] = [dict(exam_id='research-only', year=2026,
            track_key='언어형', set_list=['언어형 1교시', '언어형 2교시'],
            main_count=3, sub_count=0, response_count=3, source_ids=['official'], character_limits='미지정')]
        exams = [dict(id=str(i), university_id=UNIVERSITIES['성균관대'], admission_year=2026,
            exam_kind='admission', field_or_division='언어형', session_label=f'{i}교시',
            exam_name=f'2026 언어형 {i}교시', registered_questions=3, runtime_policy=None) for i in (1, 2)]
        questions = [dict(id=f'{i}-{q}', essay_exam_id=str(i)) for i in (1, 2) for q in (1, 2, 3)]
        result = compare(surveys, {'exams': exams, 'questions': questions})
        self.assertEqual(result['summary']['성균관대']['survey_sittings'], 2)
        self.assertEqual([r['registry_exam_id'] for r in result['exams']], ['1', '2'])
        self.assertTrue(all(not r['publication_approved'] for r in result['exams']))
        # Future guidance cannot supply missing historical questions.
        surveys['성균관대']['guidance_2027'] = [{'main_count': 99}]
        exams[0]['exam_kind'] = 'mock'
        result = compare(surveys, {'exams': exams, 'questions': questions})
        self.assertEqual(result['summary']['성균관대']['missing_exams'], 1)
        self.assertIsNone(result['exams'][0]['registry_exam_id'])


if __name__ == '__main__':
    unittest.main()
