#!/usr/bin/env python3
"""Disposable PostgreSQL17 fixture runner. Never contacts Production or an AI provider.
No DSN output. Requires empty dedicated DB on numeric loopback, prefix essay_review_.
Billing concurrency below tests the documented locking protocol, NOT a shipped RPC/API.
"""
import os
import json
import re
from pathlib import Path
from datetime import datetime, timezone, timedelta
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

HERE=Path(__file__).resolve().parent
DRAFT=HERE.parent
ROOT=DRAFT.parents[2]

def uid(n): return f'00000000-0000-0000-0000-{n:012d}'
SHA='a'*64
T=datetime(2026,1,1,tzinfo=timezone.utc)

def main():
    dsn=os.environ.get('ESSAY_REVIEW_TEST_DSN')
    if not dsn or os.environ.get('ESSAY_REVIEW_DISPOSABLE')!='YES':
        print('NOT_RUN: explicit disposable PostgreSQL test environment not configured')
        return 2
    import psycopg
    from psycopg import sql
    from psycopg.conninfo import conninfo_to_dict
    from psycopg.types.json import Jsonb
    cfg=conninfo_to_dict(dsn)
    if cfg.get('host') not in ('127.0.0.1','::1') or cfg.get('hostaddr',cfg.get('host')) not in ('127.0.0.1','::1') or cfg.get('service') or not cfg.get('dbname','').startswith('essay_review_'):
        raise SystemExit('REFUSED: only dedicated essay_review_* DB on numeric loopback')
    c=psycopg.connect(dsn,autocommit=True)
    if c.execute("select current_database() like 'essay_review_%', current_setting('server_version_num')::int>=170000").fetchone()!=(True,True):
        raise SystemExit('REFUSED: dedicated PostgreSQL17+ required')
    if c.execute("select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','auth') and c.relkind in ('r','p','v','m')").fetchone()[0]:
        raise SystemExit('REFUSED: DB must be empty; this runner never drops/resets existing data')
    checks=[]
    def check(ok,name):
        if not ok: raise AssertionError(name)
        checks.append(name)
    def scalar(q,args=()): return c.execute(q,args).fetchone()[0]
    def denied(q,args=(),state=None):
        try:
            with c.transaction(): c.execute(q,args)
        except psycopg.Error as e:
            if state and e.sqlstate!=state: raise
            return
        raise AssertionError('Expected SQL denial')
    def put(table,**values):
        values={k:Jsonb(v) if isinstance(v,dict) else v for k,v in values.items()}
        c.execute(sql.SQL('insert into public.{} ({}) values ({})').format(sql.Identifier(table),sql.SQL(',').join(map(sql.Identifier,values)),sql.SQL(',').join(sql.Placeholder() for _ in values)),list(values.values()))
    def evaluation(n,attempt,regime='r1',contract='1.2',kind='student'):
        put('essay_evaluations',id=uid(n),attempt_id=uid(attempt),session_id=uid(40),question_id=uid(30),idempotency_key=uid(n+10000),request_hash=SHA,request_kind=kind,status='processing',evaluation_version=contract,contract_version=contract,regime_key=regime,evidence_manifest_sha256=SHA,evidence_completeness='complete',requested_at=T+timedelta(days=n-500,minutes=2))
    def decision(n,ev,reason='paid_cycle',credits=1,parent=None):
        put('essay_billing_decisions',id=uid(n),account_id=uid(70),evaluation_id=uid(ev),idempotency_key=uid(n+10000),policy_key='essay_cycle',policy_version='v1',reason=reason,credits_required=credits,status='authorized',included_by_decision_id=uid(parent) if parent else None)
    def posting(n,kind,balance,reserved,decision_id=None,reverse=None):
        put('credit_transactions',id=uid(n),account_id=uid(70),grant_id=uid(71),decision_id=uid(decision_id) if decision_id else None,transaction_type=kind,balance_delta=balance,reserved_delta=reserved,idempotency_key=f'fixture/{n}',reason_code='fixture',reversal_of=uid(reverse) if reverse else None)
    c.execute("""create schema auth;
    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    do $$begin
      if not exists(select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
      if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
      if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role nologin bypassrls; end if;
    end$$;
    grant usage on schema public,auth to anon,authenticated,service_role;
    grant execute on function auth.uid() to anon,authenticated,service_role;
    """)
    for path in [ROOT/'supabase/migrations/20260912000100_initial_content_schema.sql',ROOT/'supabase/migrations/20260927000200_essay_lab_foundation.sql',DRAFT/'001_student_essay_product.draft.sql',DRAFT/'002_entitlements.draft.sql']:
        c.execute(path.read_text())
    check(True,'clean_apply_actual_baselines_plus_review_drafts')
    c.execute('insert into auth.users values (%s),(%s)',(uid(1),uid(2)))
    put('profiles',id=uid(1));put('profiles',id=uid(2))
    put('source_posts',id=uid(10),source='synthetic',external_post_id='fixture',url='https://example.edu/fixture',title='Synthetic')
    put('content_items',id=uid(11),source_post_id=uid(10),source_content_key='fixture',slug='fixture',content_type='university_essay',title='Synthetic',source_url='https://example.edu/fixture',is_active=True)
    put('resources',id=uid(12),content_item_id=uid(11),source_post_id=uid(10),source_resource_key='fixture',title='Synthetic',source_url='https://example.edu/fixture.pdf',is_active=True)
    put('universities',id=uid(20),slug='hanyang',name='Synthetic Hanyang',is_active=True)
    put('essay_exams',id=uid(21),university_id=uid(20),admission_year=2024,exam_key='synthetic',exam_name='Synthetic',exam_kind='admission',provenance='official',verification_status='verified',verified_at=T,official_source_url='https://example.edu/fixture',evidence_note='Synthetic only',is_active=True)
    put('essay_exam_resources',essay_exam_id=uid(21),resource_id=uid(12),role='scoring_criteria',provenance='official',verification_status='verified',verified_at=T,official_source_url='https://example.edu/fixture',source_locator='fixture page 1',evidence_note='Synthetic only',is_active=True)
    put('essay_questions',id=uid(30),essay_exam_id=uid(21),question_key='1',label='Synthetic',display_order=1,metadata_version='v1',is_published=True)
    put('essay_question_evidence',id=uid(31),question_id=uid(30),essay_exam_id=uid(21),resource_id=uid(12),role='scoring_criteria',source_locator='fixture page 1',mapping_version='v1',source_sha256=SHA)
    put('essay_evaluation_criteria',id=uid(32),question_id=uid(30),criterion_key='reasoning',definition_version='v1',label='논리와 구성',description='Synthetic criterion only',origin='official',source_evidence_id=uid(31),display_order=1,verified_at=T)
    put('essay_practice_sessions',id=uid(40),user_id=uid(1),question_id=uid(30))
    put('essay_drafts',session_id=uid(40),body='Synthetic draft',device_class='web_desktop')
    put('essay_improvement_items',id=uid(45),session_id=uid(40),issue_key='local-link',category='reasoning',normalized_issue_key='argument-connection',normalization_version='fixture-v1',normalization_status='reviewed')
    statuses=['open','improved','resolved','recurred','improved']
    for i,level in enumerate([2,3,3,4,4],1):
        put('essay_attempts',id=uid(100+i),session_id=uid(40),attempt_no=i,body=f'Synthetic answer {i}',body_sha256=SHA,input_method='typed',device_class='web_desktop',mode='practice',started_at=T+timedelta(days=i),submitted_at=T+timedelta(days=i,seconds=60),active_writing_seconds=50,character_count=18,count_rule_version='fixture-v1',question_metadata_version='v1',conditions_snapshot={'length_min':10,'length_max':30},submission_key=uid(1100+i))
        evaluation(500+i,100+i)
        put('essay_evaluation_dimensions',id=uid(600+i),evaluation_id=uid(500+i),question_id=uid(30),criterion_id=uid(32),level_1_to_5=level,explanation='Synthetic explanation',display_order=1)
        put('essay_improvement_progress',id=uid(650+i),issue_id=uid(45),previous_progress_id=uid(650+i-1) if i>1 else None,session_id=uid(40),evaluation_id=uid(500+i),status=statuses[i-1],title='Synthetic issue',explanation='Synthetic observation',next_action='Synthetic action',priority=1)
        put('essay_ai_processing_runs',id=uid(700+i),evaluation_id=uid(500+i),run_no=1,provider='synthetic',model_name='X',model_version='fixture-v1',prompt_version='v1',status='completed',selected_result=True,started_at=T+timedelta(days=i,minutes=2),completed_at=T+timedelta(days=i,minutes=3),output_sha256=SHA)
        c.execute("update public.essay_evaluations set status='completed',model_provider='synthetic',model_name='X',model_version='fixture-v1',prompt_version='v1',completed_at=%s,overall_summary='Synthetic result',input_sha256=%s,output_sha256=%s where id=%s",(T+timedelta(days=i,minutes=3),SHA,SHA,uid(500+i)))
    evaluation(520,101,'r2','2','operator_reevaluation')
    put('essay_evaluation_dimensions',evaluation_id=uid(520),question_id=uid(30),criterion_id=uid(32),level_1_to_5=5,explanation='Synthetic v2',display_order=1)
    put('essay_ai_processing_runs',evaluation_id=uid(520),run_no=1,provider='synthetic',model_name='Y',model_version='v2',prompt_version='v2',status='unknown',started_at=T+timedelta(days=20,minutes=2),timed_out_at=T+timedelta(days=20,minutes=3),selected_result=False)
    put('essay_ai_processing_runs',evaluation_id=uid(520),run_no=2,provider='synthetic',model_name='Y',model_version='v2',prompt_version='v2',status='completed',selected_result=True,started_at=T+timedelta(days=20,minutes=3),completed_at=T+timedelta(days=20,minutes=4),output_sha256=SHA)
    c.execute("update public.essay_evaluations set status='completed',model_provider='synthetic',model_name='Y',model_version='v2',prompt_version='v2',completed_at=%s,overall_summary='Synthetic v2',input_sha256=%s,output_sha256=%s where id=%s",(T+timedelta(days=20,minutes=4),SHA,SHA,uid(520)))
    put('essay_generated_rewrites',id=uid(60),evaluation_id=uid(501),status='completed',generation_version='v1',contract_version='1.2',body='Synthetic rewrite',input_sha256=SHA,output_sha256=SHA,created_at=T+timedelta(days=1,minutes=3),completed_at=T+timedelta(days=1,minutes=4))
    put('essay_learning_events',id=uid(61),event_key=uid(161),session_id=uid(40),attempt_id=uid(101),evaluation_id=uid(501),stage_attempt_id=uid(101),learning_stage='first_evaluated',event_type='essay_example_rewrite_viewed',occurred_at=T+timedelta(days=1,minutes=4))
    put('credit_accounts',id=uid(70),user_id=uid(1));put('credit_grants',id=uid(71),account_id=uid(70),origin='promotion')
    posting(800,'promotion',1,0)
    decision(81,501);posting(801,'reserve',0,1,81)
    c.execute("update public.essay_billing_decisions set status='reserved',reserved_at=now() where id=%s",(uid(81),))
    posting(802,'consume',-1,-1,81)
    c.execute("update public.essay_billing_decisions set status='settled',settled_at=now() where id=%s",(uid(81),))
    decision(82,502,'included_revision',0,81)
    c.execute("update public.essay_billing_decisions set status='settled',settled_at=now() where id=%s",(uid(82),))
    check(scalar('select sum(balance_delta) from public.credit_transactions')==0,'one_credit_consumed_once_included_zero')
    posting(803,'refund',1,0,81,802)
    evaluation(530,103,'failure-fixture');decision(83,530);posting(804,'reserve',0,1,83)
    c.execute("update public.essay_billing_decisions set status='reserved',reserved_at=now() where id=%s",(uid(83),))
    c.execute("update public.essay_evaluations set status='failed',error_code='SYNTHETIC' where id=%s",(uid(530),))
    posting(805,'release',0,-1,83)
    c.execute("update public.essay_billing_decisions set status='released',released_at=now() where id=%s",(uid(83),))
    check(scalar('select sum(balance_delta-reserved_delta) from public.credit_transactions')==1,'refund_and_failure_release_history')
    # Owner and cross-owner RLS; table INSERT is denied, authorized submission endpoint is a future gate.
    for user,expected in [(1,1),(2,0)]:
        c.execute('set role authenticated');c.execute("select set_config('request.jwt.claim.sub',%s,false)",(uid(user),))
        for table in ['essay_practice_sessions','essay_drafts','essay_attempts','essay_evaluations','essay_improvement_items','essay_generated_rewrites']:
            check((scalar(f'select count(*) from public.{table}')>0)==bool(expected),f'rls_user{user}_{table}')
        if user==1:
            c.execute("update public.essay_drafts set body='Synthetic saved',revision=revision+1 where session_id=%s",(uid(40),))
            denied("update public.essay_drafts set body='stale' where session_id=%s",(uid(40),))
        if user==2:
            check(c.execute("update public.essay_drafts set body='forbidden',revision=revision+1 where session_id=%s",(uid(40),)).rowcount==0,'other_user_draft_write_denied')
        denied("insert into public.essay_evaluations default values",state='42501')
        denied("update public.essay_attempts set body='forbidden'",state='42501')
        c.execute('reset role')
    c.execute('set role anon');denied('select * from public.essay_attempts',state='42501');c.execute('reset role')
    check(True,'anon_denied_owner_draft_cas_result_write_denied')
    c.execute('set role service_role')
    check(scalar('select count(*) from public.essay_evaluations')>0,'trusted_service_read_grant')
    denied('delete from public.credit_transactions',state='42501')
    c.execute('reset role')
    # Server-side immutable records, CHECK/FK/UNIQUE enforcement.
    denied("update public.essay_attempts set body='overwrite' where id=%s",(uid(101),))
    denied("update public.essay_evaluations set overall_summary='overwrite' where id=%s",(uid(501),))
    denied("update public.essay_evaluation_dimensions set level_1_to_5=4 where id=%s",(uid(601),))
    denied("update public.essay_improvement_progress set status='resolved' where id=%s",(uid(651),))
    denied("update public.essay_ai_processing_runs set model_name='changed' where id=%s",(uid(701),))
    denied("update public.credit_transactions set balance_delta=5 where id=%s",(uid(802),))
    denied("update public.essay_billing_decisions set reason='promotion' where id=%s",(uid(81),))
    denied("update public.credit_grants set expires_at=now() where id=%s",(uid(71),))
    denied("insert into public.essay_practice_sessions(user_id,question_id) values (%s,%s)",(uid(9999),uid(30)),'23503')
    denied("insert into public.essay_drafts(session_id,device_class,revision) values (%s,'invalid',0)",(uid(40),),'23514')
    denied("insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values (%s,%s,%s,'consume',-1,-1,'different-key','fixture')",(uid(70),uid(71),uid(81)),'23505')
    check(True,'immutability_fk_check_unique')
    for k,v in [('user_id',uid(1)),('criterion_id',uid(32)),('regime_key','r1')]: c.execute('select set_config(%s,%s,false)',('essay_review.'+k,v))
    queries=re.split(r'-- Q\d+:', (DRAFT/'history_queries.sql').read_text())[1:]
    results=[]
    for q in queries:
        # Remove title remainder; each block contains one SQL statement and optional comments.
        stmt=q.split('\n',1)[1]
        results.append(c.execute(stmt).fetchall())
    check(len(results)==12,'all_12_history_queries_execute')
    check([row[3] for row in results[3]]==[2,3,3,4,4],'comparable_growth_2_3_3_4_4')
    check([row[5] for row in results[2]][:4]==['open','improved','resolved','recurred'],'all_four_issue_states_retained')
    check(scalar('select count(*) from public.essay_evaluations where attempt_id=%s',(uid(101),))==2,'same_attempt_versions_coexist')
    check(len(results[5])==1 and results[5][0][3:5]==(2,3),'included_revision_improvement_query')
    check(len(results[9])==1,'failed_no_charge_query')
    # One-time correction annotation preserves original result; erasure detaches only predecessor.
    c.execute("update public.essay_evaluations set invalidated_at=now(),invalidation_reason='Synthetic correction' where id=%s",(uid(520),))
    denied("update public.essay_evaluations set invalidation_reason='changed' where id=%s",(uid(520),))
    c.execute('delete from public.essay_attempts where id=%s',(uid(101),))
    check(scalar('select count(*) from public.essay_improvement_progress')==4,'erasing_predecessor_preserves_later_observations')
    check(scalar('select previous_progress_id from public.essay_improvement_progress where id=%s',(uid(652),)) is None,'erasure_detaches_predecessor')
    check(scalar('select count(*) from public.credit_transactions')==6,'financial_ledger_survives_answer_erasure')
    # Concurrency tests use REAL separate PostgreSQL transactions and the explicit reference lock protocol.
    # Test A: separate request UUIDs for the same attempt/regime resolve to one student request by partial UNIQUE.
    gate=Barrier(2)
    def request(n):
        with psycopg.connect(dsn) as con:
            gate.wait()
            con.execute("insert into public.essay_evaluations(id,attempt_id,session_id,question_id,idempotency_key,request_hash,evaluation_version,contract_version,regime_key,evidence_manifest_sha256,evidence_completeness) values (%s,%s,%s,%s,%s,%s,'test','test','concurrent',%s,'complete') on conflict do nothing",(uid(n),uid(105),uid(40),uid(30),uid(n+10000),SHA,SHA))
    with ThreadPoolExecutor(2) as pool: list(pool.map(request,[900,901]))
    check(scalar("select count(*) from public.essay_evaluations where regime_key='concurrent'")==1,'concurrent_duplicate_logical_request')
    # Test B: two different paid commands compete for the last unit. Lock account before reading balance.
    gate=Barrier(2)
    def consume(n):
        with psycopg.connect(dsn) as con:
            gate.wait()
            con.execute('select id from public.credit_accounts where id=%s for update',(uid(70),))
            available=con.execute('select coalesce(sum(balance_delta-reserved_delta),0) from public.credit_transactions where account_id=%s',(uid(70),)).fetchone()[0]
            if available<1:return False
            con.execute("insert into public.essay_billing_decisions(id,account_id,idempotency_key,policy_key,policy_version,reason,credits_required,status) values(%s,%s,%s,'fixture','v1','additional_revision',1,'authorized')",(uid(n),uid(70),uid(n+10000)))
            for kind,b,rsv in [('reserve',0,1),('consume',-1,-1)]:
                con.execute("insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,%s,%s,%s,%s,%s,'fixture')",(uid(70),uid(71),uid(n),kind,b,rsv,f'concurrent/{n}/{kind}'))
            con.execute("update public.essay_billing_decisions set status='settled',settled_at=now() where id=%s",(uid(n),))
            return True
    with ThreadPoolExecutor(2) as pool: wins=list(pool.map(consume,[910,911]))
    check(sum(wins)==1,'concurrent_distinct_requests_one_credit_one_winner')
    check(scalar('select sum(balance_delta-reserved_delta) from public.credit_transactions')==0,'no_negative_balance_with_reference_protocol')
    c.execute('delete from public.essay_ai_processing_runs where evaluation_id=%s',(uid(503),))
    check(scalar('select model_name from public.essay_evaluations where id=%s',(uid(503),))=='X','evaluation_model_context_survives_ops_retention')
    # Independent event erasure does not erase attempts/evaluations. Then full user erasure retains financial facts.
    before=scalar('select count(*) from public.essay_attempts');c.execute('delete from public.essay_learning_events')
    check(scalar('select count(*) from public.essay_attempts')==before,'behavior_retention_independent')
    c.execute('delete from public.profiles where id=%s',(uid(1),))
    check(scalar('select count(*) from public.essay_attempts')==0 and scalar('select count(*) from public.essay_evaluations')==0,'private_learning_cascade')
    check(scalar('select count(*) from public.credit_transactions')>0 and scalar('select user_id from public.credit_accounts where id=%s',(uid(70),)) is None,'financial_retention_boundary')
    print(json.dumps({'runtime':'PASS','checks':checks,'limitations':['Auth stub, not full Supabase/PostgREST integration','Billing uses test reference transactions, production RPC not implemented','Submission endpoint and narrow worker permission E2E remain gates']},indent=2))
    return 0

if __name__=='__main__':
    raise SystemExit(main())
