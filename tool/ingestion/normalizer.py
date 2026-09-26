"""Raw observed facts -> canonical rows, quarantine cases and confidence.

Column names and value domains follow
`supabase/migrations/20260912000100_initial_content_schema.sql` exactly.
Generated columns (`exams.sort_date`, `exams.content_type`,
`content_items.feed_updated_at`) are never produced here.
"""
from __future__ import annotations

import hashlib
import re

from . import MAPPING_RULE_VERSION, PARSER_VERSION, SOURCE
from .models import PlannedPost, QuarantineCase, RawPost
from .parser import parse_title, split_resource_kind, split_subject
from .subjects import TAXONOMY_VERSION, map_subject, subject_id
from .taxonomy import (
    ACADEMIC_YEAR_TRUSTED, CATEGORY_CONTENT_TYPE, EXAM_SUBCATEGORY,
    GRADE_SPACE, clean,
)

# Deterministic quarantine codes. Stored in ingestion_quarantine.kind, which
# only requires a non-blank value, so no schema change is needed.
KINDS = (
    'classification_missing_category',
    'classification_unknown_category',
    'exam_year_unknown',
    'exam_month_unknown',
    'exam_grade_unknown',
    'exam_type_unknown',
    'exam_academic_year_conflict',
    'attachment_none',
    'resource_kind_unknown',
    'resource_subject_unknown',
    'resource_identity_missing',
    'resource_identity_duplicate',
    'resource_url_expiring',
    'merge_candidate_exam',
    'source_missing',
    'subject_taxonomy_gap',
)
# Advisory cases: recorded for review but never a whole-post publication blocker.
# - resource_url_expiring: a known, uniform Kakao CDN property.
# - subject_taxonomy_gap: a recognized subject whose raw label has no taxonomy
#   rule yet. Per decisions.md ("taxonomy activity does not determine occurrence/
#   resource publication"), such an occurrence publishes UNMAPPED with its raw
#   label (subject_id NULL) and is never force-mapped to a wrong subject; the
#   canonical mapping is completed in a later taxonomy wave. An incomplete
#   non-core taxonomy (e.g. 제2외국어/한문) must not hold back the core exam.
ADVISORY = frozenset({'resource_url_expiring', 'subject_taxonomy_gap'})
# Cases that stop a post from becoming a publish candidate.
BLOCKING = frozenset({
    'classification_missing_category', 'classification_unknown_category',
    'exam_year_unknown', 'exam_month_unknown', 'exam_grade_unknown',
    'exam_type_unknown', 'exam_academic_year_conflict',
    'resource_identity_missing', 'resource_identity_duplicate',
    'source_missing',
})

TITLE_LEAD = re.compile(r'^[\s→▶◆\-–—>]+')
EXT = re.compile(r'\.([A-Za-z0-9]{2,5})$')
BOX_ACTION_SUFFIX = re.compile(
    r'\s*\(\s*실시간(?:\s*듣기)?\s*/\s*(?:다운로드|다운)\s*\)\s*$'
)


def display_title(raw: str) -> str:
    return clean(TITLE_LEAD.sub('', clean(raw)))


def content_hash(post: RawPost) -> str:
    """Stable digest of everything that would change a canonical projection."""
    parts = [
        post.title, post.category or '', post.published_at or '',
        post.updated_at or '', PARSER_VERSION, MAPPING_RULE_VERSION,
    ]
    for att in sorted(post.attachments, key=lambda a: a.resource_key):
        parts.append(f'{att.provider}|{att.resource_key}|{att.display_name}|{att.unsigned_url}')
    return hashlib.sha256('\x1f'.join(parts).encode('utf-8')).hexdigest()


def classify(category: str | None) -> tuple[str | None, str | None]:
    """Return (content_type, quarantine kind if undecidable)."""
    cat = clean(category or '')
    if not cat:
        return None, 'classification_missing_category'
    for token, content_type in CATEGORY_CONTENT_TYPE:
        if token in cat:
            return content_type, None
    if GRADE_SPACE.search(cat):
        if EXAM_SUBCATEGORY.search(cat):
            return 'exam', None
        return 'study_material', None
    return None, 'classification_unknown_category'


