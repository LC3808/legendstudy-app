"""Offline tests for the legendstudy.com ingestion pipeline.

No network. Fixtures keep only the minimum markup that reproduces the real
page structure; no full page HTML and no article body text is stored.
"""
from __future__ import annotations

import contextlib
import io
import json
from collections import Counter
import sys
import tempfile
import unittest
import unittest.mock
import urllib.error
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ingestion.crawler import (  # noqa: E402
    ACCEPT_HTML, ACCEPT_XML, USER_AGENT, FetchError, NetworkSource,
    PoliteFetcher, SampleSource, robots_allows, sitemap_post_ids,
)
from ingestion.models import RawAttachment, RawPost  # noqa: E402
from ingestion.normalizer import (  # noqa: E402
    ADVISORY, BLOCKING, classify, content_hash, display_title, normalize,
)
from ingestion.parser import (  # noqa: E402
    canonical_post_url, classify_attachment, normalize_post_url, parse_html,
    parse_title, split_resource_kind, split_subject, strip_query,
)
from ingestion.pipeline import next_state, run  # noqa: E402
from ingestion.subjects import (  # noqa: E402
    ALIASES, BY_CODE, DEFERRED_HISTORICAL, GRADE_SCOPED, SUBJECTS_V1,
    TAXONOMY_VERSION, map_subject, subject_id,
)
from ingestion.apply import (  # noqa: E402
    EXPECTED_SUBJECT_COUNT, ApplyAborted, apply_pilot, apply_quarantine,
    assert_no_signing_material, assert_write_shape, postflight, preflight, resolve,
    row_id,
)
from ingestion.writer import (  # noqa: E402
    PILOT_C, ApplyRefused, ScopeViolation, assert_apply_allowed, assert_in_scope,
    assert_no_collisions, expected_rows,
)
from ingest_legendstudy import (  # noqa: E402
    PILOT_C_POST_IDS, _fetch_network_posts, _network_post_ids, _report_retry,
)

CRAWLED_AT = '2026-09-15T02:00:00+00:00'
SIGNED = ('https://blog.kakaocdn.net/dna/cXNYPE/dJMcadW9IkW/AAAA/'
          '%EA%B5%AD%EC%96%B4.pdf?credential=abc&expires=1790780399'
          '&allow_ip=&allow_referer=&signature=xyz%3D&attach=1&knm=tfile.pdf')
UNSIGNED = 'https://blog.kakaocdn.net/dna/cXNYPE/dJMcadW9IkW/AAAA/%EA%B5%AD%EC%96%B4.pdf'
CFILE = 'https://t1.daumcdn.net/cfile/tistory/99B09A3E5FBF493422'
BOX = 'https://app.box.com/s/bo9z2i1qjqu4qn4ttddsrbh58ygslh1s'

MODERN_HTML = f"""<html><head>
<meta property="og:title" content="&rarr; [2026년 5월 시행] 2026년 5월 고3 모의고사 - 문제, 답">
<meta property="article:published_time" content="2026-07-24T13:54:57+09:00">
<meta property="article:modified_time" content="2026-07-24T13:54:57+09:00">
</head><body>
<a href="/category/%E2%97%86%EF%BB%BF%20%22%EA%B3%A03%22%EC%9D%84%20%EC%9C%84%ED%95%9C%20%EA%B3%B5%EA%B0%84%20/3%ED%95%99%EB%85%84%20%EB%AA%A8%EC%9D%98%EA%B3%A0%EC%82%AC%20%EC%A0%84%EA%B3%BC%EB%AA%A9%20%EC%9E%90%EB%A3%8C">cat</a>
<div class="tt_article_useless_p_margin contents_style">
<figure class="fileblock"><a href="{SIGNED}">
  <div class="image"></div>
  <div class="desc"><div class="filename"><span class="name">2026년 5월 고3_국어(언매) 정답,해설.pdf</span></div>
  <div class="size">0.30MB</div></div></a></figure>
<p><a href="{BOX}" target="_blank">2026년 5월 고3_영어 듣기파일.mp3(실시간/다운로드)</a></p>
</div></body></html>"""

LEGACY_HTML = """<html><head>
<meta property="og:title" content="&#9654; 2019 고2 9월 모의고사 한국사, 사회탐구">
<meta property="article:published_time" content="2020-11-30T10:37:06+09:00">
</head><body>
<a href="/category/%22%EA%B3%A02%22%EB%A5%BC%20%EC%9C%84%ED%95%9C%20%EA%B3%B5%EA%B0%84/2%ED%95%99%EB%85%84%20%EB%AA%A8%EC%9D%98%EA%B3%A0%EC%82%AC%20%EC%A0%84%EA%B3%BC%EB%AA%A9%20%EC%9E%90%EB%A3%8C">c</a>
<div class="tt_article_useless_p_margin contents_style">
<a href="https://t1.daumcdn.net/cfile/tistory/99B09A3E5FBF493422">2019학년도 9월 고2 모의고사 - 한국사 문제.pdf</a>
<a href="https://t1.daumcdn.net/cfile/tistory/997D304E5FBF493426">2019학년도 9월 고2 모의고사 - 한국사 정답,해설.pdf</a>
</div></body></html>"""


def raw(post_id='1705', title='→ [2026년 5월 시행] 2026년 5월 고3 모의고사',
        category='◆ "고3"을 위한 공간 /3학년 모의고사 전과목 자료', attachments=()):
    return RawPost(external_post_id=post_id, url=canonical_post_url(post_id),
                   title=title, category=category,
                   published_at='2026-07-24T13:54:57+09:00',
                   updated_at='2026-07-24T13:54:57+09:00', attachments=tuple(attachments))


def att(key, name, provider='kakaocdn', url=UNSIGNED, signed=True):
    return RawAttachment(provider, key, name, url, signed)


class UrlIdentityTests(unittest.TestCase):
    def test_signing_query_is_stripped_and_flagged(self):
        url, signed = strip_query(SIGNED)
        self.assertEqual(url, UNSIGNED)
        self.assertTrue(signed)
        for token in ('credential', 'signature', 'expires'):
            self.assertNotIn(token, url)

    def test_unsigned_url_reports_no_signing_query(self):
        self.assertEqual(strip_query(CFILE), (CFILE, False))

    def test_post_url_normalisation_is_generation_independent(self):
        for value in ('https://legendstudy.com/1705', 'https://legendstudy.com/1705/',
                      'https://legendstudy.com/m/1705', 'https://coroico.tistory.com/1705',
                      'https://www.legendstudy.com/1705/'):
            self.assertEqual(normalize_post_url(value), 'https://legendstudy.com/1705')

    def test_non_post_urls_are_rejected(self):
        self.assertIsNone(normalize_post_url('https://legendstudy.com/category/x'))
        self.assertIsNone(normalize_post_url('https://example.com/1705'))

    def test_provider_identity_is_stable_across_signature_rotation(self):
        first = classify_attachment(SIGNED, 'a.pdf', None)
        rotated = classify_attachment(SIGNED.replace('expires=1790780399', 'expires=1799999999')
                                      .replace('signature=xyz%3D', 'signature=other%3D'),
                                      'a.pdf', None)
        self.assertEqual(first.resource_key, rotated.resource_key)
        self.assertEqual(first.unsigned_url, rotated.unsigned_url)

    def test_each_provider_is_recognised(self):
        self.assertEqual(classify_attachment(SIGNED, 'a', None).provider, 'kakaocdn')
        self.assertEqual(classify_attachment(CFILE, 'a', None).provider, 'cfile')
        box = classify_attachment(BOX, 'a', None)
        self.assertEqual((box.provider, box.resource_key),
                         ('box', 'box:bo9z2i1qjqu4qn4ttddsrbh58ygslh1s'))
        self.assertIsNone(classify_attachment('https://legendstudy.com/1664', 'a', None))


