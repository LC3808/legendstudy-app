"""Run opt-in iOS simulator Flutter smoke with hidden passwords via one-shot loopback.
No passwords in shell history, files, Dart defines, compiled app or printed logs.
Usage: python3 tool/run_day_target_flutter_smoke.py EXTERNAL_PUBLIC_CONFIG [--accounts EXTERNAL_JSON] [--device UUID]
"""
import argparse
import getpass
import json
import re
import secrets
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from verify_day_target_jwt import EMAILS, external_json, HOST


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('public_config')
    parser.add_argument('--accounts')
    parser.add_argument('--device', default='AEC17AF7-4950-4B41-9520-45A60BB7C918')
    args = parser.parse_args()
    config = external_json(args.public_config)
    if config.get('SUPABASE_URL', '').rstrip('/') != HOST:
        raise ValueError('Wrong project')
    if args.accounts:
        accounts = external_json(args.accounts)
    else:
        accounts = {}
        for label, email in EMAILS.items():
            accounts[f'TEST_{label}_EMAIL'] = email
            accounts[f'TEST_{label}_PASSWORD'] = getpass.getpass(f'Password for {label} ({email}) > ')
    for label, email in EMAILS.items():
        if accounts.get(f'TEST_{label}_EMAIL') != email:
            raise ValueError('Wrong account')
    payload = json.dumps({**config, **accounts}).encode()
    route = '/' + secrets.token_urlsafe(32)
    class Handler(BaseHTTPRequestHandler):
        used = False
        def log_message(self, *args):
            pass
        def do_GET(self):
            if self.path != route or Handler.used:
                self.send_error(404)
                return
            Handler.used = True
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(payload)
    server = HTTPServer(('127.0.0.1', 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    repo = Path(__file__).resolve().parents[1]
    flutter = Path.home() / 'development/flutter/bin/flutter'
    print('Flutter smoke target: LegendStudy / stlhijzpjfgwwdgunlsd', flush=True)
    print('Launching simulator test; only safe stage markers are displayed.', flush=True)
    seen = set()
    try:
        process = subprocess.Popen([str(flutter), 'test', 'integration_test/day_target_persistence_smoke_test.dart',
            '-d', args.device, '--dart-define=SMOKE_CONFIG_URL=http://127.0.0.1:' + str(server.server_port) + route],
            cwd=repo, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in process.stdout:
            for status, stage in re.findall(r'DDAY_RUNTIME (PASS|FAIL) ([a-z_]+)', line):
                allowed = {'login_preflight','fixture_profile','home_save','container_restore','home_edit','account_switch','home_clear','profile_school_preserved','fixture_cleanup','auth_users_retained'}
                if stage in allowed and (status, stage) not in seen:
                    print(f'DDAY_RUNTIME {status} {stage}', flush=True)
                    seen.add((status, stage))
        code = process.wait()
        required = {'login_preflight','home_save','container_restore','home_edit','account_switch','home_clear','profile_school_preserved','fixture_cleanup','auth_users_retained'}
        ok = code == 0 and all(('PASS', s) in seen for s in required) and not any(s == 'FAIL' for s, _ in seen)
        print('Flutter persistence smoke: ' + ('PASS' if ok else 'NOT VERIFIED / FAIL'), flush=True)
        if ('PASS','fixture_cleanup') not in seen:
            print('Fixture cleanup unconfirmed; check before rerunning. Auth users must be retained.', flush=True)
        return 0 if ok else 1
    finally:
        server.shutdown()
        server.server_close()


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (Exception, KeyboardInterrupt):
        print('Flutter smoke runner stopped; no sensitive details logged. Cleanup must be confirmed.')
        raise SystemExit(1)
