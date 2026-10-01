"""Offline safety tests; synthetic users/JWT/answers only, no network."""
import base64
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
import urllib.error
from unittest.mock import patch

from verify_quality_gateway import HOST, CheckFailed, NoRedirect, main, private_json, verify


def token(subject):
    segment = base64.urlsafe_b64encode(json.dumps({'sub': subject, 'role': 'authenticated'}).encode()).decode().rstrip('=')
    return 'synthetic.'+segment+'.signature-'+subject


class Response:
    status = 200
    def __init__(self, body): self.body = body
    def __enter__(self): return self
    def __exit__(self, *args): pass
    def read(self): return json.dumps(self.body).encode()


class Gateway:
    def __init__(self, with_case=False):
        self.with_case = with_case
        self.requests = []
    def open(self, request, timeout):
        self.requests.append(request)
        path = request.full_url.removeprefix(HOST)
        auth = request.get_header('Authorization')
        body = json.loads(request.data) if request.data else {}
        if path.startswith('/auth/v1/token'):
            role = 'admin' if body['email'].startswith('admin') else 'student'
            return Response({'access_token': token(role)})
        if path == '/auth/v1/user':
            role = 'admin' if auth == 'Bearer '+token('admin') else 'student'
            return Response({'id': role, 'email': role+'@example.invalid'})
        code = 401
        if auth in ('Bearer '+token('admin'), 'Bearer '+token('student')):
            role = 'admin' if auth == 'Bearer '+token('admin') else 'student'
            if 'user_id' in body:
                code = 404
            elif path.endswith('is_quality_operator'):
                return Response(role == 'admin')
            elif role == 'student':
                code = 403
            elif path.endswith('ql_list_cases'):
                return Response({'dto_version': 'ql-read-v1', 'cases': [{'evaluation_id': 'synthetic-case'}] if self.with_case else []})
            else:
                answer = '합성 답안 ONLY'
                return Response({'student_submission': {'answer_full_text': answer, 'body_sha256': hashlib.sha256(answer.encode()).hexdigest()}})
        raise urllib.error.HTTPError(request.full_url, code, 'NEVER EMIT', {}, io.BytesIO(b'PRIVATE_ERROR_BODY'))


CONFIG = {'SUPABASE_URL': HOST, 'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_synthetic'}
ACCOUNTS = {f'QUALITY_{role}_{field}': role.lower()+'@example.invalid' if field == 'EMAIL' else 'synthetic-password'
            for role in ('ADMIN', 'STUDENT') for field in ('EMAIL', 'PASSWORD')}


class Safety(unittest.TestCase):
    def test_no_case_still_denies_all_unauthorized_reads(self):
        gateway = Gateway()
        result = verify(CONFIG, ACCOUNTS, gateway)
        self.assertEqual(result['FULL_ANSWER_OPERATOR_ACCESS'], 'NOT_ASSESSABLE')
        self.assertEqual(result['PRODUCTION_GATEWAY_AUTHORIZATION'], 'PASS')
        self.assertTrue(all(r.method in ('GET', 'POST') and r.full_url.startswith(HOST+'/') for r in gateway.requests))
        self.assertTrue(all('/rpc/' in r.full_url or '/auth/v1/' in r.full_url for r in gateway.requests))

    def test_answer_and_identity_never_in_report(self):
        result = verify(CONFIG, ACCOUNTS, Gateway(True))
        self.assertEqual(result['FULL_ANSWER_OPERATOR_ACCESS'], 'PASS')
        report = json.dumps(result)
        for private in ('합성', 'synthetic-case', 'example.invalid', 'synthetic-password', 'signature', 'PRIVATE_ERROR_BODY'):
            self.assertNotIn(private, report)

    def test_project_and_service_key_rejected_before_network(self):
        for config in ({**CONFIG, 'SUPABASE_URL': 'https://example.invalid'}, {**CONFIG, 'SUPABASE_PUBLISHABLE_KEY': 'service-key'}):
            gateway = Gateway()
            with self.assertRaises(CheckFailed): verify(config, ACCOUNTS, gateway)
            self.assertEqual(gateway.requests, [])

    def test_external_file_safety(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)/'credential.json'
            path.write_text('{}')
            path.chmod(0o600)
            self.assertEqual(private_json(path), {})
            link = Path(directory)/'link.json'
            link.symlink_to(path)
            with self.assertRaises(CheckFailed): private_json(link)
            path.chmod(0o644)
            with self.assertRaises(CheckFailed): private_json(path)

    def test_redirect_is_never_followed(self):
        self.assertIsNone(NoRedirect().redirect_request(None, None, 302, '', {}, 'https://example.invalid'))

    def test_unexpected_exception_is_redacted(self):
        with patch('sys.argv', ['verify_quality_gateway.py', '/outside/public', '/outside/credentials']), \
             patch('verify_quality_gateway.private_json', side_effect=RuntimeError('PRIVATE_TOKEN')), \
             patch('sys.stdout', new_callable=io.StringIO) as output:
            self.assertEqual(main(), 1)
            self.assertNotIn('PRIVATE_TOKEN', output.getvalue())
            self.assertIn('LOCAL_OR_TRANSPORT_ERROR', output.getvalue())


if __name__ == '__main__': unittest.main()
