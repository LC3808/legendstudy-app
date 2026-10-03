#!/usr/bin/env python3
"""Canonical PG17 disposable chain + unchanged Math C/D/E suites; no network DSN."""
from pathlib import Path
import json,hashlib,concurrent.futures,copy
import psycopg
from psycopg.types.json import Jsonb
import test_account_deletion_ownership as topology
R=Path(__file__).resolve().parents[1];V=R/'supabase/verification/payments';M=R/'supabase/migrations/20261003000100_payment_foundation.sql'
checks=[]
def ok(n,x=True):
 assert x,n
 checks.append(n);print('PAYMENT',n,'PASS',flush=True)
def install(c,admin):
 c.execute('create schema if not exists supabase_migrations;create table if not exists supabase_migrations.schema_migrations(version text primary key)')
 c.execute((V/'catalog.sql').read_text())
 before=topology.snapshot(c);body=M.read_text()
 for marker in ['grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;','grant create on schema public to essay_executor;','set role essay_executor;','grant execute on function public.payment_order(jsonb) to authenticated;','reset role;']:
  try:topology.execute_as_production(c,admin,body.replace(marker,marker+"\ndo $$begin raise exception 'PAYMENT_INJECT';end$$;",1));raise AssertionError('injection missing')
  except psycopg.errors.RaiseException as e:assert e.diag.message_primary=='PAYMENT_INJECT'
  assert topology.snapshot(c)==before
  assert c.execute("select to_regnamespace('payment_private')").fetchone()==(None,)
 ok('bootstrap_failure_restore')
 topology.execute_as_production(c,admin,body)
 c.execute((V/'postflight.sql').read_text())
 ok('catalog_pre_postflight_queries')
 ok('non_superuser_full_apply')
 after=topology.snapshot(c);ok('membership_schema_acl_restored',before[:2]==after[:2])
 old={x[0]:x for x in before[2]};now={x[0]:x for x in after[2]};ok('all_existing_function_bodies_owners_acls_unchanged',all(now[k]==v for k,v in old.items()))
 c.execute('create view public.payment_dependency as select * from public.payment_orders')
 try:topology.execute_as_production(c,admin,(V/'rollback.sql').read_text());raise AssertionError('dependency allowed')
 except psycopg.errors.DependentObjectsStillExist:pass
 ok('rollback_unexpected_dependency_refused',after==topology.snapshot(c))
 c.execute('drop view public.payment_dependency')
 topology.execute_as_production(c,admin,(V/'rollback.sql').read_text())
 ok('empty_install_rollback',topology.snapshot(c)==before)
 topology.execute_as_production(c,admin,body)
 for sig,owner,roles in [('public.payment_order(jsonb)','essay_executor',['authenticated','essay_executor']),('public.payment_process(jsonb)','essay_executor',['essay_executor','essay_finance']),('payment_private.result(uuid)','postgres',['essay_executor','postgres']),('payment_private.spend_guard()','postgres',['postgres'])]:
  a=c.execute("select pg_get_userbyid(proowner),prosecdef,proconfig from pg_proc where oid=%s::regprocedure",(sig,)).fetchone();assert a==(owner,True,['search_path=""']),(sig,a)
  grants=c.execute("select pg_get_userbyid(a.grantee) from pg_proc p cross join lateral aclexplode(proacl) a where oid=%s::regprocedure order by 1",(sig,)).fetchall();assert grants==[(r,) for r in roles],(sig,grants)
 ok('owner_execute_security_search_path')
 for table in ['public.payment_orders','public.payment_operations','public.payment_events','payment_private.configuration']:
  assert c.execute('select relrowsecurity from pg_class where oid=%s::regclass',(table,)).fetchone()==(True,)
  for role in ['anon','authenticated','service_role']:
   assert not c.execute("select has_table_privilege(%s,%s,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE')",(role,table)).fetchone()[0]
 ok('rls_no_client_crud')