class TitleParsingTests(unittest.TestCase):
    def test_administered_prefix_supplies_calendar_year(self):
        f = parse_title('→ [2026년 5월 시행] 2026년 5월 고3 모의고사', '')
        self.assertEqual((f['calendar_year'], f['administered_month'], f['nominal_month']),
                         (2026, 5, 5))
        self.assertEqual((f['grade_level'], f['exam_type']), (3, 'national_mock'))

    def test_postponed_sitting_keeps_nominal_and_administered_month(self):
        f = parse_title('→ (2023년 5월 시행) 2023년 4월 고3 모의고사 기출', '')
        self.assertEqual(f['administered_month'], 5)
        self.assertEqual(f['nominal_month'], 4)

    def test_evaluation_mock_academic_year_is_read(self):
        f = parse_title('→ [2026년 6월 시행] 2027학년도 6월 모의평가', '')
        self.assertEqual((f['calendar_year'], f['academic_year']), (2026, 2027))
        self.assertEqual(f['exam_type'], 'evaluation_mock')

    def test_csat_is_not_read_as_generic_mock(self):
        f = parse_title('→[2025년 11월 시행] 2026학년도 수능 기출', '')
        self.assertEqual(f['exam_type'], 'csat')
        self.assertEqual((f['calendar_year'], f['academic_year']), (2025, 2026))

    def test_grade_falls_back_to_category(self):
        f = parse_title('→ 2026년 6월 모의고사 기출',
                        '◆﻿ "고2"를 위한 공간 /2학년 모의고사 전과목 자료')
        self.assertEqual(f['grade_level'], 2)

    def test_short_academic_year_label(self):
        self.assertEqual(parse_title('25학년도 9월 모평', '')['academic_year'], 2025)

    def test_academic_year_is_not_read_as_calendar_year(self):
        f = parse_title('→ 2023학년도 연세대 논술 기출', '')
        self.assertIsNone(f['calendar_year'])
        self.assertEqual(f['academic_year'], 2023)

    def test_grade_and_score_numbers_are_not_months_or_years(self):
        f = parse_title('▶ 1등급 3점짜리 문제만 모은 자료', '')
        self.assertIsNone(f['calendar_year'])
        self.assertIsNone(f['nominal_month'])
        self.assertIsNone(f['grade_level'])


class FilenameParsingTests(unittest.TestCase):
    def test_combined_answer_explanation_beats_either_half(self):
        self.assertEqual(split_resource_kind('x 정답,해설.pdf')[1], 'answer_explanation')
        self.assertEqual(split_resource_kind('x 정답해설.pdf')[1], 'answer_explanation')
        self.assertEqual(split_resource_kind('x 정답.pdf')[1], 'answer')
        self.assertEqual(split_resource_kind('x 해설.pdf')[1], 'explanation')

    def test_listening_kinds(self):
        self.assertEqual(split_resource_kind('x 듣기대본.pdf')[1], 'listening_script')
        self.assertEqual(split_resource_kind('x 듣기파일.mp3')[1], 'listening_audio')

    def test_unknown_kind_returns_none(self):
        self.assertIsNone(split_resource_kind('참고자료.zip')[1])

    def test_subject_substring_false_positives(self):
        pairs = {
            '한국사 문제.pdf': ('한국사', False),
            '한국지리 문제.pdf': ('한국지리', False),
            '한국근현대사 문제.pdf': ('한국근현대사', True),
            '세계사 문제.pdf': ('세계사', False),
            '세계지리 문제.pdf': ('세계지리', False),
            '사회문화 문제.pdf': ('사회문화', False),
            '통합사회 문제.pdf': ('통합사회', False),
            '과학탐구 문제.pdf': ('과학탐구', False),
        }
        for name, expected in pairs.items():
            left, _kind, _raw = split_resource_kind(name)
            self.assertEqual(split_subject(left), expected, name)

    def test_group_prefixes_are_stripped(self):
        for name in ('2026년 5월 고3_과_물리학1 문제.pdf',
                     '2024년 10월 과탐_물리학1 문제.pdf',
                     '2012년 10월_고3 모의고사_과학탐구_ 물리학1 문제.pdf'):
            left, _kind, _raw = split_resource_kind(name)
            self.assertEqual(split_subject(left)[0], '물리학1', name)

    def test_elective_is_part_of_the_subject_label(self):
        left, _k, _r = split_resource_kind('2026년 5월 고3_국어(언매) 정답,해설.pdf')
        self.assertEqual(split_subject(left)[0], '국어(언매)')

    def test_historical_electives_are_flagged_not_modernised(self):
        left, _k, _r = split_resource_kind('2019학년도 9월 고2 - 수학 가형 정답,해설.pdf')
        self.assertEqual(split_subject(left), ('수학 가형', True))

    def test_source_typo_does_not_silently_map(self):
        for name in ('2025학년도 수능_수학(미정) 정답,해설.pdf',
                     '2024년 10월 사탐_사회문화1 문제.pdf'):
            left, _k, _r = split_resource_kind(name)
            self.assertEqual(split_subject(left), (None, False), name)

    def test_a_token_inside_a_longer_hangul_word_is_not_a_subject(self):
        # Source typo '생화활과윤리' ends with the historical subject '윤리'.
        left, _k, _r = split_resource_kind('2025학년도 6월 s_생화활과윤리 정답,해설.pdf')
        self.assertEqual(split_subject(left), (None, False))

    def test_boundary_rule_still_accepts_real_separators(self):
        for name, expected in (('2025년 10월 고1_과학 문제.pdf', '과학'),
                               ('2019학년도 9월 고2 모의고사 - 한국사 문제.pdf', '한국사'),
                               ('2012년 10월_고3_사회탐구_ 한국지리 문제.pdf', '한국지리'),
                               ('통합사회 문제.pdf', '통합사회')):
            left, _k, _r = split_resource_kind(name)
            self.assertEqual(split_subject(left)[0], expected, name)


class HtmlParsingTests(unittest.TestCase):
    def test_modern_post(self):
        post = parse_html('1705', MODERN_HTML)
        self.assertEqual(post.url, 'https://legendstudy.com/1705')
        self.assertIn('2026년 5월 고3 모의고사', post.title)
        self.assertIn('3학년 모의고사 전과목 자료', post.category)
        self.assertEqual(len(post.attachments), 2)
        first = post.attachments[0]
        self.assertEqual(first.resource_key, 'cXNYPE/dJMcadW9IkW')
        self.assertEqual(first.display_name, '2026년 5월 고3_국어(언매) 정답,해설.pdf')
        self.assertEqual(first.unsigned_url, UNSIGNED)
        self.assertTrue(first.had_signed_query)
        self.assertEqual(post.attachments[1].provider, 'box')

    def test_legacy_post_uses_anchor_text_and_unsigned_cfile_path(self):
        post = parse_html('1450', LEGACY_HTML)
        self.assertEqual(len(post.attachments), 2)
        self.assertEqual(post.attachments[0].provider, 'cfile')
        self.assertEqual(post.attachments[0].resource_key, '99B09A3E5FBF493422')
        self.assertFalse(post.attachments[0].had_signed_query)
        self.assertTrue(post.attachments[0].display_name.endswith('한국사 문제.pdf'))

    def test_repeat_parse_is_deterministic(self):
        a, b = parse_html('1705', MODERN_HTML), parse_html('1705', MODERN_HTML)
        self.assertEqual(a, b)
        self.assertEqual(content_hash(a), content_hash(b))


class ClassificationTests(unittest.TestCase):
    def test_known_categories(self):
        cases = {
            '◆ "고3"을 위한 공간 /3학년 모의고사 전과목 자료': 'exam',
            '◆ "고1"을 위한 공간/08~25년  국영수 문제': 'exam',
            '◆ 논술 기출 자료/연세대, 고려대': 'university_essay',
            '교육 입시 관련 소식': 'education_column',
            '수업 자료실': 'study_material',
            '◆ 적성고사, 면접 자료': 'study_material',
        }
        for category, expected in cases.items():
            self.assertEqual(classify(category)[0], expected, category)

    def test_missing_and_unknown_categories_quarantine(self):
        self.assertEqual(classify(None), (None, 'classification_missing_category'))
        self.assertEqual(classify('완전히 새로운 카테고리')[1], 'classification_unknown_category')

    def test_grade_space_without_exam_subcategory_is_not_an_exam(self):
        self.assertEqual(classify('◆ "고3"을 위한 공간 /독서 추천')[0], 'study_material')

    def test_display_title_drops_decorative_lead(self):
        self.assertEqual(display_title('→ [2026년] 자료'), '[2026년] 자료')
        self.assertEqual(display_title('▶ 2020 고2'), '2020 고2')


