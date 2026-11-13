"""Disposable local PostgreSQL only. Never accepts a remote connection URL."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent
pg = Path('/opt/homebrew/opt/postgresql@17/bin')
with tempfile.TemporaryDirectory(prefix='legend-pdf-') as temp:
    data = Path(temp) / 'data'
    def run(args, **kwargs):
        result = subprocess.run(args, capture_output=True, text=True, **kwargs)
        if result.returncode:
            raise RuntimeError(result.stderr)
        return result
    run([str(pg/'initdb'), '-D', str(data), '-A', 'trust', '--no-locale', '-E', 'UTF8'])
    run([str(pg/'pg_ctl'), '-D', str(data), '-l', str(Path(temp)/'server.log'), '-o', f"-k {temp} -p 55439 -c listen_addresses=''", '-w', 'start'])
    command = [str(pg/'psql'), '-h', temp, '-p', '55439', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-At']
    def sql(query):
        return run(command, input=query).stdout.strip()
    try:
        for filename in ['baseline-fixture.sql','baseline-apply.sql','fixture-resources.sql']:
            run(command+['-f', str(root/filename)])
        # A current registry change must fail with counts, without granting anything.
        target = '05dc696a-7ff0-5406-9162-ddfe2f85c754'
        sql(f"update public.resources set is_active=false where id='{target}'")
        rejected = subprocess.run(command+['-f', str(root/'apply.sql')],capture_output=True,text=True)
        assert rejected.returncode != 0 and 'PDF845-R2 Registry mismatch: expected=845 input=845 matched=844' in rejected.stderr, rejected.stderr
        assert sql("select count(*) from material_download_private.permissions") == '0'
        sql(f"update public.resources set is_active=true where id='{target}'")
        applied = run(command+['-f', str(root/'apply.sql')])
        assert 'PDF845-R2|' in applied.stdout and '|845|845' in applied.stdout
        assert sql("select count(*) from material_download_private.permissions") == '845'
        assert sql("set role anon; select count(*) from public.resources where public.resource_download_policy(id)->>'state'='ALLOWED'").splitlines()[-1] == '845'
        assert sql("select public.resource_download_policy('78960745-ee6a-5045-842f-08738ac1fe44')->>'state'") != 'ALLOWED'
        replay = subprocess.run(command+['-f', str(root/'apply.sql')],capture_output=True,text=True)
        assert replay.returncode != 0 and 'Permission history changed' in replay.stderr
        run(command+['-f', str(root/'rollback.sql')])
        assert sql("select count(*) from public.resources where public.resource_download_policy(id)->>'state'='ALLOWED'") == '0'
        assert sql("select count(*) from material_download_private.permissions where state='ALLOWED'") == '845'
        assert sql("select count(*) from material_download_private.permissions where state='VIEW_ONLY'") == '845'
        print('PASS: 845 active / retired excluded / guest / replay rejected / append-only rollback')
    finally:
        run([str(pg/'pg_ctl'), '-D', str(data), '-m', 'fast', '-w', 'stop'])
