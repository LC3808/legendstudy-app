"""Observed source vocabularies.

Every entry here was seen in the 2026-09-15 survey of legendstudy.com
(227 modern posts / 4,280 attachments). Nothing is invented: unknown tokens
quarantine instead of being forced into a canonical value.
"""
from __future__ import annotations

import re
import unicodedata

ZERO_WIDTH = re.compile(r'[​-‏﻿]')


def clean(text: str | None) -> str:
    """NFC-normalise, drop zero-width marks, collapse whitespace."""
    if not text:
        return ''
    text = unicodedata.normalize('NFC', text)
    text = ZERO_WIDTH.sub('', text)
    return re.sub(r'\s+', ' ', text).strip()


# --- resource kind -------------------------------------------------------
# Longest-first: '정답,해설' must win over '정답' and over '해설'.
RESOURCE_KIND_TOKENS: tuple[tuple[str, str], ...] = (
    ('정답 및 해설', 'answer_explanation'),
    ('정답,해설', 'answer_explanation'),
    ('정답, 해설', 'answer_explanation'),
    ('해설,답안', 'answer_explanation'),
    ('해설, 답안', 'answer_explanation'),
    ('답안,해설', 'answer_explanation'),
    ('정답해설', 'answer_explanation'),
    ('듣기 대본', 'listening_script'),
    ('듣기대본', 'listening_script'),
    ('듣기 파일', 'listening_audio'),
    ('듣기파일', 'listening_audio'),
    ('듣기평가', 'listening_audio'),
    ('채점기준', 'reference'),
    ('출제의도', 'reference'),
    ('예시답안', 'answer'),
    ('모범답안', 'answer'),
    ('우수답안', 'answer'),
    ('등급컷', 'grade_cut'),
    ('대본', 'listening_script'),
    ('문제', 'question'),
    ('정답', 'answer'),
    ('해설', 'explanation'),
    ('답안', 'answer'),
)

# --- subject ------------------------------------------------------------
# Order matters. '한국지리' must be tested before '한국사' would ever match a
# tail, and '세계지리' before '세계사'; see tests for the false-positive cases.
SUBJECT_TOKENS: tuple[str, ...] = (
    # Saved Wave1 labels; raw strings remain distinct. Broad/typo labels stay NULL.
    '국어_공통', '국어_언매', '국어_화작', '국어-언매', '국어-화작',
    '수학_공통', '수학_기하', '수학_미적', '수학_확통',
    '국어(+언매)', '국어(+화작)', '수학(+기하)', '수학(+미적)', '수학(+확통)',
    '국어(화작,매체)', '수학(기하,미적,확통)',
    '탐구영역', '생화과윤리', '사회문화1',
    # 국어 / 수학 with elective in parentheses
    '국어(화작)', '국어(언매)', '국어(공통)', '국어(화법과작문)', '국어(언어와매체)',
    '수학(확통)', '수학(미적)', '수학(기하)', '수학(공통)',
    '수학(확률과통계)', '수학(미적분)',
    # 탐구 (modern)
    '생활과윤리', '윤리와사상', '동아시아사', '한국지리', '세계지리', '세계사',
    '정치와법', '법과정치', '사회문화', '사회·문화', '경제',
    '물리학1', '물리학2', '화학1', '화학2',
    '생명과학1', '생명과학2', '지구과학1', '지구과학2',
    # 고1/고2 combined papers: the group name is itself the paper's subject
    '통합사회', '통합과학', '사회탐구', '과학탐구',
    # 고2 papers drop the elective number
    '생명과학', '지구과학', '물리학', '화학',
    # Observed modern 제2외국어/한문 papers (2026-09-26). Recognition only:
    # canonical mapping remains independently gated by subjects.py.
    '독일어', '프랑스어', '스페인어', '중국어', '일본어',
    '러시아어', '아랍어', '베트남어', '한문',
    # base subjects
    '한국사', '국어', '수학', '영어', '사회', '과학',
)

# Historical labels. Never auto-mapped to a modern elective (wiki/ingestion.md).
HISTORICAL_SUBJECT_TOKENS: tuple[str, ...] = (
    # Saved Wave1 labels; raw strings remain distinct. Broad/typo labels stay NULL.
    '국어_공통', '국어_언매', '국어_화작', '국어-언매', '국어-화작',
    '수학_공통', '수학_기하', '수학_미적', '수학_확통',
    '국어(+언매)', '국어(+화작)', '수학(+기하)', '수학(+미적)', '수학(+확통)',
    '국어(화작,매체)', '수학(기하,미적,확통)',
    '탐구영역', '생화과윤리', '사회문화1',
    '수학 가형', '수학 나형', '수학가형', '수학나형',
    '한국근현대사', '법과사회', '경제지리', '국사', '윤리',
    '물리1', '물리2', '생물1', '생물2',
)

# Grouping prefixes inside filenames: '고3_과_물리학1 문제.pdf'.
GROUP_PREFIXES: tuple[str, ...] = (
    '사회탐구 - ', '과학탐구 - ', '사회탐구_', '과학탐구_',
    '사탐_', '과탐_', '사_', '과_',
)

# --- category -> content_type -------------------------------------------
CATEGORY_CONTENT_TYPE: tuple[tuple[str, str], ...] = (
    ('논술 기출 자료', 'university_essay'),
    ('적성고사, 면접 자료', 'study_material'),
    ('사관학교, 경찰대 자료', 'study_material'),
    ('수업 자료실', 'study_material'),
    ('교육 입시 관련 소식', 'education_column'),
)
# Grade-space categories are exam material only when the sub-category says so.
GRADE_SPACE = re.compile(r'"?고([123])"?[을를]\s*위한\s*공간')
EXAM_SUBCATEGORY = re.compile(r'모의고사|국영수|사탐,\s*과탐|사탐,\s*과탐|수능')

# --- exam type ----------------------------------------------------------
# Checked in order; '모의평가'/'모평' must win before the generic '모의고사'.
EXAM_TYPE_TOKENS: tuple[tuple[str, str], ...] = (
    ('수능', 'csat'),
    ('대학수학능력시험', 'csat'),
    ('모의평가', 'evaluation_mock'),
    ('모평', 'evaluation_mock'),
    ('전국연합학력평가', 'national_mock'),
    ('전국연합 학력평가', 'national_mock'),
    ('학력평가', 'national_mock'),
    ('학평', 'national_mock'),
    ('모의고사', 'national_mock'),
)
# The site labels 교육청 학력평가 posts with a calendar year written as
# 'N학년도'. Verified 2026-09-15: post 1705 title says '2026년 5월 고3' while its
# body heading says '2026학년도 고3 전국연합학력평가' for a 2027학년도 cohort.
# academic_year is therefore only trusted for 평가원/수능 material.
ACADEMIC_YEAR_TRUSTED = frozenset({'csat', 'evaluation_mock'})
