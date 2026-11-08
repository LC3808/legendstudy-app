"""Canonical dry-run row models.

Field names match `supabase/migrations/20260912000100_initial_content_schema.sql`.
Nothing here is written to a database; these are plan objects only.
"""
from __future__ import annotations

from dataclasses import dataclass, field
import json
from pathlib import Path

# Explicit reviewed publication holds survive isolated/bounded reruns.
IDENTITY_REVIEW_IDS = frozenset(
    post_id for group in json.loads((Path(__file__).parent /
        "samples/wave1-identity-review.json").read_text())["groups"]
    for post_id in group["external_post_ids"])
SUPPORTED_NON_EXAM_TYPES = frozenset({
    "university_essay", "study_material", "education_column"})

CONTENT_TYPES = frozenset({
    'exam', 'study_material', 'education_column', 'university_essay',
    'admissions_info', 'other',
})
EXAM_TYPES = frozenset({
    'school_assessment', 'national_mock', 'evaluation_mock',
    'csat', 'preliminary', 'other',
})
RESOURCE_TYPES = frozenset({
    'question', 'answer', 'explanation', 'answer_explanation',
    'listening_audio', 'listening_script', 'grade_cut', 'reference', 'other',
})
LINK_KINDS = frozenset({'file', 'landing_page', 'unknown'})
CONFIDENCE = ('high', 'medium', 'low')


@dataclass(frozen=True)
class RawAttachment:
    """One observed attachment link, before canonical classification."""
    provider: str            # 'kakaocdn' | 'cfile' | 'box' | 'gdrive' | 'other'
    resource_key: str        # deterministic provider file identity
    display_name: str        # visible link text / filename
    unsigned_url: str        # observed href with expiring query removed
    had_signed_query: bool
    display_size: str | None = None


@dataclass(frozen=True)
class RawPost:
    """Everything the parser observed on one source post."""
    external_post_id: str
    url: str
    title: str
    category: str | None
    published_at: str | None
    updated_at: str | None
    attachments: tuple[RawAttachment, ...] = ()
    body_excerpt: str | None = None


@dataclass
class QuarantineCase:
    kind: str                 # deterministic code, see quarantine.KINDS
    external_post_id: str | None
    note: str
    payload: dict = field(default_factory=dict)

    def as_row(self) -> dict:
        return {
            'kind': self.kind,
            'external_post_id': self.external_post_id,
            'status': 'open',
            'note': self.note,
            'payload': self.payload,
        }


@dataclass
class PlannedPost:
    """One source post's complete canonical plan."""
    source_post: dict
    content_item: dict | None = None
    exam: dict | None = None
    occurrences: list[dict] = field(default_factory=list)
    resources: list[dict] = field(default_factory=list)
    quarantine: list[QuarantineCase] = field(default_factory=list)
    confidence: str = 'low'
    publishable: bool = False

    @property
    def external_post_id(self) -> str:
        return self.source_post['external_post_id']
