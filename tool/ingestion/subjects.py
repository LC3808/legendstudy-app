"""Canonical subject taxonomy v1 and raw-label mapping.

Design basis, all of it checked against the applied schema and the Day 9-B
survey rather than assumed:

* `subjects` separates the taxonomy from the occurrence. `exam_subjects`
  already carries `source_subject_key` and `raw_subject_label` per paper, so a
  선택과목 variant is a property of the paper, not a new taxonomy entry.
* Day 9-A's 과목 filter is flat: it resolves an exact public subject name to a
  set of ids and tests membership. Hierarchical expansion is recorded as LATER
  in `day-9-search-explore.md`. Mapping 국어(언매) to a separate subject would
  therefore make a 국어 filter miss two thirds of 국어 papers.
* Measured token distribution (Day 9-B dry-run, 609 occurrences): the bare
  tokens 사회 / 과학 / 사회탐구 / 과학탐구 occur **only at grade 1**, and 통합사회 /
  통합과학 at grades 1-2 — they are the site's spellings of one 고1/고2 paper.
  물리학 / 화학 / 생명과학 / 지구과학 without a numeral occur **only at grade 2**.
  국어(…) and 수학(…) occur **only at grade 3**.

So v1 is a flat list of the 영역/과목 a student actually sits, grouped by
`subjects.category`. `parent_id` is deliberately left NULL: `category` already
expresses the grouping as a public column, and leaving the parent FK unused
keeps a future hierarchical v2 free without re-releasing v1 meaning.
"""
from __future__ import annotations

import uuid
import re
import unicodedata
from dataclasses import dataclass

TAXONOMY_VERSION = 'v1'
# The pilot spans a curriculum transition and the source never states which
# curriculum a paper follows, so curriculum_version stays NULL rather than
# asserting something the evidence does not support.
CURRICULUM_VERSION = None

# Deterministic ids: the seed must produce the same UUID on every run and on
# every machine, so `subjects.id` is supplied explicitly instead of relying on
# gen_random_uuid(). id = uuid5(namespace, "<taxonomy_version>:<code>").
NAMESPACE = uuid.uuid5(uuid.NAMESPACE_URL, 'https://legendstudy.com/taxonomy')


def subject_id(code: str, taxonomy_version: str = TAXONOMY_VERSION) -> str:
    return str(uuid.uuid5(NAMESPACE, f'{taxonomy_version}:{code}'))


@dataclass(frozen=True)
class Subject:
    code: str
    name: str
    category: str
    sort_order: int

    @property
    def id(self) -> str:
        return subject_id(self.code)


# Order is the 수능 영역 order; sort_order is spaced so a later release can
# insert without renumbering.
SUBJECTS_V1: tuple[Subject, ...] = (
    Subject('korean', '국어', '공통', 10),
    Subject('math', '수학', '공통', 20),
    Subject('english', '영어', '공통', 30),
    Subject('korean_history', '한국사', '공통', 40),
    Subject('integrated_social', '통합사회', '통합', 50),
    Subject('integrated_science', '통합과학', '통합', 60),
    Subject('life_ethics', '생활과 윤리', '사회탐구', 110),
    Subject('ethics_thought', '윤리와 사상', '사회탐구', 120),
    Subject('korean_geography', '한국지리', '사회탐구', 130),
    Subject('world_geography', '세계지리', '사회탐구', 140),
    Subject('east_asian_history', '동아시아사', '사회탐구', 150),
    Subject('world_history', '세계사', '사회탐구', 160),
    Subject('economics', '경제', '사회탐구', 170),
    Subject('politics_law', '정치와 법', '사회탐구', 180),
    Subject('society_culture', '사회·문화', '사회탐구', 190),
    Subject('physics_1', '물리학Ⅰ', '과학탐구', 210),
    Subject('chemistry_1', '화학Ⅰ', '과학탐구', 220),
    Subject('life_science_1', '생명과학Ⅰ', '과학탐구', 230),
    Subject('earth_science_1', '지구과학Ⅰ', '과학탐구', 240),
    Subject('physics_2', '물리학Ⅱ', '과학탐구', 250),
    Subject('chemistry_2', '화학Ⅱ', '과학탐구', 260),
    Subject('life_science_2', '생명과학Ⅱ', '과학탐구', 270),
    Subject('earth_science_2', '지구과학Ⅱ', '과학탐구', 280),
)
BY_CODE = {s.code: s for s in SUBJECTS_V1}

