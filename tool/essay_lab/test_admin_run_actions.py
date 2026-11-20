import unittest
from .admin_run_actions import retry_admin_run
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
