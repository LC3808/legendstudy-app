#!/usr/bin/env python3
"""ADR-2 disposable PG17 regression. No network DSN accepted; synthetic fixtures only."""
import sys,uuid,json,datetime,concurrent.futures
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import test_human_quality as h
import psycopg
from psycopg.types.json import Jsonb

def verify(c,rpc,new,scalar,first,second,zero,A,B,OP,session,previous,args,sock):
 for version in ['20260913000200','20260914000100','20260914000200','20260923000100','20260926000100','20260930000100','20260917000200']:
  c.execute(next((h.R/'supabase/migrations').glob(version+'_*.sql')).read_text())
 c.execute("alter table auth.users add column email_confirmed_at timestamptz default now()") # Auth-only verified-email shim; no fake Essay schema.
 c.execute((h.R/'supabase/migrations/20261001000200_human_quality_persistence.sql').read_text())
 oldql=scalar("select jsonb_agg(jsonb_build_array(p.oid,pg_get_functiondef(p.oid),p.proacl::text) order by p.oid) from pg_proc p where pronamespace='public'::regnamespace and proname like 'ql_%'")
 oldacls=scalar("select jsonb_object_agg(c.oid::text,jsonb_build_array(c.relowner,array(select a::text from unnest(coalesce(c.relacl,acldefault('r',c.relowner))) a where a::text !~ '^account_erasure_executor=' order by 1)::text,c.relrowsecurity)) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r'")
 oldexec=scalar("select jsonb_object_agg(p.oid::text,jsonb_build_array(p.proowner,p.proacl::text)) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','essay_private')")
 oldpolicies=scalar("select jsonb_agg(to_jsonb(p) order by schemaname,tablename,policyname) from pg_policies p")
 # Exact prior function bodies for a dependency-safe rollback package.
 restore_signatures=['public.is_quality_operator()', 'essay_private.uid()', 'essay_private.owner(uuid)', 'essay_private.lock_job(uuid)', 'essay_private.credit_profile_signup()', 'public.essay_claim_signup_credit()', 'essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)', 'public.fetch_own_mock_attempt(uuid)', 'public.submit_mock_attempt(uuid,uuid,uuid,uuid,text,jsonb)']
 originals=[scalar('select pg_get_functiondef(%s::regprocedure)',(name,)) for name in restore_signatures]
 # Prior function definitions are compared after bounded rollback below.
 # More real canonical fixtures: a queued reservation and a second student's evaluation.
 import hashlib
 question=str(scalar('select question_id from public.essay_evaluations where id=%s',(first,)))
 criterion=str(scalar('select id from public.essay_evaluation_criteria where question_id=%s limit 1',(question,)))
 evidence=str(scalar("select id from public.essay_question_evidence where question_id=%s and role='scoring_criteria' limit 1",(question,)))
 rpc('essay_admin_grant',[A,3,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 def new_evaluation(user,complete):
  se=str(rpc('essay_open_session',[new(),question],uid=user));body='Synthetic canonical answer.'
  rev=rpc('essay_save_draft',[se,scalar('select revision from public.essay_drafts where session_id=%s',(se,)),body,'web_desktop','practice',0],uid=user)
  at=str(rpc('essay_submit_attempt',[se,rev,new(),hashlib.sha256(body.encode()).hexdigest()],uid=user))
  ev=str(rpc('essay_request_evaluation',[at,new(),'essay-v1.3'],uid=user))
  if complete:
   cl=rpc('essay_claim',[ev],role='essay_worker')
   out={'contract_version':'1.3','attempt_id':at,'answer_hash':hashlib.sha256(body.encode()).hexdigest(),'summary':'Synthetic summary','strengths':['Concept application works because it connects the criterion.'],'checklist':['Reuse reasoning'],'dimensions':[{'criterion_id':criterion,'level':4,'explanation':'Synthetic criterion','evidence_ids':[evidence]}],'improvements':[],'core_improvement_keys':[],'previous_improvement_reviews':[],'sentence_feedback':[],'local_reviews':[]}
   rpc('essay_finalize_success',[ev,cl['run_id'],cl['lease_token'],out],role='essay_worker')
  return ev
 queued=new_evaluation(A,False);other=new_evaluation(B,True)
 decision=str(scalar('select id from public.essay_billing_decisions where evaluation_id=%s',(queued,)))
 c.execute('insert into public.quality_operators(user_id) values(%s)',(A,))
 def review(ev,reviewer):
  detail=rpc('ql_case_detail',[ev],uid=OP)
  rubric={k:'OK' for k in ['diagnosis','core_priority','actionability','evidence_adherence','stance_preservation','hallucination_absence']}
  rubric.update(sentence_feedback='NA',progression='NA',generated_rewrite='NA')
  p={'dto_version':'hq-write-v1','evaluation_id':ev,'expected_output_sha256':detail['provenance']['output_sha256'],'client_submission_id':new(),'rubric_version':'hq-rubric-v1','overall_disposition':'PASS_WITH_NOTES','rubric_result':rubric,'findings':[{'issue_category':'OTHER','severity':'MINOR','target_kind':'OVERALL','target_ref':None,'note':'Synthetic note'}],'official_source_reviewed':True}
  return str(rpc('ql_submit_human_judgment',[p],uid=reviewer)['judgment_id'])
 j_subject=review(zero,OP);j_reviewer=review(other,A)
 settled_before=scalar("select count(*) from public.credit_transactions where transaction_type='consume'")
 fb=str(scalar("insert into public.feedback_submissions(user_id,category,title,body,app_version,build_number,platform,os_version) values(%s,'inquiry','Synthetic','Synthetic feedback','1','1','web','test') returning id",(A,)))

 c.execute((h.R/'supabase/migrations/20261001000300_account_deletion_lifecycle.sql').read_text())
 if ROLLBACK_ONLY:
  c.execute('create view public.adr2_test_dependency as select * from public.account_deletion_requests')
  try:
   c.execute((h.R/'supabase/verification/account_deletion/rollback.sql').read_text())
   raise AssertionError('unexpected dependency removed')
  except psycopg.errors.DependentObjectsStillExist:
   c.execute('rollback');c.execute('drop view public.adr2_test_dependency');print('ROLLBACK_DEPENDENCY_REFUSED')
  c.execute((h.R/'supabase/verification/account_deletion/rollback.sql').read_text());assert scalar("select to_regnamespace('account_private')") is None;assert oldpolicies==scalar("select jsonb_agg(to_jsonb(p) order by schemaname,tablename,policyname) from pg_policies p");assert oldql==scalar("select jsonb_agg(jsonb_build_array(p.oid,pg_get_functiondef(p.oid),p.proacl::text) order by p.oid) from pg_proc p where pronamespace='public'::regnamespace and proname like 'ql_%'");assert originals==[scalar('select pg_get_functiondef(%s::regprocedure)',(name,)) for name in restore_signatures];print('ROLLBACK_CANONICAL_PRESERVATION_PASS');print('ROLLBACK_PASS');return
 checks=[]
 def ok(n,v=True):assert v,n;checks.append(n);print(n,'PASS',flush=True)
 def deny(n,fn):
  try:fn()
  except psycopg.Error as error:
   security_names={'ordinary_internal_reauth','worker_client_deny','D7_old_token','D14_mock_read','D14_mock_submit','D15','D16','D17','D18_HQP','D22','D27','D28','D51'}
   if n in security_names or n.startswith('anon_'):assert error.sqlstate=='42501',(n,error.sqlstate)
   ok(n);return
  raise AssertionError(n+' unexpectedly allowed')
 ok('apply')
 ok('existing_table_acl_owner_rls',all(scalar("select jsonb_build_array(relowner,array(select a::text from unnest(coalesce(relacl,acldefault('r',relowner))) a where a::text !~ '^account_erasure_executor=' order by 1)::text,relrowsecurity) from pg_class where oid=%s::oid",(oid,))==value for oid,value in oldacls.items()))
 ok('existing_function_acl_owner',all(scalar('select jsonb_build_array(proowner,proacl::text) from pg_proc where oid=%s::oid',(oid,))==value for oid,value in oldexec.items()))
 ok('new_rpc_definer_search_path',scalar("select bool_and(prosecdef and pg_get_userbyid(proowner)='postgres' and proconfig @> array['search_path=\"\"']) from pg_proc where pronamespace='public'::regnamespace and proname like 'account_%'"))
 deny('ordinary_internal_reauth',lambda:rpc('account_reauth_attest',[A,new()],uid=A))

 deny('activation_default_off',lambda:rpc('account_deletion_request',uid=A))
 ok('inactive_worker',rpc('account_deletion_claim',[5],role='account_lifecycle_worker')==[])
 c.execute('update account_private.dispatch_health set enabled=true')
 ok('D69_D70_D71',oldql==scalar("select jsonb_agg(jsonb_build_array(p.oid,pg_get_functiondef(p.oid),p.proacl::text) order by p.oid) from pg_proc p where pronamespace='public'::regnamespace and proname like 'ql_%'"))
 ok('D66_policies',oldpolicies==scalar("select jsonb_agg(to_jsonb(p) order by schemaname,tablename,policyname) from pg_policies p where policyname<>'account_lifecycle_restriction'"))
 for name in ['account_deletion_request','account_deletion_status','account_deletion_cancel']:
  deny('anon_'+name,lambda n=name:rpc(n,uid=None,role='anon'))
 deny('forged_target_signature',lambda:rpc('account_deletion_request',[B],uid=A))
 req=rpc('account_deletion_request',uid=A);rid=req['request_id']
 ok('D1',req['state']=='DELETION_PENDING')
 ok('D2',scalar("select scheduled_deletion_at=requested_at+interval '336 hours' from public.account_deletion_requests where id=%s",(rid,)))
 ok('D3_D4',rpc('account_deletion_request',uid=A)==req)
 deny('D7_old_token',lambda:rpc('account_deletion_cancel',uid=A))
 sid=new();rpc('account_reauth_attest',[A,sid],role='account_lifecycle_worker')
 deny('reauth_wrong_session',lambda:rpc('account_deletion_cancel',uid=A,extra={'session_id':new()}))
 c.execute("update account_private.reauth_tickets set verified_at=now()-interval '10 minutes',expires_at=now()-interval '5 minutes' where subject_id=%s",(A,))
 deny('reauth_stale',lambda:rpc('account_deletion_cancel',uid=A,extra={'session_id':sid}))
 rpc('account_reauth_attest',[B,sid],role='account_lifecycle_worker')
 deny('reauth_wrong_subject',lambda:rpc('account_deletion_cancel',uid=A,extra={'session_id':sid}))
 ok('login_does_not_cancel',rpc('account_deletion_status',uid=A)['state']=='DELETION_PENDING')
 rpc('account_reauth_attest',[A,sid],role='account_lifecycle_worker')
 ok('D7',rpc('account_deletion_cancel',uid=A,extra={'session_id':sid})['state']=='CANCELLED')
 unbound=rpc('account_deletion_unbound',[100],role='account_lifecycle_worker')
 ok('restore_cancelled_unbound',any(x['request_id']==rid and x['state']=='CANCELLED' for x in unbound))
 rpc('account_deletion_bind',[rid,Jsonb([{'version':'test','marker':'f'*64}]),'test','f'*64],role='account_lifecycle_worker')
 ok('cancelled_no_admission_block_recreated',scalar('select count(*) from account_private.lifecycle_identity_blocks where request_id=%s',(rid,))==0)
 manifest=rpc('account_deletion_restore_manifest',role='account_lifecycle_worker')
 cancelled=next(x for x in manifest if x['request_id']==rid)
 ok('restore_cancelled_manifest',cancelled['state']=='CANCELLED' and cancelled['cancelled_at'] is not None and cancelled['requested_at'] is not None)
 ok('cancel_expiry_exact',scalar("select expires_at=cancelled_at+interval '720 hours' from public.account_deletion_requests where id=%s",(rid,)))

 ok('D20',rpc('account_service_allowed',uid=A))
 req2=rpc('account_deletion_request',uid=A);ok('D5_D6',req2['request_id']!=rid)
 deny('D11',lambda:c.execute('update public.account_deletion_requests set scheduled_deletion_at=scheduled_deletion_at+interval \'1 hour\' where id=%s',(req2['request_id'],)))
 deny('D14_mock_read',lambda:rpc('fetch_own_mock_attempt',[new()],uid=A))
 deny('D14_mock_submit',lambda:rpc('submit_mock_attempt',[new(),None,new(),None,'mcq5-v1',Jsonb([])],uid=A))
 deny('D17',lambda:rpc('essay_claim_signup_credit',uid=A))
 deny('D16',lambda:rpc('essay_request_rewrite',[first],uid=A))
 deny('D15',lambda:rpc('essay_request_evaluation',[str(scalar('select attempt_id from public.essay_evaluations where id=%s',(first,))),new(),'essay-v1.3'],uid=A))
 deny('D28',lambda:rpc('essay_claim',[first],role='essay_worker'))
 deny('D27',lambda:rpc('essay_finalize_success',[first,new(),new(),{}],role='essay_worker'))
 deny('D22',lambda:c.execute("update public.profiles set grade_level=3 where id=%s",(A,)))
 with c.transaction():
  c.execute('set local role authenticated');c.execute("select set_config('request.jwt.claim.sub',%s,true)",(A,))
  ok('D14_pending_read',scalar('select count(*) from public.profiles where id=%s',(A,))==0)
 ok('D19',scalar('select count(*) from public.resources')>0)
 rpc('account_deletion_request',uid=OP);ok('D18',not rpc('is_quality_operator',uid=OP))
 deny('D18_HQP',lambda:rpc('ql_review_state',[[]],uid=OP))
 for role in ['anon','authenticated','service_role']:
  ok('acl_'+role,not scalar("select has_table_privilege(%s,'public.account_deletion_requests','SELECT')",(role,)))
 deny('worker_client_deny',lambda:rpc('account_deletion_claim',[5],uid=A))
 # synthetic past request: no production timestamp override is added
 U=new();c.execute('insert into auth.users(id) values(%s)',(U,));c.execute('insert into public.profiles(id) values(%s)',(U,))
 pid=scalar("insert into public.account_deletion_requests(subject_id,requested_at,scheduled_deletion_at) values(%s,statement_timestamp()-interval '337 hours',statement_timestamp()-interval '1 hour') returning id",(U,))
 jobs=rpc('account_deletion_claim',[5],role='account_lifecycle_worker');job=next(x for x in jobs if x['request_id']==str(pid))
 rpc('account_deletion_capture_result',[str(pid),'NOT_AVAILABLE'],role='account_lifecycle_worker')
 ok('I3_no_identity_capture_metadata',scalar("select benefit_capture_state='NOT_AVAILABLE' from public.account_deletion_requests where id=%s",(pid,)))
 ok('D54',job['phase']=='PERSONAL');ok('D55',rpc('account_deletion_claim',[5],role='account_lifecycle_worker')==[])
 deny('D8_D9',lambda:rpc('account_deletion_cancel',uid=U))
 rpc('account_deletion_personal',[str(pid),job['lease_token']],role='account_lifecycle_worker');ok('personal')
 for phase in ['STORAGE','PROVIDER','FINANCE']:rpc('account_deletion_advance',[str(pid),job['lease_token'],phase],role='account_lifecycle_worker')
 deny('D38_auth_last',lambda:rpc('account_deletion_advance',[str(pid),job['lease_token'],'AUTH'],role='account_lifecycle_worker'))
 c.execute('delete from auth.users where id=%s',(U,))
 rpc('account_deletion_advance',[str(pid),job['lease_token'],'AUTH'],role='account_lifecycle_worker')
 rpc('account_deletion_finish',[str(pid),job['lease_token']],role='account_lifecycle_worker')
 ok('D60_D62',scalar("select subject_id is null and state='ERASED' and expires_at=completed_at+interval '720 hours' from public.account_deletion_requests where id=%s",(pid,)))
 ok('provider_unknown_local_erased',scalar("select state='ERASED' and not provider_verified and error_code='PROVIDER_EXTERNAL_GATE' from public.account_deletion_requests where id=%s",(pid,)))
 # Benefit grant using existing ledger, no profile-time grant coupling.
 V,W=new(),new()
 for u in [V,W]:c.execute('insert into auth.users(id) values(%s)',(u,));c.execute('insert into public.profiles(id) values(%s)',(u,))
 ok('benefit_recovery_candidates',V in rpc('account_benefit_candidates',[100],role='account_lifecycle_worker'))
 ok('D45_D46',scalar('select count(*) from public.credit_accounts where user_id=%s',(V,))==0)
 m=[{'version':'synthetic-v1','marker':'a'*64}]
 result=rpc('account_benefit_claim',[V,Jsonb(m)],role='account_lifecycle_worker')
 ok('D47_D72',result['state']=='GRANTED')
 rpc('account_benefit_claim',[V,Jsonb(m)],role='account_lifecycle_worker')
 ok('D42_client_recovery',rpc('essay_claim_signup_credit',uid=V) is not None)
 ok('D42',scalar("select count(*) from public.credit_grants g join public.credit_accounts a on a.id=g.account_id where a.user_id=%s and g.origin='signup_bonus'",(V,))==1)
 ok('D43',rpc('account_benefit_claim',[W,Jsonb(m)],role='account_lifecycle_worker')['state']=='PREVIOUSLY_CLAIMED')
 deny('D51',lambda:rpc('account_benefit_claim',[W,Jsonb(m)],uid=W))
 deny('null_marker_no_grant',lambda:rpc('account_benefit_claim',[W,None],role='account_lifecycle_worker'))
 # Concurrent connections race on one new verified marker across two accounts.
 X,Y=new(),new()
 for u in [X,Y]:c.execute('insert into auth.users(id) values(%s)',(u,));c.execute('insert into public.profiles(id) values(%s)',(u,))
 def claim(u):
  with psycopg.connect(host=str(sock),port=5432,user='postgres',dbname='postgres',autocommit=True) as x:
   x.execute('set role account_lifecycle_worker')
   return x.execute('select public.account_benefit_claim(%s,%s)',(u,Jsonb([{'version':'synthetic-v1','marker':'b'*64}]))).fetchone()[0]['state']
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:res=list(pool.map(claim,[X,Y]))
 ok('D44',sorted(res)==['GRANTED','PREVIOUSLY_CLAIMED'])
 # Cancelled history must allow final Auth FK identity erasure, not block it.
 # A is both student and reviewer. Replace only the synthetic future request with a due fixture.
 c.execute('delete from public.account_deletion_requests where id=%s',(req2['request_id'],))
 dueA=scalar("insert into public.account_deletion_requests(subject_id,requested_at,scheduled_deletion_at) values(%s,statement_timestamp()-interval '337 hours',statement_timestamp()-interval '1 hour') returning id",(A,))
 ajob=next(x for x in rpc('account_deletion_claim',[5],role='account_lifecycle_worker') if x['request_id']==str(dueA))
 rpc('account_deletion_personal',[str(dueA),ajob['lease_token']],role='account_lifecycle_worker')
 rpc('account_deletion_personal',[str(dueA),ajob['lease_token']],role='account_lifecycle_worker')
 ok('D23_D24_D25',scalar("select count(*) from public.credit_transactions where decision_id=%s and transaction_type='release'",(decision,))==1)
 ok('D26_D68',scalar("select count(*) from public.credit_transactions where transaction_type='consume'")==settled_before)
 ok('D30',scalar('select count(*) from public.human_quality_judgments where id=%s',(j_subject,))==0)
 ok('D30_findings',scalar('select count(*) from public.human_quality_findings where judgment_id=%s',(j_subject,))==0)
 ok('D32_D33_D34',scalar('select count(*) from public.feedback_submissions where id=%s',(fb,))==0 and scalar('select count(*) from public.feedback_notifications where feedback_id=%s',(fb,))==0)
 finance_before=scalar("select md5(string_agg((to_jsonb(t)-array['idempotency_key','actor_reference'])::text,'|' order by id)) from public.credit_transactions t")
 for ph in ['STORAGE','PROVIDER','FINANCE']:rpc('account_deletion_advance',[str(dueA),ajob['lease_token'],ph],role='account_lifecycle_worker')
 ok('finance_economic_integrity',finance_before==scalar("select md5(string_agg((to_jsonb(t)-array['idempotency_key','actor_reference'])::text,'|' order by id)) from public.credit_transactions t"))
 ok('finance_embedded_uuid_removed',scalar('select count(*) from public.credit_grants where external_reference=%s',('signup_bonus/'+A,))==0 and scalar('select count(*) from public.credit_transactions where idempotency_key=%s',('grant/signup_bonus/'+A,))==0)
 c.execute('delete from auth.users where id=%s',(A,))
 ok('D31',scalar('select reviewer_user_id is null from public.human_quality_judgments where id=%s',(j_reviewer,)))
 ok('D31_findings',scalar('select count(*) from public.human_quality_findings where judgment_id=%s',(j_reviewer,))==1)
 rpc('account_deletion_advance',[str(dueA),ajob['lease_token'],'AUTH'],role='account_lifecycle_worker')
 rpc('account_deletion_provider_result',[str(dueA),ajob['lease_token'],True],role='account_lifecycle_worker')
 rpc('account_deletion_finish',[str(dueA),ajob['lease_token']],role='account_lifecycle_worker')
 ok('student_and_reviewer_completion',scalar("select state='ERASED' and subject_id is null from public.account_deletion_requests where id=%s",(dueA,)))
 ok('cancelled_FK_detach',scalar('select subject_id is null from public.account_deletion_requests where id=%s',(rid,)))
 ok('D21_deleted_token',not rpc('account_service_allowed',uid=A))
 # Owner P-03: absent historical evidence after lawful erasure is accepted promotional risk.
 rejoin,unrelated=new(),new()
 for user in [rejoin,unrelated]:
  c.execute('insert into auth.users(id) values(%s)',(user,));c.execute('insert into public.profiles(id) values(%s)',(user,))
 ok('I8_rejoin_creation_allowed',scalar('select count(*) from auth.users where id=%s',(rejoin,))==1)
 ok('I7_temporary_current_failure_no_grant',rpc('essay_claim_signup_credit',uid=rejoin) is None)
 ok('I7_absent_historical_marker_normal_eligibility',rpc('account_benefit_claim',[rejoin,Jsonb([{'version':'synthetic-v1','marker':'c'*64}])],role='account_lifecycle_worker')['state']=='GRANTED')
 ok('I7_no_global_hold',rpc('account_benefit_claim',[unrelated,Jsonb([{'version':'synthetic-v1','marker':'d'*64}])],role='account_lifecycle_worker')['state']=='GRANTED')
 known=new();c.execute('insert into auth.users(id) values(%s)',(known,));c.execute('insert into public.profiles(id) values(%s)',(known,))
 ok('I7_known_prior_claim_still_denied',rpc('account_benefit_claim',[known,Jsonb(m)],role='account_lifecycle_worker')['state']=='PREVIOUSLY_CLAIMED')

 ok('D61',scalar("select count(*) from information_schema.columns where table_schema='public' and table_name='account_deletion_requests' and column_name in ('email','answer','evaluation_hash','oauth_id')")==0)
 ok('D63',rpc('account_deletion_maintenance',role='account_lifecycle_worker')['purged']==0)
 # Server credential boundaries: no direct private facts, no browser worker/secret path.
 for table in ['benefit_claims','benefit_delivery','reauth_tickets','lifecycle_identity_blocks','restore_tags','dispatch_health']:
  for role in ['anon','authenticated','service_role']:
   ok('private_acl_'+table+'_'+role,not scalar("select has_table_privilege(%s,%s,'SELECT,INSERT,UPDATE,DELETE')",(role,'account_private.'+table)))
 ok('D48_D49_D52',scalar("select count(*) from information_schema.columns where table_schema='account_private' and table_name='benefit_claims' and column_name in ('email','user_id','subject_id','evaluation_id','grant_id')")==0)
 # Real clock fixtures for overdue recovery and lease expiry; no exposed clock override.
 Z=new();c.execute('insert into auth.users(id) values(%s)',(Z,));c.execute('insert into public.profiles(id) values(%s)',(Z,))
 expired=scalar("insert into public.account_deletion_requests(subject_id,requested_at,scheduled_deletion_at,state,lease_token,lease_until) values(%s,statement_timestamp()-interval '338 hours',statement_timestamp()-interval '2 hours','ERASING',gen_random_uuid(),statement_timestamp()-interval '1 minute') returning id",(Z,))
 claimed=rpc('account_deletion_claim',[5],role='account_lifecycle_worker');zjob=next(x for x in claimed if x['request_id']==str(expired));ok('D56_D59',bool(zjob['lease_token']))
 deny('D55_stale_fence',lambda:rpc('account_deletion_personal',[str(expired),new()],role='account_lifecycle_worker'))
 rpc('account_deletion_retry',[str(expired),zjob['lease_token'],'TRANSPORT_UNAVAILABLE'],role='account_lifecycle_worker')
 ok('D12_D58',scalar("select state='ERASING' and retry_count=1 and scheduled_deletion_at=requested_at+interval '336 hours' from public.account_deletion_requests where id=%s",(expired,)))
 ok('D64_watchdog',rpc('account_deletion_maintenance',role='account_lifecycle_worker')['overdue']>=1)
 # Expired receipts and purge failure are distinct from active erasure retry.
 er=scalar("insert into public.account_deletion_requests(requested_at,scheduled_deletion_at,state,phase,completed_at,expires_at) values(statement_timestamp()-interval '1200 hours',statement_timestamp()-interval '864 hours','ERASED','DONE',statement_timestamp()-interval '721 hours',statement_timestamp()-interval '1 hour') returning id")
 try:
  with c.transaction():
   c.execute('set transaction read only');c.execute('set local role account_lifecycle_worker');c.execute('select public.account_deletion_maintenance()')
  raise AssertionError('read-only purge unexpectedly passed')
 except psycopg.errors.ReadOnlySqlTransaction:ok('D64_purge_failure_visible',rpc('account_deletion_health',role='account_lifecycle_worker')['expired_receipts']==1)
 ok('D63_actual_purge',rpc('account_deletion_maintenance',role='account_lifecycle_worker')['purged']==1)
 ok('D63_repeat',rpc('account_deletion_maintenance',role='account_lifecycle_worker')['purged']==0)
 # Real two-connection cancellation/claim race at an already reached deadline.
 C=new();c.execute('insert into auth.users(id) values(%s)',(C,));c.execute('insert into public.profiles(id) values(%s)',(C,))
 cid=scalar("insert into public.account_deletion_requests(subject_id,requested_at,scheduled_deletion_at) values(%s,statement_timestamp()-interval '336 hours',statement_timestamp()) returning id",(C,))
 def race(which):
  with psycopg.connect(host=str(sock),port=5432,user='postgres',dbname='postgres',autocommit=True) as x:
   x.execute("set statement_timeout='5s'")
   if which=='claim':x.execute('set role account_lifecycle_worker');return x.execute('select public.account_deletion_claim(20)').fetchone()[0]
   x.execute('set role authenticated');x.execute("select set_config('request.jwt.claim.sub',%s,false)",(C,))
   try:x.execute('select public.account_deletion_cancel()');return 'cancelled'
   except psycopg.Error as e:return e.sqlstate
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:raced=list(pool.map(race,['claim','cancel']))
 ok('D10_cancel_denied',raced[1]=='22023')
 rpc('account_deletion_claim',[20],role='account_lifecycle_worker')
 ok('D10',scalar('select state from public.account_deletion_requests where id=%s',(cid,))=='ERASING')
 # Actual erase/grant race: target lock precedes account/grant row locks.
 c.execute("update public.account_deletion_requests set next_attempt_at=statement_timestamp()-interval '1 minute' where id=%s",(expired,))
 zjob=next(x for x in rpc('account_deletion_claim',[20],role='account_lifecycle_worker') if x['request_id']==str(expired))
 def erase_grant(which):
  with psycopg.connect(host=str(sock),port=5432,user='postgres',dbname='postgres',autocommit=True) as x:
   x.execute("set statement_timeout='5s'")
   if which=='erase':
    x.execute('set role account_lifecycle_worker');x.execute('select public.account_deletion_personal(%s,%s)',(str(expired),zjob['lease_token']));return 'erased'
   x.execute('set role essay_finance');x.execute("select set_config('request.jwt.claim.sub',%s,false)",(X,))
   try:x.execute("select public.essay_admin_grant(%s,1,'admin_grant',%s,'test_account',null)",(Z,new()));return 'granted'
   except psycopg.Error as e:return e.sqlstate
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(erase_grant,['erase','grant']))
 ok('D29',results==['erased','42501'])
 # Rollback must refuse an active or historical lifecycle, preserving all data.
 try:
  c.execute((h.R/'supabase/verification/account_deletion/rollback.sql').read_text())
  raise AssertionError('unsafe rollback allowed')
 except psycopg.Error:
  c.execute('rollback');ok('rollback_data_refused')

 print('CHECKS',len(checks))
ROLLBACK_ONLY='--rollback-probe' in sys.argv
if ROLLBACK_ONLY:sys.argv.remove('--rollback-probe')
h.verify_hqp=verify
h.main()
