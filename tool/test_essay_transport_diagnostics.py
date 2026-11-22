"""Actual Cloudflare adapter with synthetic fetch/timer proxies, no network."""
import json
from types import SimpleNamespace
from unittest.mock import patch
import unittest

from tool.essay_lab.cloudflare_http import provider_transport
from tool.essay_lab.cloudflare_runtime import receipt_checkpoint_key
from tool.essay_lab.live_worker import OpenAIResponses, Unknown, ProviderFailure, execution_failure
from tool.essay_lab.transport_diagnostics import attach_transport_diagnostic, validate_transport_diagnostic
from tool import test_essay_reviewed_runtime as runtime_fixture
from tool import test_essay_session_retry as session_fixture


class TransportDiagnosticTests(unittest.IsolatedAsyncioTestCase):
    async def invoke(self, mode, status=200):
        events=[]; signal=SimpleNamespace(aborted=False); timer=[]

        def abort():signal.aborted=True
        controller=SimpleNamespace(signal=signal,abort=SimpleNamespace(bind=lambda _:abort))
        class Reader:
            async def read(self):
                if mode=='body_timeout':timer[0]();raise RuntimeError('private response fragment')
                if mode=='body_read':raise RuntimeError('private response fragment')
                if mode=='oversize':return SimpleNamespace(done=False,value=SimpleNamespace(to_py=lambda:b'x'*524289))
                return SimpleNamespace(done=True)
            async def cancel(self):events.append('cancel')

        async def fetch(*args,**kwargs):
            events.append('fetch')
            if mode=='timeout':timer[0]();raise RuntimeError('private token')
            if mode=='network':raise RuntimeError('AbortError unrelated to our deadline')
            return SimpleNamespace(status=status,js_response=SimpleNamespace(body=SimpleNamespace(getReader=lambda:Reader())))

        def set_timer(callback,milliseconds):timer.append(callback);events.append(milliseconds);return 'timer'
        js=SimpleNamespace(AbortController=SimpleNamespace(new=lambda:controller),
                           setTimeout=set_timer,clearTimeout=lambda _:events.append('clear'))
        provider=OpenAIResponses('synthetic-only-key','synthetic-model',{},transport=provider_transport)
        with patch.dict('sys.modules',{'workers':SimpleNamespace(fetch=fetch),'js':js}), \
             patch('tool.essay_lab.cloudflare_http.time.monotonic',side_effect=[100,100,175.001]):
            try:await provider.evaluate_async({})
            except (Unknown,ProviderFailure) as error:return error,events
        self.fail('Expected a bounded synthetic failure')

    async def test_transport_categories_preserve_unknown_and_record_no_contents(self):
        expected={'timeout':('PROVIDER_TIMEOUT','request','timeout',None),
                  'network':('PROVIDER_NETWORK_UNKNOWN','request','network',None),
                  'body_timeout':('PROVIDER_TIMEOUT','response_body','timeout',200),
                  'body_read':('PROVIDER_BODY_READ_UNKNOWN','response_body','body_read',200),
                  'oversize':('PROVIDER_RESPONSE_TOO_LARGE','response_body','response_too_large',200)}
        for mode,(code,phase,kind,status) in expected.items():
            with self.subTest(mode=mode):
                error,events=await self.invoke(mode)
                self.assertIsInstance(error,Unknown)
                value=execution_failure(error,'provider')
                self.assertEqual(value['code'],code)
                self.assertEqual(value['transport'],dict(kind=kind,phase=phase,elapsed_ms=75001,deadline_ms=75000,http_status=status))
                self.assertEqual(receipt_checkpoint_key(value),'execution-failure')
                self.assertEqual(events.count('fetch'),1)
                self.assertIn(75000,events);self.assertEqual(events[-1],'clear')
                self.assertNotIn('private',json.dumps(value));self.assertNotIn('synthetic-only-key',json.dumps(value))

    async def test_http_status_keeps_429_failed_and_5xx_unknown_without_retry(self):
        for status in [429,500,503]:
            with self.subTest(status=status):
                error,events=await self.invoke('http',status)
                self.assertIsInstance(error,ProviderFailure if status==429 else Unknown)
                value=execution_failure(error,'provider')
                self.assertEqual(value['transport']['http_status'],status)
                self.assertEqual(value['transport']['kind'],'http_status')
                self.assertEqual(receipt_checkpoint_key(value),'execution-failure')
                self.assertEqual(events.count('fetch'),1)

    async def test_failure_receipt_save_error_restart_never_redispatches_or_settles(self):
        journal=session_fixture.Journal();settled=[];receipts=[]
        original=runtime_fixture.RuntimeTests.fixture

        def fixture(test,mode='ok'):
            result=original(test,mode)
            def fail_receipt(value):
                receipts.append(value)
                raise Unknown('SYNTHETIC_DB_SAVE_FAILED')
            result[0].receipt_sink=fail_receipt
            return result

        with patch.object(runtime_fixture.RuntimeTests,'fixture',fixture):
            run,requests=session_fixture.SessionRetryTests().prepare(['timeout'],journal,{},settled)
            with self.assertRaisesRegex(Unknown,'SYNTHETIC_DB_SAVE_FAILED'):
                await run()
        self.assertEqual(len(requests[0]),1)
        self.assertEqual(receipts[0]['component'],'execution_failure')
        self.assertEqual(journal.rows['q0']['state'],'pending')
        self.assertEqual(settled,[])

        # A new worker cannot infer whether the prior Provider call completed.
        # It must keep that intent and reservation rather than regenerate/refund.
        run,replayed=session_fixture.SessionRetryTests().prepare(['ok'],journal,{},settled)
        self.assertEqual(await run(),'reconciling')
        self.assertEqual(len(replayed[0]),0)
        self.assertEqual(journal.rows['q0']['state'],'pending')
        self.assertEqual(settled,[])

    def test_canonical_receipt_rejects_unbounded_data_and_preserves_existing_usage(self):
        diagnostic=dict(kind='network',phase='request',elapsed_ms=10,deadline_ms=75000,http_status=None)
        usage=object();error=attach_transport_diagnostic(Unknown('PROVIDER_NETWORK_UNKNOWN',usage=usage),diagnostic)
        self.assertIs(error.usage,usage)
        self.assertEqual(receipt_checkpoint_key(execution_failure(Unknown('PROVIDER_NETWORK_UNKNOWN'),'provider')),'execution-failure')
        for invalid in [dict(diagnostic,message='secret'),dict(diagnostic,elapsed_ms=True),dict(diagnostic,deadline_ms=120001),dict(diagnostic,http_status='429'),dict(diagnostic,phase='unbounded text'),dict(diagnostic,kind=['network'])]:
            with self.subTest(invalid=invalid):
                with self.assertRaises((ValueError,TypeError)):validate_transport_diagnostic(invalid)
                value=execution_failure(error,'provider');value['transport']=invalid
                with self.assertRaises((ValueError,TypeError)):receipt_checkpoint_key(value)


if __name__=='__main__':unittest.main()
