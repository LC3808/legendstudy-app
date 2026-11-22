"""Pure validation of trusted, immutable recovery artifacts; never evaluates.

Only the worker-only recovery context supplies claims/checkpoints. The admin HTTP
request cannot supply a result or proof. A durable reviewed checkpoint records
the original successful validator/reviewer boundary; its historical attestation
is not re-signed, extended, or tested against today's expiry clock.
"""
from copy import deepcopy
from importlib import import_module
import math
import re
from uuid import UUID

from .exam_runtime import ExamQuestionChannel
from .evaluation_policy import policy_family, question_engine
from .live_worker import QUALITY_CHECKS, digest, package, require, validate_output
from .material_runtime import prepare_claimed_material
from .mixed_math_runtime import validate_math_child_result
from .scaffolding_adapter import finalize_payload

VERSION = 'admin-run-recovery-v1'
USAGE_FIELDS = ('input_tokens', 'output_tokens', 'total_tokens', 'latency_ms', 'cost_amount', 'currency')


def _hash(value):
    return isinstance(value, str) and re.fullmatch('[0-9a-f]{64}', value) is not None


def _stored(rows, key):
    row = rows.get(key)
    require(type(row) is dict and row.get('state') == 'checkpoint' and
            type(row.get('payload')) is dict, 'RECOVERY_ARTIFACT_REQUIRED')
    return row['payload']


def _aggregate(rows, key):
    row = rows[key]
    if type(row) is dict and row.get('state') == 'pending':
        require(row.get('payload') is None, 'RECOVERY_ARTIFACT_REQUIRED')
        # N/N question artifacts already prove the complete deterministic result.
        # Retain this interrupted aggregate intent; never overwrite its writer.
        return None
    return _stored(rows, key)


class _SnapshotJournal:
    def __init__(self, rows):
        self.rows = rows

    async def read(self, key):
        return deepcopy(self.rows.get(key))


async def _review_package(claim, cache, rows, index, attempt, expected):
    value = package(claim, cache)
    # Historical pre-feedback attempts used this unchanged package. Newer live
    # runtimes include their existing bounded previous-attempt feedback helper.
    if digest(value) == expected:
        return value
    require(attempt > 0, 'RECOVERY_PACKAGE_MISMATCH')
    try:
        helper = import_module('.retry_feedback', __package__)
    except ModuleNotFoundError as error:
        if error.name != __package__ + '.retry_feedback':
            raise
        raise ValueError('RECOVERY_RUNTIME_UNAVAILABLE') from None
    previous = await helper.previous_feedback(_SnapshotJournal(rows), index, attempt)
    require(previous is not None, 'RECOVERY_PACKAGE_MISMATCH')
    value['retry_validation_context'] = previous
    require(digest(value) == expected, 'RECOVERY_PACKAGE_MISMATCH')
    return value


def _usage(payload, identity):
    require(set(payload) == set(identity) | {'p_' + k for k in USAGE_FIELDS} and
            all(payload[k] == v for k, v in identity.items()), 'RECOVERY_USAGE_MISMATCH')
    counts = [payload['p_' + k] for k in USAGE_FIELDS[:3]]
    require(all(v is None or type(v) is int and 0 <= v < 2**63 for v in counts),
            'RECOVERY_USAGE_MISMATCH')
    require(any(v is None for v in counts) or counts[0] + counts[1] == counts[2],
            'RECOVERY_USAGE_MISMATCH')
    latency = payload['p_latency_ms']
    require(type(latency) is int and 0 <= latency <= 86400000, 'RECOVERY_USAGE_MISMATCH')
    amount, currency = payload['p_cost_amount'], payload['p_currency']
    require(amount is None or type(amount) in (int, float) and math.isfinite(amount) and amount >= 0,
            'RECOVERY_USAGE_MISMATCH')
    require(currency is None or isinstance(currency, str) and len(currency) <= 16,
            'RECOVERY_USAGE_MISMATCH')
    return {k: payload['p_' + k] for k in USAGE_FIELDS}


