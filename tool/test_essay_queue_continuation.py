"""Exercise the actual deployed entry queue handler with no network or Provider."""
import ast
import json
from pathlib import Path
from types import SimpleNamespace
import unittest

class QueueContinuationTests(unittest.IsolatedAsyncioTestCase):
    async def check(self, fail_send=False):
        tree=ast.parse(Path('tool/cloudflare_essay/entry.py').read_text())
        method=next(n for n in ast.walk(tree) if isinstance(n,ast.AsyncFunctionDef) and n.name=='queue')
        scope={'json':json,'print':lambda *_:None}
        exec(compile(ast.fix_missing_locations(ast.Module(body=[method],type_ignores=[])),'queue','exec'),scope)
        events=[]
        async def consume(message):events.append('consume');return 'continue'
        async def send(body):
            self.assertEqual(json.loads(body),{'subject_id':'subject','run_id':'run'})
            events.append('send')
            if fail_send:raise RuntimeError('enqueue unavailable')
        message=SimpleNamespace(body=json.dumps({'subject_id':'subject','run_id':'run'}),ack=lambda:events.append('ack'),retry=lambda:events.append('retry'))
        worker=SimpleNamespace(transport=lambda:None,configuration=lambda _:SimpleNamespace(consume=consume),env=SimpleNamespace(ESSAY_QUEUE=SimpleNamespace(send=send)))
        await scope['queue'](worker,SimpleNamespace(messages=[message]))
        return events

    async def test_send_before_ack(self):self.assertEqual(await self.check(),['consume','send','ack'])
    async def test_failed_enqueue_retries_original_without_ack(self):self.assertEqual(await self.check(True),['consume','send','retry'])
