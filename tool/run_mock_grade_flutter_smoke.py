"""Opt-in D3 native Flutter grade/result smoke. Owner-run only; scoped D1 cleanup."""
import argparse
import contextlib
import getpass
import io
import json
import os
import re
import signal
import subprocess
import sys
import threading
import uuid
import warnings
from run_mock_scoring_flutter_smoke import Bridge
from pathlib import Path

import psycopg
from verify_mock_scoring_jwt import (Acceptance, AdminFixtures, EMAILS, REF,
    admin_settings, admin_host_from_config, require, uuid_value, SAFE_CODES)
from verify_study_sessions_jwt import Failure

STAGES = frozenset('login_preflight confirmed_grade estimated_grade unavailable_grade result_summary answer_review provenance auth_restore historical_version account_isolation retry legacy_fallback navigation local_fixture_cleanup'.split())
CLEANUP = frozenset('fixture_scope_verified fixture_cleanup cleanup_triggers_restored scoring_baseline_restored existing_data_preserved auth_users_retained'.split())


RUN_STAGES = frozenset('startup public_config simulator_preflight credential_input admin_settings login_preflight_A login_preflight_B db_connect fixture_preflight fixture_create bridge_start flutter_runtime bridge_control bridge_close fixture_capture fixture_cleanup auth_users_retained db_close runner'.split()) | STAGES
KINDS = frozenset('guard file_missing permission config_json interrupted db_error timeout subprocess_error unexpected assertion state format auth http network simulator_inventory missing_stages bridge_failed flutter_failed compiler_error test_failure app_stop'.split())
GUARDS = frozenset('INTERACTIVE_REQUIRED EXTERNAL_CONFIG PROJECT KEY ADMIN_HOST ADMIN_PASSWORD LOGIN TOKEN IDENTITY DISTINCT MISSING_TABLES EXISTING_SCORING_STOP ADMIN_PROJECT_IDENTITY UUID_COLLISION ADMIN_TABLE_OWNER_REQUIRED TRIGGER_STATE KIND RUN_LIMIT EXISTING_UUID_STOP SWITCH_ORDER MISSING_PRIOR CONTROL_REJECTED SIZE SHAPE NO_BASELINE TABLE_CATALOG_CHANGED TRIGGER_DRIFT EXISTING_DATA_CHANGED FIXTURE_COUNT_OR_DIGEST_CHANGED ATTEMPT_SCOPE STUDY_SCOPE DELETE_COUNT ANSWERS_CASCADE TRIGGERS_NOT_RESTORED FIXTURE_REMAINS BASELINE_NOT_RESTORED SIMULATOR_NOT_BOOTED SIMULATOR_MISSING SIMULATOR_UNAVAILABLE'.split())


def diagnostic(stage, kind, *, code=None, http_status=None, exit_code=None):
    # Never stringify exceptions, commands, paths, URLs or response bodies.
    stage = stage if stage in RUN_STAGES else 'runner'
    kind = kind if kind in KINDS else 'unexpected'
    fields = ['stage=' + stage, 'kind=' + kind]
    if isinstance(code, str) and code in GUARDS | SAFE_CODES:
        fields.append('code=' + code)
    if type(http_status) is int and 100 <= http_status <= 599:
        fields.append('http_status=' + str(http_status))
    if type(exit_code) is int and -255 <= exit_code <= 255:
        fields.append('exit_code=' + str(exit_code))
    print('D3_FLUTTER DIAG ' + ' '.join(fields), flush=True)


def diagnose(stage, error, app=None):
    kind, code = 'unexpected', None
    if isinstance(error, Failure):
        kind = 'guard'
        code = error.args[0] if error.args and isinstance(error.args[0], str) else None
    elif isinstance(error, KeyboardInterrupt): kind = 'interrupted'
    elif isinstance(error, FileNotFoundError): kind = 'file_missing'
    elif isinstance(error, PermissionError): kind = 'permission'
    elif isinstance(error, json.JSONDecodeError): kind = 'config_json'
    elif isinstance(error, psycopg.Error): kind, code = 'db_error', error.sqlstate
    elif isinstance(error, (TimeoutError, subprocess.TimeoutExpired)): kind = 'timeout'
    elif isinstance(error, subprocess.CalledProcessError): kind = 'subprocess_error'
    status = None
    if app is not None and stage in ('login_preflight', 'login_preflight_A', 'login_preflight_B'):
        if app.stage in ('login_preflight_A', 'login_preflight_B'): stage = app.stage
        if app.last is not None: status = app.last.status
    diagnostic(stage, kind, code=code, http_status=status,
               exit_code=error.returncode if isinstance(error, subprocess.CalledProcessError) else None)


