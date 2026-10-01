import json, unittest, urllib.error, base64
from verify_human_quality_gateway import allowed, verify, EMPTY_ID, HOST
from verify_quality_gateway import NoRedirect
class Tests(unittest.TestCase):
 def test_no_operator_write(self):
  for role in ('ADMIN','FORGED'):
   self.assertFalse(allowed(role,'/rest/v1/rpc/ql_submit_human_judgment',{'p_payload':{}},'POST'))
 def test_no_valid_submission(self):
  for role in ('STUDENT','ANON'):
   self.assertFalse(allowed(role,'/rest/v1/rpc/ql_submit_human_judgment',{'p_payload':{'evaluation_id':EMPTY_ID}},'POST'))
 def test_no_rest_writes_or_answer_reads(self):
  for method in ('POST','PATCH','DELETE'):
   self.assertFalse(allowed('ADMIN','/rest/v1/human_quality_judgments?select=id&limit=0',None,method))
  self.assertFalse(allowed('ADMIN','/rest/v1/rpc/ql_case_detail',{'p_evaluation_id':'other'},'POST'))
 def test_bounded_inputs(self):
  self.assertTrue(allowed('ADMIN','/rest/v1/rpc/ql_review_state',{'p_evaluation_ids':[]},'POST'))
  self.assertFalse(allowed('ADMIN','/rest/v1/rpc/ql_review_state',{'p_evaluation_ids':[EMPTY_ID]},'POST'))
 def test_redirect(self):self.assertIsNone(NoRedirect().redirect_request(None,None,302,'',{},'https://example.invalid'))
 def test_full_sanitized_simulation(self):
  import io
  credentials={f'QUALITY_{role}_{kind}':role+kind for role in ('ADMIN','STUDENT') for kind in ('EMAIL','PASSWORD')}
  class Response:
   def __init__(self,body):self.status=200;self.body=body
   def __enter__(self):return self
   def __exit__(self,*args):pass
   def read(self):return json.dumps(self.body).encode()
  class Opener:
   def open(self,req,timeout):
    path=req.full_url[len(HOST):];data=json.loads(req.data) if req.data else None;token=req.headers.get('Authorization','').removeprefix('Bearer ')
    role='ANON'
    if token:
     claims=json.loads(base64.urlsafe_b64decode(token.split('.')[1]+'==='));role=claims['sub']
     if token.split('.')[2]!=role:raise urllib.error.HTTPError(req.full_url,401,'',{},io.BytesIO(b'{}'))
    if path.startswith('/auth/v1/token'):
     role=data['email'].removesuffix('EMAIL');token='x.'+base64.urlsafe_b64encode(json.dumps({'sub':role,'role':'authenticated'}).encode()).decode().rstrip('=')+'.'+role
     return Response({'access_token':token})
    if path=='/auth/v1/user':return Response({'id':role,'email':role+'EMAIL'})
    if path.endswith('is_quality_operator'):return Response(role=='ADMIN')
    if path.endswith('ql_review_state') and role=='ADMIN':return Response({'dto_version':'hq-read-v1','cases':[]})
    if path.endswith('ql_list_cases') and role=='ADMIN':return Response({'dto_version':'ql-read-v1','cases':[]})
    code=500 if role=='ADMIN' and path.endswith('ql_list_human_judgments') else (401 if role=='ANON' else 403)
    err='P0002' if code==500 else '42501'
    raise urllib.error.HTTPError(req.full_url,code,'',{},io.BytesIO(json.dumps({'code':err,'message':'PRIVATE_RESPONSE_SENTINEL'}).encode()))
  result=verify({'SUPABASE_URL':HOST,'SUPABASE_PUBLISHABLE_KEY':'sb_publishable_synthetic'},credentials,Opener())
  serialized=json.dumps(result)
  self.assertEqual(result['PRODUCTION_HQP_AUTHORIZATION'],'PASS')
  for secret in [*credentials.values(),'PRIVATE_RESPONSE_SENTINEL','access_token']:
   self.assertNotIn(secret,serialized)
if __name__=='__main__':unittest.main()