def _exam_row(facts: dict, cases: list[QuarantineCase], post_id: str) -> dict | None:
    year = facts['calendar_year']
    month = facts['nominal_month'] or facts['administered_month']
    grade = facts['grade_level']
    exam_type = facts['exam_type']

    if year is None:
        cases.append(QuarantineCase('exam_year_unknown', post_id,
                                    'No calendar year in title or 시행 prefix.',
                                    {'title': facts['raw_title']}))
    if month is None:
        cases.append(QuarantineCase('exam_month_unknown', post_id,
                                    'No nominal or administered month in title.',
                                    {'title': facts['raw_title']}))
    if grade is None:
        cases.append(QuarantineCase('exam_grade_unknown', post_id,
                                    'No 고N in title and no grade in category.',
                                    {'title': facts['raw_title'],
                                     'category': facts['raw_category']}))
    if exam_type is None:
        cases.append(QuarantineCase('exam_type_unknown', post_id,
                                    'No recognised exam-type token in title.',
                                    {'title': facts['raw_title']}))

    notes: list[str] = []
    academic_year = None
    if facts['academic_year'] is not None:
        if exam_type in ACADEMIC_YEAR_TRUSTED:
            academic_year = facts['academic_year']
            # 수능/모의평가: the labelled 학년도 is one ahead of the sitting year.
            if year is not None and academic_year not in (year, year + 1):
                cases.append(QuarantineCase(
                    'exam_academic_year_conflict', post_id,
                    'Labelled 학년도 is not the sitting year or the next year.',
                    {'calendar_year': year, 'academic_year': academic_year}))
                academic_year = None
        else:
            # Verified 2026-09-15: 교육청 학력평가 posts write the calendar year as
            # 'N학년도' (post 1705 body: '2026학년도 고3 전국연합학력평가' for a
            # 2026-05 sitting). Never promote that label to academic_year.
            notes.append(f"source academic label {facts['academic_year_label']!r} "
                         f"not trusted for {exam_type}")
    if (facts['administered_month'] is not None
            and facts['nominal_month'] is not None
            and facts['administered_month'] != facts['nominal_month']):
        notes.append(f"nominal month {facts['nominal_month']} differs from "
                     f"administered month {facts['administered_month']}")
    if year is None or month is None or grade is None or exam_type is None:
        return None
    return {
        'year': year,
        'academic_year': academic_year,
        'exam_month': month,
        'exam_date': None,
        'grade_level': grade,
        'raw_grade_label': facts['raw_grade_label'],
        'exam_type': exam_type,
        'raw_exam_type': facts['raw_exam_type'],
        'exam_round': None,
        'curriculum_version': None,
        'normalization_note': '; '.join(notes) or None,
    }


def _apply_taxonomy(occurrences: list[dict], grade_level: int | None,
                    post_id: str, cases: list[QuarantineCase]) -> None:
    """Attach a provisional taxonomy mapping. Never produces `verified`."""
    for occ in occurrences:
        mapping = map_subject(occ['source_subject_key'], grade_level)
        occ['mapping_reason'] = mapping.reason
        if mapping.status != 'provisional':
            if mapping.reason == 'no rule for this raw label':
                cases.append(QuarantineCase(
                    'subject_taxonomy_gap', post_id,
                    'Raw subject label has no taxonomy rule; occurrence stays unmapped.',
                    {'raw_subject_label': occ['source_subject_key']}))
            continue
        occ['subject_id'] = subject_id(mapping.code)
        occ['subject_code'] = mapping.code
        occ['taxonomy_version'] = TAXONOMY_VERSION
        occ['mapping_status'] = 'provisional'
        occ['mapping_confidence'] = mapping.confidence
        occ['mapping_note'] = '; '.join(
            x for x in (occ.get('mapping_note'), mapping.note) if x) or None