class NormalizeTests(unittest.TestCase):
    def plan(self, **kw):
        return normalize(raw(**kw), CRAWLED_AT)

    def test_exam_plan_shape(self):
        plan = self.plan(attachments=[
            att('a/b', '2026년 5월 고3_국어(언매) 문제.pdf'),
            att('a/c', '2026년 5월 고3_국어(언매) 정답,해설.pdf'),
            att('a/d', '2026년 5월 고3_영어 문제.pdf'),
        ])
        self.assertEqual(plan.content_item['slug'], 'legendstudy-1705-main')
        self.assertEqual(plan.content_item['content_type'], 'exam')
        self.assertFalse(plan.content_item['is_active'])
        self.assertEqual(plan.exam['year'], 2026)
        self.assertEqual(plan.exam['exam_month'], 5)
        self.assertEqual(plan.exam['grade_level'], 3)
        self.assertEqual(plan.exam['exam_type'], 'national_mock')
        self.assertEqual([o['source_subject_key'] for o in plan.occurrences],
                         ['국어(언매)', '영어'])
        self.assertEqual([o['display_order'] for o in plan.occurrences], [0, 1])
        self.assertEqual(plan.confidence, 'high')
        self.assertTrue(plan.publishable)

    def test_generated_columns_are_never_produced(self):
        plan = self.plan(attachments=[att('a/b', '국어 문제.pdf')])
        self.assertNotIn('sort_date', plan.exam)
        self.assertNotIn('content_type', plan.exam)
        self.assertNotIn('feed_updated_at', plan.content_item)

    def test_occurrences_start_unmapped_and_satisfy_the_mapping_check(self):
        plan = self.plan(attachments=[att('a/b', '국어 문제.pdf')])
        occ = plan.occurrences[0]
        self.assertEqual(occ['mapping_status'], 'unmapped')
        for field in ('subject_id', 'taxonomy_version', 'mapping_confidence', 'verified_at'):
            self.assertIsNone(occ[field], field)

    def test_national_mock_never_takes_the_source_academic_label(self):
        plan = normalize(raw(title='→ [2026년 7월 시행] 2026학년도 7월 고3 모의고사 기출'),
                         CRAWLED_AT)
        self.assertIsNone(plan.exam['academic_year'])
        self.assertIn('not trusted', plan.exam['normalization_note'])

    def test_evaluation_mock_keeps_the_academic_year(self):
        plan = normalize(raw(title='→ [2026년 6월 시행] 2027학년도 6월 모의평가'), CRAWLED_AT)
        self.assertEqual(plan.exam['academic_year'], 2027)

    def test_impossible_academic_year_is_quarantined(self):
        plan = normalize(raw(title='→ [2026년 6월 시행] 2019학년도 6월 모의평가'), CRAWLED_AT)
        self.assertIn('exam_academic_year_conflict', {c.kind for c in plan.quarantine})
        self.assertIsNone(plan.exam['academic_year'])

    def test_postponed_sitting_is_noted_not_dropped(self):
        plan = normalize(raw(title='→ (2023년 5월 시행) 2023년 4월 고3 모의고사'), CRAWLED_AT)
        self.assertEqual(plan.exam['exam_month'], 4)
        self.assertIn('administered month 5', plan.exam['normalization_note'])

    def test_missing_exam_field_blocks_publication(self):
        plan = normalize(raw(title='→ 고3 모의고사 자료'), CRAWLED_AT)
        self.assertIsNone(plan.exam)
        self.assertEqual(plan.confidence, 'low')
        self.assertFalse(plan.publishable)
        self.assertTrue({'exam_year_unknown', 'exam_month_unknown'}
                        <= {c.kind for c in plan.quarantine})

    def test_signed_provider_is_never_marked_a_proven_file(self):
        plan = self.plan(attachments=[att('a/b', '국어 문제.pdf')])
        res = plan.resources[0]
        self.assertEqual(res['link_kind'], 'unknown')
        self.assertEqual(res['link_status'], 'unchecked')
        self.assertIsNone(res['file_url'])
        self.assertIsNone(res['file_size'])
        self.assertIsNone(res['mime_type'])
        self.assertNotIn('credential', res['source_url'])
        self.assertIn('resource_url_expiring', {c.kind for c in plan.quarantine})

    def test_unsigned_legacy_provider_is_a_file_link(self):
        plan = self.plan(attachments=[
            RawAttachment('cfile', 'HEX1', '국어 문제.pdf', CFILE, False)])
        self.assertEqual(plan.resources[0]['link_kind'], 'file')
        self.assertNotIn('resource_url_expiring', {c.kind for c in plan.quarantine})

    def test_landing_page_provider(self):
        plan = self.plan(attachments=[
            RawAttachment('box', 'box:abc', '영어 듣기파일.mp3', BOX, False)])
        self.assertEqual(plan.resources[0]['link_kind'], 'landing_page')
        self.assertEqual(plan.resources[0]['resource_type'], 'listening_audio')

    def test_box_listening_action_suffix_maps_type_subject_and_extension(self):
        label = '2026년 6월 고2_ 영어 듣기파일.mp3 (실시간/다운로드)'
        plan = self.plan(attachments=[
            RawAttachment('box', 'box:abc', label, BOX, False)])
        resource = plan.resources[0]
        self.assertEqual(resource['resource_type'], 'listening_audio')
        self.assertEqual(resource['occurrence_subject_key'], '영어')
        self.assertEqual(resource['file_extension'], 'mp3')
        self.assertEqual(resource['title'], label)
        self.assertEqual(resource['link_kind'], 'landing_page')
        self.assertFalse({'resource_kind_unknown', 'resource_subject_unknown',
                          'resource_url_expiring'} & {c.kind for c in plan.quarantine})

    def test_expiration_advisory_is_kakaocdn_specific(self):
        box = RawAttachment('box', 'box:abc', '영어 듣기파일.mp3', BOX, False)
        other = RawAttachment('other', 'other:abc', '영어 듣기파일.mp3',
                              'https://example.com/audio', False)
        for attachment in (box, other):
            plan = self.plan(attachments=[attachment])
            self.assertNotIn('resource_url_expiring',
                             {c.kind for c in plan.quarantine})
        kakao = self.plan(attachments=[att('a/b', '영어 듣기파일.mp3')])
        self.assertIn('resource_url_expiring', {c.kind for c in kakao.quarantine})

    def test_advisory_case_does_not_lower_parse_confidence(self):
        plan = self.plan(attachments=[att('a/b', '국어 문제.pdf')])
        self.assertTrue({c.kind for c in plan.quarantine} <= ADVISORY)
        self.assertEqual(plan.confidence, 'high')

    def test_duplicate_provider_identity_is_quarantined_once(self):
        plan = self.plan(attachments=[att('a/b', '국어 문제.pdf'), att('a/b', '국어 문제.pdf')])
        self.assertEqual(len(plan.resources), 1)
        self.assertIn('resource_identity_duplicate', {c.kind for c in plan.quarantine})
        self.assertTrue(BLOCKING & {c.kind for c in plan.quarantine})
        self.assertFalse(plan.publishable)

    def test_missing_provider_identity_is_quarantined(self):
        plan = self.plan(attachments=[att('', '국어 문제.pdf')])
        self.assertEqual(plan.resources, [])
        self.assertIn('resource_identity_missing', {c.kind for c in plan.quarantine})

    def test_unknown_subject_keeps_the_resource_but_scopes_it_to_no_occurrence(self):
        plan = self.plan(attachments=[att('a/b', '수학(미정) 정답,해설.pdf')])
        self.assertEqual(plan.occurrences, [])
        self.assertIsNone(plan.resources[0]['occurrence_subject_key'])
        self.assertIn('resource_subject_unknown', {c.kind for c in plan.quarantine})

    def test_non_exam_content_creates_no_occurrence(self):
        plan = normalize(raw(title='→ 연세대] 2023학년도 수시 논술 기출',
                             category='◆ 논술 기출 자료/연세대, 고려대',
                             attachments=[att('a/b', '2023학년도 연세대 논술_수학 문제.pdf')]),
                         CRAWLED_AT)
        self.assertEqual(plan.content_item['content_type'], 'university_essay')
        self.assertIsNone(plan.exam)
        self.assertEqual(plan.occurrences, [])
        self.assertIsNone(plan.resources[0]['occurrence_subject_key'])

    def test_no_attachment_is_recorded(self):
        plan = normalize(raw(title='▶ 2026년 모의고사 일정', category='교육 입시 관련 소식'),
                         CRAWLED_AT)
        self.assertEqual(plan.content_item['content_type'], 'education_column')
        self.assertIn('attachment_none', {c.kind for c in plan.quarantine})


