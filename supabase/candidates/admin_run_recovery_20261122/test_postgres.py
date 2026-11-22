#!/usr/bin/env python3
"""Real PostgreSQL, real role grants, captured live RPCs, synthetic data only."""
import asyncio,hashlib,json,os,subprocess,sys,unittest,uuid,time
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2];sys.path.insert(0,str(ROOT))
from tool.test_essay_admin_recovery import recovery_fixture,RUN,KEY,OWNER,EXAM,TOKEN
from tool.essay_lab.admin_run_recovery import validate_saved_recovery
from tool.essay_lab.admin_run_recovery import finish_saved_recovery
from tool.essay_lab.admin_run_actions import recover_admin_run
PG='/opt/homebrew/opt/postgresql@17/bin/psql';DB='admin_recovery_test'
ADMIN='00000000-0000-4000-8000-000000000001';ADMIN2='00000000-0000-4000-8000-000000000009'
def lit(v):
 if v is None:return 'null'
 if isinstance(v,(dict,list)):v=json.dumps(v,ensure_ascii=False)
 return "'"+str(v).replace("'","''")+"'"
def sql(s,role=None,actor=ADMIN,db=DB,user='postgres'):
 prefix="set statement_timeout='12s';set lock_timeout='8s';set test.actor="+lit(actor)+";set request.jwt.claims="+lit({'sub':actor,'role':'authenticated','exp':int(time.time())+600})+";"
 if role:prefix+='set role '+role+';'
 p=subprocess.run([PG,'-X','-h','/private/tmp','-p','55441','-U',user,'-d',db,'-Atq','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose'],input=prefix+s,text=True,capture_output=True,timeout=20)
 if p.returncode:raise RuntimeError(p.stderr.strip())
 return p.stdout.strip().splitlines()[-1] if p.stdout.strip() else ''
def rpc(name,*args,role='authenticated',actor=ADMIN):
 v=sql('select public.'+name+'('+','.join(lit(a) for a in args)+');',role=role,actor=actor)
 try:return json.loads(v)
 except json.JSONDecodeError:return v
def protected():
 return json.loads(sql("select jsonb_build_object('runs',(select jsonb_agg(to_jsonb(r) order by id) from essay_exam_private.runs r),'checkpoints',(select jsonb_agg(to_jsonb(c) order by run_id,key) from essay_exam_private.checkpoints c),'billing',(select jsonb_agg(to_jsonb(b) order by id) from public.essay_billing_decisions b),'ledger',(select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t),'retries',(select jsonb_agg(to_jsonb(t) order by run_id,generation) from essay_exam_private.retry_requests t))"))