# Confidence tiers. `verified` is never produced by automated ingestion; a
# human promotes a row, and `ingestion.md` forbids ingestion from touching a
# verified row at all.
EXACT = 1.000       # raw token is the canonical name
ALIAS = 0.950       # documented source spelling of the same subject
INFERRED = 0.800    # resolved only with grade context

# raw source token -> (code, confidence, note)
ALIASES: dict[str, tuple[str, float, str | None]] = {
    '국어': ('korean', EXACT, None),
    '수학': ('math', EXACT, None),
    '영어': ('english', EXACT, None),
    '한국사': ('korean_history', EXACT, None),
    '통합사회': ('integrated_social', EXACT, None),
    '통합과학': ('integrated_science', EXACT, None),
    '경제': ('economics', EXACT, None),
    '동아시아사': ('east_asian_history', EXACT, None),
    '세계사': ('world_history', EXACT, None),
    '세계지리': ('world_geography', EXACT, None),
    '한국지리': ('korean_geography', EXACT, None),
    '생활과윤리': ('life_ethics', ALIAS, 'source omits the space in 생활과 윤리'),
    '윤리와사상': ('ethics_thought', ALIAS, 'source omits the space in 윤리와 사상'),
    '정치와법': ('politics_law', ALIAS, 'source omits the space in 정치와 법'),
    '사회문화': ('society_culture', ALIAS, 'source omits the interpunct in 사회·문화'),
    '사회·문화': ('society_culture', EXACT, None),
    # 국어/수학 선택과목: the elective is a property of the paper. The raw label
    # is preserved on the occurrence; the subject stays the 영역.
    '국어(화작)': ('korean', ALIAS, '선택과목 화법과 작문; subject is the 국어 영역'),
    '국어(언매)': ('korean', ALIAS, '선택과목 언어와 매체; subject is the 국어 영역'),
    '국어(공통)': ('korean', ALIAS, '공통 과목 paper of the 국어 영역'),
    '국어(화법과작문)': ('korean', ALIAS, '선택과목 화법과 작문; subject is the 국어 영역'),
    '국어(언어와매체)': ('korean', ALIAS, '선택과목 언어와 매체; subject is the 국어 영역'),
    '수학(확통)': ('math', ALIAS, '선택과목 확률과 통계; subject is the 수학 영역'),
    '수학(미적)': ('math', ALIAS, '선택과목 미적분; subject is the 수학 영역'),
    '수학(기하)': ('math', ALIAS, '선택과목 기하; subject is the 수학 영역'),
    '수학(공통)': ('math', ALIAS, '공통 과목 paper of the 수학 영역'),
    '수학(확률과통계)': ('math', ALIAS, '선택과목 확률과 통계; subject is the 수학 영역'),
    '수학(미적분)': ('math', ALIAS, '선택과목 미적분; subject is the 수학 영역'),
    # 과학탐구: the source writes an Arabic numeral for the Roman one.
    '물리학1': ('physics_1', ALIAS, 'source writes 1 for Ⅰ'),
    '물리학2': ('physics_2', ALIAS, 'source writes 2 for Ⅱ'),
    '화학1': ('chemistry_1', ALIAS, 'source writes 1 for Ⅰ'),
    '화학2': ('chemistry_2', ALIAS, 'source writes 2 for Ⅱ'),
    '생명과학1': ('life_science_1', ALIAS, 'source writes 1 for Ⅰ'),
    '생명과학2': ('life_science_2', ALIAS, 'source writes 2 for Ⅱ'),
    '지구과학1': ('earth_science_1', ALIAS, 'source writes 1 for Ⅰ'),
    '지구과학2': ('earth_science_2', ALIAS, 'source writes 2 for Ⅱ'),
}

