"""Boundary checks on actual entry methods, without Cloudflare or any network."""
import ast,asyncio,json,unittest
from pathlib import Path
from types import SimpleNamespace
from uuid import UUID

class ProbeTests(unittest.TestCase):
 def run_queue(self,enabled,body):
  tree=ast.parse(Path(__file__).with_name('entry.py').read_text())
  cls=next(n for n in tree.body if isinstance(n,ast.ClassDef))
  queue=next(n for n in cls.body if isinstance(n,ast.AsyncFunctionDef) and n.name=='queue')
  ns={'json':json,'UUID':UUID,'require':lambda ok,code: None if ok else (_ for _ in ()).throw(ValueError(code)),'print':lambda *args:None}
  exec(compile(ast.Module(body=[queue],type_ignores=[]),'queue','exec'),ns)
  events=[]
  def forbidden():events.append('runtime');raise AssertionError('runtime must not run')
  owner=SimpleNamespace(env=SimpleNamespace(ESSAY_EXECUTION_ENABLED=enabled),transport=forbidden)
  message=SimpleNamespace(body=json.dumps(body),ack=lambda:events.append('ack'),retry=lambda:events.append('retry'))
  asyncio.run(ns['queue'](owner,SimpleNamespace(messages=[message])))
  return events
 def test_admission_reads_without_dispatch(self):
  import time
  from tool.essay_lab.live_worker import require,digest
  tree=ast.parse(Path(__file__).with_name('entry.py').read_text())
  method=next(n for n in next(n for n in tree.body if isinstance(n,ast.ClassDef)).body if isinstance(n,ast.AsyncFunctionDef) and n.name=='admission')
  calls=[];authorized=[]
  async def rpc(name,args):
   calls.append(name)
   if name=='essay_exam_preflight':return {'package_digest':'hash','binding':{'model':'test'},'regime':'test','evaluation_type':'humanities'}
   if name=='essay_material_runtime_package':return {'package_version':17}
   raise AssertionError('write RPC forbidden')
  class Worker:
   def __init__(self,*a,**kw):pass
   def authorize(self,x):authorized.append(x)
  def forbidden(*a,**kw):raise AssertionError('Provider/dispatch forbidden')
  key=b'fixture-key'
  runtime=SimpleNamespace(provider=forbidden,reviewer=SimpleNamespace(keys={'review':key}),review_source=SimpleNamespace(key=key,reviewer_id='review'),receipt_sink=forbidden)
  ns={'load_reviewed_material':lambda *a,**kw:({'q':SimpleNamespace(frozen_cache={})},{'ready':True}),'REGISTRY':{},'ReviewedRuntimeWorker':Worker,'RuntimePermit':lambda *a:None,'digest':digest,'time':time,'require':require}
  exec(compile(ast.Module(body=[method],type_ignores=[]),'admission','exec'),ns)
  owner=SimpleNamespace(env=SimpleNamespace(ESSAY_REVIEW_MODE='independent_model'),configuration=lambda _, binding: runtime if binding=={'model':'test'} else forbidden())
  result=asyncio.run(ns['admission'](owner,SimpleNamespace(rpc=rpc),'subject','exam'))
  self.assertEqual(calls,['essay_exam_preflight','essay_material_runtime_package']);self.assertEqual(authorized,['preflight'])
  self.assertTrue(result['ready']);self.assertFalse(result['provider_called'])
 def test_probe_acks_without_runtime(self):
  self.assertEqual(self.run_queue('false',{'kind':'connection_probe','probe_id':'00000000-0000-4000-8000-000000000001'}),['ack'])
 def test_live_mode_and_extra_payload_rejected(self):
  p={'kind':'connection_probe','probe_id':'00000000-0000-4000-8000-000000000001'}
  self.assertEqual(self.run_queue('true',p),['retry'])
  self.assertEqual(self.run_queue('false',{**p,'run_id':'not-used'}),['retry'])
if __name__=='__main__':unittest.main()
