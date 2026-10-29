"""Offline deployment asset regression; no Worker deployment or Provider calls."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class StageTests(unittest.TestCase):
    def test_staged_current_import_and_historical_policy_assets(self):
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder) / 'worker'
            subprocess.run([sys.executable, str(ROOT / 'tool/cloudflare_essay/stage.py'), str(target)], check=True, capture_output=True)
            script = "from essay_lab.positive_learning import PROMPT, PROMPT_VERSION; assert PROMPT; from essay_lab.reviewed_runtime import reviewed_openai; from essay_lab.retry_feedback import feedback; assert feedback('EXACT_QUOTE')['code'] == 'EXACT_QUOTE'"
            subprocess.run([sys.executable, '-c', script], cwd=target/'src', check=True, capture_output=True)
            for version in ('v3','v6','v7','v10','v11','v12'):
                name=f'scaffolding-1.3-{version}.txt'
                self.assertEqual((target/'src/essay_lab/prompts'/name).read_bytes(), (ROOT/'tool/essay_lab/prompts'/name).read_bytes())
            config=json.loads((target/'wrangler.jsonc').read_text())
            self.assertEqual(config['vars']['ESSAY_EXECUTION_ENABLED'], 'false')
            self.assertFalse(config['workers_dev'])

if __name__ == '__main__': unittest.main()

class RuntimePolicyTests(unittest.TestCase):
    def test_validation_failure_receipt_needs_no_provider_hash(self):
        from tool.essay_lab.cloudflare_runtime import receipt_checkpoint_key
        from tool.essay_lab.live_worker import Invalid
        value={'component':'validation_failure','code':'UNKNOWN_CRITERION'}
        self.assertTrue(receipt_checkpoint_key(value).startswith('validation-failure-'))
        self.assertEqual(receipt_checkpoint_key(value),receipt_checkpoint_key(dict(value)))
        self.assertEqual(receipt_checkpoint_key({'output_sha256':'abc'}),'receipt-abc')
        with self.assertRaises(Invalid):
            receipt_checkpoint_key(dict(value,answer='private'))
        with self.assertRaises(Invalid):
            receipt_checkpoint_key(dict(value,code='raw secret text'))

    def test_consumer_uses_frozen_policy_and_rejects_unconfigured_before_package(self):
        import asyncio
        from tool.essay_lab.cloudflare_runtime import CloudflareExamRuntime
        from tool.essay_lab.reviewed_runtime import configured_binding
        from tool.essay_lab.live_worker import Invalid
        subject='11111111-1111-4111-8111-111111111111'
        run='22222222-2222-4222-8222-222222222222'
        calls=[]
        async def rpc(name,args):
            calls.append(name)
            if name=='essay_exam_session_claim':
                return dict(session_version='exam-session-v1',attempts={},state='reserved',subject_id=subject,lease_token='lease',snapshot=dict(ownerId=subject,runtime=dict(binding={'model':'unapproved'})))
            self.fail('No package/provider/finalize request after rejected policy')
        runtime=CloudflareExamRuntime(rpc=rpc,registry={},provider=None,reviewer=None,review_source=None,receipt_sink=None,allowed_subjects=[subject],enabled=True,provider_factory=lambda binding: configured_binding(binding,{'model':'approved'}))
        with self.assertRaises(Invalid): asyncio.run(runtime.consume(dict(subject_id=subject,run_id=run)))
        self.assertEqual(calls,['essay_exam_session_claim'])

class PublicScopeTests(unittest.TestCase):
    def test_public_consumer_rejects_unreleased_exam_before_provider(self):
        import asyncio
        from tool.essay_lab.cloudflare_runtime import CloudflareExamRuntime
        from tool.essay_lab.live_worker import Invalid
        subject='11111111-1111-4111-8111-111111111111'
        run='22222222-2222-4222-8222-222222222222'
        exam='33333333-3333-4333-8333-333333333333'
        calls=[]
        async def rpc(name,args):
            calls.append(name)
            return dict(state='reserved',exam_id=run)
        runtime=CloudflareExamRuntime(rpc=rpc,registry={},provider=None,reviewer=None,review_source=None,receipt_sink=None,allowed_subjects=[],public_exams=[exam],enabled=True)
        with self.assertRaisesRegex(Invalid,'EXAM_ACCESS_DENIED'):
            asyncio.run(runtime.consume(dict(subject_id=subject,run_id=run)))
        self.assertEqual(calls,['essay_exam_session_claim'])

    def test_public_completed_redelivery_does_not_re_evaluate(self):
        import asyncio
        from tool.essay_lab.cloudflare_runtime import CloudflareExamRuntime
        subject='11111111-1111-4111-8111-111111111111'
        run='22222222-2222-4222-8222-222222222222'
        async def rpc(name,args):
            self.assertEqual(name,'essay_exam_session_claim')
            return dict(state='completed',run_id=run)
        runtime=CloudflareExamRuntime(rpc=rpc,registry={},provider=None,reviewer=None,review_source=None,receipt_sink=None,allowed_subjects=[],public_exams=[run],enabled=True)
        self.assertEqual(asyncio.run(runtime.consume(dict(subject_id=subject,run_id=run))),'completed')

class SessionTransportTests(unittest.IsolatedAsyncioTestCase):
    async def test_session_runtime_rpc_crosses_real_transport_guard(self):
        from unittest.mock import AsyncMock
        from tool.essay_lab.cloudflare_http import AsyncOperatingTransport
        from tool.essay_lab.live_worker import Invalid
        transport=object.__new__(AsyncOperatingTransport)
        transport.worker='synthetic-worker-token'
        transport._request=AsyncMock(return_value='exam-session-v1')
        for name in ('essay_exam_session_ready','essay_exam_session_claim','essay_exam_session_checkpoint'):
            await transport.rpc(name,{})
            transport._request.assert_awaited_with('/rest/v1/rpc/'+name,'synthetic-worker-token',{})
        transport._request.reset_mock()
        for name in ('admin_report','math_session_submit','unlisted_rpc'):
            with self.assertRaises(Invalid):await transport.rpc(name,{})
        transport._request.assert_not_awaited()
