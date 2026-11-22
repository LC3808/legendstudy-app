"""Full captured entry + real transport constructor/handler, synthetic IO only.
Run: python -m tool.cloudflare_essay.test_recovery_entry_runtime CANDIDATE
"""
import asyncio,base64,contextlib,importlib.util,io,json,sys,time,types,unittest
from pathlib import Path
from urllib.error import HTTPError
from unittest.mock import patch
from tool.test_essay_admin_recovery import recovery_fixture,RUN,KEY,OWNER,EXAM
RUNTIME=Path(sys.argv.pop(1)).resolve()
sys.path.insert(0,str(RUNTIME))
class Response:
 @staticmethod
 def json(value,**kw):return dict(body=value,**kw)
sys.modules['workers']=types.SimpleNamespace(WorkerEntrypoint=object,Response=Response,Request=object)
spec=importlib.util.spec_from_file_location('captured_entry',RUNTIME/'entry.py');entry=importlib.util.module_from_spec(spec);spec.loader.exec_module(entry)
import essay_lab.cloudflare_http as http

def encoded(v):return base64.urlsafe_b64encode(json.dumps(v).encode()).decode().rstrip('=')
class Request:
 method='POST'
 def __init__(self,path,payload,token='admin',service='s'*32):self.url='https://essay-worker.internal/'+path;self.payload=payload;self.headers={'X-Essay-Service-Token':service,'Authorization':'Bearer '+token}
 async def text(self):return json.dumps(self.payload)
class Tests(unittest.IsolatedAsyncioTestCase):
 def setup_case(self):
  self.events=[];self.queued=[];self.context,self.material,self.registry,_=recovery_fixture(final=False)
  self.context['operation']='verify_then_retry';self.context['uncertain_question_ids']=[self.context['claimed']['snapshot']['answers'][1]['questionId']]
  rows=self.context['checkpoints']; q1=rows['q1']['payload'];q1.update(state='reconciling',output=None)
  for k in list(rows):
   if k.startswith('q1') and k!='q1':del rows[k]
  binding=self.context['claimed']['snapshot']['runtime']['binding']
  self.w=entry.Default();self.w.env=types.SimpleNamespace(ESSAY_WORKER_SERVICE_TOKEN='s'*32,ESSAY_EXECUTION_ENABLED='true',SUPABASE_PUBLISHABLE_KEY='sb_publishable_fixture',ESSAY_REGISTRY_WORKER_JWT=encoded({'alg':'ES256'})+'.'+encoded({'role':'essay_worker','exp':int(time.time())+3600})+'.fixture',ESSAY_ALLOWED_SUBJECTS=json.dumps([OWNER]),ESSAY_PUBLIC_EXAMS=json.dumps([EXAM]),ESSAY_PROVIDER_BINDING=json.dumps(binding),ESSAY_PROVIDER_KEY='fixture-key',ESSAY_REVIEW_MODE='independent_model',ESSAY_REVIEW_BINDING=json.dumps(dict(reviewer_id='fixture',model='fixture',model_version='fixture')),ESSAY_REVIEW_VERIFY_KEYS=json.dumps({'fixture':'s'*32}),ESSAY_QUEUE=types.SimpleNamespace(send=self.enqueue))
  self.fault=None
 async def enqueue(self,value):self.queued.append(json.loads(value))
 def action(self,operation):
  state,dispatch,success={'verify_then_retry':('verification_required',False,False),'retry':('queued',True,False)}[operation]
  return dict(version='admin-run-recovery-v1',run_id=RUN,subject_id=OWNER,exam_id=EXAM,action='recover',action_id=KEY,recovery_type='E',reason=None,operation=operation,state=state,dispatch_required=dispatch,success=success,**({'generation':1} if dispatch else {}))
 async def fetch(self,url,headers,body=None,**kwargs):
  name=url.rsplit('/',1)[-1];self.events.append(name);args=json.loads(body or '{}')
  if headers['Authorization']=='Bearer student':raise HTTPError(url,403,'HTTP_FAILURE',None,io.BytesIO(b'{"message":"ADMIN_REQUIRED"}'))
  if name==self.fault:raise RuntimeError('sensitive exception must not escape')
  if name=='admin_lab_run_recovery':return json.dumps(dict(version='admin-run-recovery-v1',run_id=RUN,subject_id=OWNER,exam_id=EXAM,hidden=False,recovery={'allowed':False})).encode()
  if name=='admin_lab_recover_run':
   if self.fault=='active':raise HTTPError(url,409,'HTTP_FAILURE',None,io.BytesIO(b'{"message":"ACTIVE_LEASE"}'))
   self.assertTrue(args['p_allow_uncertain']);return json.dumps(self.action('verify_then_retry')).encode()
  if name=='essay_exam_session_ready':return b'"exam-session-v1"'
  if name=='essay_exam_preflight':return json.dumps(self.context['claimed']['snapshot']['runtime']).encode()
  if name=='essay_material_runtime_package':return json.dumps(self.material).encode()
  if name=='essay_exam_recovery_quality_ready':return b'"quality-repair-2-1-v1"'
  if name=='essay_exam_recovery_context':return json.dumps(self.context).encode()
  if name=='essay_exam_recovery_finish':
   self.assertNotIn('failure_code',args['p_proof']);return json.dumps(self.action('retry')).encode()
  raise AssertionError('Unexpected network '+name)
 async def invoke(self,check=False,token='admin',service='s'*32):
  log=io.StringIO();payload={'run_id':RUN} if check else dict(run_id=RUN,key=KEY,diagnosis_token='a'*64,allow_uncertain=True)
  with patch.object(entry,'REGISTRY',self.registry),patch.object(entry,'fetch_bytes',self.fetch),patch.object(http,'fetch_bytes',self.fetch),contextlib.redirect_stdout(log):
   result=await self.w.fetch(Request('admin-exam-recovery-check' if check else 'admin-exam-recover',payload,token,service))
  self.last_log=log.getvalue();self.assertNotIn('sensitive',self.last_log);return result
 async def test_real_constructor_has_validated_origin(self):
  self.setup_case();self.assertEqual(self.w.transport().origin,http.ORIGIN)
 async def test_recovery_reaches_real_validation_and_queue(self):
  self.setup_case();r=await self.invoke();self.assertEqual(r['body'].get('state'),'queued',r);self.assertEqual(len(self.queued),1);self.assertIn('essay_exam_recovery_finish',self.events)
 async def test_readonly_check_initializes_real_runtime_without_mutation_or_provider(self):
  self.setup_case();r=await self.invoke(check=True);self.assertTrue(r['body'].get('ready'),r);self.assertEqual(self.events,['admin_lab_run_recovery','essay_exam_session_ready','essay_exam_preflight','essay_material_runtime_package','essay_exam_recovery_quality_ready']);self.assertFalse(self.queued)
 async def test_student_denied_before_runtime_and_mutations(self):
  self.setup_case();r=await self.invoke(check=True,token='student');self.assertEqual(r['status'],403);self.assertEqual(self.events,['admin_lab_run_recovery']);self.assertFalse(self.queued)
 async def test_normal_active_run_blocked(self):
  self.setup_case();self.fault='active';r=await self.invoke();self.assertEqual(r['body']['code'],'ACTIVE_LEASE');self.assertFalse(self.queued)
 async def test_missing_runtime_binding_classified(self):
  self.setup_case();del self.w.env.ESSAY_PROVIDER_KEY;r=await self.invoke(check=True);self.assertEqual(r['body']['code'],'RECOVERY_RUNTIME_INIT_FAILED');self.assertFalse(self.queued)
 async def test_unknown_read_and_mutation_are_distinct(self):
  for fault,code in [('admin_lab_run_recovery','ADMIN_RPC_UNAVAILABLE'),('admin_lab_recover_run','RECOVERY_RESPONSE_UNCERTAIN'),('essay_exam_recovery_finish','RECOVERY_RESPONSE_UNCERTAIN')]:
   self.setup_case();self.fault=fault;r=await self.invoke();self.assertEqual(r['body']['code'],code,r);self.assertFalse(self.queued)
 async def test_wrong_service_secret_never_reaches_rpc(self):
  self.setup_case();await self.invoke(service='wrong');self.assertEqual(self.events,[])
