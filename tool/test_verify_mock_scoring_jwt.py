"""Offline tests: private PostgreSQL Unix socket, synthetic identities, NO live HTTP.

The SQL-backed transport checks verifier logic, NOT production JWT evidence.
Set SCORING_PG_BIN to PostgreSQL17 native bin directory; no external DSN accepted.
"""
import contextlib
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import urllib.parse
import uuid

import psycopg
from psycopg import sql
from psycopg.rows import dict_row
from psycopg.types.json import Jsonb

from verify_mock_scoring_jwt import (Acceptance, AdminFixtures, EMAILS, HOST, TRIGGERS,
                                      admin_settings, identifier)
from verify_study_sessions_jwt import Response

ROOT=Path(__file__).resolve().parents[1]
OWNERS={who:str(uuid.uuid4()) for who in EMAILS}
CONFIG={'SUPABASE_URL':HOST,'SUPABASE_PUBLISHABLE_KEY':'sb_'+'publishable_'+'offline'}
SECRET='private-offline-canary-do-not-print'


class SqlTransport:
    """Translate only this verifier's REST subset into local role-constrained SQL."""
    def __init__(self, db):
        self.db=db
        self.calls=[]
        self.lose_once=False

    def __call__(self,method,path,data=None,token=None,prefer=None):
        self.calls.append((method,path))
        if path.startswith('/auth/v1/token'):
            who=next(w for w,e in EMAILS.items() if e==data['email'])
            return Response(200,{'access_token':SECRET+who,'user':{'id':OWNERS[who],'email':EMAILS[who]}})
        who=next(w for w in EMAILS if token==SECRET+w)
        if path=='/auth/v1/user':
            return Response(200,{'id':OWNERS[who]})
        if path.startswith('/auth/v1/logout'):
            return Response(204,None)
        try:
            with self.db.transaction():
                self.db.execute('set local role authenticated')
                self.db.execute("select set_config('request.jwt.claim.sub',%s,true)",(OWNERS[who],))
                if path.startswith('/rest/v1/rpc/'):
                    name=path.split('/')[-1]
                    params=list(data.values())
                    if name=='submit_mock_attempt':
                        params[-1]=Jsonb(params[-1])
                    query=sql.SQL('select public.{}({}) as result').format(sql.Identifier(name),
                        sql.SQL(',').join(sql.SQL('{} => %s').format(sql.Identifier(k)) for k in data))
                    value=self.db.execute(query,params).fetchone()[0]
                else:
                    table=path.split('/')[3].split('?')[0]
                    args=urllib.parse.parse_qs(urllib.parse.urlsplit(path).query)
                    filters=[]; values=[]
                    for key, vals in args.items():
                        if key=='select':continue
                        assert vals[0].startswith('eq.')
                        filters.append(sql.SQL('{}=%s').format(sql.Identifier(key)))
                        values.append(vals[0][3:])
                    where=sql.SQL(' where ')+sql.SQL(' and ').join(filters) if filters else sql.SQL('')
                    selected=args.get('select',['*'])[0]
                    columns=sql.SQL('*') if selected=='*' else sql.SQL(',').join(map(sql.Identifier,selected.split(',')))
                    # PostgREST representation selects permitted columns, not private request_payload.
                    returning=columns if method == 'DELETE' else sql.SQL('*')
                    if method=='GET':
                        query=sql.SQL('select {} from {}{}').format(columns,identifier(table),where)
                    elif method=='POST':
                        query=sql.SQL('insert into {} ({}) values ({}) returning {}').format(identifier(table),
                            sql.SQL(',').join(map(sql.Identifier,data)),sql.SQL(',').join(sql.Placeholder() for _ in data),returning)
                        values=[Jsonb(v) if isinstance(v,(dict,list)) else v for v in data.values()]
                    elif method=='PATCH':
                        query=sql.SQL('update {} set {}{} returning {}').format(identifier(table),
                            sql.SQL(',').join(sql.SQL('{}=%s').format(sql.Identifier(k)) for k in data),where,returning)
                        values=list(data.values())+values
                    elif method=='DELETE':
                        query=sql.SQL('delete from {}{} returning {}').format(identifier(table),where,returning)
                    else:raise AssertionError(method)
                    with self.db.cursor(row_factory=dict_row) as c:
                        c.execute(query,values)
                        value=json.loads(json.dumps(c.fetchall(),default=str))
            if self.lose_once and path.endswith('/rpc/submit_mock_attempt'):
                self.lose_once=False
                raise TimeoutError(SECRET)
            return Response(201 if method=='POST' and '/rpc/' not in path else 200,value)
        except psycopg.Error as e:
            status=403 if e.sqlstate=='42501' else 409 if e.sqlstate in ('23505','23503') else 400
            return Response(status,{'code':e.sqlstate,'message':e.diag.message_primary,'details':SECRET})


class StorageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.bin=Path(os.environ['SCORING_PG_BIN'])
        cls.temp=Path(tempfile.mkdtemp(prefix='ls-score-',dir='/private/tmp'))
        cls.socket=cls.temp/'s';cls.socket.mkdir()
        cls.data=cls.temp/'d'
        def command(name,*args):
            return subprocess.run([str(cls.bin/name),*args],check=True,capture_output=True,timeout=30)
        cls.command=staticmethod(command)
        command('initdb','-D',str(cls.data),'-U','fixture_admin','--auth-local=trust','--auth-host=reject','--encoding=UTF8','--locale=C')
        command('pg_ctl','-D',str(cls.data),'-l',str(cls.temp/'server.log'),'-o',
                f"-k {cls.socket} -p 65432 -c listen_addresses='' -c unix_socket_permissions=0700",'-w','start')
        cls.root=psycopg.connect(host=str(cls.socket),port=65432,user='fixture_admin',dbname='postgres',autocommit=True)
        cls.root.execute('create database scoring_template')
        with psycopg.connect(host=str(cls.socket),port=65432,user='fixture_admin',dbname='scoring_template',autocommit=True) as db:
            db.execute("""create role anon;create role authenticated;create role service_role bypassrls;
              create schema auth;create table auth.users(id uuid primary key,email text);
              create function auth.uid() returns uuid language sql stable as $$
              select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
              grant usage on schema public,auth to anon,authenticated,service_role;
              grant execute on function auth.uid() to public;""")
            for migration in sorted((ROOT/'supabase/migrations').glob('*.sql')):
                db.execute(migration.read_text())
            for who in EMAILS:
                db.execute('insert into auth.users values(%s,%s)',(OWNERS[who],EMAILS[who]))
            db.execute("""insert into public.profiles(id,display_name,grade_level,neis_office_code,neis_school_code,target_date,target_label)
              values(%s,'Preserve fixture profile',1,'J10','7530932','2026-10-01','Preserve target')""",(OWNERS['A'],))

    @classmethod
    def tearDownClass(cls):
        cls.root.close()
        cls.command('pg_ctl','-D',str(cls.data),'-m','immediate','-w','stop')
        shutil.rmtree(cls.temp)

    def setUp(self):
        self.name='case_'+uuid.uuid4().hex
        self.root.execute(sql.SQL('create database {} template scoring_template').format(sql.Identifier(self.name)))
        args=dict(host=str(self.socket),port=65432,user='fixture_admin',dbname=self.name,autocommit=True)
        self.db=psycopg.connect(**args)
        self.httpdb=psycopg.connect(**args)
        self.admin=AdminFixtures(self.db)
        self.transport=SqlTransport(self.httpdb)
        self.app=Acceptance(CONFIG,self.transport)
        self.app.login(dict.fromkeys(EMAILS,SECRET))
        self.admin.preflight(OWNERS)
        self.app.admin=self.admin

    def tearDown(self):
        self.db.close();self.httpdb.close()
        self.root.execute(sql.SQL('drop database {}').format(sql.Identifier(self.name)))

    def test_full_acceptance_and_cleanup(self):
        output=io.StringIO()
        with contextlib.redirect_stdout(output):
            self.app.exercise()
            self.admin.cleanup()
            self.assertTrue(self.app.finish_auth())
        for stage in ('publish_fixture','valid_submit','fetch_own','direct_forgery_denied',
                      'ownership_isolation','idempotent_retry','current_version','invalid_inputs',
                      'study_delete_semantics','owner_delete','fixture_scope_verified','fixture_cleanup',
                      'cleanup_triggers_restored','scoring_baseline_restored','existing_data_preserved','auth_users_retained'):
            self.assertIn('SCORING_RUNTIME PASS '+stage,output.getvalue())
        self.assertNotIn(SECRET,output.getvalue())
        self.assertEqual(self.admin.snapshot(),self.admin.baseline)

    def test_preflight_does_not_write(self):
        self.assertEqual(self.admin.snapshot(),self.admin.baseline)
        self.assertFalse(self.admin.started)
        self.assertFalse(any('/rest/' in p and m!='GET' for m,p in self.transport.calls))

    def test_cleanup_rollback_every_step(self):
        from verify_mock_scoring_jwt import DELETE_ORDER
        self.admin.create()
        p=self.app.payload();self.app.result(p)
        before=self.admin.snapshot()
        def fail_at(target):
            def fail(stage):
                if stage==target:raise RuntimeError('injected')
            return fail
        for stage in ('disabled',*DELETE_ORDER,'before_commit'):
            with self.subTest(stage=stage),self.assertRaises(RuntimeError):
                self.admin.cleanup(fail_at(stage))
            self.assertEqual(self.admin.trigger_state(),self.admin.original_triggers)
            self.assertEqual(self.admin.snapshot(),before)
        self.admin.cleanup()

    def test_count_mismatch_stops_before_delete(self):
        self.admin.create()
        self.db.execute('delete from public.answer_key_versions where id=%s',(self.admin.ids['incomplete'],))
        before=self.admin.snapshot()
        with self.assertRaises(Exception):self.admin.cleanup()
        self.assertEqual(self.admin.snapshot(),before)
        self.assertEqual(self.admin.trigger_state(),self.admin.original_triggers)

    def test_existing_data_drift_stops(self):
        self.admin.create()
        self.db.execute("update public.profiles set display_name='External change' where id=%s",(OWNERS['A'],))
        before=self.admin.snapshot()
        with self.assertRaises(Exception):self.admin.cleanup()
        self.assertEqual(self.admin.snapshot(),before)
        self.assertEqual(self.admin.trigger_state(),self.admin.original_triggers)

    def test_trigger_drift_stops(self):
        self.admin.create()
        self.db.execute('alter table public.answer_key_versions disable trigger scoring_key_publication')
        before=self.admin.snapshot()
        with self.assertRaises(Exception):self.admin.cleanup()
        self.assertEqual(self.admin.snapshot(),before)
        self.assertIn(('answer_key_versions','scoring_key_publication','D',False,'0'),self.admin.trigger_state())

    def test_network_loss_committed_attempt_cleanup(self):
        self.admin.create();self.transport.lose_once=True
        with self.assertRaises(TimeoutError):self.app.result(self.app.payload())
        self.assertEqual(self.admin.manifest['mock_exam_attempts'][0],1)
        self.admin.cleanup()
        self.assertEqual(self.admin.snapshot(),self.admin.baseline)

    def test_existing_scoring_preflight_stops(self):
        self.admin.create()
        other=AdminFixtures(self.db)
        with self.assertRaises(Exception):other.preflight(OWNERS)
        self.assertFalse(other.started)
        self.admin.cleanup()

    def test_admin_identity_mismatch_stops(self):
        with self.assertRaises(Exception):
            AdminFixtures(self.db).preflight({**OWNERS,'B':str(uuid.uuid4())})

    def test_fk_reference_outside_run_not_deleted(self):
        self.admin.create()
        self.db.execute("""insert into public.content_items(source_post_id,source_content_key,slug,content_type,title,source_url)
            values(%s,'foreign','foreign','other','Not this run','https://example.invalid/foreign')""",(self.admin.ids['source'],))
        before=self.admin.snapshot()
        with self.assertRaises(Exception):self.admin.cleanup()
        self.assertEqual(self.admin.snapshot(),before)

    def test_wrong_rejection_not_accepted(self):
        self.admin.create()
        original=self.transport
        def transport(method,path,data=None,token=None,prefer=None):
            if '/rpc/submit_mock_attempt' in path:return Response(400,{'code':'22023','message':SECRET})
            return original(method,path,data,token,prefer)
        self.app.transport=transport
        with self.assertRaises(Exception):self.app.reject(self.app.payload(),'23514','KEY_UNAVAILABLE')
        self.admin.cleanup()

    def run_main(self, preflight=False, fail_result=False):
        from unittest.mock import patch
        import verify_mock_scoring_jwt as module
        with tempfile.TemporaryDirectory(prefix='ls-config-',dir='/private/tmp') as directory:
            config=Path(directory)/'public.json';config.write_text(json.dumps(CONFIG))
            connection=psycopg.connect(host=str(self.socket),port=65432,user='fixture_admin',
                                      dbname=self.name,autocommit=True)
            original=self.transport
            def transport(*args):
                result=original(*args)
                if fail_result and args[1].endswith('/rpc/submit_mock_attempt') and result.status==200:
                    result.body['raw_score']=999
                return result
            args=['verify_mock_scoring_jwt.py',str(config)]+(['--preflight-only'] if preflight else [])
            out=io.StringIO()
            with patch.object(module.sys,'argv',args), patch.object(module.sys.stdin,'isatty',return_value=True), \
                 patch.object(module.getpass,'getpass',return_value=SECRET), patch('builtins.input',return_value=''), \
                 patch.object(module,'Transport',return_value=transport), \
                 patch.object(module.psycopg,'connect',return_value=connection),contextlib.redirect_stdout(out):
                code=module.main()
            self.assertNotIn(SECRET,out.getvalue())
            return code,out.getvalue()

    def test_main_failure_finally_cleanup_no_acceptance(self):
        code,out=self.run_main(fail_result=True)
        self.assertEqual(code,1)
        self.assertIn('SCORING_RUNTIME FAIL valid_submit',out)
        self.assertIn('SCORING_RUNTIME PASS fixture_cleanup',out)
        self.assertNotIn('SCORING_RUNTIME PASS acceptance',out)
        self.assertEqual(self.admin.snapshot(),self.admin.baseline)

    def test_main_preflight_only_no_fixture(self):
        code,out=self.run_main(preflight=True)
        self.assertEqual(code,0)
        self.assertIn('SCORING_RUNTIME PASS preflight_only',out)
        self.assertNotIn('publish_fixture',out)
        self.assertNotIn('SCORING_RUNTIME PASS acceptance',out)
        self.assertEqual(self.admin.snapshot(),self.admin.baseline)


