"""Cloudflare fetch adapter over unchanged Provider request/response rules."""
import json
import math
import time
import io
from uuid import UUID
from urllib.error import HTTPError
from .operating_host import OperatingTransport,ORIGIN,RPCS
from .live_worker import require,Unknown
from .transport_diagnostics import FetchFailure,attach_transport_diagnostic

def parse_public_exams(raw):
    """Read legacy JSON or compact UUID CSV without broadening authorization."""
    require(isinstance(raw,str),'PUBLIC_SCOPE_INVALID')
    value=raw.strip()
    if value.startswith('uuid64:'):
        import base64
        encoded=value[7:]
        require(len(encoded)<=5464,'PUBLIC_SCOPE_INVALID')
        data=base64.b64decode(encoded,validate=True)
        require(data and len(data)%16==0 and len(data)<=4096 and base64.b64encode(data).decode()==encoded,'PUBLIC_SCOPE_INVALID')
        items=[str(UUID(bytes=data[i:i+16])) for i in range(0,len(data),16)]
        require(len(set(items))==len(items),'PUBLIC_SCOPE_INVALID')
        return items
    items=json.loads(value) if value.startswith('[') else value.split(',') if value else []
    require(type(items) is list and len(items)<=256,'PUBLIC_SCOPE_INVALID')
    require(all(isinstance(item,str) and item.strip() for item in items),'PUBLIC_SCOPE_INVALID')
    return [str(UUID(item.strip())) for item in items]

async def fetch_bytes(url,headers,body=None,timeout=25,limit=8388608,error_limit=0):
    from workers import fetch
    from js import AbortController,setTimeout,clearTimeout
    controller=AbortController.new()
    timer=setTimeout(controller.abort.bind(controller),timeout*1000)
    started=time.monotonic();phase='request';status=None
    def diagnostic(kind):
        return dict(kind=kind,phase=phase,elapsed_ms=math.ceil(max(0,time.monotonic()-started)*1000),
                    deadline_ms=math.ceil(timeout*1000),http_status=status)
    try:
        response=await fetch(url,method='POST' if body is not None else 'GET',headers=headers,
                             body=body,redirect='manual',signal=controller.signal)
        status=response.status
        if status!=200:
            # Only explicit admin RPC callers retain a bounded error body, never logs.
            error_body=b''
            if error_limit:
                require(type(error_limit) is int and 0<error_limit<=4096,'ERROR_LIMIT_INVALID')
                reader=response.js_response.body.getReader();parts=[];size=0
                while True:
                    chunk=await reader.read()
                    if chunk.done:break
                    piece=bytes(chunk.value.to_py());size+=len(piece)
                    if size>error_limit:
                        await reader.cancel();parts=[];break
                    parts.append(piece)
                error_body=b''.join(parts)
            raise attach_transport_diagnostic(HTTPError(url,status,'HTTP_FAILURE',None,io.BytesIO(error_body)),diagnostic('http_status'))
        phase='response_body'
        # Reader caps before full allocation; never record response/error content.
        reader=response.js_response.body.getReader()
        parts=[];size=0
        while True:
            chunk=await reader.read()
            if chunk.done:break
            piece=bytes(chunk.value.to_py());size+=len(piece)
            if size>limit:
                failure=FetchFailure(diagnostic('response_too_large'))
                try:await reader.cancel()
                except Exception:pass
                raise failure
            parts.append(piece)
        return b''.join(parts)
    except (HTTPError,FetchFailure):raise
    except Exception:
        # Only this request's deadline controller proves a timeout. Other aborts
        # remain network/read ambiguity; no raw exception or response is copied.
        kind='timeout' if bool(controller.signal.aborted) else 'body_read' if phase=='response_body' else 'network'
        raise FetchFailure(diagnostic(kind)) from None
    finally:clearTimeout(timer)

class AsyncOperatingTransport(OperatingTransport):
    def __init__(self,public_exams=(),**kwargs):
        super().__init__(**kwargs,open_url=lambda *_:None)
        # The deployed legacy parent validates origin but does not retain it.
        self.origin=kwargs['origin']
        require(type(public_exams) in (list,tuple) and len(public_exams)<=256,'PUBLIC_SCOPE_INVALID')
        self.public_exams={str(UUID(exam)) for exam in public_exams}
    async def _request(self,path,token,payload=None):
        require(isinstance(token,str) and token and not any(c.isspace() for c in token),'TOKEN_REQUIRED')
        body=None if payload is None else json.dumps(payload,allow_nan=False)
        require(body is None or len(body.encode())<=8388608,'REQUEST_TOO_LARGE')
        try:return json.loads(await fetch_bytes(self.origin+path,{'apikey':self.key,'Authorization':'Bearer '+token,'Content-Type':'application/json'},body))
        except Exception:raise Unknown('BACKEND_UNAVAILABLE') from None
    async def subject(self,token):
        user=await self._request('/auth/v1/user',token)
        require(type(user) is dict and (user.get('id') in self.allowed or bool(self.public_exams)),'ACCESS_DENIED')
        require(str(UUID(user['id']))==user['id'],'ACCESS_DENIED')
        return user['id']
    async def rpc(self,name,args):
        require(name in RPCS|{'essay_exam_checkpoint','essay_exam_session_ready','essay_exam_session_claim','essay_exam_session_checkpoint','essay_exam_dispatch_guard','essay_exam_recovery_context','essay_exam_recovery_finish','essay_exam_recovery_quality_ready'} and type(args) is dict,'RPC_DENIED')
        return await self._request('/rest/v1/rpc/'+name,self.worker,args)

class BufferedResponse:
    def __init__(self,body):self.body=body
    def __enter__(self):return self
    def __exit__(self,*_):pass
    def read(self,n):return self.body[:n]

async def provider_transport(request,timeout):
    require(request.full_url=='https://api.openai.com/v1/responses','PROVIDER_ENDPOINT_DENIED')
    try:
        raw=await fetch_bytes(request.full_url,dict(request.header_items()),request.data.decode(),timeout,524288)
        return BufferedResponse(raw)
    except HTTPError:raise
    except FetchFailure as error:
        code={'timeout':'PROVIDER_TIMEOUT','network':'PROVIDER_NETWORK_UNKNOWN',
              'body_read':'PROVIDER_BODY_READ_UNKNOWN','response_too_large':'PROVIDER_RESPONSE_TOO_LARGE'}[error.transport_diagnostic['kind']]
        raise attach_transport_diagnostic(Unknown(code),error.transport_diagnostic) from None
    except Exception:raise Unknown('PROVIDER_NETWORK_UNKNOWN') from None
