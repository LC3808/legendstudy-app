"""Opt-in native Flutter scoring smoke. Hidden credentials; UUID-scoped D1 cleanup."""
import argparse
import contextlib
import getpass
import io
import json
import os
import re
import secrets
import signal
import subprocess
import sys
import threading
import warnings
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import psycopg
from verify_mock_scoring_jwt import (Acceptance, AdminFixtures, EMAILS, REF,
    admin_settings, require, uuid_value)

STAGES = frozenset('login_preflight auth_scoring_start answer_entry pause_resume draft_restore auth_submit auth_result auth_restore account_isolation retry stale_version local_fixture_cleanup'.split())
CLEANUP = frozenset('fixture_scope_verified fixture_cleanup cleanup_triggers_restored scoring_baseline_restored existing_data_preserved auth_users_retained'.split())


def mark(stage):
    print('D2_FLUTTER PASS ' + stage, flush=True)


def safe_forward(output, allowed):
    seen = set()
    for line in output.splitlines():
        match = re.fullmatch(r'(?:D2_FLUTTER|SCORING_RUNTIME) (PASS|FAIL) ([a-z_]+)', line.strip())
        if match and match[2] in allowed:
            seen.add((match[1], match[2]))
            print('D2_FLUTTER ' + match[1] + ' ' + match[2], flush=True)
    return seen


class RuntimeFixtures(AdminFixtures):
    def __init__(self, connection):
        super().__init__(connection)
        self.studies = set()
        self.switched = False

    def scopes(self):
        result = super().scopes()
        result['study_sessions'] = sorted(self.studies)
        return result

    def register(self, kind, value):
        require(kind in ('study', 'attempt'), 'KIND')
        value = uuid_value(value)
        registry = self.studies if kind == 'study' else self.attempts
        if value in registry:
            return  # An exact retry never adopts a different UUID.
        require(len(registry) < 2, 'RUN_LIMIT')
        table = 'study_sessions' if kind == 'study' else 'mock_exam_attempts'
        require(self.db.execute('select count(*) from public.' + table + ' where id=%s',
                               (value,)).fetchone()[0] == 0, 'EXISTING_UUID_STOP')
        registry.add(value)  # Before the native repository dispatches any write.
        self.capture()

    def control(self, request):
        action = request.get('action')
        if action == 'register' and set(request) == {'action', 'kind', 'id'}:
            self.register(request['kind'], request['id'])
        elif action == 'checkpoint' and set(request) == {'action'}:
            self.capture()
        elif action == 'switch' and set(request) == {'action'}:
            require(not self.switched and len(self.attempts) == 1, 'SWITCH_ORDER')
            require(self.db.execute('select count(*) from public.mock_exam_attempts where id=any(%s::uuid[])',
                                   (sorted(self.attempts),)).fetchone()[0] == 1, 'MISSING_PRIOR')
            self.switch()
            self.switched = True
        else:
            raise ValueError('CONTROL_REJECTED')


