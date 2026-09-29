"""All HTTP responses synthetic. Socket/real HTTPS construction prohibited in this suite."""
import copy
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch
from tool.essay_lab import round1_dispatcher as d
from tool.test_essay_bakeoff import envelope

KEY='synthetic-provider-secret-never-live'


class FakeHTTPS:
    synthetic_only=True
    def __init__(self, data=b'{}', status=200, error=None, before_send=None):
        self.data,self.status,self.error,self.before_send=data,status,error,before_send
        self.calls=[]; self.connections=[]
    def __call__(self,host,**kwargs):
        parent=self; self.connections.append((host,kwargs))
        class Connection:
            def request(self,method,path,body,headers):
                parent.calls.append((method,path,body,headers))
                if parent.before_send: parent.before_send()
                if parent.error: raise parent.error
            def getresponse(self):
                class Response:
                    status=parent.status
                    def read(self,limit): return parent.data[:limit]
                return Response()
            def close(self): pass
        return Connection()


def output(value):
    return dict(contract_version='1.3',attempt_id=value['attempt_id'],answer_hash=value['answer_hash'],
                summary='합성 평가',strengths=['주장을 확인했어요.'],checklist=['연결을 확인하세요.'],
                dimensions=[dict(criterion_id=c,level=3,explanation='합성 기준 진단',evidence_ids=['E2']) for c in value['criteria']],
                improvements=[],core_improvement_keys=[],previous_improvement_reviews=[],sentence_feedback=[])


