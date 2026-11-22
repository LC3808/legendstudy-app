"""Synthetic trusted artifacts + existing validators; no Provider or DB network."""
from copy import deepcopy
import hmac
import importlib
import io
import json
from types import SimpleNamespace
from urllib.error import HTTPError
from urllib.parse import urlparse
from uuid import UUID
from unittest.mock import patch
import unittest

from tool.test_essay_live_worker import fixture, receipt
from tool.essay_lab.admin_run_recovery import validate_saved_recovery, finish_saved_recovery
from tool.essay_lab.live_worker import digest, package, Invalid
from tool.essay_lab.material_runtime import prepare_claimed_material
from tool.essay_lab.scaffolding_adapter import finalize_payload
from tool.essay_lab.admin_run_actions import recover_admin_run, retry_admin_run
from tool.test_essay_archived_dispatch import method

RUN = '10000000-0000-4000-8000-000000000001'
KEY = '20000000-0000-4000-8000-000000000001'
OWNER = '30000000-0000-4000-8000-000000000001'
EXAM = '40000000-0000-4000-8000-000000000001'
TOKEN = '50000000-0000-4000-8000-000000000001'


def recovery_fixture(count=2, pending=None, attempt=0, final=True, math_indices=(), rewrite=False):
    base, _, raw_base = fixture()
    questions = [f'60000000-0000-4000-8000-{i+1:012}' for i in range(count)]
    binding = dict(policy_version='fixture', provider='openai', model='fixture', model_version='fixture',
                   prompt_version='scaffolding-1.3-v12', contract_version='1.3')
    version = 'material-1-' + 'f' * 64
    exam = dict(examId=EXAM, universityId=OWNER, year=2027, kind='mock', track='humanities',
                session=None, campus=None, name='Synthetic exam', sourceHashes=['a' * 64],
                questions=[dict(id=q, sourceKey='source:' + q) for q in questions])
    registry = {'exams': [exam]}
    material = dict(schema='essay-material-package-v1', verification_status='VERIFIED_MANIFEST',
        package_digest='f' * 64, package_version=1, exam_id=EXAM, university_id=OWNER,
        exam_identity=dict(academic_year=2027, exam_type='mock', track='humanities', title='Synthetic exam'),
        rights_status={'a' * 64: {'providerTransmission': 'APPROVED'}},
        questions=[dict(question_id=q, source_key='source:' + q, source_page_references=[
            dict(questionId=q, sourceHash='a' * 64, role=role, startPage=1, endPage=1,
                 evidenceText='Synthetic ' + role, verification='VERIFIED')
            for role in ('question', 'shared_passage', 'intent', 'criteria')]) for q in questions])
    for i in math_indices:
        entry = material['questions'][i]
        entry['evaluation_engine'] = 'math'
        entry['math_context'] = dict(question_id=questions[i], exam_id=EXAM,
            leaf={'response_format': 'FULL_SOLUTION'}, profile={'reasoning_required': True},
            provider_binding={'model': 'fixture-math'}, criteria=[{'id': KEY, 'description': 'Synthetic math criterion'}])
    claim = dict(run_id=RUN, subject_id=OWNER, exam_id=EXAM, lease_token=TOKEN,
        session_version='exam-session-v1', parent_id=None, parent_result=None,
        attempts={str(i): attempt for i in range(count)} if attempt else {},
        snapshot=dict(ownerId=OWNER, runtime=dict(package_digest='f' * 64, binding=binding,
            regime='essay-v1.3/policy/' + 'b' * 64, evaluation_type='humanities'),
            answers=[dict(questionId=q, body=base['answer'], rubricVersion=version, evidenceVersion=version) for q in questions]))
    if rewrite:
        claim['parent_id'] = KEY
        claim['parent_result'] = recovery_fixture(count=count, math_indices=math_indices)[3]
    prepared, caches = prepare_claimed_material(claim, material, registry)
    rows, results = {}, []
    def store(k, value):
        rows[k] = {'state': 'checkpoint', 'payload': deepcopy(value)}
    for i, q in enumerate(prepared):
        c, cache = q['claim'], caches[q['questionId']]
        if i in math_indices:
            output = {'contract_version': 'math-eval-v1', 'summary': 'Synthetic reviewed math result'}
            criteria = [dict(binding=dict(id=x['id'], version=version), label=x['description']) for x in cache['criteria']]
        else:
            raw = deepcopy(raw_base)
            raw['attempt_id'] = q['evaluationId']
            raw['answer_hash'] = c['input']['answer_hash']
            evidence = c['input']['evidence'][-1]['id']
            raw['dimensions'][0].update(criterion_id=c['input']['criteria'][0]['id'], evidence_ids=[evidence])
            raw['improvements'][0]['evidence_ids'] = [evidence]
            if rewrite:
                progress = c['input']['scaffolding_context']['items'][0]['progress_id']
                raw['improvements'][0].update(previous_progress_id=progress, status='improved')
                raw['previous_improvement_reviews'] = [dict(previous_progress_id=progress, outcome='improved', reason='Synthetic comparison')]
            output = finalize_payload(raw, contract_version='1.3')
            criteria = cache['criteria']
        identity = dict(p_evaluation=q['evaluationId'], p_run=RUN, p_token=TOKEN)
        key = f'q{i}' + (f'-retry-{attempt}' if attempt else '')
        store(key + '-reviewed', dict(identity, p_output=output))
        store(key, dict(evaluation_id=q['evaluationId'], claim_sha256=digest(c), state='completed', output=output))
        if pending == i:
            rows[key] = {'state': 'pending', 'payload': None}
        telemetry = dict(input_tokens=1, output_tokens=2, total_tokens=3, latency_ms=1, cost_amount=None, currency=None)
        store(key + '-usage', identity | {'p_' + k: v for k, v in telemetry.items()})
        if i not in math_indices:
            store(f'q{i}-a{attempt}-review', receipt(q['evaluationId'], package(c, cache), raw))
        results.append({k: q[k] for k in ('questionId', 'rubricVersion', 'evidenceVersion')} |
                       dict(evaluation=output, criteria=criteria, telemetry=telemetry))
    result = dict(summary='\n\n'.join(q['evaluation']['summary'] for q in results), questions=results)
    if final:
        if count > 1:
            store('summary', {'input': digest(results), 'summary': result['summary']})
        store('final', {'result': result, 'failed': False})
    return dict(version='admin-run-recovery-v1', run_id=RUN, action_id=KEY, diagnosis_token='a' * 64, operation='verify_saved',
                claimed=claim, checkpoints=rows), material, registry, result