def initialize():
 assert sql('show data_directory',db='postgres',user='recovery_super')=='/private/tmp/legendstudy-recovery-pg2'
 # Bootstrap is local-only; function owner matches production NOSUPERUSER+BYPASSRLS.
 sql("do $$begin if not exists(select 1 from pg_roles where rolname='postgres') then create role postgres login nosuperuser bypassrls createdb createrole;end if;end$$;",db='postgres',user='recovery_super')
 sql('drop database if exists '+DB,db='postgres',user='recovery_super');sql('create database '+DB+' owner postgres',db='postgres',user='recovery_super')
 sql('create schema extensions;create extension pgcrypto with schema extensions;',user='recovery_super')
 for f in [HERE.parent/'admin_run_management_20261120/fixture.sql',HERE.parent/'admin_archived_run_guard_20261120/fixture_extra.sql',HERE.parent/'admin_run_management_20261120/install.sql']:
  sql(f.read_text())
 sql("""create table public.admin_users(user_id uuid primary key);create schema account_private;create table auth.users(id uuid primary key,active boolean default true);
 create function account_private.allowed(uuid) returns boolean language sql as $$select exists(select 1 from auth.users where id=$1 and active)$$;
 create function account_private.lock_subject(uuid) returns void language sql as $$select pg_advisory_xact_lock(hashtextextended($1::text,84612))$$;
 create or replace function math_private.require_active(uuid[]) returns void language plpgsql security definer set search_path='' as $$declare u uuid;begin if $1 is null or array_position($1,null) is not null then raise insufficient_privilege;end if;for u in select distinct x from unnest($1)x order by x loop perform account_private.lock_subject(u);if not account_private.allowed(u) then raise insufficient_privilege;end if;end loop;end$$;
 create or replace function essay_ops_private.require_admin() returns void language plpgsql as $$begin if not exists(select 1 from public.admin_users where user_id=auth.uid()) or not account_private.allowed(auth.uid()) then raise insufficient_privilege using message='ADMIN_REQUIRED';end if;end$$;
 alter table public.essay_billing_decisions add column reason text default 'paid_cycle',add column reserved_at timestamptz default now(),add column settled_at timestamptz,add column released_at timestamptz;
 alter table public.credit_transactions alter column id set default gen_random_uuid();
 alter table public.credit_transactions add column account_id uuid,add column idempotency_key text unique,add column reason_code text;
 alter table public.credit_grants add column account_id uuid;
 grant essay_worker,authenticated,anon,service_role to postgres;
 """)
 sql((HERE/'auth_preimage.sql').read_text())
 data=json.loads((HERE/'preimage.json').read_text())
 for c in data['constraints']:
  if c['relation']=='essay_exam_private.checkpoints' and c['name'] in ('checkpoints_check','checkpoints_state_check','checkpoints_payload_check'):sql('alter table essay_exam_private.checkpoints add constraint '+c['name']+' '+c['definition'])
 for f in data['functions']:sql(f['definition'])
 for f in data['functions']:
  sig=f['signature'];sql(f'revoke all on function {sig} from public,anon,authenticated,essay_worker,service_role')
  for acl in f['acl']:
   grantee=acl.split('=')[0]
   if grantee!='postgres':sql(f'grant execute on function {sig} to {grantee}')
 sql('grant usage on schema extensions to postgres;',user='recovery_super')
 before=protected();sql((HERE/'install.sql').read_text());assert before==protected(),'INSTALLER_CHANGED_DATA'
 assert sql("select rolsuper from pg_roles where rolname=current_user")=='f'
 write_postchecks()

