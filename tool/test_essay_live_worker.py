"""Synthetic worker contracts. No external provider or production database access."""
import copy
import hashlib
import hmac
import json
import unittest
from tool.essay_lab.live_worker import *


def fixture():
    body='🙂 가가 문장을 확인한다. '
    evidence=[dict(id=str(i),role=role,hash='a'*64,version=1,locator={'page':1}) for i,role in enumerate(['question','passage','exam_intent','scoring_criteria'])]
    snap={'contract_version':'1.3','attempt_id':'attempt','answer_hash':sha256(body.encode()).hexdigest(),'criteria':[{'id':'criterion','version':1}],'evidence':evidence,
          'scaffolding_context':{'items':[],'previous_core_progress_ids':[]}}
    claim={'run_id':'run','lease_token':'lease','answer':body,'input':snap}
    cache={'contract_version':'1.3','evidence':[{'binding':v,'text':'합성 공식 요구','text_sha256':sha256('합성 공식 요구'.encode()).hexdigest()} for v in evidence],
           'criteria':[{'binding':snap['criteria'][0],'label':'논리 구성'}]}
    issue={'issue_key':'root','category':'reasoning','status':'open','previous_progress_id':None,'title':'연결','explanation':'결론의 이유를 확인해요.','action':'이유를 연결하세요.','priority':1,'evidence_ids':['3'],'claim_scope':'official_criterion'}
    out={'contract_version':'1.3','attempt_id':'attempt','answer_hash':snap['answer_hash'],'summary':'합성 평가','strengths':['주장을 썼어요.'],'checklist':['연결 확인'],'dimensions':[{'criterion_id':'criterion','level':3,'explanation':'기준 확인','evidence_ids':['3']}],
         'improvements':[issue],'core_improvement_keys':['root'],'previous_improvement_reviews':[],
         'sentence_feedback':[{'observation_key':'s1','linked_issue_key':'root','category':'logic','priority':'contradiction','start':0,'end':5,'quote':body[:5],'diagnosis':'합성 관측','direction':'확인하세요.'}]}
    return claim,cache,out


def receipt(e,p,o,clock=100):
    r={'reviewer':'independent-test','expires_at':clock+60,'evaluation_id':e,'package_sha256':digest(p),'output_sha256':digest(o),'quality':dict.fromkeys(QUALITY_CHECKS,True),
       'local_issue_keys':[x['issue_key'] for x in o['improvements'] if x['claim_scope']=='local_sentence']}
    r['signature']=hmac.new(b'test-only-not-deployed',encoded(r),'sha256').hexdigest();return r