class SavedRecoveryTests(unittest.IsolatedAsyncioTestCase):
    async def test_all_saved_questions_recover_pending_aggregates_without_overwriting_them(self):
        for keys in (('summary',), ('final',), ('summary', 'final')):
            context, material, registry, expected = recovery_fixture()
            for key in keys:
                context['checkpoints'][key] = {'state': 'pending', 'payload': None}
            before = deepcopy(context)
            result, _ = await validate_saved_recovery(context, material, registry)
            self.assertEqual(result, expected)
            self.assertEqual(context, before)
            context['checkpoints'][keys[0]]['payload'] = {'unexpected': 'not empty'}
            with self.assertRaisesRegex(Invalid, 'RECOVERY_ARTIFACT_REQUIRED'):
                await validate_saved_recovery(context, material, registry)

    async def test_partial_failure_with_any_aggregate_intent_cannot_mix_generations(self):
        for key in ('summary', 'final'):
            context, material, registry, _ = recovery_fixture(final=False)
            context['operation'] = 'verify_then_retry'
            context['checkpoints']['q0']['payload'].update(state='failed', output=None)
            context['checkpoints'].pop('q0-reviewed')
            context['checkpoints'][key] = {'state': 'pending', 'payload': None}
            with self.assertRaisesRegex(Invalid, 'RECOVERY_CONTEXT_INVALID'):
                await validate_saved_recovery(context, material, registry)

    async def test_rewrite_rebuilds_exact_frozen_parent_context_and_rejects_changed_parent(self):
        context, material, registry, expected = recovery_fixture(rewrite=True)
        result, _ = await validate_saved_recovery(context, material, registry)
        self.assertEqual(result, expected)
        context['claimed']['parent_result']['questions'][0]['evaluation']['improvements'][0]['action'] = 'changed prior observation'
        with self.assertRaises((ValueError, Invalid)):
            await validate_saved_recovery(context, material, registry)

    async def test_math_and_mixed_saved_outputs_reuse_existing_child_boundary_without_essay_review(self):
        for math_indices in ((0,), (0, 1)):
            for pending in (None, 0):
                for attempt in (0, 1):
                    with self.subTest(math_indices=math_indices, pending=pending, attempt=attempt):
                        context, material, registry, expected = recovery_fixture(math_indices=math_indices,
                            pending=pending, attempt=attempt, final=pending is None)
                        before = deepcopy(context)
                        with patch('tool.essay_lab.mixed_math_runtime.MixedMathWorker.__init__', side_effect=AssertionError('Math evaluator created')):
                            result, proof = await validate_saved_recovery(context, material, registry)
                        self.assertEqual(result, expected)
                        self.assertEqual(len(proof['questions']), 2)
                        self.assertEqual(context, before)

    async def test_math_contract_or_usage_corruption_is_rejected(self):
        for change in (
            lambda c: c['checkpoints']['q0-reviewed']['payload']['p_output'].update(contract_version='1.3'),
            lambda c: c['checkpoints']['q0-reviewed']['payload']['p_output'].update(summary=''),
            lambda c: c['checkpoints']['q0-usage']['payload'].update(p_input_tokens=None),
            lambda c: c['checkpoints']['q0']['payload'].update(claim_sha256='0'*64),
        ):
            context, material, registry, _ = recovery_fixture(math_indices=(0,))
            change(context)
            with self.assertRaises((ValueError, Invalid)):
                await validate_saved_recovery(context, material, registry)

    async def test_saved_final_and_reviewed_pending_restore_without_provider_construction(self):
        for pending, final in [(None, True), (0, False)]:
            for attempt in [0, 2]:
                with self.subTest(pending=pending, final=final, attempt=attempt):
                    context, material, registry, expected = recovery_fixture(pending=pending, attempt=attempt, final=final)
                    original = deepcopy(context)
                    with patch('tool.essay_lab.reviewed_runtime.ReviewedRuntimeWorker.__init__', side_effect=AssertionError('Worker constructed')), \
                         patch('tool.essay_lab.live_worker.OpenAIResponses.__init__', side_effect=AssertionError('Provider constructed')):
                        result, proof = await validate_saved_recovery(context, material, registry)
                    self.assertEqual(result, expected)
                    self.assertEqual(proof['result_sha256'], digest(expected))
                    self.assertEqual(len(proof['questions']), 2)
                    self.assertEqual(context, original)

    async def test_foreign_claim_generation_review_usage_or_final_fail_closed(self):
        changes = {
            'foreign_claim': lambda c: c['checkpoints']['q0']['payload'].update(claim_sha256='0' * 64),
            'foreign_evaluation': lambda c: c['checkpoints']['q0-reviewed']['payload'].update(p_evaluation=EXAM),
            'foreign_token': lambda c: c['checkpoints']['q0-reviewed']['payload'].update(p_token=KEY),
            'foreign_owner': lambda c: c['claimed'].update(subject_id=EXAM),
            'latest_generation_only': lambda c: c['claimed'].update(attempts={'0': 1}),
            'unaccepted_review': lambda c: c['checkpoints']['q0-a0-review']['payload']['quality'].update(grounding=False),
            'missing_review': lambda c: c['checkpoints'].pop('q0-a0-review'),
            'changed_review_output': lambda c: c['checkpoints']['q0-a0-review']['payload'].update(output_sha256='0' * 64),
            'changed_review_package': lambda c: c['checkpoints']['q0-a0-review']['payload'].update(package_sha256='0' * 64),
            'usage_owner': lambda c: c['checkpoints']['q0-usage']['payload'].update(p_run=EXAM),
            'usage_total': lambda c: c['checkpoints']['q0-usage']['payload'].update(p_total_tokens=100),
            'partial_final': lambda c: c['checkpoints']['final']['payload']['result']['questions'].pop(),
            'summary_changed': lambda c: c['checkpoints']['summary']['payload'].update(summary='invented'),
            'wrong_exact_quote': lambda c: c['checkpoints']['q0-reviewed']['payload']['p_output']['sentence_feedback'][0].update(quote='not submitted'),
        }
        for name, change in changes.items():
            with self.subTest(name=name):
                context, material, registry, _ = recovery_fixture()
                change(context)
                with self.assertRaises((Invalid, ValueError)):
                    await validate_saved_recovery(context, material, registry)

    async def test_unknown_or_missing_payload_is_never_taken_over(self):
        for state in ['pending', 'reconciling', 'failed', 'absent']:
            with self.subTest(state=state):
                context, material, registry, _ = recovery_fixture(final=False)
                if state == 'absent':
                    context['checkpoints'].pop('q0')
                elif state == 'pending':
                    context['checkpoints']['q0'] = dict(state='pending', payload=None)
                    context['checkpoints'].pop('q0-reviewed')
                else:
                    context['checkpoints']['q0']['payload'].update(state=state, output=None)
                with self.assertRaises((Invalid, ValueError)):
                    await validate_saved_recovery(context, material, registry)

    async def test_pending_reviewed_plus_definite_failure_returns_only_preserved_subset(self):
        context, material, registry, expected = recovery_fixture(pending=0, final=False)
        context['operation'] = 'verify_then_retry'
        context['checkpoints']['q1']['payload'].update(state='failed', output=None)
        context['checkpoints'].pop('q1-reviewed')
        expected['questions'].pop()
        expected['summary'] = expected['questions'][0]['evaluation']['summary']
        before = deepcopy(context)
        result, proof = await validate_saved_recovery(context, material, registry)
        self.assertEqual(result, expected)
        self.assertEqual(len(proof['questions']), 1)
        self.assertEqual(context, before)
        context['checkpoints']['q1']['payload'].update(state='reconciling')
        with self.assertRaises((ValueError, Invalid)):
            await validate_saved_recovery(context, material, registry)

    async def test_partial_or_all_failed_retries_verify_every_frozen_claim_before_dispatch(self):
        for failed_indices in ((0,), (0, 1)):
            context, material, registry, expected = recovery_fixture(final=False)
            context['operation'] = 'verify_then_retry'
            for index in failed_indices:
                context['checkpoints'][f'q{index}']['payload'].update(state='failed', output=None)
                context['checkpoints'].pop(f'q{index}-reviewed')
            expected['questions'] = [q for i, q in enumerate(expected['questions']) if i not in failed_indices]
            expected['summary'] = '\n\n'.join(q['evaluation']['summary'] for q in expected['questions'])
            result, proof = await validate_saved_recovery(context, material, registry)
            self.assertEqual(result, expected)
            self.assertEqual(len(proof['questions']), len(expected['questions']))
            context['checkpoints']['q0']['payload']['claim_sha256'] = '0' * 64
            with self.assertRaisesRegex(Invalid, 'FOREIGN_CHANNEL_CHECKPOINT'):
                await validate_saved_recovery(context, material, registry)

    async def test_terminal_context_never_fetches_material_or_calls_finish(self):
        action = dict(action_id=KEY, run_id=RUN, subject_id=OWNER, exam_id=EXAM)
        terminal = dict(action, operation='blocked', state='blocked', dispatch_required=False)
        calls = []
        async def rpc(name, args):
            calls.append(name)
            return {'version': 'admin-run-recovery-v1', 'terminal': terminal}
        for state in ('blocked', 'completed'):
            calls.clear()
            terminal.update(operation=state, state=state)
            self.assertEqual(await finish_saved_recovery(action, rpc, {}), terminal)
            self.assertEqual(calls, ['essay_exam_recovery_context'])
        terminal['run_id'] = KEY
        with self.assertRaisesRegex(Invalid, 'RECOVERY_CONTEXT_INVALID'):
            await finish_saved_recovery(action, rpc, {})

    async def test_verifier_failure_records_only_bounded_code_and_never_result(self):
        context, material, registry, _ = recovery_fixture(pending=0, final=False)
        context['checkpoints']['q0-reviewed']['payload']['p_output']['summary'] = 'changed private output'
        calls = []
        async def rpc(name, args):
            calls.append((name, deepcopy(args)))
            if name == 'essay_exam_recovery_context': return context
            if name == 'essay_material_runtime_package': return material
            return {'state': 'blocked'}
        action = dict(action_id=KEY, run_id=RUN, subject_id=OWNER, exam_id=EXAM)
        self.assertEqual(await finish_saved_recovery(action, rpc, registry), {'state': 'blocked'})
        self.assertEqual(calls[-1][1]['p_proof'], {'failure_code': 'ARTIFACT_VERIFICATION_FAILED'})
        self.assertIsNone(calls[-1][1]['p_result'])

    async def test_missing_runtime_feedback_helper_blocks_without_fallback(self):
        context, material, registry, _ = recovery_fixture(attempt=1)
        context['checkpoints']['q0-a1-review']['payload']['package_sha256'] = '0' * 64
        error = ModuleNotFoundError(name='tool.essay_lab.retry_feedback')
        with patch('tool.essay_lab.admin_run_recovery.import_module', side_effect=error):
            with self.assertRaisesRegex(ValueError, 'RECOVERY_RUNTIME_UNAVAILABLE'):
                await validate_saved_recovery(context, material, registry)

    async def test_live_retry_feedback_reconstruction_when_existing_runtime_has_helper(self):
        try:
            helper = importlib.import_module('tool.essay_lab.retry_feedback')
        except ModuleNotFoundError:
            self.skipTest('HEAD lacks live retry_feedback; exact deployed-runtime harness covers this path')
        for pending in (None, 0):
            context, material, registry, expected = recovery_fixture(attempt=1, pending=pending, final=pending is None)
            prepared, caches = prepare_claimed_material(context['claimed'], material, registry)
            for i, q in enumerate(prepared):
                value = dict(component='validation_failure', code='EXACT_QUOTE')
                context['checkpoints'][f'q{i}-a0-validation-failure-' + digest(value)] = dict(state='checkpoint', payload=value)
                expected_package = package(q['claim'], caches[q['questionId']])
                expected_package['retry_validation_context'] = helper.feedback('EXACT_QUOTE')
                context['checkpoints'][f'q{i}-a1-review']['payload']['package_sha256'] = digest(expected_package)
            result, _ = await validate_saved_recovery(context, material, registry)
            self.assertEqual(result, expected)

    async def test_finish_uses_only_worker_context_package_and_commit_with_original_token(self):
        context, material, registry, expected = recovery_fixture(pending=0, final=False)
        calls = []
        async def rpc(name, args):
            calls.append((name, deepcopy(args)))
            if name == 'essay_exam_recovery_context':
                return context
            if name == 'essay_material_runtime_package':
                return material
            self.assertEqual(name, 'essay_exam_recovery_finish')
            self.assertEqual(args['p_result'], expected)
            self.assertEqual(args['p_diagnosis_token'], context['diagnosis_token'])
            raise ValueError('DIAGNOSIS_CHANGED')
        action = dict(action_id=KEY, run_id=RUN, subject_id=OWNER, exam_id=EXAM)
        with self.assertRaisesRegex(ValueError, 'DIAGNOSIS_CHANGED'):
            await finish_saved_recovery(action, rpc, registry)
        self.assertEqual([x[0] for x in calls], ['essay_exam_recovery_context', 'essay_material_runtime_package', 'essay_exam_recovery_finish'])
        self.assertFalse(any('claim' in name or 'retry' in name for name, _ in calls))


