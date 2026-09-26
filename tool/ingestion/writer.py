"""Production write gate.

The writer is intentionally incomplete: Day 9-B stops before any Supabase
write. `plan_statements` renders the ordered upsert plan for Owner review;
`assert_apply_allowed` always refuses, and refuses twice if the target project
is not the LegendStudy project.
"""
from __future__ import annotations

from dataclasses import dataclass

from .models import PlannedPost, SUPPORTED_NON_EXAM_TYPES, IDENTITY_REVIEW_IDS

LEGENDSTUDY_PROJECT_REF = 'stlhijzpjfgwwdgunlsd'

UPSERT_ORDER = (
    ('source_posts', '(source, external_post_id)'),
    ('content_items', '(source_post_id, source_content_key)'),
    ('exams', '(content_item_id)'),
    ('exam_subjects', '(content_item_id, source_subject_key)'),
    ('resources', '(content_item_id, source_post_id, source_resource_key)'),
)


class ApplyRefused(RuntimeError):
    pass


def assert_apply_allowed(project_ref: str | None, confirmed: bool,
                         live_source: bool = False) -> None:
    """Refuse unless every gate is satisfied. Order matters.

    The project ref is checked first and by exact equality, so a run aimed at
    Muselry — or at anything that is not LegendStudy — is refused before a
    connection is opened, a password is requested or a row is considered.
    """
    if project_ref != LEGENDSTUDY_PROJECT_REF:
        raise ApplyRefused(
            f'refusing: target project ref {project_ref!r} is not the LegendStudy '
            f'project {LEGENDSTUDY_PROJECT_REF!r}')
    if not confirmed:
        raise ApplyRefused('refusing: --i-have-owner-approval was not given')
    if not live_source:
        raise ApplyRefused(
            'refusing: apply requires --source network so the plan comes from a live '
            'dry-run of the current site, not a committed sample')


def plan_statements(plan: PlannedPost) -> list[str]:
    """Human-readable ordered plan for one post. No SQL is executed."""
    out = [f"upsert source_posts {UPSERT_ORDER[0][1]} "
           f"-> ({plan.source_post['source']}, {plan.external_post_id})"]
    if plan.content_item:
        out.append(f"upsert content_items {UPSERT_ORDER[1][1]} "
                   f"-> slug {plan.content_item['slug']} "
                   f"type {plan.content_item['content_type']} is_active=false")
    if plan.exam:
        out.append(f"upsert exams {UPSERT_ORDER[2][1]} -> year {plan.exam['year']} "
                   f"month {plan.exam['exam_month']} grade {plan.exam['grade_level']} "
                   f"type {plan.exam['exam_type']}")
    for occ in plan.occurrences:
        out.append(f"upsert exam_subjects {UPSERT_ORDER[3][1]} "
                   f"-> {occ['source_subject_key']} status {occ['mapping_status']}")
    for res in plan.resources:
        out.append(f"upsert resources {UPSERT_ORDER[4][1]} -> {res['source_resource_key']} "
                   f"type {res['resource_type']} link_kind {res['link_kind']}")
    return out


@dataclass(frozen=True)
class PilotScope:
    """A bounded, named apply scope. Nothing outside it may be written.

    ``approved_ids`` optionally restricts the scope to an explicit operator set of
    external post ids. When it is ``None`` (Pilot C), the caller is responsible
    for bounding the id set, and only the year/type/confidence invariants apply.
    """
    name: str
    min_year: int
    max_year: int
    content_types: frozenset
    approved_ids: frozenset | None = None


PILOT_C = PilotScope('pilot-c-2025-2026', 2025, 2026, frozenset({'exam'}))

# The widest year window an exam scope allows; general controlled apply does not
# inherit the Pilot C 2025-2026 window (see A3-1). Every other Pilot C invariant
# — exam type, high confidence, no verified mapping, is_active=false — is kept.
_MIN_EXAM_YEAR = 1994
_MAX_EXAM_YEAR = 2100


