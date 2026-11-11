"""Local synthetic fixtures only. Never accepts a production DSN."""
import os
from pathlib import Path
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PG = Path('/opt/homebrew/opt/postgresql@17/bin')
# Fixed localhost port; fail if occupied. Never use a pre-existing database/server.
with tempfile.TemporaryDirectory(prefix='task04b-isolated-') as tmp:
    path = Path(tmp)
    subprocess.run([str(PG/'initdb'), '-D', str(path/'data'), '-A', 'trust', '-U', 'postgres'], check=True, stdout=subprocess.DEVNULL)
    started = False
    try:
        subprocess.run([str(PG/'pg_ctl'), '-D', str(path/'data'), '-l', str(path/'server.log'), '-o', f'-p 55450 -k {tmp} -h 127.0.0.1', 'start'], check=True)
        started = True
        psql = [str(PG/'psql'), '-X', '-h', '127.0.0.1', '-p', '55450', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1']
        original = ROOT/'supabase/candidates/task04_home_20261111'
        subprocess.run(psql+['-f', str(original/'isolated_bootstrap.sql'), '-c', 'create role service_role bypassrls; alter default privileges in schema public grant all on tables to anon,authenticated,service_role; alter default privileges in schema public grant execute on functions to anon,authenticated,service_role;', '-f', str(original/'candidate.sql'), '-f', str(original/'isolated_test.sql')], check=True)
        env = dict(os.environ, TASK04B_ISOLATED='1', TASK04B_RESULTS=tmp)
        for script in ['verify_original_local.py', 'verify_a_local.py']:
            subprocess.run(['python3', str(HERE/script)], check=True, env=env)
        subprocess.run(psql+['-f', str(HERE/'verify_c_readonly.sql')], check=True)
        print('PASS: original counterexamples reproduced; revised A checks and rollback passed.')
    finally:
        if started:
            subprocess.run([str(PG/'pg_ctl'), '-D', str(path/'data'), 'stop', '-m', 'fast'], check=True)
