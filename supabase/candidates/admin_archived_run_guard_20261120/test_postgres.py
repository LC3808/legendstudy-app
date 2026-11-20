#!/usr/bin/env python3
"""Synthetic-only real PostgreSQL archive guards. No remote connection configuration."""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import json
import os
import subprocess
import time
import unittest
import uuid

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
PG='/opt/homebrew/opt/postgresql@17/bin/psql'
DB='admin_archive_test'
ADMIN='00000000-0000-4000-8000-000000000001'
OWNER='00000000-0000-4000-8000-000000000002'
EXAM='00000000-0000-4000-8000-000000000003'

def lit(v):
    if v is None:return 'null'
    if isinstance(v,bool):return str(v).lower()
    if isinstance(v,(dict,list)):v=json.dumps(v)
    return "'"+str(v).replace("'","''")+"'"

def sql(s,actor=ADMIN,role=None,db=DB,user='postgres'):
    prefix="set statement_timeout='8s';set lock_timeout='6s';"
    if actor:prefix+='set test.actor='+lit(actor)+';'
    if role:
        assert role in ('authenticated','anon','essay_worker','service_role')
        prefix+='set role '+role+';'
    p=subprocess.run([PG,'-X','-h','/private/tmp','-p','55441','-U',user,'-d',db,'-Atq','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose'],input=prefix+s,text=True,capture_output=True,timeout=12)
    if p.returncode:raise RuntimeError(p.stderr.strip())
    return p.stdout.strip()

def scalar(s,**kwargs):
    lines=sql(s,**kwargs).splitlines()
    return lines[-1] if lines else ''

def rpc(name,*args,**kwargs):
    out=scalar('select public.'+name+'('+','.join(lit(x) for x in args)+')',**kwargs)
    try:return json.loads(out)
    except json.JSONDecodeError:return out

def protected(run):
    return json.loads(scalar(f"select jsonb_build_object('run',(select to_jsonb(r) from essay_exam_private.runs r where id={lit(run)}),'checkpoints',(select jsonb_agg(to_jsonb(c) order by key) from essay_exam_private.checkpoints c where run_id={lit(run)}),'billing',(select to_jsonb(b) from public.essay_billing_decisions b join essay_exam_private.runs r on r.decision_id=b.id where r.id={lit(run)}),'ledger',(select jsonb_agg(to_jsonb(t) order by t.id) from public.credit_transactions t join essay_exam_private.runs r on r.decision_id=t.decision_id where r.id={lit(run)}),'retries',(select jsonb_agg(to_jsonb(t) order by generation) from essay_exam_private.retry_requests t where run_id={lit(run)}))"))

