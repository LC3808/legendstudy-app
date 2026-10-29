"""Local transport parity only; no real Provider or operating Credit."""
import unittest
from unittest.mock import patch
from tool import test_essay_reviewed_runtime as fixtures
from tool.essay_lab.live_worker import Unknown

class AsyncTests(unittest.IsolatedAsyncioTestCase):
 @patch('tool.essay_lab.live_worker.time.monotonic', return_value=100.0)
 async def test_existing_worker_success_failure_timeout_parity(self, _clock):
  for mode in ('ok','invalid','timeout','lost_finalize'):
   sync,sc,sr,ss,*_=fixtures.RuntimeTests().fixture(mode)
   async_worker,ac,ar,ass,*_=fixtures.RuntimeTests().fixture(mode)
   def wrap(fn):
    async def call(*args,**kwargs):return fn(*args,**kwargs)
    return call
   for name in ('rpc','receipt_sink','review_source','checkpoint'):
    setattr(async_worker,name,wrap(getattr(async_worker,name)))
   async_worker.provider.transport=wrap(async_worker.provider.transport)
   async_worker.provider.evaluate=async_worker.provider.evaluate_async
   if mode=='lost_finalize':
    with self.assertRaises(Unknown):sync.execute('evaluation')
    with self.assertRaises(Unknown):await async_worker.execute_async('evaluation')
   else:self.assertEqual(sync.execute('evaluation'),await async_worker.execute_async('evaluation'))
   self.assertEqual(sc,ac);self.assertEqual(sr,ar);self.assertEqual(ss,ass)

if __name__=='__main__':unittest.main()
