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
 def test_probe_acks_without_runtime(self):
  self.assertEqual(self.run_queue('false',{'kind':'connection_probe','probe_id':'00000000-0000-4000-8000-000000000001'}),['ack'])
 def test_live_mode_and_extra_payload_rejected(self):
  p={'kind':'connection_probe','probe_id':'00000000-0000-4000-8000-000000000001'}
  self.assertEqual(self.run_queue('true',p),['retry'])
  self.assertEqual(self.run_queue('false',{**p,'run_id':'not-used'}),['retry'])
if __name__=='__main__':unittest.main()