class SecurityTests(unittest.TestCase):
    def test_project_pinning(self):
        from verify_mock_scoring_jwt import REF
        good=admin_settings('db.'+REF+'.supabase.co',SECRET)
        self.assertEqual(good['user'],'postgres')
        self.assertEqual(good['port'],5432)
        pool=admin_settings('aws-0-ap-northeast-2.pooler.supabase.com',SECRET)
        self.assertEqual(pool['user'],'postgres.'+REF)
        for host in ('localhost','other.supabase.co','db.other.supabase.co','aws-0-a.pooler.supabase.com.evil','host password=x'):
            with self.subTest(host=host),self.assertRaises(Exception):admin_settings(host,SECRET)

    def test_safe_error_output(self):
        app=Acceptance(CONFIG,lambda *a:None)
        app.last=Response(400,{'code':SECRET,'message':SECRET,'details':SECRET})
        out=io.StringIO()
        with contextlib.redirect_stdout(out):app.failure(RuntimeError(SECRET))
        self.assertNotIn(SECRET,out.getvalue())
        self.assertIn('db_code=UNAVAILABLE',out.getvalue())

    def test_cleanup_sql_scope(self):
        import inspect
        source=inspect.getsource(AdminFixtures.cleanup)
        self.assertNotIn('session_replication_role',source)
        self.assertNotIn('disable trigger all',source.lower())
        self.assertNotIn('disable trigger user',source.lower())
        self.assertIn('where {} = any(%s::uuid[])',source)
        self.assertEqual(len(TRIGGERS),3)


if __name__=='__main__':
    unittest.main()
