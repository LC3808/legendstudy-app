"""Offline release-config regressions: synthetic public values; never build."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('store-release')

class ReleaseConfigTests(unittest.TestCase):
    def check(self, config):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'config.json'
            path.write_text(json.dumps(config))
            return subprocess.run([str(SCRIPT), 'ios', '--check', '--config', str(path)], capture_output=True, text=True)

    def fixture(self):
        return dict(APP_ENV='production', GOOGLE_OAUTH_ENABLED=True, APPLE_OAUTH_ENABLED=True,
                    KAKAO_OAUTH_ENABLED=True, GOOGLE_SERVER_CLIENT_ID='synthetic-server', GOOGLE_IOS_CLIENT_ID='synthetic-ios')

    def test_all_existing_social_settings_required(self):
        good = self.fixture()
        self.assertEqual(self.check(good).returncode, 0)
        for name in ('GOOGLE_OAUTH_ENABLED', 'APPLE_OAUTH_ENABLED', 'KAKAO_OAUTH_ENABLED',
                     'GOOGLE_SERVER_CLIENT_ID', 'GOOGLE_IOS_CLIENT_ID'):
            missing = dict(good)
            del missing[name]
            result = self.check(missing)
            self.assertNotEqual(result.returncode, 0, name)
            self.assertNotIn('synthetic-server', result.stderr)

    def test_false_string_is_not_truthy(self):
        config = self.fixture()
        config['APPLE_OAUTH_ENABLED'] = 'false'
        self.assertNotEqual(self.check(config).returncode, 0)

if __name__ == '__main__':
    unittest.main()