@unittest.skipUnless(d.PRIVATE.is_dir(), 'private accepted package unavailable')
class Dispatcher(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(prefix='essay-l2b1-test',dir='/private/tmp')
        self.root=Path(self.tmp.name)
        pins=json.loads((d.EVIDENCE/'l2_b1_frozen_files.json').read_text())
        for name in pins['files']:
            target=self.root/name;target.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
            target.write_bytes((d.PRIVATE/name).read_bytes());target.chmod(0o400)
        self.network=patch('http.client.HTTPSConnection',side_effect=AssertionError('REAL_NETWORK_PROHIBITED'))
        self.sockets=patch('socket.create_connection',side_effect=AssertionError('REAL_SOCKET_PROHIBITED'))
        self.network.start();self.sockets.start()
        self.addCleanup(self.network.stop);self.addCleanup(self.sockets.stop);self.addCleanup(self.tmp.cleanup)

    def fixture(self,slot='sookmyung-openai',mutate=None,status=200,error=None):
        value=d.verify_frozen(self.root,slot)[0]
        provider=d.policy(d.SLOTS[slot][1])['provider']
        data=envelope(provider,json.dumps(output(value),ensure_ascii=False))
        if mutate: mutate(data)
        return FakeHTTPS(d.encoded(data),status,error)

    def run_slot(self,slot='sookmyung-openai',fake=None,environment=None):
        provider=d.policy(d.SLOTS[slot][1])['provider']
        env={d.CREDENTIAL_NAMES[provider]:KEY} if environment is None else environment
        return d.run_synthetic(self.root,slot,env,fake or self.fixture(slot))

    def test_allowlist_and_real_disabled_before_credentials(self):
        self.assertEqual(len(d.SLOTS),4)
        for slot in ['arbitrary','../sookmyung','sookmyung-other']:
            with self.assertRaises(d.Invalid): d.verify_frozen(self.root,slot)
        with patch.dict(os.environ,{'ESSAY_PILOT_OPENAI_API_KEY':KEY}):
            with self.assertRaisesRegex(d.Invalid,'REAL_EXECUTION_DISABLED'): d.dispatch('sookmyung-openai')
        self.assertFalse((d.PRIVATE/'round1-started').exists())
        with self.assertRaises(d.Invalid): d.run_synthetic(d.PRIVATE,'sookmyung-openai',{},FakeHTTPS())

    def test_endpoint_provider_and_redirect(self):
        for provider,url in [('other','https://api.openai.com/v1/responses'),
                             ('openai','https://evil.invalid/v1/responses'),
                             ('openai','http://api.openai.com/v1/responses'),
                             ('openai','https://api.openai.com/v1/responses?forward=1')]:
            fake=FakeHTTPS()
            with self.assertRaises(d.Invalid): d.OfficialHTTP(fake).send(provider,url,b'{}',{})
            self.assertEqual(fake.calls,[])
        fake=self.fixture(status=307)
        r=self.run_slot(fake=fake)
        self.assertEqual(r['request_outcome'],'REDIRECT_REJECTED');self.assertEqual(len(fake.calls),1)
        self.assertEqual(fake.connections[0][0],'api.openai.com')
        self.assertNotIn('Location',json.dumps(r))

    def test_manifest_prompt_schema_package_context_policy_settings_drift(self):
        names=['manifest.json','policy-regimes.json','transport-plan.json',
               'sookmyung/manifest.json','sookmyung/prompt.txt','sookmyung/schema.json',
               'sookmyung/package.json','sookmyung/validation-context.json','sookmyung/input_1.png',
               'hanyang/input_5.png']
        for name in names:
            p=self.root/name; old=p.read_bytes();p.chmod(0o600);p.write_bytes(old+b' ')
            fake=FakeHTTPS()
            with self.assertRaises(d.Invalid): self.run_slot(fake=fake)
            self.assertEqual(fake.calls,[]);self.assertFalse((self.root/'round1-started').exists())
            p.write_bytes(old);p.chmod(0o400)

    def test_model_override_and_current_prompt_schema_drift(self):
        for name,value in [('PILOT_PROMPT','modified'),('output_schema',lambda:{}),
                           ('policy',lambda _:dict(provider='openai',model='fallback'))]:
            with patch.object(d,name,value):
                with self.assertRaises(d.Invalid): self.run_slot(fake=FakeHTTPS())
        with patch.object(d.OpenAIPilot,'endpoint','https://evil.invalid'):
            with self.assertRaises(d.Invalid): self.run_slot(fake=FakeHTTPS())
        self.assertFalse((self.root/'round1-started').exists())

    def test_credential_sources_and_errors_redacted(self):
        name=d.CREDENTIAL_NAMES['openai']
        for env in [{},{name:''},{name:KEY,name+'_FILE':''},{name:KEY,name+'_FILE':'/missing'},
                    {name+'_FILE':'/private/tmp/'+KEY},{name:KEY+'\n'}]:
            fake=FakeHTTPS()
            with self.assertRaises(d.Invalid) as caught:self.run_slot(fake=fake,environment=env)
            self.assertNotIn(KEY,str(caught.exception));self.assertEqual(fake.calls,[])
        p=self.root/'credential';p.write_text(KEY);p.chmod(0o600)
        self.assertEqual(d.credential('openai',{name+'_FILE':str(p)}),KEY)
        for mode in [0o644,0o440,0o700]:
            p.chmod(mode)
            with self.assertRaises(d.Invalid):d.credential('openai',{name+'_FILE':str(p)})
        p.chmod(0o600);link=self.root/'key-link';link.symlink_to(p)
        with self.assertRaises(d.Invalid):d.credential('openai',{name+'_FILE':str(link)})
        fifo=self.root/'fifo';os.mkfifo(fifo,0o600)
        with self.assertRaises(d.Invalid):d.credential('openai',{name+'_FILE':str(fifo)})

    def test_started_before_send_raw_before_parse_valid_all_four(self):
        original=d.parse_provider
        for slot in d.SLOTS:
            fake=self.fixture(slot)
            def before(slot=slot):
                start=json.loads(d.read_private(self.root/'round1-started'/f'{slot}.json'))
                self.assertEqual(start['state'],'STARTED_CONSUMED_FOR_ROUND1')
            fake.before_send=before
            def parse(raw,claim,slot=slot):
                self.assertTrue((self.root/'round1'/slot/'raw-response.bin').is_file())
                self.assertFalse((self.root/'round1'/slot/'normalized.json').exists())
                return original(raw,claim)
            with patch.object(d,'parse_provider',side_effect=parse):r=self.run_slot(slot,fake)
            self.assertEqual(r['state'],'VALID_UNREVIEWED');self.assertEqual(len(fake.calls),1)
            self.assertEqual(r['human_review'],'NOT_RUN')
        d.build_review(self.root)
        review=(self.root/'round1-owner-review.md').read_text()
        self.assertIn('Original Answer',review);self.assertIn('sentence diagnosis',review)
        self.assertIn('문장 다듬기',review);self.assertNotIn('WINNER',review)
        self.assertIn(d.verify_frozen(self.root,'hanyang-openai')[0]['answer'],review)

    def test_no_retry_even_after_result_directory_deleted(self):
        fake=self.fixture();self.run_slot(fake=fake)
        shutil.rmtree(self.root/'round1'/'sookmyung-openai')
        self.assertEqual(d.slot_state(self.root,'sookmyung-openai'),'UNKNOWN_CONSUMED_FOR_ROUND1')
        with self.assertRaises(d.Invalid):self.run_slot(fake=fake)
        self.assertEqual(len(fake.calls),1)

    def test_concurrent_one_winner(self):
        fakes=[self.fixture(),self.fixture()]
        def run(f):
            try:return self.run_slot(fake=f)['state']
            except (d.Invalid,FileExistsError):return 'DENIED'
        with ThreadPoolExecutor(2) as pool:result=list(pool.map(run,fakes))
        self.assertEqual(sorted(result),['DENIED','VALID_UNREVIEWED'])
        self.assertEqual(sum(len(f.calls) for f in fakes),1)

    def test_malformed_refusal_incomplete_unexpected_model(self):
        variants=[lambda x:x.update(status='incomplete',stop_reason='max_tokens'),
                  lambda x:x.update(status='refusal',stop_reason='refusal'),
                  lambda x:x.update(model='unexpected-model')]
        for slot,mutate in zip(list(d.SLOTS)[:3],variants):
            f=self.fixture(slot,mutate=mutate);r=self.run_slot(slot,f)
            self.assertEqual(r['state'],'FAILED_CONSUMED_FOR_ROUND1');self.assertNotIn(KEY,json.dumps(r))
            self.assertEqual(len(f.calls),1)
            self.assertEqual(r['parser_status'],'REJECTED')
        f=FakeHTTPS(b'{malformed');r=self.run_slot('hanyang-anthropic',f)
        self.assertEqual(r['parser_status'],'REJECTED')
        self.assertEqual((self.root/'round1/hanyang-anthropic/raw-response.bin').read_bytes(),b'{malformed')

    def test_schema_failure_not_repaired(self):
        slot='sookmyung-openai';v=d.verify_frozen(self.root,slot)[0];o=output(v);o['local_reviews']=[]
        f=FakeHTTPS(d.encoded(envelope('openai',json.dumps(o))))
        r=self.run_slot(slot,f);self.assertEqual(r['parser_status'],'REJECTED')
        self.assertEqual(len(f.calls),1);self.assertFalse((self.root/'round1'/slot/'normalized.json').exists())

    def test_timeout_connection_interrupt_unknown(self):
        for slot,error in zip(d.SLOTS,[TimeoutError(KEY),ConnectionResetError(KEY),KeyboardInterrupt(KEY),RuntimeError(KEY)]):
            f=self.fixture(slot,error=error);r=self.run_slot(slot,f)
            self.assertEqual(r['state'],'UNKNOWN_CONSUMED_FOR_ROUND1');self.assertNotIn(KEY,json.dumps(r))
            with self.assertRaises(d.Invalid):self.run_slot(slot,f)
            self.assertEqual(len(f.calls),1)
        d.build_review(self.root)  # Terminal UNKNOWN is still a reviewable frozen outcome.

    def test_http_error_raw_and_usage(self):
        for slot,code in zip(d.SLOTS,[400,429,500,503]):
            f=self.fixture(slot,status=code);r=self.run_slot(slot,f)
            self.assertEqual(r['request_outcome'],'HTTP_ERROR');self.assertEqual(len(f.calls),1)
            self.assertEqual(r['telemetry']['input_tokens'],10)
            self.assertIsNone(r['telemetry']['actual_cost'])

    def test_write_failure_after_send_and_missing_terminal(self):
        original=d.freeze
        def failing(path,data):
            if path.name in ('normalized.json','terminal.json'):raise OSError(KEY)
            return original(path,data)
        f=self.fixture()
        with patch.object(d,'freeze',side_effect=failing):r=self.run_slot(fake=f)
        self.assertFalse(r['terminal_saved']);self.assertEqual(r['state'],'UNKNOWN_CONSUMED_FOR_ROUND1')
        with self.assertRaises(d.Invalid):self.run_slot(fake=f)
        self.assertEqual(len(f.calls),1)
        with self.assertRaises(d.Invalid):d.build_review(self.root)

    def test_permissions_and_gitignore(self):
        r=self.run_slot()
        for folder in [self.root/'round1',self.root/'round1-started',self.root/'round1/sookmyung-openai']:
            self.assertEqual(folder.stat().st_mode & 0o777,0o700)
            for p in folder.iterdir():
                if p.is_file(): self.assertEqual(p.stat().st_mode & 0o777,0o400)
        with patch.object(d.subprocess,'check_output',return_value=b'private-file-tracked'):
            with self.assertRaisesRegex(d.Invalid,'PRIVATE_GIT_EXCLUSION'): d.verify_frozen(self.root,'hanyang-openai')
        p=self.root/'hanyang/package.json';p.chmod(0o644)
        with self.assertRaises(d.Invalid): d.verify_frozen(self.root,'hanyang-openai')

    def test_secret_echo_never_persisted(self):
        f=self.fixture(mutate=lambda x:x.update(secret=KEY));r=self.run_slot(fake=f)
        self.assertEqual(r['request_outcome'],'SECRET_ECHO_WITHHELD')
        for p in (self.root/'round1').rglob('*'):
            if p.is_file():self.assertNotIn(KEY.encode(),p.read_bytes())
        self.assertFalse((self.root/'round1/sookmyung-openai/raw-response.bin').exists())

    def test_escaped_secret_and_oversize(self):
        escaped=''.join('\\u%04x' % ord(c) for c in KEY)
        f=FakeHTTPS((' {"echo":"'+escaped+'"}').encode())
        r=self.run_slot(fake=f)
        self.assertEqual(r['request_outcome'],'SECRET_ECHO_WITHHELD')
        self.assertFalse((self.root/'round1/sookmyung-openai/raw-response.bin').exists())
        f=self.fixture('hanyang-openai');f.data+=b' '*(d.MAX_RESPONSE+1)
        r=self.run_slot('hanyang-openai',f)
        self.assertEqual(r['parser_status'],'REJECTED')
        self.assertTrue(r['raw_capture_truncated']);self.assertEqual(len(f.calls),1)

    def test_duplicate_json_and_invalid_usage(self):
        f=FakeHTTPS(b'{"model":"a","model":"b"}')
        r=self.run_slot(fake=f);self.assertEqual(r['parser_status'],'REJECTED')
        binding=d.policy(d.SLOTS['hanyang-openai'][1])
        u=d.metadata({'usage':{'input_tokens':True,'output_tokens':-1,'total_tokens':2**64}},binding,0)
        for field in ('input_tokens','output_tokens','total_tokens'):self.assertIsNone(u[field])

    def test_usage_no_invented_total_cost(self):
        f=self.fixture('sookmyung-anthropic',mutate=lambda x:x['usage'].update(cache_read_input_tokens=8,cache_creation_input_tokens=2))
        r=self.run_slot('sookmyung-anthropic',f);u=r['telemetry']
        self.assertEqual((u['input_tokens'],u['output_tokens'],u['cache_read_input_tokens'],u['cache_creation_input_tokens']),(10,20,8,2))
        self.assertIsNone(u['total_tokens']);self.assertIsNone(u['actual_cost']);self.assertIsNone(u['currency'])
        f=self.fixture('hanyang-openai',mutate=lambda x:x['usage'].update(input_tokens_details={'cached_tokens':3}))
        r=self.run_slot('hanyang-openai',f);self.assertEqual(r['telemetry']['cached_input_tokens'],3)

    def test_contract_parity_in_actual_request_paths(self):
        a=self.fixture();b=self.fixture('sookmyung-anthropic')
        self.run_slot(fake=a);self.run_slot('sookmyung-anthropic',b)
        x=json.loads(a.calls[0][2]);y=json.loads(b.calls[0][2])
        self.assertEqual(x['instructions'],y['system'])
        self.assertEqual(x['text']['format']['schema'],y['output_config']['format']['schema'])
        self.assertEqual(x['input'][0]['content'][0]['text'],y['messages'][0]['content'][0]['text'])
        self.assertEqual([i['image_url'].split(',',1)[1] for i in x['input'][0]['content'][1:]],
                         [i['source']['data'] for i in y['messages'][0]['content'][1:]])
        self.assertIs(x['store'],False);self.assertNotIn('tools',x);self.assertNotIn('tools',y)

    def test_single_http_object_not_reusable(self):
        fake=FakeHTTPS();http=d.OfficialHTTP(fake)
        http.send('openai','https://api.openai.com/v1/responses',b'{}',{})
        with self.assertRaises(d.Invalid):http.send('openai','https://api.openai.com/v1/responses',b'{}',{})
        self.assertEqual(len(fake.calls),1)

if __name__=='__main__':unittest.main()
