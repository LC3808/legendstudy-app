"""Synthetic-only L2-C3 transport/lifecycle and unchanged-input regression."""
import copy
import json
from pathlib import Path
import tempfile
import time
import unittest
from unittest.mock import patch
from tool.essay_lab import hanyang_recovery as r
from tool.test_essay_live_worker import fixture
from tool.test_vnext_validation import envelope,KEY

class Factory:
    synthetic_only=True
    def __init__(self,chunks=(),error_at=None,error=None,status=200,delay=0):
        self.chunks=list(chunks);self.error_at=error_at;self.error=error or TimeoutError(KEY);self.status=status;self.delay=delay;self.calls=0;self.closed=False
    def __call__(self,host,**kw):
        self.host,self.kw=host,kw;f=self
        class Connection:
            def request(self,method,path,**kw):
                f.calls+=1;f.method,f.path=method,path
                if f.error_at=='write':raise f.error
            def getresponse(self):
                if f.delay:time.sleep(f.delay)
                if f.error_at=='headers':raise f.error
                class Response:
                    status=f.status
                    def read1(self,n):
                        if f.chunks:return f.chunks.pop(0)
                        if f.error_at=='read':raise f.error
                        return b''
                return Response()
            def close(self):f.closed=True
        return Connection()


def prepared():
    c,_,o=fixture();c['input']['attempt_id']=r.SLOT;o['attempt_id']=r.SLOT
    p={'model':'gpt-5.6-sol'};b=dict(slot=r.SLOT,policy=r.POLICY,payload_hash=r.old.digest(p),claim_hash=r.old.digest(c))
    return ({},c,p,b),o

