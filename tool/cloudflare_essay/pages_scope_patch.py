"""Build a minimal Pages public-exam patch; never replay a settings response.

No network calls or credentials. Cloudflare secret_text values in GET responses
are redacted and MUST NOT be included in a PATCH, even as an empty string.
"""
from uuid import UUID
import base64


def public_scope_patch(current, additions):
    value = current['deployment_configs']['production']['env_vars']['ESSAY_PUBLIC_EXAMS']
    if value.get('type') != 'plain_text':
        raise ValueError('PUBLIC_SCOPE_MUST_BE_PLAIN_TEXT')
    from essay_lab.cloudflare_http import parse_public_exams
    existing = parse_public_exams(value['value'])
    ids = list(dict.fromkeys(existing + list(additions)))
    if any(str(UUID(item)) != item for item in ids):
        raise ValueError('INVALID_EXAM_ID')
    # Match the current gateway/worker contract; batch rollout must explicitly
    # update this limit and its authorization tests before expanding it.
    if not ids or len(ids) > 256:
        raise ValueError('CURRENT_RUNTIME_SCOPE_LIMIT')
    encoded = ','.join(ids)
    if len(encoded.encode()) > 5000:
        encoded = ','.join(UUID(item).hex for item in ids)
    if len(encoded.encode()) > 5000:
        encoded = 'uuid64:' + base64.b64encode(b''.join(UUID(item).bytes for item in ids)).decode()
    if len(encoded.encode()) > 5000:
        raise ValueError('HOSTING_BINDING_SIZE_LIMIT')
    return {'deployment_configs': {'production': {'env_vars': {
        'ESSAY_PUBLIC_EXAMS': {'type': 'plain_text', 'value': encoded}
    }}}}
