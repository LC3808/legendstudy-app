import base64
import hashlib
import hmac
import io
import json
import unittest
from urllib.error import HTTPError

from tool.cloudflare_essay.issue_worker_jwt import mint, verify, verify_math

CONFIG = {'vars': {'SUPABASE_PUBLISHABLE_KEY':'sb_publishable_fixture',
                   'ESSAY_ALLOWED_SUBJECTS':'["fixture-subject"]'}}

class Response(io.BytesIO):
    status = 200

class Probe:
    def __init__(self, responses):
        self.responses = iter(responses)
        self.requests = []
    def open(self, request, timeout):
        self.requests.append(request)
        status, body = next(self.responses)
        if status != 200:
            raise HTTPError(request.full_url,status,'fixture',{},io.BytesIO(json.dumps(body).encode()))
        return Response(json.dumps(body).encode())

class ExistingJwtContractTest(unittest.TestCase):
    def test_exact_claims_and_signature(self):
        secret='synthetic-signing-fixture-not-production-12345'
        for role, days in [('essay_worker',365),('math_evaluation_worker',7),('math_extraction_worker',7)]:
            token, expiry=mint(secret,1700000000,role)
            head, body, signature=token.split(b'.')
            decode=lambda v:json.loads(base64.urlsafe_b64decode(v+b'='*((-len(v))%4)))
            self.assertEqual(decode(head),{'alg':'HS256','typ':'JWT'})
            expected={'role':role,'iat':1700000000,'exp':1700000000+days*86400}
            if role!='essay_worker': expected['iss']='supabase'
            self.assertEqual(decode(body),expected)
            self.assertEqual(expiry,expected['exp'])
            self.assertEqual(signature,base64.urlsafe_b64encode(hmac.new(secret.encode(),head+b'.'+body,hashlib.sha256).digest()).rstrip(b'='))
        with self.assertRaises(ValueError):mint(secret,1700000000,'service_role')

    def test_thirty_days_changes_only_expiry(self):
        secret='synthetic-signing-fixture-not-production-12345'
        for role in ('essay_worker','math_evaluation_worker','math_extraction_worker'):
            old,_=mint(secret,1700000000,role)
            new,expiry=mint(secret,1700000000,role,30)
            def claims(token):
                raw=token.split(b'.')[1]
                return json.loads(base64.urlsafe_b64decode(raw+b'='*((-len(raw))%4)))
            before,after=claims(old),claims(new)
            before.pop('exp');after.pop('exp')
            self.assertEqual(before,after)
            self.assertEqual(expiry,1700000000+30*86400)
        with self.assertRaises(ValueError):mint(secret,1700000000,'essay_worker',365)

    def test_registry_growth_does_not_break_authentication(self):
        self.assertEqual(verify(b'synthetic-token',CONFIG,Probe([(200,[{}]*700)])),700)
        with self.assertRaises(ValueError):verify(b'synthetic-token',CONFIG,Probe([(200,{'error':'fixture'})]))

    def test_math_probes_only_null_dto_and_exact_roles(self):
        for role,own in [('math_evaluation_worker','math_evaluation'),('math_extraction_worker','math_extraction')]:
            transport=Probe([(400,{'code':'22023'}),(403,{'code':'42501'})])
            result=verify_math(b'synthetic-token',CONFIG,role,transport)
            self.assertEqual(result[0][0],own)
            self.assertTrue(all(r.data==b'{"p_request":null}' for r in transport.requests))
            self.assertTrue(all(r.full_url.startswith('https://stlhijzpjfgwwdgunlsd.supabase.co/rest/v1/rpc/math_') for r in transport.requests))

    def test_auth_failure_or_cross_role_acceptance_is_rejected(self):
        for responses in [[(401,{'code':'PGRST303'})],[(400,{'code':'22023'}),(200,{})]]:
            with self.assertRaises(ValueError):verify_math(b'synthetic-token',CONFIG,'math_evaluation_worker',Probe(responses))

if __name__=='__main__':unittest.main()
