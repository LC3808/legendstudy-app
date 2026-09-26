"""Saved Wave1 labels and mixed-content publication contracts; no network/DB."""
import copy
import json
import unittest
from dataclasses import asdict
from ingestion.models import RawPost, RawAttachment, IDENTITY_REVIEW_IDS
from ingestion.normalizer import normalize, is_advisory
from ingestion.pipeline import run
from ingestion.writer import approved_scope, assert_in_scope, expected_rows, ScopeViolation
from ingestion.apply import resolve, _rows_for, apply_pilot, preflight, ApplyAborted
from ingestion.subjects import map_subject
from ingestion.parser import split_resource_kind, split_subject
from test_ingestion import FakeDb
from test_general_activation import FakeSession
from publish_pilot_c import publish_scope, ScopeCounts, PublicationRefused


def raw(pid='90001', category='수업 자료실', label='학습 가이드북.pdf'):
    attachments = () if label is None else (RawAttachment('cfile', 'file-'+pid, label,
                                  'https://t1.daumcdn.net/cfile/tistory/'+pid, False),)
    return RawPost(pid, 'https://legendstudy.com/'+pid,
                   '2026년 5월 고3 모의고사', category, '2026-01-01', None, attachments)


def plan(pid='90001', category='수업 자료실', label='학습 가이드북.pdf'):
    return normalize(raw(pid, category, label), '2026-09-27', map_subjects=True)


