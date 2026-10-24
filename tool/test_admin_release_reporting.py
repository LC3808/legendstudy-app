"""Disposable PostgreSQL checks of additive reporting; no remote connection option."""
import json, os, subprocess, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PG = Path('/opt/homebrew/opt/postgresql@17/bin')

def main():
    env = {k:v for k,v in os.environ.items() if not k.startswith('PG')}
    env['LC_ALL'] = 'C'
    with tempfile.TemporaryDirectory(prefix='admin-report-', dir='/private/tmp') as tmp:
        root = Path(tmp); sock = root/'socket'; sock.mkdir(); db = root/'db'
        def run(args, **kw):
            return subprocess.run([str(x) for x in args], env=env, text=True, capture_output=True, **kw)
        def command(args):
            p=run(args); assert p.returncode==0,p.stderr
        command([PG/'initdb','-D',db,'-U','postgres','--auth=trust','--no-locale','--encoding=UTF8'])
        command([PG/'pg_ctl','-D',db,'-l',root/'server.log','-o',f"-k {sock} -c listen_addresses=''",'-w','start'])
        try:
            def sql(s, error=None):
                p=run([PG/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','postgres'],input=s)
                if error:
                    assert p.returncode and error in p.stderr,p.stderr
                    return
                assert p.returncode==0,p.stderr
                return p.stdout.strip()
            sql("""
              create role anon; create role authenticated; create role service_role;
              create function public.admin_operator() returns boolean language sql stable as
                $$select coalesce(current_setting('test.operator',true),'')='yes'$$;
              create table public.profiles(id uuid,created_at timestamptz);
              create table public.credit_grants(id uuid,origin text);
              create table public.credit_transactions(id uuid,grant_id uuid,created_at timestamptz,transaction_type text,balance_delta int,reserved_delta int);
              create table public.payment_orders(id uuid,sku text,quantity int,amount int,currency text,mode text,state text,grant_state text,created_at timestamptz,paid_at timestamptz);
              create schema essay_exam_private;
              create table essay_exam_private.runs(id uuid,state text,created_at timestamptz);
              create table public.study_sessions(duration_seconds int,include_in_study_total boolean,started_at timestamptz,ended_at timestamptz);
              create table public.essay_exams(id uuid,university_id uuid);
              create table public.essay_questions(id uuid,is_published boolean);
            """)
            source=ROOT/'supabase/candidates/admin_release_reporting'
            sql((source/'install.sql').read_text())
            def report(kind, **filters):
                payload=json.dumps(dict(version='admin-release-v1',kind=kind,**filters)).replace("'","''")
                return json.loads(sql(f"set role authenticated;set test.operator='yes';select public.admin_release_report('{payload}');"))
            for role in ('anon','service_role'):
                sql(f"set role {role};select public.admin_release_report('{{}}');",'permission denied')
            sql("set role authenticated;select public.admin_release_report('{}');",'OPERATOR_REQUIRED')
            sql("set role authenticated;select * from public.credit_transactions;",'permission denied')
            sql("""
              insert into public.credit_grants values('00000000-0000-0000-0000-000000000001','purchase');
              insert into public.credit_transactions select gen_random_uuid(),'00000000-0000-0000-0000-000000000001','2026-10-24 00:00+09',t,d,r from (values ('purchase',10,0),('consume',-1,-1),('expiration',-2,0),('refund',1,0),('reserve',0,1),('adjustment',-1,0)) v(t,d,r);
              insert into public.payment_orders select gen_random_uuid(),'original-sku',3,3000,'KRW','LIVE','PAID','GRANTED','2026-10-24 00:00+09','2026-10-24 00:00+09' from generate_series(1,60);
              insert into public.payment_orders values(gen_random_uuid(),'test-sku',3,3000,'KRW','TEST','PAID','GRANTED','2026-10-24 00:00+09','2026-10-24 00:00+09'),(gen_random_uuid(),'cancelled',1,1000,'KRW','LIVE','PARTIALLY_CANCELLED','GRANTED','2026-10-24 00:00+09','2026-10-24 00:00+09');
              insert into public.profiles values(gen_random_uuid(),'2026-10-24 00:00+09'),(gen_random_uuid(),'2026-10-25 00:00+09');
              insert into public.study_sessions values(120,true,'2026-10-24 00:00+09',now()),(300,false,'2026-10-24 00:00+09',now()),(500,true,'2026-10-24 00:00+09',null);
              insert into essay_exam_private.runs values(gen_random_uuid(),'completed','2026-10-24 00:00+09'),(gen_random_uuid(),'reserved','2026-10-24 00:00+09');
            """)
            bounds={'from':'2026-10-24T00:00:00+09:00','to':'2026-10-25T00:00:00+09:00'}
            dash=report('dashboard',**bounds)
            assert (dash['new_members'],dash['credit_granted'],dash['credit_used'],dash['study_seconds'])==(1,10,1,120)
            assert dash['essay']==dict(pending=1,completed=1,failed=0)
            paid=report('payment',quantity=3,state='paid',limit=5,**bounds)
            assert paid['total']==61 and len(paid['rows'])==5
            assert paid['paid']==[dict(mode='LIVE',currency='KRW',count=60,amount=180000),dict(mode='TEST',currency='KRW',count=1,amount=3000)]
            assert report('payment',state='cancelled',**bounds)['total']==1
            first={r['id'] for r in paid['rows']}
            assert not first.intersection(r['id'] for r in report('payment',quantity=3,state='paid',limit=5,offset=5,**bounds)['rows'])
            assert report('credit',category='all',**bounds)['total']==6
            assert report('credit',category='consume',**bounds)['balance_delta']==-1
            assert report('credit',category='reversal',**bounds)['total']==2
            assert report('credit',category='expiration',**bounds)['balance_delta']==-2
            assert report('credit',category='free',**bounds)['total']==0
            sql((source/'rollback.sql').read_text())
            assert sql('select count(*) from public.credit_transactions')=='6'
            print(json.dumps({'checks':12,'productionWrites':0,'result':'PASS','coverage':'permissions, bounds, paging >50, mode isolation, category totals, study eligibility, rollback preservation'}))
        finally:
            command([PG/'pg_ctl','-D',db,'-m','immediate','-w','stop'])

if __name__=='__main__': main()