# Tokens whose subject is only decidable with the grade of the sitting.
# Measured: these occur only at grade 1 (combined paper) or grade 2 (Ⅰ-level).
GRADE_SCOPED: dict[str, dict[int, tuple[str, float, str]]] = {
    '사회': {1: ('integrated_social', ALIAS, 'grade 1 combined social paper'),
             2: ('integrated_social', ALIAS, 'grade 2 combined social paper')},
    '과학': {1: ('integrated_science', ALIAS, 'grade 1 combined science paper'),
             2: ('integrated_science', ALIAS, 'grade 2 combined science paper')},
    '사회탐구': {1: ('integrated_social', ALIAS, 'grade 1 combined social paper'),
                 2: ('integrated_social', ALIAS, 'grade 2 combined social paper')},
    '과학탐구': {1: ('integrated_science', ALIAS, 'grade 1 combined science paper'),
                 2: ('integrated_science', ALIAS, 'grade 2 combined science paper')},
    '물리학': {2: ('physics_1', INFERRED, 'grade 2 탐구 paper is Ⅰ-level')},
    '화학': {2: ('chemistry_1', INFERRED, 'grade 2 탐구 paper is Ⅰ-level')},
    '생명과학': {2: ('life_science_1', INFERRED, 'grade 2 탐구 paper is Ⅰ-level')},
    '지구과학': {2: ('earth_science_1', INFERRED, 'grade 2 탐구 paper is Ⅰ-level')},
}

# Historical labels are never auto-mapped onto a v1 subject. They stay
# `unmapped` with the raw label preserved until a reviewed historical release
# exists. Listed so the reason is explicit rather than an accidental miss.
DEFERRED_HISTORICAL = frozenset({
    '수학 가형', '수학 나형', '수학가형', '수학나형',
    '국사', '한국근현대사', '법과사회', '법과정치', '경제지리', '윤리',
    '물리1', '물리2', '생물1', '생물2',
})

# Day 10-C legacy vocabulary. These statuses are intentionally separate from
# the ingestion mapping status: a search/display alias may be useful without
# authorizing an automated occurrence mapping.
SAFE_ALIAS = 'SAFE_ALIAS'
REVIEW_REQUIRED = 'REVIEW_REQUIRED'
HISTORICAL_DISTINCT = 'HISTORICAL_DISTINCT'
UNKNOWN_ALIAS = 'UNKNOWN'

_SUBJECT_FORMAT_RE = re.compile(r'\s+')
_ROMAN_NUMERALS = str.maketrans({'Ⅰ': '1', 'Ⅱ': '2'})


def normalize_subject_token(raw_token: str | None) -> str:
    """Fold formatting only; never infer a curriculum meaning."""
    if not raw_token:
        return ''
    value = unicodedata.normalize('NFC', raw_token).strip().translate(_ROMAN_NUMERALS)
    value = _SUBJECT_FORMAT_RE.sub('', value)
    return value.replace('·', '')


@dataclass(frozen=True)
class LegacySubjectResolution:
    raw_label: str
    normalized_label: str
    status: str
    canonical_code: str | None = None
    canonical_name: str | None = None
    reason: str = ''


# Formatting-equivalent forms and observed full-name source spellings are safe
# aliases. The raw label is still retained by the occurrence writer.
_SAFE_ALIAS_CODES: dict[str, str] = {
    '물리학1': 'physics_1', '물리학2': 'physics_2',
    '화학1': 'chemistry_1', '화학2': 'chemistry_2',
    '생명과학1': 'life_science_1', '생명과학2': 'life_science_2',
    '지구과학1': 'earth_science_1', '지구과학2': 'earth_science_2',
    '생활과윤리': 'life_ethics', '윤리와사상': 'ethics_thought',
    '정치와법': 'politics_law', '사회문화': 'society_culture',
}