def approved_scope(
    post_ids, content_types=frozenset({'exam'}) | SUPPORTED_NON_EXAM_TYPES,
) -> PilotScope:
    """A controlled apply scope bounded to an explicit approved id set.

    Reuses the Pilot C invariants through the same ``assert_in_scope`` gate; the explicit source set may contain reviewed exam or supported non-exam
    Materials, while Pilot C remains exam-only. An
    empty id set produces a scope that refuses every plan.
    """
    ids = frozenset(str(value) for value in post_ids)
    return PilotScope(f'approved-ids({len(ids)})', _MIN_EXAM_YEAR, _MAX_EXAM_YEAR,
                      content_types, ids)


class ScopeViolation(RuntimeError):
    pass


def expected_rows(plans: list[PlannedPost]) -> dict:
    """Row counts an apply of these plans must produce, for pre/postflight diff."""
    return {
        'source_posts': len(plans),
        'content_items': sum(1 for p in plans if p.content_item),
        'exams': sum(1 for p in plans if p.exam),
        'exam_subjects': sum(len(p.occurrences) for p in plans),
        'resources': sum(len(p.resources) for p in plans),
    }


def assert_in_scope(plans: list[PlannedPost], scope: PilotScope) -> None:
    """Refuse an apply set that reaches outside the approved pilot.

    Checked before any write would be attempted: a scope slip is the one
    mistake that a transaction cannot undo for the Owner afterwards.
    """
    for plan in plans:
        if scope.approved_ids is not None and \
                str(plan.external_post_id) not in scope.approved_ids:
            raise ScopeViolation(
                f'{plan.external_post_id}: outside approved apply set {scope.name}')
        if plan.content_item is None:
            raise ScopeViolation(f'{plan.external_post_id}: no content item')
        content_type = plan.content_item['content_type']
        if content_type not in scope.content_types:
            raise ScopeViolation(
                f'{plan.external_post_id}: content_type {content_type!r} outside {scope.name}')
        if plan.external_post_id in IDENTITY_REVIEW_IDS:
            raise ScopeViolation(f'{plan.external_post_id}: identity review remains frozen')
        if content_type == 'exam':
            if plan.exam is None:
                raise ScopeViolation(f'{plan.external_post_id}: exam extension missing')
            year = plan.exam['year']
            if not scope.min_year <= year <= scope.max_year:
                raise ScopeViolation(f'{plan.external_post_id}: year outside {scope.name}')
        elif content_type in SUPPORTED_NON_EXAM_TYPES:
            if plan.exam is not None or plan.occurrences or any(
                    r.get('occurrence_subject_key') is not None or
                    r.get('exam_subject_id') is not None for r in plan.resources):
                raise ScopeViolation(f'{plan.external_post_id}: non-exam has exam children')
        else:
            raise ScopeViolation(f'{plan.external_post_id}: unsupported content type')
        if not plan.publishable:
            raise ScopeViolation(
                f'{plan.external_post_id}: not a publish candidate ({plan.confidence})')
        for occurrence in plan.occurrences:
            if occurrence['mapping_status'] == 'verified':
                raise ScopeViolation(
                    f'{plan.external_post_id}: automated ingestion must never write a '
                    f'verified mapping ({occurrence["source_subject_key"]})')
        for row in (plan.content_item, *plan.occurrences, *plan.resources):
            if row.get('is_active'):
                raise ScopeViolation(
                    f'{plan.external_post_id}: ingestion must plan is_active=false')


def assert_no_collisions(plans: list[PlannedPost]) -> None:
    """Every upsert key must be unique within the apply set."""
    for label, keys in (
        ('source_posts', [p.external_post_id for p in plans]),
        ('content_items', [(p.external_post_id, p.content_item['source_content_key'])
                           for p in plans if p.content_item]),
        ('slug', [p.content_item['slug'] for p in plans if p.content_item]),
        ('exam_subjects', [(p.external_post_id, o['source_subject_key'])
                           for p in plans for o in p.occurrences]),
        ('resources', [(p.external_post_id, r['source_post_external_id'],
                        r['source_resource_key'])
                       for p in plans for r in p.resources]),
    ):
        if len(keys) != len(set(keys)):
            raise ScopeViolation(f'{label}: duplicate upsert key within the apply set')
