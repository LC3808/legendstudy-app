"""Exam orchestration through real ReviewedRuntimeWorker, fake Provider transport.
No production credentials, provider calls, or financial operations.
"""
import unittest
from dataclasses import replace
from tool.test_essay_reviewed_runtime import RuntimeTests
from tool.essay_lab.live_worker import Invalid,Unknown
from tool.essay_lab.exam_runtime import ExamQuestionChannel,execute_exam,resume_exam
class ExamRuntimeTests(unittest.TestCase):
 def setup_exam(self,modes=('ok','ok')):
  questions=[];workers={};requests=[];events=[];saved=[];settled=[]
  for index,mode in enumerate(modes):
   worker,calls,req,checkpoints,claim,out=RuntimeTests().fixture(mode)
   worker.permit=replace(worker.permit,evaluation_id=f'evaluation-{index}')
   channel=ExamQuestionChannel(f'evaluation-{index}',claim,lambda name,args:events.append((name,args)))
   worker.rpc=channel;workers[channel]=worker;requests.append(req)
   questions.append(dict(questionId=str(index),rubricVersion='r1',evidenceVersion='e1',channel=channel))
  def finalize(record):settled.append(record);return 'failed' if record['failed'] else 'completed'
  def execute(final=finalize,summary=lambda _: 'Synthetic reviewed exam summary'):
   return execute_exam('exam',questions,workers.get,summary,saved.append,final)
  return execute,questions,requests,events,saved,settled
 def test_child_success_staged_single_exam_finalization(self):
  execute,questions,requests,events,saved,settled=self.setup_exam()
  self.assertEqual(execute(),'completed');self.assertEqual([len(x) for x in requests],[1,1])
  self.assertEqual(len(settled),1);self.assertEqual(len(settled[0]['result']['questions']),2)
  self.assertEqual([n for n,_ in events].count('question_success'),2)
  self.assertEqual(saved,settled)
 def test_partial_failure_never_settles_success(self):
  execute,_,requests,_,saved,settled=self.setup_exam(('ok','invalid','ok'))
  self.assertEqual(execute(),'failed');self.assertEqual([len(x) for x in requests],[1,1,0])
  self.assertEqual(settled,[{'examId':'exam','result':None,'failed':True}])
 def test_timeout_retains_reservation_for_reconciliation(self):
  execute,_,requests,_,saved,settled=self.setup_exam(('timeout','ok'))
  self.assertEqual(execute(),'reconciling');self.assertEqual([len(x) for x in requests],[1,0])
  self.assertEqual(saved,[]);self.assertEqual(settled,[])
 def test_ambiguous_finalize_replays_checkpoint_without_provider(self):
  execute,_,requests,_,saved,settled=self.setup_exam()
  def lost(_):raise Unknown()
  with self.assertRaises(Unknown):execute(final=lost)
  self.assertEqual(len(saved),1)
  self.assertEqual(resume_exam('exam',saved[0],lambda _: 'completed'),'completed')
  self.assertEqual([len(x) for x in requests],[1,1])
  with self.assertRaises(Invalid):resume_exam('foreign',saved[0],lambda _: 'completed')
 def test_storage_failure_prevents_provider_and_no_implicit_refund(self):
  execute,questions,requests,_,saved,settled=self.setup_exam()
  def unavailable(*_):raise Unknown()
  questions[0]['channel'].save_event=unavailable
  with self.assertRaises(Unknown):execute()
  self.assertEqual([len(x) for x in requests],[0,0]);self.assertEqual(settled,[])
 def test_no_fabricated_summary_or_blind_second_execution(self):
  execute,_,requests,_,saved,settled=self.setup_exam()
  with self.assertRaises(Invalid):execute(summary=lambda _: '')
  self.assertEqual(settled,[])
  with self.assertRaises(Invalid):execute()
  self.assertEqual([len(x) for x in requests],[1,1])
 def test_unknown_rpc_and_foreign_lease_rejected(self):
  _,questions,_,_,_,_=self.setup_exam();channel=questions[0]['channel']
  channel('essay_claim',{'p_evaluation':'evaluation-0'})
  with self.assertRaises(Invalid):channel('essay_finalize_success',{'p_evaluation':'evaluation-0','p_run':'run','p_token':'wrong'})
  with self.assertRaises(Invalid):channel('essay_admin_grant',{'p_evaluation':'evaluation-0','p_run':'run','p_token':'lease'})
if __name__=='__main__':unittest.main()
