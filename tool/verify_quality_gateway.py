"""Read-only Quality gateway checks. Credentials/JWT/answers never leave process memory.
Existing accounts only. Password login creates auth sessions; no application DML,
SQL, service-role credential, provider call, token persistence or automatic retry.
"""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import stat
import sys
import urllib.error
import urllib.request

HOST = 'https://stlhijzpjfgwwdgunlsd.supabase.co'
REPO = Path(__file__).resolve().parents[1]

class CheckFailed(Exception):
    pass

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

def require(condition, label):
    if not condition:
        raise CheckFailed(label)

def private_json(path):
    path = Path(path).absolute()
    require(not path.is_symlink() and not path.resolve().is_relative_to(REPO), 'EXTERNAL_FILE_REQUIRED')
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    try:
        st = os.fstat(fd)
        require(stat.S_ISREG(st.st_mode) and stat.S_IMODE(st.st_mode) == 0o600
                and st.st_uid == os.getuid(), 'UNSAFE_CREDENTIAL_FILE')
        with os.fdopen(fd, 'r') as stream:
            fd = None
            return json.load(stream)
    finally:
        if fd is not None:
            os.close(fd)

def verify(config, accounts, opener=None):
    require(config.get('SUPABASE_URL', '').rstrip('/') == HOST, 'PROJECT_MISMATCH')
    key = config.get('SUPABASE_PUBLISHABLE_KEY', '')
    require(isinstance(key, str) and key.startswith('sb_publishable_'), 'PUBLIC_KEY_REQUIRED')
    opener = opener or urllib.request.build_opener(NoRedirect())
    results = {}
    def call(path, data=None, token=None, method='POST'):
        require(path in ('/auth/v1/token?grant_type=password', '/auth/v1/user')
                or path in tuple('/rest/v1/rpc/'+x for x in
                                 ('is_quality_operator', 'ql_list_cases', 'ql_case_detail')), 'ROUTE_NOT_ALLOWED')
        headers = {'apikey': key, 'Content-Type': 'application/json', 'Cache-Control': 'no-store'}
        if token:
            headers['Authorization'] = 'Bearer '+token
        request = urllib.request.Request(HOST+path, data=None if data is None else json.dumps(data).encode(), headers=headers, method=method)
        try:
            with opener.open(request, timeout=30) as response:
                return response.status, json.loads(response.read())
        except urllib.error.HTTPError as error:
            try:
                # Error contents are never returned or printed; retain only HTTP status.
                error.close()
            finally:
                return error.code, None
    def rpc(name, data=None, token=None):
        return call('/rest/v1/rpc/'+name, {} if data is None else data, token)
    sessions = {}
    for role in ('ADMIN', 'STUDENT'):
        email, password = accounts['QUALITY_'+role+'_EMAIL'], accounts['QUALITY_'+role+'_PASSWORD']
        require(isinstance(email, str) and isinstance(password, str) and email and password, 'MISSING_ACCOUNT')
        code, body = call('/auth/v1/token?grant_type=password', {'email': email, 'password': password})
        require(code == 200 and isinstance(body, dict), role+'_LOGIN_FAILED')
        token = body['access_token']
        claims = json.loads(base64.urlsafe_b64decode(token.split('.')[1]+'==='))
        require(claims.get('role') == 'authenticated', 'AUTHENTICATED_JWT_REQUIRED')
        code, user = call('/auth/v1/user', token=token, method='GET')
        require(code == 200 and user.get('id') == claims.get('sub')
                and user.get('email', '').casefold() == email.casefold(), role+'_IDENTITY_MISMATCH')
        sessions[role] = {'token': token, 'id': user['id']}
        results[role+'_AUTHENTICATED_JWT'] = 'PASS'
        del body, claims, user, password
    admin, student = sessions['ADMIN'], sessions['STUDENT']
    require(admin['id'] != student['id'], 'DISTINCT_ACCOUNTS_REQUIRED')
    code, value = rpc('is_quality_operator', token=admin['token'])
    require(code == 200 and value is True, 'ADMIN_HELPER_FAILED')
    results['ADMIN_OPERATOR_TRUE'] = 'PASS'
    code, page = rpc('ql_list_cases', {'p_limit': 1}, admin['token'])
    require(code == 200 and isinstance(page, dict) and page.get('dto_version') == 'ql-read-v1'
            and isinstance(page.get('cases'), list) and len(page['cases']) <= 1, 'ADMIN_LIST_FAILED')
    results['ADMIN_ALLOW'] = 'PASS'
    require('answer_full_text' not in json.dumps(page), 'LIST_ANSWER_EXPOSURE')
    case = page['cases'][0]['evaluation_id'] if page['cases'] else '00000000-0000-0000-0000-000000000000'
    results['FULL_ANSWER_OPERATOR_ACCESS'] = 'NOT_ASSESSABLE'
    results['ADMIN_DETAIL'] = 'NOT_ASSESSABLE'
    if page['cases']:
        code, detail = rpc('ql_case_detail', {'p_evaluation_id': case}, admin['token'])
        require(code == 200 and isinstance(detail, dict), 'ADMIN_DETAIL_FAILED')
        submission = detail.get('student_submission', {})
        answer = submission.get('answer_full_text')
        require(isinstance(answer, str) and bool(answer), 'FULL_ANSWER_MISSING')
        require(hashlib.sha256(answer.encode()).hexdigest() == submission.get('body_sha256'), 'ANSWER_HASH_MISMATCH')
        results['ADMIN_DETAIL'] = results['FULL_ANSWER_OPERATOR_ACCESS'] = 'PASS'
        del detail, submission, answer
    del page
    code, value = rpc('is_quality_operator', token=student['token'])
    require(code == 200 and value is False, 'STUDENT_HELPER_FAILED')
    results['STUDENT_OPERATOR_FALSE'] = 'PASS'
    for name, data in [('ql_list_cases', {'p_limit': 1}), ('ql_case_detail', {'p_evaluation_id': case})]:
        code, _ = rpc(name, data, student['token'])
        require(code == 403, 'STUDENT_'+name+'_NOT_DENIED')
        results['STUDENT_'+name+'_HTTP'] = code
    results['STUDENT_DENY'] = 'PASS'
    for name, data in [('is_quality_operator', {}), ('ql_list_cases', {'p_limit': 1}), ('ql_case_detail', {'p_evaluation_id': case})]:
        code, _ = rpc(name, data)
        require(code in (401, 403), 'ANON_'+name+'_NOT_DENIED')
        results['ANON_'+name+'_HTTP'] = code
    results['ANON_DENY'] = 'PASS'
    code, _ = rpc('ql_list_cases', {'p_limit': 1, 'user_id': admin['id']}, student['token'])
    require(code == 404, 'CALLER_ID_ARGUMENT_ACCEPTED')
    results['CALLER_ID_ARGUMENT_REJECTED'] = 'PASS'
    # Tamper only this authorized test account's JWT subject, retaining its invalid signature.
    parts = student['token'].split('.')
    claims = json.loads(base64.urlsafe_b64decode(parts[1]+'==='))
    claims['sub'] = admin['id']
    parts[1] = base64.urlsafe_b64encode(json.dumps(claims).encode()).decode().rstrip('=')
    code, _ = rpc('is_quality_operator', token='.'.join(parts))
    require(code == 401, 'FORGED_SIGNATURE_NOT_DENIED')
    results['FORGED_JWT_DENY'] = 'PASS'
    results['PRODUCTION_GATEWAY_AUTHORIZATION'] = 'PASS'
    results['APPLICATION_DATA_WRITES'] = 0
    results['PROVIDER_CALLS'] = 0
    return results

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('public_config')
    parser.add_argument('credentials')
    args = parser.parse_args()
    try:
        result = verify(private_json(args.public_config), private_json(args.credentials))
        print(json.dumps(result, indent=2))
    except CheckFailed as error:
        print(json.dumps({'status': 'STOP', 'check': str(error)}))
        return 1
    except Exception:
        # Never emit traceback, HTTP body, request, password, token, identity or answer.
        print(json.dumps({'status': 'STOP', 'check': 'LOCAL_OR_TRANSPORT_ERROR'}))
        return 1
    return 0

if __name__ == '__main__':
    sys.exit(main())
