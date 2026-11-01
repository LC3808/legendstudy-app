"""Run only on a fresh disposable local DB; never accepts a remote DSN."""
import pathlib, subprocess, uuid, re
HERE = pathlib.Path(__file__).resolve().parent
PG = '/opt/homebrew/opt/postgresql@17/bin/psql'
BASE = [PG, '-X', '-h', '127.0.0.1', '-p', '55439', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-Atq']
DB = 'task09_gate_' + uuid.uuid4().hex[:10]
def sql(text, db=DB):
    r = subprocess.run(BASE + ['-d', db], input=text, text=True, capture_output=True)
    if r.returncode: raise AssertionError(r.stderr)
    return r.stdout
sql(f'create database {DB}', 'postgres')
try:
    source = (HERE.parent / 'notices_v1/local_test.sql').read_text()
    source = re.sub(r'create role (anon|authenticated|service_role);', lambda m: f"do $$begin if not exists(select 1 from pg_roles where rolname='{m[1]}') then create role {m[1]};end if;end$$;", source)
    source = re.sub(r'create function public.admin_operator\(\).*?\$\$;', (HERE / 'admin_gate.sql').read_text(), source, flags=re.S)
    source = re.sub(r"(select set_config\('request.jwt.claim.sub','([^']*)',false\);)", lambda m: m[1]+"\nselect set_config('request.jwt.claims',jsonb_build_object('sub','"+m[2]+"','role','authenticated','exp',extract(epoch from now())+3600)::text,false);", source)
    for name in ('install.sql','rollback.sql'):
        source = source.replace('\\ir '+name, (HERE.parent/'notices_v1'/name).read_text())
    result = sql(source)
    assert 'NOTICE CONTRACT PASS' in result
    print('PASS existing notice behavior, schedule, expiry, channel/read sync, denial, rollback with real admin gate')
    print(sql("""
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select set_config('request.jwt.claims','{}',false);
select public.assert_ok(not public.admin_operator(),'missing claims denied');
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated","exp":0}',false);
select public.assert_ok(not public.admin_operator(),'expired claims denied');
select set_config('request.jwt.claims','malformed',false);
select public.assert_ok(not public.admin_operator(),'malformed claims denied');
select set_config('request.jwt.claims',jsonb_build_object('sub','different','role','authenticated','exp',extract(epoch from now())+3600)::text,false);
select public.assert_ok(not public.admin_operator(),'subject mismatch denied');
select 'PASS missing/expired/malformed/mismatched request contexts';
""").splitlines()[-1])
finally:
    sql(f'drop database {DB}', 'postgres')