class ChangeAndDuplicateTests(unittest.TestCase):
    def test_identical_input_is_idempotent(self):
        posts = [raw(attachments=[att('a/b', '국어 문제.pdf')])]
        first = run(posts, CRAWLED_AT)
        state = next_state(first)
        second = run(posts, CRAWLED_AT, state)
        self.assertEqual(second.unchanged, ['1705'])
        self.assertEqual(second.changed, [])
        self.assertEqual(first.counts()['resources'], second.counts()['resources'])

    def test_a_new_answer_file_marks_the_post_changed(self):
        base = [raw(attachments=[att('a/b', '국어 문제.pdf')])]
        state = next_state(run(base, CRAWLED_AT))
        grown = [raw(attachments=[att('a/b', '국어 문제.pdf'),
                                  att('a/c', '국어 정답,해설.pdf')])]
        self.assertEqual(run(grown, CRAWLED_AT, state).changed, ['1705'])

    def test_reordered_attachments_do_not_change_the_digest(self):
        one = raw(attachments=[att('a/b', '국어 문제.pdf'), att('a/c', '영어 문제.pdf')])
        two = raw(attachments=[att('a/c', '영어 문제.pdf'), att('a/b', '국어 문제.pdf')])
        self.assertEqual(content_hash(one), content_hash(two))

    def test_a_corrected_title_marks_the_post_changed(self):
        state = next_state(run([raw()], CRAWLED_AT))
        result = run([raw(title='→ [2026년 5월 시행] 2026년 5월 고3 학력평가')], CRAWLED_AT, state)
        self.assertEqual(result.changed, ['1705'])

    def test_two_posts_for_one_exam_identity_become_a_merge_candidate(self):
        result = run([raw(post_id='1705'), raw(post_id='1706')], CRAWLED_AT)
        self.assertEqual(len(result.merge_candidates), 1)
        self.assertEqual(result.merge_candidates[0]['external_post_ids'], ['1705', '1706'])

    def test_a_vanished_source_is_flagged_never_deleted(self):
        result = run([], CRAWLED_AT, {'1705': 'deadbeef'})
        self.assertEqual(result.missing, ['1705'])
        self.assertIn('source_missing', {c.kind for c in result.quarantine})
        self.assertEqual(result.plans, [])

    def test_parser_failure_is_reported_not_swallowed(self):
        broken = RawPost('x', 'https://legendstudy.com/x', 'title', None, None, None,
                         attachments=(None,))  # type: ignore[arg-type]
        result = run([broken], CRAWLED_AT)
        self.assertEqual(len(result.parse_errors), 1)
        self.assertEqual(result.plans, [])