def initialize():
    admin=os.environ.get('USER','woojinchang')
    assert scalar('show data_directory',db='postgres',user=admin)=='/private/tmp/legendstudy-dday-pg'
    sql("do $$begin if not exists(select 1 from pg_roles where rolname='essay_worker') then create role essay_worker nologin;end if;end$$;alter role postgres nosuperuser bypassrls;grant essay_worker,authenticated,anon,service_role to postgres;",db='postgres',user=admin)
    sql('drop database if exists '+DB,db='postgres',user=admin)
    sql('create database '+DB+' owner postgres',db='postgres',user=admin)
    for f in [HERE.parent/'admin_run_management_20261120/fixture.sql',HERE/'fixture_extra.sql',HERE.parent/'admin_run_management_20261120/install.sql',HERE/'preimage.sql',HERE/'session_claim_preimage.sql']:
        sql(f.read_text())
    # Restore captured ACLs, including Worker-only execution of trusted subject RPCs.
    for row in json.loads((HERE/'preimage.json').read_text())['functions']:
        name=row['proname'];signature='public.'+row['signature']
        sql(f'revoke all on function {signature} from public,anon,authenticated,essay_worker,service_role')
        role='authenticated' if name.startswith('admin_') or name in ('essay_exam_session_status','essay_exam_observation') else 'essay_worker'
        sql(f'grant execute on function {signature} to {role}')
    sql('revoke all on function public.essay_exam_session_claim(uuid,uuid,uuid) from public,anon,authenticated,service_role;grant execute on function public.essay_exam_session_claim(uuid,uuid,uuid) to essay_worker')
    existing=rpc('make_run',0)
    before=protected(existing)
    acl_before=scalar("select jsonb_agg(jsonb_build_object('name',proname,'acl',proacl) order by proname) from pg_proc where pronamespace='public'::regnamespace and proname in ("+','.join(lit(r['proname']) for r in json.loads((HERE/'preimage.json').read_text())['functions'])+")")
    sql((HERE/'install.sql').read_text())
    assert before==protected(existing),'Installer mutated existing run/checkpoints/billing/ledger/retry'
    assert acl_before==scalar("select jsonb_agg(jsonb_build_object('name',proname,'acl',proacl) order by proname) from pg_proc where pronamespace='public'::regnamespace and proname in ("+','.join(lit(r['proname']) for r in json.loads((HERE/'preimage.json').read_text())['functions'])+")"),'Existing RPC ACL changed'
    assert scalar("select rolsuper from pg_roles where rolname=current_user")=='f'
    defs=json.loads(scalar("select jsonb_agg(jsonb_build_object('signature',p.oid::regprocedure::text,'md5',md5(pg_get_functiondef(p.oid))) order by p.proname) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ("+','.join(lit(r['proname']) for r in json.loads((HERE/'preimage.json').read_text())['functions'])+",'essay_exam_dispatch_guard')"))
    values=','.join('('+lit('public.'+x['signature'])+','+lit(x['md5'])+')' for x in defs)
    rollback="-- Revert Worker adapter first. RPC source rollback only; preserve all operational rows.\nbegin;\ndo $$declare x record;begin for x in select * from (values "+values+") v(signature,expected_md5) loop if md5(pg_get_functiondef(x.signature::regprocedure))<>x.expected_md5 then raise exception 'POSTIMAGE_CHANGED: %',x.signature;end if;end loop;end$$;\n"+(HERE/'preimage.sql').read_text()+"drop function public.essay_exam_dispatch_guard(uuid,uuid);\nnotify pgrst,'reload schema';\ncommit;\n"
    (HERE/'rollback.sql').write_text(rollback)
    return defs