class Wave1Tests(unittest.TestCase):
    def test_supported_types_and_mixed_exact_counts_idempotency(self):
        plans = [plan('90001', '고3을 위한 공간/모의고사', '국어 문제.pdf'),
                 plan('90002', '논술 기출 자료'), plan('90003'),
                 plan('90004', '교육 입시 관련 소식', None)]
        assert_in_scope(plans, approved_scope([p.external_post_id for p in plans]))
        expected = dict(source_posts=4, content_items=4, exams=1, exam_subjects=1, resources=3)
        self.assertEqual(expected_rows(plans), expected)
        posts = [resolve(p) for p in plans]
        self.assertEqual(posts, [resolve(p) for p in plans])
        self.assertEqual(len(_rows_for('exams', posts)), 1)
        self.assertEqual(_rows_for('exams', posts[1:]), [])
        self.assertEqual(_rows_for('exam_subjects', posts[1:]), [])
        db = FakeDb()
        self.assertFalse(preflight(db, posts, 0).already_applied)
        self.assertEqual(apply_pilot(db, posts, expected), expected)
        self.assertTrue(preflight(db, posts, 0).already_applied)
        self.assertEqual(apply_pilot(db, posts, dict.fromkeys(expected, 0)), dict.fromkeys(expected, 0))

    def test_invalid_children_and_unsupported_fail_both_layers(self):
        exam = plan('90001', '고3을 위한 공간/모의고사', '국어 문제.pdf')
        candidates=[]
        p=plan();p.exam=exam.exam;candidates.append(p)
        p=plan();p.occurrences=exam.occurrences;candidates.append(p)
        p=plan();p.resources[0]['occurrence_subject_key']='국어';candidates.append(p)
        p=copy.deepcopy(exam);p.exam=None;candidates.append(p)
        p=plan();p.content_item['content_type']='other';candidates.append(p)
        for p in candidates:
            with self.subTest(p=p), self.assertRaises(ScopeViolation):
                assert_in_scope([p], approved_scope([p.external_post_id], frozenset({'other','exam','study_material'})))
            with self.assertRaises(ApplyAborted): resolve(p)

    def test_unknown_kind_is_only_non_exam_advisory(self):
        general=plan();self.assertTrue(general.publishable)
        self.assertEqual(general.resources[0]['resource_type'], 'other')
        self.assertEqual(general.resources[0]['source_label'], '학습 가이드북.pdf')
        exam=plan(category='고3을 위한 공간/모의고사',label='국어 낯선파일.pdf')
        self.assertFalse(exam.publishable)
        self.assertFalse(is_advisory('resource_kind_unknown','exam'))
        self.assertTrue(is_advisory('resource_kind_unknown','university_essay'))
        self.assertFalse(plan(label=None).publishable)
        self.assertTrue(plan(category='교육 입시 관련 소식',label=None).publishable)

    def test_observed_decorations_and_raw_labels(self):
        for label,subject,kind in [
            ('영어 듣기파일.mp3 (PC/스마트폰 실시간)','영어','listening_audio'),
            ('영어 듣기평가.mp3(실시간 & 다운)','영어','listening_audio'),
            ('국어 문제(홀).pdf','국어','question'),
            ('수학 가형 정답,해설(풀이).pdf','수학 가형','answer_explanation'),
            ('국어_공통 문제.pdf','국어_공통','question'),
            ('국어(+언매) 정답,해설.pdf','국어(+언매)','answer_explanation'),
            ('국어 정답,해설(화작,매체).pdf','국어(화작,매체)','answer_explanation')]:
            with self.subTest(label=label):
                left,k,_=split_resource_kind(label)
                self.assertEqual((split_subject(left)[0],k),(subject,kind))
                p=plan(category='고3을 위한 공간/모의고사',label=label)
                self.assertEqual(p.resources[0]['source_label'],label)
                self.assertEqual(p.occurrences[0]['raw_subject_label'],subject)
        self.assertIsNone(split_resource_kind('영어 듣기파일.mp3 (확인되지않음)')[1])

    def test_uncertain_recognition_never_force_maps(self):
        for label in ('탐구영역','생화과윤리','사회문화1','국어(화작,매체)','수학(기하,미적,확통)'):
            with self.subTest(label=label):
                self.assertEqual(split_subject(label)[0],label)
                self.assertIsNone(map_subject(label,3).code)
                p=plan(category='고3을 위한 공간/모의고사',label=label+' 문제.pdf')
                self.assertTrue(p.publishable)
                self.assertIsNone(p.occurrences[0]['subject_id'])
        self.assertEqual(map_subject('국어_공통',3).code,'korean')

    def test_all_52_frozen_individually_and_activation_refuses_before_transaction(self):
        self.assertEqual(len(IDENTITY_REVIEW_IDS),52)
        for pid in IDENTITY_REVIEW_IDS:
            p=plan(pid,'고3을 위한 공간/모의고사','국어 문제.pdf')
            self.assertFalse(p.publishable)
            with self.assertRaises(ScopeViolation):assert_in_scope([p],approved_scope([pid]))
            with self.assertRaises(ApplyAborted):resolve(p)
            s=FakeSession()
            with self.assertRaises(PublicationRefused):publish_scope(s,[pid],ScopeCounts(1,1,1,1,1))
            self.assertFalse(s.begun)

    def test_new_cross_post_exam_duplicates_are_held(self):
        result=run([raw('90001','고3을 위한 공간/모의고사','국어 문제.pdf'),
                    raw('90002','고3을 위한 공간/모의고사','영어 문제.pdf')], '2026-09-27')
        self.assertTrue(result.merge_candidates)
        self.assertTrue(all(not p.publishable for p in result.plans))

    def test_repeated_advisory_details_are_not_lost_to_duplicate_ids(self):
        source=raw()
        second=RawAttachment('cfile','second','별도 가이드.pdf',
                             'https://t1.daumcdn.net/cfile/tistory/second',False)
        source=RawPost(source.external_post_id,source.url,source.title,source.category,
                       source.published_at,None,source.attachments+(second,))
        resolved=resolve(normalize(source,'2026-09-27'))
        self.assertEqual(len(resolved.quarantine),1)
        self.assertEqual(len(json.loads(resolved.quarantine[0]['payload'])['cases']),2)

    def test_zero_exam_occurrence_activation_and_text_only(self):
        for resources in (0,3):
            session=FakeSession(scope=(1,1,0,0,resources),affected=(1,0,resources),active_after=(1,0,resources))
            self.assertEqual(publish_scope(session,['90001'],ScopeCounts(1,1,0,0,resources)),'published')
            self.assertTrue(session.committed)

if __name__=='__main__':unittest.main()
