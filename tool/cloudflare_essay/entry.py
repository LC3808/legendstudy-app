"""Deployment entry. Disabled by default; no Provider/Credit startup calls."""
import json,hmac
from uuid import UUID
from urllib.error import HTTPError
from urllib.parse import urlparse
from workers import WorkerEntrypoint,Response,Request
from essay_lab.live_worker import require,SignedReview,Unknown
from essay_lab.cloudflare_http import AsyncOperatingTransport,ORIGIN,provider_transport,fetch_bytes
from essay_lab.cloudflare_runtime import CloudflareExamRuntime
from essay_lab.reviewed_runtime import reviewed_openai,ReviewedRuntimeWorker,RuntimePermit,configured_binding
from essay_lab.material_runtime import load_reviewed_material
from essay_lab.semantic_review import openai_review
from essay_lab.live_worker import digest
from registry_asset import REGISTRY
import time

class Default(WorkerEntrypoint):
    def transport(self):
        return AsyncOperatingTransport(origin=ORIGIN,publishable_key=self.env.SUPABASE_PUBLISHABLE_KEY,
            worker_jwt=self.env.ESSAY_REGISTRY_WORKER_JWT,allowed_subjects=json.loads(self.env.ESSAY_ALLOWED_SUBJECTS),
            public_exams=json.loads(getattr(self.env,'ESSAY_PUBLIC_EXAMS','[]')))

    def configuration(self,transport,binding=None):
        # No synthetic review callback or automatic signing fallback.
        mode=getattr(self.env,'ESSAY_REVIEW_MODE','service')
        require(mode in ('service','independent_model'),'REVIEW_MODE_REQUIRED')
        legacy=json.loads(self.env.ESSAY_PROVIDER_BINDING)
        raw=getattr(self.env,'ESSAY_PROVIDER_BINDINGS',None)
        approved=json.loads(raw) if raw else None
        def provider_for(policy):
            selected=configured_binding(policy,legacy,approved)
            result=reviewed_openai(self.env.ESSAY_PROVIDER_KEY,selected,transport=provider_transport)
            result.evaluate=result.evaluate_async
            return result
        provider=provider_for(legacy if binding is None else binding)
        keys={k:v.encode() for k,v in json.loads(self.env.ESSAY_REVIEW_VERIFY_KEYS).items()}
        require(keys,'REVIEWER_BLOCKED')
        async def review(evaluation,value,output):
            response=await self.env.ESSAY_REVIEWER.fetch(Request('https://essay-review.internal/review',method='POST',
                headers={'Content-Type':'application/json'},body=json.dumps({'evaluation_id':evaluation,'package':value,'output':output})).js_object)
            require(response.status==200,'REVIEW_UNAVAILABLE')
            return json.loads(await response.text())
        if mode=='independent_model':
            policy=json.loads(self.env.ESSAY_REVIEW_BINDING)
            require(set(policy)=={'reviewer_id','model','model_version'} and policy['reviewer_id'] in keys,'REVIEW_POLICY_REQUIRED')
            review=openai_review(key=self.env.ESSAY_PROVIDER_KEY,model=policy['model'],model_version=policy['model_version'],
                reviewer_id=policy['reviewer_id'],signing_key=keys[policy['reviewer_id']],transport=provider_transport)
        else:
            require(getattr(self.env,'ESSAY_REVIEWER',None) is not None,'REVIEW_SERVICE_REQUIRED')
        async def receipt(_):
            # Actual receipt persistence is supplied per-run below, never discard.
            raise Unknown('RECEIPT_PERSISTENCE_REQUIRED')
        return CloudflareExamRuntime(rpc=transport.rpc,registry=REGISTRY,provider=provider,
            reviewer=SignedReview(keys),review_source=review,receipt_sink=receipt,
            allowed_subjects=transport.allowed,enabled=self.env.ESSAY_EXECUTION_ENABLED=='true',provider_factory=provider_for,public_exams=transport.public_exams)

    async def admission(self,t,subject,exam):
        require(subject in t.allowed or exam in t.public_exams,'EXAM_ACCESS_DENIED')
        require(await t.rpc('essay_exam_session_ready',{})=='exam-session-v1','EXAM_SESSION_CONTRACT_REQUIRED')
        policy=await t.rpc('essay_exam_preflight',dict(p_subject=subject,p_exam=exam))
        pkg=await t.rpc('essay_material_runtime_package',dict(p_exam=exam,p_digest=policy['package_digest']))
        hosted,report=load_reviewed_material(pkg,REGISTRY,pinned_digest=policy['package_digest'],binding=policy['binding'],regime=policy['regime'],evaluation_type=policy['evaluation_type'],activation_approved=True)
        runtime=self.configuration(t,policy['binding'])
        for q in hosted.values():
            worker=ReviewedRuntimeWorker(t.rpc,runtime.provider,q.frozen_cache,runtime.reviewer,runtime.review_source,runtime.receipt_sink,lambda _:None,
                permit=RuntimePermit('preflight','unused',digest(q.frozen_cache),policy['binding'],int(time.time()+90),True))
            worker.authorize('preflight')
        source=runtime.review_source
        key_bound=bool(getattr(source,'key',None) and runtime.reviewer.keys.get(getattr(source,'reviewer_id',''))==source.key)
        if getattr(self.env,'ESSAY_REVIEW_MODE','service')=='independent_model':require(key_bound,'REVIEW_KEY_BINDING_REQUIRED')
        return {'session_version':'exam-session-v1','ready':bool(report['ready'] and hosted),'package_version':pkg['package_version'],'package_digest':policy['package_digest'],'question_count':len(hosted),'question_ids':sorted(hosted),'model':policy['binding']['model'],'review_key_binding':'PASS' if key_bound else 'EXTERNAL_SERVICE','provider_called':False}

    async def fetch(self,request):
        headers={'Cache-Control':'no-store'}
        try:
            secret=getattr(self.env,'ESSAY_WORKER_SERVICE_TOKEN','')
            require(len(secret)>=32 and hmac.compare_digest(request.headers.get('X-Essay-Service-Token',''),secret),'ACCESS_DENIED')
            require(request.method=='POST' and int(request.headers.get('Content-Length','0'))<=4096,'INVALID_REQUEST')
            raw=await request.text();require(len(raw.encode())<=4096,'INVALID_REQUEST')
            payload=json.loads(raw);path=urlparse(request.url).path
            token=request.headers.get('Authorization','').removeprefix('Bearer ')
            t=self.transport();subject=await t.subject(token)
            if path=='/connection-check':
                require(self.env.ESSAY_EXECUTION_ENABLED=='false' and set(payload)=={'probe_id'},'INVALID_REQUEST')
                probe=str(UUID(payload['probe_id']))
                result={'service_auth':'PASS','user_auth':'PASS','execution_enabled':False,'probe_id':probe}
                # Fixed read-only RPCs. Never claim/reserve/evaluate, return evidence or log credentials.
                calls=[('registry','essay_registered_questions',{'p_subject':subject}),
                    ('package','essay_material_runtime_package',{'p_exam':'345d3caa-3438-58c3-8f80-62a6242179ec','p_digest':'40ef4e7bbe5295facf146946b7f1924f086ff6e540108a3def8efb22e37ba4ae'}),
                    ('policy','essay_exam_preflight',{'p_subject':subject,'p_exam':'345d3caa-3438-58c3-8f80-62a6242179ec'})]
                for label,name,args in calls:
                    try:
                        raw=await fetch_bytes(ORIGIN+'/rest/v1/rpc/'+name,{'apikey':t.key,'Authorization':'Bearer '+t.worker,'Content-Type':'application/json'},json.dumps(args))
                        value=json.loads(raw)
                        result[label]={'http':200,**({'count':len(value)} if label=='registry' and isinstance(value,list) else {})}
                    except HTTPError as e:result[label]={'http':e.code}
                    except Exception:result[label]={'http':None}
                review_binding='ESSAY_REVIEW_BINDING' if getattr(self.env,'ESSAY_REVIEW_MODE','service')=='independent_model' else 'ESSAY_REVIEWER'
                result['missing_runtime_bindings']=[name for name in (review_binding,'ESSAY_PROVIDER_BINDING','ESSAY_PROVIDER_KEY','ESSAY_REVIEW_VERIFY_KEYS') if not getattr(self.env,name,None)]
                try:
                    result['runtime_admission']=await self.admission(t,subject,'345d3caa-3438-58c3-8f80-62a6242179ec')
                except Exception as error:
                    result['runtime_admission']={'ready':False,'code':type(error).__name__}
                await self.env.ESSAY_QUEUE.send(json.dumps({'kind':'connection_probe','probe_id':probe}))
                result['queue']='ENQUEUED'
                return Response.json(result,headers=headers)
            if path=='/exam-admission':
                require(set(payload)=={'exam_id'},'INVALID_REQUEST')
                return Response.json(await self.admission(t,subject,payload['exam_id']),headers=headers)
            require(path=='/exam-evaluate' and set(payload)=={'run_id'},'INVALID_REQUEST')
            require(self.env.ESSAY_EXECUTION_ENABLED=='true','EVALUATION_EXECUTION_HELD')
            # Identity-only message. Consumer independently verifies owner/lifecycle/lease.
            # Native binding is a JS proxy: use its positional API. The default
            # structured-clone encoding preserves this JSON string on delivery.
            await self.env.ESSAY_QUEUE.send(json.dumps({'subject_id':subject,'run_id':payload['run_id']}))
            return Response.json({'run_id':payload['run_id'],'state':'queued'},status=202,headers=headers)
        except Exception:
            return Response.json({'code':'RUNTIME_UNAVAILABLE'},status=503,headers=headers)

    async def queue(self,batch,*_context):
        for message in batch.messages:
            try:
                value=json.loads(message.body)
                if isinstance(value,dict) and value.get('kind')=='connection_probe':
                    require(self.env.ESSAY_EXECUTION_ENABLED=='false' and set(value)=={'kind','probe_id'},'INVALID_PROBE')
                    probe=str(UUID(value['probe_id']))
                    print('ESSAY_CONNECTION_PROBE_ACK '+probe)
                    message.ack()
                    continue
                t=self.transport();runtime=self.configuration(t)
                state=await runtime.consume(json.loads(message.body))
                if state=='continue':
                    # Durable question checkpoints make duplicate delivery safe.
                    # Send before ACK so a lost enqueue never loses the exam.
                    await self.env.ESSAY_QUEUE.send(message.body)
                    message.ack()
                elif state=='reconciling':message.retry()
                else:message.ack()
            except Exception as error:
                # Symbolic class only: messages/tracebacks may contain credentials.
                print('ESSAY_QUEUE_ERROR '+type(error).__name__)
                message.retry() # DB intent prevents repeated Provider call.
