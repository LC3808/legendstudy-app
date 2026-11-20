"""Actual Worker entry/consumer boundaries; synthetic identities, no network."""
import ast
import hmac
import json
from pathlib import Path
from types import SimpleNamespace
from urllib.parse import urlparse
from uuid import UUID, uuid5
import unittest

SUBJECT = '10000000-0000-4000-8000-000000000001'
RUN = '20000000-0000-4000-8000-000000000001'


def require(ok, code):
    if not ok:
        raise ValueError(code)


def method(path, name, scope):
    tree = ast.parse(Path(path).read_text())
    node = next(n for n in ast.walk(tree) if isinstance(n, ast.AsyncFunctionDef) and n.name == name)
    exec(compile(ast.Module(body=[node], type_ignores=[]), path, 'exec'), scope)
    return scope[name]


class ArchivedDispatchTests(unittest.IsolatedAsyncioTestCase):
    async def request(self, state='archived', denied=False):
        events = []

        async def subject(token):
            self.assertEqual(token, 'original-student')
            events.append('authenticate')
            return SUBJECT

        async def rpc(name, args):
            self.assertEqual(name, 'essay_exam_dispatch_guard')
            self.assertEqual(args, {'p_subject': SUBJECT, 'p_run': RUN})
            events.append('owner-lifecycle-guard')
            if denied:
                raise ValueError('ACCESS_DENIED')
            return {'run_id': RUN, 'state': state}

        async def send(body):
            events.append('enqueue')
            self.assertEqual(json.loads(body), {'subject_id': SUBJECT, 'run_id': RUN})

        async def text():
            return json.dumps({'run_id': RUN})

        response = SimpleNamespace(json=lambda value, status=200, headers=None: (status, value))
        fetch = method('tool/cloudflare_essay/entry.py', 'fetch', {
            'json': json, 'hmac': hmac, 'urlparse': urlparse, 'UUID': UUID,
            'require': require, 'Response': response, 'print': lambda *_: None,
        })
        secret = 'synthetic-service-token-32-characters'
        owner = SimpleNamespace(
            env=SimpleNamespace(ESSAY_WORKER_SERVICE_TOKEN=secret, ESSAY_EXECUTION_ENABLED='true', ESSAY_QUEUE=SimpleNamespace(send=send)),
            transport=lambda: SimpleNamespace(subject=subject, rpc=rpc),
        )
        request = SimpleNamespace(method='POST', url='https://worker.test/exam-evaluate', text=text,
                                  headers={'X-Essay-Service-Token': secret, 'Authorization': 'Bearer original-student'})
        return await fetch(owner, request), events

    async def test_archived_old_client_is_rejected_before_queue(self):
        result, events = await self.request()
        self.assertEqual(result, (409, {'code': 'RUN_ARCHIVED'}))
        self.assertEqual(events, ['authenticate', 'owner-lifecycle-guard'])

    async def test_active_run_keeps_identity_only_dispatch(self):
        result, events = await self.request('reserved')
        self.assertEqual(result, (202, {'run_id': RUN, 'state': 'queued'}))
        self.assertEqual(events, ['authenticate', 'owner-lifecycle-guard', 'enqueue'])

    async def test_owner_denial_cannot_enqueue(self):
        result, events = await self.request(denied=True)
        self.assertNotEqual(result[0], 202)
        self.assertNotIn('enqueue', events)

    async def test_archived_claim_returns_before_provider_or_checkpoint(self):
        calls = []

        async def rpc(name, args):
            calls.append(name)
            self.assertEqual(args['p_subject'], SUBJECT)
            self.assertEqual(args['p_run'], RUN)
            return {'state': 'archived', 'run_id': RUN, 'dispatch_allowed': False}

        def forbidden(*args, **kwargs):
            self.fail('Provider or checkpoint was reached for an archived request')

        consume = method('tool/essay_lab/cloudflare_runtime.py', 'consume', {
            'require': require, 'UUID': UUID, 'uuid5': uuid5, 'NS': UUID(SUBJECT),
            'DatabaseCheckpoint': forbidden, 'prepare_claimed_material': forbidden,
        })
        owner = SimpleNamespace(enabled=True, allowed={SUBJECT}, public_exams=set(), rpc=rpc, provider_factory=forbidden)
        state = await consume(owner, {'subject_id': SUBJECT, 'run_id': RUN})
        self.assertEqual(state, 'archived')
        self.assertEqual(calls, ['essay_exam_session_claim'])

    async def test_checkpoint_race_only_acks_after_authoritative_archive_confirmation(self):
        for guard_state in ['archived', 'reserved', 'unavailable', 'denied']:
            with self.subTest(guard_state=guard_state):
                events = []

                async def consume(_):
                    events.extend(['claim', 'checkpoint-fence'])
                    raise ValueError('BACKEND_UNAVAILABLE')

                async def rpc(name, args):
                    self.assertEqual(name, 'essay_exam_dispatch_guard')
                    self.assertEqual(args, {'p_subject': SUBJECT, 'p_run': RUN})
                    events.append('owner-lifecycle-guard')
                    if guard_state in ('unavailable', 'denied'):
                        raise ValueError(guard_state)
                    return {'state': guard_state, 'run_id': RUN}

                queue = method('tool/cloudflare_essay/entry.py', 'queue', {
                    'json': json, 'UUID': UUID, 'require': require, 'print': lambda *_: None,
                })
                owner = SimpleNamespace(transport=lambda: SimpleNamespace(rpc=rpc),
                                        configuration=lambda _: SimpleNamespace(consume=consume))
                message = SimpleNamespace(body=json.dumps({'subject_id': SUBJECT, 'run_id': RUN}),
                                          ack=lambda: events.append('ack'), retry=lambda: events.append('retry'))
                await queue(owner, SimpleNamespace(messages=[message]))
                self.assertEqual(events, ['claim', 'checkpoint-fence', 'owner-lifecycle-guard',
                                          'ack' if guard_state == 'archived' else 'retry'])


if __name__ == '__main__':
    unittest.main()