class Contracts(unittest.TestCase):
    def setUp(self):self.c,self.cache,self.o=fixture()
    def test_exact_unicode(self):self.assertEqual(validate_output(self.o,self.c),self.o)
    def test_reject_matrix(self):
        changes=[lambda o:o.update(local_reviews=[]),lambda o:o.update(uncertainty_note='pilot'),lambda o:o.update(answer_hash='0'*64),lambda o:o.update(attempt_id='foreign'),
         lambda o:o['dimensions'][0].update(level=True),lambda o:o['dimensions'][0].update(criterion_id='foreign'),lambda o:o['dimensions'][0].update(evidence_ids=['foreign']),
         lambda o:o['sentence_feedback'][0].update(quote='없는 문장'),lambda o:o['sentence_feedback'][0].update(end=4),lambda o:o['sentence_feedback'][0].update(start=True),
         lambda o:o['sentence_feedback'][0].update(quote='🙂 가가'),lambda o:o['sentence_feedback'].append(dict(o['sentence_feedback'][0],observation_key='other')),
         lambda o:o.update(sentence_feedback=o['sentence_feedback']*6),lambda o:o.update(core_improvement_keys=['a','b','c','d']),lambda o:o['improvements'].append(o['improvements'][0]),
         lambda o:o['improvements'][0].update(status='resolved'),lambda o:o['improvements'][0].update(claim_scope='local_sentence'),lambda o:o['improvements'][0].update(explanation='x'*451)]
        for i,change in enumerate(changes):
            with self.subTest(i=i):
                bad=deepcopy(self.o);change(bad)
                with self.assertRaises(Invalid):validate_output(bad,self.c)
    def test_json(self):
        for raw in ['{"x":1,"x":2}','{"x":NaN}','```json {} ```','x'*262145]:
            with self.assertRaises(Invalid):strict_json(raw)
    def test_optional_transport_example(self):
        self.o['sentence_feedback'][0]['example']=None
        parsed=parse_provider(json.dumps(self.o),self.c)
        self.assertNotIn('example',parsed['sentence_feedback'][0])
    def test_zero_supported(self):
        self.o.update(improvements=[],core_improvement_keys=[],sentence_feedback=[])
        validate_output(self.o,self.c)
    def test_prior_states(self):
        for state,prior_status in [('unchanged','open'),('improved','open'),('resolved','improved'),('recurred','resolved')]:
            with self.subTest(state=state):
                c,_,o=fixture();c['input']['scaffolding_context']={'items':[{'progress_id':'p','issue_key':'root','status':prior_status}],'previous_core_progress_ids':['p']}
                o['improvements'][0].update(previous_progress_id='p',status=state)
                o['previous_improvement_reviews']=[{'previous_progress_id':'p','outcome':state,'reason':'새 답안 확인'}]
                if state=='resolved':o.update(core_improvement_keys=[],sentence_feedback=[])
                validate_output(o,c)
                o['previous_improvement_reviews']=[]
                with self.assertRaises(Invalid):validate_output(o,c)
    def test_not_assessable(self):
        self.c['input']['scaffolding_context']={'items':[{'progress_id':'p','issue_key':'root','status':'open'}],'previous_core_progress_ids':['p']}
        self.o.update(improvements=[],core_improvement_keys=[],sentence_feedback=[],previous_improvement_reviews=[{'previous_progress_id':'p','outcome':'not_assessable','reason':'비교 근거 부족'}])
        validate_output(self.o,self.c)
    def test_cache_frozen(self):
        p=package(self.c,self.cache);self.assertNotIn('lease_token',p);self.assertNotIn('run_id',p)
        for key in ['text','text_sha256','binding']:
            bad=deepcopy(self.cache);bad['evidence'][0][key]='changed'
            with self.assertRaises(Invalid):package(self.c,bad)
        self.c['input']['evidence'][0]['role']='example_answer'
        with self.assertRaises(Invalid):package(self.c,self.cache)
    def test_signed_review(self):
        self.o['improvements'][0].update(claim_scope='local_sentence',evidence_ids=[])
        p=package(self.c,self.cache);r=receipt('e',p,self.o)
        reviewer=SignedReview({'independent-test':b'test-only-not-deployed'},clock=lambda:100)
        reviews=reviewer.verify(r,'e',p,self.o)
        self.assertEqual(finalize_payload(self.o,contract_version='1.3',local_reviews=reviews)['local_reviews'],reviews)
        for key,value in [('evaluation_id','other'),('signature','forged'),('quality',{}),('local_issue_keys',[])]:
            bad=dict(r,**{key:value})
            with self.assertRaises(Invalid):reviewer.verify(bad,'e',p,self.o)
        changed=deepcopy(self.o);changed['improvements'][0]['action']='새로운 주장'
        with self.assertRaises(Invalid):reviewer.verify(r,'e',p,changed)
        with self.assertRaises(Invalid):SignedReview({'independent-test':b'test-only-not-deployed'},clock=lambda:200).verify(r,'e',p,self.o)
    def test_worker_paths(self):
        for mode,expected in [('success','essay_finalize_success'),('timeout','essay_timeout'),('bad','essay_finalize_failure'),('failure','essay_finalize_failure')]:
            with self.subTest(mode=mode):
                calls=[];facts=[];saved=[]
                def rpc(name,args):calls.append((name,args));return self.c if name=='essay_claim' else 'completed'
                out=self.o
                class Provider:
                    synthetic_only=True
                    def evaluate(self,p):
                        if mode=='timeout':raise Unknown()
                        if mode=='failure':raise ProviderFailure()
                        return ProviderResult(json.dumps(out) if mode=='success' else '{}','synthetic','test',10,20,1)
                w=Worker(rpc,Provider(),self.cache,SignedReview({'independent-test':b'test-only-not-deployed'},clock=lambda:100),receipt,facts.append,saved.append,isolated_fixture=True)
                w.execute('e');self.assertEqual(calls[-1][0],expected)
                self.assertEqual(len(saved),int(mode=='success'))
    def test_finalize_ambiguity_no_release(self):
        calls=[];saved=[]
        def rpc(name,args):
            calls.append(name)
            if name=='essay_claim':return self.c
            raise Unknown()
        out=self.o
        class Provider:
            synthetic_only=True
            def evaluate(self,p):return ProviderResult(json.dumps(out),'synthetic','test',1,1,1)
        w=Worker(rpc,Provider(),self.cache,SignedReview({'independent-test':b'test-only-not-deployed'},clock=lambda:100),receipt,lambda _:None,saved.append,isolated_fixture=True)
        with self.assertRaises(Unknown):w.execute('e')
        self.assertEqual(calls,['essay_claim','essay_finalize_success']);self.assertEqual(len(saved),1)
    def test_prompt_quality_regression(self):
        self.assertIn('내용 보충 필요와 문장 의미 불명확을 구분',PROMPT)
        self.assertIn('분량 조건',PROMPT)
        self.assertIn('간결',PROMPT)
    def test_real_provider_gate_no_call(self):
        calls=[]
        def rpc(name,args):calls.append(name);return self.c if name=='essay_claim' else None
        class NeverCall:
            def evaluate(self,p):raise AssertionError('Actual provider must not run without metadata boundary')
        worker=Worker(rpc,NeverCall(),self.cache,None,None,None,None)
        with self.assertRaisesRegex(Invalid,'REAL_PROVIDER_NOT_AUTHORIZED'):worker.execute('e')
        self.assertEqual(calls,[])
    def test_malformed_types_fail_closed(self):
        for key in ['dimensions','improvements','sentence_feedback','previous_improvement_reviews']:
            for value in [None,1,True,{},[None],[{}],[{'issue_key':[]}]]:
                with self.subTest(key=key,value=value):
                    bad=deepcopy(self.o);bad[key]=value
                    with self.assertRaises(Invalid):parse_provider(json.dumps(bad),self.c)
    def test_transport_request(self):
        class Response:
            def __enter__(self):return self
            def __exit__(self,*args):pass
            def read(self,n):return encoded({'status':'completed','model':'test','usage':{'input_tokens':1,'output_tokens':2},'output':[{'type':'message','content':[{'type':'output_text','text':'{}'}]}]})
        def transport(req,timeout):
            p=json.loads(req.data);self.assertIs(p['store'],False);self.assertNotIn('tools',p);self.assertEqual(timeout,75)
            self.assertEqual(p['text']['format']['schema'],output_schema());return Response()
        result=OpenAIResponses('test-key','test',output_schema(),transport=transport).evaluate({})
        self.assertEqual(result.input_tokens,1)

if __name__=='__main__':unittest.main()