def _resource_rows(post: RawPost, is_exam: bool,
                   cases: list[QuarantineCase]) -> tuple[list[dict], list[dict]]:
    occurrences: dict[str, dict] = {}
    resources: list[dict] = []
    seen_keys: set[str] = set()
    expiring = 0

    for order, att in enumerate(post.attachments):
        if not clean(att.resource_key):
            cases.append(QuarantineCase('resource_identity_missing', post.external_post_id,
                                        'Attachment has no stable provider identity.',
                                        {'name': att.display_name}))
            continue
        if att.resource_key in seen_keys:
            cases.append(QuarantineCase('resource_identity_duplicate', post.external_post_id,
                                        'Two attachments resolve to one provider identity.',
                                        {'resource_key': att.resource_key}))
            continue
        seen_keys.add(att.resource_key)

        classification_name = (clean(BOX_ACTION_SUFFIX.sub('', att.display_name))
                               if att.provider == 'box' else att.display_name)
        left, resource_type, raw_kind = split_resource_kind(classification_name)
        if resource_type is None:
            cases.append(QuarantineCase('resource_kind_unknown', post.external_post_id,
                                        'Filename tail is not a known resource kind.',
                                        {'name': att.display_name}))
            resource_type = 'other'

        subject_key = None
        if is_exam:
            raw_subject, historical = split_subject(left)
            if raw_subject is None:
                cases.append(QuarantineCase('resource_subject_unknown', post.external_post_id,
                                            'No known subject token in filename.',
                                            {'name': att.display_name}))
            else:
                subject_key = raw_subject
                if subject_key not in occurrences:
                    occurrences[subject_key] = {
                        'source_subject_key': subject_key,
                        'subject_id': None,
                        'raw_subject_label': raw_subject,
                        'taxonomy_version': None,
                        'mapping_status': 'unmapped',
                        'mapping_confidence': None,
                        'mapping_note': ('historical curriculum label; never auto-mapped'
                                         if historical else None),
                        'mapping_rule_version': MAPPING_RULE_VERSION,
                        'verified_at': None,
                        'display_order': len(occurrences),
                        'is_active': False,
                        'historical': historical,
                    }

        if att.provider in ('box', 'gdrive'):
            link_kind = 'landing_page'
        elif att.provider == 'cfile':
            link_kind = 'file'
        elif att.provider == 'kakaocdn':
            # Verified 2026-09-15: the unsigned blog.kakaocdn.net path and an
            # expired signature both fail to load. The observed href carries a
            # site-wide rolling credential/expires/signature that must not be
            # stored, so the stored locator is not a proven direct file.
            link_kind = 'unknown'
            expiring += 1
        else:
            link_kind = 'unknown'

        ext_match = EXT.search(classification_name)
        resources.append({
            'source_post_external_id': post.external_post_id,
            'source_resource_key': att.resource_key,
            'resource_type': resource_type,
            'raw_kind_label': raw_kind or None,
            'title': att.display_name or att.resource_key,
            'source_label': att.display_name or None,
            'source_url': att.unsigned_url,
            'link_kind': link_kind,
            'file_url': None,
            'mime_type': None,
            'file_extension': (ext_match.group(1).lower() if ext_match else None),
            'file_size': None,
            'link_status': 'unchecked',
            'last_checked_at': None,
            'display_order': order,
            'is_active': False,
            'occurrence_subject_key': subject_key,
            'provider': att.provider,
        })

    if expiring:
        cases.append(QuarantineCase(
            'resource_url_expiring', post.external_post_id,
            'Attachment locators require a site-wide rolling signature; stored '
            'source_url is identity only and is not a proven download link.',
            {'count': expiring, 'provider': 'kakaocdn'}))
    if not post.attachments:
        cases.append(QuarantineCase('attachment_none', post.external_post_id,
                                    'Post has no attachment of any known provider.', {}))
    return list(occurrences.values()), resources


def normalize(post: RawPost, crawled_at: str, map_subjects: bool = False) -> PlannedPost:
    cases: list[QuarantineCase] = []
    content_type, cls_case = classify(post.category)
    if cls_case:
        cases.append(QuarantineCase(cls_case, post.external_post_id,
                                    'Category could not be mapped to a content type.',
                                    {'category': post.category}))

    facts = parse_title(post.title, post.category)
    is_exam = content_type == 'exam'
    exam = _exam_row(facts, cases, post.external_post_id) if is_exam else None
    occurrences, resources = _resource_rows(post, is_exam, cases)
    if map_subjects and occurrences:
        _apply_taxonomy(occurrences, (exam or {}).get('grade_level'),
                        post.external_post_id, cases)

    source_post = {
        'source': SOURCE,
        'external_post_id': post.external_post_id,
        'url': post.url,
        'title': post.title,
        'category': post.category,
        'source_published_at': post.published_at,
        'source_updated_at': post.updated_at,
        'raw_excerpt': None,
        'raw_metadata': {
            'parser_version': PARSER_VERSION,
            'mapping_rule_version': MAPPING_RULE_VERSION,
            'title_facts': {k: v for k, v in facts.items() if v is not None},
            'attachment_providers': sorted({a.provider for a in post.attachments}),
            'attachment_count': len(post.attachments),
            'signed_attachment_count': sum(1 for a in post.attachments if a.had_signed_query),
        },
        'content_hash': content_hash(post),
        'parser_version': PARSER_VERSION,
        'last_crawled_at': crawled_at,
        'source_status': 'available',
    }

    content_item = None
    if content_type:
        content_item = {
            'source_content_key': 'main',
            'slug': f'legendstudy-{post.external_post_id}-main',
            'content_type': content_type,
            'title': display_title(post.title),
            'summary': None,
            'source_url': post.url,
            'published_at': post.published_at,
            'source_updated_at': post.updated_at,
            'thumbnail_url': None,
            'is_active': False,
        }

    blocking = [c for c in cases if c.kind in BLOCKING]
    soft = [c for c in cases if c.kind not in BLOCKING and c.kind not in ADVISORY]
    if blocking or content_item is None:
        confidence = 'low'
    elif soft:
        confidence = 'medium'
    else:
        confidence = 'high'
    if is_exam and exam is None:
        confidence = 'low'

    return PlannedPost(
        source_post=source_post,
        content_item=content_item,
        exam=exam,
        occurrences=occurrences,
        resources=resources,
        quarantine=cases,
        confidence=confidence,
        publishable=(confidence == 'high'),
    )


def exam_identity(plan: PlannedPost) -> tuple | None:
    """Canonical exam key used only to surface merge candidates for review."""
    if not plan.exam:
        return None
    e = plan.exam
    return (e['year'], e['exam_month'], e['grade_level'], e['exam_type'])
