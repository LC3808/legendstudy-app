#!/usr/bin/env python3
"""Full original G1 behavioral contract on installed G1 + payment trigger.
Only fixture setup changes: no G1 reapply; create a v1 fixture with a temporary
session default; old Auth users are explicit. Original behavioral assertions retained.
"""
import sys,inspect,json,uuid
from pathlib import Path
import psycopg
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'supabase/validation/essay_lab_product'))
import g1_runtime as g,test_human_quality as h
s=inspect.getsource(g.cases)
s=s.replace('legacy=session();old=request(submit(legacy));lease=claim(old)',"c.execute(\"alter table public.essay_practice_sessions alter column billing_policy_version set default 'v1'\");legacy=session();c.execute(\"alter table public.essay_practice_sessions alter column billing_policy_version set default 'v2'\");old=request(submit(legacy));lease=claim(old)")
s=s.replace('before=facts();c.execute(MIGRATION.read_text());c.execute("notify pgrst,\'reload schema\'")','before=facts()')
ns=dict(g.__dict__);exec(s,ns)
def verify(c,*args):
 sock=args[-1]
 with psycopg.connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True) as admin:
  c.execute('revoke essay_executor from postgres;grant usage on schema public to postgres')
  admin.execute('grant essay_executor to postgres with admin true,inherit false,set false granted by supabase_admin;alter role postgres nosuperuser createrole bypassrls')
  try:c.execute((R/'supabase/migrations/20261003000100_payment_foundation.sql').read_text())
  finally:c.execute('rollback');admin.execute('alter role postgres superuser')
 def user(old=False):
  u=str(uuid.uuid4());c.execute("insert into auth.users(id,created_at) values(%s,clock_timestamp()-case when %s then interval '10 years' else interval '0' end)",(u,old));c.execute('insert into public.profiles(id) values(%s)',(u,));return u
 A=user(True);B=user(True)
 checks=ns['cases'](c,g.s.native_rpc(c,A),user,A,B)
 (R/'supabase/verification/payments/g1_validation.json').write_text(json.dumps(dict(checks=checks,count=len(checks),fixture_adaptation='preinstalled G1; v1 default fixture; explicit pre-activation Auth; no assertions removed',production_writes=0),indent=2)+'\n')
 print('G1_POST_PAYMENT',len(checks),'PASS')
h.verify_hqp=verify;h.main(bootstrap_user='supabase_admin')
