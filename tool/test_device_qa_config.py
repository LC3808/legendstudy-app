"""No signing/build/Auth network call: complete and incomplete synthetic configs."""
import runpy
import tempfile
from pathlib import Path
import unittest

module = runpy.run_path(str(Path(__file__).with_name('device-qa')))


class DeviceQaConfigTests(unittest.TestCase):
    def fixture(self):
        return dict(APP_ENV='production', GOOGLE_OAUTH_ENABLED=True, APPLE_OAUTH_ENABLED=True,
            KAKAO_OAUTH_ENABLED=True, ESSAY_LIVE_WRITES_ENABLED=True, ESSAY_EVALUATION_REQUESTS_ENABLED=True,
            GOOGLE_IOS_CLIENT_ID='synthetic.apps.googleusercontent.com', GOOGLE_SERVER_CLIENT_ID='synthetic-server',
            SUPABASE_PUBLISHABLE_KEY='synthetic-public', SUPABASE_URL='https://stlhijzpjfgwwdgunlsd.supabase.co')

    def test_incomplete_debug_or_release_flags_fail_before_build(self):
        config = self.fixture()
        module['validate'](config)
        for key in config:
            incomplete = dict(config)
            del incomplete[key]
            with self.assertRaises(ValueError, msg=key): module['validate'](incomplete)

    def test_review_test_backend_or_false_string_cannot_be_mislabelled_qa(self):
        for changes in ({'REVIEW_READ_ONLY':True}, {'APPLE_OAUTH_ENABLED':'false'},
                        {'APP_ENV':'test'}, {'SUPABASE_URL':'https://other.supabase.co'}):
            with self.assertRaises(ValueError): module['validate'](self.fixture() | changes)

    def test_native_scheme_and_both_modes_must_match(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = root/'ios/Flutter'
            folder.mkdir(parents=True)
            with self.assertRaises(ValueError): module['validate_native'](self.fixture(), root)
            (folder/'Auth.local.xcconfig').write_text('GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.synthetic\n')
            for mode in ('Debug','Release'):
                (folder/f'{mode}.xcconfig').write_text('#include? "Auth.local.xcconfig"\n')
            module['validate_native'](self.fixture(), root)
            (folder/'Release.xcconfig').write_text('')
            with self.assertRaises(ValueError): module['validate_native'](self.fixture(), root)


if __name__ == '__main__': unittest.main()
