"""No network: adapter identity and measured telemetry contract adversarial tests."""
import json,unittest
from dataclasses import replace
from tool.test_essay_live_worker import fixture,receipt
from tool.essay_lab.live_worker import *

class Binding(unittest.TestCase):
    def setUp(self):
        self.claim,self.cache,self.output=fixture()
        self.binding=dict(policy_version='synthetic-v1',provider='synthetic',model='synthetic-only',model_version='fixture-1',prompt_version=PROMPT_VERSION,contract_version='1.3')
        self.claim['provider_binding']=dict(self.binding);self.claim['input']['provider_binding']=dict(self.binding)
        self.result=ProviderResult(json.dumps(self.output),'synthetic','synthetic-only',10,20,12,30,'fixture-1')
    def worker(self,mode='ok',binding=None,result=None):
        calls=[];invoked=[];owner=self
        class Synthetic:
            synthetic_only=True
            def __init__(self):self.binding=binding or owner.binding
            def evaluate(self,p):
                invoked.append(True)
                if mode=='timeout':raise Unknown(usage=owner.result)
                if mode=='failure':raise ProviderFailure(usage=owner.result)
                return result or owner.result
        def rpc(n,a):
            calls.append((n,a))
            if n=='essay_claim':return self.claim
            if n=='essay_record_provider_telemetry' and mode=='telemetry_network':raise Unknown()
            return 'done'
        w=Worker(rpc,Synthetic(),self.cache,SignedReview({'independent-test':b'test-only-not-deployed'},clock=lambda:100),receipt,lambda _:None,lambda _:None,isolated_fixture=True)
        return w,calls,invoked
    def test_bound_success(self):
        w,calls,invoked=self.worker();w.execute('e')
        self.assertEqual([x[0] for x in calls],['essay_claim','essay_record_provider_telemetry','essay_finalize_success'])
        self.assertEqual(len(invoked),1)
        self.assertEqual(set(calls[1][1]),set('p_evaluation p_run p_token p_input_tokens p_output_tokens p_total_tokens p_latency_ms p_cost_amount p_currency'.split()))
    def test_override_denied_before_provider(self):
        for key in self.binding:
            w,calls,invoked=self.worker(binding=dict(self.binding,**{key:'tampered'}));self.assertEqual(w.execute('e'),'failed');self.assertEqual(invoked,[])
    def test_claim_snapshot_disagreement(self):
        self.claim['provider_binding']['model']='tampered'
        w,_,invoked=self.worker();self.assertEqual(w.execute('e'),'failed');self.assertEqual(invoked,[])
    def test_response_cannot_select_identity(self):
        for field in ['provider','model','model_version']:
            w,calls,_=self.worker(result=replace(self.result,**{field:'tampered'}));self.assertEqual(w.execute('e'),'failed')
            self.assertNotIn('essay_record_provider_telemetry',[c[0] for c in calls])
    def test_timeout_failure_usage_before_terminal(self):
        for mode,last in [('timeout','essay_timeout'),('failure','essay_finalize_failure')]:
            w,calls,_=self.worker(mode);w.execute('e');self.assertEqual([c[0] for c in calls],['essay_claim','essay_record_provider_telemetry',last])
    def test_ambiguous_telemetry_no_result_or_release(self):
        w,calls,invoked=self.worker('telemetry_network')
        with self.assertRaises(Unknown):w.execute('e')
        self.assertEqual(len(invoked),1);self.assertEqual([c[0] for c in calls],['essay_claim','essay_record_provider_telemetry'])
    def test_invalid_counters(self):
        for changes in [{'input_tokens':True},{'input_tokens':-1},{'total_tokens':29},{'latency_ms':-1},{'latency_ms':None},{'output_tokens':2**63}]:
            with self.assertRaises(Invalid):telemetry_payload({},replace(self.result,**changes),self.binding)
    def test_missing_total_is_not_invented(self):
        self.assertIsNone(telemetry_payload({},replace(self.result,total_tokens=None),self.binding)['p_total_tokens'])

if __name__=='__main__':unittest.main()
