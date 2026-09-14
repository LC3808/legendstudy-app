"""Offline loopback/fixture safety tests; never uses production credentials or HTTP."""
import contextlib
import io
import json
import unittest
import urllib.error
import urllib.request
import uuid
from unittest.mock import Mock, patch
from argparse import Namespace
from pathlib import Path

import test_verify_mock_scoring_jwt as d1
import run_mock_scoring_flutter_smoke as runner


class BridgeTests(unittest.TestCase):
    def test_one_use_config_and_authorized_bounded_control(self):
        admin = Mock()
        bridge = runner.Bridge({'private': 'offline-canary'}, admin)
        try:
            with urllib.request.urlopen(bridge.url) as response:
                self.assertEqual(json.load(response), {'private': 'offline-canary'})
            with self.assertRaises(urllib.error.HTTPError):
                urllib.request.urlopen(bridge.url)
            request = urllib.request.Request(bridge.url, data=b'{"action":"checkpoint"}')
            with urllib.request.urlopen(request) as response:
                self.assertEqual(json.load(response), {'ok': True})
            admin.control.assert_called_once_with({'action': 'checkpoint'})
            with self.assertRaises(urllib.error.HTTPError):
                urllib.request.urlopen(urllib.request.Request(bridge.url+'wrong', data=b'{}'))
            with self.assertRaises(urllib.error.HTTPError):
                urllib.request.urlopen(urllib.request.Request(bridge.url, data=b'x'*513))
            self.assertTrue(bridge.failed)
        finally:
            bridge.close()

    def test_error_redaction_and_control_before_config_denied(self):
        admin = Mock()
        admin.control.side_effect = RuntimeError('offline-secret-canary')
        bridge = runner.Bridge({}, admin)
        try:
            with self.assertRaises(urllib.error.HTTPError):
                urllib.request.urlopen(urllib.request.Request(bridge.url, data=b'{}'))
            admin.control.assert_not_called()
            urllib.request.urlopen(bridge.url).close()
            with self.assertRaises(urllib.error.HTTPError) as error:
                urllib.request.urlopen(urllib.request.Request(bridge.url, data=b'{}'))
            self.assertNotIn(b'offline-secret-canary', error.exception.read())
        finally:
            bridge.close()

    def test_native_output_requires_every_stage_and_zero_exit(self):
        bridge = Mock(url='http://127.0.0.1:1/offline', failed=False)
        for code, missing in [(0, False), (1, False), (0, True)]:
            process = Mock()
            stages = runner.STAGES - ({'retry'} if missing else set())
            process.stdout = io.StringIO('\n'.join('D2_FLUTTER PASS '+s for s in stages))
            process.wait.return_value = code
            process.poll.return_value = code
            with patch.object(runner.subprocess, 'Popen', return_value=process) as launch, \
                 patch.object(runner.subprocess, 'run') as terminate, \
                 contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(runner.run_flutter(bridge, 'offline-device'), code == 0 and not missing)
            self.assertNotIn('PASSWORD', ' '.join(launch.call_args.args[0]))
            self.assertEqual(terminate.call_args.args[0][-1], 'com.legendstudy.app')

    def test_output_allowlist(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            seen = runner.safe_forward('secret D2_FLUTTER PASS auth_submit\n'
                'D2_FLUTTER PASS auth_submit secret\nD2_FLUTTER PASS auth_submit\n'
                'D2_FLUTTER FAIL auth_result\nD2_FLUTTER PASS invented', runner.STAGES)
        self.assertEqual(seen, {('PASS', 'auth_submit'), ('FAIL', 'auth_result')})
        self.assertNotIn('secret', output.getvalue())
        self.assertNotIn('invented', output.getvalue())


class RuntimeStorageTests(unittest.TestCase):
    # Reuse the isolated Unix-socket database harness, not its acceptance tests.
    setUpClass = classmethod(d1.StorageTests.setUpClass.__func__)
    tearDownClass = classmethod(d1.StorageTests.tearDownClass.__func__)
    setUp = d1.StorageTests.setUp
    tearDown = d1.StorageTests.tearDown

    def runtime(self):
        admin = runner.RuntimeFixtures(self.db)
        admin.preflight(d1.OWNERS)
        admin.create()
        return admin

    def test_runner_failure_still_cleans_and_restores(self):
        args = Namespace(public_config=Path('/private/tmp/offline-public.json'),
                         device='offline-device', preflight_only=False)
        output = io.StringIO()
        with patch.object(runner.argparse.ArgumentParser, 'parse_args', return_value=args), \
             patch.object(Path, 'read_text', return_value=json.dumps(d1.CONFIG)), \
             patch.object(runner.sys.stdin, 'isatty', return_value=True), \
             patch.object(runner.getpass, 'getpass', return_value=d1.SECRET), \
             patch('builtins.input', return_value=''), \
             patch.object(runner, 'Acceptance', side_effect=lambda config: d1.Acceptance(config, self.transport)), \
             patch.object(runner.psycopg, 'connect', return_value=self.db), \
             patch.object(runner, 'run_flutter', side_effect=RuntimeError(d1.SECRET)), \
             contextlib.redirect_stdout(output):
            self.assertEqual(runner.main(), 1)
        self.assertIn('D2_FLUTTER PASS fixture_cleanup', output.getvalue())
        self.assertIn('D2_FLUTTER PASS cleanup_triggers_restored', output.getvalue())
        self.assertIn('D2_FLUTTER PASS existing_data_preserved', output.getvalue())
        self.assertNotIn(d1.SECRET, output.getvalue())
        self.assertNotIn('Flutter scoring smoke: PASS', output.getvalue())
        self.assertEqual(self.httpdb.execute('select count(*) from public.answer_key_versions').fetchone()[0], 0)

    def test_registered_studies_cleanup_and_baseline(self):
        admin = self.runtime()
        for _ in range(2):
            value = str(uuid.uuid4())
            admin.register('study', value)
            self.db.execute('''insert into public.study_sessions(id,user_id,mode,started_at,ended_at,active_segments)
                values(%s,%s,'study','2026-09-14T00:00:00Z','2026-09-14T00:01:00Z','[[0,60000]]')''',
                (value, d1.OWNERS['A']))
            admin.capture()
            admin.register('study', value)  # Exact retry keeps the same scope.
        with self.assertRaises(Exception):
            admin.register('study', str(uuid.uuid4()))
        before = admin.trigger_state()
        with contextlib.redirect_stdout(io.StringIO()):
            admin.cleanup()
        self.assertEqual(admin.snapshot(), admin.baseline)
        self.assertEqual(admin.trigger_state(), before)

    def test_other_owner_registered_study_stops_cleanup(self):
        admin = self.runtime()
        value = str(uuid.uuid4())
        admin.register('study', value)
        self.db.execute('''insert into public.study_sessions(id,user_id,mode,started_at,ended_at,active_segments)
            values(%s,%s,'study','2026-09-14T00:00:00Z','2026-09-14T00:01:00Z','[[0,60000]]')''',
            (value, d1.OWNERS['B']))
        admin.capture()
        before = admin.snapshot()
        with self.assertRaises(Exception):
            admin.cleanup()
        self.assertEqual(admin.snapshot(), before)
        self.assertEqual(admin.trigger_state(), admin.original_triggers)

    def test_existing_uuid_never_adopted(self):
        admin = self.runtime()
        value = str(uuid.uuid4())
        self.db.execute('''insert into public.study_sessions(id,user_id,mode,started_at,ended_at,active_segments)
            values(%s,%s,'study','2026-09-14T00:00:00Z','2026-09-14T00:01:00Z','[[0,60000]]')''',
            (value, d1.OWNERS['A']))
        with self.assertRaises(Exception):
            admin.register('study', value)
        self.assertNotIn(value, admin.studies)

    def test_current_switch_order_and_exact_retry(self):
        admin = self.runtime()
        self.app.admin = admin
        with self.assertRaises(Exception):
            admin.control({'action': 'switch'})
        payload = self.app.payload()
        with contextlib.redirect_stdout(io.StringIO()):
            result = self.app.result(payload)
        admin.control({'action': 'switch'})
        self.assertTrue(admin.switched)
        self.assertEqual(self.app.result(payload), result)
        with self.assertRaises(Exception):
            admin.control({'action': 'switch'})
        with self.assertRaises(Exception):
            admin.control({'action': 'arbitrary', 'sql': 'not executed'})
        with contextlib.redirect_stdout(io.StringIO()):
            admin.cleanup()
        self.assertEqual(admin.snapshot(), admin.baseline)


if __name__ == '__main__':
    unittest.main()
