"""Math child adapter for the existing durable Essay parent; no billing RPCs."""
from .live_worker import require


class MixedMathWorker:
    def __init__(self, channel, checkpoint, evaluate):
        self.rpc = channel.call_async
        self.checkpoint = checkpoint
        self.evaluate = evaluate

    async def execute_async(self, evaluation):
        claim = await self.rpc('essay_claim', {'p_evaluation': evaluation})
        args = dict(p_evaluation=evaluation, p_run=claim['run_id'], p_token=claim['lease_token'])
        # Once dispatch may have occurred, uncertainty is durable and never auto-retried.
        try:
            result = await self.evaluate(evaluation)
            if result.get('state')=='failed' and result.get('code')=='INVALID_MATH_OUTPUT':
                usage=result['usage']
                require(all(type(usage.get(k)) is int and usage[k]>=0 for k in
                            ('input_tokens','output_tokens','total_tokens','latency_ms')),'PROVIDER_TELEMETRY_REQUIRED')
                await self.rpc('essay_record_provider_telemetry',args|{'p_'+k:v for k,v in usage.items()})
                return await self.rpc('essay_finalize_failure',args)
            require(type(result) is dict and type(result.get('evaluation')) is dict and
                    result['evaluation'].get('contract_version') == 'math-eval-v1' and
                    isinstance(result['evaluation'].get('summary'), str) and result['evaluation']['summary'],
                    'INVALID_MATH_CHILD_RESULT')
            usage = result['usage']
            require(all(type(usage.get(k)) is int and usage[k] >= 0 for k in
                        ('input_tokens', 'output_tokens', 'total_tokens', 'latency_ms')), 'PROVIDER_TELEMETRY_REQUIRED')
            await self.rpc('essay_record_provider_telemetry', args | {'p_' + k: v for k, v in usage.items()})
            final = args | {'p_output': result['evaluation']}
            await self.checkpoint(final)
            return await self.rpc('essay_finalize_success', final)
        except Exception:
            await self.rpc('essay_timeout', args)
            return 'reconciling'