def check_device(device):
    result = subprocess.run(['xcrun', 'simctl', 'list', 'devices', '--json'],
                            capture_output=True, text=True, timeout=20, check=True)
    devices = [d for group in json.loads(result.stdout)['devices'].values() for d in group]
    target = next((d for d in devices if d.get('udid') == device), None)
    require(target is not None, 'SIMULATOR_MISSING')
    require(target.get('isAvailable') is True, 'SIMULATOR_UNAVAILABLE')
    require(target.get('state') == 'Booted', 'SIMULATOR_NOT_BOOTED')


class DiagnosticBridge(Bridge):
    def __init__(self, payload, admin):
        # Shared D2 bridge protocol/credential handling stays unchanged.
        class Control:
            def control(self, request):
                try:
                    admin.control(request)
                except (Exception, KeyboardInterrupt) as error:
                    diagnose('bridge_control', error)
                    raise
        super().__init__(payload, Control())


def mark(stage):
    print('D3_FLUTTER PASS ' + stage, flush=True)


def safe_forward(output, allowed):
    seen = set()
    for line in output.splitlines():
        line = line.strip()
        if line.startswith('flutter: '): line = line[9:]
        detail = re.fullmatch(r'D3_FLUTTER DIAG stage=([a-z_]+) kind=([a-z_]+)(?: code=([A-Z0-9]+))?(?: http_status=([0-9]{3}))?', line)
        if detail and detail[1] in STAGES and detail[2] in KINDS:
            diagnostic(detail[1], detail[2], code=detail[3], http_status=int(detail[4]) if detail[4] else None)
            continue
        match = re.fullmatch(r'(?:D3_FLUTTER|SCORING_RUNTIME) (PASS|FAIL) ([a-z_]+)', line.strip())
        if match and match[2] in allowed:
            seen.add((match[1], match[2]))
            print('D3_FLUTTER ' + match[1] + ' ' + match[2], flush=True)
    return seen


