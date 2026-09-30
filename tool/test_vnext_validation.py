"""Offline one-shot lifecycle tests. No secrets, sockets, or provider calls."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from tool.essay_lab import vnext_validation as v
from tool.essay_lab.live_worker import Invalid, encoded, digest
from tool.test_essay_live_worker import fixture

SLOT=next(iter(v.SLOTS));KEY='synthetic-l2c2-secret'

def prepared():
    c,_,o=fixture();c['input']['attempt_id']=SLOT;o['attempt_id']=SLOT
    payload={'model':v.POLICY['model']}
    binding=dict(slot=SLOT,policy=v.POLICY,payload_hash=digest(payload),claim_hash=digest(c))
    return ({},c,payload,binding),o

class Fake:
    synthetic_only=True
    def __init__(self,raw,status=200,error=None,before=None):self.raw,self.status,self.error,self.before=raw,status,error,before;self.calls=0
    def send(self,body,headers):
        self.calls+=1
        if self.before:self.before()
        if self.error:raise self.error
        return self.status,self.raw

def envelope(output):
    return encoded(dict(model='gpt-5.6-sol',status='completed',usage=dict(input_tokens=10,output_tokens=20,total_tokens=30,input_tokens_details={'cached_tokens':0}),output=[dict(type='message',content=[dict(type='output_text',text=json.dumps(output))])]))

class Lifecycle(unittest.TestCase):
    def setUp(self):
        t=tempfile.TemporaryDirectory(prefix='essay-l2c2-test',dir='/private/tmp');self.addCleanup(t.cleanup);self.root=Path(t.name)
        self.p,self.o=prepared()
        for name in ('socket.create_connection','http.client.HTTPSConnection'):
            p=patch(name,side_effect=AssertionError('NETWORK_FORBIDDEN'));p.start();self.addCleanup(p.stop)
    def run_fake(self,f):return v.run_slot(self.root,SLOT,self.p,KEY,f,synthetic=True)
    def test_success_raw_before_parse_started_before_send(self):
        f=Fake(envelope(self.o),before=lambda:self.assertTrue((self.root/'started'/f'{SLOT}.json').is_file()))
        actual=v.parse_provider
        def parse(raw,claim):
            self.assertTrue((self.root/'results'/SLOT/'raw-response.bin').is_file());return actual(raw,claim)
        with patch.object(v,'parse_provider',side_effect=parse):r=self.run_fake(f)
        self.assertEqual(r['parser'],'PASS');self.assertEqual(f.calls,1);self.assertIsNone(r['telemetry']['actual_cost'])
        with self.assertRaises(Invalid):self.run_fake(f)
        self.assertEqual(f.calls,1)
    def test_parser_failure_consumed_no_repair(self):
        self.o['sentence_feedback'][0]['linked_issue_key']='missing';f=Fake(envelope(self.o));r=self.run_fake(f)
        self.assertEqual(r['validation_error'],'SENTENCE_ROOT');self.assertFalse((self.root/'results'/SLOT/'normalized.json').exists())
        with self.assertRaises(Invalid):self.run_fake(f)
        self.assertEqual(f.calls,1)
    def test_http_error_consumed(self):
        f=Fake(b'{}',429);self.assertEqual(self.run_fake(f)['request_outcome'],'HTTP_ERROR')
        with self.assertRaises(Invalid):self.run_fake(f)
        self.assertEqual(f.calls,1)
    def test_unknown_stops_next(self):
        r=self.run_fake(Fake(b'',error=TimeoutError()));self.assertEqual(r['state'],'UNKNOWN_CONSUMED');self.assertTrue(v.blocked_after(r))
        with self.assertRaises(Invalid):self.run_fake(Fake(b''))
    def test_substitution_stops(self):
        data=json.loads(envelope(self.o));data['model']='unexpected';r=self.run_fake(Fake(encoded(data)))
        self.assertEqual(r['request_outcome'],'MODEL_MISMATCH');self.assertTrue(v.blocked_after(r))
    def test_secret_withheld_stops(self):
        r=self.run_fake(Fake(encoded({'echo':KEY})));self.assertTrue(v.blocked_after(r))
        self.assertFalse((self.root/'results'/SLOT/'raw-response.bin').exists())
        for p in self.root.rglob('*'):
            if p.is_file():self.assertNotIn(KEY.encode(),p.read_bytes())
    def test_deleted_output_not_retry(self):
        v.child_dir(self.root,'started');v.freeze(self.root/'started'/f'{SLOT}.json',b'{}')
        f=Fake(b'{}')
        with self.assertRaises(Invalid):self.run_fake(f)
        self.assertEqual(f.calls,0)
    def test_arbitrary_slot_and_live_closed(self):
        with self.assertRaises(Invalid):v.dispatch(SLOT)
        with self.assertRaises(Invalid):v.run_slot(self.root,'third',self.p,KEY,Fake(b''),synthetic=True)
    def test_payload_or_claim_mutation_rejected_before_marker(self):
        for index in (1,2):
            p=copy.deepcopy(self.p);p[index]['changed']=True
            with self.assertRaises(Invalid):v.run_slot(self.root,SLOT,p,KEY,Fake(b''),synthetic=True)
        self.assertFalse((self.root/'started').exists())
    def test_repository_private_exclusion_failure_stops_before_credentials(self):
        from types import SimpleNamespace
        with patch.object(v,'EXECUTION_AUTHORIZATION',v.AUTHORIZATION), patch.object(v.subprocess,'run',return_value=SimpleNamespace(returncode=1)), patch.object(v,'credential',side_effect=AssertionError('CREDENTIAL_MUST_NOT_BE_READ')):
            with self.assertRaisesRegex(Invalid,'HISTORICAL_PRIVATE_NOT_IGNORED'):v.dispatch(SLOT)
    def test_live_http_one_post_endpoint_and_no_retry(self):
        calls=[]
        class Connection:
            def request(self,*args,**kwargs):calls.append((args,kwargs))
            def getresponse(self):
                class Response:
                    status=429
                    def read(self,n):return b'{}'
                return Response()
            def close(self):pass
        with patch.object(v,'EXECUTION_AUTHORIZATION',v.AUTHORIZATION), patch.object(v.http.client,'HTTPSConnection',return_value=Connection()) as factory:
            h=v.SingleHTTP();self.assertEqual(h.send(b'{}',{}),(429,b'{}'))
            with self.assertRaises(Invalid):h.send(b'{}',{})
            self.assertEqual(factory.call_args.args,('api.openai.com',));self.assertEqual(factory.call_args.kwargs['timeout'],300)
            self.assertEqual(calls[0][0],('POST','/v1/responses'));self.assertEqual(len(calls),1)
    def test_second_requires_first_terminal(self):
        slot=list(v.SLOTS)[1];p=copy.deepcopy(self.p);p[3]['slot']=slot
        with self.assertRaisesRegex(Invalid,'SEQUENTIAL_ONLY'):v.run_slot(self.root,slot,p,KEY,Fake(b''),synthetic=True)
    def test_malformed_and_oversize_remain_raw(self):
        f=Fake(b'not json');r=self.run_fake(f);self.assertEqual(r['parser'],'REJECTED')
        self.assertEqual((self.root/'results'/SLOT/'raw-response.bin').read_bytes(),b'not json')
    def test_credential_contract_refuses_inline_or_multiple(self):
        for env in ({},{'ESSAY_PILOT_OPENAI_API_KEY':KEY},{'OPENAI_API_KEY':KEY,'ESSAY_PILOT_OPENAI_API_KEY_FILE':'/nonexistent'}):
            with self.assertRaises(Invalid):v.credential_environment(env)

@unittest.skipUnless(v.PACKAGES.is_dir(),'private reviewed C1 packages unavailable')
class ActualPackages(unittest.TestCase):
    def test_exact_accepted_packages_blind_materialization(self):
        for slot in v.SLOTS:
            value,c,p,b=v.assemble(slot)
            self.assertEqual(b['package_hash'],v.PINS[v.SLOTS[slot]][0]);self.assertEqual(b['payload_hash'],digest(p))
            self.assertFalse(p['store']);self.assertNotIn('tools',p);self.assertEqual(p['model'],'gpt-5.6-sol')
            self.assertEqual(p['instructions'],v.prompt_contract()['prompt'])
            self.assertEqual(p['text']['format']['schema'],v.output_schema())
            self.assertTrue(all(r['semantic_role'] not in v.evidence.EXAMPLES for r in value['evidence']))
            self.assertEqual(c['input']['answer_hash'],b['answer_hash'])
            self.assertEqual(len(p['input'][0]['content'])-1,len(b['ordered_image_hashes']))
            self.assertNotIn('reviewer',encoded(value).decode())
    def test_official_examples_calibration_only_not_perfect_label(self):
        # Official/accepted examples remain available OFFLINE but absent from request.
        # No assumption that official provenance alone proves every criterion perfect.
        for slot,case in v.SLOTS.items():
            cat=json.loads((v.PACKAGES/case/'catalog.json').read_text());examples=[d for d in cat['derivatives'] if d['semantic_role'] in v.evidence.EXAMPLES]
            self.assertGreaterEqual(len(examples),1)
            value,_,_,_=v.assemble(slot)
            for ex in examples:
                self.assertTrue(v.blob(ex['path']));self.assertNotIn(ex['id'],[r['id'] for r in value['evidence']])
    def test_bad_accepted_pin_rejected(self):
        with patch.dict(v.PINS,{'sookmyung':('0'*64,'0'*64)}):
            with self.assertRaisesRegex(Invalid,'ACCEPTED_PACKAGE_BINDING'):v.assemble(SLOT)

if __name__=='__main__':unittest.main()
