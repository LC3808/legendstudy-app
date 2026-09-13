"""Offline verifier tests; no network, credentials, or production mutations."""
import contextlib
import copy
import io
import json
import ssl
import unittest
import urllib.error
import urllib.parse
from unittest.mock import patch
import verify_day_target_jwt as verifier

IDS = {"A": "00000000-0000-4000-8000-000000000001", "B": "00000000-0000-4000-8000-000000000002"}
SENSITIVE = "DO_NOT_PRINT_TEST_CREDENTIAL"


class Response:
    status = 200
    def __init__(self, body):
        self.body = body
    def __enter__(self):
        return self
    def __exit__(self, *args):
        pass
    def read(self):
        return json.dumps(self.body).encode()


class VerifierTest(unittest.TestCase):
    def setUp(self):
        self.config = {"SUPABASE_URL": verifier.HOST, "SUPABASE_PUBLISHABLE_KEY": "sb_" + "publishable_" + SENSITIVE}
        self.accounts = {}
        for label, email in verifier.EMAILS.items():
            self.accounts[f"TEST_{label}_EMAIL"] = email
            self.accounts[f"TEST_{label}_PASSWORD"] = SENSITIVE
        self.requests = []
        self.users = {label: {"user": {"id": IDS[label], "email": email}, "access_token": SENSITIVE + label} for label, email in verifier.EMAILS.items()}
        self.rows = {IDS[label]: [] for label in IDS}

    def transport(self, request, timeout):
        self.requests.append(request)
        if '/auth/v1/token' in request.full_url:
            email = json.loads(request.data)['email']
            label = next(k for k, v in verifier.EMAILS.items() if v == email)
            return Response(copy.deepcopy(self.users[label]))
        if '/auth/v1/logout' in request.full_url:
            return Response(None)
        query = urllib.parse.parse_qs(urllib.parse.urlsplit(request.full_url).query)
        if request.method == 'GET':
            self.assertEqual(query['select'], [verifier.FIELDS])
            owner = query['id'][0].removeprefix('eq.')
            return Response(self.rows[owner])
        self.fail('Unexpected profile write')

    def execute(self, transport=None, preflight=True):
        output = io.StringIO()
        error = None
        with patch.object(verifier.urllib.request, 'urlopen', transport or self.transport), contextlib.redirect_stdout(output):
            try:
                verifier.run(self.config, self.accounts, preflight_only=preflight)
            except Exception as caught:
                error = verifier.failure_code(caught)
        text = output.getvalue()
        self.assertNotIn(SENSITIVE, text)
        self.assertNotIn('Authorization', text)
        return error, text

    def test_healthy_preflight_encodes_complete_projection_and_reads_both(self):
        error, text = self.execute()
        self.assertIsNone(error)
        self.assertIn('A profile read status=200 count=0', text)
        self.assertIn('B profile read status=200 count=0', text)
        self.assertIn('Preflight-only PASS', text)
        self.assertFalse(any(r.method != 'GET' and '/rest/' in r.full_url for r in self.requests))

    def test_email_case_and_surrounding_whitespace_normalized(self):
        self.accounts['TEST_A_EMAIL'] = '  ' + verifier.EMAILS['A'].upper() + ' '
        self.users['A']['user']['email'] = verifier.EMAILS['A'].upper()
        self.assertIsNone(self.execute()[0])

    def test_wrong_input_email_rejected_without_network(self):
        self.accounts['TEST_B_EMAIL'] = 'wrong@example.invalid'
        self.assertEqual(self.execute()[0], 'B_INPUT_EMAIL_MISMATCH')
        self.assertEqual(self.requests, [])

    def test_existing_profile_refuses_all_writes_and_still_reports_b(self):
        self.rows[IDS['A']] = [{'id': IDS['A']}]
        error, text = self.execute()
        self.assertEqual(error, 'A_PROFILE_NOT_EMPTY')
        self.assertIn('B profile read status=200 count=0', text)
        self.assertIn('NOT NEEDED', text)
        self.assertFalse(any(r.method != 'GET' and '/rest/' in r.full_url for r in self.requests))

    def test_malformed_login_fields_are_distinct(self):
        cases = [({}, 'A_LOGIN_USER_MISSING'),
                 ({'user': {}, 'access_token': 'x'}, 'A_USER_ID_MISSING'),
                 ({'user': {'id': IDS['A']}}, 'A_ACCESS_TOKEN_MISSING'),
                 ({'user': {'id': 'invalid'}, 'access_token': 'x'}, 'A_USER_ID_INVALID')]
        for body, expected in cases:
            with self.subTest(expected=expected):
                self.users['A'] = body
                self.assertEqual(self.execute()[0], expected)

    def test_login_email_mismatch_reports_no_actual_email(self):
        self.users['A']['user']['email'] = SENSITIVE
        self.assertEqual(self.execute()[0], 'A_LOGIN_EMAIL_MISMATCH')

    def test_same_user_id_rejected_before_profile_read(self):
        self.users['B']['user']['id'] = IDS['A']
        self.assertEqual(self.execute()[0], 'A_B_SAME_USER_ID')

    def test_non_array_profile_body(self):
        self.rows[IDS['A']] = {'message': SENSITIVE}
        self.assertEqual(self.execute()[0], 'A_PROFILE_READ_NOT_ARRAY')

    def test_profile_http_error_retains_status_not_body(self):
        def transport(request, timeout):
            if request.method == 'GET':
                raise urllib.error.HTTPError(request.full_url, 403, SENSITIVE, {}, io.BytesIO(json.dumps({'message': SENSITIVE}).encode()))
            return self.transport(request, timeout)
        error, text = self.execute(transport)
        self.assertEqual(error, 'A_PROFILE_READ_HTTP')
        self.assertIn('A profile read status=403', text)

    def test_html_response_retains_status(self):
        class HTML(Response):
            def read(self):
                return SENSITIVE.encode()
        error, text = self.execute(lambda *_args, **_kwargs: HTML(None))
        self.assertEqual(error, 'RESPONSE_NOT_JSON')
        self.assertIn('status=200', text)

    def test_tls_and_timeout_safe_diagnostics(self):
        for cause, code in [(urllib.error.URLError(ssl.SSLCertVerificationError(1, SENSITIVE)), 'TLS_CERTIFICATE_VERIFICATION_FAILED'),
                            (TimeoutError(SENSITIVE), 'NETWORK_TIMEOUT')]:
            with self.subTest(code=code):
                def transport(*args, **kwargs):
                    raise cause
                self.assertEqual(self.execute(transport)[0], code)

    def test_uncertain_first_upsert_cleans_only_registered_fixture(self):
        deleted = []
        def transport(request, timeout):
            if '/rest/' in request.full_url and request.method == 'POST':
                raise TimeoutError(SENSITIVE)
            if request.method == 'DELETE':
                deleted.append(urllib.parse.parse_qs(urllib.parse.urlsplit(request.full_url).query)['id'][0])
                return Response(None)
            return self.transport(request, timeout)
        error, text = self.execute(transport, preflight=False)
        self.assertEqual(error, 'NETWORK_TIMEOUT')
        self.assertEqual(deleted, ['eq.' + IDS['A']])
        self.assertIn('Fixture cleanup: PASS', text)


if __name__ == '__main__':
    unittest.main()