class RuntimeFixtures(AdminFixtures):
    """Three A attempts; all mutations bounded to this preflighted UUID registry."""
    def __init__(self, connection):
        super().__init__(connection)
        self.ids.update({name: uuid_value(uuid.uuid4()) for name in
                         ('estimated_key', 'estimated_cut', 'unavailable_key')})
        self.studies = set()
        self.switched = False

    def scopes(self):
        result = super().scopes()
        for table in ('answer_key_versions', 'exam_questions'):
            result[table] += [self.ids['estimated_key'], self.ids['unavailable_key']]
        result['grade_cutoff_versions'] += [self.ids['estimated_cut']]
        result['study_sessions'] = sorted(self.studies)
        return result

    def create(self):
        super().create()
        i = self.ids
        # All extra UUIDs were included in preflight/capture, even on partial failure.
        with self.db.transaction():
            for name, variant in [('estimated_key', 'estimated'), ('unavailable_key', 'unavailable')]:
                self.db.execute("""insert into public.answer_key_versions(id,exam_subject_id,content_item_id,
                  paper_variant,version,question_count,max_score,source_name,source_url,source_digest,fetched_at)
                  values(%s,%s,%s,%s,1,3,9,%s,'https://example.invalid/grade-key',repeat('2',64),now())""",
                  (i[name], i['occurrence'], i['content'], variant, 'Synthetic '+variant+' key'))
                for number, answer, points in [(1,1,2),(2,2,3),(3,3,4)]:
                    self.insert('exam_questions', dict(answer_key_version_id=i[name],
                        question_number=number, correct_answer=answer, points=points))
                self.publish('answer_key_versions', i[name])
            self.db.execute("""insert into public.grade_cutoff_versions(id,exam_subject_id,content_item_id,
              paper_variant,version,basis,certainty,max_score,minimum_scores,source_name,source_url,source_digest,fetched_at)
              values(%s,%s,%s,'estimated',1,'raw_estimate','estimated',9,%s,'Synthetic estimated cutoff',
              'https://example.invalid/estimated-cutoff',repeat('3',64),now())""",
              (i['estimated_cut'], i['occurrence'], i['content'], [9,8,7,6,5,4,3,1,0]))
            self.publish('grade_cutoff_versions', i['estimated_cut'])
            # v2 is still draft: published v1 definitions are never edited.
            self.db.execute("update public.answer_key_versions set source_name='Synthetic key v2',"
                            "source_url='https://example.invalid/key-v2' where id=%s", (i['key2'],))
            self.db.execute("update public.grade_cutoff_versions set source_name='Synthetic cutoff v2',"
                            "source_url='https://example.invalid/cutoff-v2' where id=%s", (i['cut2'],))
        self.capture()

    def register(self, kind, value):
        require(kind in ('study', 'attempt'), 'KIND')
        value = uuid_value(value)
        registry = self.studies if kind == 'study' else self.attempts
        if value in registry:
            return
        require(not self.switched and len(registry) < 3, 'RUN_LIMIT')
        table = 'study_sessions' if kind == 'study' else 'mock_exam_attempts'
        require(self.db.execute('select count(*) from public.' + table + ' where id=%s',
                               (value,)).fetchone()[0] == 0, 'EXISTING_UUID_STOP')
        registry.add(value)
        self.capture()

    def control(self, request):
        action = request.get('action')
        if action == 'register' and set(request) == {'action', 'kind', 'id'}:
            self.register(request['kind'], request['id'])
        elif action == 'checkpoint' and set(request) == {'action'}:
            self.capture()
        elif action == 'switch' and set(request) == {'action'}:
            require(not self.switched and len(self.attempts) == 3 and len(self.studies) == 3, 'SWITCH_ORDER')
            rows = self.db.execute('select user_id::text,answer_key_version_id::text from public.mock_exam_attempts '
                                   'where id=any(%s::uuid[])', (sorted(self.attempts),)).fetchall()
            require(len(rows) == 3 and all(row[0] == self.owners['A'] for row in rows) and
                    {row[1] for row in rows} == {self.ids[n] for n in ('key1','estimated_key','unavailable_key')},
                    'MISSING_PRIOR')
            self.switch()
            self.switched = True
        else:
            raise ValueError('CONTROL_REJECTED')


