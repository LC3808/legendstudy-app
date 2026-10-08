"""Job-scoped runtime adapter over the existing worker; no HTTP listener or new ledger.

Permit and checkpoint are TRUSTED server inputs, never a student/provider request.
Hosting must verify the student's token and ownership before issuing the permit.
Missing provider-bound DB claims, reviewed evidence or independent reviewer fail closed.
No default model, key generation, publication, scheduler or automatic provider retry.
"""
from copy import deepcopy
from dataclasses import dataclass
import time
from urllib.request import build_opener,HTTPRedirectHandler
from .live_worker import ProviderFailure
from .live_worker import Worker, SignedReview, OpenAIResponses, output_schema, digest, provider_binding, require
from .positive_learning import PROMPT, PROMPT_VERSION


@dataclass(frozen=True)
class RuntimePermit:
    evaluation_id: str
    snapshot_sha256: str
    cache_sha256: str
    binding: dict
    expires_at: int
    enabled: bool = False


class ReviewedRuntimeWorker(Worker):
    def __init__(self, *args, permit: RuntimePermit, clock=time.time, **kwargs):
        super().__init__(*args, **kwargs)
        self.permit=deepcopy(permit)
        self.clock=clock

    def authorize(self, evaluation):
        p=self.permit
        require(p.enabled is True and p.evaluation_id==evaluation, 'RUNTIME_GATED')
        require(type(p.expires_at) is int and self.clock()<p.expires_at<=self.clock()+120,
                'RUNTIME_PERMIT_EXPIRED')
        require(not self.isolated_fixture and not getattr(self.provider,'synthetic_only',False),
                'RUNTIME_PROVIDER_REQUIRED')
        require(p.binding.get('provider') not in (None,'unconfigured','synthetic'), 'PROVIDER_BLOCKED')
        require(p.binding==getattr(self.provider,'binding',None), 'ADAPTER_BINDING_MISMATCH')
        require(p.binding.get('prompt_version')==PROMPT_VERSION and getattr(self.provider,'prompt_version',None)==PROMPT_VERSION, 'CURRENT_PROMPT_REQUIRED')
        require(isinstance(self.reviewer,SignedReview) and bool(self.reviewer.keys), 'REVIEWER_BLOCKED')
        require(all(callable(x) for x in [self.review_source,self.receipt_sink,self.checkpoint]),
                'PERSISTENCE_BOUNDARY_REQUIRED')
        require(digest(self.cache)==p.cache_sha256, 'REVIEWED_CACHE_CHANGED')

    def bind_claim(self, claim):
        require(digest(claim['input'])==self.permit.snapshot_sha256, 'SNAPSHOT_CHANGED')
        binding=provider_binding(claim,self.provider)
        require(binding==self.permit.binding, 'PERMIT_BINDING_MISMATCH')
        return binding

    def check_result_identity(self, result):
        require(result.provider==self.permit.binding['provider'], 'RESPONSE_IDENTITY_MISMATCH')
        # Existing telemetry_payload additionally checks model/model_version before persistence.

    def resume_finalization(self, checkpoint):
        """Replay only a durable trusted checkpoint after ambiguous finalize; never regenerate.
        Canonical SQL checks immutable payload hash, run and lease fencing on replay.
        """
        self.authorize(self.permit.evaluation_id)
        require(type(checkpoint) is dict and set(checkpoint)==
                {'p_evaluation','p_run','p_token','p_output'}, 'INVALID_CHECKPOINT')
        require(checkpoint['p_evaluation']==self.permit.evaluation_id, 'FOREIGN_CHECKPOINT')
        return self.rpc('essay_finalize_success',deepcopy(checkpoint))


def dispatch_owned_evaluation(evaluation, user_rpc, worker):
    """user_rpc must use the Auth-verified caller JWT, NEVER the worker credential.
    No evaluation creation, billing or grants here. The existing student RPC enforces RLS.
    Unknown/failed outcomes do not silently become new provider executions.
    """
    state=user_rpc('essay_evaluation_status',{'p_evaluation':evaluation})
    require(type(state) is dict, 'INVALID_STATUS')
    if state.get('state')=='completed':return 'completed'
    if state.get('state')=='reconciling':return 'reconciling'
    if state.get('state')=='failed':return 'failed'
    require(state.get('state')=='processing' and state.get('credit_state') in ('reserved','included'),
            'INVALID_STATUS')
    return worker.execute(evaluation)


class _NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ProviderFailure('PROVIDER_REDIRECT_DENIED')


def _provider_transport(request, timeout):
    require(request.full_url=='https://api.openai.com/v1/responses', 'PROVIDER_ENDPOINT_DENIED')
    return build_opener(_NoRedirect()).open(request,timeout=timeout)


def reviewed_openai(key, binding, **transport_options):
    """Use existing current v3 positive-learning prompt; no fallback to historical v1."""
    require(binding.get('provider')=='openai' and binding.get('prompt_version')==PROMPT_VERSION
            and binding.get('contract_version')=='1.3', 'CURRENT_PROMPT_REQUIRED')
    transport_options.setdefault('transport',_provider_transport)
    provider=OpenAIResponses(key,binding['model'],output_schema(),instructions=PROMPT,
                            prompt_version=PROMPT_VERSION,**transport_options)
    provider.binding=deepcopy(binding)
    return provider
