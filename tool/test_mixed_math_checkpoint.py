"""Control-flow only; no student answers, Provider transport or financial RPC."""
import unittest
from copy import deepcopy
from tool.essay_lab.async_exam import execute_async_exam
from tool.essay_lab.mixed_math_runtime import MixedMathWorker

class Journal:
    def __init__(self):self.values={}
    async def read(self,key):return deepcopy(self.values.get(key))
    async def begin(self,key):self.values.setdefault(key,dict(state='pending'))
    async def write(self,key,value):self.values[key]=dict(state='checkpoint',payload=deepcopy(value))

class MixedCheckpointTests(unittest.IsolatedAsyncioTestCase):
    async def run_case(self,fail=False):
        calls=[];settled=[];journal=Journal()
        async def evaluate(evaluation):
            calls.append(evaluation)
            if fail:raise TimeoutError('transport')
            return dict(evaluation=dict(contract_version='math-eval-v1',summary='schema-only'),
                usage=dict(input_tokens=0,output_tokens=0,total_tokens=0,latency_ms=0,cost_amount=None,currency='USD'))
        async def finalize(record):settled.append(record);return 'completed'
        async def invoke():
            return await execute_async_exam(questions=[dict(questionId='question',rubricVersion='pin',evidenceVersion='pin',
                evaluationId='child',claim=dict(run_id='existing-parent',lease_token='existing-lease'),criteria=[])],
                journal=journal,build_worker=lambda channel,checkpoint:MixedMathWorker(channel,checkpoint,evaluate),finalize=finalize)
        first=await invoke();second=await invoke()
        self.assertEqual(calls,['child'])
        return first,second,settled

    async def test_completed_child_is_replayed_without_evaluation(self):
        first,second,settled=await self.run_case()
        self.assertEqual((first,second),('completed','completed'))
        self.assertEqual(settled[0],settled[1])

    async def test_ambiguous_dispatch_is_not_retried_or_settled(self):
        first,second,settled=await self.run_case(True)
        self.assertEqual((first,second),('reconciling','reconciling'))
        self.assertEqual(settled,[])

if __name__=='__main__':unittest.main()
