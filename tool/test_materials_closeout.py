"""Owner-source closeout regression cases; no network or Production writes."""
import unittest
from ingestion.models import RawPost, RawAttachment, IDENTITY_REVIEW_IDS
from ingestion.normalizer import normalize
from ingestion.parser import parse_title, split_resource_kind, split_subject


class MaterialsCloseoutTests(unittest.TestCase):
    def test_postponed_nominal_month(self):
        facts = parse_title('(4월 시행) 2020년 3월 고3 모의고사', None)
        self.assertEqual((facts['calendar_year'], facts['nominal_month'], facts['administered_month']), (2020, 3, 4))

    def test_csat_mock_is_not_csat(self):
        facts = parse_title('[2019년 6월 시행] 2020학년도 대수능 모의평가', '"고3"을 위한 공간')
        self.assertEqual(facts['exam_type'], 'evaluation_mock')
        self.assertEqual(facts['calendar_year'], 2019)
        self.assertEqual(parse_title('2012년 5월 고2 수능 예비시행', None)['exam_type'], 'preliminary')

    def test_historical_names_stay_raw(self):
        left, kind, _ = split_resource_kind('2013년 11월 고1_과학탐구-물리I_문제지.pdf')
        self.assertEqual(kind, 'question')
        self.assertEqual(split_subject(left), ('물리I', True))
        self.assertEqual(split_resource_kind('2014년 국어A 정답 해설.pdf')[1], 'answer_explanation')
        self.assertEqual(split_resource_kind('2020 수학 가형 정답,해설(풀이).pdf')[1], 'answer_explanation')

    def test_general_file_and_whole_exam_answer_keep_semantics(self):
        raw = RawPost('9998', 'https://legendstudy.com/9998', '2014년 3월 고1 모의고사',
                      '"고1"을 위한 공간/1학년 모의고사 전과목 자료', '2023-01-01T00:00:00Z', None,
                      (RawAttachment('cfile', 'A', '2014년 국어.pdf', 'https://t1.daumcdn.net/cfile/tistory/A', False),
                       RawAttachment('cfile', 'B', '2014년 모의고사 정답 및 해설.pdf', 'https://t1.daumcdn.net/cfile/tistory/B', False)))
        p = normalize(raw, '2026-09-27T00:00:00Z', map_subjects=True)
        self.assertTrue(p.publishable)
        self.assertEqual(p.resources[0]['resource_type'], 'other')
        self.assertIsNone(p.resources[1]['occurrence_subject_key'])
        self.assertEqual({q.kind for q in p.quarantine}, {'resource_kind_unknown', 'resource_subject_unknown'})

    def test_only_owner_full_set_counterparts_released(self):
        self.assertNotIn('1431', IDENTITY_REVIEW_IDS)
        self.assertIn('1473', IDENTITY_REVIEW_IDS)
        self.assertEqual(len(IDENTITY_REVIEW_IDS), 34)


if __name__ == '__main__':
    unittest.main()
