"""Opt-in Study REST acceptance. Passwords only via hidden terminal input.

Only this run's random Study IDs may be deleted. Profiles and Auth users are never
mutated. A/B visible Study history must be empty; global counts require Owner SQL.
"""
import argparse
import getpass
import json
import re
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
import warnings
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

HOST = 'https://stlhijzpjfgwwdgunlsd.supabase.co'
EMAILS = {'A': 'legendstudy1@legendstudy.com', 'B': 'legendstudy2@legendstudy.com'}
FIELDS = 'id,user_id,mode,title,subject,planned_duration_seconds,started_at,ended_at,active_segments,duration_seconds,created_at'
SAFE_DB_CODES = {'23514', '42501', '23502', '23505', '22007', '22008', '22003', '428C9', 'PGRST204'}


@dataclass
class Response:
    status: int
    body: object
    count: int | None = None


class Failure(Exception):
    pass


def require(value, code):
    if not value:
        raise Failure(code)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None  # Never forward credentials to another endpoint.


class Transport:
    def __init__(self, key):
        self.key = key
        self.opener = urllib.request.build_opener(NoRedirect())

    def __call__(self, method, path, data=None, token=None, prefer=None):
        headers = {'apikey': self.key, 'Content-Type': 'application/json'}
        if token:
            headers['Authorization'] = 'Bearer ' + token
        if prefer:
            headers['Prefer'] = prefer
        request = urllib.request.Request(HOST + path, method=method, headers=headers,
            data=None if data is None else json.dumps(data).encode())
        try:
            response = self.opener.open(request, timeout=30)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            raw, status = response.read(), response.code
            content_range = response.headers.get('Content-Range', '')
        count_match = re.fullmatch(r'(?:\d+-\d+|\*)/(\d+)', content_range)
        try:
            body = json.loads(raw) if raw else None
        except (ValueError, UnicodeError):
            body = None  # Preserve status; never display raw HTML/body.
        return Response(status, body, int(count_match[1]) if count_match else None)


def instant(value):
    require(isinstance(value, str), 'TIMESTAMP_SHAPE')
    try:
        result = datetime.fromisoformat(value.replace('Z', '+00:00'))
    except ValueError:
        raise Failure('TIMESTAMP_SHAPE') from None
    require(result.tzinfo is not None, 'TIMESTAMP_TIMEZONE')
    return result.astimezone(timezone.utc)


def base_payload(**changes):
    data = {'mode': 'study', 'started_at': '2026-09-14T00:00:00Z',
            'ended_at': '2026-09-14T00:03:00Z',
            'active_segments': [[0, 60000], [120000, 180000]]}
    data.update(changes)
    return data


