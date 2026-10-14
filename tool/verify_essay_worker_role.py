"""Local PG17 role switching, replay and rollback. No remote DSN or credentials."""
import os, subprocess, tempfile
from pathlib import Path
R=Path(__file__).resolve().parents[1]
PG=Path('/opt/homebrew/opt/postgresql@17/bin')
env={k:v for k,v in os.environ.items() if not k.startswith('PG')}
with tempfile.TemporaryDirectory(prefix='essay-worker-role-',dir='/private/tmp') as root:
    root=Path(root);sock=root/'socket';sock.mkdir()
    def run(args, **kw):return subprocess.run([str(x) for x in args],env=env,capture_output=True,text=True,**kw)
    p=run([PG/'initdb','-D',root/'db','-U','postgres','--auth=trust','--no-locale','--encoding=UTF8']);assert p.returncode==0,p.stderr
    started=False
    try:
        p=run([PG/'pg_ctl','-D',root/'db','-l',root/'server.log','-o',f"-k {sock} -p 5432 -c listen_addresses=''",'-w','start']);assert p.returncode==0,p.stderr;started=True
        def sql(s, deny=False):
            p=run([PG/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','postgres'],input=s)
            if deny:assert p.returncode!=0,p.stdout
            else:assert p.returncode==0,p.stderr
            return p.stdout.strip()
        sql('create role authenticator login noinherit; create role essay_worker nologin; create role essay_executor nologin bypassrls; create role authenticated; create role anon;')
        sql('set session authorization authenticator;set role essay_worker;',deny=True)
        migration=next((R/'supabase/migrations').glob('*_essay_worker_gateway_role.sql')).read_text()
        sql(migration);sql(migration)
        assert sql('set session authorization authenticator;set role essay_worker;select current_user;')=='essay_worker'
        assert sql("select inherit_option||','||set_option||','||admin_option from pg_auth_members where member='authenticator'::regrole and roleid='essay_worker'::regrole")=='false,true,false'
        for role in ('anon','authenticated'):
            sql(f'set session authorization {role};set role essay_worker;',deny=True)
        sql('set session authorization essay_worker;set role essay_executor;',deny=True)
        sql((R/'supabase/reviews/essay-worker-gateway/rollback.sql').read_text())
        sql('set session authorization authenticator;set role essay_worker;',deny=True)
        print('PASS: gateway SET ROLE only; no inherited/admin/executor/student grant; reapply and rollback verified. No remote changes.')
    finally:
        if started:run([PG/'pg_ctl','-D',root/'db','-m','immediate','stop'])