class Bridge:
    """One-shot credentials and a bounded, authenticated loopback fixture registry."""
    def __init__(self, payload, admin):
        self.payload = payload
        self.admin = admin
        self.route = '/' + secrets.token_urlsafe(32)
        self.failed = False
        bridge = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass

            def reply(self, code, data):
                self.send_response(code)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Cache-Control', 'no-store')
                self.end_headers()
                self.wfile.write(json.dumps(data).encode())

            def do_GET(self):
                if self.path != bridge.route or bridge.payload is None:
                    self.reply(404, {'ok': False}); return
                payload, bridge.payload = bridge.payload, None
                self.reply(200, payload)

            def do_POST(self):
                if self.path != bridge.route or bridge.payload is not None:
                    self.reply(404, {'ok': False}); return
                try:
                    size = int(self.headers.get('Content-Length', '0'))
                    require(0 < size <= 512, 'SIZE')
                    request = json.loads(self.rfile.read(size))
                    require(isinstance(request, dict), 'SHAPE')
                    bridge.admin.control(request)
                    self.reply(200, {'ok': True})
                except Exception:
                    bridge.failed = True
                    self.reply(400, {'ok': False})  # Never serialize exceptions/DB rows.

        self.server = HTTPServer(('127.0.0.1', 0), Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.url = f'http://127.0.0.1:{self.server.server_port}{self.route}'

    def close(self):
        self.server.shutdown()
        self.thread.join()
        self.server.server_close()
        self.payload = None


def run_flutter(bridge, device):
    repo = Path(__file__).resolve().parents[1]
    command = [str(Path.home() / 'development/flutter/bin/flutter'), 'test',
        'integration_test/mock_scoring_auth_smoke_test.dart', '-d', device,
        '--dart-define=SMOKE_CONFIG_URL=' + bridge.url, '--reporter', 'expanded']
    process = subprocess.Popen(command, cwd=repo, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, text=True, start_new_session=True)
    seen = set()
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
        return (process.wait() == 0 and not bridge.failed
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
        subprocess.run(['xcrun', 'simctl', 'terminate', device, 'com.legendstudy.app'],
                       capture_output=True, timeout=15, check=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('public_config', type=Path)
    parser.add_argument('--device', default='AEC17AF7-4950-4B41-9520-45A60BB7C918')
    parser.add_argument('--preflight-only', action='store_true')
    args = parser.parse_args()
    app = admin = db = bridge = None
    passwords = {}; settings = {}; ok = False
    try:
        require(sys.stdin.isatty(), 'INTERACTIVE_REQUIRED')
        path = args.public_config.resolve()
        require(not path.is_relative_to(Path(__file__).resolve().parents[1]), 'EXTERNAL_CONFIG')
        raw = json.loads(path.read_text())
        config = {key: raw[key] for key in ('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY')}
        app = Acceptance(config)
        print('Target: LegendStudy / ' + REF, flush=True)
        with warnings.catch_warnings():
            warnings.simplefilter('error', getpass.GetPassWarning)
            for label, email in EMAILS.items():
                passwords[label] = getpass.getpass(f'Password for {label} ({email}) > ')
            host = input('Supabase Connect Session pooler host (blank = direct DB) > ').strip()
            settings = admin_settings(host or 'db.' + REF + '.supabase.co',
                                      getpass.getpass('LegendStudy DB password > '))
        app.login(passwords)
        db = psycopg.connect(**settings)
        settings.clear()
        admin = RuntimeFixtures(db)
        admin.preflight({who: session['id'] for who, session in app.sessions.items()})
        if args.preflight_only:
            mark('login_preflight'); ok = True
        else:
            admin.create()
            payload = {**config, 'fixture': admin.ids, 'owners': admin.owners,
                       'accounts': {label: {'email': EMAILS[label], 'password': password}
                                    for label, password in passwords.items()}}
            bridge = Bridge(payload, admin)
            passwords.clear()
            ok = run_flutter(bridge, args.device)
    except (Exception, KeyboardInterrupt):
        print('D2_FLUTTER FAIL runner', flush=True)
    finally:
        passwords.clear(); settings.clear()
        if bridge:
            bridge.close()  # Native process has exited before cleanup starts.
        if admin and admin.started:
            try:
                # Reconcile only UUIDs registered BEFORE dispatch, including lost acknowledgements.
                admin.capture()
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    admin.cleanup()
                seen = safe_forward(output.getvalue(), CLEANUP)
                ok = all(('PASS', stage) in seen for stage in CLEANUP - {'auth_users_retained'}) and ok
            except (Exception, KeyboardInterrupt):
                print('D2_FLUTTER FAIL fixture_cleanup', flush=True); ok = False
        if app:
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                retained = app.finish_auth()
            safe_forward(output.getvalue(), CLEANUP)
            ok = retained and ok
        if db:
            db.close()
    print(('Preflight: ' if args.preflight_only else 'Flutter scoring smoke: ') + ('PASS' if ok else 'FAIL'), flush=True)
    return 0 if ok else 1


if __name__ == '__main__':
    raise SystemExit(main())
