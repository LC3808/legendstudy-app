"""Admin-only dispatch adapter. No grading, ownership or billing impersonation."""
from uuid import UUID
import re
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


async def recover_admin_run(payload, token, rpc_as_caller, admission, enqueue, finish_saved):
    """Explicit admin recovery; only SQL may choose retry vs saved-result replay.

    An ambiguous mutation response never authorizes enqueue/finish. The same
    action key can be resubmitted after a lost queue/finish response; the database
    checks its immutable intent and current lifecycle before accepting that replay.
    """
    require(type(payload) is dict and set(payload) == {'run_id', 'key', 'diagnosis_token'}, 'INVALID_REQUEST')
    run, key = str(UUID(payload['run_id'])), str(UUID(payload['key']))
    diagnosis_token = payload['diagnosis_token']
    require(isinstance(diagnosis_token, str) and re.fullmatch('[0-9a-f]{64}', diagnosis_token), 'INVALID_REQUEST')
    diagnosis = await rpc_as_caller('admin_lab_run_recovery', {'p_run': run}, token)
    require(type(diagnosis) is dict and diagnosis.get('version') == 'admin-run-recovery-v1' and
            diagnosis.get('run_id') == run, 'ADMIN_CONTRACT_REQUIRED')
    require(diagnosis.get('hidden') is not True, 'RUN_ARCHIVED')
    preflight = False
    async def ready():
        report = await admission(diagnosis['subject_id'], diagnosis['exam_id'])
        require(report.get('ready') is True and report.get('session_version') == 'exam-session-v1',
                'ADMIN_CONTRACT_REQUIRED')
    if diagnosis.get('recovery', {}).get('allowed') is True and diagnosis['recovery'].get('method') in ('retry_failed', 'verify_then_retry'):
        await ready()
        preflight = True
    result = await rpc_as_caller('admin_lab_recover_run',
        dict(p_run=run, p_key=key, p_diagnosis_token=diagnosis_token), token)

    def checked(value):
        require(type(value) is dict and value.get('version') == 'admin-run-recovery-v1' and
                value.get('run_id') == run and value.get('action') == 'recover' and
                value.get('action_id') == key and value.get('subject_id') == diagnosis['subject_id'] and
                value.get('exam_id') == diagnosis['exam_id'] and
                type(value.get('dispatch_required')) is bool and type(value.get('success')) is bool,
                'ADMIN_CONTRACT_REQUIRED')
        require(value.get('recovery_type') in (None, 'A', 'B', 'C', 'D') and
                (value.get('reason') is None or isinstance(value['reason'], str) and
                 re.fullmatch('[A-Z][A-Z_0-9]{0,79}', value['reason'])) and
                ('generation' not in value or type(value['generation']) is int and value['generation'] > 0),
                'ADMIN_CONTRACT_REQUIRED')
        expected = {'retry': ('queued', True, False), 'verify_saved': ('verification_required', False, False),
                    'verify_then_retry': ('verification_required', False, False),
                    'completed': ('completed', False, True), 'blocked': ('blocked', False, False)}
        require(value.get('operation') in expected and
                (value.get('state'), value['dispatch_required'], value.get('success')) == expected[value['operation']],
                'ADMIN_CONTRACT_REQUIRED')
        return value

    result = checked(result)
    if result['operation'] in ('verify_saved', 'verify_then_retry'):
        prepared_operation = result['operation']
        if result['operation'] == 'verify_then_retry' and not preflight:
            await ready()
            preflight = True
        result = checked(await finish_saved(result))
        require(result['operation'] in (('completed', 'blocked', 'retry') if prepared_operation == 'verify_then_retry'
                                       else ('completed', 'blocked')), 'ADMIN_CONTRACT_REQUIRED')
    if result['operation'] == 'retry':
        # A successful idempotent replay can have an active retry lease in the new
        # diagnostic snapshot. Only the DB action response may authorize its queue.
        if not preflight:
            await ready()
        await enqueue({'subject_id': result['subject_id'], 'run_id': run})
    # Explicit projection keeps private frozen context, result and proof out of HTTP.
    return {name: result[name] for name in ('version', 'run_id', 'action', 'action_id',
        'operation', 'state', 'recovery_type', 'dispatch_required', 'generation', 'reason', 'success') if name in result}
