import asyncio,copy,json,unittest
from tool.test_essay_live_worker import fixture,receipt
from tool.essay_lab.live_worker import QUALITY_CHECKS,digest,ProviderResult,Unknown,Invalid,ProviderFailure,package,validate_output,SignedReview
from tool.essay_lab.quality_repair import QualityRepair,ReviewRejected,local_targets,merge_patch,combined_generation_usage

def assessment(check='grounding',reason='[root] 근거가 설명과 다릅니다.'):
 checks={k:{'decision':'pass','reason':'검증'} for k in QUALITY_CHECKS};checks[check]={'decision':'fail','reason':reason}
 return {'checks':checks,'local_issue_keys':[]}
def patch(out,field='explanation',value='공식 근거에 맞는 설명'):
 return json.dumps({'base_sha256':digest(out),'edits':[{'collection':'improvements','id':'root','field':field,'value_text':value,'value_ids':None}]})
class Journal:
 def __init__(self):self.rows={}
 async def begin(self,k):
  if k in self.rows:raise Unknown('PENDING_CALL_NOT_REPLAYED')
  self.rows[k]=None
 async def write(self,k,v):self.rows[k]=copy.deepcopy(v)
class Provider:
 def __init__(self,values):self.values=iter(values);self.calls=0
 async def evaluate_async(self,request):
  self.calls+=1;result=next(self.values)
  if isinstance(result,Exception):raise result
  return ProviderResult(result,'synthetic','test',10,20,5,30,'test')
class Review:
 def __init__(self,results):self.results=iter(results);self.calls=0;self.audit=None
 def bind_audit(self,audit):self.audit=audit;return self
 async def __call__(self,e,v,o):
  self.calls+=1;decision=next(self.results)
  await self.audit({'output_sha256':digest({'call':self.calls}),'component':'independent_review','telemetry':{'input_tokens':1}})
  if decision:raise ReviewRejected(decision)
  return receipt(e,v,o)
class QualityTests(unittest.IsolatedAsyncioTestCase):
 def setup_pipeline(self,patches,reviews,full=()):
  self.c,self.cache,self.o=fixture();self.j=Journal();self.p=Provider(patches);self.f=Provider(full);self.r=Review(reviews);self.receipts=[]
  async def persist(v):self.receipts.append(v)
  self.pipeline=QualityRepair(journal=self.j,prefix='q1-a0-',provider=self.f,repair_provider=self.p,source=self.r,
      binding={'provider':'synthetic','model':'test','model_version':'test'},persist_receipt=persist)
  return self.pipeline
 async def run_pipeline(self):return await self.pipeline('e',package(self.c,self.cache),self.o,self.c)
 async def test_local_repair_success_full_review_and_score_preserved(self):
  _,_,o=fixture();self.setup_pipeline([patch(o)],[assessment(),None]);out,signed=await self.run_pipeline()
  self.assertEqual(out['dimensions'],self.o['dimensions']);self.assertEqual(out['summary'],self.o['summary']);validate_output(out,self.c)
  SignedReview({'independent-test':b'test-only-not-deployed'},clock=lambda:100).verify(signed,'e',package(self.c,self.cache),out)
  self.assertEqual((self.p.calls,self.f.calls,self.r.calls),(1,0,2))
 async def test_two_partial_then_one_full_then_hold(self):
  c,_,o=fixture();raw=patch(o);updated=merge_patch(o,raw,local_targets(assessment(),o),c);self.setup_pipeline([raw,patch(updated,value='다시 수정한 설명')],[assessment()]*4,[json.dumps(o)])
  with self.assertRaisesRegex(ProviderFailure,'ADMIN_QUALITY_REVIEW_REQUIRED'):await self.run_pipeline()
  self.assertEqual((self.p.calls,self.f.calls,self.r.calls),(2,1,4));self.assertIn('q1-a0-quality-review-required',self.j.rows)
 async def test_nonlocal_goes_full_once(self):
  _,_,o=fixture();self.setup_pipeline([],[assessment('stance_preservation'),None],[json.dumps(o)])
  await self.run_pipeline();self.assertEqual((self.p.calls,self.f.calls),(0,1))
 async def test_partial_failure_then_full_success(self):
  _,_,o=fixture();self.setup_pipeline(['{}','{}'],[assessment(),None],[json.dumps(o)])
  out,_=await self.run_pipeline();self.assertEqual(out,o);self.assertEqual((self.p.calls,self.f.calls,self.r.calls),(2,1,2))
 async def test_provider_unknown_never_falls_back(self):
  self.setup_pipeline([Unknown('PROVIDER_NETWORK_UNKNOWN')],[assessment()])
  with self.assertRaises(Unknown):await self.run_pipeline()
  self.assertEqual(self.f.calls,0);self.assertIsNone(self.j.rows['q1-a0-quality-partial-1'])
 async def test_same_journal_cannot_replay_provider(self):
  _,_,o=fixture();self.setup_pipeline([patch(o)],[assessment(),None]);await self.run_pipeline()
  with self.assertRaises(Unknown):await self.run_pipeline()
  self.assertEqual(self.p.calls,1)
 async def test_existing_worker_uses_full_validation_signature_and_checkpoint(self):
  from tool.essay_lab.live_worker import Worker
  _,_,o=fixture();self.setup_pipeline([patch(o)],[assessment(),None]);saved=[];calls=[]
  class Initial:
   synthetic_only=True
   async def evaluate(self,value):return ProviderResult(json.dumps(o),'synthetic','test',1,2,3,3,'test')
  async def rpc(name,args):calls.append(name);return self.c if name=='essay_claim' else 'completed'
  worker=Worker(rpc,Initial(),self.cache,SignedReview({'independent-test':b'test-only-not-deployed'},clock=lambda:100),
    lambda *_:None,lambda _:None,saved.append,isolated_fixture=True,quality_repair=self.pipeline)
  self.assertEqual(await worker.execute_async('e'),'completed');self.assertEqual(len(saved),1)
  self.assertEqual(saved[0]['p_output']['dimensions'],o['dimensions']);self.assertEqual(calls.count('essay_finalize_success'),1)
 async def test_full_rejected_cannot_repeat_partial(self):
  _,_,o=fixture();self.setup_pipeline([],[assessment('stance_preservation'),assessment()],[json.dumps(o)])
  with self.assertRaisesRegex(ProviderFailure,'ADMIN_QUALITY'):await self.run_pipeline()
  self.assertEqual(self.p.calls,0);self.assertEqual(self.f.calls,1)
 async def test_aggregate_known_generation_tokens(self):
  _,_,o=fixture();self.setup_pipeline([patch(o)],[assessment(),None]);await self.run_pipeline()
  result=combined_generation_usage(ProviderResult('{}','synthetic','test',100,200,50,300,'test'),self.pipeline)
  self.assertEqual((result.input_tokens,result.output_tokens,result.total_tokens,result.latency_ms),(110,220,330,55));self.assertIsNone(result.cost_amount)
 def test_patch_cannot_change_scores_or_unknown_identity(self):
  c,_,o=fixture();targets=local_targets(assessment(),o)
  for field in ['level','summary','quote','issue_key']:
   with self.assertRaises(Invalid):merge_patch(o,patch(o,field),targets,c)
  bad=json.loads(patch(o));bad['base_sha256']='f'*64
  with self.assertRaises(Invalid):merge_patch(o,json.dumps(bad),targets,c)
 def test_no_localization_from_unscoped_reason(self):
  _,_,o=fixture();self.assertEqual(local_targets(assessment(reason='근거 오류'),o),[])
if __name__=='__main__':unittest.main()