def run_flutter(bridge, device):
    repo = Path(__file__).resolve().parents[1]
    command = [str(Path.home() / 'development/flutter/bin/flutter'), 'test',
        'integration_test/mock_grade_auth_smoke_test.dart', '-d', device,
        '--dart-define=SMOKE_CONFIG_URL=' + bridge.url, '--reporter', 'expanded']
    process = subprocess.Popen(command, cwd=repo, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, text=True, start_new_session=True)
    seen = set()
    failure_kinds = set()
    # Bounded overall runtime. A stalled simulator cannot leave fixtures indefinitely.
    def stop():
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    def force_stop():
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    kill_timer = threading.Timer(910, force_stop)
    kill_timer.start()
    timer = threading.Timer(900, stop)
    timer.start()
    try:
        for line in process.stdout:
            seen.update(safe_forward(line, STAGES))
            for needle, kind in [('Compilation failed', 'compiler_error'), ('Failed to build iOS app', 'compiler_error'), ('TestFailure', 'test_failure')]:
                if needle in line and kind not in failure_kinds:
                    diagnostic('flutter_runtime', kind)
                    failure_kinds.add(kind)
        code = process.wait()
        diagnostic('flutter_runtime', 'subprocess_error' if code else 'state', exit_code=code)
        for stage in sorted(STAGES):
            if ('PASS', stage) not in seen: diagnostic(stage, 'missing_stages')
        if bridge.failed: diagnostic('bridge_control', 'bridge_failed')
        return (code == 0 and not bridge.failed
                and all(('PASS', stage) in seen for stage in STAGES)
                and not any(status == 'FAIL' for status, _ in seen))
    finally:
        timer.cancel()
        kill_timer.cancel()
        if process.poll() is None:
            stop()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
        process.stdout.close()
        # Stop this simulator app only; detached native code must not send later writes.
        terminated = subprocess.run(['xcrun', 'simctl', 'terminate', device, 'com.legendstudy.app'],
                       capture_output=True, timeout=15, check=False)
        diagnostic('flutter_runtime', 'app_stop', exit_code=terminated.returncode)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('public_config', type=Path)
    parser.add_argument('--device', default='AEC17AF7-4950-4B41-9520-45A60BB7C918')
    parser.add_argument('--preflight-only', action='store_true')
    args = parser.parse_args()
    app = admin = db = bridge = None
    passwords = {}; settings = {}; ok = False
    stage = 'startup'
    try:
        require(sys.stdin.isatty(), 'INTERACTIVE_REQUIRED')
        stage = 'public_config'
        path = args.public_config.resolve()
        require(not path.is_relative_to(Path(__file__).resolve().parents[1]), 'EXTERNAL_CONFIG')
        raw = json.loads(path.read_text())
        config = {key: raw[key] for key in ('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY')}
        app = Acceptance(config)
        if not args.preflight_only:
            stage = 'simulator_preflight'
            check_device(args.device)
        stage = 'credential_input'
        print('Target: LegendStudy / ' + REF, flush=True)
        with warnings.catch_warnings():
            warnings.simplefilter('error', getpass.GetPassWarning)
            for label, email in EMAILS.items():
                passwords[label] = getpass.getpass(f'Password for {label} ({email}) > ')
            stage = 'admin_settings'
            host = admin_host_from_config(raw)
            settings = admin_settings(host,
                                      getpass.getpass('LegendStudy DB password > '))
        stage = 'login_preflight'
        app.login(passwords)
        stage = 'db_connect'
        db = psycopg.connect(**settings)
        settings.clear()
        admin = RuntimeFixtures(db)
        stage = 'fixture_preflight'
        admin.preflight({who: session['id'] for who, session in app.sessions.items()})
        if args.preflight_only:
            mark('login_preflight'); ok = True
        else:
            stage = 'fixture_create'
            admin.create()
            payload = {**config, 'fixture': admin.ids, 'owners': admin.owners,
                       'accounts': {label: {'email': EMAILS[label], 'password': password}
                                    for label, password in passwords.items()}}
            stage = 'bridge_start'
            bridge = DiagnosticBridge(payload, admin)
            passwords.clear()
            stage = 'flutter_runtime'
            ok = run_flutter(bridge, args.device)
    except (Exception, KeyboardInterrupt) as error:
        diagnose(stage, error, app)
        print('D3_FLUTTER FAIL runner', flush=True)
    finally:
        passwords.clear(); settings.clear()
        if bridge:
            try:
                bridge.close()  # Native process has exited before cleanup starts.
            except (Exception, KeyboardInterrupt) as error:
                diagnose('bridge_close', error); ok = False
        if admin and admin.started:
            try:
                # Reconcile only UUIDs registered BEFORE dispatch, including lost acknowledgements.
                stage = 'fixture_capture'
                admin.capture()
                stage = 'fixture_cleanup'
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    admin.cleanup()
                seen = safe_forward(output.getvalue(), CLEANUP)
                ok = all(('PASS', stage) in seen for stage in CLEANUP - {'auth_users_retained'}) and ok
            except (Exception, KeyboardInterrupt) as error:
                diagnose(stage, error)
                print('D3_FLUTTER FAIL fixture_cleanup', flush=True); ok = False
        if app and app.sessions:
            try:
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    retained = app.finish_auth()
                safe_forward(output.getvalue(), CLEANUP)
                if not retained: diagnostic('auth_users_retained', 'guard')
                ok = retained and ok
            except (Exception, KeyboardInterrupt) as error:
                diagnose('auth_users_retained', error); ok = False
        if db:
            try:
                db.close()
            except (Exception, KeyboardInterrupt) as error:
                diagnose('db_close', error); ok = False
    print(('Preflight: ' if args.preflight_only else 'Flutter grade result smoke: ') + ('PASS' if ok else 'FAIL'), flush=True)
    return 0 if ok else 1


if __name__ == '__main__':
    raise SystemExit(main())
