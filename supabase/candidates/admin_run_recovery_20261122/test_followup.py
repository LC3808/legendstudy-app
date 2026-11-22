"""Synthetic-only extension coverage over captured SQL and real role boundaries."""
import asyncio,hashlib,json,sys,unittest,uuid,copy
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from test_postgres import *

class FollowupTests(RecoveryTests):
 def uncertain(self):
  self.seed(failed=(1,),final=False,paid=0)
  sql("update essay_exam_private.checkpoints set payload=jsonb_set(payload,'{state}','\"reconciling\"') where key='q1'")
  # Remove the synthetic old review audit: target production has only provider uncertainty.
  sql("delete from essay_exam_private.checkpoints where key like 'q1-a0-%'")
  sql("insert into essay_exam_private.checkpoints values("+lit(RUN)+",'q1-a0-execution-failure',gen_random_uuid(),'checkpoint',"+lit({'component':'execution_failure','code':'PROVIDER_NETWORK_UNKNOWN','stage':'provider','provider_call':'possible','http_status':None})+")")
  return self.diag()
 def approve(self,d=None):
  d=d or self.diag();self.token=d['diagnosis_token'];return rpc('admin_lab_recover_run',RUN,self.key,self.token,True)
 def test_E_actual_adapter_only_enqueues_after_worker_and_DB_validation(self):
  d=self.uncertain();calls=[]
  async def caller(name,args,_):return rpc(name,*args.values())
  async def worker(name,args):return self.material if name=='essay_material_runtime_package' else rpc(name,*args.values(),role='essay_worker')
  async def admission(subject,exam):calls.append('admission');return {'ready':True,'session_version':'exam-session-v1'}
  async def enqueue(job):calls.append('enqueue')
  async def finish(action):return await finish_saved_recovery(action,worker,self.registry)
  out=asyncio.run(recover_admin_run({'run_id':RUN,'key':self.key,'diagnosis_token':d['diagnosis_token'],'allow_uncertain':True},'fixture-admin',caller,admission,enqueue,finish))
  self.assertEqual(out['state'],'queued');self.assertEqual(out['recovery_type'],'E');self.assertEqual(calls,['admission','enqueue']);self.assertEqual(sql('select count(*) from public.credit_transactions'),'0')
 def test_E_explicit_only_retains_completed_and_no_ledger(self):
  d=self.uncertain();before=protected();self.assertFalse(d['recovery']['allowed']);self.assertTrue(d['uncertain_recovery']['allowed'])
  self.assertEqual(self.approve()['operation'],'verify_then_retry');result,proof=self.proof();self.assertEqual(len(result['questions']),1)
  out=self.commit(result,proof);self.assertEqual(out['state'],'queued');after=protected()
  self.assertEqual(before['checkpoints'],after['checkpoints']);self.assertEqual(before['ledger'],after['ledger']);self.assertEqual(before['billing'],after['billing'])
  self.assertEqual(after['retries'][0]['attempts'],{'1':1});self.assertEqual(out['fenced_attempts'],{'1':0})
 def test_E_late_original_writer_and_finalization_blocked(self):
  self.uncertain();self.approve();self.commit();writer=sql("select writer from essay_exam_private.checkpoints where key='q1'")
  payload=json.loads(sql("select payload from essay_exam_private.checkpoints where key='q1'"))
  with self.assertRaisesRegex(RuntimeError,'STALE_QUESTION_ATTEMPT'):rpc('essay_exam_checkpoint',OWNER,RUN,TOKEN,'q1','write',writer,payload,role='essay_worker')
  for key in ['q1-a0-receipt-late','q1-reviewed','summary','final']:
   with self.assertRaisesRegex(RuntimeError,'STALE_'):rpc('essay_exam_session_checkpoint',OWNER,RUN,TOKEN,key,'begin',str(uuid.uuid4()),None,role='essay_worker')
  with self.assertRaisesRegex(RuntimeError,'STALE_RECOVERY_RESULT'):rpc('essay_exam_finish',OWNER,RUN,TOKEN,self.expected,False,role='essay_worker')
  self.assertEqual(sql('select count(*) from public.credit_transactions'),'0')
 def test_E_active_and_ordinary_student_denied(self):
  self.uncertain();sql("update essay_exam_private.runs set lease_until=now()+interval '5 minutes'")
  self.assertEqual(self.approve()['state'],'blocked')
  with self.assertRaises(RuntimeError):rpc('admin_lab_recover_run',RUN,str(uuid.uuid4()),self.diag()['diagnosis_token'],True,actor=OWNER)
 def test_E_new_evidence_invalidates_preparation(self):
  self.uncertain();self.approve();sql("insert into essay_exam_private.checkpoints values("+lit(RUN)+",'q1-a0-receipt-late',gen_random_uuid(),'checkpoint','{}')")
  out=rpc('essay_exam_recovery_context',self.key,role='essay_worker');self.assertEqual(out['terminal']['state'],'blocked');self.assertEqual(sql('select count(*) from essay_exam_private.retry_requests'),'0')
 def test_E_explicit_approval_is_part_of_idempotency(self):
  d=self.uncertain();self.approve(d)
  with self.assertRaisesRegex(RuntimeError,'ACTION_KEY_CONFLICT'):rpc('admin_lab_recover_run',RUN,self.key,d['diagnosis_token'],False)
  self.commit();self.assertEqual(self.approve(d)['state'],'queued');self.assertEqual(sql('select count(*) from essay_exam_private.retry_requests'),'1')
 def test_E_unknown_with_durable_output_is_not_overridden(self):
  self.uncertain();sql("insert into essay_exam_private.checkpoints values("+lit(RUN)+",'q1-reviewed',gen_random_uuid(),'checkpoint','{}')")
  self.assertFalse(self.diag()['uncertain_recovery']['allowed']);self.assertEqual(self.approve()['state'],'blocked')
 def test_E_new_attempt_write_permitted_and_stale_output_rejected(self):
  self.uncertain();self.approve();self.commit();writer=str(uuid.uuid4())
  self.assertTrue(rpc('essay_exam_session_checkpoint',OWNER,RUN,TOKEN,'q1-retry-1','begin',writer,None,role='essay_worker')['started'])
  payload=copy.deepcopy(self.context['checkpoints']['q1']['payload']);payload['state']='completed';payload['output']=copy.deepcopy(self.expected['questions'][1]['evaluation']);payload['output']['summary']='새 시도 검토 결과'
  rpc('essay_exam_session_checkpoint',OWNER,RUN,TOKEN,'q1-retry-1','write',writer,payload,role='essay_worker')
  with self.assertRaisesRegex(RuntimeError,'STALE_RECOVERY_RESULT'):rpc('essay_exam_finish',OWNER,RUN,TOKEN,self.expected,False,role='essay_worker')
  self.assertEqual(sql('select count(*) from public.credit_transactions'),'0')
 def test_E_fence_cannot_be_removed_by_rollback_after_use(self):
  self.uncertain();self.approve();self.commit()
  with self.assertRaisesRegex(RuntimeError,'ACTIVE_FENCES_REQUIRE_FORWARD_FIX'):sql((HERE/'rollback.sql').read_text())
  self.assertEqual(sql("select count(*) from pg_trigger where tgname='recovery_attempt_fence'"),'1')
 def test_quality_budget_blocks_existing_retry_rpc(self):
  self.seed(failed=(1,),final=False)
  sql("insert into essay_exam_private.checkpoints values("+lit(RUN)+",'q1-a0-quality-policy',gen_random_uuid(),'checkpoint','{\"version\":\"quality-repair-2-1-v1\"}')")
  before=protected()
  with self.assertRaisesRegex(RuntimeError,'ADMIN_QUALITY_REVIEW_REQUIRED'):rpc('essay_exam_retry',OWNER,RUN,str(uuid.uuid4()),EXAM,role='essay_worker')
  self.assertEqual(before,protected())

if __name__=='__main__':
 initialize();result=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(FollowupTests))
 (HERE/'followup-result.json').write_text(json.dumps({'tests':result.testsRun,'failures':len(result.failures),'errors':len(result.errors),'passed':result.wasSuccessful(),'production_mutations':0,'install_sha256':hashlib.sha256((HERE/'install.sql').read_bytes()).hexdigest()},indent=2)+'\n')
 sys.exit(not result.wasSuccessful())