class Verifier:
    def __init__(self, config, transport=None):
        require(isinstance(config, dict), 'CONFIG_SHAPE')
        require(config.get('SUPABASE_URL', '').rstrip('/') == HOST, 'PROJECT_MISMATCH')
        key = config.get('SUPABASE_PUBLISHABLE_KEY')
        require(isinstance(key, str) and key.startswith('sb_publishable_')
                and key == key.strip(), 'PUBLIC_KEY_FORMAT')
        self.transport = transport or Transport(key)
        self.sessions = {}
        self.attempted = set()
        self.profiles = {}
        self.baseline = {}
        self.stage = 'login_preflight'
        self.last = None

    def call(self, method, path, data=None, label=None, prefer=None):
        self.last = None
        self.last = self.transport(method, path, data,
            self.sessions[label]['token'] if label else None, prefer)
        return self.last

    def passed(self, stage):
        print('STUDY_RUNTIME PASS ' + stage, flush=True)

    def failed(self, error):
        code = str(error) if isinstance(error, Failure) else (
            'INTERRUPTED' if isinstance(error, KeyboardInterrupt) else
            'TLS_ERROR' if isinstance(error, ssl.SSLError) else
            'NETWORK_ERROR' if isinstance(error, (urllib.error.URLError, TimeoutError)) else 'LOCAL_ERROR')
        # Only script-owned failures and a short allowlist of server codes are shown.
        if not re.fullmatch(r'[A-Z0-9_]+', code):
            code = 'LOCAL_ERROR'
        db = self.last.body.get('code') if self.last and isinstance(self.last.body, dict) else None
        if db not in SAFE_DB_CODES:
            db = 'UNAVAILABLE'
        status = self.last.status if self.last else 'UNAVAILABLE'
        print(f'STUDY_RUNTIME FAIL {self.stage} HTTP={status} code={code} db_code={db}', flush=True)

    def read(self, label, row_id=None, table='study_sessions', count=False):
        query = {'select': FIELDS if table == 'study_sessions' else '*'}
        if row_id:
            query['id'] = 'eq.' + row_id
        else:
            query['user_id' if table == 'study_sessions' else 'id'] = 'eq.' + self.sessions[label]['id']
        if count:
            query['limit'] = '1'
        response = self.call('GET', '/rest/v1/' + table + '?' + urllib.parse.urlencode(query),
                             label=label, prefer='count=exact' if count else None)
        require(response.status in (200, 206) and isinstance(response.body, list), 'READ_RESULT')
        if count:
            require(type(response.count) is int and response.count >= 0, 'EXACT_COUNT_MISSING')
            require(len(response.body) == min(response.count, 1), 'COUNT_RESULT_MISMATCH')
        return response

    def login(self, passwords):
        for label, email in EMAILS.items():
            self.stage = 'login_preflight_' + label
            require(isinstance(passwords.get(label), str) and bool(passwords[label]), 'PASSWORD_MISSING')
            response = self.call('POST', '/auth/v1/token?grant_type=password',
                                 {'email': email, 'password': passwords[label]})
            require(response.status == 200 and isinstance(response.body, dict), 'LOGIN_RESULT')
            user, token = response.body.get('user'), response.body.get('access_token')
            require(isinstance(user, dict) and isinstance(token, str) and bool(token.strip()), 'LOGIN_SHAPE')
            require(isinstance(user.get('email'), str) and user['email'].strip().casefold() == email, 'LOGIN_IDENTITY')
            try:
                owner = str(uuid.UUID(user['id']))
            except (ValueError, TypeError, KeyError, AttributeError):
                raise Failure('LOGIN_UUID') from None
            self.sessions[label] = {'id': owner, 'token': token}
        require(self.sessions['A']['id'] != self.sessions['B']['id'], 'IDENTITIES_NOT_DISTINCT')
        for label in EMAILS:
            self.stage = 'login_preflight_' + label
            response = self.read(label, count=True)
            require(response.count == 0 and response.body == [], 'EXISTING_STUDY_ROWS_STOP')
            self.baseline[label] = response.count
            self.profiles[label] = self.read(label, table='profiles').body
        self.passed('login_preflight')
        print('STUDY_RUNTIME baseline scope=A/B study_rows=0; global baseline=Owner-reported 0 (not JWT-visible)', flush=True)

    def allocate(self):
        row_id = str(uuid.uuid4())
        # Verify absence through both identities before registering cleanup ownership.
        for label in EMAILS:
            require(self.read(label, row_id).body == [], 'UUID_COLLISION_STOP')
        self.attempted.add(row_id)  # Before dispatch, including an uncertain INSERT.
        return row_id

    def check_row(self, label, data, row, duration):
        require(isinstance(row, dict), 'ROW_SHAPE')
        require(row.get('user_id') == self.sessions[label]['id'], 'ROW_OWNER')
        for field in ('id', 'mode', 'active_segments', 'title', 'subject', 'planned_duration_seconds'):
            require(row.get(field) == data.get(field), 'ROW_FIELDS')
        for field in ('started_at', 'ended_at'):
            require(instant(row.get(field)) == instant(data[field]), 'ROW_TIME')
        require(type(row.get('duration_seconds')) is int and row['duration_seconds'] == duration, 'GENERATED_DURATION')
        instant(row.get('created_at'))

    def insert(self, label, data, duration):
        data = {'id': self.allocate(), **data}
        require(not {'user_id', 'duration_seconds', 'created_at'} & data.keys(), 'CLIENT_PAYLOAD')
        response = self.call('POST', '/rest/v1/study_sessions', data, label, 'return=representation')
        require(response.status == 201 and isinstance(response.body, list) and len(response.body) == 1, 'INSERT_RESULT')
        self.check_row(label, data, response.body[0], duration)
        rows = self.read(label, data['id']).body
        require(len(rows) == 1, 'INSERT_SELECT_COUNT')
        self.check_row(label, data, rows[0], duration)
        return rows[0]

    def reject(self, data, label='A', expected='23514'):
        data = {'id': self.allocate(), **data}
        response = self.call('POST', '/rest/v1/study_sessions', data, label, 'return=representation')
        require(response.status == (403 if expected == '42501' else 400)
                and isinstance(response.body, dict) and response.body.get('code') == expected, 'EXPECTED_REJECTION')
        for who in EMAILS:
            require(self.read(who, data['id']).body == [], 'REJECTED_ROW_EXISTS')

    def delete(self, label, row_id):
        require(row_id in self.attempted, 'DELETE_NOT_OWNED_BY_RUN')
        return self.call('DELETE', '/rest/v1/study_sessions?' + urllib.parse.urlencode({'id': 'eq.' + row_id}),
                         label=label, prefer='return=representation')

    def acceptance(self):
        self.stage = 'normal_study'
        original = self.insert('A', base_payload(), 120)
        self.passed(self.stage)
        self.stage = 'mock_exam'
        for limit in (60, 43200):
            end = datetime(2026, 9, 14, tzinfo=timezone.utc) + timedelta(seconds=limit)
            self.insert('A', base_payload(mode='mock_exam', title='모의고사', subject='국어',
                planned_duration_seconds=limit, ended_at=end.isoformat(), active_segments=[[0, limit*1000]]), limit)
        self.insert('B', base_payload(), 120)
        self.passed(self.stage)
        self.stage = 'interval_validation'
        invalid = [ [[60000, 0]], [[0, 60000], [30000, 90000]], [[0, 180001]],
                    [[-1, 1000]], [[0, 0]], [[2000, 3000], [0, 1000]],
                    [[i*2, i*2+1] for i in range(257)], [], None, {},
                    [[0.5, 1000]], [[0, None]], [[0, '1000']], [[0, 1000, 2000]] ]
        for index, intervals in enumerate(invalid):
            self.stage = f'interval_validation_case_{index+1}'
            self.reject(base_payload(active_segments=intervals))
        self.stage = 'interval_validation_span'
        self.reject(base_payload(ended_at='2026-09-15T00:00:01Z'))
        self.reject(base_payload(ended_at='2026-09-13T23:59:59Z'))
        self.insert('A', base_payload(ended_at='2026-09-15T00:00:00Z', active_segments=[[0,86400000]]),86400)
        self.insert('A', base_payload(ended_at='2026-09-14T00:10:00Z',
            active_segments=[[i*2000, i*2000+1000] for i in range(256)]),256)
        self.passed('interval_validation')
        self.stage = 'generated_duration'
        for field, value in [('duration_seconds', 999), ('user_id', self.sessions['A']['id']),
                             ('created_at', '2026-09-14T00:00:00Z')]:
            self.stage = 'generated_duration_' + field
            self.reject(base_payload(**{field:value}), expected='42501')
        self.passed('generated_duration')
        self.stage = 'mode_validation'
        for index, changes in enumerate([{'mode':'invalid'}, {'planned_duration_seconds':60},
                        {'mode':'mock_exam','planned_duration_seconds':60},
                        {'mode':'mock_exam','title':'시험'},
                        *[{'mode':'mock_exam','title':'시험','planned_duration_seconds':x} for x in (59,43201,60)]]):
            self.stage = f'mode_validation_case_{index+1}'
            self.reject(base_payload(**changes))
        self.stage = 'mode_validation_subsecond_over_plan'
        self.reject(base_payload(mode='mock_exam',title='시험',planned_duration_seconds=60,
                                 active_segments=[[0,60001]]))
        self.passed('mode_validation')
        self.stage = 'text_validation'
        self.insert('A', base_payload(title='가'*80, subject='나'*40),120)
        for field, maximum in [('title',80), ('subject',40)]:
            for index, value in enumerate(('', '   ', '\t\n', ' 앞', '뒤 ', '가'*(maximum+1))):
                self.stage = f'text_validation_{field}_{index+1}'
                self.reject(base_payload(**{field:value}))
        self.passed('text_validation')
        self.stage = 'ownership_isolation'
        require(self.read('B', original['id']).body == [], 'B_CAN_READ_A')
        response = self.delete('B', original['id'])
        require(response.status == 200 and response.body == [], 'B_DELETE_RESULT')
        self.reject(base_payload(user_id=self.sessions['A']['id']),label='B',expected='42501')
        require(self.read('A', original['id']).body == [original], 'A_ROW_CHANGED')
        self.passed(self.stage)
        self.stage = 'update_denied'
        response = self.call('PATCH', '/rest/v1/study_sessions?' + urllib.parse.urlencode({'id':'eq.'+original['id']}),
                             {'title':'forbidden'}, 'A', 'return=representation')
        require(response.status == 403 and isinstance(response.body, dict) and response.body.get('code') == '42501', 'UPDATE_ALLOWED')
        require(self.read('A', original['id']).body == [original], 'UPDATE_CHANGED_ROW')
        self.passed(self.stage)
        self.stage = 'owner_delete'
        response = self.delete('A', original['id'])
        require(response.status == 200 and response.body == [original], 'OWNER_DELETE_RESULT')
        require(self.read('A', original['id']).body == [], 'OWNER_DELETE_NOT_REMOVED')
        self.passed(self.stage)

    def cleanup(self):
        good = True
        for row_id in sorted(self.attempted):
            for label in self.sessions:
                try:
                    response = self.delete(label, row_id)
                    require(response.status == 200 and isinstance(response.body, list), 'CLEANUP_DELETE')
                    require(self.read(label, row_id).body == [], 'CLEANUP_ROW_REMAINS')
                except (Exception, KeyboardInterrupt) as error:
                    self.failed(error)
                    good = False
        # Verify full A/B counts, not merely IDs; never delete unrelated new rows.
        for label, baseline in self.baseline.items():
            try:
                require(self.read(label, count=True).count == baseline, 'BASELINE_NOT_RESTORED')
                require(self.read(label, table='profiles').body == self.profiles[label], 'PROFILE_CHANGED')
            except (Exception, KeyboardInterrupt) as error:
                self.failed(error)
                good = False
        return good

    def run(self, passwords, preflight_only=False):
        good = False
        try:
            self.login(passwords)
            if not preflight_only:
                self.acceptance()
            good = True
        except (Exception, KeyboardInterrupt) as error:
            self.failed(error)
        finally:
            self.stage = 'fixture_cleanup'
            # No DELETE at all on preflight-only or pre-existing-history STOP.
            cleanup_ok = self.cleanup() if self.attempted else True
            good = good and cleanup_ok
            if self.attempted and cleanup_ok:
                self.passed('fixture_cleanup')
                print('STUDY_RUNTIME PASS study_rows_baseline_restored scope=A/B', flush=True)
                self.passed('profile_school_dday_preserved')
            elif not self.attempted:
                print('STUDY_RUNTIME SKIP fixture_cleanup no_mutations', flush=True)
            self.stage = 'auth_users_retained'
            retained = len(self.sessions) == 2
            for label, session in self.sessions.items():
                try:
                    response = self.call('GET', '/auth/v1/user', label=label)
                    require(response.status == 200 and isinstance(response.body, dict)
                            and response.body.get('id') == session['id'], 'AUTH_USER_READ')
                except (Exception, KeyboardInterrupt) as error:
                    self.failed(error)
                    retained = False
            if retained:
                self.passed('auth_users_retained')
            good = good and retained
            for label in self.sessions:
                try:
                    response = self.call('POST', '/auth/v1/logout?scope=local',label=label)
                    require(response.status in (200,204), 'LOGOUT_FAILED')
                except (Exception, KeyboardInterrupt) as error:
                    self.stage = 'session_logout'
                    self.failed(error)
                    good = False
        if good:
            self.passed('preflight_only' if preflight_only else 'acceptance')
        return good


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('public_config')
    parser.add_argument('--preflight-only', action='store_true')
    args = parser.parse_args(argv)
    try:
        path = Path(args.public_config).resolve()
        require(not path.is_relative_to(Path(__file__).resolve().parents[1]), 'CONFIG_MUST_BE_EXTERNAL')
        verifier = Verifier(json.loads(path.read_text()))
        require(sys.stdin.isatty(), 'INTERACTIVE_TERMINAL_REQUIRED')
        with warnings.catch_warnings():
            warnings.simplefilter('error', getpass.GetPassWarning)
            passwords = {label: getpass.getpass(f'Password for {label} ({email}) > ') for label,email in EMAILS.items()}
        return 0 if verifier.run(passwords,args.preflight_only) else 1
    except (Exception,KeyboardInterrupt):
        print('STUDY_RUNTIME FAIL setup HTTP=UNAVAILABLE code=CONFIG_OR_SECURE_INPUT_ERROR',flush=True)
        return 1


if __name__ == '__main__':
    sys.exit(main())
