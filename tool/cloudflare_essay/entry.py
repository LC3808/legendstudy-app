"""Deployment entry. Disabled by default; no Provider/Credit startup calls."""
import json,hmac
from urllib.parse import urlparse
from workers import WorkerEntrypoint,Response,Request
from essay_lab.live_worker import require,SignedReview,Unknown
from essay_lab.cloudflare_http import AsyncOperatingTransport,ORIGIN,provider_transport
from essay_lab.cloudflare_runtime import CloudflareExamRuntime
from essay_lab.reviewed_runtime import reviewed_openai,ReviewedRuntimeWorker,RuntimePermit
from essay_lab.material_runtime import load_reviewed_material
from essay_lab.live_worker import digest
from registry_asset import REGISTRY
import time

class Default(WorkerEntrypoint):
    def transport(self):
        return AsyncOperatingTransport(origin=ORIGIN,publishable_key=self.env.SUPABASE_PUBLISHABLE_KEY,
            worker_jwt=self.env.ESSAY_REGISTRY_WORKER_JWT,allowed_subjects=json.loads(self.env.ESSAY_ALLOWED_SUBJECTS))

    def configuration(self,transport):
        # No synthetic review callback or automatic signing fallback.
        require(getattr(self.env,'ESSAY_REVIEWER',None) is not None,'REVIEW_SERVICE_REQUIRED')
        binding=json.loads(self.env.ESSAY_PROVIDER_BINDING)
        provider=reviewed_openai(self.env.ESSAY_PROVIDER_KEY,binding,transport=provider_transport)
        provider.evaluate=provider.evaluate_async
        keys={k:v.encode() for k,v in json.loads(self.env.ESSAY_REVIEW_VERIFY_KEYS).items()}
        require(keys,'REVIEWER_BLOCKED')
        async def review(evaluation,value,output):
            response=await self.env.ESSAY_REVIEWER.fetch(Request('https://essay-review.internal/review',method='POST',
                headers={'Content-Type':'application/json'},body=json.dumps({'evaluation_id':evaluation,'package':value,'output':output})).js_object)
            require(response.status==200,'REVIEW_UNAVAILABLE')
            return json.loads(await response.text())
        async def receipt(_):
            # Actual receipt persistence is supplied per-run below, never discard.
            raise Unknown('RECEIPT_PERSISTENCE_REQUIRED')
        return CloudflareExamRuntime(rpc=transport.rpc,registry=REGISTRY,provider=provider,
            reviewer=SignedReview(keys),review_source=review,receipt_sink=receipt,
            allowed_subjects=transport.allowed,enabled=self.env.ESSAY_EXECUTION_ENABLED=='true')

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
            if path=='/exam-admission':
                require(set(payload)=={'exam_id'},'INVALID_REQUEST')
                policy=await t.rpc('essay_exam_preflight',dict(p_subject=subject,p_exam=payload['exam_id']))
                pkg=await t.rpc('essay_material_runtime_package',dict(p_exam=payload['exam_id'],p_digest=policy['package_digest']))
                hosted,report=load_reviewed_material(pkg,REGISTRY,pinned_digest=policy['package_digest'],binding=policy['binding'],regime=policy['regime'],evaluation_type=policy['evaluation_type'],activation_approved=True)
                runtime=self.configuration(t)
                for q in hosted.values():
                    worker=ReviewedRuntimeWorker(t.rpc,runtime.provider,q.frozen_cache,runtime.reviewer,runtime.review_source,runtime.receipt_sink,lambda _:None,
                        permit=RuntimePermit('preflight','unused',digest(q.frozen_cache),policy['binding'],int(time.time()+90),True))
                    worker.authorize('preflight')
                return Response.json({'ready':bool(report['ready'] and hosted)},headers=headers)
            require(path=='/exam-evaluate' and set(payload)=={'run_id'},'INVALID_REQUEST')
            require(self.env.ESSAY_EXECUTION_ENABLED=='true','EVALUATION_EXECUTION_HELD')
            # Identity-only message. Consumer independently verifies owner/lifecycle/lease.
            # Native binding is a JS proxy: use its positional API. The default
            # structured-clone encoding preserves this JSON string on delivery.
            await self.env.ESSAY_QUEUE.send(json.dumps({'subject_id':subject,'run_id':payload['run_id']}))
            return Response.json({'run_id':payload['run_id'],'state':'queued'},status=202,headers=headers)
        except Exception:
            return Response.json({'code':'RUNTIME_UNAVAILABLE'},status=503,headers=headers)

    async def queue(self,batch):
        for message in batch.messages:
            try:
                t=self.transport();runtime=self.configuration(t)
                state=await runtime.consume(json.loads(message.body))
                if state=='reconciling':message.retry()
                else:message.ack()
            except Exception:message.retry() # DB intent prevents repeated Provider call.
