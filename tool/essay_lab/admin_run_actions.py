"""Admin-only dispatch adapter. No grading, ownership or billing impersonation."""
from uuid import UUID
from .live_worker import require

async def retry_admin_run(payload, token, rpc_as_caller, admission, enqueue):
    require(isinstance(payload, dict) and set(payload) == {'run_id', 'key'}, 'INVALID_REQUEST')
    run, key = str(UUID(payload['run_id'])), str(UUID(payload['key']))
    # Both RPCs use the original admin JWT, never the Worker credential.
    caps = await rpc_as_caller('admin_lab_run_capabilities', {'p_run': run}, token)
    require(caps.get('version') == 'admin-run-management-v1', 'ADMIN_CONTRACT_REQUIRED')
    require(caps.get('hidden') is not True, 'RUN_ARCHIVED')
    ready = await admission(caps['subject_id'], caps['exam_id'])
    require(ready.get('ready') is True and ready.get('session_version') == 'exam-session-v1', 'ADMIN_CONTRACT_REQUIRED')
    result = await rpc_as_caller('admin_lab_manage_run', {'p_run': run, 'p_action': 'retry', 'p_key': key}, token)
    require(result.get('version') == 'admin-run-management-v1' and result.get('run_id') == run and result.get('action') == 'retry', 'ADMIN_CONTRACT_REQUIRED')
    # Existing consumer rechecks run owner, lifecycle and immutable checkpoints.
    await enqueue({'subject_id': result['subject_id'], 'run_id': run})
    return {'version': 'admin-run-management-v1', 'run_id': run, 'action': 'retry', 'action_id': key, 'state': 'queued'}
