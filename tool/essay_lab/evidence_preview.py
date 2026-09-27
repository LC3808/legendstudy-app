"""Offline review contract only. No DB, ingestion, classification or AI calls.

The future caller must obtain visible IDs under existing resource RLS and supply
only a verified/visible exam's mappings. This helper does not replace SQL/RLS.
"""
ROLES = (
    'question', 'passage', 'exam_intent', 'scoring_criteria', 'model_answer',
    'example_answer', 'high_scoring_answer', 'explanation', 'guidebook', 'other',
)


def evidence_manifest(exam_id, mappings, visible_resource_ids):
    """Deterministic official resource manifest; missing roles are explicit.

    Reject duplicate composite identities rather than silently select a winner.
    The output is references only, never evidence text or an evaluation package.
    """
    seen = set()
    by_role = {role: [] for role in ROLES}
    visible = set(visible_resource_ids)
    for row in mappings:
        key = (row['essay_exam_id'], row['resource_id'], row['role'])
        if row['role'] not in ROLES:
            raise ValueError('Unknown role')
        if key in seen:
            raise ValueError('Duplicate exam/resource/role mapping')
        seen.add(key)
        if (row['essay_exam_id'] != exam_id or row['resource_id'] not in visible
                or not row.get('is_active') or row.get('verification_status') != 'verified'
                or row.get('provenance') != 'official'
                or not row.get('official_source_url') or not row.get('source_locator')):
            continue
        by_role[row['role']].append(row['resource_id'])
    return {
        'essay_exam_id': exam_id,
        'resources_by_role': {role: sorted(ids) for role, ids in by_role.items()},
        'missing_roles': [role for role, ids in by_role.items() if not ids],
    }
