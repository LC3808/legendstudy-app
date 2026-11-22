import unittest
from .admin_run_actions import retry_admin_run, recover_admin_run
R='10000000-0000-4000-8000-000000000001'
K='30000000-0000-4000-8000-000000000001'
class AdminDispatchTests(unittest.IsolatedAsyncioTestCase):
 async def run_case(self,deny=False,failed_admission=False,failed_queue=False,archived=False):
  events=[]
  async def rpc(name,args,token):
   events.append((name,args,token))
   if deny:raise PermissionError('ADMIN_REQUIRED')
   return {'version':'admin-run-management-v1','run_id':R,'action':'retry','subject_id':'owner-from-database','exam_id':'exam-from-database','hidden':archived}
  async def admission(subject,exam):
   events.append(('admission',subject,exam))
   if failed_admission:raise RuntimeError('UNAVAILABLE')
   return {'ready':True,'session_version':'exam-session-v1'}
  async def enqueue(value):
   events.append(('enqueue',value))
   if failed_queue:raise RuntimeError('QUEUE_UNAVAILABLE')
  try:result=await retry_admin_run({'run_id':R,'key':K},'original-admin-jwt',rpc,admission,enqueue)
  except Exception:result=None
  return result,events
 async def test_authoritative_owner_and_caller_token(self):
  result,events=await self.run_case()
  self.assertEqual(result['state'],'queued');self.assertEqual([e[0] for e in events],['admin_lab_run_capabilities','admission','admin_lab_manage_run','enqueue'])
  self.assertEqual(events[0][2],'original-admin-jwt');self.assertEqual(events[2][2],'original-admin-jwt')
  self.assertEqual(events[-1][1],{'subject_id':'owner-from-database','run_id':R})
  self.assertEqual(events[2][1]['p_key'],K)
 async def test_student_denied_before_admission_write_or_queue(self):
  result,events=await self.run_case(deny=True);self.assertIsNone(result);self.assertEqual(len(events),1)
 async def test_archived_denied_before_admission_write_or_queue(self):
  result,events=await self.run_case(archived=True);self.assertIsNone(result);self.assertEqual([e[0] for e in events],['admin_lab_run_capabilities'])
 async def test_admission_failure_does_not_create_retry(self):
  result,events=await self.run_case(failed_admission=True);self.assertIsNone(result);self.assertEqual(len(events),2)
 async def test_queue_failure_is_not_reported_success(self):
  result,_=await self.run_case(failed_queue=True);self.assertIsNone(result)
 async def test_caller_cannot_supply_subject(self):
  with self.assertRaises(Exception):await retry_admin_run({'run_id':R,'key':K,'subject_id':'spoof'},'jwt',None,None,None)