class ArchiveTests(unittest.TestCase):
    serial=0
    def setUp(self):
        ArchiveTests.serial+=1
        self.run=rpc('make_run',ArchiveTests.serial)
        self.key=str(uuid.uuid4())
        sql(f"update essay_exam_private.runs set dispatch_key=gen_random_uuid() where id={lit(self.run)}")
        sql(f"insert into public.credit_transactions(id,decision_id,balance_delta,reserved_delta) select gen_random_uuid(),decision_id,0,1 from essay_exam_private.runs where id={lit(self.run)}")
    def hide(self,hidden=True):return rpc('admin_lab_set_run_hidden',self.run,hidden,role='authenticated')
    def manage(self,action,key=None):return rpc('admin_lab_manage_run',self.run,action,key or self.key,role='authenticated')
    def caps(self):return rpc('admin_lab_run_capabilities',self.run,role='authenticated')
    def claim(self):return rpc('essay_exam_claim',OWNER,self.run,scalar(f"select dispatch_key from essay_exam_private.runs where id={lit(self.run)}") or str(uuid.uuid4()),role='essay_worker')
    def test_archive_excludes_live_kpi_keeps_history_and_ledger(self):
        before=rpc('admin_essay_operations','2026-01-01','2026-03-01',{},0,None,role='authenticated')
        state=protected(self.run)
        self.hide()
        after=rpc('admin_essay_operations','2026-01-01','2026-03-01',{},0,None,role='authenticated')
        self.assertEqual(after['live']['processing'],before['live']['processing']-1)
        self.assertEqual(after['live']['retry_pending'],before['live']['retry_pending']-1)
        self.assertEqual(after['live']['archived'],before['live']['archived']+1)
        self.assertEqual(before['summary'],after['summary'])
        self.assertEqual(protected(self.run),state)
    def test_archived_claim_bounded_and_session_wrapper(self):
        self.hide();before=protected(self.run)
        self.assertEqual(self.claim(),{'state':'archived','run_id':self.run,'dispatch_allowed':False})
        out=rpc('essay_exam_session_claim',OWNER,self.run,str(uuid.uuid4()),role='essay_worker')
        self.assertEqual(out['state'],'archived');self.assertNotIn('snapshot',out);self.assertNotIn('lease_token',out)
        self.assertEqual(before,protected(self.run))
    def test_archived_retry_and_capability(self):
        self.hide();before=protected(self.run)
        self.assertEqual(self.caps()['retry_reason'],'RUN_ARCHIVED')
        with self.assertRaisesRegex(RuntimeError,'RUN_ARCHIVED'):self.manage('retry')
        with self.assertRaisesRegex(RuntimeError,'RUN_ARCHIVED'):rpc('essay_exam_retry',OWNER,self.run,self.key,EXAM,role='essay_worker')
        self.assertEqual(before,protected(self.run))
    def test_retry_replay_is_blocked_after_archive(self):
        self.manage('retry')
        sql(f"update essay_exam_private.retry_requests set lease_until=now()-interval '1 minute' where run_id={lit(self.run)}")
        self.hide();before=protected(self.run)
        with self.assertRaisesRegex(RuntimeError,'RUN_ARCHIVED'):self.manage('retry')
        with self.assertRaisesRegex(RuntimeError,'RUN_ARCHIVED'):rpc('essay_exam_retry',OWNER,self.run,self.key,EXAM,role='essay_worker')
        self.assertEqual(before,protected(self.run))
    def test_restore_only_changes_visibility_no_auto_execution(self):
        self.hide();before=protected(self.run)
        self.manage('restore')
        self.assertFalse(self.caps()['hidden']);self.assertTrue(self.caps()['retry_allowed'])
        self.assertEqual(before,protected(self.run))
    def test_active_run_lease_archive_denied_legacy_and_manage(self):
        sql(f"update essay_exam_private.runs set lease_until=now()+interval '1 hour' where id={lit(self.run)}")
        self.assertEqual(self.caps()['archive_reason'],'ACTIVE_LEASE')
        with self.assertRaisesRegex(RuntimeError,'ACTIVE_LEASE'):self.hide()
        with self.assertRaisesRegex(RuntimeError,'ACTIVE_LEASE'):self.manage('archive')
        self.assertFalse(self.caps()['hidden'])
    def test_active_retry_lease_archive_denied(self):
        self.manage('retry')
        with self.assertRaisesRegex(RuntimeError,'ACTIVE_LEASE'):self.hide()
        self.assertFalse(self.caps()['archive_allowed'])
    def test_pending_or_reconciling_work_not_archived(self):
        for state,payload in [('pending',None),('checkpoint',{'state':'reconciling'})]:
            sql(f"update essay_exam_private.checkpoints set state={lit(state)},payload={lit(payload)}::jsonb where run_id={lit(self.run)}")
            with self.assertRaisesRegex(RuntimeError,'RECONCILIATION_REQUIRED'):self.hide()
            self.assertEqual(self.caps()['archive_reason'],'RECONCILIATION_REQUIRED')
    def test_undispatched_or_missing_token_not_archived(self):
        sql(f"update essay_exam_private.runs set dispatch_key=null where id={lit(self.run)}")
        with self.assertRaisesRegex(RuntimeError,'RECONCILIATION_REQUIRED'):self.hide()
        self.assertEqual(self.caps()['archive_reason'],'RECONCILIATION_REQUIRED')
        sql(f"update essay_exam_private.runs set dispatch_key=gen_random_uuid(),lease_token=null where id={lit(self.run)}")
        with self.assertRaisesRegex(RuntimeError,'RECONCILIATION_REQUIRED'):self.hide()
    def test_final_checkpoint_reserved_needs_reconciliation(self):
        for state,payload in [('pending',None),('checkpoint',{'state':'completed','result':'SYNTHETIC'})]:
            sql(f"insert into essay_exam_private.checkpoints values({lit(self.run)},'final',gen_random_uuid(),{lit(state)},{lit(payload)}::jsonb) on conflict(run_id,key) do update set state=excluded.state,payload=excluded.payload")
            before=protected(self.run)
            with self.assertRaisesRegex(RuntimeError,'RECONCILIATION_REQUIRED'):self.hide()
            with self.assertRaisesRegex(RuntimeError,'RECONCILIATION_REQUIRED'):self.manage('archive')
            self.assertEqual(self.caps()['archive_reason'],'RECONCILIATION_REQUIRED')
            self.assertEqual(protected(self.run),before)
    def test_checkpoint_begin_blocked_but_original_evidence_preserved(self):
        token=scalar(f"select lease_token from essay_exam_private.runs where id={lit(self.run)}")
        writer=str(uuid.uuid4())
        self.hide()
        for name in ['essay_exam_checkpoint','essay_exam_session_checkpoint']:
            with self.assertRaisesRegex(RuntimeError,'RUN_ARCHIVED'):rpc(name,OWNER,self.run,token,'q1','begin',writer,None,role='essay_worker')
        # Existing completed checkpoint can still be read/replayed by its original writer.
        original=scalar(f"select writer from essay_exam_private.checkpoints where run_id={lit(self.run)} and key='q0'")
        self.assertEqual(rpc('essay_exam_checkpoint',OWNER,self.run,token,'q0','read',None,None,role='essay_worker')['payload'],{'state':'failed'})
        self.assertTrue(rpc('essay_exam_session_checkpoint',OWNER,self.run,token,'q0','write',original,{'state':'failed'},role='essay_worker')['stored'])
    def test_guard_read_only_and_wrong_owner(self):
        self.hide();before=protected(self.run)
        out=json.loads(scalar(f"begin read only;select public.essay_exam_dispatch_guard({lit(OWNER)},{lit(self.run)});rollback;",role='essay_worker'))
        self.assertEqual(out,{'run_id':self.run,'state':'archived'})
        with self.assertRaises(RuntimeError):rpc('essay_exam_dispatch_guard',str(uuid.uuid4()),self.run,role='essay_worker')
        with self.assertRaises(RuntimeError):rpc('essay_exam_claim',str(uuid.uuid4()),self.run,str(uuid.uuid4()),role='essay_worker')
        self.assertEqual(before,protected(self.run))
    def test_worker_guard_acl_and_nonadmin_actions(self):
        for role in ['anon','authenticated','service_role']:
            with self.assertRaises(RuntimeError):rpc('essay_exam_dispatch_guard',OWNER,self.run,role=role)
        with self.assertRaisesRegex(RuntimeError,'ADMIN_REQUIRED'):rpc('admin_lab_set_run_hidden',self.run,True,actor=OWNER,role='authenticated')
        with self.assertRaisesRegex(RuntimeError,'ADMIN_REQUIRED'):rpc('admin_lab_manage_run',self.run,'archive',self.key,actor=OWNER,role='authenticated')
        for table in ['essay_ops_private.run_actions','essay_ops_private.hidden_runs','essay_exam_private.runs','essay_exam_private.retry_requests','public.credit_transactions']:
            with self.assertRaises(RuntimeError):sql('select * from '+table,actor=OWNER,role='authenticated')
    def test_student_status_and_observation_retry_disabled(self):
        question=str(uuid.uuid4())
        sql(f"insert into public.essay_questions values({lit(question)},{lit(EXAM)},'문제1',1);update essay_exam_private.runs set snapshot=jsonb_build_object('answers',jsonb_build_array(jsonb_build_object('questionId',{lit(question)},'body','SYNTHETIC'))) where id={lit(self.run)}")
        self.hide()
        for name in ['essay_exam_session_status','essay_exam_observation']:
            result=rpc(name,self.run,actor=OWNER,role='authenticated')
            self.assertFalse(result['retry_allowed']);self.assertEqual(result['questions'][0]['state'],'failed')
    def test_archive_manage_audit_and_restoration(self):
        before=protected(self.run)
        self.manage('archive');self.manage('archive')
        self.manage('restore',str(uuid.uuid4()))
        self.assertEqual(scalar(f"select count(*) from essay_ops_private.run_actions where run_id={lit(self.run)}"),'2')
        self.assertEqual(protected(self.run),before)
    def test_claim_vs_archive_serialization(self):
        sql(f"update essay_exam_private.runs set dispatch_key=null where id={lit(self.run)}")
        with ThreadPoolExecutor(max_workers=2) as ex:
            first=ex.submit(sql,f"begin;select public.essay_exam_claim({lit(OWNER)},{lit(self.run)},{lit(self.key)});select pg_sleep(0.4);commit;",role='essay_worker')
            time.sleep(.1)
            second=ex.submit(self.hide)
            first.result()
            with self.assertRaisesRegex(RuntimeError,'ACTIVE_LEASE'):second.result()
        self.assertFalse(self.caps()['hidden'])
    def test_archive_vs_claim_serialization(self):
        with ThreadPoolExecutor(max_workers=2) as ex:
            first=ex.submit(sql,f"begin;select public.admin_lab_set_run_hidden({lit(self.run)},true);select pg_sleep(0.4);commit;",role='authenticated')
            time.sleep(.1)
            second=ex.submit(self.claim)
            first.result();self.assertEqual(second.result()['state'],'archived')
    def test_archive_vs_retry_serialization(self):
        with ThreadPoolExecutor(max_workers=2) as ex:
            first=ex.submit(sql,f"begin;select public.admin_lab_set_run_hidden({lit(self.run)},true);select pg_sleep(0.4);commit;",role='authenticated')
            time.sleep(.1)
            second=ex.submit(rpc,'essay_exam_retry',OWNER,self.run,self.key,EXAM,role='essay_worker')
            first.result()
            with self.assertRaisesRegex(RuntimeError,'RUN_ARCHIVED'):second.result()
        self.assertEqual(scalar(f"select count(*) from essay_exam_private.retry_requests where run_id={lit(self.run)}"),'0')
    def test_completed_archive_and_history_kept(self):
        sql(f"update essay_exam_private.runs set state='completed',result='{{}}',completed_at=now() where id={lit(self.run)}")
        before=protected(self.run);self.hide();self.assertEqual(protected(self.run),before)
        self.assertEqual(self.claim()['state'],'archived')
    def test_z_rollback_preserves_data_restores_hashes_and_acl(self):
        self.hide()
        before=protected(self.run)
        rows=json.loads((HERE/'preimage.json').read_text())['functions']
        names=','.join(lit(r['proname']) for r in rows)
        acl=scalar(f"select jsonb_agg(jsonb_build_object('name',proname,'acl',proacl) order by proname) from pg_proc where pronamespace='public'::regnamespace and proname in ({names})")
        sql((HERE/'rollback.sql').read_text())
        self.assertEqual(protected(self.run),before)
        self.assertEqual(scalar(f"select jsonb_agg(jsonb_build_object('name',proname,'acl',proacl) order by proname) from pg_proc where pronamespace='public'::regnamespace and proname in ({names})"),acl)
        for row in rows:self.assertEqual(scalar('select md5(pg_get_functiondef('+lit('public.'+row['signature'])+'::regprocedure))'),row['md5'])
        self.assertEqual(scalar("select to_regprocedure('public.essay_exam_dispatch_guard(uuid,uuid)') is null"),'t')

if __name__=='__main__':
    defs=initialize()
    files=[HERE/name for name in ['install.sql','preimage.json','preimage.sql','fixture_extra.sql','session_claim_preimage.sql','test_postgres.py','rollback.sql']]
    hashes={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
    result=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(ArchiveTests))
    unchanged=all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
    report={'scope':'LOCAL_SYNTHETIC_ONLY','production_mutations':0,'installer_role':'postgres NOSUPERUSER BYPASSRLS, matching inspected Production; authenticated/essay_worker NOBYPASSRLS','verified_at_utc':datetime.now(timezone.utc).isoformat(),'tests':result.testsRun,'successful':result.wasSuccessful() and unchanged,'failures':[t.id() for t,_ in result.failures],'errors':[t.id() for t,_ in result.errors],'source_sha256':hashes,'installed_function_md5':defs,'limits':['Minimal existing schema/admin/lifecycle fixture; exact captured RPCs and real roles/locks used.','No actual student archive/retry/refund operation; hosted JWT and Worker transport tested separately.']}
    (HERE/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    raise SystemExit(0 if report['successful'] else 1)
