"""Offline runner check: no real server, Flutter process or credentials."""
import contextlib
import io
import unittest
from unittest.mock import patch
import run_day_target_flutter_smoke as runner

class FakeServer:
    server_port = 12345
    def __init__(self, *args): pass
    def serve_forever(self): pass
    def shutdown(self): pass
    def server_close(self): pass

class RunnerTest(unittest.TestCase):
    def test_passwords_never_enter_flutter_arguments_or_output(self):
        private = 'LOCAL_TEST_INPUT_NOT_A_CREDENTIAL'
        config = {'SUPABASE_URL': runner.HOST, 'SUPABASE_PUBLISHABLE_KEY': 'test-public'}
        accounts = {}
        for label, email in runner.EMAILS.items():
            accounts[f'TEST_{label}_EMAIL'] = email
            accounts[f'TEST_{label}_PASSWORD'] = private
        stages = ['login_preflight','home_save','container_restore','home_edit','account_switch','home_clear','profile_school_preserved','fixture_cleanup','auth_users_retained']
        class Process:
            stdout = [private, 'DDAY_RUNTIME PASS arbitrary_untrusted_value', *['DDAY_RUNTIME PASS ' + s for s in stages]]
            def wait(self): return 0
        output = io.StringIO()
        with patch('sys.argv', ['runner','external-public','--accounts','external-accounts']), \
             patch.object(runner, 'external_json', side_effect=[config, accounts]), \
             patch.object(runner, 'HTTPServer', FakeServer), \
             patch.object(runner.subprocess, 'Popen', return_value=Process()) as process, \
             contextlib.redirect_stdout(output):
            self.assertEqual(runner.main(), 0)
        self.assertNotIn(private, str(process.call_args))
        self.assertNotIn('TEST_A_PASSWORD', str(process.call_args))
        self.assertNotIn(private, output.getvalue())
        self.assertNotIn('arbitrary_untrusted_value', output.getvalue())
        self.assertIn('Flutter persistence smoke: PASS', output.getvalue())

if __name__ == '__main__': unittest.main()
