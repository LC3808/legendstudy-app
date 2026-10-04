from pathlib import Path
import sys,inspect,uuid
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'supabase/validation/essay_lab_product'))
import g1_runtime as g

def verify(c):
 def user(old=False):
  u=str(uuid.uuid4());c.execute("insert into auth.users(id,created_at) values(%s,clock_timestamp()-case when %s then interval '10 years' else interval '0' end)",(u,old));c.execute('insert into public.profiles(id) values(%s)',(u,));return u
 A=user(True);B=user(True)
 source=inspect.getsource(g.cases).split(' # Real pre-migration session')[0].replace('def cases(', 'def runtime_cases(')
 source += '''
 c.execute("update payment_private.configuration set mode='LIVE'")
 U=make_user(True)
 def pay(action,**kw):return rpc('payment_process',[dict(dto_version='payment-v1',action=action,**kw)],role='essay_finance')
 def summary():return rpc('credit_summary',[],user=U)
 o=rpc('payment_order',[dict(dto_version='payment-v1',action='create',sku='5c',request_key=uid())],user=U)
 op=pay('confirm_begin',id=o['id'],request_key=uid(),payment_key='synthetic_runtime',amount=17900)
 pay('confirm_finish',id=o['id'],operation_id=op['operation_id'],payment_key='synthetic_runtime',amount=17900,paid_at=scalar('select clock_timestamp()').isoformat())
 ok(summary()['spendable']==5 and summary()['paid']==5 and summary()['free']==0,'P09_shared_canonical_purchase_5')
 se=session(U);finish(request(submit(se,U),user=U));ok(summary()['spendable']==4,'P10_real_evaluation_5_to_4')
 finish(request(submit(se,U),user=U));ok(summary()['spendable']==4,'P11_included_reevaluation_no_deduction')
 finish(request(submit(session(U),U),user=U));ok(summary()['spendable']==3,'P12_new_answer_4_to_3')
 p=dict(dto_version='payment-v1',action='inspect',id=o['id'],operator_id=A,request_key=uid())
 preview=rpc('payment_support',[p],role='essay_finance')
 ok(preview['used']==2 and preview['refund_amount']==8100 and preview['eligible'],'P18_support_preview_17900_2_used_8100')
 ok(rpc('payment_support',[p],role='essay_finance')==preview,'support_inspect_idempotent')
 deny(lambda:rpc('payment_support',[dict(p,id=uid())],role='authenticated'),'support_browser_denied')
 deny(lambda:rpc('payment_support',[p],role='service_role'),'support_service_role_denied')
 deny(lambda:rpc('credit_summary',[],role='anon'),'balance_anon_denied')
 ok(rpc('credit_summary',[],user=B)['paid']==0,'balance_foreign_not_exposed')
 op=pay('cancel_begin',id=o['id'],request_key=uid());ok(summary()['spendable']==0,'cancel_pending_not_spendable')
 pay('cancel_finish',id=o['id'],operation_id=op['operation_id'],payment_key='synthetic_runtime',amount=8100)
 ok(summary()['spendable']==0,'cancelled_purchase_no_credit')
 for sig,allowed in [('public.credit_summary()','authenticated'),('public.payment_support(jsonb)','essay_finance'),('public.payment_compensate(jsonb)','essay_finance')]:
  for role in ['anon','authenticated','service_role','essay_finance']:
   ok(scalar("select has_function_privilege(%s,%s,'EXECUTE')",(role,sig))==(role==allowed),'runtime_acl_'+sig+'_'+role)
 # Same canonical pending purchase, then account detached before provider-local posting.
 o2=rpc('payment_order',[dict(dto_version='payment-v1',action='create',sku='1c',request_key=uid())],user=U)
 op2=pay('confirm_begin',id=o2['id'],request_key=uid(),payment_key='synthetic_compensation',amount=4900)
 body=dict(dto_version='payment-v1',id=o2['id'],request_key=uid(),payment_key='synthetic_compensation',amount=4900,paid_at=scalar('select clock_timestamp()').isoformat())
 deny(lambda:rpc('payment_compensate',[body],role='essay_finance'),'active_account_compensation_denied')
 deny(lambda:rpc('payment_compensate',[body],role='authenticated'),'browser_compensation_denied')
 before=scalar('select count(*) from public.credit_transactions')
 c.execute('update public.payment_orders set subject_id=null where id=%s',(o2['id'],))
 inspected=rpc('payment_support',[dict(dto_version='payment-v1',action='reconcile',id=o2['id'],operator_id=A,request_key=uid())],role='essay_finance')
 ok(inspected['compensation_required'],'restricted_paid_support_recovery_detected')
 result=rpc('payment_compensate',[body],role='essay_finance')
 ok(result['state']=='CANCEL_PENDING' and result['grant_state']=='NONE','restricted_purchase_full_refund_claim_no_grant')
 ok(rpc('payment_compensate',[body],role='essay_finance')==result,'compensation_claim_retry_once')
 pending=pay('get',id=o2['id'])
 pay('cancel_finish',id=o2['id'],operation_id=pending['operation_id'],payment_key='synthetic_compensation',amount=4900)
 ok(scalar('select count(*) from public.credit_transactions')==before,'compensation_cancel_no_ledger_effect')
 # Original grant expiry is immutable; isolate expiry behavior using a separate synthetic expired grant.
 expired=uid();account=scalar('select id from public.credit_accounts where user_id=%s',(U,))
 c.execute("insert into public.credit_grants(id,account_id,origin,expires_at) values(%s,%s,'admin_grant',clock_timestamp()-interval '1 day')",(expired,account))
 c.execute("insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,'admin_grant',2,0,%s,'synthetic')",(account,expired,uid()))
 ok(summary()['spendable']==0,'expired_grant_excluded_from_shared_balance')
 free_user=make_user(True)
 # Pre-existing signup entitlement fixture; ADR benefit issuance remains independently gated.
 c.execute("select essay_private.credit_post_grant(%s,3,'signup_bonus',%s,'signup_bonus_v1','system/signup_bonus',null)",(free_user,'signup_bonus/'+free_user))
 free=rpc('credit_summary',[],user=free_user)
 ok(free['free']==3 and free['paid']==0 and free['next_expiry'] is None,'free_signup_forever_no_purchase_inference')
 deny(lambda:rpc('payment_support',[dict(p,action='cancel')],role='essay_finance'),'support_request_semantics_conflict')
 try:c.execute((ROOT/'supabase/verification/payments/runtime_rollback.sql').read_text());raise AssertionError('rollback accepted audit history')
 except psycopg.errors.RaiseException:c.execute('rollback');ok(True,'support_history_rollback_refused')
 return checks
'''
 scope=dict(g.__dict__);exec(source,scope)
 return scope['runtime_cases'](c,g.s.native_rpc(c,A),user,A,B)
