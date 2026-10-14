"""DB-journal orchestration over existing ReviewedRuntimeWorker, not an evaluator.
All inputs are trusted frozen server context; HTTP/queue must never supply claims.
"""
from copy import deepcopy
from .live_worker import require,digest
from .exam_runtime import ExamQuestionChannel
from .reviewed_runtime import ReviewedRuntimeWorker

async def execute_async_exam(*,questions,journal,build_worker,finalize,summarize=None):
    require(questions and len({q['questionId'] for q in questions})==len(questions),'INVALID_EXAM_QUESTION_SET')
    require(len({q['evaluationId'] for q in questions})==len(questions),'DUPLICATE_EXAM_CHANNEL')
    require(len(questions)==1 or callable(summarize),'EXAM_SYNTHESIS_REQUIRED')
    final=await journal.read('final')
    if final:
        if final['state']!='checkpoint':return 'reconciling'
        return await finalize(final['payload'])
    results=[]
    # Caller validates ALL evidence/claims and authorizes ALL workers before this loop.
    for index,q in enumerate(questions):
        key='q'+str(index);claim=q['claim'];evaluation=q['evaluationId']
        def completed(args):
            require(args.get('p_evaluation')==evaluation and args.get('p_run')==claim['run_id'] and
                    args.get('p_token')==claim['lease_token'] and type(args.get('p_output')) is dict,'FOREIGN_EXAM_CHECKPOINT')
            return dict(evaluation_id=evaluation,claim_sha256=digest(claim),state='completed',output=deepcopy(args['p_output']))
        async def put(suffix,value):
            await journal.begin(suffix)
            await journal.write(suffix,value)
        async def checkpoint(args):
            completed(args)
            await put(key+'-reviewed',args)
        async def event(name,args):
            if name=='claim':await journal.begin(key)
            elif name=='telemetry':await put(key+'-usage',args)
            elif name=='question_success':
                checked=await journal.read(key+'-reviewed')
                require(checked and checked['state']=='checkpoint' and checked['payload']==args,'REVIEWED_CHECKPOINT_REQUIRED')
                await journal.write(key,completed(args))
            elif name in ('question_failure','question_unknown'):
                await journal.write(key,dict(evaluation_id=evaluation,claim_sha256=digest(claim),
                    state='failed' if name=='question_failure' else 'reconciling',output=None))
            else:raise ValueError('INVALID_EXAM_EVENT')
        channel=ExamQuestionChannel(evaluation,claim,event)
        saved=await journal.read(key);reviewed=await journal.read(key+'-reviewed')
        if saved and saved['state']=='checkpoint':channel.restore(saved['payload'])
        elif reviewed and reviewed['state']=='checkpoint':channel.restore(completed(reviewed['payload']))
        elif saved:return 'reconciling' # Dispatch may have occurred. Never steal/retry.
        if not channel.claimed:
            worker=build_worker(channel,checkpoint)
            require(isinstance(worker,ReviewedRuntimeWorker) and worker.checkpoint is checkpoint,'EXISTING_REVIEWED_WORKER_REQUIRED')
            # The same channel state machine with awaitable event persistence.
            worker.rpc=channel.call_async
            state=await worker.execute_async(evaluation)
        else:state=channel.terminal
        if state=='reconciling':return state
        if state=='failed':
            record={'result':None,'failed':True}
            await put('final',record)
            return await finalize(record)
        require(state=='completed' and channel.output is not None,'EXAM_QUESTION_INCOMPLETE')
        usage=await journal.read(key+'-usage')
        require(usage and usage['state']=='checkpoint','PROVIDER_TELEMETRY_REQUIRED')
        results.append({k:q[k] for k in ('questionId','rubricVersion','evidenceVersion')}|
            {'evaluation':channel.output,'criteria':deepcopy(q['criteria']),
             'telemetry':{k:usage['payload'].get('p_'+k) for k in ('input_tokens','output_tokens','total_tokens','latency_ms','cost_amount','currency')}})
    if len(results)==1:summary=results[0]['evaluation']['summary']
    else:
        saved=await journal.read('summary')
        if saved and saved['state']=='checkpoint':
            require(saved['payload']['input']==digest(results),'EXAM_SYNTHESIS_CHANGED')
            summary=saved['payload']['summary']
        elif saved:return 'reconciling'
        else:
            await journal.begin('summary')
            summary=await summarize(deepcopy(results))
            require(type(summary) is str and summary.strip(),'EXAM_SYNTHESIS_REQUIRED')
            await journal.write('summary',{'input':digest(results),'summary':summary})
    record={'result':{'summary':summary,'questions':results},'failed':False}
    await journal.begin('final');await journal.write('final',record)
    return await finalize(record)
