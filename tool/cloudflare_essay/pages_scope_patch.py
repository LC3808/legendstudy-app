"""Build a minimal Pages public-exam patch; never replay a settings response.

No network calls or credentials. Cloudflare secret_text values in GET responses
are redacted and MUST NOT be included in a PATCH, even as an empty string.
"""
from uuid import UUID


def public_scope_patch(current, additions):
    value = current['deployment_configs']['production']['env_vars']['ESSAY_PUBLIC_EXAMS']
    if value.get('type') != 'plain_text':
        raise ValueError('PUBLIC_SCOPE_MUST_BE_PLAIN_TEXT')
    existing = [part.strip() for part in value['value'].split(',') if part.strip()]
    ids = list(dict.fromkeys(existing + list(additions)))
    if any(str(UUID(item)) != item for item in ids):
        raise ValueError('INVALID_EXAM_ID')
    # Match the current gateway/worker contract; batch rollout must explicitly
    # update this limit and its authorization tests before expanding it.
    if not ids or len(ids) > 64:
        raise ValueError('CURRENT_RUNTIME_SCOPE_LIMIT')
    return {'deployment_configs': {'production': {'env_vars': {
        'ESSAY_PUBLIC_EXAMS': {'type': 'plain_text', 'value': ','.join(ids)}
    }}}}
