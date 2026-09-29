"""L2-A2 real local Auth JWT/PostgREST + synthetic bound Worker. No real API.
After provider_runtime --supabase. Existing fixture enforces loopback/container consent.
"""
import contextlib,io,json,os,uuid,hmac,time
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.error import HTTPError
import psycopg
from psycopg import sql
from psycopg.types.json import Jsonb
from . import prepare_l1_client_fixture as fixture
from .live_worker import *

def main():
    with contextlib.redirect_stdout(io.StringIO()):fixture.main()
    cfg=json.loads(Path(os.environ['ESSAY_REVIEW_SUPABASE_STATUS_FILE']).read_text())
    private=json.loads(Path(os.environ['ESSAY_L1_CLIENT_FIXTURE']).read_text());checks=[]
    def ok(x,n):assert x,n;checks.append(n)
    def http(path,body,token,method=None):
        req=Request(private['url']+path,data=encoded(body) if body is not None else None,method=method,headers={'apikey':private['anon'],'Authorization':'Bearer '+token,'Content-Type':'application/json'})
        try:
            with urlopen(req,timeout=20) as response:return json.loads(response.read() or b'null')
        except HTTPError as e:
            code=json.loads(e.read()).get('code','HTTP');raise Invalid(str(code)) from None
    def login(u):return http('/auth/v1/token?grant_type=password',u,private['anon'])['access_token']
    a,b=[login(u) for u in private['users']]
    def rpc(t):return lambda n,args:http('/rest/v1/rpc/'+n,args,t)
    user,other,worker=rpc(a),rpc(b),rpc(private['worker'])
    def deny(fn,n):
        try:fn()
        except Invalid:checks.append(n);return
        raise AssertionError(n+' allowed')
    con=psycopg.connect(cfg['DB_URL'],autocommit=True)
    def scalar(q,args=()):return con.execute(q,args or None).fetchone()[0]
    binding=dict(policy_version='synthetic-v1',provider='synthetic',model='synthetic-only',model_version='fixture-1',prompt_version=PROMPT_VERSION,contract_version='1.3')
    con.execute('grant essay_executor to current_user')
    regime='essay-v1.3/policy/'+scalar('select essay_private.hash(%s::jsonb::text)',(Jsonb(binding),))
    con.execute('revoke essay_executor from current_user')
    def newjob():
        se=user('essay_open_session',{'p_id':str(uuid.uuid4()),'p_question':private['question']})
        body='🙂 합성 답안';rev=user('essay_save_draft',{'p_session':se,'p_revision':scalar('select revision from public.essay_drafts where session_id=%s',(se,)),'p_body':body,'p_active_seconds':0})
        attempt=user('essay_submit_attempt',{'p_session':se,'p_revision':rev,'p_key':str(uuid.uuid4()),'p_body_hash':sha256(body.encode()).hexdigest()})
        request={'p_attempt':attempt,'p_key':str(uuid.uuid4()),'p_regime':regime}
        deny(lambda:user('essay_request_evaluation',dict(request,provider='injected',model='injected')),'client_model_parameter_rejected')
        return se,user('essay_request_evaluation',request)
    se,e=newjob();l=worker('essay_claim',{'p_evaluation':e});base={'p_evaluation':e,'p_run':l['run_id'],'p_token':l['lease_token'],'p_input_tokens':10,'p_output_tokens':20,'p_total_tokens':30,'p_latency_ms':12}
    for k in ['provider','model','prompt','body','raw_response','raw_error','metadata','user_id']:
        deny(lambda:worker('essay_record_provider_telemetry',dict(base,**{k:'injected'})),'no_arbitrary_'+k)
    deny(lambda:user('essay_record_provider_telemetry',base),'owner_no_telemetry');deny(lambda:other('essay_record_provider_telemetry',base),'other_no_telemetry')
    deny(lambda:rpc(private['anon'])('essay_record_provider_telemetry',base),'anon_no_telemetry')
    deny(lambda:worker('essay_claim',{'p_evaluation':e,'p_model':'injected'}),'worker_claim_model_override_denied')
    for token,name in [(a,'owner'),(private['worker'],'worker')]:
        deny(lambda:http('/rest/v1/essay_ai_processing_runs',{'provider':'injected'},token),'no_direct_run_insert_'+name)
        deny(lambda:http('/rest/v1/essay_ai_processing_runs?id=eq.'+l['run_id'],{'input_tokens':99},token,'PATCH'),'no_direct_run_update_'+name)
    ok(worker('essay_record_provider_telemetry',base)==l['run_id'],'JWT_telemetry_success')
    worker('essay_finalize_failure',{k:base[k] for k in ['p_evaluation','p_run','p_token']})
    def cache_for(e):
        snap=scalar('select input_snapshot from public.essay_evaluations where id=%s',(e,))
        return {'contract_version':'1.3','evidence':[{'binding':v,'text':'합성 기준','text_sha256':sha256('합성 기준'.encode()).hexdigest()} for v in snap['evidence']], 'criteria':[{'binding':v,'label':'합성 항목'} for v in snap['criteria']]}
    key=b'local-synthetic-review-only'
    def review(e,p,o):
        r={'reviewer':'independent','expires_at':int(time.time())+60,'evaluation_id':e,'package_sha256':digest(p),'output_sha256':digest(o),'quality':dict.fromkeys(QUALITY_CHECKS,True),'local_issue_keys':[]}
        r['signature']=hmac.new(key,encoded(r),'sha256').hexdigest();return r
    for mode in ['success','timeout','failure','wrong_adapter','wrong_response']:
        se,e=newjob();calls=[]
        class Synthetic:
            synthetic_only=True
            def __init__(self):self.binding=dict(binding,model='wrong') if mode=='wrong_adapter' else binding
            def evaluate(self,p):
                calls.append(True)
                out={'contract_version':'1.3','attempt_id':p['attempt_id'],'answer_hash':p['answer_hash'],'summary':'합성 평가','strengths':[],'checklist':[],'dimensions':[{'criterion_id':v['reference']['id'],'level':3,'explanation':'합성 판단','evidence_ids':[private['evidence']]} for v in p['criteria']],'improvements':[],'core_improvement_keys':[],'previous_improvement_reviews':[],'sentence_feedback':[]}
                result=ProviderResult(json.dumps(out),'synthetic','wrong' if mode=='wrong_response' else 'synthetic-only',10,20,12,30,'fixture-1')
                if mode=='timeout':raise Unknown(usage=result)
                if mode=='failure':raise ProviderFailure(usage=result)
                return result
        w=Worker(worker,Synthetic(),cache_for(e),SignedReview({'independent':key}),review,lambda _:None,lambda _:None,isolated_fixture=True)
        result=w.execute(e);ok(result==(e if mode=='success' else 'reconciling' if mode=='timeout' else 'failed'),'bound_worker_'+mode)
        projection=user('essay_evaluation_status',{'p_evaluation':e})
        ok(projection['state']==('completed' if mode=='success' else 'reconciling' if mode=='timeout' else 'failed'),'post_migration_status_'+mode)
        ok(len(calls)==(0 if mode=='wrong_adapter' else 1),'call_count_'+mode)
        run=con.execute('select provider,model_name,model_version,input_tokens,total_tokens,status from public.essay_ai_processing_runs where evaluation_id=%s',(e,)).fetchone()
        ok(run[:3]==('synthetic','synthetic-only','fixture-1'),'provenance_'+mode)
        ok(run[3:5]==((None,None) if mode.startswith('wrong_') else (10,30)),'usage_'+mode)
        if mode=='timeout':
            user('essay_erase',{'p_session':se})
            ok(scalar('select count(*) from public.essay_ai_processing_runs where evaluation_id=%s',(e,))==0,'erasure_removes_provider_usage')
    con.close()
    print(json.dumps({'checks':checks,'count':len(checks),'runtime':'PASS','real_JWT':True,'postgrest':True,'provider_calls':'SYNTHETIC_ONLY','real_AI_runs':0,'production_apply':False},indent=2))

if __name__=='__main__':main()
