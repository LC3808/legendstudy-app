"""Real reviewed worker with synthetic Provider; immutable in-memory journal parity."""
import unittest
from copy import deepcopy
from dataclasses import replace
from tool import test_essay_reviewed_runtime as fixtures
from tool.essay_lab.async_exam import execute_async_exam
from tool.essay_lab.live_worker import Unknown

class Journal:
    def __init__(self):self.rows={}
    async def read(self,key):return deepcopy(self.rows.get(key))
    async def begin(self,key):
        if key in self.rows:raise Unknown('EXISTING_INTENT')
        self.rows[key]=dict(state='pending',payload=None)
    async def write(self,key,value):
        assert self.rows[key]['state']=='pending'
        self.rows[key]=dict(state='checkpoint',payload=deepcopy(value))

class SessionRetryTests(unittest.IsolatedAsyncioTestCase):
    def prepare(self,modes,journal,attempts,settled,lost=False,budget=None):
        questions=[];workers={};requests=[]
        for index,mode in enumerate(modes):
            worker,_,req,_,claim,_=fixtures.RuntimeTests().fixture(mode)
            eid=f'evaluation-{index}';worker.permit=replace(worker.permit,evaluation_id=eid)
            workers[eid]=worker;requests.append(req)
            questions.append(dict(questionId=str(index),rubricVersion='r1',evidenceVersion='e1',evaluationId=eid,claim=claim,criteria=[]))
        def build(channel,checkpoint):
            w=workers[channel.evaluation_id];w.rpc=channel;w.checkpoint=checkpoint
            def wrap(fn):
                async def call(*args,**kwargs):return fn(*args,**kwargs)
                return call
            for name in ('receipt_sink','review_source'):setattr(w,name,wrap(getattr(w,name)))
            w.provider.transport=wrap(w.provider.transport)
            w.provider.evaluate=w.provider.evaluate_async
            return w
        async def finish(record):
            settled.append(record)
            if lost:raise Unknown()
            return 'completed'
        async def summary(results):return '\n\n'.join(q['evaluation']['summary'] for q in results)
        async def run():return await execute_async_exam(questions=questions,journal=journal,build_worker=build,finalize=finish,summarize=summary,attempts=attempts,max_new_questions=budget)
        return run,requests

    async def test_failure_preserves_success_and_only_failed_question_reexecutes(self):
        j=Journal();settled=[]
        run,requests=self.prepare(['ok','invalid','ok'],j,{},settled)
        self.assertEqual(await run(),'retryable');self.assertEqual([len(r) for r in requests],[1,1,1]);self.assertEqual(settled,[])
        original=deepcopy(j.rows)
        run,requests=self.prepare(['ok','ok','ok'],j,{},settled)
        self.assertEqual(await run(),'retryable');self.assertEqual([len(r) for r in requests],[0,0,0])
        run,requests=self.prepare(['ok','ok','ok'],j,{'1':1},settled)
        self.assertEqual(await run(),'completed');self.assertEqual([len(r) for r in requests],[0,1,0])
        self.assertTrue(all(j.rows[k]==v for k,v in original.items()))
        self.assertEqual(len(settled[0]['result']['questions']),3)
        self.assertFalse(settled[0]['failed'])

    async def test_bounded_delivery_preserves_success_and_advances_without_rebilling(self):
        j=Journal();settled=[]
        for index in range(4):
            run,requests=self.prepare(['ok']*4,j,{},settled,budget=1)
            self.assertEqual(await run(),'completed' if index==3 else 'continue')
            self.assertEqual([len(r) for r in requests],[int(i==index) for i in range(4)])
            self.assertEqual(len(settled),int(index==3))
        run,requests=self.prepare(['ok']*4,j,{},settled,budget=1)
        self.assertEqual(await run(),'completed')
        self.assertEqual([len(r) for r in requests],[0]*4)
        self.assertEqual(settled[0],settled[1])

    async def test_bounded_failure_does_not_block_later_question_or_repeat_success(self):
        j=Journal();settled=[]
        for expected in ['continue','continue','retryable']:
            run,_=self.prepare(['ok','invalid','ok'],j,{},settled,budget=1)
            self.assertEqual(await run(),expected)
        self.assertEqual(settled,[])
        run,requests=self.prepare(['ok']*3,j,{'1':1},settled,budget=1)
        self.assertEqual(await run(),'completed')
        self.assertEqual([len(r) for r in requests],[0,1,0])

    async def test_unknown_does_not_dispatch_again_or_finalize(self):
        j=Journal();settled=[]
        run,_=self.prepare(['ok','timeout'],j,{},settled)
        self.assertEqual(await run(),'reconciling')
        run,requests=self.prepare(['ok','ok'],j,{},settled)
        self.assertEqual(await run(),'reconciling');self.assertEqual([len(r) for r in requests],[0,0]);self.assertEqual(settled,[])

    async def test_four_question_completion_and_lost_finish_replay(self):
        j=Journal();settled=[]
        run,requests=self.prepare(['ok']*4,j,{},settled,lost=True)
        with self.assertRaises(Unknown):await run()
        self.assertEqual([len(r) for r in requests],[1]*4)
        run,requests=self.prepare(['ok']*4,j,{},settled)
        self.assertEqual(await run(),'completed');self.assertEqual([len(r) for r in requests],[0]*4)
        self.assertEqual(settled[0],settled[1])

if __name__=='__main__':unittest.main()