# These labels are observed or explicitly called out by the historical survey,
# but are not safe modern-v1 mappings. They remain searchable as raw text until
# a reviewed historical release supplies curriculum/year context.
_REVIEW_REQUIRED_LABELS = frozenset({
    '물리1', '물리2', '생물', '생물1', '생물2',
})

_HISTORICAL_DISTINCT_LABELS = frozenset({
    '수학가형', '수학나형', '국사', '한국근현대사', '법과사회',
    '법과정치', '경제지리', '윤리',
})


def resolve_legacy_subject(
    raw_token: str,
    *,
    year: int | None = None,
    curriculum_version: str | None = None,
    grade_level: int | None = None,
) -> LegacySubjectResolution:
    """Resolve an alias for review/search without creating a verified mapping.

    ``year``, ``curriculum_version`` and ``grade_level`` are deliberately
    accepted now so a later historical release can make context-aware decisions
    without changing this API. They do not promote an ambiguous token today.
    """
    normalized = normalize_subject_token(raw_token)
    if normalized in _HISTORICAL_DISTINCT_LABELS:
        return LegacySubjectResolution(
            raw_token, normalized, HISTORICAL_DISTINCT,
            reason='historical curriculum identity must remain distinct',
        )
    if normalized in _REVIEW_REQUIRED_LABELS:
        return LegacySubjectResolution(
            raw_token, normalized, REVIEW_REQUIRED,
            reason='legacy label requires reviewed year/curriculum evidence',
        )
    code = _SAFE_ALIAS_CODES.get(normalized)
    if code is None:
        # Canonical names are safe too, but use the same normalized lookup so
        # spaces, interpuncts and Roman/Arabic numerals are formatting only.
        code = next(
            (subject.code for subject in SUBJECTS_V1
             if normalize_subject_token(subject.name) == normalized),
            None,
        )
    if code is None:
        return LegacySubjectResolution(
            raw_token, normalized, UNKNOWN_ALIAS,
            reason='no released alias rule',
        )
    return LegacySubjectResolution(
        raw_token, normalized, SAFE_ALIAS, code, BY_CODE[code].name,
        reason='canonical spelling or documented formatting/source alias',
    )


@dataclass(frozen=True)
class Mapping:
    code: str | None
    confidence: float | None
    note: str | None
    status: str          # 'provisional' | 'unmapped'
    reason: str          # why, for the dry-run report


def map_subject(raw_token: str, grade_level: int | None) -> Mapping:
    """Deterministic raw label -> taxonomy v1. Never guesses."""
    if raw_token in DEFERRED_HISTORICAL:
        return Mapping(None, None, None, 'unmapped',
                       'historical label deferred to a reviewed historical release')
    hit = ALIASES.get(raw_token)
    if hit:
        code, confidence, note = hit
        return Mapping(code, confidence, note, 'provisional',
                       'exact canonical name' if confidence == EXACT else 'documented source alias')
    scoped = GRADE_SCOPED.get(raw_token)
    if scoped is not None:
        if grade_level is None:
            return Mapping(None, None, None, 'unmapped',
                           'token needs the grade of the sitting and no grade was determined')
        entry = scoped.get(grade_level)
        if entry is None:
            return Mapping(None, None, None, 'unmapped',
                           f'token not observed at grade {grade_level}; not inferred')
        code, confidence, note = entry
        return Mapping(code, confidence, note, 'provisional',
                       'exact canonical name' if confidence == EXACT else
                       ('documented source alias' if confidence == ALIAS else 'grade-context inference'))
    return Mapping(None, None, None, 'unmapped', 'no rule for this raw label')
