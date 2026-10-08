"""No network: real-provider request path with fake transport + existing worker validator.
Successful fixtures are engineering verification, not actual provider/quality approval.
"""
from dataclasses import replace
import json,unittest
from tool.test_essay_live_worker import fixture,receipt
from tool.essay_lab.live_worker import (OpenAIResponses,ProviderResult,SignedReview,PROMPT_VERSION,
                                      output_schema,digest,Unknown,Invalid,ProviderFailure)
from tool.essay_lab.reviewed_runtime import RuntimePermit,ReviewedRuntimeWorker,dispatch_owned_evaluation,reviewed_openai
from tool.essay_lab.positive_learning import PROMPT_VERSION

class RuntimeTests(unittest.TestCase):
    def fixture(self, mode='ok'):
        claim,cache,out=fixture();claim.update(run_id='run',lease_token='lease')
        binding=dict(policy_version='reviewed-fixture',provider='openai',model='fixture-model',
                     model_version='fixture-model',prompt_version=PROMPT_VERSION,contract_version='1.3')
        claim['provider_binding']=dict(binding);claim['input']['provider_binding']=dict(binding)
        calls=[];requests=[];saved=[]
        class Response:
            def __enter__(self):return self
            def __exit__(self,*a):pass
            def read(self,n):return json.dumps({'status':'completed','model':'fixture-model','usage':{'input_tokens':1,'output_tokens':2,'total_tokens':3},'output':[{'type':'message','content':[{'type':'output_text','text':json.dumps(out) if mode!='invalid' else '{}'}]}]}).encode()
        def transport(req,timeout):
            requests.append(json.loads(req.data))
            if mode=='timeout':raise TimeoutError()
            return Response()
        provider=reviewed_openai('fixture-only',binding,transport=transport)
        provider.binding=dict(binding)
        def rpc(name,args):
            calls.append((name,args))
            if name=='essay_claim':return claim
            if name=='essay_finalize_success' and mode=='lost_finalize':raise Unknown()
            return 'completed'
        permit=RuntimePermit('evaluation',digest(claim['input']),digest(cache),binding,160,True)
        worker=ReviewedRuntimeWorker(rpc,provider,cache,SignedReview({'independent-test':b'test-only-not-deployed'},clock=lambda:100),receipt,lambda _:None,saved.append,permit=permit,clock=lambda:100)
        return worker,calls,requests,saved,claim,out

    def test_real_request_shape_existing_atomic_finalize(self):
        w,calls,requests,saved,_,_=self.fixture()
        self.assertEqual(w.execute('evaluation'),'completed')
        self.assertEqual([n for n,_ in calls],['essay_claim','essay_record_provider_telemetry','essay_finalize_success'])
        self.assertEqual(len(requests),1);self.assertFalse(requests[0]['store'])
        self.assertNotIn('tools',requests[0]);self.assertEqual(len(saved),1)
        self.assertNotIn('lease_token',requests[0]['input'])
        self.assertEqual(saved[0]['p_output']['contract_version'],'1.3')

    def test_gates_before_claim_or_network(self):
        for change in [dict(enabled=False),dict(expires_at=99),dict(evaluation_id='foreign'),dict(cache_sha256='changed')]:
            w,calls,requests,*_=self.fixture();w.permit=replace(w.permit,**change)
            with self.assertRaises(Invalid):w.execute('evaluation')
            self.assertEqual(calls,[]);self.assertEqual(requests,[])

    def test_missing_production_binding_and_changed_evidence_no_provider(self):
        for mode in ['no_binding','changed_snapshot']:
            w,calls,requests,_,claim,_=self.fixture()
            if mode=='no_binding':claim.pop('provider_binding');claim['input'].pop('provider_binding')
            else:claim['input']['answer_hash']='changed'
            self.assertEqual(w.execute('evaluation'),'failed');self.assertEqual(requests,[])
            self.assertEqual(calls[-1][0],'essay_finalize_failure')

    def test_timeout_and_invalid_output_use_existing_recovery(self):
        for mode,status,fn in [('timeout','reconciling','essay_timeout'),('invalid','failed','essay_finalize_failure')]:
            w,calls,requests,saved,*_=self.fixture(mode)
            self.assertEqual(w.execute('evaluation'),status)
            self.assertEqual(calls[-1][0],fn);self.assertEqual(len(requests),1);self.assertEqual(saved,[])

    def test_ambiguous_finalize_checkpoint_replay_no_second_provider(self):
        w,calls,requests,saved,*_=self.fixture('lost_finalize')
        with self.assertRaises(Unknown):w.execute('evaluation')
        self.assertEqual(len(saved),1)
        w.rpc=lambda n,a: calls.append((n,a)) or 'completed'
        self.assertEqual(w.resume_finalization(saved[0]),'completed')
        self.assertEqual(len(requests),1)
        self.assertNotIn('essay_finalize_failure',[n for n,_ in calls])
        with self.assertRaises(Invalid):w.resume_finalization(dict(saved[0],p_evaluation='foreign'))

    def test_owner_check_and_completed_retry_never_dispatch(self):
        w,calls,requests,*_=self.fixture()
        def deny(*a):raise Invalid('PT403')
        with self.assertRaises(Invalid):dispatch_owned_evaluation('evaluation',deny,w)
        for state in ['completed','reconciling','failed']:
            self.assertEqual(dispatch_owned_evaluation('evaluation',lambda *a:{'state':state},w),state)
        self.assertEqual(calls,[]);self.assertEqual(requests,[])
        self.assertEqual(dispatch_owned_evaluation('evaluation',lambda *a:{'state':'processing','credit_state':'reserved'},w),'completed')

    def test_redirect_and_noncanonical_endpoint_denied(self):
        from urllib.request import Request
        from tool.essay_lab.reviewed_runtime import _NoRedirect,_provider_transport
        with self.assertRaises(ProviderFailure):_NoRedirect().redirect_request(None,None,302,'',{},'https://other.invalid')
        with self.assertRaises(Invalid):_provider_transport(Request('https://other.invalid'),5)
        w,calls,requests,*_=self.fixture()
        w.permit.binding['prompt_version']='scaffolding-1.3-v1'
        with self.assertRaises(Invalid):w.execute('evaluation')
        self.assertEqual(calls,[])

    def test_independent_review_is_mandatory(self):
        w,calls,requests,*_=self.fixture();w.reviewer=None
        with self.assertRaises(Invalid):w.execute('evaluation')
        self.assertEqual(calls,[])
        w,calls,requests,saved,*_=self.fixture();w.review_source=lambda *a:{}
        self.assertEqual(w.execute('evaluation'),'failed');self.assertEqual(saved,[])

if __name__=='__main__':unittest.main()