async def validate_saved_recovery(context, material, registry):
    """Return result + proof, without creating a Worker, Provider, lease or write."""
    require(type(context) is dict and context.get('version') == VERSION and
            _hash(context.get('diagnosis_token')), 'RECOVERY_CONTEXT_INVALID')
    run = str(UUID(context['run_id']))
    str(UUID(context['action_id']))
    claimed, rows = context['claimed'], context['checkpoints']
    operation = context.get('operation')
    require(operation in ('verify_saved', 'verify_then_retry'), 'RECOVERY_CONTEXT_INVALID')
    require(type(claimed) is dict and type(rows) is dict and claimed.get('run_id') == run and
            claimed.get('session_version') == 'exam-session-v1' and
            claimed.get('subject_id') == claimed.get('snapshot', {}).get('ownerId'),
            'RECOVERY_CONTEXT_INVALID')
    require(claimed.get('lease_token') and material.get('exam_id') == claimed.get('exam_id'),
            'RECOVERY_CONTEXT_INVALID')
    questions, caches = prepare_claimed_material(claimed, material, registry)
    family = policy_family(claimed['snapshot']['runtime']['evaluation_type'], material['exam_identity'])
    attempts = claimed.get('attempts')
    require(type(attempts) is dict and set(attempts) <= {str(i) for i in range(len(questions))} and
            all(type(v) is int and v >= 0 for v in attempts.values()), 'INVALID_RETRY_ATTEMPT')
    version = f"material-{material['package_version']}-{claimed['snapshot']['runtime']['package_digest']}"
    results, proofs = [], []
    failed, recoverable = 0, 0
    for index, question in enumerate(questions):
        # Math has a different reviewed-output contract. Never interpret it as an
        # essay or invoke its evaluator while restoring a saved result.
        engine = question.get('engine', 'essay')
        require(engine in ('essay', 'science', 'math'), 'UNSUPPORTED_RECOVERY_ENGINE')
        question_engine(family, engine)
        require(question['rubricVersion'] == question['evidenceVersion'] == version,
                'REVIEWED_PACKAGE_PIN_REQUIRED')
        attempt = attempts.get(str(index), 0)
        key = f'q{index}' + (f'-retry-{attempt}' if attempt else '')
        claim, evaluation = question['claim'], question['evaluationId']
        saved = rows.get(key)
        require(type(saved) is dict, 'RECOVERY_ARTIFACT_REQUIRED')
        if saved.get('state') == 'checkpoint' and saved.get('payload', {}).get('state') == 'failed':
            channel = ExamQuestionChannel(evaluation, claim, None)
            channel.restore(saved['payload'])
            require(operation == 'verify_then_retry' and key + '-reviewed' not in rows,
                    'RECONCILIATION_REQUIRED')
            failed += 1
            continue
        identity = dict(p_evaluation=evaluation, p_run=run, p_token=claimed['lease_token'])
        reviewed = _stored(rows, key + '-reviewed')
        require(set(reviewed) == set(identity) | {'p_output'} and
                all(reviewed[k] == v for k, v in identity.items()) and
                type(reviewed['p_output']) is dict, 'FOREIGN_EXAM_CHECKPOINT')
        output = deepcopy(reviewed['p_output'])
        cache = caches[question['questionId']]
        telemetry = _usage(_stored(rows, key + '-usage'), identity)
        if engine == 'math':
            # The Math child already verified this immutable reviewed output.
            # Reuse its existing boundary; never require an essay review receipt.
            validate_math_child_result(dict(evaluation=output, usage=telemetry))
            output_hash, package_hash = digest(output), digest(cache)
            criteria = [dict(binding=dict(id=c['id'], version=version), label=c['description'])
                        for c in cache['criteria']]
        else:
            raw = deepcopy(output)
            local = raw.pop('local_reviews', None)
            require(type(local) is list, 'RECOVERY_REVIEW_INVALID')
            validate_output(raw, claim)
            require(finalize_payload(raw, contract_version='1.3', local_reviews=local) == output,
                    'RECOVERY_REVIEW_INVALID')
            review = _stored(rows, f'q{index}-a{attempt}-review')
            require(set(review) == {'reviewer', 'expires_at', 'evaluation_id', 'package_sha256',
                                   'output_sha256', 'quality', 'local_issue_keys', 'signature'} and
                    review['evaluation_id'] == evaluation and review['output_sha256'] == digest(raw) and
                    _hash(review['package_sha256']) and _hash(review['signature']) and
                    isinstance(review['reviewer'], str) and bool(review['reviewer'].strip()) and
                    type(review['expires_at']) is int and review['expires_at'] > 0 and
                    type(review['quality']) is dict and set(review['quality']) == QUALITY_CHECKS and
                    all(v is True for v in review['quality'].values()), 'RECOVERY_REVIEW_INVALID')
            local_keys = [i['issue_key'] for i in raw['improvements'] if i['claim_scope'] == 'local_sentence']
            require(type(review['local_issue_keys']) is list and len(review['local_issue_keys']) == len(local_keys)
                    and set(review['local_issue_keys']) == set(local_keys) and
                    all(item['reviewer'] == review['reviewer'] for item in local), 'RECOVERY_REVIEW_INVALID')
            await _review_package(claim, cache, rows, index, attempt, review['package_sha256'])
            output_hash, package_hash = digest(raw), review['package_sha256']
            criteria = deepcopy(cache['criteria'])
        completed = dict(evaluation_id=evaluation, claim_sha256=digest(claim), state='completed', output=output)
        if saved.get('state') == 'checkpoint':
            channel = ExamQuestionChannel(evaluation, claim, None)
            channel.restore(saved['payload'])
            require(channel.terminal == 'completed' and saved['payload'] == completed,
                    'RECOVERY_RESULT_MISMATCH')
        else:
            # A durable reviewed payload is stronger than a still-pending q write.
            # No pending/reconciling row is overwritten, stolen or dispatched.
            require(saved.get('state') == 'pending' and saved.get('payload') is None,
                    'RECONCILIATION_REQUIRED')
            recoverable += 1
        results.append({k: question[k] for k in ('questionId', 'rubricVersion', 'evidenceVersion')} |
                       dict(evaluation=output, criteria=criteria, telemetry=telemetry))
        proofs.append(dict(question_id=question['questionId'], evaluation_id=evaluation,
                           claim_sha256=digest(claim), output_sha256=output_hash,
                           package_sha256=package_hash))
    require(bool(results) or operation == 'verify_then_retry', 'INVALID_EXAM_QUESTION_SET')
    require(operation != 'verify_then_retry' or failed > 0 and
            'summary' not in rows and 'final' not in rows, 'RECOVERY_CONTEXT_INVALID')
    summary = '\n\n'.join(q['evaluation']['summary'] for q in results)
    if 'summary' in rows:
        saved_summary = _aggregate(rows, 'summary')
        require(saved_summary is None or saved_summary == {'input': digest(results), 'summary': summary}, 'EXAM_SYNTHESIS_CHANGED')
    result = dict(summary=summary, questions=results)
    if 'final' in rows:
        final = _aggregate(rows, 'final')
        require(final is None or final == {'result': result, 'failed': False}, 'RECOVERY_FINAL_MISMATCH')
    return result, dict(questions=proofs, result_sha256=digest(result))