class ErrorBodyTests(unittest.IsolatedAsyncioTestCase):
 async def test_rpc_error_body_bounded_and_default_provider_body_discarded(self):
  for body,limit,expected in [(b'{"message":"ACTIVE_LEASE"}',4096,b'{"message":"ACTIVE_LEASE"}'),(b'x'*4097,4096,b''),(b'private',0,b'')]:
   events=[];chunks=[body]
   class Reader:
    async def read(self):
     if chunks:return types.SimpleNamespace(done=False,value=types.SimpleNamespace(to_py=lambda:chunks.pop(0)))
     return types.SimpleNamespace(done=True)
    async def cancel(self):events.append('cancel')
   async def fetch(*a,**kw):return types.SimpleNamespace(status=409,js_response=types.SimpleNamespace(body=types.SimpleNamespace(getReader=lambda:Reader())))
   controller=types.SimpleNamespace(signal=types.SimpleNamespace(aborted=False),abort=types.SimpleNamespace(bind=lambda _:lambda:None))
   js=types.SimpleNamespace(AbortController=types.SimpleNamespace(new=lambda:controller),setTimeout=lambda *a:1,clearTimeout=lambda _:None)
   with patch.dict(sys.modules,{'workers':types.SimpleNamespace(fetch=fetch),'js':js}):
    with self.assertRaises(HTTPError) as caught:await http.fetch_bytes('https://fixture.invalid',{},error_limit=limit)
   self.assertEqual(caught.exception.read(),expected)
   if len(body)>4096:self.assertEqual(events,['cancel'])

if __name__=='__main__':
 if '--reproduce-origin-bug' in sys.argv:
  t=Tests();t.setup_case();r=asyncio.run(t.invoke());assert not hasattr(t.w.transport(),'origin') and r['body']['code']=='RUNTIME_UNAVAILABLE' and t.events==[] and 'AttributeError' in t.last_log
  print(json.dumps(dict(response=r,rpc_calls=0,log=t.last_log.strip(),origin_present=False)))
 else:unittest.main()
