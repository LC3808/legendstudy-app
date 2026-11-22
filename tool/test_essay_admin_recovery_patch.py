"""Offline candidate packaging preserves unmodified deployed runtime bytes."""
from copy import deepcopy
from hashlib import sha256
import unittest
from tool.cloudflare_essay.admin_recovery_patch import prepare, EXISTING, NEW


class RecoveryPatchTests(unittest.TestCase):
    def fixture(self):
        baseline = {
            'entry.py': b'from essay_lab.admin_run_actions import retry_admin_run\nclass Default:\n    async def fetch(self):\n        return "old"\n    async def queue(self):\n        return "baseline queue"\n',
            'essay_lab/cloudflare_http.py': b'class AsyncOperatingTransport:\n    async def rpc(self):\n        return "old"\n    async def _request(self):\n        return "baseline origin"\n',
            'essay_lab/admin_run_actions.py': b'def retry():\n    return "old"\n',
            'essay_lab/mixed_math_runtime.py': b'def evaluate():\n    return "unchanged criteria"\n',
        }
        live = dict(baseline)
        live['entry.py'] = live['entry.py'].replace(b'baseline queue', b'live queue preserved')
        live['essay_lab/cloudflare_http.py'] = live['essay_lab/cloudflare_http.py'].replace(b'baseline origin', b'live origin preserved')
        live['essay_lab/live_worker.py'] = b'approved provider and diagnostics bytes'
        live['essay_lab/prompts/current.txt'] = b'approved prompt bytes'
        current = {p: data.replace(b'"old"', b'"new"') for p, data in baseline.items()}
        current['essay_lab/mixed_math_runtime.py'] += b'\ndef pure_guard():\n    return "unchanged criteria"\n'
        current[NEW] = b'def verify():\n    return "no provider"\n'
        return live, baseline, current, {p: sha256(data).hexdigest() for p, data in live.items()}

    def test_narrow_patch_preserves_runtime_differences_and_all_other_files(self):
        live, baseline, current, hashes = self.fixture()
        before = deepcopy(live)
        candidate, manifest = prepare(live, baseline, current, hashes)
        self.assertEqual(live, before)
        self.assertEqual({x['module'] for x in manifest['changes']}, set(EXISTING) | {NEW})
        self.assertIn(b'live queue preserved', candidate['entry.py'])
        self.assertIn(b'live origin preserved', candidate['essay_lab/cloudflare_http.py'])
        for path in manifest['preserved']:
            self.assertEqual(candidate[path], live[path])
        self.assertFalse(manifest['deployment_performed'])

    def test_unknown_preimage_or_method_drift_fails_closed(self):
        live, baseline, current, hashes = self.fixture()
        bad = dict(hashes, **{'entry.py': '0' * 64})
        with self.assertRaisesRegex(ValueError, 'preimage'):
            prepare(live, baseline, current, bad)
        live['entry.py'] = live['entry.py'].replace(b'"old"', b'"unreviewed fetch"')
        hashes['entry.py'] = sha256(live['entry.py']).hexdigest()
        with self.assertRaisesRegex(ValueError, 'method drift'):
            prepare(live, baseline, current, hashes)

    def test_changed_math_module_or_extra_input_module_cannot_be_silently_replaced(self):
        for path in ('essay_lab/mixed_math_runtime.py', 'essay_lab/admin_run_actions.py'):
            live, baseline, current, hashes = self.fixture()
            live[path] += b'# unreviewed live behavior\n'
            hashes[path] = sha256(live[path]).hexdigest()
            with self.assertRaisesRegex(ValueError, 'module drift'):
                prepare(live, baseline, current, hashes)
        live, baseline, current, hashes = self.fixture()
        live['unknown.py'] = b'new live module'
        with self.assertRaisesRegex(ValueError, 'preimage'):
            prepare(live, baseline, current, hashes)


if __name__ == '__main__':
    unittest.main()
