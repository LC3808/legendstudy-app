#!/usr/bin/env python3
"""Disposable PG only: existing payment/math regressions plus mixed-mode candidate."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
V=R/'supabase/verification/payments/live-20261104'
def live_cases(c,rpc,new,scalar,sock):
 import psycopg
 from test_account_deletion_ownership import execute_as_production
 checks=[]
 def ok(name,condition):
  assert condition,name
  checks.append(name);print('LIVE_CANDIDATE',name,'PASS',flush=True)
 review='ddc5ae63-acbb-490b-a423-c996b811dea8';buyer=new();gateway=new()
 c.execute('alter table auth.users add column if not exists email text')
 c.execute('alter table auth.users add column if not exists email_confirmed_at timestamptz')
 for u,email in [(review,'review@legendstudy.com'),(buyer,'buyer@example.com'),(gateway,'gateway@example.com')]:
  c.execute('insert into auth.users(id,email,email_confirmed_at) values(%s,%s,now())',(u,email));c.execute('insert into public.profiles(id) values(%s)',(u,))
 c.execute("update payment_private.configuration set mode='TEST'")
 def order(u,sku='1c',key=None):return rpc('payment_order',[dict(dto_version='payment-v1',action='create',sku=sku,request_key=key or new())],uid=u)
 def process(action,**kw):return rpc('payment_process',[dict(dto_version='payment-v1',action=action,**kw)],role='essay_finance',uid=gateway)
 legacy=order(buyer)
 before=scalar('select jsonb_agg(to_jsonb(o) order by id) from public.payment_orders o')
 with psycopg.connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True) as admin:
  execute_as_production(c,admin,(V/'prepare.sql').read_text())
 ok('prepare_keeps_test_configuration',scalar('select mode from payment_private.configuration')=='TEST')
 ok('prepare_preserves_all_order_rows',before==scalar('select jsonb_agg(to_jsonb(o) order by id) from public.payment_orders o'))
 c.execute((V/'activate.sql').read_text())
 ok('review_uid_email_test',order(review)['mode']=='TEST')
 ok('ordinary_buyer_live',order(buyer)['mode']=='LIVE')
 c.execute("update auth.users set email='changed@example.com' where id=%s",(review,))
 ok('changed_review_email_live',order(review)['mode']=='LIVE')
 c.execute("update auth.users set email='review@legendstudy.com' where id=%s",(buyer,))
 ok('same_email_different_uid_live',order(buyer)['mode']=='LIVE')
 c.execute("update auth.users set email='review@legendstudy.com',email_confirmed_at=null where id=%s",(review,))
 ok('unconfirmed_review_live',order(review)['mode']=='LIVE')
 c.execute('update auth.users set email_confirmed_at=now() where id=%s',(review,))
 for mode,o in [('legacy_TEST',legacy),('review_TEST',order(review)),('LIVE',order(buyer,'3c'))]:
  key=new();pk='synthetic_'+new();op=process('confirm_begin',id=o['id'],request_key=key,payment_key=pk,amount=o['amount']);paid=scalar('select clock_timestamp()').isoformat()
  body=dict(id=o['id'],operation_id=op['operation_id'],payment_key=pk,amount=o['amount'],paid_at=paid)
  r=process('confirm_finish',**body);process('confirm_finish',**body)
  grants=scalar('select count(*) from public.credit_grants where external_reference=%s',('payment/'+o['id'],))
  ok(mode+'_one_grant_or_test_zero',grants==(1 if mode=='LIVE' else 0))
  ok(mode+'_record_state',r['grant_state']==('POSTED' if mode=='LIVE' else 'TEST_RECORDED'))
  if mode=='LIVE':ok('live_quantity_matches_ledger',scalar('select sum(balance_delta) from public.credit_transactions where grant_id=(select grant_id from public.payment_orders where id=%s)',(o['id'],))==3)
  op=process('cancel_begin',id=o['id'],request_key=new());body=dict(id=o['id'],operation_id=op['operation_id'],payment_key=pk,amount=o['amount'])
  process('cancel_finish',**body);process('cancel_finish',**body)
  ok(mode+'_cancel_idempotent',scalar("select count(*) from public.credit_transactions where idempotency_key=%s",('payment_cancel/'+op['operation_id'],))==(1 if mode=='LIVE' else 0))
 for role in ['anon','authenticated','service_role','essay_finance']:
  ok('private_helper_denied_'+role,not scalar("select has_function_privilege(%s,'payment_private.current_order_mode()','EXECUTE')",(role,)))
 (V/'validation.json').write_text(json.dumps({'checks':checks,'production_writes':0,'provider_calls':0},indent=2)+'\n')

saved={p:p.read_bytes() for p in (R/'supabase/verification').rglob('*.json')}
s=(R/'tool/test_payment_foundation.py').read_text().replace(' checks.extend(verify(c))',' checks.extend(verify(c))\n live_cases(c,rpc,new,scalar,sock)')
s=s.replace("payment_cases=payment_cases,install=install)","payment_cases=payment_cases,install=install,live_cases=live_cases)")
try:exec(compile(s,str(R/'tool/test_payment_foundation.py'),'exec'),{'__file__':str(R/'tool/test_payment_foundation.py'),'__name__':'__main__','live_cases':live_cases})
finally:
 for p,b in saved.items():p.write_bytes(b)
