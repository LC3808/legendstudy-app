"""Fault injection only: no live Provider, deployment or operating data."""
import unittest
from urllib.error import HTTPError
from tool import test_essay_reviewed_runtime as fixtures
from tool.essay_lab.live_worker import Invalid, execution_failure
from tool.essay_lab.cloudflare_runtime import receipt_checkpoint_key

class FailureObservationTests(unittest.TestCase):
    def test_input_failure_has_no_provider_call_and_preserves_existing_failure_path(self):
        worker,calls,requests,saved,*_=fixtures.RuntimeTests().fixture()
        receipts=[];worker.receipt_sink=receipts.append
        def invalid(_):raise Invalid('ANSWER_HASH')
        worker.prepare_input=invalid
        self.assertEqual(worker.execute('evaluation'),'failed')
        self.assertEqual(requests,[]);self.assertEqual(saved,[])
        self.assertEqual(receipts,[execution_failure(Invalid('ANSWER_HASH'),'input')])
        self.assertEqual(receipts[0]['provider_call'],'not_started')
        self.assertEqual(calls[-1][0],'essay_finalize_failure')
        self.assertEqual(receipt_checkpoint_key(receipts[0]),'execution-failure')

    def test_provider_http_metadata_without_error_body_or_automatic_retry(self):
        for status in (400,429):
            worker,calls,requests,saved,*_=fixtures.RuntimeTests().fixture()
            receipts=[];worker.receipt_sink=receipts.append;network=[]
            def rejected(req,timeout):
                network.append(1)
                raise HTTPError('https://private.invalid',status,'PRIVATE BODY',{},None)
            worker.provider.transport=rejected
            self.assertEqual(worker.execute('evaluation'),'failed')
            self.assertEqual(len(network),1);self.assertFalse(saved)
            self.assertEqual(receipts[0]['http_status'],status)
            self.assertEqual(receipts[0]['code'],'PROVIDER_REJECTED')
            self.assertEqual(receipts[0]['provider_call'],'possible')
            self.assertNotIn('PRIVATE',str(receipts));self.assertNotIn('private.invalid',str(receipts))

    def test_unknown_keeps_reservation_and_diagnostic_does_not_dispatch_again(self):
        worker,calls,requests,saved,*_=fixtures.RuntimeTests().fixture('timeout')
        receipts=[];worker.receipt_sink=receipts.append
        self.assertEqual(worker.execute('evaluation'),'reconciling')
        self.assertEqual(len(requests),1);self.assertFalse(saved)
        self.assertEqual(calls[-1][0],'essay_timeout')
        self.assertEqual(receipts[0]['stage'],'provider')
        self.assertEqual(receipts[0]['code'],'PROVIDER_NETWORK_UNKNOWN')

    def test_non_symbolic_error_is_redacted_and_extra_fields_rejected(self):
        value=execution_failure(Invalid('student answer / bearer secret'),'input')
        self.assertEqual(value['code'],'UNCLASSIFIED_FAILURE')
        self.assertEqual(receipt_checkpoint_key(value),'execution-failure')
        with self.assertRaises(Invalid):receipt_checkpoint_key(dict(value,answer='private'))

    def test_failed_audit_leaves_unknown_intent_instead_of_hiding_it(self):
        worker,calls,requests,saved,*_=fixtures.RuntimeTests().fixture('timeout')
        def lost(_):raise TimeoutError('synthetic audit unavailable')
        worker.receipt_sink=lost
        with self.assertRaises(TimeoutError):worker.execute('evaluation')
        self.assertEqual(len(requests),1)
        self.assertFalse(any(name=='essay_finalize_failure' for name,_ in calls))
