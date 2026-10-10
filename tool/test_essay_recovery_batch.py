"""Disposable PG17, canonical Math billing/lease recovery plus bounded scheduler."""
import inspect,json
import psycopg
import test_math_persistence as m
R=m.R;V=R/'supabase/verification/essay_service'
M=R/'supabase/migrations/20261010150837_essay_math_recovery_batch.sql'
def cases(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock):
 checks=[]
 def ok(n,b=True):assert b,n;checks.append(n);print(n,'PASS',flush=True)
 c.execute((V/'original-recovery.sql').read_text())
 original=scalar("select md5(pg_get_functiondef('public.math_recover_evaluation(uuid)'::regprocedure))")
 ok('deployed_recovery_fingerprint_exact',original=='5cc017fbbd0ba9ca4602827dd0fbeeeb')
 c.execute(M.read_text())
 def batch(n=20):return rpc('math_recover_expired_evaluations',[n],role='math_evaluation_worker')
 def deny(name,fn):
  try:fn()
  except psycopg.Error as e:
   assert e.sqlstate in ('42501','22023','P0001'),(name,e.sqlstate);ok(name);return
  raise AssertionError(name)
 for role in ['anon','authenticated','service_role','math_extraction_worker']:
  deny('no_batch_'+role,lambda:rpc('math_recover_expired_evaluations',[20],role=role))
 deny('limit_bounded',lambda:batch(51))
 ok('completed_job_untouched',batch()['recovered']==0)
 a=str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic recovery only')]))
 e=str(rpc('math_request_evaluation',[a,new()]))
 ok('active_request_not_recovered',batch()['recovered']==0)
 claim=rpc('math_claim_evaluation',[e],role='math_evaluation_worker')
 ok('active_lease_not_recovered',batch()['recovered']==0)
 c.execute("update public.math_evaluations set lease_until=clock_timestamp()-interval '1 second' where id=%s",(e,))
 before=scalar('select count(*) from public.credit_transactions')
 ok('expired_processing_recovered',batch()['recovered']==1)
 ok('failed_timeout_state',scalar("select state='FAILED' and error_code='TIMEOUT' from public.math_evaluations where id=%s",(e,)))
 after=scalar('select count(*) from public.credit_transactions')
 ok('replay_no_duplicate_settlement',batch()['recovered']==0 and scalar('select count(*) from public.credit_transactions')==after)
 ok('canonical_credit_release',scalar("select d.status from public.essay_billing_decisions d join public.math_billing_bindings b on b.billing_decision_id=d.id where b.math_evaluation_id=%s",(e,))=='released')
 # A completed recovery rejects a late provider result, even with the old lease.
 deny('late_finalize_denied',lambda:rpc('math_finalize_evaluation',[e,claim['lease_token'],out],role='math_evaluation_worker'))
 a2=str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=leaf,kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic queued recovery')]))
 e2=str(rpc('math_request_evaluation',[a2,new()]))
 c.execute("update public.math_evaluations set requested_at=clock_timestamp()-interval '6 minutes' where id=%s",(e2,))
 # A separate transaction holds the canonical first lock. The batch skips it.
 with psycopg.connect(c.info.dsn) as locked:
  locked.execute('select id from public.math_attempts where id=%s for update',(a2,))
  ok('concurrent_attempt_lock_skipped',batch()['scanned']==0)
 ok('expired_unclaimed_request_recovered',batch()['recovered']==1)
 ok('requested_failure_release',scalar("select d.status from public.essay_billing_decisions d join public.math_billing_bindings b on b.billing_decision_id=d.id where b.math_evaluation_id=%s",(e2,))=='released')
 after=scalar('select count(*) from public.credit_transactions')
 # Original RPC and historical completed result remain unchanged by installation/recovery.
 ok('original_recovery_unchanged',scalar("select md5(pg_get_functiondef('public.math_recover_evaluation(uuid)'::regprocedure))")==original)
 ok('completed_result_preserved',rpc('math_evaluation_detail',[ev])['output']==out)
 c.execute((V/'recovery-rollback.sql').read_text())
 ok('rollback_only_batch_removed',scalar("select to_regprocedure('public.math_recover_expired_evaluations(integer)') is null and to_regprocedure('public.math_recover_evaluation(uuid)') is not null"))
 ok('rollback_preserves_credit_facts',scalar('select count(*) from public.credit_transactions')==after)
 (V/'recovery-validation.json').write_text(json.dumps(dict(checks=checks,count=len(checks),production_writes=0,provider_calls=0,scope='isolated PG17 canonical Math lifecycle',credit_transactions_before=before,credit_transactions_after=after),indent=2)+'\n')
 return checks
source=inspect.getsource(m.verify).replace("R/'supabase/verification/math_essay/behavior_validation.json'","V/'recovery-baseline-validation.json'")
ns=dict(m.__dict__);ns.update(V=V,verify_math_cases=cases)
exec(source,ns)
m.h.verify_hqp=ns['verify']
if __name__=='__main__':m.h.main(bootstrap_user='supabase_admin')