def write_postchecks():
 manifest=json.loads((HERE/'manifest.json').read_text())
 records=json.loads(sql("select jsonb_agg(jsonb_build_object('signature',p.oid::regprocedure::text,'md5',md5(pg_get_functiondef(p.oid)),'acl',p.proacl,'owner',pg_get_userbyid(p.proowner))) from pg_proc p where p.oid in ("+','.join(lit(s)+'::regprocedure' for s in manifest['new_functions'])+")"))
 manifest['tested_postimages']=records;(HERE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 vals=','.join('('+lit(x['signature'])+','+lit(x['md5'])+','+lit(x['acl'])+'::jsonb)' for x in records)
 guard="do $$declare x record;p pg_proc;begin for x in select * from (values "+vals+") v(signature,expected_md5,expected_acl) loop select * into p from pg_proc where oid=x.signature::regprocedure;if md5(pg_get_functiondef(p.oid))<>x.expected_md5 or to_jsonb(p.proacl) is distinct from x.expected_acl or pg_get_userbyid(p.proowner)<>'postgres' then raise exception 'POSTIMAGE_CHANGED: %',x.signature;end if;end loop;end$$;\n"
 old_vals=','.join('('+lit(x['signature'])+','+lit(x['md5'])+','+lit(x['owner'])+','+lit(x['acl'])+'::jsonb)' for x in manifest['existing_function_preimages'])
 old_guard="do $$declare x record;p pg_proc;begin for x in select * from(values "+old_vals+")v(signature,expected_md5,expected_owner,expected_acl) loop select * into p from pg_proc where oid=x.signature::regprocedure;if md5(pg_get_functiondef(p.oid))<>x.expected_md5 or pg_get_userbyid(p.proowner)<>x.expected_owner or to_jsonb(p.proacl) is distinct from x.expected_acl then raise exception 'EXISTING_RPC_CHANGED: %',x.signature;end if;end loop;end$$;\n"
 (HERE/'postcheck.sql').write_text('-- Read-only source/ACL verification; no real student action.\nbegin read only;\n'+guard+old_guard+"select 'PASS: expected recovery functions/ACLs; original RPC definitions unchanged' as result;\nrollback;\n")
 rollback='-- Revert Worker/WEB adapters first. Never reverse real results/ledger/audit events.\nbegin;\n'+guard
 for sig in reversed(manifest['new_functions']):rollback+='drop function '+sig+';\n'
 rollback+="do $$begin if not exists(select 1 from essay_ops_private.run_actions where action='recover') then alter table essay_ops_private.run_actions drop constraint run_actions_action_check;alter table essay_ops_private.run_actions add constraint run_actions_action_check check(action in('retry','delete','archive','restore'));end if;end$$;\nnotify pgrst,'reload schema';\ncommit;\n"
 (HERE/'rollback.sql').write_text(rollback)

class RecoveryTests(unittest.TestCase):
 def setUp(self):
  sql('truncate essay_ops_private.run_actions,essay_ops_private.hidden_runs,essay_exam_private.checkpoints,essay_exam_private.retry_requests,essay_exam_private.runs,public.credit_transactions,public.essay_billing_decisions,public.credit_accounts,public.credit_grants,public.admin_users,auth.users cascade;')
  sql('insert into auth.users(id) values '+','.join('('+lit(x)+')' for x in (ADMIN,ADMIN2,OWNER))+';insert into public.admin_users values ('+lit(ADMIN)+'),('+lit(ADMIN2)+');insert into public.credit_accounts values ('+lit(OWNER)+','+lit(OWNER)+');')
  self.key=str(uuid.uuid4())
 def seed(self,pending=None,failed=(),final=True,paid=1,attempt=0,math_indices=()):
  self.context,self.material,self.registry,self.expected=recovery_fixture(pending=pending,final=final,attempt=attempt,math_indices=math_indices)
  for i in failed:
   k=f'q{i}'+(f'-retry-{attempt}' if attempt else '')
   self.context['checkpoints'][k]['payload'].update(state='failed',output=None)
   self.context['checkpoints'].pop(k+'-reviewed',None);self.context['checkpoints'].pop(k+'-usage',None)
  sql(f"insert into public.essay_billing_decisions(id,account_id,credits_required,status) values ({lit(KEY)},{lit(OWNER)},{paid},'reserved');insert into essay_exam_private.runs(id,account_id,exam_id,decision_id,request_key,snapshot,state,created_at,dispatch_key,lease_token,lease_until) values({lit(RUN)},{lit(OWNER)},{lit(EXAM)},{lit(KEY)},gen_random_uuid(),{lit(self.context['claimed']['snapshot'])},'reserved',now()-interval '1 hour',gen_random_uuid(),{lit(TOKEN)},now()-interval '30 minutes');")
  for k,v in self.context['checkpoints'].items():sql(f'insert into essay_exam_private.checkpoints values({lit(RUN)},{lit(k)},gen_random_uuid(),{lit(v["state"])},{lit(v["payload"])})')
  if attempt:sql(f"insert into essay_exam_private.retry_requests values({lit(RUN)},gen_random_uuid(),{attempt},{lit(self.context['claimed']['attempts'])},now()-interval '1 hour',now()-interval '30 minutes')")
  if paid:
   sql(f"insert into public.credit_grants values({lit(EXAM)},'apple_purchase',{lit(OWNER)});insert into public.credit_transactions(decision_id,account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key) values({lit(KEY)},{lit(OWNER)},{lit(EXAM)},'reserve',0,1,'fixture-reserve')")
  self.before=protected();return self.diag()
 def diag(self):return rpc('admin_lab_run_recovery',RUN)
 def prepare(self,d=None,key=None,actor=ADMIN):
  d=d or self.diag();self.token=d['diagnosis_token'];return rpc('admin_lab_recover_run',RUN,key or self.key,self.token,actor=actor)
 def proof(self):
  context=rpc('essay_exam_recovery_context',self.key,role='essay_worker');return asyncio.run(validate_saved_recovery(context,self.material,self.registry))
 def commit(self,result=None,proof=None,key=None):
  if result is None and proof is None:result,proof=self.proof()
  return rpc('essay_exam_recovery_finish',key or self.key,self.token,result,proof,role='essay_worker')
 def ledger(self):return json.loads(sql("select coalesce(jsonb_agg(to_jsonb(t) order by created_at,id),'[]') from public.credit_transactions t"))
 def test_A_final_complete_once_original_credit_source(self):
  d=self.seed();self.assertEqual(d['recovery']['type'],'A');p=self.prepare(d);self.assertEqual(p['state'],'verification_required')
  result,proof=self.proof();out=self.commit(result,proof);self.assertEqual(out['state'],'completed');snapshot=protected()
  self.assertEqual(self.commit(result,proof),out);self.assertEqual(self.prepare(d),out);self.assertEqual(snapshot,protected())
  self.assertEqual([t['transaction_type'] for t in self.ledger()],['reserve','consume']);self.assertEqual(self.before['runs'][0]['snapshot'],snapshot['runs'][0]['snapshot']);self.assertEqual(self.before['checkpoints'],snapshot['checkpoints'])
 def test_D_pending_reviewed_restored_via_original_writer_no_extra_credit(self):
  self.seed(pending=0,final=False);writer=sql(f"select writer from essay_exam_private.checkpoints where run_id={lit(RUN)} and key='q0'")
  self.prepare();out=self.commit();self.assertEqual(out['state'],'completed');self.assertEqual(out['restored_questions'],1)
  self.assertEqual(sql(f"select writer from essay_exam_private.checkpoints where run_id={lit(RUN)} and key='q0'"),writer)
  self.assertEqual(len(self.ledger()),2)
 def test_B_partial_retries_failed_only_preserves_success(self):
  d=self.seed(failed=(1,),final=False);self.assertEqual(d['recovery']['type'],'B');self.prepare(d);out=self.commit();self.assertEqual(out['state'],'queued');after=protected()
  self.assertEqual(after['checkpoints'],self.before['checkpoints']);self.assertEqual(after['ledger'],self.before['ledger']);self.assertEqual(after['retries'][0]['attempts'],{'1':1})
  self.assertEqual(self.prepare(d),out);self.assertEqual(after,protected())
 def test_C_all_failed_retries_existing_reservation(self):
  d=self.seed(failed=(0,1),final=False);self.assertEqual(d['recovery']['type'],'C');self.prepare();out=self.commit();self.assertEqual(out['state'],'queued');self.assertEqual(protected()['retries'][0]['attempts'],{'0':1,'1':1});self.assertEqual(self.before['ledger'],protected()['ledger'])
 def test_D_mixed_restore_then_retry_atomic(self):
  d=self.seed(pending=0,failed=(1,),final=False);self.assertEqual(d['recovery']['method'],'verify_then_retry');self.assertEqual(self.prepare()['operation'],'verify_then_retry');out=self.commit();self.assertEqual(out['state'],'queued');self.assertEqual(out['restored_questions'],1)
  after=protected();self.assertEqual(after['retries'][0]['attempts'],{'1':1});self.assertEqual(after['ledger'],self.before['ledger']);self.assertEqual(after['runs'],self.before['runs'])
 def test_D_mixed_invalid_subset_rolls_back_pending_and_retry(self):
  self.seed(pending=0,failed=(1,),final=False);self.prepare();result,proof=self.proof();result['summary']='changed';out=self.commit(result,proof)
  self.assertEqual(out['state'],'blocked');self.assertEqual(self.before,protected());self.assertEqual(sql("select count(*) from essay_ops_private.run_actions where action='recover'"),'2')
 def test_active_lease_blocks_and_audits(self):
  self.seed();sql(f"update essay_exam_private.runs set lease_until=now()+interval '5 minutes' where id={lit(RUN)}");d=self.diag();before=protected();self.assertEqual(d['recovery']['reason'],'ACTIVE_LEASE');self.assertEqual(self.prepare(d)['state'],'blocked');self.assertEqual(before,protected())
 def test_unknown_response_is_blocked_even_after_expiry(self):
  self.seed(final=False);sql(f"update essay_exam_private.checkpoints set payload=jsonb_set(jsonb_set(payload,'{{state}}','\"reconciling\"'),'{{output}}','null') where run_id={lit(RUN)} and key='q0'");before=protected();self.assertEqual(self.prepare()['reason'],'RECONCILIATION_REQUIRED');self.assertEqual(before,protected())
 def test_definite_429_failure_remains_retryable(self):
  self.seed(failed=(1,),final=False);sql(f"insert into essay_exam_private.checkpoints values({lit(RUN)},'q1-a0-execution-failure',gen_random_uuid(),'checkpoint','{{\"component\":\"execution_failure\",\"code\":\"PROVIDER_HTTP_FAILURE\",\"stage\":\"provider\",\"http_status\":429,\"provider_call\":\"possible\"}}')");self.prepare();self.assertEqual(self.commit()['state'],'queued')
 def test_archived_never_recovers(self):
  self.seed();sql(f"insert into essay_ops_private.hidden_runs(run_id,hidden) values({lit(RUN)},true)");self.assertEqual(self.prepare()['reason'],'RUN_ARCHIVED')
 def test_missing_or_released_reservation_blocks(self):
  self.seed();sql('delete from public.credit_transactions');self.assertEqual(self.prepare()['reason'],'LEDGER_RECONCILIATION_REQUIRED')
 def test_free_revision_zero_ledger_settles(self):
  self.seed(paid=0);self.prepare();self.assertEqual(self.commit()['state'],'completed');self.assertEqual(self.ledger(),[])
 def test_generation_drift_invalidates_preparation(self):
  self.seed();self.prepare();result,proof=self.proof();sql(f"insert into essay_exam_private.retry_requests values({lit(RUN)},gen_random_uuid(),1,'{{}}',now(),now()-interval '1 minute')");before=protected();self.assertEqual(self.commit(result,proof)['reason'],'DIAGNOSIS_CHANGED');self.assertEqual(before,protected())
 def test_worker_cannot_create_intent_or_access_unprepared_context(self):
  self.seed()
  with self.assertRaisesRegex(RuntimeError,'permission denied'):rpc('admin_lab_recover_run',RUN,self.key,self.diag()['diagnosis_token'],role='essay_worker')
  with self.assertRaisesRegex(RuntimeError,'RECOVERY_INTENT_REQUIRED'):rpc('essay_exam_recovery_context',self.key,role='essay_worker')
 def test_students_cannot_bypass_admin_or_read_private_context(self):
  self.seed()
  for role in ('anon','authenticated'):
   with self.assertRaisesRegex(RuntimeError,'ADMIN_REQUIRED|permission denied'):rpc('admin_lab_run_recovery',RUN,role=role,actor=OWNER)
   with self.assertRaisesRegex(RuntimeError,'permission denied'):rpc('essay_exam_recovery_context',self.key,role=role,actor=OWNER)
  with self.assertRaisesRegex(RuntimeError,'permission denied'):sql('select * from essay_ops_private.run_actions',role='authenticated',actor=OWNER)
 def test_admin_revocation_between_phases_blocks(self):
  self.seed();self.prepare();result,proof=self.proof();sql('delete from public.admin_users where user_id='+lit(ADMIN));before=protected()
  with self.assertRaisesRegex(RuntimeError,'RECOVERY_INTENT_REQUIRED'):self.commit(result,proof)
  self.assertEqual(before,protected())
 def test_lifecycle_revocation_blocks(self):
  self.seed();self.prepare();sql('update auth.users set active=false where id='+lit(OWNER))
  with self.assertRaisesRegex(RuntimeError,'42501'):rpc('essay_exam_recovery_context',self.key,role='essay_worker')
 def test_same_key_concurrent_prepare_is_idempotent(self):
  d=self.seed(failed=(1,),final=False);self.token=d['diagnosis_token']
  with ThreadPoolExecutor(max_workers=2) as pool:out=list(pool.map(lambda _:self.prepare(d),range(2)))
  self.assertEqual(out[0],out[1]);self.assertEqual(sql('select count(*) from essay_exam_private.retry_requests'),'0');self.commit();self.assertEqual(sql('select count(*) from essay_exam_private.retry_requests'),'1')
 def test_different_admin_concurrent_commit_finishes_once(self):
  d=self.seed();self.prepare(d);result,proof=self.proof();key2=str(uuid.uuid4());self.prepare(d,key2,ADMIN2)
  with ThreadPoolExecutor(max_workers=2) as pool:out=list(pool.map(lambda k:self.commit(result,proof,k),[self.key,key2]))
  self.assertEqual(sorted(x['state'] for x in out),['blocked','completed']);self.assertEqual(len(self.ledger()),2)
 def test_proof_rejection_audit_no_private_exception_text(self):
  self.seed();self.prepare();out=self.commit(None,{'failure_code':'ARTIFACT_VERIFICATION_FAILED'});self.assertEqual(out['reason'],'ARTIFACT_VERIFICATION_FAILED');self.assertEqual(protected(),self.before);self.assertNotIn('snapshot',json.dumps(out))
 def test_proof_foreign_output_and_extra_questions_rejected(self):
  self.seed();self.prepare();result,proof=self.proof();result['questions'][0]['evaluation']['summary']='arbitrary';self.assertEqual(self.commit(result,proof)['state'],'blocked');self.assertEqual(protected(),self.before)
 def test_audit_is_immutable(self):
  self.seed();self.prepare()
  with self.assertRaisesRegex(RuntimeError,'ADMIN_AUDIT_IMMUTABLE'):sql("update essay_ops_private.run_actions set outcome='{}'")
  with self.assertRaisesRegex(RuntimeError,'ADMIN_AUDIT_IMMUTABLE'):sql('delete from essay_ops_private.run_actions')
 def test_operational_projection_only_completed_attributed_recovery(self):
  self.seed();before=rpc('admin_lab_recovery_operations','2026-01-01','2026-04-01') if False else rpc('admin_lab_recovery_operations','2026-11-01','2026-12-01');self.assertEqual(before['attention_total'],1);self.assertEqual(before['recover_success'],0)
  self.prepare();self.assertEqual(rpc('admin_lab_recovery_operations','2026-11-01','2026-12-01')['recover_success'],0);self.commit();after=rpc('admin_lab_recovery_operations','2026-11-01','2026-12-01');self.assertEqual(after['attention_total'],0);self.assertEqual(after['recover_success'],1)
 def test_jwt_expired_wrong_role_and_mismatched_subject_denied(self):
  self.seed()
  for claims in ({'sub':ADMIN,'role':'authenticated','exp':1},{'sub':ADMIN,'role':'essay_worker','exp':int(time.time())+60},{'sub':OWNER,'role':'authenticated','exp':int(time.time())+60},{'sub':ADMIN,'role':'authenticated','exp':'9999999999'}):
   with self.assertRaisesRegex(RuntimeError,'ADMIN_REQUIRED'):sql('set request.jwt.claims='+lit(claims)+';select public.admin_lab_run_recovery('+lit(RUN)+')',role='authenticated')
 def test_expired_replay_canonical_blocked_no_dispatch(self):
  d=self.seed(failed=(1,),final=False);self.prepare(d);self.commit();sql("update essay_exam_private.retry_requests set lease_until=now()-interval '1 minute'");out=self.prepare(d)
  self.assertEqual((out['state'],out['operation'],out['dispatch_required'],out['success']),('blocked','blocked',False,False))
 def test_completed_same_generation_replay_canonical_success(self):
  d=self.seed(failed=(1,),final=False);self.prepare(d);self.commit();rpc('essay_exam_finish',OWNER,RUN,TOKEN,self.expected,False,role='essay_worker');out=self.prepare(d)
  self.assertEqual((out['state'],out['operation'],out['dispatch_required'],out['success']),('completed','completed',False,True));self.assertEqual(rpc('admin_lab_recovery_operations','2026-11-01','2026-12-01')['recover_success'],1)
 def test_unrelated_later_retry_completion_not_attributed(self):
  d=self.seed(failed=(1,),final=False);self.prepare(d);self.commit();sql(f"insert into essay_exam_private.retry_requests(run_id,request_key,generation,attempts) values({lit(RUN)},gen_random_uuid(),2,'{{\"1\":2}}')");rpc('essay_exam_finish',OWNER,RUN,TOKEN,self.expected,False,role='essay_worker');out=self.prepare(d)
  self.assertEqual(out['state'],'blocked');self.assertFalse(out['success']);self.assertEqual(rpc('admin_lab_recovery_operations','2026-11-01','2026-12-01')['recover_success'],0)
 def test_completed_billing_current_reserved_zero_not_false_warning(self):
  self.seed();self.prepare();self.commit();billing=self.diag()['billing'];self.assertEqual(billing['reserved'],0);self.assertEqual(billing['reserved_total'],1);self.assertTrue(billing['consistent']);self.assertFalse(billing['recovery_eligible'])
 def test_math_durable_saved_result_uses_existing_type_boundary(self):
  self.seed(pending=0,final=False,math_indices=(0,));d=self.diag();self.assertTrue(d['recovery']['allowed']);self.prepare(d);self.assertEqual(self.commit()['state'],'completed')
 def test_restore_target_includes_pending_but_rerun_count_only_failed(self):
  d=self.seed(pending=0,failed=(1,),final=False);self.assertEqual(len(d['recovery']['target_question_ids']),2);self.assertEqual(d['recovery']['rerun_question_count'],1)
 def test_late_checkpoint_write_invalidates_prepared_context_and_audits(self):
  self.seed(pending=0,final=False);self.prepare();result,proof=self.proof();sql(f"insert into essay_exam_private.checkpoints values({lit(RUN)},'extra',gen_random_uuid(),'checkpoint','{{}}')");before=protected();out=rpc('essay_exam_recovery_context',self.key,role='essay_worker');self.assertEqual(out['terminal']['state'],'blocked');self.assertEqual(before,protected())
 def test_settlement_error_rolls_back_restoration_with_clear_reason(self):
  self.seed(pending=0,final=False);self.prepare();result,proof=self.proof();sql("create function public.fixture_block_consume() returns trigger language plpgsql as $$begin if new.transaction_type='consume' then raise exception 'SYNTHETIC PRIVATE DETAILS';end if;return new;end$$;create trigger fixture_block before insert on public.credit_transactions for each row execute function public.fixture_block_consume();")
  try:
   out=self.commit(result,proof);self.assertEqual(out['reason'],'RECOVERY_SETTLEMENT_FAILED');self.assertEqual(protected(),self.before);self.assertNotIn('PRIVATE',json.dumps(out))
  finally:sql('drop trigger fixture_block on public.credit_transactions;drop function public.fixture_block_consume()')
 def test_automatic_retry_race_has_one_generation(self):
  self.seed(failed=(1,),final=False);self.prepare();result,proof=self.proof()
  def auto():
   try:return rpc('essay_exam_retry',OWNER,RUN,str(uuid.uuid4()),EXAM,role='essay_worker')
   except RuntimeError:return {'blocked':True}
  with ThreadPoolExecutor(max_workers=2) as pool:
   a=pool.submit(self.commit,result,proof);b=pool.submit(auto);a.result();b.result()
  # Existing retry itself permits another explicit request while the same failed
  # checkpoint remains; recovery must observe any race through its digest guard.
  self.assertEqual(sql('select count(*) from essay_exam_private.retry_requests'),'1')
  self.assertEqual(self.before['ledger'],protected()['ledger'])
 def adapter(self,token):
  calls=[]
  async def caller(name,args,_):return rpc(name,*args.values())
  async def worker(name,args):
   if name=='essay_material_runtime_package':return self.material
   return rpc(name,*args.values(),role='essay_worker')
  async def admission(subject,exam):calls.append('admission');return {'ready':True,'session_version':'exam-session-v1'}
  async def enqueue(job):calls.append('enqueue')
  async def finish(action):return await finish_saved_recovery(action,worker,self.registry)
  result=asyncio.run(recover_admin_run({'run_id':RUN,'key':self.key,'diagnosis_token':token},'fixture-admin-jwt',caller,admission,enqueue,finish))
  return result,calls
 def test_actual_SQL_receipts_pass_worker_adapter_A_and_idempotent_replay(self):
  d=self.seed();out,calls=self.adapter(d['diagnosis_token']);self.assertEqual(out['state'],'completed');self.assertEqual(calls,[]);snapshot=protected();out,calls=self.adapter(d['diagnosis_token']);self.assertEqual(out['state'],'completed');self.assertEqual(calls,[]);self.assertEqual(snapshot,protected())
 def test_actual_SQL_receipts_pass_worker_adapter_B_queue_and_expired_replay(self):
  d=self.seed(failed=(1,),final=False);out,calls=self.adapter(d['diagnosis_token']);self.assertEqual(out['state'],'queued');self.assertEqual(calls,['admission','enqueue']);out,calls=self.adapter(d['diagnosis_token']);self.assertEqual(out['state'],'queued');self.assertEqual(calls,['admission','enqueue']);sql("update essay_exam_private.retry_requests set lease_until=now()-interval '1 minute'");out,calls=self.adapter(d['diagnosis_token']);self.assertEqual(out['state'],'blocked');self.assertEqual(calls,[])
 def test_actual_SQL_receipts_pass_worker_adapter_D_mixed(self):
  d=self.seed(pending=0,failed=(1,),final=False);out,calls=self.adapter(d['diagnosis_token']);self.assertEqual(out['state'],'queued');self.assertEqual(calls,['admission','enqueue']);self.assertEqual(self.before['ledger'],protected()['ledger'])
 def test_credit_source_grant_rows_survive_original_settlement(self):
  self.seed();before=sql('select jsonb_agg(to_jsonb(g) order by id) from public.credit_grants g');self.prepare();self.commit();self.assertEqual(before,sql('select jsonb_agg(to_jsonb(g) order by id) from public.credit_grants g'));self.assertEqual(len({x['grant_id'] for x in self.ledger()}),1)
 def test_toss_purchase_grant_rows_survive_original_settlement(self):
  self.seed();sql("update public.credit_grants set origin='purchase'");before=sql('select jsonb_agg(to_jsonb(g) order by id) from public.credit_grants g');self.prepare();self.commit();self.assertEqual(before,sql('select jsonb_agg(to_jsonb(g) order by id) from public.credit_grants g'));self.assertEqual(len({x['grant_id'] for x in self.ledger()}),1)
 def test_pending_payload_nonnull_rejected_by_existing_checkpoint_constraint(self):
  self.seed(final=False)
  with self.assertRaisesRegex(RuntimeError,'checkpoints_check'):sql(f"insert into essay_exam_private.checkpoints values({lit(RUN)},'summary',gen_random_uuid(),'pending','{{}}')")
 def test_missing_dispatch_is_not_assumed_safe_from_age(self):
  self.seed(final=False);sql(f'update essay_exam_private.runs set dispatch_key=null where id={lit(RUN)}');self.assertEqual(self.prepare()['reason'],'DISPATCH_NOT_CONFIRMED')
 def test_missing_question_checkpoint_is_never_created_by_recovery(self):
  self.seed(final=False);sql(f"delete from essay_exam_private.checkpoints where run_id={lit(RUN)} and key='q0'");before=protected();self.assertEqual(self.prepare()['reason'],'RECONCILIATION_REQUIRED');self.assertEqual(before,protected())
 def test_terminal_cross_actor_collision_cannot_leak_context(self):
  self.seed();self.prepare();sql(f"insert into essay_ops_private.run_actions(id,run_id,actor,action,outcome) values(essay_ops_private.recovery_key({lit(self.key)}),{lit(RUN)},{lit(ADMIN2)},'recover','{{}}')")
  with self.assertRaisesRegex(RuntimeError,'ACTION_KEY_CONFLICT'):rpc('essay_exam_recovery_context',self.key,role='essay_worker')
 def test_pending_aggregate_rows_preserved_during_proven_no_provider_completion(self):
  self.seed(final=False);sql(f"insert into essay_exam_private.checkpoints values({lit(RUN)},'summary',gen_random_uuid(),'pending',null),({lit(RUN)},'final',gen_random_uuid(),'pending',null)");before=protected();self.prepare();self.assertEqual(self.commit()['state'],'completed');self.assertEqual(before['checkpoints'],protected()['checkpoints'])
 def test_failed_question_with_aggregate_checkpoint_is_blocked(self):
  self.seed(failed=(1,),final=False);sql(f"insert into essay_exam_private.checkpoints values({lit(RUN)},'summary',gen_random_uuid(),'pending',null)");self.assertEqual(self.prepare()['reason'],'FINAL_CHECKPOINT_CONFLICT')
 def test_zz_postcheck_rollback_preserves_all_runtime_and_audit_rows(self):
  self.seed();self.prepare();self.commit();before=protected();audit=sql('select md5(jsonb_agg(to_jsonb(a) order by id)::text) from essay_ops_private.run_actions a');sql((HERE/'postcheck.sql').read_text());sql((HERE/'rollback.sql').read_text());self.assertEqual(before,protected());self.assertEqual(audit,sql('select md5(jsonb_agg(to_jsonb(a) order by id)::text) from essay_ops_private.run_actions a'));self.assertEqual(sql("select to_regprocedure('public.admin_lab_run_recovery(uuid)') is null"),'t')

if __name__=='__main__':
 initialize();suite=unittest.defaultTestLoader.loadTestsFromTestCase(RecoveryTests);result=unittest.TextTestRunner(verbosity=2).run(suite)
 receipt={'tests':result.testsRun,'failures':len(result.failures),'errors':len(result.errors),'passed':result.wasSuccessful(),'runtime':'isolated PostgreSQL 17; NOSUPERUSER BYPASSRLS owner and real authenticated/essay_worker/anon roles','install_sha256':hashlib.sha256((HERE/'install.sql').read_bytes()).hexdigest(),'production_mutations':0}
 (HERE/'result.json').write_text(json.dumps(receipt,indent=2)+'\n');sys.exit(not result.wasSuccessful())
