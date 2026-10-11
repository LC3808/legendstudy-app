"""Private hosting adapter for the EXISTING ReviewedRuntimeWorker.
No model choice, new billing, public listener, credentials or deployment defaults.
Host callbacks must use the verified caller JWT / existing narrow worker credential.
"""
from copy import deepcopy
from dataclasses import dataclass
import hmac,json,re,time
from .live_worker import digest,require,Invalid
from .reviewed_runtime import ReviewedRuntimeWorker,RuntimePermit,dispatch_owned_evaluation
from .service_content import cache_for_claim

UUID=re.compile(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
@dataclass(frozen=True)
class HostedQuestion:
    question_id:str
    metadata_version:str
    regime:str
    binding:dict
    plan:dict
    approved_processing:bool=False
    reviewed_cache:bool=False

class RuntimeHost:
    """Dependency-injected production adapter; missing prerequisites fail before claiming.

    authenticate(token) verifies Auth online AND existing allowlist.
    owned(token,id) performs RLS read of the evaluation with its frozen input_snapshot.
    journal.lock(id) must serialize processes, journal.read/write are durable/private.
    worker_factory(permit,cache,checkpoint) MUST return ReviewedRuntimeWorker with
    independent SignedReview, receipt persistence and the existing provider adapter.
    preflight(q) must validate exact provider binding, reviewer key/source and receipt sink
    availability before admission can reserve Credit. Missing composition stays closed.
    No callback is accepted from HTTP input. No public administrative metadata.
    """
    def __init__(self,*,questions,authenticate,owned,user_rpc,worker_factory,journal,
                 service_token,preflight,enabled=False,clock=time.time):
        self.questions=deepcopy(questions);self.authenticate=authenticate;self.owned=owned
        self.user_rpc=user_rpc;self.worker_factory=worker_factory;self.journal=journal
        self.service_token=service_token;self.preflight=preflight;self.enabled=enabled;self.clock=clock

    def ready(self,q):
        require(q.approved_processing and q.reviewed_cache,'CONTENT_HELD')
        require(re.fullmatch(r'essay-v1\.3/policy/[a-f0-9]{64}',q.regime),'POLICY_REQUIRED')
        require(q.binding.get('provider') not in (None,'unconfigured','synthetic'),'PROVIDER_REQUIRED')
        require(self.journal.ready is True,'DURABLE_CHECKPOINT_REQUIRED')
        require(self.preflight(q) is True,'REVIEWER_PROVIDER_PERSISTENCE_UNAVAILABLE')
        private=next((x for x in q.plan['private_content'] if x['question_id']==q.question_id),None)
        require(private and not private['requires_figure'] and private['metadata_version']==q.metadata_version,'CONTENT_NOT_SUPPORTED')

    def handle(self,path,service_token,caller_token,payload):
        if not self.enabled or len(self.service_token)<32:return 503,{'code':'RUNTIME_UNAVAILABLE'}
        if not hmac.compare_digest(service_token,self.service_token):return 403,{'code':'ACCESS_DENIED'}
        try:
            require(type(payload) is dict,'INVALID_REQUEST')
            if path=='/admission':
                require(set(payload)=={'questionId','metadataVersion'},'INVALID_REQUEST')
                q=self.questions.get(payload['questionId']);require(q,'QUESTION_UNAVAILABLE');self.ready(q)
                require(payload['metadataVersion']==q.metadata_version,'METADATA_CHANGED')
                return 200,dict(version='essay-worker-admission-v1',ready=True,questionId=q.question_id,
                    metadataVersion=q.metadata_version,regime=q.regime,expiresAt=int((self.clock()+60)*1000))
            require(path=='/evaluate' and set(payload)=={'evaluation_id'} and UUID.fullmatch(payload['evaluation_id']),'INVALID_REQUEST')
            require(caller_token and self.authenticate(caller_token),'ACCESS_DENIED')
            eid=payload['evaluation_id']
            with self.journal.lock(eid):
                row=self.owned(caller_token,eid)
                require(row and row.get('id')==eid,'ACCESS_DENIED')
                q=self.questions.get(row.get('question_id'));require(q,'QUESTION_UNAVAILABLE');self.ready(q)
                require(row.get('regime_key')==q.regime,'POLICY_CHANGED')
                snapshot=row['input_snapshot']
                cache=cache_for_claim(q.plan,q.question_id,{'input':snapshot,'answer':row['answer']})
                permit=RuntimePermit(eid,digest(snapshot),digest(cache),q.binding,int(self.clock()+90),True)
                checkpoint=lambda value:self.journal.write(eid,deepcopy(value))
                worker=self.worker_factory(permit,cache,checkpoint)
                require(isinstance(worker,ReviewedRuntimeWorker),'EXISTING_WORKER_REQUIRED')
                worker.authorize(eid) # Verify provider/reviewer/persistence before any claim.
                user=lambda name,args:self.user_rpc(caller_token,name,args)
                state=user('essay_evaluation_status',{'p_evaluation':eid})
                if state.get('state') in ('completed','failed','reconciling'):
                    return 200,{'code':'STATUS_CHECK_REQUIRED','evaluation_id':eid}
                saved=self.journal.read(eid)
                if saved is not None:worker.resume_finalization(saved)
                else:dispatch_owned_evaluation(eid,user,worker)
                return 202,{'code':'STATUS_CHECK_REQUIRED','evaluation_id':eid}
        except (Invalid,ValueError,KeyError,TypeError):
            return 409,{'code':'STATUS_CHECK_REQUIRED'}
        except Exception:
            # Transport/finalize uncertainty never causes new reservation or guessed release.
            return 503,{'code':'STATUS_CHECK_REQUIRED'}

    def wsgi(self,environ,start_response):
        """Deploy only on a private host behind the existing gateway, TLS and service auth.
        Student JWT remains distinct from internal service token; no credential logging.
        """
        try:
            size=int(environ.get('CONTENT_LENGTH','0'))
            if environ.get('REQUEST_METHOD')!='POST' or not 0<size<=4096:raise ValueError()
            raw=environ['wsgi.input'].read(size)
            if len(raw)!=size:raise ValueError()
            code,value=self.handle(environ.get('PATH_INFO',''),environ.get('HTTP_X_ESSAY_SERVICE_TOKEN',''),
                environ.get('HTTP_AUTHORIZATION','').removeprefix('Bearer '),json.loads(raw))
        except (ValueError,KeyError):code,value=400,{'code':'INVALID_REQUEST'}
        body=json.dumps(value).encode()
        start_response(f'{code} '+{200:'OK',202:'Accepted',400:'Bad Request',403:'Forbidden',409:'Conflict',503:'Service Unavailable'}[code],
            [('Content-Type','application/json'),('Cache-Control','no-store'),('Content-Length',str(len(body)))])
        return [body]
