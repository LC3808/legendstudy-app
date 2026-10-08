"""Local PostgreSQL 17 role/concurrency checks. No remote/Production connection."""
import concurrent.futures
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import importlib.util
import psycopg

root=Path(__file__).resolve().parents[3]
bin_dir=Path(os.environ['PG_BIN'])

def command(args):
    subprocess.run([str(bin_dir/args[0]), *args[1:]],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)

def uid(n):return f'00000000-0000-4000-8000-{n:012d}'

with tempfile.TemporaryDirectory(prefix='legendstudy-foundation-pg-') as tmp:
    base=Path(tmp);(base/'socket').mkdir()
    command(['initdb','-D',str(base/'data'),'-U','harness','--no-locale','--encoding=UTF8','-A','trust'])
    command(['pg_ctl','-D',str(base/'data'),'-l',str(base/'server.log'),'-o',f"-k {base/'socket'} -h ''",'-w','start'])
    dsn=f"host={base/'socket'} dbname=postgres user=harness"
    try:
        with psycopg.connect(dsn,autocommit=True) as c:
            c.execute('create role postgres nosuperuser; create role anon;create role authenticated;create role service_role;grant create on database postgres to postgres;grant all on schema public to postgres;set role postgres;')
            source=(root/'supabase/verification/my_foundation/student360.mjs').read_text()
            fixture=re.search(r'await db.exec\(`(.*?)`\);',source,re.S)[1]
            fixture=fixture.replace('create role anon;create role authenticated;create role service_role;','')
            c.execute(fixture)
            lifecycle=(root/'supabase/migrations/20261001000300_account_deletion_lifecycle.sql').read_text()
            c.execute(lifecycle[lifecycle.index('create function account_private.lock_subject'):lifecycle.index('create function account_private.guard_request')])
            c.execute((root/'supabase/verification/my_foundation/fixtures/admin_operator.sql').read_text())
            c.execute((root/'supabase/migrations/20260914000100_study_sessions.sql').read_text())
            c.execute('alter table study_sessions add column include_in_study_total boolean not null default true;')
            for fn in ['public.account_deletion_personal','public.account_deletion_postconditions']:
                at=lifecycle.index('create function '+fn+'(')
                end=lifecycle.index('end$$;',at)+7
                c.execute(lifecycle[at:end])
            c.execute('create schema supabase_migrations;create table supabase_migrations.schema_migrations(version text primary key,name text,statements text[]);')
            spec=importlib.util.spec_from_file_location('activation',root/'tool/production/prepare_my_foundation.py')
            module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
            package=module.prepare('0'*40,'foundation',lambda path:(root/path).read_text())
            c.execute(package)
            assert c.execute('select count(*) from supabase_migrations.schema_migrations').fetchone()[0]==3
            try:c.execute(package)
            except psycopg.Error as e:
                assert 'MIGRATION_ALREADY_RECORDED_OR_COLLISION' in str(e)
                c.execute('rollback')
            else:raise AssertionError('activation replay accepted')
            c.execute('insert into auth.users values(%s),(%s),(%s),(%s)',[uid(1),uid(2),uid(3),uid(4)])
            c.execute('insert into profiles(id) select id from auth.users')
            c.execute('insert into universities(id,name) values(%s,%s)',[uid(5),'Test University'])
            c.execute('insert into admin_users values(%s)',[uid(3)])
            c.execute('insert into quality_operators values(%s)',[uid(4)])
        def session(c,owner,role='authenticated'):
            c.execute('set role '+role)
            c.execute("select set_config('request.jwt.claim.sub',%s,false),set_config('request.jwt.claims',%s,false)",[owner,json.dumps(dict(sub=owner,role=role,exp=9999999999))])
        def save():
            with psycopg.connect(dsn,autocommit=True) as c:
                session(c,uid(1))
                return c.execute("select my_application_save(null,0,2027,%s,'Business','Early','Essay',%s)",[uid(5),uid(6)]).fetchone()[0]
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            ids=list(pool.map(lambda _:save(),range(8)))
        assert len(set(ids))==1
        app=ids[0]
        def event():
            with psycopg.connect(dsn,autocommit=True) as c:
                session(c,uid(1))
                return c.execute("select my_application_event(%s,'submitted',null,null,%s)",[app,uid(7)]).fetchone()[0]
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            ids=list(pool.map(lambda _:event(),range(8)))
        assert len(set(ids))==1
        with psycopg.connect(dsn,autocommit=True) as c:
            for owner,role in [(uid(1),'authenticated'),(uid(4),'authenticated'),('','anon')]:
                c.execute('reset role');session(c,owner,role)
                try:c.execute('select admin_student360(%s)',[uid(1)])
                except psycopg.Error as e:assert e.sqlstate=='42501'
                else:raise AssertionError('unauthorized admin read succeeded')
            c.execute('reset role');session(c,uid(3));data=c.execute('select admin_student360(%s)',[uid(1)]).fetchone()[0]
            assert len(data['applications']['items'])==1
            c.execute('reset role');session(c,uid(1));assert c.execute('select my_study_summary()').fetchone()[0]['last30_ms']==0
            c.execute('reset role');c.execute('set role postgres')
            assert c.execute("select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','student_private') and (p.proname like 'my_application%%' or p.proname in ('my_study_summary','my_essay_summary','admin_student360')) and (pg_get_userbyid(p.proowner)<>'postgres' or p.proconfig is distinct from %s::text[])", [['search_path=""']]).fetchone()[0]==0
            assert c.execute("select rolsuper from pg_roles where rolname='postgres'").fetchone()[0] is False
            c.execute('delete from auth.users where id=%s',[uid(1)])
            assert c.execute('select count(*) from student_application_events').fetchone()[0]==0
        print('POSTGRES17_REAL_ROLES PASS: NOSUPERUSER postgres nested helpers, eight-way save/event idempotency, anonymous/normal/quality-only deny, admin allow, ownership/search_path and Auth cascade')
    finally:
        command(['pg_ctl','-D',str(base/'data'),'-m','immediate','-w','stop'])
