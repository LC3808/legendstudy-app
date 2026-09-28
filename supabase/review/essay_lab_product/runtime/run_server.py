"""Execute real review RPCs after the existing fail-closed Phase2A regression.
No provider calls. Synthetic data only. SQL-role tests are NOT JWT integration.
"""
import contextlib,io,json,os,uuid,hashlib,time
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from pathlib import Path
import psycopg
from psycopg.types.json import Jsonb
import run as baseline
HERE=Path(__file__).resolve().parent

def main():
    buf=io.StringIO()
    with contextlib.redirect_stdout(buf):
        result=baseline.main(additional_draft=HERE.parent/'003_server_operations.draft.sql')
    if result:return result
    regression=json.loads(buf.getvalue())
    dsn=os.environ['ESSAY_REVIEW_TEST_DSN']
    c=psycopg.connect(dsn,autocommit=True)
    tests=[]
    def ok(condition,name):
        if not condition:raise AssertionError(name)
        tests.append(name)
    def scalar(q,args=()):return c.execute(q,args).fetchone()[0]
    def rpc(name,args=(),user=None,role='authenticated',con=None):
        con=con or c
        with con.transaction():
            con.execute(psycopg.sql.SQL('set local role {}').format(psycopg.sql.Identifier(role)))
            con.execute("select set_config('request.jwt.claim.sub',%s,true)",(str(user or A),))
            return con.execute(psycopg.sql.SQL('select public.{}({})').format(psycopg.sql.Identifier(name),psycopg.sql.SQL(',').join(psycopg.sql.Placeholder() for _ in args)),tuple(Jsonb(x) if isinstance(x,dict) else x for x in args)).fetchone()[0]
    def deny(fn,name,state=None):
        try:fn()
        except psycopg.Error as e:
            if state and e.sqlstate!=state:raise
            ok(True,name);return
        raise AssertionError(name+' was allowed')
    def new():return uuid.uuid4()
    A=new();B=new();Q=baseline.uid(30);C=baseline.uid(32);E=baseline.uid(31)
    c.execute('insert into auth.users(id) values(%s),(%s)',(A,B))
    c.execute('insert into public.profiles(id) values(%s),(%s)',(A,B))
    for i,role in enumerate(['question','passage','exam_intent'],34):
        c.execute("insert into public.essay_exam_resources(essay_exam_id,resource_id,role,provenance,verification_status,verified_at,official_source_url,source_locator,evidence_note,is_active) values(%s,%s,%s,'official','verified',now(),'https://example.edu/fixture','p1','Synthetic',true)",(baseline.uid(21),baseline.uid(12),role))
        c.execute("insert into public.essay_question_evidence(id,question_id,essay_exam_id,resource_id,role,source_locator,mapping_version,source_sha256) values(%s,%s,%s,%s,%s,'p1','v1',%s)",(baseline.uid(i),Q,baseline.uid(21),baseline.uid(12),role,baseline.SHA))
    c.execute("insert into public.essay_question_evidence(id,question_id,essay_exam_id,resource_id,role,source_locator,mapping_version,source_sha256) values(%s,%s,%s,%s,'scoring_criteria','p2','v1',%s)",(baseline.uid(37),baseline.uid(33),baseline.uid(21),baseline.uid(12),baseline.SHA))
    c.execute("insert into public.essay_evaluation_criteria(id,question_id,criterion_key,definition_version,label,description,origin,source_evidence_id,display_order,verified_at) values(%s,%s,'other','v1','Other','Synthetic','official',%s,1,now())",(baseline.uid(38),baseline.uid(33),baseline.uid(37)))
    def grant(user,units,expires=None):
        c.execute('insert into public.credit_accounts(user_id) values(%s) on conflict(user_id) do nothing',(user,))
        acc=scalar('select id from public.credit_accounts where user_id=%s',(user,));g=new()
        c.execute("insert into public.credit_grants(id,account_id,origin,expires_at) values(%s,%s,'admin_grant',%s)",(g,acc,expires))
        c.execute("insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,'admin_grant',%s,0,%s,'synthetic_setup')",(acc,g,units,str(new())))
        return g
    def session(user=None):return rpc('essay_open_session',(new(),Q),user=user)
    def submit(s,body,user=None):
        rev=scalar('select revision from public.essay_drafts where session_id=%s',(s,))
        rev=rpc('essay_save_draft',(s,rev,body),user=user)
        key=new();h=hashlib.sha256(body.encode()).hexdigest()
        return rpc('essay_submit_attempt',(s,rev,key,h),user=user),rev,key,h
    def request(a,user=None,regime='essay-v1.2',key=None):return rpc('essay_request_evaluation',(a,key or new(),regime),user=user)
    def claim(e,rw=None):return rpc('essay_claim',(e,rw),role='essay_worker')
    def output(state='open',previous=None):return {'contract_version':'1.2','summary':'핵심 내용을 이해했습니다.','strengths':['논거를 제시했습니다.'],'checklist':['연결을 확인해 보세요.'],'dimensions':[{'criterion_id':C,'level':3,'explanation':'논거를 연결했습니다.','evidence_ids':[E]}],'improvements':[{'issue_key':'connection','category':'reasoning','status':state,'previous_progress_id':str(previous) if previous else None,'title':'논거 연결','explanation':'다음 판단으로 이어지는 근거를 밝혀 보세요.','action':'연결을 한 문장 보충하세요.','priority':1,'evidence_ids':[E]}]}
    def finish(e,lease,out=None,rw=None):return rpc('essay_finalize_success',(e,lease['run_id'],lease['lease_token'],out or output(),rw),role='essay_worker')
    def status(e):return scalar('select status from public.essay_evaluations where id=%s',(e,))
    def count_consume(e):return scalar("select count(*) from public.credit_transactions t join public.essay_billing_decisions b on b.id=t.decision_id where b.evaluation_id=%s and t.transaction_type='consume'",(e,))
    s=session();rev=rpc('essay_save_draft',(s,1,'Synthetic first answer'))
    ok(rev==2,'T1_draft_CAS')
    deny(lambda:rpc('essay_save_draft',(s,1,'stale')),'T2_stale_CAS','PT409')
    a,rev,key,h=submit(s,'Synthetic submitted answer')
    ok(scalar('select body_sha256 from public.essay_attempts where id=%s',(a,))==h,'T3_submit_hash_count')
    ok(rpc('essay_submit_attempt',(s,rev,key,h))==a,'T4_submit_idempotent')
    deny(lambda:rpc('essay_submit_attempt',(s,rev,key,'b'*64)),'T5_submit_payload_mismatch','PT409')
    deny(lambda:rpc('essay_submit_attempt',(s,rev,new(),h),user=B),'T6_cross_user_submit','PT403')
    grant(A,20)
    ek=new();e=request(a,key=ek)
    ok(scalar('select status from public.essay_billing_decisions where evaluation_id=%s',(e,))=='reserved','T7_paid_reservation')
    ok(request(a,key=ek)==e and request(a)==e,'request_same_payload_and_logical_dedupe')
    a2,_,_,_=submit(s,'Synthetic second answer')
    deny(lambda:request(a2,key=ek),'evaluation_key_payload_mismatch','PT409')
    l=claim(e)
    deny(lambda:claim(e),'active_worker_claim_denied','PT409')
    bad=output();bad['dimensions'][0]['level']=6
    deny(lambda:finish(e,l,bad),'T19_invalid_level','PT422')
    bad=output();bad['dimensions'][0]['criterion_id']=baseline.uid(38)
    deny(lambda:finish(e,l,bad),'T19_invalid_criterion','PT422')
    bad=output();bad['dimensions'][0]['evidence_ids']=[baseline.uid(37)]
    deny(lambda:finish(e,l,bad),'T20_cross_question_evidence','PT422')
    # Fault injection is TEST-ONLY trigger DDL; the RPC has no caller-controlled failure switch.
    c.execute("create function public.essay_test_fault() returns trigger language plpgsql as $$begin raise exception 'synthetic fault';end$$")
    c.execute("create trigger essay_test_fault before insert on public.credit_transactions for each row when(new.transaction_type='consume') execute function public.essay_test_fault()")
    deny(lambda:finish(e,l),'T15_failure_between_result_and_settlement')
    ok(status(e)=='processing' and count_consume(e)==0 and scalar('select count(*) from public.essay_evaluation_dimensions where evaluation_id=%s',(e,))==0,'T15_result_rollback')
    c.execute('drop trigger essay_test_fault on public.credit_transactions')
    c.execute("create trigger essay_test_fault after insert on public.credit_transactions for each row when(new.transaction_type='consume') execute function public.essay_test_fault()")
    deny(lambda:finish(e,l),'T15_failure_after_consume_before_commit')
    ok(status(e)=='processing' and count_consume(e)==0,'T15_consume_rollback')
    c.execute('drop trigger essay_test_fault on public.credit_transactions');c.execute('drop function public.essay_test_fault()')
    finish(e,l)
    ok(status(e)=='completed' and count_consume(e)==1,'T7_atomic_success')
    ok(finish(e,l)==e and count_consume(e)==1,'T16_idempotent_finalize_one_consume')
    p=scalar('select id from public.essay_improvement_progress where evaluation_id=%s',(e,))
    e2=request(a2);ok(scalar('select reason from public.essay_billing_decisions where evaluation_id=%s',(e2,))=='included_revision','T8_included_revision')
    finish(e2,claim(e2),output('improved',p));ok(count_consume(e2)==0,'T8_zero_charge')
    for state in ['resolved','recurred']:
        a3,_,_,_=submit(s,'Synthetic '+state)
        ex=request(a3);p=scalar('select id from public.essay_improvement_progress where evaluation_id=%s',(e2,))
        finish(ex,claim(ex),output(state,p));e2=ex
    states=c.execute('select p.status from public.essay_improvement_progress p join public.essay_evaluations e on e.id=p.evaluation_id where p.session_id=%s order by e.requested_at',(s,)).fetchall()
    ok([x[0] for x in states]==['open','improved','resolved','recurred'],'history_four_states_preserved')
    ealt=request(a,regime='essay-v1.2-next-model');finish(ealt,claim(ealt),dict(output(),improvements=[]))
    ok(scalar('select count(*) from public.essay_evaluations where attempt_id=%s',(a,))==2,'T21_regime_version_coexistence')
    rw=rpc('essay_request_rewrite',(e,));rl=claim(e,rw);finish(e,rl,{'contract_version':'1.2','body':'Synthetic minimal rewrite'},rw)
    ok(rpc('essay_request_rewrite',(e,))==rw and count_consume(e)==1,'rewrite_on_demand_reuse_no_extra_charge')
    # Dedicated worker/finance roles have RPC EXECUTE, no table rights and no executor membership.
    for role in ['authenticated','essay_worker']:
        with c.transaction():
            c.execute(psycopg.sql.SQL('set local role {}').format(psycopg.sql.Identifier(role)))
            deny(lambda:c.execute("update public.essay_attempts set body='forged'"),'worker_client_no_answer_write_'+role,'42501')
        with c.transaction():
            c.execute(psycopg.sql.SQL('set local role {}').format(psycopg.sql.Identifier(role)))
            deny(lambda:c.execute('delete from public.credit_transactions'),'worker_client_no_ledger_delete_'+role,'42501')
    deny(lambda:rpc('essay_claim',(e,)),'client_worker_RPC_denied','42501')
    consume=scalar("select t.id from public.credit_transactions t join public.essay_billing_decisions b on b.id=t.decision_id where b.evaluation_id=%s and t.transaction_type='consume'",(e,))
    rk='refund/'+str(new());refund=rpc('essay_refund',(consume,rk,1),role='essay_finance')
    ok(rpc('essay_refund',(consume,rk,1),role='essay_finance')==refund,'T17_refund_idempotent')
    deny(lambda:rpc('essay_refund',(consume,'refund/'+str(new()),1),role='essay_finance'),'T18_refund_bound','PT409')
    deny(lambda:rpc('essay_refund',(consume,'x',1),role='essay_worker'),'worker_cannot_refund','42501')
    # Test-only clock injection avoids long sleeps; installed RPC clock has no caller/GUC input.
    c.execute("create or replace function essay_private.clock() returns timestamptz language sql volatile set search_path='' as $$select clock_timestamp()+coalesce(nullif(current_setting('essay_test.offset',true),''),'0 seconds')::interval$$")
    def advance(seconds):c.execute("select set_config('essay_test.offset',%s,false)",(str(seconds)+' seconds',))
    sf=session();af,_,_,_=submit(sf,'Synthetic failure');ef=request(af);lf=claim(ef)
    rpc('essay_finalize_failure',(ef,lf['run_id'],lf['lease_token']),role='essay_worker')
    ok(status(ef)=='failed' and count_consume(ef)==0,'T12_failure_release')
    er=request(af);la=claim(er);rpc('essay_timeout',(er,la['run_id'],la['lease_token']),role='essay_worker');advance(121);lb=claim(er)
    deny(lambda:finish(er,la),'T14_stale_worker_after_reclaim','PT409');finish(er,lb)
    ok(count_consume(er)==1 and scalar('select count(*) from public.essay_ai_processing_runs where evaluation_id=%s',(er,))==2,'T13_timeout_retry_success')
    advance(0);sl=session();al,_,_,_=submit(sl,'Synthetic late');el=request(al);ll=claim(el);advance(121);rpc('essay_reconcile',(el,),role='essay_worker')
    deny(lambda:finish(el,ll),'T14_late_success_after_release','PT409')
    ok(status(el)=='cancelled' and count_consume(el)==0,'late_success_no_charge_no_result');advance(0)
    # Included-benefit race invokes actual request RPCs from independent transactions.
    sr=session();ar,_,_,_=submit(sr,'Synthetic paid cycle');ep=request(ar);finish(ep,claim(ep))
    ar2,_,_,_=submit(sr,'Synthetic revision race A');ar3,_,_,_=submit(sr,'Synthetic revision race B')
    barrier=Barrier(2)
    def race(a,user):
        with psycopg.connect(dsn,autocommit=True) as con:
            barrier.wait(timeout=10)
            try:return rpc('essay_request_evaluation',(a,new(),'essay-v1.2'),user=user,con=con)
            except psycopg.Error as ex:return ex.sqlstate
    with ThreadPoolExecutor(2) as pool:rs=list(pool.map(lambda a:race(a,A),[ar2,ar3]))
    ok(all(isinstance(x,uuid.UUID) for x in rs),'T9_both_requests_complete')
    ok(scalar("select count(*) from public.essay_billing_decisions b join public.essay_evaluations e on e.id=b.evaluation_id where e.session_id=%s and b.reason='included_revision'",(sr,))==1,'T9_concurrent_included_claim_one')
    ok(scalar("select count(*) from public.essay_billing_decisions b join public.essay_evaluations e on e.id=b.evaluation_id where e.session_id=%s and b.reason='additional_revision' and b.status='reserved'",(sr,))==1,'T9_other_request_paid_reserved')
    sd=session();ad,_,_,_=submit(sd,'Synthetic duplicate race')
    barrier=Barrier(2)
    with ThreadPoolExecutor(2) as pool:dupes=list(pool.map(lambda a:race(a,A),[ad,ad]))
    ok(all(isinstance(x,uuid.UUID) for x in dupes) and dupes[0]==dupes[1],'RPC_concurrent_same_logical_request')
    ed=dupes[0];finish(ed,claim(ed))
    ok(count_consume(ed)==1,'RPC_concurrent_duplicate_single_consume')
    sb=session(B);ab,_,_,_=submit(sb,'Synthetic B',B)
    deny(lambda:request(ab,user=B),'T10_insufficient_credit','PT402')
    expired=grant(B,1,scalar("select now()-interval '1 second'"))
    deny(lambda:request(ab,user=B),'expired_grant_unusable','PT402')
    expiring=grant(B,1,scalar("select now()+interval '60 seconds'"))
    sb2=session(B);ab2,_,_,_=submit(sb2,'Synthetic B2',B)
    barrier=Barrier(2)
    with ThreadPoolExecutor(2) as pool:rs=list(pool.map(lambda a:race(a,B),[ab,ab2]))
    ok(sum(isinstance(x,uuid.UUID) for x in rs)==1 and rs.count('PT402')==1,'T11_last_credit_one_winner')
    eb=next(x for x in rs if isinstance(x,uuid.UUID));bl=claim(eb);advance(61);finish(eb,bl)
    ok(count_consume(eb)==1,'grant_expired_after_reservation_honored');advance(0)
    se=session();ae,_,_,_=submit(se,'Synthetic erasure during processing');ee=request(ae);le=claim(ee)
    rpc('essay_erase',(se,));deny(lambda:finish(ee,le),'erase_fences_active_worker','PT404')
    ok(scalar("select count(*) from public.essay_billing_decisions where evaluation_id is null and status='released'")>0,'erase_releases_active_reservation')
    rw2=rpc('essay_request_rewrite',(er,));lr2=claim(er,rw2);advance(121);rpc('essay_reconcile',(er,rw2),role='essay_worker')
    deny(lambda:finish(er,lr2,{'contract_version':'1.2','body':'late'},rw2),'rewrite_expired_lease_rejected','PT409');advance(0)
    # Erasure serializes against finalize and leaves financial history as detached audit facts.
    deny(lambda:rpc('essay_erase',(s,),user=B),'T23_other_user_erase','PT403')
    before=scalar('select count(*) from public.credit_transactions')
    rpc('essay_erase',(s,))
    ok(scalar('select count(*) from public.essay_attempts where session_id=%s',(s,))==0,'T22_owner_erasure')
    ok(scalar('select count(*) from public.credit_transactions')==before,'T24_financial_history_preserved')
    ok(scalar('select count(*) from public.essay_billing_decisions where evaluation_id is null')>0,'erasure_detaches_billing')
    # Search-path injection cannot replace the explicitly qualified table references or uid bridge.
    with c.transaction():
        c.execute('create temporary table essay_practice_sessions(id uuid,user_id uuid)')
        c.execute("set local search_path=pg_temp,public")
        deny(lambda:rpc('essay_erase',(sb,),user=A),'search_path_owner_spoof_denied','PT403')
    ok(not scalar("select pg_has_role('essay_worker','essay_executor','member')") and not scalar("select pg_has_role('authenticated','essay_executor','member')"),'executor_not_granted_to_clients_or_worker')
    # Restore the exact production clock body before handing off this disposable DB.
    c.execute("create or replace function essay_private.clock() returns timestamptz language sql volatile set search_path='' as $$select pg_catalog.clock_timestamp()$$")
    print(json.dumps({'server_transactions':'PASS','tests':tests,'phase2a_assertions':len(regression['checks']),'phase2a':'PASS','supabase_integration':'SEPARATE','clock_test':'test-only time source replacement; production clock has no override','actual_ai_calls':0,'tables':19},indent=2))
if __name__=='__main__':raise SystemExit(main())