async def finish_saved_recovery(action, worker_rpc, registry):
    """Private worker-only second phase. Never returns context/proof to the WEB."""
    key = str(UUID(action['action_id']))
    context = await worker_rpc('essay_exam_recovery_context', {'p_key': key})
    require(type(context) is dict and context.get('version') == VERSION, 'RECOVERY_CONTEXT_INVALID')
    if 'terminal' in context:
        terminal = context['terminal']
        require(type(terminal) is dict and terminal.get('action_id') == key and
                all(terminal.get(k) == action[k] for k in ('run_id', 'subject_id', 'exam_id')),
                'RECOVERY_CONTEXT_INVALID')
        return terminal
    require(context.get('action_id') == key and context.get('run_id') == action['run_id'],
            'RECOVERY_CONTEXT_INVALID')
    claim = context['claimed']
    require(claim.get('subject_id') == action['subject_id'] and claim.get('exam_id') == action['exam_id'],
            'RECOVERY_CONTEXT_INVALID')
    policy = claim['snapshot']['runtime']
    material = await worker_rpc('essay_material_runtime_package',
                                dict(p_exam=claim['exam_id'], p_digest=policy['package_digest']))
    try:
        result, proof = await validate_saved_recovery(context, material, registry)
    except Exception as error:
        # Persist only a closed symbolic reason; no exception text or artifacts.
        code = str(error)
        safe = code if code in ('UNSUPPORTED_RECOVERY_ENGINE', 'RECOVERY_RUNTIME_UNAVAILABLE') else 'ARTIFACT_VERIFICATION_FAILED'
        return await worker_rpc('essay_exam_recovery_finish', dict(p_key=key,
            p_diagnosis_token=context['diagnosis_token'], p_result=None, p_proof={'failure_code': safe}))
    return await worker_rpc('essay_exam_recovery_finish', dict(p_key=key,
        p_diagnosis_token=context['diagnosis_token'], p_result=result, p_proof=proof))