class CrawlerTests(unittest.TestCase):
    def test_robots_disallows_are_honoured(self):
        self.assertTrue(robots_allows('/1705'))
        self.assertTrue(robots_allows('/sitemap.xml'))
        for path in ('/search', '/m/search', '/guestbook', '/manage', '/owner', '/admin'):
            self.assertFalse(robots_allows(path), path)

    def test_fetcher_refuses_disallowed_paths_without_a_request(self):
        fetcher = PoliteFetcher(delay=0)
        with self.assertRaises(FetchError) as ctx:
            fetcher.get('https://legendstudy.com/search?q=x')
        self.assertFalse(ctx.exception.transient)
        self.assertEqual(fetcher.stats.requests, 0)

    def test_request_budget_is_enforced(self):
        fetcher = PoliteFetcher(delay=0, max_requests=0)
        with self.assertRaises(FetchError):
            fetcher.get('https://legendstudy.com/1705')

    def test_request_budget_also_bounds_retry_attempts(self):
        fetcher = PoliteFetcher(delay=0, max_retries=2, max_requests=2)
        calls = []

        def timeout(req, timeout=None):
            calls.append(req.full_url)
            raise TimeoutError()

        with unittest.mock.patch('urllib.request.urlopen', timeout), \
                unittest.mock.patch('time.sleep'):
            with self.assertRaises(FetchError) as ctx:
                fetcher.get('https://legendstudy.com/1705')
        self.assertEqual(ctx.exception.reason, 'run request budget exhausted')
        self.assertEqual(len(calls), 2)
        self.assertEqual(fetcher.stats.requests, 2)

    def test_sitemap_extraction_is_ordered_and_deduplicated(self):
        xml = ('<loc>https://legendstudy.com/12</loc>'
               '<loc>https://legendstudy.com/1709</loc>'
               '<loc>https://legendstudy.com/category/x</loc>'
               '<loc>https://legendstudy.com/12</loc>'
               '<loc>https://legendstudy.com/notice/5</loc>')
        self.assertEqual(sitemap_post_ids(xml), [1709, 12])

    def test_timeout_and_retries_are_bounded_and_reported(self):
        retries = []
        timeouts = []
        fetcher = PoliteFetcher(delay=0, timeout=7, max_retries=2,
                                on_retry=lambda *event: retries.append(event))

        def timeout(req, timeout=None):
            timeouts.append(timeout)
            raise TimeoutError()

        with unittest.mock.patch('urllib.request.urlopen', timeout), \
                unittest.mock.patch('time.sleep'):
            with self.assertRaises(FetchError) as ctx:
                fetcher.get('https://legendstudy.com/1705', request_label='1705')
        self.assertEqual(ctx.exception.reason, 'TimeoutError')
        self.assertEqual(timeouts, [7, 7, 7])
        self.assertEqual(retries, [
            ('1705', 2, 'TimeoutError'),
            ('1705', 3, 'TimeoutError'),
        ])
        self.assertEqual(fetcher.stats.requests, 3)
        self.assertEqual(fetcher.stats.retries, 2)
        self.assertEqual(fetcher.stats.failures, 1)

    def test_pilot_network_selection_is_the_approved_23_posts(self):
        sitemap_ids = [9999, *PILOT_C_POST_IDS, 1]
        self.assertEqual(_network_post_ids(sitemap_ids, 'c', None),
                         list(PILOT_C_POST_IDS))
        self.assertEqual(_network_post_ids(sitemap_ids, 'c', 2), [1709, 1708])

    def test_pilot_network_selection_fails_if_an_approved_post_is_missing(self):
        with self.assertRaisesRegex(ValueError, 'missing 1 approved posts'):
            _network_post_ids(list(PILOT_C_POST_IDS[:-1]), 'c', None)

    def test_network_progress_is_flushed_without_urls_or_response_bodies(self):
        class Source:
            def post(self, post_id):
                return raw(post_id=str(post_id), attachments=[
                    att(f'key/{post_id}', '국어 문제.pdf'),
                ])

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            posts, failures = _fetch_network_posts(Source(), [1709, 1708])
        text = output.getvalue()
        self.assertEqual(len(posts), 2)
        self.assertEqual(failures, 0)
        self.assertIn('INGEST fetch 1/2 post=1709', text)
        self.assertIn('INGEST done 2/2 post=1708', text)
        self.assertIn('attachments=1', text)
        self.assertNotIn('https://', text)
        self.assertNotIn('credential=', text)

    def test_retry_diagnostic_contains_only_safe_request_context(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            _report_retry('1705', 2, 'HTTP 503')
        self.assertEqual(output.getvalue(),
                         'INGEST retry post=1705 attempt=2 status=503\n')


class SampleAndArtifactTests(unittest.TestCase):
    SAMPLES = Path(__file__).resolve().parent / 'ingestion/samples'

    def test_committed_samples_parse(self):
        posts = SampleSource(self.SAMPLES / 'day9b_exam_posts.jsonl').posts()
        self.assertGreaterEqual(len(posts), 30)
        self.assertTrue(all(p.attachments for p in posts))
        result = run(posts, CRAWLED_AT)
        self.assertEqual(result.parse_errors, [])
        self.assertEqual(result.counts()['content_types'], {'exam': len(posts)})

    def test_committed_samples_are_deterministic(self):
        posts = SampleSource(self.SAMPLES / 'day9b_exam_posts.jsonl').posts()
        first, second = run(posts, CRAWLED_AT), run(posts, CRAWLED_AT)
        self.assertEqual(first.counts(), second.counts())

    def test_samples_contain_no_signing_material(self):
        for path in self.SAMPLES.glob('*.jsonl'):
            text = path.read_text(encoding='utf-8')
            for token in ('credential=', 'signature=', 'expires=', 'Bearer ',
                          'service_role', 'apikey'):
                self.assertNotIn(token, text, f'{path.name} contains {token}')

    def test_artifacts_never_carry_a_signed_url(self):
        from ingest_legendstudy import write_artifacts
        posts = [raw(attachments=[att('a/b', '국어 문제.pdf')])]
        with tempfile.TemporaryDirectory() as tmp:
            written = write_artifacts(run(posts, CRAWLED_AT), Path(tmp), CRAWLED_AT)
            self.assertTrue(written)
            for path in written:
                body = path.read_text(encoding='utf-8')
                for token in ('credential=', 'signature=', 'expires='):
                    self.assertNotIn(token, body, f'{path.name} contains {token}')
            summary = json.loads((Path(tmp) / 'dryrun-summary.json').read_text())
            self.assertIn('counts', summary)


class ApplyGateTests(unittest.TestCase):
    def test_wrong_project_missing_approval_and_sample_source_all_refuse(self):
        for ref, approved, live in ((None, False, True), ('other', True, True),
                                    ('muselry', True, True),
                                    ('stlhijzpjfgwwdgunlsd', False, True),
                                    ('stlhijzpjfgwwdgunlsd', True, False)):
            with self.assertRaises(ApplyRefused):
                assert_apply_allowed(ref, approved, live)

    def test_project_ref_is_checked_before_anything_else(self):
        with self.assertRaises(ApplyRefused) as ctx:
            assert_apply_allowed('muselry-ref', False, False)
        self.assertIn('is not the LegendStudy project', str(ctx.exception))

    def test_all_gates_satisfied_returns(self):
        self.assertIsNone(
            assert_apply_allowed('stlhijzpjfgwwdgunlsd', True, True))

    def test_wrong_project_is_named_in_the_refusal(self):
        with self.assertRaises(ApplyRefused) as ctx:
            assert_apply_allowed('muselry-project-ref', True)
        self.assertIn('stlhijzpjfgwwdgunlsd', str(ctx.exception))




class TaxonomyTests(unittest.TestCase):
    def test_row_shape_matches_the_subjects_check_constraints(self):
        for s in SUBJECTS_V1:
            self.assertRegex(s.code, r'^[a-z0-9]+(_[a-z0-9]+)*$', s.code)
            self.assertTrue(s.name.strip(), s.code)
            self.assertGreaterEqual(s.sort_order, 0)
            self.assertTrue(TAXONOMY_VERSION.strip())

    def test_codes_ids_names_and_sort_orders_are_unique(self):
        for attr in ('code', 'name', 'sort_order'):
            values = [getattr(s, attr) for s in SUBJECTS_V1]
            self.assertEqual(len(values), len(set(values)), attr)
        self.assertEqual(len({s.id for s in SUBJECTS_V1}), len(SUBJECTS_V1))

    def test_subject_id_is_deterministic_and_version_scoped(self):
        self.assertEqual(subject_id('korean'), subject_id('korean'))
        self.assertNotEqual(subject_id('korean'), subject_id('math'))
        self.assertNotEqual(subject_id('korean', 'v1'), subject_id('korean', 'v2'))
        self.assertEqual(subject_id('korean'), '9ae14424-dad0-593c-bf7e-96dca10e719f')

    def test_every_alias_target_exists(self):
        for raw, (code, _c, _n) in ALIASES.items():
            self.assertIn(code, BY_CODE, raw)
        for raw, per_grade in GRADE_SCOPED.items():
            for code, _c, _n in per_grade.values():
                self.assertIn(code, BY_CODE, raw)

    def test_selection_subjects_resolve_to_their_area(self):
        for raw in ('국어(화작)', '국어(언매)', '국어(공통)'):
            self.assertEqual(map_subject(raw, 3).code, 'korean', raw)
        for raw in ('수학(확통)', '수학(미적)', '수학(기하)', '수학(공통)'):
            self.assertEqual(map_subject(raw, 3).code, 'math', raw)

    def test_social_and_science_details_stay_distinct(self):
        pairs = {'생활과윤리': 'life_ethics', '윤리와사상': 'ethics_thought',
                 '한국지리': 'korean_geography', '세계지리': 'world_geography',
                 '동아시아사': 'east_asian_history', '세계사': 'world_history',
                 '경제': 'economics', '정치와법': 'politics_law',
                 '사회문화': 'society_culture', '물리학1': 'physics_1',
                 '물리학2': 'physics_2', '화학1': 'chemistry_1',
                 '생명과학2': 'life_science_2', '지구과학1': 'earth_science_1'}
        for raw, code in pairs.items():
            self.assertEqual(map_subject(raw, 3).code, code, raw)
        self.assertEqual(len({map_subject(r, 3).code for r in pairs}), len(set(pairs.values())))

    def test_grade_scoped_tokens_need_a_grade(self):
        self.assertEqual(map_subject('사회', 1).code, 'integrated_social')
        self.assertEqual(map_subject('과학탐구', 1).code, 'integrated_science')
        self.assertEqual(map_subject('물리학', 2).code, 'physics_1')
        for raw in ('사회', '물리학'):
            self.assertIsNone(map_subject(raw, None).code, raw)
            self.assertEqual(map_subject(raw, None).status, 'unmapped')
        self.assertIsNone(map_subject('물리학', 3).code)

    def test_historical_labels_are_deferred_not_mapped(self):
        for raw in DEFERRED_HISTORICAL:
            mapping = map_subject(raw, 3)
            self.assertEqual(mapping.status, 'unmapped', raw)
            self.assertIsNone(mapping.code, raw)
            self.assertIn('historical', mapping.reason)

    def test_unknown_label_is_never_forced(self):
        mapping = map_subject('수학(미정)', 3)
        self.assertEqual(mapping.status, 'unmapped')
        self.assertEqual(mapping.reason, 'no rule for this raw label')

    def test_automated_mapping_never_produces_verified(self):
        for raw in list(ALIASES) + list(GRADE_SCOPED) + ['알수없는과목']:
            for grade in (None, 1, 2, 3):
                self.assertNotEqual(map_subject(raw, grade).status, 'verified')


class TaxonomyIngestionTests(unittest.TestCase):
    def plan(self, raw_names, grade_title='→ [2026년 5월 시행] 2026년 5월 고3 모의고사'):
        return normalize(raw(title=grade_title,
                             attachments=[att(f'k/{i}', n) for i, n in enumerate(raw_names)]),
                         CRAWLED_AT, map_subjects=True)

    def test_default_is_still_unmapped(self):
        plan = normalize(raw(attachments=[att('a/b', '국어 문제.pdf')]), CRAWLED_AT)
        self.assertEqual(plan.occurrences[0]['mapping_status'], 'unmapped')
        self.assertIsNone(plan.occurrences[0]['subject_id'])

    def test_provisional_row_satisfies_the_mapping_state_check(self):
        occ = self.plan(['국어 문제.pdf']).occurrences[0]
        self.assertEqual(occ['mapping_status'], 'provisional')
        self.assertIsNotNone(occ['subject_id'])
        self.assertEqual(occ['taxonomy_version'], TAXONOMY_VERSION)
        self.assertIsNotNone(occ['mapping_confidence'])
        self.assertIsNone(occ['verified_at'])
        self.assertGreaterEqual(occ['mapping_confidence'], 0)
        self.assertLessEqual(occ['mapping_confidence'], 1)

    def test_raw_label_and_source_key_survive_mapping(self):
        occ = self.plan(['2026년 5월 고3_국어(언매) 정답,해설.pdf']).occurrences[0]
        self.assertEqual(occ['source_subject_key'], '국어(언매)')
        self.assertEqual(occ['raw_subject_label'], '국어(언매)')
        self.assertEqual(occ['subject_code'], 'korean')

    def test_two_electives_stay_two_occurrences_under_one_subject(self):
        plan = self.plan(['국어(화작) 문제.pdf', '국어(언매) 문제.pdf'])
        self.assertEqual(len(plan.occurrences), 2)
        self.assertEqual({o['subject_code'] for o in plan.occurrences}, {'korean'})
        self.assertEqual(len({o['source_subject_key'] for o in plan.occurrences}), 2)

    def test_unmappable_label_records_a_taxonomy_gap(self):
        plan = self.plan(['국어 문제.pdf', '알수없는것 문제.pdf'])
        self.assertIn('resource_subject_unknown', {c.kind for c in plan.quarantine})

    def test_grade_context_comes_from_the_parsed_exam(self):
        plan = self.plan(['사회 문제.pdf'], '→ 2026년 3월 고1 모의고사')
        self.assertEqual(plan.occurrences[0]['subject_code'], 'integrated_social')

    def test_mapping_is_deterministic_across_runs(self):
        a, b = self.plan(['국어 문제.pdf', '물리학1 문제.pdf']), self.plan(['국어 문제.pdf', '물리학1 문제.pdf'])
        self.assertEqual([o['subject_id'] for o in a.occurrences],
                         [o['subject_id'] for o in b.occurrences])


class PilotScopeTests(unittest.TestCase):
    SAMPLES = Path(__file__).resolve().parent / 'ingestion/samples'

    def pilot(self):
        posts = SampleSource(self.SAMPLES / 'day9b_exam_posts.jsonl').posts()
        result = run(posts, CRAWLED_AT, map_subjects=True)
        return result, [p for p in result.plans if p.exam and p.exam['year'] >= 2025]

    def test_pilot_c_mapping_coverage_is_total(self):
        _result, pilot = self.pilot()
        occurrences = [o for p in pilot for o in p.occurrences]
        self.assertEqual(len(occurrences), 363)
        self.assertEqual({o['mapping_status'] for o in occurrences}, {'provisional'})
        self.assertEqual(len({o['subject_code'] for o in occurrences}), len(SUBJECTS_V1))

    def test_pilot_c_expected_row_counts(self):
        _result, pilot = self.pilot()
        self.assertEqual(expected_rows(pilot), {
            'source_posts': 23, 'content_items': 23, 'exams': 23,
            'exam_subjects': 363, 'resources': 739})

    def test_pilot_c_box_resources_are_one_english_audio_per_post(self):
        result, pilot = self.pilot()
        boxes = [[r for r in plan.resources if r['provider'] == 'box']
                 for plan in pilot]
        self.assertTrue(all(len(rows) == 1 for rows in boxes))
        self.assertTrue(all(rows[0]['resource_type'] == 'listening_audio'
                            and rows[0]['occurrence_subject_key'] == '영어'
                            and rows[0]['link_kind'] == 'landing_page'
                            for rows in boxes))
        keys = [rows[0]['source_resource_key'] for rows in boxes]
        urls = [rows[0]['source_url'] for rows in boxes]
        self.assertEqual(len(set(keys)), 23)
        self.assertTrue(all(key.startswith('box:') for key in keys))
        self.assertTrue(all(url.startswith('https://app.box.com/s/')
                            and '?' not in url and '#' not in url for url in urls))
        self.assertEqual(result.counts()['providers']['box'], 23)
        self.assertEqual(result.counts()['resource_types']['listening_audio'], 23)
        self.assertEqual({c.kind for p in pilot for c in p.quarantine},
                         {'resource_url_expiring'})

    def test_pilot_c_passes_the_scope_and_collision_guards(self):
        _result, pilot = self.pilot()
        assert_in_scope(pilot, PILOT_C)
        assert_no_collisions(pilot)

    def test_out_of_scope_year_is_refused(self):
        result, _pilot = self.pilot()
        with self.assertRaises(ScopeViolation):
            assert_in_scope(result.plans, PILOT_C)

    def test_active_row_is_refused(self):
        _result, pilot = self.pilot()
        pilot[0].content_item['is_active'] = True
        try:
            with self.assertRaises(ScopeViolation):
                assert_in_scope(pilot, PILOT_C)
        finally:
            pilot[0].content_item['is_active'] = False

    def test_verified_mapping_is_refused(self):
        _result, pilot = self.pilot()
        pilot[0].occurrences[0]['mapping_status'] = 'verified'
        with self.assertRaises(ScopeViolation):
            assert_in_scope(pilot, PILOT_C)

    def test_duplicate_upsert_key_is_refused(self):
        _result, pilot = self.pilot()
        with self.assertRaises(ScopeViolation):
            assert_no_collisions(pilot + [pilot[0]])


class SeedPackageTests(unittest.TestCase):
    SEED = Path(__file__).resolve().parent.parent / 'supabase/seed/subjects_taxonomy_v1.sql'

    def test_seed_file_is_current_and_idempotent_by_construction(self):
        from ingest_legendstudy import cmd_emit_seed
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'seed.sql'
            cmd_emit_seed(out)
            self.assertEqual(out.read_text(encoding='utf-8'),
                             self.SEED.read_text(encoding='utf-8'),
                             'committed seed is stale; re-run --emit-subjects-seed')
            body = out.read_text(encoding='utf-8')
        self.assertIn('on conflict (taxonomy_version, code) do nothing', body)
        self.assertNotIn('update', body.lower().replace('updated_at', ''))
        self.assertNotIn('delete', body.lower())
        for s in SUBJECTS_V1:
            self.assertIn(s.id, body, s.code)
            self.assertIn(f"'{s.code}'", body)

    def test_seed_declares_every_row_active_and_parentless(self):
        body = self.SEED.read_text(encoding='utf-8')
        self.assertEqual(body.count(', null, true, '), len(SUBJECTS_V1))




class RequestHeaderTests(unittest.TestCase):
    """The live smoke returned HTTP 406 for sitemap.xml. These pin the fix."""

    def capture(self, fetch):
        seen = {}

        class FakeResponse:
            def __enter__(self_inner):
                return self_inner

            def __exit__(self_inner, *exc):
                return False

            def read(self_inner):
                return b'<urlset></urlset>'

        def fake_urlopen(req, timeout=None):
            seen['url'] = req.full_url
            seen['headers'] = {k.lower(): v for k, v in req.header_items()}
            return FakeResponse()

        with unittest.mock.patch('urllib.request.urlopen', fake_urlopen):
            fetch()
        return seen

    def test_user_agent_is_a_single_comment_crawler_token(self):
        self.assertEqual(USER_AGENT, 'LegendStudyIngest/0.1 (+https://legendstudy.com)')
        self.assertNotIn(';', USER_AGENT)
        self.assertEqual(USER_AGENT.count('('), 1)
        self.assertEqual(USER_AGENT.count(')'), 1)
        self.assertRegex(USER_AGENT, r'^[\w.-]+/[\d.]+ \(\+https://[^\s()]+\)$')

    def test_accept_headers_cover_the_served_type_and_end_in_a_wildcard(self):
        for accept in (ACCEPT_HTML, ACCEPT_XML):
            self.assertIn('text/xml', accept)
            self.assertIn('application/xml', accept)
            self.assertIn('text/html', accept)
            self.assertIn('*/*', accept)
        # the sitemap header must prefer XML over HTML
        self.assertLess(ACCEPT_XML.index('application/xml'), ACCEPT_XML.index('text/html'))
        self.assertLess(ACCEPT_HTML.index('text/html'), ACCEPT_HTML.index('*/*'))

    def test_sitemap_request_sends_the_xml_accept_header(self):
        fetcher = PoliteFetcher(delay=0)
        seen = self.capture(lambda: NetworkSource(fetcher).post_ids())
        self.assertTrue(seen['url'].endswith('/sitemap.xml'))
        self.assertEqual(seen['headers']['accept'], ACCEPT_XML)
        self.assertEqual(seen['headers']['user-agent'], USER_AGENT)
        self.assertEqual(seen['headers']['accept-encoding'], 'identity')
        self.assertEqual(seen['headers']['accept-language'], 'ko,en;q=0.8')

    def test_post_request_sends_the_html_accept_header(self):
        fetcher = PoliteFetcher(delay=0)
        seen = self.capture(lambda: fetcher.get('https://legendstudy.com/1705'))
        self.assertEqual(seen['headers']['accept'], ACCEPT_HTML)
        self.assertEqual(seen['headers']['user-agent'], USER_AGENT)

    def test_406_is_reported_as_non_transient_and_not_retried(self):
        fetcher = PoliteFetcher(delay=0, max_retries=3)

        def fake_urlopen(req, timeout=None):
            raise urllib.error.HTTPError(req.full_url, 406, 'Not Acceptable', {}, None)

        with unittest.mock.patch('urllib.request.urlopen', fake_urlopen):
            with self.assertRaises(FetchError) as ctx:
                fetcher.get('https://legendstudy.com/sitemap.xml', accept=ACCEPT_XML)
        self.assertIn('HTTP 406', str(ctx.exception))
        self.assertFalse(ctx.exception.transient)
        self.assertEqual(fetcher.stats.requests, 1)
        self.assertEqual(fetcher.stats.retries, 0)

    def test_header_change_did_not_weaken_robots_or_the_budget(self):
        fetcher = PoliteFetcher(delay=0)
        with self.assertRaises(FetchError):
            fetcher.get('https://legendstudy.com/search?q=x', accept=ACCEPT_XML)
        self.assertEqual(fetcher.stats.requests, 0)
        budgeted = PoliteFetcher(delay=0, max_requests=0)
        with self.assertRaises(FetchError):
            budgeted.get('https://legendstudy.com/sitemap.xml', accept=ACCEPT_XML)




class FakeDb:
    """In-memory stand-in for the production database.

    Only the statement shapes the writer actually issues are recognised;
    anything else raises, so a future query change fails loudly here instead of
    silently returning the wrong answer. No production database is contacted.
    """

    UNIQUE = {
        'source_posts': (('source', 'external_post_id'),),
        'content_items': (('source_post_id', 'source_content_key'), ('slug',)),
        'exams': (),
        'exam_subjects': (('content_item_id', 'source_subject_key'),),
        'resources': (('content_item_id', 'source_post_id', 'source_resource_key'),),
        'ingestion_quarantine': (),
    }
    PK = {'source_posts': 'id', 'content_items': 'id', 'exams': 'content_item_id',
          'exam_subjects': 'id', 'resources': 'id', 'ingestion_quarantine': 'id'}

    def __init__(self, subjects=None, fail_on=None):
        self.tables = {name: {} for name in self.PK}
        self.subjects = {s.id: s for s in (subjects if subjects is not None else SUBJECTS_V1)}
        self.log: list[str] = []
        self.pending: dict | None = None
        self.fail_on = fail_on
        self.committed = 0

    # -- transaction
    def begin(self):
        self.log.append('BEGIN')
        self.pending = {name: dict(rows) for name, rows in self.tables.items()}

    def commit(self):
        self.log.append('COMMIT')
        if self.pending is not None:
            self.tables = self.pending
            self.pending = None
        self.committed += 1

    def rollback(self):
        self.log.append('ROLLBACK')
        self.pending = None

    @property
    def _live(self):
        return self.pending if self.pending is not None else self.tables

    # -- execute
    def execute(self, statement, params=()):
        text = ' '.join(statement.split())
        if text.lower().startswith(('update ', 'delete ')):
            raise AssertionError(f'writer must never issue: {text[:60]}')
        if text.startswith('insert into public.'):
            return self._insert(text, params)
        return self._select(text, params)

    def _insert(self, text, params):
        table = text.split('insert into public.', 1)[1].split(' ', 1)[0]
        columns = [c.strip() for c in
                   text.split('(', 1)[1].split(')', 1)[0].split(',')]
        row = dict(zip(columns, params))
        self.log.append(f'INSERT {table}')
        if self.fail_on == table:
            raise RuntimeError(f'simulated failure inserting {table}')
        rows = self._live[table]
        key = row[self.PK[table]]
        if key in rows:
            return []
        for unique in self.UNIQUE[table]:
            signature = tuple(row.get(c) for c in unique)
            if any(tuple(existing.get(c) for c in unique) == signature
                   for existing in rows.values()):
                return []
        rows[key] = row
        return [(1,)]

    def _select(self, text, params):
        live = self._live
        if 'from public.subjects where taxonomy_version' in text and 'id::text' in text:
            wanted = set(params[1])
            return [(sid,) for sid in self.subjects if sid in wanted]
        if 'count(*) from public.subjects where taxonomy_version' in text:
            return [(len(self.subjects),)]
        if 'from public.source_posts where source' in text:
            wanted = set(params[1])
            return [(sum(1 for r in live['source_posts'].values()
                         if r['source'] == params[0] and r['external_post_id'] in wanted),)]
        if 'from public.content_items where slug = any' in text:
            wanted = set(params[0])
            return [(sum(1 for r in live['content_items'].values()
                         if r['slug'] in wanted),)]
        if 'from public.exam_subjects where mapping_status = %s and content_item_id' in text:
            wanted = set(params[1])
            return [(sum(1 for r in live['exam_subjects'].values()
                         if r['mapping_status'] == params[0]
                         and r['content_item_id'] in wanted),)]
        if "where mapping_status = 'verified'" in text:
            return [(sum(1 for r in live['exam_subjects'].values()
                         if r['mapping_status'] == 'verified'),)]
        if 'ilike' in text and 'public.resources' in text:
            signed = sum(
                1 for r in live['resources'].values()
                if any(t in (r.get('source_url') or '')
                       for t in ('credential=', 'signature=', 'expires=')))
            return [(signed,)]
        if 'where is_active' in text:
            table = text.split('from public.', 1)[1].split(' ', 1)[0]
            return [(sum(1 for r in live[table].values() if r.get('is_active')),)]
        if text.startswith('select count(*) from public.'):
            table = text.split('from public.', 1)[1].strip()
            if table == 'subjects':
                return [(len(self.subjects),)]
            return [(len(live[table]),)]
        raise AssertionError(f'FakeDb does not recognise: {text[:90]}')


class ApplyWriterTests(unittest.TestCase):
    SAMPLES = Path(__file__).resolve().parent / 'ingestion/samples'

    @classmethod
    def setUpClass(cls):
        posts = SampleSource(cls.SAMPLES / 'day9b_exam_posts.jsonl').posts()
        result = run(posts, CRAWLED_AT, map_subjects=True)
        cls.plans = [p for p in result.plans if p.exam and p.exam['year'] >= 2025]
        cls.quarantine = [c for c in result.quarantine
                          if c.external_post_id in {p.external_post_id for p in cls.plans}]

    def resolved(self):
        return [resolve(plan) for plan in self.plans]

    def expected(self):
        return expected_rows(self.plans)

    # -- identity
    def test_row_ids_are_deterministic(self):
        first, second = self.resolved(), self.resolved()
        self.assertEqual([p.source_post['id'] for p in first],
                         [p.source_post['id'] for p in second])
        self.assertEqual([r['id'] for p in first for r in p.resources],
                         [r['id'] for p in second for r in p.resources])

    def test_row_ids_are_unique_within_the_pilot(self):
        posts = self.resolved()
        for label, ids in (
            ('source_posts', [p.source_post['id'] for p in posts]),
            ('content_items', [p.content_item['id'] for p in posts]),
            ('exam_subjects', [o['id'] for p in posts for o in p.occurrences]),
            ('resources', [r['id'] for p in posts for r in p.resources]),
            ('quarantine', [q['id'] for p in posts for q in p.quarantine]),
        ):
            self.assertEqual(len(ids), len(set(ids)), label)

    def test_exam_shares_the_content_item_primary_key(self):
        for post in self.resolved():
            self.assertEqual(post.exam['content_item_id'], post.content_item['id'])

    def test_planning_only_fields_are_never_sent(self):
        post = self.resolved()[0]
        for key in ('subject_code', 'mapping_reason', 'historical'):
            self.assertNotIn(key, post.occurrences[0])
        for key in ('provider', 'occurrence_subject_key', 'source_post_external_id',
                    'raw_kind_label'):
            self.assertNotIn(key, post.resources[0])
        for key in ('sort_date', 'content_type'):
            self.assertNotIn(key, post.exam)
        self.assertNotIn('feed_updated_at', post.content_item)

    # -- invariants
    def test_no_signed_url_is_ever_persisted(self):
        posts = self.resolved()
        assert_no_signing_material(posts)
        posts[0].resources[0]['source_url'] += '?credential=abc&signature=x'
        with self.assertRaises(ApplyAborted):
            assert_no_signing_material(posts)

    def test_active_row_is_refused(self):
        posts = self.resolved()
        posts[0].content_item['is_active'] = True
        with self.assertRaises(ApplyAborted):
            assert_write_shape(posts)

    def test_verified_mapping_is_refused(self):
        posts = self.resolved()
        posts[0].occurrences[0]['mapping_status'] = 'verified'
        with self.assertRaises(ApplyAborted):
            assert_write_shape(posts)

    def test_claiming_a_verified_file_is_refused(self):
        posts = self.resolved()
        posts[0].resources[0]['file_url'] = 'https://example.com/a.pdf'
        with self.assertRaises(ApplyAborted):
            assert_write_shape(posts)

    def test_box_listening_resources_are_landing_pages(self):
        listening = [r for p in self.resolved() for r in p.resources
                     if r['resource_type'] == 'listening_audio']
        self.assertEqual(len(listening), 23)
        for row in listening:
            self.assertEqual(row['link_kind'], 'landing_page')
            self.assertIn('box.com', row['source_url'])
            self.assertIsNotNone(row['exam_subject_id'])

    def test_kakaocdn_resources_stay_unknown_and_unchecked(self):
        rows = [r for p in self.resolved() for r in p.resources
                if 'kakaocdn' in r['source_url']]
        self.assertEqual(len(rows), 716)
        for row in rows:
            self.assertEqual((row['link_kind'], row['link_status']), ('unknown', 'unchecked'))
            self.assertIsNone(row['file_url'])

class ApplyTransactionTests(unittest.TestCase):
    SAMPLES = Path(__file__).resolve().parent / 'ingestion/samples'

    @classmethod
    def setUpClass(cls):
        posts = SampleSource(cls.SAMPLES / 'day9b_exam_posts.jsonl').posts()
        result = run(posts, CRAWLED_AT, map_subjects=True)
        cls.plans = [p for p in result.plans if p.exam and p.exam['year'] >= 2025]

    def setUp(self):
        self.posts = [resolve(plan) for plan in self.plans]
        self.expected = expected_rows(self.plans)

    def apply_all(self, db):
        preflight(db, self.posts, 0)
        inserted = apply_pilot(db, self.posts, self.expected)
        quarantined = apply_quarantine(db, self.posts)
        return inserted, quarantined

    def test_expected_pilot_rows(self):
        self.assertEqual(self.expected, {
            'source_posts': 23, 'content_items': 23, 'exams': 23,
            'exam_subjects': 363, 'resources': 739})

    def test_full_apply_produces_the_expected_delta(self):
        db = FakeDb()
        inserted, quarantined = self.apply_all(db)
        self.assertEqual(inserted, self.expected)
        self.assertEqual(quarantined, 23)
        counts = postflight(db)
        self.assertEqual(counts['source_posts'], 23)
        self.assertEqual(counts['content_items'], 23)
        self.assertEqual(counts['exams'], 23)
        self.assertEqual(counts['subjects'], EXPECTED_SUBJECT_COUNT)
        self.assertEqual(counts['exam_subjects'], 363)
        self.assertEqual(counts['resources'], 739)
        self.assertEqual(counts['ingestion_quarantine'], 23)
        for key in ('active_content_items', 'active_exam_subjects', 'active_resources',
                    'verified_exam_subjects', 'signed_resource_urls'):
            self.assertEqual(counts[key], 0, key)

    def test_resource_type_breakdown(self):
        rows = [r for p in self.posts for r in p.resources]
        self.assertEqual(Counter(r['resource_type'] for r in rows),
                         Counter({'question': 360, 'answer_explanation': 356,
                                  'listening_audio': 23}))

    def test_every_occurrence_is_provisional_against_taxonomy_v1(self):
        rows = [o for p in self.posts for o in p.occurrences]
        self.assertEqual(len(rows), 363)
        self.assertEqual({o['mapping_status'] for o in rows}, {'provisional'})
        self.assertEqual({o['taxonomy_version'] for o in rows}, {TAXONOMY_VERSION})
        self.assertEqual(Counter(o['mapping_confidence'] for o in rows),
                         Counter({0.95: 203, 1.0: 160}))
        self.assertTrue(all(o['raw_subject_label'] and o['source_subject_key'] for o in rows))
        self.assertTrue(all(o['verified_at'] is None for o in rows))

    def test_insert_order_follows_the_foreign_keys(self):
        db = FakeDb()
        self.apply_all(db)
        order = [line.split(' ', 1)[1] for line in db.log if line.startswith('INSERT ')]
        first_seen = []
        for table in order:
            if table not in first_seen:
                first_seen.append(table)
        self.assertEqual(first_seen, ['source_posts', 'content_items', 'exams',
                                      'exam_subjects', 'resources',
                                      'ingestion_quarantine'])

    def test_quarantine_commits_in_its_own_transaction(self):
        db = FakeDb()
        self.apply_all(db)
        self.assertEqual(db.committed, 2)
        commit_positions = [i for i, line in enumerate(db.log) if line == 'COMMIT']
        first_quarantine = db.log.index('INSERT ingestion_quarantine')
        self.assertLess(commit_positions[0], first_quarantine)

    def test_second_apply_is_a_no_op(self):
        db = FakeDb()
        self.apply_all(db)
        checks = preflight(db, self.posts, 0)
        self.assertTrue(checks.already_applied)
        self.assertEqual(checks.existing_posts, 23)
        again = apply_pilot(db, self.posts, {k: 0 for k in self.expected})
        self.assertEqual(again, {k: 0 for k in self.expected})
        self.assertEqual(postflight(db)['resources'], 739)

    def test_quarantine_is_idempotent(self):
        db = FakeDb()
        self.apply_all(db)
        self.assertEqual(apply_quarantine(db, self.posts), 0)
        self.assertEqual(postflight(db)['ingestion_quarantine'], 23)

    def test_count_mismatch_rolls_the_whole_pilot_back(self):
        db = FakeDb()
        wrong = dict(self.expected, resources=999)
        with self.assertRaises(ApplyAborted):
            apply_pilot(db, self.posts, wrong)
        self.assertEqual(db.log[-1], 'ROLLBACK')
        self.assertEqual(postflight(db)['source_posts'], 0)
        self.assertEqual(postflight(db)['resources'], 0)

    def test_a_failure_mid_write_leaves_nothing_behind(self):
        db = FakeDb(fail_on='resources')
        with self.assertRaises(RuntimeError):
            apply_pilot(db, self.posts, self.expected)
        self.assertEqual(db.log[-1], 'ROLLBACK')
        counts = postflight(db)
        for table in ('source_posts', 'content_items', 'exams', 'exam_subjects',
                      'resources'):
            self.assertEqual(counts[table], 0, table)

    def test_missing_taxonomy_refuses_before_any_write(self):
        db = FakeDb(subjects=SUBJECTS_V1[:5])
        with self.assertRaises(ApplyAborted) as ctx:
            preflight(db, self.posts, 0)
        self.assertIn('subjects_taxonomy_v1.sql', str(ctx.exception))
        self.assertNotIn('BEGIN', db.log)

    def test_blocking_quarantine_refuses(self):
        db = FakeDb()
        with self.assertRaises(ApplyAborted) as ctx:
            preflight(db, self.posts, 1)
        self.assertIn('blocking quarantine', str(ctx.exception))

    def test_partial_pilot_state_fails_closed(self):
        db = FakeDb()
        subset = self.posts[:5]
        preflight(db, subset, 0)
        apply_pilot(db, subset, expected_rows(self.plans[:5]))
        with self.assertRaises(ApplyAborted) as ctx:
            preflight(db, self.posts, 0)
        self.assertIn('partial pilot state', str(ctx.exception))

    def test_existing_verified_mapping_refuses(self):
        db = FakeDb()
        self.apply_all(db)
        target = next(iter(db.tables['exam_subjects'].values()))
        target['mapping_status'] = 'verified'
        with self.assertRaises(ApplyAborted) as ctx:
            preflight(db, self.posts, 0)
        self.assertIn('verified', str(ctx.exception))

    def test_writer_never_issues_update_or_delete(self):
        db = FakeDb()
        self.apply_all(db)
        postflight(db)
        self.assertTrue(all(not line.startswith(('UPDATE', 'DELETE')) for line in db.log))

    def test_subjects_table_is_never_written(self):
        db = FakeDb()
        self.apply_all(db)
        self.assertNotIn('INSERT subjects', db.log)
        self.assertEqual(len(db.subjects), EXPECTED_SUBJECT_COUNT)


if __name__ == '__main__':
    unittest.main(verbosity=2)