def payment_cases(c,rpc,new,scalar,sock):
 U,OTHER,SERVER=[new() for _ in range(3)]
 for u in [U,OTHER,SERVER]:
  c.execute('insert into auth.users(id) values(%s)',(u,));c.execute('insert into public.profiles(id) values(%s)',(u,))
 def order(action='create',uid=U,role='authenticated',**kw):return rpc('payment_order',[dict(dto_version='payment-v1',action=action,**kw)],uid=uid,role=role)
 def process(action,role='essay_finance',**kw):return rpc('payment_process',[dict(dto_version='payment-v1',action=action,**kw)],uid=SERVER,role=role)
 def deny(n,fn):
  try:fn()
  except psycopg.Error as e:
   assert e.sqlstate.startswith('PT') or e.sqlstate in ('42501','23505','23514','22P02'),(n,e.sqlstate,str(e));ok(n);return
  raise AssertionError(n+' allowed')
 def create(sku='10c',**kw):return order(sku=sku,request_key=new(),**kw)
 def start(o,key=None,payment=None):return process('confirm_begin',id=o['id'],request_key=key or new(),payment_key=payment or 'synthetic_'+new(),amount=o['amount'])
 def finish(o,op,paid=None):return process('confirm_finish',id=o['id'],operation_id=op['operation_id'],payment_key=op['payment_key'],amount=o['amount'],paid_at=paid or scalar('select clock_timestamp()').isoformat())
 def paid_order(sku='10c'):
  o=create(sku);op=start(o);result=finish(o,op);return o,op,result
 # Provider-neutral identity storage, with Toss-only executable adapter.
 neutral=[]
 for provider,mode in [('TOSS','TEST'),('APPLE_IAP','TEST'),('GOOGLE_PLAY','TEST'),('TOSS','LIVE')]:
  nid=new();c.execute("insert into public.payment_orders(id,subject_id,request_key,provider,mode,sku,amount,quantity,provider_purchase_id) values(%s,%s,%s,%s,%s,'1c',4900,1,'synthetic_shared_identity')",(nid,U,new(),provider,mode));neutral.append(nid)
 ok('provider_mode_identity_namespace',len(neutral)==4)
 deny('same_provider_mode_purchase_duplicate',lambda:c.execute("insert into public.payment_orders(subject_id,request_key,provider,mode,sku,amount,quantity,provider_purchase_id) values(%s,%s,'APPLE_IAP','TEST','1c',4900,1,'synthetic_shared_identity')",(U,new())))
 deny('unsupported_provider',lambda:c.execute("insert into public.payment_orders(subject_id,request_key,provider,mode,sku,amount,quantity) values(%s,%s,'OTHER','TEST','1c',4900,1)",(U,new())))
 for nid in neutral[1:3]:deny('iap_adapter_not_enabled_'+nid[:0]+str(neutral.index(nid)),lambda nid=nid:process('get',id=nid))
 deny('browser_provider_selection',lambda:create(provider='APPLE_IAP'))
 ok('toss_server_selected',create()['provider']=='TOSS')
 baseline=scalar('select count(*) from public.credit_transactions')
 signup_baseline=scalar("select coalesce(sum(t.balance_delta),0) from public.credit_transactions t join public.credit_grants g on g.id=t.grant_id where g.origin='signup_bonus'")
 for sku,amount,quantity in [('1c',4900,1),('3c',11900,3),('5c',17900,5),('10c',29900,10)]:
  r=create(sku);ok('sku_'+sku,r['amount']==amount and r['quantity']==quantity and r['mode']=='TEST')
 deny('unsupported_sku',lambda:create('20c'));deny('client_amount',lambda:create(amount=1));deny('forged_user',lambda:create(user_id=OTHER));deny('coupon',lambda:create(coupon='free'));deny('anon',lambda:create(role='anon'))
 key=new();o=order(sku='10c',request_key=key);ok('server_order_id',o['order_id'].startswith('ls_') and len(o['order_id'])==35)
 ok('create_retry',order(sku='10c',request_key=key)==o);deny('create_changed',lambda:order(sku='1c',request_key=key))
 deny('foreign_owner',lambda:order(action='get',uid=OTHER,id=o['id']));deny('browser_confirm',lambda:process('get',role='authenticated',id=o['id']));deny('service_role_confirm',lambda:process('get',role='service_role',id=o['id']))
 deny('amount_mismatch',lambda:process('confirm_begin',id=o['id'],request_key=new(),payment_key='synthetic',amount=1))
 op=start(o);ok('authorization_pending',op['state']=='AUTHORIZATION_PENDING' and scalar('select count(*) from public.credit_transactions')==baseline)
 process('outcome',id=o['id'],operation_id=op['operation_id'],outcome='UNKNOWN');ok('unknown_recoverable',process('get',id=o['id'])['operation_state']=='PENDING')
 paid=scalar('select clock_timestamp()').isoformat();result=finish(o,op,paid);ok('test_confirm',result['state']=='PAID' and result['grant_state']=='TEST_RECORDED')
 ok('confirm_retry',finish(o,op,paid)==result);ok('test_no_spendable_credit',scalar('select count(*) from public.credit_transactions')==baseline and scalar("select count(*) from public.payment_orders where mode='TEST' and grant_id is not null")==0)
 ok('test_payment_attributable_credit_zero',scalar("select count(*) from public.credit_transactions t join public.credit_grants g on g.id=t.grant_id where g.origin='purchase' or g.external_reference like 'payment/%' or t.idempotency_key like 'grant/payment/%' or t.actor_reference='system/payment' or exists(select 1 from public.payment_orders o where o.grant_id=g.id)")==0)
 ok('test_signup_lineage_preserved',scalar("select coalesce(sum(t.balance_delta),0) from public.credit_transactions t join public.credit_grants g on g.id=t.grant_id where g.origin='signup_bonus'")==signup_baseline)
 deny('changed_payment_key',lambda:process('confirm_finish',id=o['id'],operation_id=op['operation_id'],payment_key='other',amount=o['amount'],paid_at=paid))
 neworder=create();deny('duplicate_provider_identity',lambda:start(neworder,payment=op['payment_key']))
 failed=create();failop=start(failed);process('outcome',id=failed['id'],operation_id=failop['operation_id'],outcome='REJECTED');ok('provider_failure_no_grant',process('get',id=failed['id'])['grant_state']=='NONE')
 cancelkey=new();cancel=process('cancel_begin',id=o['id'],request_key=cancelkey);ok('test_full_cancel_amount',cancel['operation_amount']==29900)
 process('outcome',id=o['id'],operation_id=cancel['operation_id'],outcome='UNKNOWN');ok('cancel_unknown_fenced',process('get',id=o['id'])['state']=='CANCEL_PENDING')
 cr=process('cancel_finish',id=o['id'],operation_id=cancel['operation_id'],payment_key=op['payment_key'],amount=cancel['operation_amount']);ok('full_cancel',cr['state']=='CANCELLED')
 ok('cancel_retry',process('cancel_finish',id=o['id'],operation_id=cancel['operation_id'],payment_key=op['payment_key'],amount=cancel['operation_amount'])==cr)
 # TEST-only install is enforced by server config; clients cannot choose LIVE.
 deny('client_live_mode',lambda:create(mode='LIVE'))
 # Synthetic local activation ONLY, never emitted as Owner apply instruction.
 c.execute("update payment_private.configuration set mode='LIVE'")
 lo,lp,lr=paid_order();grant=scalar('select grant_id from public.payment_orders where id=%s',(lo['id'],));acct=scalar('select account_id from public.credit_grants where id=%s',(grant,))
 ok('live_one_grant',scalar('select count(*) from public.credit_transactions where grant_id=%s',(grant,))==1)
 ok('expiry_3_calendar_months_utc',scalar("select credit_expires_at=((paid_at at time zone 'UTC'+interval '3 months') at time zone 'UTC') from public.payment_orders where id=%s",(lo['id'],)))
 ok('purchase_lineage',scalar('select origin from public.credit_grants where id=%s',(grant,))=='purchase')
 # Use actual canonical posting checks and per-grant consumed facts; no browser counts.
 for i in range(5):
  decision=new();c.execute("insert into public.essay_billing_decisions(id,account_id,idempotency_key,policy_key,policy_version,reason,credits_required,status) values(%s,%s,%s,'essay_cycle','v2','paid_cycle',1,'authorized')",(decision,acct,new()))
  c.execute("insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,%s,'reserve',0,1,%s,'synthetic')",(acct,grant,decision,new()))
  c.execute("insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,%s,'consume',-1,-1,%s,'synthetic')",(acct,grant,decision,new()))
 ck=new();cc=process('cancel_begin',id=lo['id'],request_key=ck);ok('refund_29900_5_used_5400',cc['operation_amount']==5400 and cc['consumed']==5)
 ok('not_removed_before_provider',scalar('select sum(balance_delta) from public.credit_transactions where grant_id=%s',(grant,))==5)
 # Rejection releases fence without touching balance.
 process('outcome',id=lo['id'],operation_id=cc['operation_id'],outcome='REJECTED');ok('cancel_failure_no_corruption',scalar('select sum(balance_delta) from public.credit_transactions where grant_id=%s',(grant,))==5)
 cc=process('cancel_begin',id=lo['id'],request_key=new());paidparams=dict(id=lo['id'],operation_id=cc['operation_id'],payment_key=lp['payment_key'],amount=5400)
 def concurrent_rpc(action,kwargs):
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as conn:
   with conn.transaction():
    conn.execute("set local role essay_finance;set local statement_timeout='8s'");conn.execute("select set_config('request.jwt.claim.sub',%s,true)",(SERVER,))
    return conn.execute('select public.payment_process(%s)',(Jsonb(dict(dto_version='payment-v1',action=action,**kwargs)),)).fetchone()[0]
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:values=list(pool.map(lambda _:concurrent_rpc('cancel_finish',paidparams),range(4)))
 ok('concurrent_partial_cancel',all(x['state']=='PARTIALLY_CANCELLED' for x in values) and scalar("select count(*) from public.credit_transactions where grant_id=%s and transaction_type='adjustment'",(grant,))==1)
 ok('refunded_grant_zero',scalar('select sum(balance_delta) from public.credit_transactions where grant_id=%s',(grant,))==0)
 co=create('3c');cop=start(co);timestamp=scalar('select clock_timestamp()').isoformat();params=dict(id=co['id'],operation_id=cop['operation_id'],payment_key=cop['payment_key'],amount=co['amount'],paid_at=timestamp)
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:values=list(pool.map(lambda _:concurrent_rpc('confirm_finish',params),range(4)))
 ok('concurrent_confirm_once',all(x['state']=='PAID' for x in values) and scalar('select count(*) from public.credit_transactions where grant_id=(select grant_id from public.payment_orders where id=%s)',(co['id'],))==1)
 # Inject transaction abort after grant: all payment/ledger effects roll back together.
 fo=create('1c');fop=start(fo);before=scalar('select count(*) from public.credit_transactions')
 try:
  with c.transaction():
   finish(fo,fop);c.execute("do $$begin raise exception 'synthetic failure';end$$")
 except psycopg.errors.RaiseException:pass
 ok('grant_transaction_failure_atomic',scalar('select count(*) from public.credit_transactions')==before and process('get',id=fo['id'])['state']=='AUTHORIZATION_PENDING')
 finish(fo,fop);ok('local_failure_retry_recovery')
 # Full LIVE cancellation and unrelated grant balances remain independent.
 otherbalances=scalar("select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t where grant_id not in (select grant_id from public.payment_orders where grant_id is not null)")
 full,fp,fr=paid_order('1c');fc=process('cancel_begin',id=full['id'],request_key=new())
 fullgrant=scalar('select grant_id from public.payment_orders where id=%s',(full['id'],))
 txbefore=scalar('select count(*) from public.credit_transactions')
 try:
  with c.transaction():
   process('cancel_finish',id=full['id'],operation_id=fc['operation_id'],payment_key=fp['payment_key'],amount=4900)
   c.execute("do $$begin raise exception 'cancel failure';end$$")
 except psycopg.errors.RaiseException:pass
 ok('cancel_local_failure_atomic',scalar('select count(*) from public.credit_transactions')==txbefore and process('get',id=full['id'])['state']=='CANCEL_PENDING')
 process('cancel_finish',id=full['id'],operation_id=fc['operation_id'],payment_key=fp['payment_key'],amount=4900)
 ok('full_live_refund',scalar('select sum(balance_delta) from public.credit_transactions where grant_id=%s',(fullgrant,))==0)
 ok('free_and_other_grants_preserved',otherbalances==scalar("select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t where grant_id not in (select grant_id from public.payment_orders where grant_id is not null)"))
 deny('client_refund_amount',lambda:process('cancel_begin',id=co['id'],request_key=new(),amount=1))
 # Canonical account lock serializes refund with existing reserve/consume paths.
 active=create('1c');activeop=start(active);finish(active,activeop)
 ag=scalar('select grant_id from public.payment_orders where id=%s',(active['id'],));aa=scalar('select account_id from public.credit_grants where id=%s',(ag,));bd=new()
 c.execute("insert into public.essay_billing_decisions(id,account_id,idempotency_key,policy_key,policy_version,reason,credits_required,status) values(%s,%s,%s,'essay_cycle','v2','paid_cycle',1,'authorized')",(bd,aa,new()))
 def reserve():c.execute("insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,%s,'reserve',0,1,%s,'synthetic')",(aa,ag,bd,new()))
 reserve();deny('reserved_credit_refund_denied',lambda:process('cancel_begin',id=active['id'],request_key=new()))
 c.execute("insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,%s,'consume',-1,-1,%s,'synthetic')",(aa,ag,bd,new()))
 deny('zero_refund_no_debt',lambda:process('cancel_begin',id=active['id'],request_key=new()))
 # Fence rejects posting while provider cancellation is unknown.
 fenced,ff,fff=paid_order('1c');fg=scalar('select grant_id from public.payment_orders where id=%s',(fenced['id'],));fa=scalar('select account_id from public.credit_grants where id=%s',(fg,))
 fcancel=process('cancel_begin',id=fenced['id'],request_key=new())
 deny('pending_cancel_blocks_posting',lambda:c.execute("insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,'expiration',-1,0,%s,'synthetic')",(fa,fg,new())))
 # Real sessions: duplicate begin requests serialize to one durable operation.
 racing,rr,rrr=paid_order('3c');ckey=new()
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:begins=list(pool.map(lambda _:concurrent_rpc('cancel_begin',dict(id=racing['id'],request_key=ckey)),range(4)))
 ok('concurrent_cancel_begin_once',len({x['operation_id'] for x in begins})==1)
 # Re-confirm and cancel can race after PAID, without issuing another grant.
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
  futures=[pool.submit(concurrent_rpc,'confirm_finish',dict(id=racing['id'],operation_id=rr['operation_id'],payment_key=rr['payment_key'],amount=racing['amount'],paid_at=rrr['paid_at'])),pool.submit(concurrent_rpc,'cancel_finish',dict(id=racing['id'],operation_id=begins[0]['operation_id'],payment_key=rr['payment_key'],amount=racing['amount']))]
  [f.result() for f in futures]
 ok('confirm_cancel_race_no_double_grant',scalar("select count(*) from public.credit_transactions where grant_id=(select grant_id from public.payment_orders where id=%s) and transaction_type='purchase'",(racing['id'],))==1)
 # Existing financial principal may be detached by approved privacy erasure.
 detached,dp,dr=paid_order('1c');dg=scalar('select grant_id from public.payment_orders where id=%s',(detached['id'],));da=scalar('select account_id from public.credit_grants where id=%s',(dg,))
 c.execute('update public.payment_orders set subject_id=null where id=%s',(detached['id'],))
 c.execute('update public.credit_accounts set user_id=null where id=%s',(da,))
 dc=process('cancel_begin',id=detached['id'],request_key=new());process('cancel_finish',id=detached['id'],operation_id=dc['operation_id'],payment_key=dp['payment_key'],amount=4900)
 ok('detached_account_cancellation',scalar('select sum(balance_delta) from public.credit_transactions where grant_id=%s',(dg,))==0)
 c.execute("update payment_private.configuration set mode='TEST'")
 try:c.execute((V/'rollback.sql').read_text());raise AssertionError('data rollback allowed')
 except psycopg.errors.RaiseException:pass
 finally:c.execute('rollback')
 ok('real_history_rollback_refused')
 (V/'validation.json').write_text(json.dumps(dict(checks=checks,count=len(checks),migration_sha256=hashlib.sha256(M.read_bytes()).hexdigest(),production_writes=0,test_provider_calls=0),indent=2)+'\n')