class RecoveryHttpTests(unittest.IsolatedAsyncioTestCase):
    async def request(self, *, retry=False, denied=False, service_valid=True, execution_enabled=True):
        events = []
        identity = dict(version='admin-run-recovery-v1', action='recover', action_id=KEY,
                        run_id=RUN, subject_id=OWNER, exam_id=EXAM, recovery_type='B' if retry else 'A')
        async def rpc_fetch(url, headers, body):
            name = url.rsplit('/', 1)[-1]
            events.append((name, json.loads(body), headers['Authorization']))
            self.assertEqual(headers['Authorization'], 'Bearer original-admin')
            if denied:
                raise HTTPError(url, 403, 'denied', None, io.BytesIO(b'{"message":"ADMIN_REQUIRED"}'))
            if name == 'admin_lab_run_recovery':
                return json.dumps(dict(identity, hidden=False, recovery={'allowed': True, 'method': 'retry_failed' if retry else 'finish_saved'}))
            self.assertEqual(name, 'admin_lab_recover_run')
            return json.dumps(dict(identity, operation='retry' if retry else 'verify_saved',
                state='queued' if retry else 'verification_required', dispatch_required=retry, success=False))
        async def saved(action, rpc, registry):
            events.append(('verify-and-finish', action))
            return dict(identity, operation='completed', state='completed', dispatch_required=False, success=True,
                        snapshot={'private': 'must not return'})
        async def admission(*args):
            events.append(('admission', args))
            return dict(ready=True, session_version='exam-session-v1')
        async def send(value):
            events.append(('enqueue', json.loads(value)))
        async def request_text():
            return json.dumps(dict(run_id=RUN, key=KEY, diagnosis_token='a' * 64))
        def forbidden(*args):
            self.fail('Recovery HTTP must not construct evaluator/provider or authenticate as the student')
        response = SimpleNamespace(json=lambda value, status=200, headers=None: (status, value, headers))
        from tool.essay_lab.live_worker import require, Unknown
        fetch = method('tool/cloudflare_essay/entry.py', 'fetch', {
            'json': json, 'hmac': hmac, 'urlparse': urlparse, 'UUID': UUID,
            'require': require, 'Response': response, 'print': lambda *_: None,
            'fetch_bytes': rpc_fetch, 'HTTPError': HTTPError, 'Unknown': Unknown,
            'retry_admin_run': retry_admin_run, 'recover_admin_run': recover_admin_run,
            'finish_saved_recovery': saved, 'REGISTRY': {},
        })
        secret = 'synthetic-service-secret-at-least32'
        owner = SimpleNamespace(env=SimpleNamespace(ESSAY_WORKER_SERVICE_TOKEN=secret,
            ESSAY_EXECUTION_ENABLED='true' if execution_enabled else 'false', ESSAY_QUEUE=SimpleNamespace(send=send)),
            transport=lambda: SimpleNamespace(origin='https://db.test', key='public-fixture', rpc=forbidden, subject=forbidden),
            admission=admission, configuration=forbidden)
        request = SimpleNamespace(method='POST', url='https://worker.test/admin-exam-recover', text=request_text,
            headers={'X-Essay-Service-Token': secret if service_valid else 'invalid', 'Authorization': 'Bearer original-admin'})
        return await fetch(owner, request), events

    async def test_real_fetch_saved_recovery_returns_200_without_provider_or_queue(self):
        (status, body, headers), events = await self.request()
        self.assertEqual(status, 200)
        self.assertEqual(body['state'], 'completed')
        self.assertNotIn('snapshot', body)
        self.assertEqual(headers['Cache-Control'], 'no-store')
        self.assertEqual([x[0] for x in events], ['admin_lab_run_recovery', 'admin_lab_recover_run', 'verify-and-finish'])

    async def test_real_fetch_failed_recovery_queues_only_db_owner(self):
        (status, body, _), events = await self.request(retry=True)
        self.assertEqual(status, 202)
        self.assertEqual(body['state'], 'queued')
        self.assertEqual(events[-1], ('enqueue', {'subject_id': OWNER, 'run_id': RUN}))

    async def test_real_fetch_student_denial_returns_403_and_never_starts_work(self):
        (status, body, _), events = await self.request(denied=True)
        self.assertEqual((status, body), (403, {'code': 'ADMIN_REQUIRED'}))
        self.assertEqual(len(events), 1)

    async def test_service_auth_and_execution_flag_block_before_admin_rpc(self):
        for flags in ({'service_valid': False}, {'execution_enabled': False}):
            result, events = await self.request(**flags)
            self.assertNotIn(result[0], (200, 202))
            self.assertEqual(events, [])


if __name__ == '__main__':
    unittest.main()
