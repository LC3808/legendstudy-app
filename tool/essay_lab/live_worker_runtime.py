"""Guarded local Supabase real JWT/PostgREST worker integration. Synthetic provider only.
Run submit_timing_runtime + status_projection_runtime in a fresh disposable local first.
No production endpoint accepted. No model API called. JSON report contains no IDs/tokens/text.
"""
import json
import contextlib,io
import os
from pathlib import Path
import sys
import uuid
from urllib.request import Request,urlopen
from urllib.error import HTTPError
import psycopg
from psycopg import sql
from . import prepare_l1_client_fixture as fixture
from .live_worker import *


def main():
    # Existing guard verifies explicit consent, numeric loopback, Docker project + DB port.
    with contextlib.redirect_stdout(io.StringIO()):fixture.main()
    cfg=json.loads(Path(os.environ['ESSAY_REVIEW_SUPABASE_STATUS_FILE']).read_text())
    private=json.loads(Path(os.environ['ESSAY_L1_CLIENT_FIXTURE']).read_text())
    checks=[]
    def ok(flag,name):
        assert flag,name;checks.append(name)
    def http(path,body,token):
        r=Request(private['url']+path,data=encoded(body),headers={'apikey':private['anon'],'Authorization':'Bearer '+token,'Content-Type':'application/json'})
        try:
            with urlopen(r,timeout=10) as response:
                raw=response.read();return json.loads(raw) if raw else None
        except HTTPError as error:
            data=json.loads(error.read());raise Invalid(str(data.get('code','HTTP_ERROR'))) from None
    def login(user):return http('/auth/v1/token?grant_type=password',user,private['anon'])['access_token']
    a,b=[login(u) for u in private['users']]
    def rpc(token):return lambda name,args:http('/rest/v1/rpc/'+name,args,token)
    user=rpc(a);other=rpc(b);narrow=rpc(private['worker'])
    def denied(fn,name):
        try:fn()
        except Invalid:checks.append(name);return
        raise AssertionError(name)
    con=psycopg.connect(cfg['DB_URL'],autocommit=True)
    def scalar(query,args=()):return con.execute(query,args).fetchone()[0]
    def submit(session,body):
        rev=scalar('select revision from public.essay_drafts where session_id=%s',(session,))
        rev=user('essay_save_draft',{'p_session':session,'p_revision':rev,'p_body':body,'p_active_seconds':0})
        key=str(uuid.uuid4());args={'p_session':session,'p_revision':rev,'p_body_hash':sha256(body.encode()).hexdigest(),'p_key':key}
        attempt=user('essay_submit_attempt',args);ok(user('essay_submit_attempt',args)==attempt,'submit_idempotent')
        return user('essay_request_evaluation',{'p_attempt':attempt,'p_key':str(uuid.uuid4()),'p_regime':'essay-v1.3'})
    session=user('essay_open_session',{'p_id':str(uuid.uuid4()),'p_question':private['question']})
    def cache_for(e):
        snap=scalar('select input_snapshot from public.essay_evaluations where id=%s',(e,))
        return {'contract_version':'1.3','evidence':[{'binding':v,'text':'합성 공식 요구','text_sha256':sha256('합성 공식 요구'.encode()).hexdigest()} for v in snap['evidence']],
                'criteria':[{'binding':v,'label':'합성 평가 항목'} for v in snap['criteria']]}
    def output(p,state):
        history=p['scaffolding_context']['items'];prior=next((v for v in history if v['issue_key']=='root'),None)
        root={'issue_key':'root','category':'reasoning','status':state,'previous_progress_id':prior['progress_id'] if prior else None,'title':'논리 연결','explanation':'합성 과제 설명','action':'연결을 확인하세요.','priority':1,'claim_scope':'official_criterion','evidence_ids':[private['evidence']]}
        o={'contract_version':'1.3','attempt_id':p['attempt_id'],'answer_hash':p['answer_hash'],'summary':'합성 평가','strengths':['합성 장점'],'checklist':['연결 확인'],'dimensions':[{'criterion_id':v['reference']['id'],'level':4 if state in ['improved','resolved'] else 3,'explanation':'합성 판단','evidence_ids':[private['evidence']]} for v in p['criteria']],
           'improvements':[root],'core_improvement_keys':[] if state=='resolved' else ['root'],'previous_improvement_reviews':[{'previous_progress_id':prior['progress_id'],'outcome':state,'reason':'합성 비교'}] if prior else [],'sentence_feedback':[]}
        return o
    reviewkey=b'local-test-only-no-production-key';facts=[];checkpoints=[]
    def review(e,p,o):
        r={'reviewer':'synthetic-independent','expires_at':int(time.time())+60,'evaluation_id':e,'package_sha256':digest(p),'output_sha256':digest(o),'quality':dict.fromkeys(QUALITY_CHECKS,True),'local_issue_keys':[]}
        r['signature']=hmac.new(reviewkey,encoded(r),'sha256').hexdigest();return r
    class SyntheticProvider:
        synthetic_only=True
        def __init__(self,state):self.state=state
        def evaluate(self,p):
            if self.state=='timeout':raise Unknown()
            if self.state=='failure':raise ProviderFailure()
            o=output(p,self.state if self.state!='bad' else 'open')
            if self.state=='bad':o['dimensions'][0]['evidence_ids']=['fabricated']
            return ProviderResult(json.dumps(o),'synthetic','synthetic-only',10,20,1)
    def worker(e,state):return Worker(narrow,SyntheticProvider(state),cache_for(e),SignedReview({'synthetic-independent':reviewkey}),review,facts.append,checkpoints.append,isolated_fixture=True)
    for i,state in enumerate(['open','improved','resolved','recurred']):
        e=submit(session,'🙂 가가 합성 답안 '+str(i))
        denied(lambda:other('essay_evaluation_status',{'p_evaluation':e}),'other_owner_status_denied')
        w=worker(e,state);ok(w.execute(e)==e,'worker_'+state)
        status=user('essay_evaluation_status',{'p_evaluation':e})
        ok(status['state']=='completed' and status['credit_state']=='settled','atomic_completed_'+state)
        ok(status['credit_mode']==('paid' if i in [0,2] else 'included'),'server_credit_'+state)
        ok(narrow('essay_finalize_success',checkpoints[-1])==e,'finalize_idempotent_'+state)
    timeline=[r[0] for r in con.execute('select p.status from public.essay_improvement_progress p join public.essay_evaluations e on e.id=p.evaluation_id where p.session_id=%s order by e.requested_at',(session,))]
    ok(timeline==['open','improved','resolved','recurred'],'history_preserved')
    for state in ['bad','failure']:
        e=submit(session,'합성 실패 답안 '+state);ok(worker(e,state).execute(e)=='failed','failure_'+state)
        s=user('essay_evaluation_status',{'p_evaluation':e})
        ok(s['state']=='failed' and s['no_credit_consumed'] and s['credit_state']=='released','release_'+state)
        ok(scalar('select count(*) from public.essay_evaluation_dimensions where evaluation_id=%s',(e,))==0,'no_invalid_result_'+state)
    # Existing clock fixture, explicit local only. No sleeping / elapsed-time guess.
    e=submit(session,'합성 timeout 답안');w=worker(e,'timeout');ok(w.execute(e)=='reconciling','worker_timeout')
    ok(user('essay_evaluation_status',{'p_evaluation':e})['state']=='reconciling','authoritative_reconciling')
    def clock(seconds):
        with con.transaction():
            con.execute('grant essay_executor to current_user')
            con.execute(sql.SQL("create or replace function essay_private.clock() returns timestamptz language sql volatile set search_path='' as {} ").format(sql.Literal("select pg_catalog.clock_timestamp()+interval '%s seconds'"%seconds)))
            con.execute('revoke essay_executor from current_user')
    try:
        clock(121)
        ok(worker(e,'improved').execute(e)==e,'retry_new_fence')
        ok(scalar('select count(*) from public.essay_ai_processing_runs where evaluation_id=%s',(e,))==2,'processing_history_not_overwritten')
    finally:clock(0)
    denied(lambda:user('essay_claim',{'p_evaluation':e}),'client_claim_denied')
    denied(lambda:user('essay_finalize_success',checkpoints[-1]),'client_finalize_denied')
    before=scalar('select count(*) from public.credit_transactions')
    user('essay_erase',{'p_session':session})
    ok(scalar('select count(*) from public.credit_transactions')==before,'financial_survives_erasure')
    denied(lambda:narrow('essay_finalize_success',checkpoints[-1]),'erased_job_finalize_denied')
    ok(len(facts)>=4,'sanitized_provider_receipts')
    con.close()
    return {'environment':'LOCAL_SUPABASE','real_auth_jwt':True,'postgrest':True,'provider':'SYNTHETIC','real_ai_calls':0,'checks':checks,'count':len(checks),'runtime':'PASS','db_provider_metadata':'BLOCKED_EXISTING_UNCONFIGURED_CLAIM','production_mutation':False}

if __name__=='__main__':
    print(json.dumps(main(),indent=2))
