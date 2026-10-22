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
            script = "from essay_lab.positive_learning import PROMPT, PROMPT_VERSION; assert PROMPT; from essay_lab.reviewed_runtime import reviewed_openai"
            subprocess.run([sys.executable, '-c', script], cwd=target/'src', check=True, capture_output=True)
            for version in ('v3','v6','v7'):
                name=f'scaffolding-1.3-{version}.txt'
                self.assertEqual((target/'src/essay_lab/prompts'/name).read_bytes(), (ROOT/'tool/essay_lab/prompts'/name).read_bytes())
            config=json.loads((target/'wrangler.jsonc').read_text())
            self.assertEqual(config['vars']['ESSAY_EXECUTION_ENABLED'], 'false')
            self.assertFalse(config['workers_dev'])

if __name__ == '__main__': unittest.main()

class RuntimePolicyTests(unittest.TestCase):
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
            if name=='essay_exam_claim':
                return dict(state='reserved',subject_id=subject,lease_token='lease',snapshot=dict(ownerId=subject,runtime=dict(binding={'model':'unapproved'})))
            self.fail('No package/provider/finalize request after rejected policy')
        runtime=CloudflareExamRuntime(rpc=rpc,registry={},provider=None,reviewer=None,review_source=None,receipt_sink=None,allowed_subjects=[subject],enabled=True,provider_factory=lambda binding: configured_binding(binding,{'model':'approved'}))
        with self.assertRaises(Invalid): asyncio.run(runtime.consume(dict(subject_id=subject,run_id=run)))
        self.assertEqual(calls,['essay_exam_claim'])

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
        self.assertEqual(calls,['essay_exam_claim'])

    def test_public_completed_redelivery_does_not_re_evaluate(self):
        import asyncio
        from tool.essay_lab.cloudflare_runtime import CloudflareExamRuntime
        subject='11111111-1111-4111-8111-111111111111'
        run='22222222-2222-4222-8222-222222222222'
        async def rpc(name,args):
            self.assertEqual(name,'essay_exam_claim')
            return dict(state='completed',run_id=run)
        runtime=CloudflareExamRuntime(rpc=rpc,registry={},provider=None,reviewer=None,review_source=None,receipt_sink=None,allowed_subjects=[],public_exams=[run],enabled=True)
        self.assertEqual(asyncio.run(runtime.consume(dict(subject_id=subject,run_id=run))),'completed')