s=(R/'tool/test_math_learning.py').read_text()
s=s.replace(' return old\n',' payment_cases(c,rpc,new,scalar,sock)\n return old\n')
s=s.replace('space=dict(m.__dict__);',"source=source.replace(\" print('MATH_FULL_NON_SUPERUSER_INSTALL_PASS')\",\" payment_install(c,admin)\\n print('MATH_FULL_NON_SUPERUSER_INSTALL_PASS')\")\nspace=dict(m.__dict__);space['payment_install']=install;")
# Existing suites write evidence: preserve original tracked evidence byte-for-byte.
paths=list((R/'supabase/verification').rglob('*.json'));saved={p:p.read_bytes() for p in paths}
try:exec(compile(s,str(R/'tool/test_math_learning.py'),'exec'),dict(__file__=str(R/'tool/test_math_learning.py'),__name__='__main__',payment_cases=payment_cases,install=install))
finally:
 if (V/'validation.json').exists():
  summary={}
  for name,relative in [('math_2c','math_essay/behavior_validation.json'),('math_2d','math_essay/learning/runtime/validation.json'),('math_2e','math_essay/learning/validation.json')]:
   evidence=json.loads((R/'supabase/verification'/relative).read_text())
   summary[name]=evidence
  (V/'regression.json').write_text(json.dumps(summary,indent=2)+'\n')
 for p,v in saved.items():
  if V not in p.parents:p.write_bytes(v)
