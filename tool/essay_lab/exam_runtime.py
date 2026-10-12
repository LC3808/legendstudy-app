"""Unmounted exam adapter reusing ReviewedRuntimeWorker validation and review.

Only trusted, durable server stores may implement save_event/checkpoint/finalize.
Never give this adapter a legacy per-question financial RPC: each child success
is staged, and only the whole exam may settle its single reservation. Production
hosting, lease fencing and operator/owner reads remain deployment prerequisites.
"""
from copy import deepcopy
from .live_worker import Invalid, require, digest
from .reviewed_runtime import ReviewedRuntimeWorker

class ExamQuestionChannel:
    def __init__(self, evaluation_id, claim, save_event):
        self.evaluation_id=evaluation_id
        self.claim=deepcopy(claim)
        self.save_event=save_event
        self.output=None
        self.claimed=False
        self.terminal=None

    def restore(self, saved):
        """Restore only from the trusted durable worker journal, never HTTP input.
        Bind persisted output to this exact frozen claim, not just a question ID.
        Pending/unknown work must be reconciled; it cannot dispatch again.
        """
        require(not self.claimed and self.terminal is None, 'CHANNEL_ALREADY_STARTED')
        require(type(saved) is dict and set(saved)=={'evaluation_id','claim_sha256','state','output'}, 'INVALID_CHANNEL_CHECKPOINT')
        require(saved['evaluation_id']==self.evaluation_id and saved['claim_sha256']==digest(self.claim), 'FOREIGN_CHANNEL_CHECKPOINT')
        state=saved['state']
        require(state in ('processing','completed','failed','reconciling'), 'INVALID_CHANNEL_CHECKPOINT')
        require((state=='completed' and type(saved['output']) is dict) or (state!='completed' and saved['output'] is None), 'INVALID_CHANNEL_CHECKPOINT')
        self.claimed=True
        self.terminal=state if state!='processing' else 'reconciling'
        self.output=deepcopy(saved['output'])

    def snapshot(self):
        require(self.claimed,'CHANNEL_NOT_STARTED')
        return dict(evaluation_id=self.evaluation_id,claim_sha256=digest(self.claim),
                    state=self.terminal or 'processing',output=deepcopy(self.output))

    def __call__(self,name,args):
        require(args.get('p_evaluation')==self.evaluation_id,'FOREIGN_EXAM_QUESTION')
        if name=='essay_claim':
            require(not self.claimed,'QUESTION_ALREADY_CLAIMED')
            # Durable claim event must succeed BEFORE permitting a provider call.
            self.save_event('claim',deepcopy(args))
            self.claimed=True
            return deepcopy(self.claim)
        require(self.claimed and args.get('p_run')==self.claim['run_id'] and
                args.get('p_token')==self.claim['lease_token'],'FOREIGN_EXAM_LEASE')
        require(self.terminal is None,'QUESTION_ALREADY_TERMINAL')
        if name=='essay_record_provider_telemetry':
            self.save_event('telemetry',deepcopy(args));return None
        if name=='essay_finalize_success':
            require(type(args.get('p_output')) is dict,'INVALID_EXAM_OUTPUT')
            self.save_event('question_success',deepcopy(args))
            self.output=deepcopy(args['p_output']);self.terminal='completed'
        elif name=='essay_finalize_failure':
            self.save_event('question_failure',deepcopy(args));self.terminal='failed'
        elif name=='essay_timeout':
            self.save_event('question_unknown',deepcopy(args));self.terminal='reconciling'
        else:
            raise Invalid('EXAM_RPC_NOT_ALLOWED')
        return self.terminal


def execute_exam(exam_id, questions, build_worker, summarize, checkpoint, finalize):
    """questions: trusted [{questionId,rubricVersion,evidenceVersion,channel}].
    build_worker(channel) returns the existing ReviewedRuntimeWorker. summarize
    must validate a reviewed exam-wide synthesis; no fabricated summary fallback.
    Exceptions (ambiguous storage/transport) deliberately propagate WITHOUT refund
    or retry. Resume only from a durable checkpoint, never rerun this loop blindly.
    """
    require(bool(questions) and len({q['questionId'] for q in questions})==len(questions),
            'INVALID_EXAM_QUESTION_SET')
    require(all(isinstance(q.get('channel'),ExamQuestionChannel) and
                q.get('rubricVersion') and q.get('evidenceVersion') for q in questions),
            'INVALID_EXAM_CHANNEL')
    require(len({q['channel'].evaluation_id for q in questions})==len(questions) and
            len({id(q['channel']) for q in questions})==len(questions),'DUPLICATE_EXAM_CHANNEL')
    results=[]
    for question in questions:
        channel=question['channel']
        # A trusted completed child can survive process restart without re-evaluation.
        # Claimed-but-unfinished children never get a new provider call by guessing.
        if channel.claimed:
            state=channel.terminal or 'reconciling'
        else:
            worker=build_worker(channel)
            require(isinstance(worker,ReviewedRuntimeWorker) and worker.rpc is channel,
                    'EXISTING_REVIEWED_WORKER_REQUIRED')
            state=worker.execute(channel.evaluation_id)
        if state=='reconciling':return 'reconciling'
        if state=='failed':
            record={'examId':exam_id,'result':None,'failed':True}
            checkpoint(deepcopy(record))
            return finalize(deepcopy(record))
        require(state=='completed' and channel.output is not None,'EXAM_QUESTION_INCOMPLETE')
        results.append({k:question[k] for k in ['questionId','rubricVersion','evidenceVersion']}|
                       {'evaluation':deepcopy(channel.output)})
    summary=summarize(deepcopy(results))
    require(type(summary) is str and bool(summary.strip()),'EXAM_SYNTHESIS_REQUIRED')
    record={'examId':exam_id,'result':{'summary':summary,'questions':results},'failed':False}
    checkpoint(deepcopy(record))
    return finalize(deepcopy(record))


def resume_exam(exam_id,checkpoint,finalize):
    """Caller loads a trusted durable checkpoint; SQL checks immutable replay.
    No worker or provider invocation occurs on this path.
    """
    require(type(checkpoint) is dict and set(checkpoint)=={'examId','result','failed'} and
            checkpoint['examId']==exam_id and type(checkpoint['failed']) is bool,
            'INVALID_EXAM_CHECKPOINT')
    require((checkpoint['failed'] and checkpoint['result'] is None) or
            (not checkpoint['failed'] and type(checkpoint['result']) is dict),
            'INVALID_EXAM_CHECKPOINT')
    return finalize(deepcopy(checkpoint))
