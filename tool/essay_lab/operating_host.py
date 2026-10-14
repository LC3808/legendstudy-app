"""Deployment composition for RuntimeHost; no new evaluator or credential issuer.

Only a private persistent host may mount the returned WSGI app. Secrets are supplied
by its secret manager, never request JSON. Construction performs no Provider call.
Independent semantic review remains an injected existing service, not self-approval.
"""
import json,base64,time
from urllib.request import Request, build_opener, HTTPRedirectHandler
from urllib.error import HTTPError, URLError
from uuid import UUID
from .live_worker import require, Unknown
from .durable_journal import DurableJournal
from .material_runtime import ReservedExamRuntime
from .runtime_host import RuntimeHost
from .reviewed_runtime import reviewed_openai

ORIGIN='https://stlhijzpjfgwwdgunlsd.supabase.co'
RPCS=frozenset(('essay_registered_questions','essay_material_runtime_package',
    'essay_exam_preflight','essay_exam_claim','essay_exam_finish'))

class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self,*args,**kwargs):
        raise URLError('REDIRECT_DENIED')

class OperatingTransport:
    def __init__(self,*,origin,publishable_key,worker_jwt,allowed_subjects,open_url=None):
        require(origin==ORIGIN,'PROJECT_MISMATCH')
        require(isinstance(publishable_key,str) and publishable_key.startswith('sb_publishable_'),'PUBLIC_KEY_REQUIRED')
        require(isinstance(worker_jwt,str) and len(worker_jwt.split('.'))==3 and not any(c.isspace() for c in worker_jwt),'WORKER_CREDENTIAL_REQUIRED')
        try:
            parts=worker_jwt.split('.')
            header,claims=[json.loads(base64.urlsafe_b64decode(p+'='*((-len(p))%4))) for p in parts[:2]]
            valid=header.get('alg') in ('HS256','ES256','RS256') and claims.get('role')=='essay_worker' and type(claims.get('exp')) is int and claims['exp']>time.time()+60
        except (ValueError,TypeError,AttributeError):valid=False
        require(valid,'WORKER_CREDENTIAL_REQUIRED') # Supabase still verifies signature.
        require(type(allowed_subjects) in (list,tuple) and 0<len(allowed_subjects)<=10,'ALLOWLIST_REQUIRED')
        self.allowed={str(UUID(s)) for s in allowed_subjects}
        self.key=publishable_key;self.worker=worker_jwt
        self.open_url=open_url or build_opener(NoRedirect()).open

    def _request(self,path,token,payload=None):
        require(isinstance(token,str) and bool(token) and not any(c.isspace() for c in token),'TOKEN_REQUIRED')
        body=None if payload is None else json.dumps(payload,allow_nan=False).encode()
        require(body is None or len(body)<=8_388_608,'REQUEST_TOO_LARGE')
        request=Request(ORIGIN+path,data=body,headers={'apikey':self.key,
            'Authorization':'Bearer '+token,'Content-Type':'application/json'})
        try:
            with self.open_url(request,timeout=25) as response:
                require(response.status==200,'RPC_RESPONSE_INVALID')
                raw=response.read(8_388_609)
                require(len(raw)<=8_388_608,'RESPONSE_TOO_LARGE')
                return json.loads(raw)
        except (HTTPError,URLError,TimeoutError):
            # Never emit response bodies, headers or token; never retry mutations.
            raise Unknown('BACKEND_UNAVAILABLE') from None

    def subject(self,token):
        user=self._request('/auth/v1/user',token)
        require(type(user) is dict and user.get('id') in self.allowed,'ACCESS_DENIED')
        return user['id']

    def rpc(self,name,args):
        require(name in RPCS and type(args) is dict,'RPC_DENIED')
        return self._request('/rest/v1/rpc/'+name,self.worker,args)

def compose_host(*,transport,registry,journal_path,service_token,provider_key,
                 binding,reviewer,review_source,receipt_sink,enabled=False):
    """Reuse current prompt, SignedReview and durable runner without a fallback.

    The caller must supply the existing independent reviewer and durable receipt
    sink. Missing services stay unavailable; this adapter never signs reviews.
    Model policy is verified again against the DB by ReservedExamRuntime.
    """
    require(len(service_token)>=32,'SERVICE_TOKEN_REQUIRED')
    require(isinstance(provider_key,str) and bool(provider_key),'PROVIDER_KEY_REQUIRED')
    require(callable(review_source) and callable(receipt_sink),'REVIEW_SERVICE_REQUIRED')
    journal=DurableJournal(journal_path)
    runtime=ReservedExamRuntime(subject=transport.subject,worker_rpc=transport.rpc,
        registry=registry,journal=journal,provider=reviewed_openai(provider_key,binding),
        reviewer=reviewer,review_source=review_source,receipt_sink=receipt_sink)
    # This host mounts only exam routes; legacy per-question endpoints stay closed.
    host=RuntimeHost(questions={},authenticate=transport.subject,owned=None,
        user_rpc=None,worker_factory=None,journal=journal,service_token=service_token,
        preflight=lambda _:False,enabled=enabled,exam_runtime=runtime)
    return host.wsgi
