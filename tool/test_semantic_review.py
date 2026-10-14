import unittest,json
from copy import deepcopy
from tool.essay_lab.semantic_review import SemanticReview,openai_review,VERSION
from tool.essay_lab.live_worker import ProviderResult,SignedReview,QUALITY_CHECKS,ProviderFailure,Invalid

class ReviewTests(unittest.IsolatedAsyncioTestCase):
 def fixture(self,decision='pass',version='review-model'):
  assessment={'checks':{k:{'decision':decision,'reason':'Synthetic check-specific evidence explanation: '+k} for k in QUALITY_CHECKS},'local_issue_keys':['local-1']}
  seen=[];audit=[]
  class Provider:
   model='review-model'
   async def evaluate_async(self,value):
    seen.append(value)
    return ProviderResult(json.dumps(assessment),'openai',self.model,10,20,100,30,version)
  async def save(value):audit.append(value)
  review=SemanticReview(provider=Provider(),reviewer_id='test-reviewer',key=b's'*32,model_version='review-model',audit=save,clock=lambda:100)
  value={'answer':'Synthetic answer','evidence':[]};output={'improvements':[{'issue_key':'local-1','claim_scope':'local_sentence'}],'sentence_feedback':[]}
  return review,value,output,seen,audit,assessment
 async def test_separate_review_and_bound_receipt(self):
  r,v,o,seen,audit,_=self.fixture();receipt=await r('eval',v,o)
  self.assertEqual(len(seen),1);self.assertEqual(len(audit),1)
  self.assertNotIn('ssssssss',json.dumps(seen))
  SignedReview({'test-reviewer':b's'*32},clock=lambda:100).verify(receipt,'eval',v,o)
  with self.assertRaises(Invalid):SignedReview({'test-reviewer':b's'*32},clock=lambda:100).verify(receipt,'other',v,o)
 async def test_fail_uncertain_never_sign(self):
  for d in ['fail','uncertain']:
   r,v,o,seen,audit,_=self.fixture(d)
   with self.assertRaises(ProviderFailure):await r('eval',v,o)
   self.assertEqual(len(seen),1);self.assertEqual(len(audit),1)
 async def test_missing_checks_forged_coverage_wrong_model(self):
  for mode in ('checks','coverage','model'):
   r,v,o,seen,audit,a=self.fixture(version='wrong' if mode=='model' else 'review-model')
   if mode=='checks':a['checks'].pop('grounding')
   if mode=='coverage':a['local_issue_keys']=[]
   with self.assertRaises(Invalid):await r('eval',v,o)
 async def test_existing_runtime_accepts_review_and_recovers_rejection(self):
  from tool.test_essay_reviewed_runtime import RuntimeTests
  for decision,expected in [('pass','completed'),('fail','failed')]:
   w,calls,requests,saved,claim,output=RuntimeTests().fixture()
   r,_,_,review_calls,audit,assessment=self.fixture(decision)
   assessment['local_issue_keys']=[x['issue_key'] for x in output['improvements'] if x['claim_scope']=='local_sentence']
   def wrap(fn):
    async def call(*args,**kwargs):return fn(*args,**kwargs)
    return call
   for name in ('rpc','receipt_sink','checkpoint'):setattr(w,name,wrap(getattr(w,name)))
   w.provider.transport=wrap(w.provider.transport);w.provider.evaluate=w.provider.evaluate_async
   w.review_source=r;w.reviewer=SignedReview({'test-reviewer':b's'*32},clock=lambda:100)
   self.assertEqual(await w.execute_async('evaluation'),expected)
   self.assertEqual(len(requests),1);self.assertEqual(len(review_calls),1)
   self.assertEqual(len(saved),1 if decision=='pass' else 0)
   self.assertEqual(calls[-1][0],'essay_finalize_success' if decision=='pass' else 'essay_finalize_failure')
 async def test_transport_no_tools_store_false_and_key_isolation(self):
  calls=[]
  async def transport(req,timeout):calls.append(json.loads(req.data));raise TimeoutError()
  r=openai_review(key='synthetic-api-key',model='review-model',model_version='review-model',reviewer_id='test-reviewer',signing_key=b's'*32,transport=transport)
  async def audit(_):pass
  from tool.essay_lab.live_worker import Unknown
  with self.assertRaises(Unknown):await r.bind_audit(audit)('eval',{'answer':'test'},{'improvements':[]})
  self.assertEqual(len(calls),1);self.assertFalse(calls[0]['store']);self.assertNotIn('tools',calls[0]);self.assertNotIn('ssssssss',json.dumps(calls))
if __name__=='__main__':unittest.main()
