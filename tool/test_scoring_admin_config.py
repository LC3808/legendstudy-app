"""Offline shared external-host configuration tests; no network or database."""
import contextlib
import io
import json
import unittest
from argparse import Namespace
from pathlib import Path
from unittest.mock import Mock, patch

import verify_mock_scoring_jwt as d1
import run_mock_scoring_flutter_smoke as d2
import run_mock_grade_flutter_smoke as d3

HOST = 'aws-1-us-east-1.pooler.supabase.com'
CANARY = 'offline-private-canary'


class AdminConfigTests(unittest.TestCase):
    def test_config_host_skips_prompt_and_retains_project_pin(self):
        with patch('builtins.input') as prompt:
            host = d1.admin_host_from_config({'SUPABASE_SESSION_POOLER_HOST': ' ' + HOST + ' '})
        prompt.assert_not_called()
        settings = d1.admin_settings(host, CANARY)
        self.assertEqual(settings['host'], HOST)
        self.assertEqual(settings['user'], 'postgres.' + d1.REF)
        self.assertEqual(settings['port'], 5432)
        self.assertEqual(settings['sslmode'], 'require')

    def test_missing_host_prompts_with_original_direct_fallback(self):
        for value, expected in [(HOST, HOST), ('', 'db.' + d1.REF + '.supabase.co')]:
            with patch('builtins.input', return_value=value) as prompt:
                self.assertEqual(d1.admin_host_from_config({}), expected)
            prompt.assert_called_once()

    def test_invalid_present_host_fails_without_prompt_or_value_disclosure(self):
        for value in [None, 1, '', ' ', 'https://' + HOST, HOST + ':5432', CANARY, HOST + '\noptions=' + CANARY]:
            with self.subTest(value_type=type(value).__name__), patch('builtins.input') as prompt:
                with self.assertRaises(Exception) as error:
                    d1.admin_host_from_config({'SUPABASE_SESSION_POOLER_HOST': value})
                self.assertEqual(str(error.exception), 'ADMIN_HOST')
                prompt.assert_not_called()

    def test_all_three_entrypoints_use_loader_and_keep_three_getpass_prompts(self):
        for module in [d1, d2, d3]:
            for configured in [True, False]:
                with self.subTest(module=module.__name__, configured=configured):
                    raw = {'SUPABASE_URL': d1.HOST, 'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_offline'}
                    if configured:
                        raw['SUPABASE_SESSION_POOLER_HOST'] = HOST
                    args = Namespace(public_config=Path('/private/tmp/offline-config.json'), device='offline', preflight_only=True)
                    app = Mock(sessions={'A': {'id': 'offline-A'}, 'B': {'id': 'offline-B'}})
                    app.read.return_value = []
                    app.finish_auth.return_value = True
                    admin = Mock(started=False)
                    db = Mock()
                    output = io.StringIO()
                    fixture_class = 'AdminFixtures' if module is d1 else 'RuntimeFixtures'
                    with patch.object(module.argparse.ArgumentParser, 'parse_args', return_value=args), \
                         patch.object(module.sys.stdin, 'isatty', return_value=True), \
                         patch.object(Path, 'read_text', return_value=json.dumps(raw)), \
                         patch.object(module, 'Acceptance', return_value=app), \
                         patch.object(module, fixture_class, return_value=admin), \
                         patch.object(module.psycopg, 'connect', return_value=db) as connect, \
                         patch.object(module.getpass, 'getpass', return_value=CANARY) as password, \
                         patch('builtins.input', return_value=HOST) as prompt, \
                         contextlib.redirect_stdout(output):
                        self.assertEqual(module.main(), 0)
                    self.assertEqual(password.call_count, 3)
                    self.assertEqual(prompt.call_count, 0 if configured else 1)
                    self.assertEqual(connect.call_args.kwargs['host'], HOST)
                    self.assertEqual(connect.call_args.kwargs['password'], CANARY)
                    self.assertNotIn(CANARY, output.getvalue())
                    self.assertNotIn(HOST, output.getvalue())
                    admin.create.assert_not_called()


if __name__ == '__main__':
    unittest.main()
