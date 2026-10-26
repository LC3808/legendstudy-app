"""Only loopback PostgreSQL; synthetic users. Run after fixture/baseline/apply."""
import subprocess, uuid, concurrent.futures
PSQL=['psql','-X','-U','postgres','-h','127.0.0.1','-p','55439','-d','credit_operations_20261027','-v','ON_ERROR_STOP=1','-Atq']
actor='00000000-0000-4000-8000-000000000001'; user='00000000-0000-4000-8000-000000000002'
setup=f"set test.admin='true';set test.actor='{actor}';"
count=0
def sql(s,ok=True,admin=True):
 p=subprocess.run(PSQL+['-c',setup+("set test.admin='false';" if not admin else '')+s],capture_output=True,text=True)
 if ok and p.returncode: raise AssertionError(p.stderr)
 if not ok and not p.returncode:raise AssertionError('Unexpected success: '+s)
 return p.stdout.strip() if ok else p.stderr

def check(condition,label):
 global count
 assert condition,label
 count+=1;print('PASS',label)
def grant(days='none',kind='admin_grant',date='null',key=None,quantity=100,reason='test'):
 return sql(f"select public.admin_credit_grant_expiring('{user}','student@example.test',{quantity},'{kind}','{days}',{date},'{reason}','{key or uuid.uuid4()}');")
def recover(g,n,key=None,ok=True):
 return sql(f"select public.admin_credit_recover('{user}','{g}',{n},'관리자 오지급: test','{key or uuid.uuid4()}');",ok)
def bal(g):return int(sql(f"select sum(balance_delta) from credit_transactions where grant_id='{g}';"))
def post(g,kind,b,r):sql(f"insert into credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key) select account_id,id,'{kind}',{b},{r},'{uuid.uuid4()}' from credit_grants where id='{g}';")
g=grant();check(sql(f"select expires_at is null from credit_grants where id='{g}'")=='t','indefinite')
k=str(uuid.uuid4());week=grant('7',key=k);check(sql(f"select expires_at between clock_timestamp()+interval '7 days'-interval '10 seconds' and clock_timestamp()+interval '7 days' from credit_grants where id='{week}'")=='t','7 days server time')
check(sql(f"select reason_code::jsonb->>'reason' from credit_transactions where grant_id='{week}'")=='test','reason audit')
check(grant('7',key=k)==week,'grant retry stable expiry')
check('CONFLICT' in sql(f"select public.admin_credit_grant_expiring('{user}','student@example.test',99,'admin_grant','7',null,'test','{k}')",False),'changed payload denied')
custom=grant('custom',date="(current_date+2)::date");check(sql(f"select expires_at=((current_date+2)+time '23:59:59') at time zone 'Asia/Seoul' from credit_grants where id='{custom}'")=='t','KST date end')
check('INVALID_EXPIRY' in sql(f"select public.admin_credit_grant_expiring('{user}','student@example.test',1,'admin_grant','custom',(current_date-1)::date,'test','{uuid.uuid4()}')",False),'past date rejected')
for kind in ['promotion','compensation','other']:check(bool(grant(kind=kind)),kind+' grant')
post(g,'reserve',0,3);post(g,'consume',-3,-3);post(g,'reserve',0,10)
check('RECOVERABLE_BALANCE_CHANGED' in recover(g,88,ok=False),'reserved credits protected')
recover(g,20);check(bal(g)==77,'partial recovery')
key=str(uuid.uuid4());tx=recover(g,67,key);check(bal(g)==10,'remaining unused recovered')
check(recover(g,67,key)==tx and bal(g)==10,'idempotent full retry')
check('CONFLICT' in recover(g,66,key,False),'recovery key payload conflict')
check('RECOVERABLE_BALANCE_CHANGED' in recover(g,1,ok=False),'used/reserved cannot recover')
check(bal(week)==100,'other grant unchanged')
check(sql(f"select public.admin_credit_operation_info('{user}','{g}')->>'recoverable'")=='0','recovery info excludes reserved')
post(g,'consume',-10,-10);check(bal(g)==0,'existing reservation settles after recovery')
expired=sql(f"insert into credit_grants(account_id,origin,external_reference,expires_at) select id,'admin_grant','expired/{uuid.uuid4()}',clock_timestamp()-interval '1 day' from credit_accounts where user_id='{user}' returning id")
check('GRANT_EXPIRED' in sql(f"select public.admin_credit_recover('{user}','{expired}',1,'expired','{uuid.uuid4()}')",False),'expired recovery denied')
check('OPERATOR_REQUIRED' in sql(f"select public.admin_credit_recover('{user}','{custom}',1,'no','{uuid.uuid4()}')",False,False),'nonadmin denied')
check('OPERATOR_REQUIRED' in sql(f"select public.admin_credit_grant_expiring('{user}','student@example.test',1,'admin_grant','none',null,'no','{uuid.uuid4()}')",False,False),'nonadmin grant denied')
check('permission denied' in sql(f"set role anon;select public.admin_credit_operation_info('{user}',null)",False),'anonymous execute denied')
check(sql(f"set role authenticated;select public.admin_credit_operation_info('{user}',null)->>'version'")=='admin-credit-operations-v1','authenticated operator access')
for origin in ['purchase','signup_bonus','b2b_program']:
 other=sql(f"select essay_private.credit_post_grant('{user}',3,'{origin}','fixture/{uuid.uuid4()}','test','system/test',null)")
 check('GRANT_NOT_RECOVERABLE' in recover(other,1,ok=False),origin+' protected')
legacy=sql(f"select admin_manual_credit_grant('{user}','student@example.test',2,'legacy','{uuid.uuid4()}')");check(bal(legacy)==2,'legacy grant preserved')
race_grant=grant()
with concurrent.futures.ThreadPoolExecutor(2) as pool:
 def competing(_):
  p=subprocess.run(PSQL+['-c',setup+f"select public.admin_credit_recover('{user}','{race_grant}',70,'race','{uuid.uuid4()}');"],capture_output=True,text=True);return p.returncode
 results=list(pool.map(competing,range(2)))
check(sum(x==0 for x in results)==1 and bal(race_grant)==30,'concurrent over-recovery prevented')
check('immutable finance row' in sql("update credit_transactions set balance_delta=0",False),'immutable ledger')
print(f'{count} checks passed')