class Recovery(unittest.TestCase):
    def setUp(self):
        t=tempfile.TemporaryDirectory(prefix='essay-l2c3-test',dir='/private/tmp');self.addCleanup(t.cleanup);self.root=Path(t.name);self.p,self.o=prepared()
        for name in ('socket.create_connection','http.client.HTTPSConnection'):
            p=patch(name,side_effect=AssertionError('NETWORK_PROHIBITED'));p.start();self.addCleanup(p.stop)
    def run_fake(self,f):return r.run(self.root,self.p,KEY,r.DiagnosticHTTP(factory=f),synthetic=True)
    def test_success_raw_before_parse_marker_before_send(self):
        f=Factory([envelope(self.o)]);parse=r.old.parse_provider
        def checked(raw,c):
            self.assertTrue((self.root/'started'/f'{r.SLOT}.json').exists())
            self.assertTrue((self.root/'results'/r.SLOT/'raw-response.bin').exists());return parse(raw,c)
        with patch.object(r.old,'parse_provider',side_effect=checked):out=self.run_fake(f)
        self.assertEqual(out['parser'],'PASS');self.assertTrue(out['transport']['request_write_returned']);self.assertTrue(out['transport']['headers_received'])
        self.assertEqual(f.calls,1);self.assertEqual(f.host,'api.openai.com');self.assertEqual(f.path,'/v1/responses');self.assertTrue(f.closed)
    def test_consumed_cannot_repeat(self):
        f=Factory([envelope(self.o)]);self.run_fake(f)
        with self.assertRaises(r.Invalid):self.run_fake(f)
        self.assertEqual(f.calls,1)
    def test_invalid_root_consumed_without_repair(self):
        self.o['sentence_feedback'][0]['linked_issue_key']='missing';out=self.run_fake(Factory([envelope(self.o)]))
        self.assertEqual(out['validation_error'],'SENTENCE_ROOT');self.assertFalse((self.root/'results'/r.SLOT/'normalized.json').exists())
    def test_wait_headers_timeout(self):
        out=self.run_fake(Factory(error_at='headers'))
        self.assertEqual(out['state'],'UNKNOWN_CONSUMED');self.assertEqual(out['transport']['stage'],'WAIT_HEADERS')
        self.assertTrue(out['transport']['request_write_returned']);self.assertFalse(out['transport']['headers_received']);self.assertIsNone(out['http_status'])
    def test_write_timeout_not_proof_request_sent(self):
        out=self.run_fake(Factory(error_at='write'));self.assertFalse(out['transport']['request_write_returned'])
        self.assertEqual(out['transport']['stage'],'CONNECT_OR_WRITE')
    def test_read_timeout_preserves_headers_partial(self):
        out=self.run_fake(Factory([b'{"partial":'],error_at='read'))
        self.assertEqual(out['state'],'UNKNOWN_CONSUMED');self.assertEqual(out['http_status'],200)
        self.assertEqual(out['transport']['stage'],'READ_BODY');self.assertEqual(out['transport']['bytes_received'],11)
        self.assertEqual((self.root/'results'/r.SLOT/'raw-partial.bin').read_bytes(),b'{"partial":')
        self.assertFalse((self.root/'results'/r.SLOT/'normalized.json').exists())
    def test_partial_secret_withheld(self):
        out=self.run_fake(Factory([KEY.encode()],error_at='read'));self.assertEqual(out['request_outcome'],'SECRET_ECHO_WITHHELD')
        for p in self.root.rglob('*'):
            if p.is_file():self.assertNotIn(KEY.encode(),p.read_bytes())
    def test_complete_secret_withheld(self):
        out=self.run_fake(Factory([r.old.encoded({'echo':KEY})]));self.assertEqual(out['request_outcome'],'SECRET_ECHO_WITHHELD')
        self.assertFalse((self.root/'results'/r.SLOT/'raw-response.bin').exists())
    def test_total_deadline_is_bounded_and_cancels_timer(self):
        import signal
        with patch.object(r,'TIMEOUT',0.02):out=self.run_fake(Factory(delay=0.1))
        self.assertEqual(out['transport']['exception_category'],'TOTAL_DEADLINE');self.assertEqual(signal.getitimer(signal.ITIMER_REAL),(0.0,0.0))
    def test_http_error_no_retry(self):
        f=Factory([b'{}'],status=429);out=self.run_fake(f);self.assertEqual(out['request_outcome'],'HTTP_ERROR');self.assertEqual(f.calls,1)
    def test_model_substitution(self):
        data=json.loads(envelope(self.o));data['model']='wrong';out=self.run_fake(Factory([r.old.encoded(data)]));self.assertEqual(out['request_outcome'],'MODEL_MISMATCH')
    def test_error_messages_never_persist(self):
        self.run_fake(Factory(error_at='headers',error=OSError(KEY)))
        for p in self.root.rglob('*'):
            if p.is_file():self.assertNotIn(KEY.encode(),p.read_bytes())
    def test_marker_alone_consumes(self):
        d=r.old.child_dir(self.root,'started');r.old.freeze(d/f'{r.SLOT}.json',b'{}');f=Factory()
        with self.assertRaises(r.Invalid):self.run_fake(f)
        self.assertEqual(f.calls,0)
    def test_bad_binding_before_started(self):
        self.p[2]['model']='other'
        with self.assertRaises(r.Invalid):self.run_fake(Factory())
        self.assertFalse((self.root/'started').exists())
    def test_no_live_or_strong_answer_entry(self):
        with self.assertRaises(r.Invalid):r.dispatch()
        self.assertEqual(r.SLOT,'hanyang-openai-vnext-l2c3-1');self.assertEqual(r.EXECUTION_AUTHORIZATION,None)
    def test_unknown_fields_and_quote_remain_rejected(self):
        self.o['local_reviews']=[];out=self.run_fake(Factory([envelope(self.o)]));self.assertEqual(out['parser'],'REJECTED')

@unittest.skipUnless(r.old.PACKAGES.is_dir(),'private C1 assets unavailable')
class InputParity(unittest.TestCase):
    def test_only_attempt_identity_changes_request(self):
        previous=r.old.assemble(r.OLD_SLOT);new=r.assemble()
        old_value=copy.deepcopy(previous[0]);old_value['attempt_id']=r.SLOT
        self.assertEqual(new[0],old_value)
        old_payload=copy.deepcopy(previous[2]);old_payload['input'][0]['content'][0]['text']=r.old.encoded(old_value).decode()
        self.assertEqual(new[2],old_payload)
        for key in ('answer_hash','package_hash','catalog_hash','prompt_hash','schema_hash','ordered_image_hashes'):
            self.assertEqual(new[3][key],previous[3][key])
        self.assertEqual(r.TIMEOUT,600);self.assertEqual(new[2]['reasoning'],{'effort':'high'});self.assertEqual(new[2]['max_output_tokens'],12000)
    def test_production_timeout_not_changed(self):
        import inspect
        from tool.essay_lab.live_worker import OpenAIResponses
        self.assertIn('timeout=75',str(inspect.signature(OpenAIResponses)))

if __name__=='__main__':unittest.main()
