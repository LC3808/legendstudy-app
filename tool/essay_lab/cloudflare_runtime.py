"""Cloudflare async consumer core: same Python evaluator, Supabase checkpoints.
No filesystem or external host. Runtime credentials/config remain server-only.
"""
from uuid import UUID,uuid5
import time
from .live_worker import require,digest,package as provider_package
from .material_runtime import prepare_claimed_material,NS
from .reviewed_runtime import ReviewedRuntimeWorker,RuntimePermit
from .exam_runtime import ExamQuestionChannel
from .db_checkpoint import DatabaseCheckpoint
from .async_exam import execute_async_exam

class CloudflareExamRuntime:
    def __init__(self,*,rpc,registry,provider,reviewer,review_source,receipt_sink,allowed_subjects,enabled=False):
        self.rpc=rpc;self.registry=registry;self.provider=provider;self.reviewer=reviewer
        self.review_source=review_source;self.receipt_sink=receipt_sink
        self.allowed=set(allowed_subjects);self.enabled=enabled

    async def consume(self,message):
        # Queue carries identity only, never JWT/answers/Package/provider choice.
        require(self.enabled is True,'EVALUATION_EXECUTION_HELD')
        require(type(message) is dict and set(message)=={'subject_id','run_id'},'INVALID_JOB')
        subject=str(UUID(message['subject_id']));run=str(UUID(message['run_id']))
        require(subject in self.allowed,'ACCESS_DENIED')
        claim=await self.rpc('essay_exam_claim',dict(p_subject=subject,p_run=run,p_dispatch=str(uuid5(NS,'dispatch/'+subject+'/'+run))))
        if claim['state'] in ('completed','failed'):return claim['state']
        require(claim['subject_id']==subject and claim['snapshot']['ownerId']==subject,'EXAM_ACCESS_DENIED')
        journal=DatabaseCheckpoint(self.rpc,subject,run,claim['lease_token'])
        policy=claim['snapshot']['runtime']
        pkg=await self.rpc('essay_material_runtime_package',dict(p_exam=claim['exam_id'],p_digest=policy['package_digest']))
        questions,caches=prepare_claimed_material(claim,pkg,self.registry)
        require(len(questions)==1,'EXAM_SYNTHESIS_REQUIRED') # First Hanyang exam; no fabricated multi-question synthesis.
        version=f"material-{pkg['package_version']}-{policy['package_digest']}"
        async def persist_receipt(value):
            key='receipt-'+value['output_sha256']
            await journal.begin(key)
            await journal.write(key,value)
        source=self.review_source.bind_audit(persist_receipt) if hasattr(self.review_source,'bind_audit') else self.review_source
        async def review(evaluation,value,output):
            receipt=await source(evaluation,value,output)
            await journal.begin('review-'+evaluation)
            await journal.write('review-'+evaluation,receipt)
            return receipt
        def build(channel,checkpoint):
            q=next(q for q in questions if q['evaluationId']==channel.evaluation_id)
            cache=caches[q['questionId']]
            return ReviewedRuntimeWorker(channel,self.provider,cache,self.reviewer,review,persist_receipt,checkpoint,
                permit=RuntimePermit(channel.evaluation_id,digest(channel.claim['input']),digest(cache),policy['binding'],int(time.time()+90),True))
        for q in questions:
            require(q['rubricVersion']==version and q['evidenceVersion']==version,'REVIEWED_PACKAGE_PIN_REQUIRED')
            provider_package(q['claim'],caches[q['questionId']])
            probe=ExamQuestionChannel(q['evaluationId'],q['claim'],lambda *_:None)
            build(probe,lambda _:None).authorize(q['evaluationId'])
            q['criteria']=caches[q['questionId']]['criteria']
        async def finish(record):
            return await self.rpc('essay_exam_finish',dict(p_subject=subject,p_run=run,p_token=claim['lease_token'],p_result=record['result'],p_failed=record['failed']))
        return await execute_async_exam(questions=questions,journal=journal,build_worker=build,finalize=finish)
