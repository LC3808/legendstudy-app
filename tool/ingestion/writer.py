"""Production write gate.

The writer is intentionally incomplete: Day 9-B stops before any Supabase
write. `plan_statements` renders the ordered upsert plan for Owner review;
`assert_apply_allowed` always refuses, and refuses twice if the target project
is not the LegendStudy project.
"""
from __future__ import annotations

from .models import PlannedPost

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


def assert_apply_allowed(project_ref: str | None, confirmed: bool) -> None:
    """Never returns. Day 9-B has no Owner authorisation to write."""
    if project_ref != LEGENDSTUDY_PROJECT_REF:
        raise ApplyRefused(
            f'refusing: target project ref {project_ref!r} is not the LegendStudy '
            f'project {LEGENDSTUDY_PROJECT_REF!r}')
    if not confirmed:
        raise ApplyRefused('refusing: --i-have-owner-approval was not given')
    raise ApplyRefused(
        'refusing: Day 9-B is dry-run only. Production apply requires a separate '
        'Owner-approved task; see wiki/day-9-ingestion.md "Production gate".')


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
