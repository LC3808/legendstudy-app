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

def receipt_checkpoint_key(value):
    # A rejected output has no successful Provider output receipt. Keep the
    # symbolic failure durable so the existing failure/Credit path can finish.
    if value.get('component')=='validation_failure':
        require(set(value)=={'component','code'},'INVALID_FAILURE_RECEIPT')
        code=value['code']
        require(isinstance(code,str) and 0<len(code)<=80 and
                all(c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789' for c in code),
                'INVALID_FAILURE_RECEIPT')
        return 'validation-failure-'+digest(value)
    return 'receipt-'+value['output_sha256']

class CloudflareExamRuntime:
    def __init__(self,*,rpc,registry,provider,reviewer,review_source,receipt_sink,allowed_subjects,enabled=False,provider_factory=None,public_exams=()):
        self.rpc=rpc;self.registry=registry;self.provider=provider;self.reviewer=reviewer
        self.review_source=review_source;self.receipt_sink=receipt_sink
        self.allowed=set(allowed_subjects);self.enabled=enabled
        self.public_exams={str(UUID(exam)) for exam in public_exams}
        self.provider_factory=provider_factory

    async def consume(self,message):
        # Queue carries identity only, never JWT/answers/Package/provider choice.
        require(self.enabled is True,'EVALUATION_EXECUTION_HELD')
        require(type(message) is dict and set(message)=={'subject_id','run_id'},'INVALID_JOB')
        subject=str(UUID(message['subject_id']));run=str(UUID(message['run_id']))
        require(subject in self.allowed or bool(self.public_exams),'ACCESS_DENIED')
        claim=await self.rpc('essay_exam_session_claim',dict(p_subject=subject,p_run=run,p_dispatch=str(uuid5(NS,'dispatch/'+subject+'/'+run))))
        if claim['state'] in ('completed','failed'):return claim['state']
        require(subject in self.allowed or claim.get('exam_id') in self.public_exams,'EXAM_ACCESS_DENIED')
        require(claim['subject_id']==subject and claim['snapshot']['ownerId']==subject,'EXAM_ACCESS_DENIED')
        require(claim.get('session_version')=='exam-session-v1','EXAM_SESSION_CONTRACT_REQUIRED')
        journal=DatabaseCheckpoint(self.rpc,subject,run,claim['lease_token'],session=True)
        policy=claim['snapshot']['runtime']
        provider=self.provider_factory(policy['binding']) if self.provider_factory else self.provider
        pkg=await self.rpc('essay_material_runtime_package',dict(p_exam=claim['exam_id'],p_digest=policy['package_digest']))
        questions,caches=prepare_claimed_material(claim,pkg,self.registry)
        version=f"material-{pkg['package_version']}-{policy['package_digest']}"
        def build(channel,checkpoint):
            index=next(i for i,q in enumerate(questions) if q['evaluationId']==channel.evaluation_id)
            q=questions[index];cache=caches[q['questionId']]
            attempt=claim['attempts'].get(str(index),0)
            prefix='q'+str(index)+'-a'+str(attempt)+'-'
            async def persist_receipt(value):
                key=prefix+receipt_checkpoint_key(value)
                await journal.begin(key)
                await journal.write(key,value)
            source=self.review_source.bind_audit(persist_receipt) if hasattr(self.review_source,'bind_audit') else self.review_source
            async def review(evaluation,value,output):
                await journal.begin(prefix+'independent-review-started')
                await journal.write(prefix+'independent-review-started',{'stage':'independent_review'})
                try:
                    receipt=await source(evaluation,value,output)
                except Exception as error:
                    await journal.begin(prefix+'independent-review-error')
                    await journal.write(prefix+'independent-review-error',{'error_type':type(error).__name__})
                    raise
                await journal.begin(prefix+'review')
                await journal.write(prefix+'review',receipt)
                return receipt
            return ReviewedRuntimeWorker(channel,provider,cache,self.reviewer,review,persist_receipt,checkpoint,
                permit=RuntimePermit(channel.evaluation_id,digest(channel.claim['input']),digest(cache),policy['binding'],int(time.time()+90),True))
        for q in questions:
            require(q['rubricVersion']==version and q['evidenceVersion']==version,'REVIEWED_PACKAGE_PIN_REQUIRED')
            provider_package(q['claim'],caches[q['questionId']])
            probe=ExamQuestionChannel(q['evaluationId'],q['claim'],lambda *_:None)
            build(probe,lambda _:None).authorize(q['evaluationId'])
            q['criteria']=caches[q['questionId']]['criteria']
        async def finish(record):
            return await self.rpc('essay_exam_finish',dict(p_subject=subject,p_run=run,p_token=claim['lease_token'],p_result=record['result'],p_failed=record['failed']))
        async def summarize(results):
            # Presentation only: verbatim reviewed summaries, no new score/evaluation.
            return '\n\n'.join(result['evaluation']['summary'] for result in results)
        return await execute_async_exam(questions=questions,journal=journal,build_worker=build,finalize=finish,
            summarize=summarize,attempts=claim['attempts'],max_new_questions=1)
