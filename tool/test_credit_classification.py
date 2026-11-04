"""Disposable localhost PostgreSQL only; never accepts a hosted DSN."""
import json, os, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
PG=Path('/opt/homebrew/opt/postgresql@17/bin')
SOURCE=ROOT/'supabase/candidates/credit_classification_20261104'

def main():
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 with tempfile.TemporaryDirectory(prefix='credit-display-',dir='/private/tmp') as tmp:
  path=Path(tmp);sock=path/'socket';sock.mkdir();db=path/'db'
  def run(args,**kw):return subprocess.run(list(map(str,args)),env=env,text=True,capture_output=True,**kw)
  def command(args):
   p=run(args);assert p.returncode==0,p.stderr
  command([PG/'initdb','-D',db,'-U','postgres','--auth=trust','--no-locale','--encoding=UTF8'])
  command([PG/'pg_ctl','-D',db,'-l',path/'log','-o',f"-k {sock} -c listen_addresses=''",'-w','start'])
  try:
   def sql(s,error=None):
    p=run([PG/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','postgres'],input=s)
    if error:assert p.returncode and error in p.stderr,p.stderr;return
    assert p.returncode==0,p.stderr
    return p.stdout.strip()
   sql("""
create role anon;create role authenticated;create role service_role;
create schema auth;create schema essay_private;create schema essay_beta_private;create schema essay_exam_private;create schema math_private;
create function public.admin_operator() returns boolean language sql stable as $$select coalesce(current_setting('test.operator',true),'')='yes'$$;
create table auth.users(id uuid);
create table public.credit_accounts(id uuid primary key,user_id uuid);
create table public.credit_grants(id uuid primary key,account_id uuid,origin text,expires_at timestamptz,created_at timestamptz);
create table public.credit_transactions(id uuid primary key,account_id uuid,grant_id uuid,decision_id uuid,transaction_type text,reason_code text,balance_delta int,reserved_delta int,created_at timestamptz,reversal_of uuid,actor_reference text);
create table essay_beta_private.daily_grants(grant_id uuid primary key);
create table public.essay_billing_decisions(id uuid primary key,status text,evaluation_id uuid);
create table essay_exam_private.runs(id uuid,decision_id uuid,exam_id uuid,state text);
create table math_private.session_runs(id uuid,decision_id uuid,exam_id uuid,state text);
create table public.essay_exams(id uuid primary key,exam_name text);
create function public.admin_credit_snapshot(uuid) returns jsonb language sql stable as $$select null::jsonb$$;
insert into auth.users values('00000000-0000-0000-0000-000000000001'),('00000000-0000-0000-0000-000000000002');
insert into public.credit_accounts select id,id from auth.users;
""")
   sql((SOURCE/'member-baseline.sql').read_text());sql((SOURCE/'apply.sql').read_text())
   sql("""
insert into public.credit_grants select ('10000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,'00000000-0000-0000-0000-000000000001',origin,null,'2026-11-03 00:00+09'
from (values (1,'signup_bonus'),(2,'promotion'),(3,'promotion'),(4,'admin_grant'),(5,'purchase'),(6,'compensation'),(7,'b2b_program'),(8,'future_source'),(9,'admin_grant')) v(n,origin);
insert into public.credit_transactions select gen_random_uuid(),g.account_id,g.id,null,case when g.origin='future_source' then 'promotion' else g.origin end,
 case right(g.id::text,1) when '1' then 'signup_bonus_v1' when '2' then 'essay_beta_daily' when '9' then '{"operation":"admin_grant_v2","kind":"other"}' else 'unknown_reason' end,
 10,0,'2026-11-03 00:00+09',null,null from public.credit_grants g;
insert into essay_beta_private.daily_grants values('10000000-0000-0000-0000-000000000002');
insert into public.essay_billing_decisions values('20000000-0000-0000-0000-000000000001','settled',null);
insert into public.essay_exams values('30000000-0000-0000-0000-000000000001','Synthetic Math exam');
insert into math_private.session_runs values(gen_random_uuid(),'20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','completed');
insert into public.credit_transactions select gen_random_uuid(),'00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001',t,r,b,h,at::timestamptz,null,null from (values
 ('reserve','essay_exam_initial',0,1,'2026-11-04 00:00+09'),('consume','essay_exam_finalization',-1,-1,'2026-11-04 00:01+09'),
 ('release','evaluation_failed',0,-1,'2026-11-04 01:00+09'),('refund','manual_refund',1,0,'2026-11-04 02:00+09'),
 ('expiration','expired',-1,0,'2026-11-04 03:00+09'),('adjustment','purchase_cancel_v1',-1,0,'2026-11-04 04:00+09'),
 ('adjustment','iap_refund_apple',-1,0,'2026-11-04 05:00+09'),('adjustment','iap_refund_reversal_google',1,0,'2026-11-04 06:00+09'),
 ('adjustment','unknown_reason',-1,0,'2026-11-04 07:00+09')) v(t,r,b,h,at);
""")
   before=sql('select md5(string_agg(row_to_json(t)::text,\'\' order by id)) from public.credit_transactions t')
   def report(**kw):
    p=json.dumps(dict(version='credit-report-v2',**kw)).replace("'","''")
    return json.loads(sql(f"set role authenticated;set test.operator='yes';select public.admin_credit_report('{p}');"))
   for role in ['anon','service_role']:sql(f"set role {role};select public.admin_credit_report('{{}}');",'permission denied')
   sql("set role authenticated;select public.admin_credit_report('{}');",'OPERATOR_REQUIRED')
   sql("set role authenticated;select * from public.credit_transactions;",'permission denied')
   sql("set role authenticated;select essay_private.credit_display_grant(null);",'permission denied')
   allrows=report();assert allrows['total']==18
   assert allrows['grant_total']==90 and allrows['consume_total']==1
   assert sum(x['quantity'] for x in allrows['grant_stats'])==90
   assert len(allrows['grant_stats'])==8
   assert report(source='other',action='grant')['total']==2
   assert report(source='beta')['total']==10
   assert report(action='restore')['total']==2 and report(action='refund_adjustment')['total']==2
   assert report(action='adjustment')['total']==1
   for kind in ['signup','beta','event','admin','purchase','compensation','school']:
    assert report(source=kind,action='grant')['grant_total']==10
   assert report(subject='00000000-0000-0000-0000-000000000002')['total']==0
   bounds={'from':'2026-11-04T00:00:00+09:00','to':'2026-11-05T00:00:00+09:00'}
   day=report(**bounds);assert day['total']==9 and day['grant_total']==0 and day['consume_total']==1
   consume=report(action='consume',**bounds)['rows'][0]
   assert consume['grant_balance_after']==9 and consume['grant_reserved_after']==0
   assert consume['exam_name']=='Synthetic Math exam' and consume['run_state']=='completed'
   first=report(limit=5);second=report(limit=5,offset=5)
   assert first['total']==second['total']==18 and not set(r['id'] for r in first['rows'])&set(r['id'] for r in second['rows'])
   for payload in [{'source':'evil'},{'action':'free'},{'limit':0},{'offset':-1},{'from':'2026-11-05','to':'2026-11-04'}]:
    p=json.dumps(dict(version='credit-report-v2',**payload)).replace("'","''")
    sql(f"set role authenticated;set test.operator='yes';select public.admin_credit_report('{p}');",'INVALID_FILTER')
   member=json.loads(sql("set test.operator='yes';select public.admin_member_credit('00000000-0000-0000-0000-000000000001');"))
   assert len(member['grants'])==9 and any(g['display_kind']=='beta' for g in member['grants'])
   assert sql('select md5(string_agg(row_to_json(t)::text,\'\' order by id)) from public.credit_transactions t')==before
   sql((SOURCE/'rollback.sql').read_text());assert sql('select md5(string_agg(row_to_json(t)::text,\'\' order by id)) from public.credit_transactions t')==before
   print('PASS: 8 source kinds, 8 actions, quantities, midnight, member, paging, original-grant lineage, Math context, ACL, invalid filters, hash preservation, rollback')
  finally:command([PG/'pg_ctl','-D',db,'-m','immediate','-w','stop'])
if __name__=='__main__':main()