class AdminRecoveryDispatchTests(unittest.IsolatedAsyncioTestCase):
 async def case(self,operation='verify_saved',*,deny=False,admission_fails=False,mutation_fails=False,
                queue_fails=False,finish_fails=False,mutation_patch=None,finish_patch=None,replay=False):
  events=[]
  identity=dict(version='admin-run-recovery-v1',run_id=R,subject_id='db-owner',exam_id='db-exam',
                action='recover',action_id=K,recovery_type='D',reason=None)
  values={'verify_saved':('verification_required',False,False),'verify_then_retry':('verification_required',False,False),
          'retry':('queued',True,False),'completed':('completed',False,True),'blocked':('blocked',False,False)}
  def result(op):
   state,dispatch,success=values[op]
   return dict(identity,operation=op,state=state,dispatch_required=dispatch,success=success)
  async def rpc(name,args,token):
   events.append((name,args,token))
   if deny:raise PermissionError('ADMIN_REQUIRED')
   if name=='admin_lab_run_recovery':
    return dict(identity,hidden=False,recovery={'allowed':not replay,'method': 'verify_then_retry' if operation=='verify_then_retry' else 'retry_failed' if operation=='retry' else 'finish_saved'})
   self.assertEqual(name,'admin_lab_recover_run')
   if mutation_fails:raise RuntimeError('unknown response')
   return result(operation) | (mutation_patch or {})
  async def admission(subject,exam):
   events.append(('admission',subject,exam))
   if admission_fails:raise RuntimeError('UNAVAILABLE')
   return dict(ready=True,session_version='exam-session-v1')
  async def enqueue(value):
   events.append(('enqueue',value))
   if queue_fails:raise RuntimeError('unknown queue response')
  async def finish(action):
   events.append(('verify-finish',action))
   if finish_fails:raise RuntimeError('unknown finish response')
   return result('retry' if operation=='verify_then_retry' else 'completed') | (finish_patch or {})
  try:
   out=await recover_admin_run(dict(run_id=R,key=K,diagnosis_token='a'*64),'original-admin-jwt',rpc,admission,enqueue,finish)
  except Exception as error:
   out=error
  return out,events

 async def test_saved_result_never_admits_or_enqueues_and_keeps_original_jwt(self):
  out,events=await self.case()
  self.assertEqual(out['state'],'completed')
  self.assertEqual([x[0] for x in events],['admin_lab_run_recovery','admin_lab_recover_run','verify-finish'])
  self.assertTrue(all(x[2]=='original-admin-jwt' for x in events[:2]))
  self.assertEqual(events[1][1],dict(p_run=R,p_key=K,p_diagnosis_token='a'*64))

 async def test_failed_only_and_mixed_retry_use_existing_admission_and_identity_queue(self):
  for operation in ('retry','verify_then_retry'):
   with self.subTest(operation=operation):
    out,events=await self.case(operation)
    self.assertEqual(out['state'],'queued')
    self.assertEqual([x[0] for x in events],['admin_lab_run_recovery','admission','admin_lab_recover_run']+
                     (['verify-finish'] if operation=='verify_then_retry' else [])+['enqueue'])
    self.assertEqual(events[-1][1],{'subject_id':'db-owner','run_id':R})

 async def test_student_denied_before_admission_or_mutation(self):
  out,events=await self.case(deny=True)
  self.assertIsInstance(out,PermissionError)
  self.assertEqual(len(events),1)

 async def test_admission_failure_precedes_new_retry_or_mixed_intent(self):
  for operation in ('retry','verify_then_retry'):
   out,events=await self.case(operation,admission_fails=True)
   self.assertIsInstance(out,Exception)
   self.assertEqual([x[0] for x in events],['admin_lab_run_recovery','admission'])

 async def test_unknown_mutation_or_finish_never_enqueues(self):
  for changes in ({'mutation_fails':True},{'finish_fails':True}):
   out,events=await self.case(**changes)
   self.assertIsInstance(out,Exception)
   self.assertNotIn('enqueue',[x[0] for x in events])

 async def test_lost_queue_replay_reuses_same_key_and_does_not_report_unknown_success(self):
  out,_=await self.case('retry',queue_fails=True)
  self.assertIsInstance(out,Exception)
  out,events=await self.case('retry',replay=True)
  self.assertEqual(out['state'],'queued')
  self.assertEqual(events[1][1]['p_key'],K)
  self.assertEqual([x[0] for x in events],['admin_lab_run_recovery','admin_lab_recover_run','admission','enqueue'])

 async def test_completed_or_blocked_replay_never_enqueues(self):
  for operation in ('completed','blocked'):
   out,events=await self.case(operation)
   self.assertEqual(out['state'],operation)
   self.assertEqual([x[0] for x in events],['admin_lab_run_recovery','admin_lab_recover_run'])

 async def test_malformed_authorization_response_or_saved_retry_is_not_actionable(self):
  for change in ({'subject_id':'foreign'},{'run_id':K},{'action_id':R},{'dispatch_required':1},
                 {'state':'completed'},{'success':True},{'success':0},{'generation':True},{'reason':'private raw message'}):
   out,events=await self.case('retry',mutation_patch=change)
   self.assertIsInstance(out,Exception)
   self.assertNotIn('enqueue',[x[0] for x in events])
  out,events=await self.case(finish_patch=dict(operation='retry',state='queued',dispatch_required=True,success=False))
  self.assertIsInstance(out,Exception)
  self.assertNotIn('enqueue',[x[0] for x in events])

 async def test_private_artifacts_never_return_to_web(self):
  out,_=await self.case(finish_patch={'snapshot':{'answer':'private'},'proof':{'private':'digest'},'lease_token':'private','p_result':{}})
  self.assertEqual(out['state'],'completed')
  self.assertEqual(set(out),{'version','run_id','action','action_id','operation','state','recovery_type','dispatch_required','reason','success'})

 async def test_request_cannot_supply_result_owner_or_worker_proof(self):
  for name in ('subject_id','p_result','proof'):
   with self.assertRaises(Exception):
    await recover_admin_run(dict(run_id=R,key=K,diagnosis_token='a'*64,**{name:'spoof'}),'jwt',None,None,None,None)
