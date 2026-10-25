"""Cloudflare fetch adapter over unchanged Provider request/response rules."""
import json
from uuid import UUID
from urllib.error import HTTPError
from .operating_host import OperatingTransport,ORIGIN,RPCS
from .live_worker import require,Unknown

async def fetch_bytes(url,headers,body=None,timeout=25,limit=8388608):
    from workers import fetch
    from js import AbortController,setTimeout,clearTimeout
    controller=AbortController.new()
    timer=setTimeout(controller.abort.bind(controller),timeout*1000)
    try:
        response=await fetch(url,method='POST' if body is not None else 'GET',headers=headers,
                             body=body,redirect='manual',signal=controller.signal)
        if response.status!=200:raise HTTPError(url,response.status,'HTTP_FAILURE',None,None)
        # Reader caps before full allocation; never record response/error content.
        reader=response.js_response.body.getReader()
        parts=[];size=0
        while True:
            chunk=await reader.read()
            if chunk.done:break
            piece=bytes(chunk.value.to_py());size+=len(piece)
            if size>limit:
                await reader.cancel();raise ValueError('RESPONSE_TOO_LARGE')
            parts.append(piece)
        return b''.join(parts)
    finally:clearTimeout(timer)

class AsyncOperatingTransport(OperatingTransport):
    def __init__(self,public_exams=(),**kwargs):
        super().__init__(**kwargs,open_url=lambda *_:None)
        require(type(public_exams) in (list,tuple) and len(public_exams)<=128,'PUBLIC_SCOPE_INVALID')
        self.public_exams={str(UUID(exam)) for exam in public_exams}
    async def _request(self,path,token,payload=None):
        require(isinstance(token,str) and token and not any(c.isspace() for c in token),'TOKEN_REQUIRED')
        body=None if payload is None else json.dumps(payload,allow_nan=False)
        require(body is None or len(body.encode())<=8388608,'REQUEST_TOO_LARGE')
        try:return json.loads(await fetch_bytes(ORIGIN+path,{'apikey':self.key,'Authorization':'Bearer '+token,'Content-Type':'application/json'},body))
        except Exception:raise Unknown('BACKEND_UNAVAILABLE') from None
    async def subject(self,token):
        user=await self._request('/auth/v1/user',token)
        require(type(user) is dict and (user.get('id') in self.allowed or bool(self.public_exams)),'ACCESS_DENIED')
        require(str(UUID(user['id']))==user['id'],'ACCESS_DENIED')
        return user['id']
    async def rpc(self,name,args):
        require(name in RPCS|{'essay_exam_checkpoint','essay_exam_session_ready','essay_exam_session_claim','essay_exam_session_checkpoint'} and type(args) is dict,'RPC_DENIED')
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
    except Exception:raise Unknown('PROVIDER_NETWORK_UNKNOWN') from None
