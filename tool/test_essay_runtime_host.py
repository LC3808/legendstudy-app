"""Private HTTP adapter + existing worker, synthetic transport only. No Provider call."""
import unittest,io,json
from contextlib import nullcontext
from unittest.mock import patch
from dataclasses import replace
from tool.test_essay_reviewed_runtime import RuntimeTests
from tool.essay_lab.runtime_host import RuntimeHost,HostedQuestion

E='00000000-0000-4000-8000-000000000001';Q='00000000-0000-4000-8000-000000000002'
class HostTests(unittest.TestCase):
 def fixture(self):
  w,calls,requests,saved,claim,out=RuntimeTests().fixture()
  class Journal:
   ready=True
   value=None
   def lock(self,e):return nullcontext()
   def read(self,e):return self.value
   def write(self,e,v):self.value=v;saved.append(v)
  journal=Journal()
  q=HostedQuestion(Q,'v1','essay-v1.3/policy/'+'a'*64,w.permit.binding,{'private_content':[{'question_id':Q,'metadata_version':'v1','requires_figure':False}]},True,True)
  def factory(permit,cache,checkpoint):w.permit=permit;w.cache=cache;w.checkpoint=checkpoint;return w
  h=RuntimeHost(questions={Q:q},authenticate=lambda t:t=='owner',owned=lambda t,e:{'id':e,'question_id':Q,'regime_key':q.regime,'input_snapshot':claim['input'],'answer':claim['answer']},user_rpc=lambda *a:{'state':'processing','credit_state':'reserved'},worker_factory=factory,journal=journal,service_token='test-only-service-token-not-deployed',preflight=lambda q:True,enabled=True,clock=lambda:100)
  return h,w,calls,requests,journal
 def dispatch(self,h):return h.handle('/evaluate',h.service_token,'owner',{'evaluation_id':E})
 def test_service_and_owner_auth_before_claim(self):
  h,w,c,r,j=self.fixture()
  self.assertEqual(h.handle('/evaluate','wrong','owner',{'evaluation_id':E})[0],403)
  self.assertEqual(h.handle('/evaluate',h.service_token,'foreign',{'evaluation_id':E})[0],409)
  self.assertEqual(c,[]);self.assertEqual(r,[])
 def test_rights_and_visual_gate(self):
  for change in [dict(approved_processing=False),dict(reviewed_cache=False),dict(plan={'private_content':[{'question_id':Q,'metadata_version':'v1','requires_figure':True}]})]:
   h,w,c,r,j=self.fixture();h.questions[Q]=replace(h.questions[Q],**change)
   self.assertEqual(h.handle('/admission',h.service_token,'',{'questionId':Q,'metadataVersion':'v1'})[0],409);self.assertEqual(c,[])
 def test_missing_reviewer_or_provider_preflight_denies_admission(self):
  h,w,c,r,j=self.fixture();h.preflight=lambda q:False
  self.assertEqual(h.handle('/admission',h.service_token,'',{'questionId':Q,'metadataVersion':'v1'})[0],409)
  self.assertEqual(c,[]);self.assertEqual(r,[])
 def test_private_admission_version_and_short_expiry(self):
  h,*_=self.fixture();code,v=h.handle('/admission',h.service_token,'',{'questionId':Q,'metadataVersion':'v1'})
  self.assertEqual(code,200);self.assertEqual(v['expiresAt'],160000)
  self.assertEqual(h.handle('/admission',h.service_token,'',{'questionId':Q,'metadataVersion':'changed'})[0],409)
 def test_existing_worker_and_checkpoint_before_finalize(self):
  h,w,c,r,j=self.fixture()
  with patch('tool.essay_lab.runtime_host.cache_for_claim',return_value=w.cache):self.assertEqual(self.dispatch(h)[0],202)
  self.assertEqual(len(r),1);self.assertIsNotNone(j.value);self.assertEqual(c[-1][0],'essay_finalize_success')
  with patch('tool.essay_lab.runtime_host.cache_for_claim',return_value=w.cache):self.assertEqual(self.dispatch(h)[0],202)
  self.assertEqual(len(r),1) # durable replay never regenerates
 def test_completed_status_does_not_call_provider(self):
  h,w,c,r,j=self.fixture();h.user_rpc=lambda *a:{'state':'completed'}
  with patch('tool.essay_lab.runtime_host.cache_for_claim',return_value=w.cache):self.assertEqual(self.dispatch(h)[0],200)
  self.assertEqual(r,[])
 def test_wsgi_bounded_and_no_store(self):
  h,*_=self.fixture();statuses=[]
  body=b'{}';out=h.wsgi({'REQUEST_METHOD':'POST','CONTENT_LENGTH':'5000','wsgi.input':io.BytesIO(body)},lambda *a:statuses.append(a))
  self.assertIn('400',statuses[0][0]);self.assertEqual(json.loads(out[0])['code'],'INVALID_REQUEST')
  self.assertIn(('Cache-Control','no-store'),statuses[0][1])
if __name__=='__main__':unittest.main()
