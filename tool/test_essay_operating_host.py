"""Transport-boundary tests, no real Auth, Provider or Credit calls."""
import base64,json,time,unittest
from urllib.error import HTTPError
from tool.essay_lab.operating_host import OperatingTransport,ORIGIN
from tool.essay_lab.live_worker import Invalid,Unknown

SUBJECT='00000000-0000-4000-8000-000000000001'
def fixture(role='essay_worker'):
    encode=lambda v:base64.urlsafe_b64encode(json.dumps(v).encode()).decode().rstrip('=')
    return encode({'alg':'HS256'})+'.'+encode({'role':role,'exp':int(time.time())+600})+'.fixture'
class Response:
    status=200
    def __init__(self,value):self.value=value
    def __enter__(self):return self
    def __exit__(self,*_):pass
    def read(self,_):return json.dumps(self.value).encode()
class Tests(unittest.TestCase):
    def transport(self,opener,**kwargs):
        return OperatingTransport(origin=ORIGIN,publishable_key='sb_publishable_fixture',worker_jwt=fixture(),allowed_subjects=[SUBJECT],open_url=opener,**kwargs)
    def test_online_identity_and_worker_credentials_are_separate(self):
        calls=[]
        def open_url(req,timeout):
            calls.append(req)
            return Response({'id':SUBJECT} if req.full_url.endswith('/user') else [])
        t=self.transport(open_url)
        self.assertEqual(t.subject('student-fixture'),SUBJECT)
        t.rpc('essay_registered_questions',{'p_subject':SUBJECT})
        self.assertEqual(calls[0].get_header('Authorization'),'Bearer student-fixture')
        self.assertEqual(calls[1].get_header('Authorization'),'Bearer '+t.worker)
        self.assertEqual(calls[1].full_url,ORIGIN+'/rest/v1/rpc/essay_registered_questions')
    def test_denied_identity_and_arbitrary_rpc(self):
        t=self.transport(lambda *a,**k:Response({'id':'foreign'}))
        with self.assertRaises(Invalid):t.subject('student')
        with self.assertRaises(Invalid):t.rpc('essay_admin_grant',{})
    def test_unknown_mutation_is_never_retried_or_logged(self):
        calls=[]
        def fail(req,timeout):
            calls.append(req);raise HTTPError(req.full_url,503,'private response',None,None)
        t=self.transport(fail)
        with self.assertRaisesRegex(Unknown,'^BACKEND_UNAVAILABLE$'):t.rpc('essay_exam_finish',{})
        self.assertEqual(len(calls),1)
    def test_reject_api_key_or_user_role_as_worker(self):
        for credential in ['sb_secret_fixture',fixture('authenticated'),fixture('service_role')]:
            with self.assertRaises(Invalid):
                OperatingTransport(origin=ORIGIN,publishable_key='sb_publishable_fixture',worker_jwt=credential,allowed_subjects=[SUBJECT])

if __name__=='__main__':unittest.main()
