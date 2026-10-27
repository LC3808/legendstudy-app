"""Only disposable loopback PostgreSQL. Reuse the verified beta runtime fixture first."""
import os,pathlib,subprocess,json,uuid
root=pathlib.Path(__file__).parent
cmd=['/opt/homebrew/bin/psql','-X','-h','127.0.0.1','-p','55449','-d','beta_source','-v','ON_ERROR_STOP=1','-Atq']
def sql(s,fail=None):
 r=subprocess.run(cmd,input=s,text=True,capture_output=True)
 if fail: assert r.returncode and fail in r.stderr,(fail,r.stderr);return
 assert r.returncode==0,r.stderr
 return r.stdout.strip()
def ok(name,cond=True):
 assert cond,name
 print('PASS',name,flush=True)
sql('create table public.payment_orders(grant_id uuid,state text);')
sql('set check_function_bodies=off;'+(root/'apply.sql').read_text())
ok('five postchecks',all(v=='t' for v in sql((root/'postcheck.sql').read_text()).split('|')))
sql('set check_function_bodies=off;'+(root/'apply.sql').read_text(),fail='BASELINE_CHANGED')
ok('duplicate apply rejected')
# Worker admission/package functions are fixture stubs; reservation and credit functions are real.
sql("create function public.essay_exam_quote(uuid,uuid,uuid[],uuid,uuid) returns jsonb language sql as $$select jsonb_build_object('version','essay-exam-quote-v1','credits',case when $4 is null then 1 else 0 end)$$;")
sql("create function public.essay_exam_submit(uuid,uuid,uuid,jsonb,uuid) returns uuid language sql as $$select essay_exam_private.reserve((select id from public.credit_accounts where user_id=$1),$2,$3,jsonb_build_object('answers',$4),$5)$$;")
sql("create function public.essay_exam_submit_cycle(uuid,uuid,uuid,jsonb,uuid,uuid) returns uuid language sql as $$select public.essay_exam_submit($1,$2,$3,$4,$5)$$;")
U='00000000-0000-4000-8000-000000000002';E='10000000-0000-4000-8000-000000000001';Q='20000000-0000-4000-8000-000000000001'
A=sql(f"select id from public.credit_accounts where user_id='{U}'")
answers=json.dumps([{'questionId':Q,'body':'fixture','revision':0,'rubricVersion':'fixture','evidenceVersion':'fixture'}])
def quote():return json.loads(sql(f"select public.essay_exam_quote_source('{U}','{E}',array['{Q}']::uuid[],null,null)"))['credit_source']
def submit(g,key=None,parent=None,fail=None):
 key=key or str(uuid.uuid4())
 return sql(f"select public.essay_exam_submit_source('{U}','{E}','{key}','{answers}',{'null' if g is None else chr(39)+g+chr(39)},{'null' if parent is None else chr(39)+parent+chr(39)},null)",fail)
source=quote();P=source['grant_id']
ok('paid fallback explicitly quoted',source['source']=='purchase' and source['beta']==0 and source['purchase']==3)
submit(None,fail='CREDIT_SOURCE_CONFIRMATION_REQUIRED');ok('missing source rejects reservation')
submit(str(uuid.uuid4()),fail='CREDIT_SOURCE_CHANGED');ok('other or fabricated grant rejected')
key=str(uuid.uuid4());R=submit(P,key)
ok('confirmed paid source reserved',sql(f"select grant_id from public.credit_transactions where decision_id=(select decision_id from essay_exam_private.runs where id='{R}') and transaction_type='reserve'")==P)
ok('same request replays',submit(P,key)==R)
sql(f"select essay_exam_private.finish('{R}',null,true)")
ok('failed request releases exact source',quote()['purchase']==3)
# Add a higher priority signup grant after quote. Never silently choose it.
sql(f"set test.actor='{U}';select essay_private.credit_post_grant('{U}',3,'signup_bonus','source-signup','fixture','source-signup',clock_timestamp()+interval '1 minute')")
N=quote();ok('signup balance and source shown',N['signup_bonus']==3 and N['source']=='signup_bonus')
submit(P,fail='CREDIT_SOURCE_CHANGED');ok('source changed after quote rejected')
S=N['grant_id'];R2=submit(S)
result=json.dumps({'summary':'fixture','questions':[{'questionId':Q,'rubricVersion':'fixture','evidenceVersion':'fixture','evaluation':{'fixture':True}}]})
sql(f"select essay_exam_private.finish('{R2}','{result}')")
free=submit(None,parent=R2)
ok('free rewrite has no reservation',sql(f"select count(*) from public.credit_transactions where decision_id=(select decision_id from essay_exam_private.runs where id='{free}')")=='0')
sql(f"update public.credit_grants set expires_at=clock_timestamp()-interval '1 second' where id='{S}'")
submit(S,fail='CREDIT_SOURCE_CHANGED');ok('expired confirmed grant cannot fall back')
ok('exact accepted request survives source expiry',submit(P,key)==R)
sql(f"insert into public.payment_orders values('{P}','CANCEL_PENDING')")
submit(P,fail='CREDIT_SOURCE_CHANGED');ok('purchase cancellation fence rejects quote and reserve')
sql(f"select public.essay_exam_quote_source('{U}','{E}',array['{Q}']::uuid[],null,null)",fail='INSUFFICIENT_CREDIT')
ok('insufficient spendable source blocked')
sql(f"delete from public.payment_orders where grant_id='{P}'")
sql(f"select public.essay_exam_submit('{U}','{E}','{uuid.uuid4()}','{answers}',null)",fail='CREDIT_SOURCE_CONFIRMATION_REQUIRED')
ok('old beta client cannot silently fallback')
for role in ['anon','authenticated','service_role']:
 sql(f"set role {role};select public.essay_exam_submit_source('{U}','{E}','{uuid.uuid4()}','{answers}','{P}',null,null)",fail='permission denied')
 ok(role+' direct submission blocked')
# Four simultaneous requests consent to the same three-credit grant.
from concurrent.futures import ThreadPoolExecutor
def concurrent_submit(_):
 key=str(uuid.uuid4())
 query=f"select public.essay_exam_submit_source('{U}','{E}','{key}','{answers}','{P}',null,null)"
 return subprocess.run(cmd,input=query,text=True,capture_output=True)
with ThreadPoolExecutor(max_workers=4) as pool:
 outcomes=list(pool.map(concurrent_submit,range(4)))
success=[r.stdout.strip() for r in outcomes if r.returncode==0]
rejected=[r for r in outcomes if r.returncode!=0]
ok('concurrent confirmed reservations cannot overspend or fallback',len(success)==3 and len(rejected)==1 and 'CREDIT_SOURCE_CHANGED' in rejected[0].stderr)
for run in success:sql(f"select essay_exam_private.finish('{run}',null,true)")
ok('concurrent failure releases preserve original paid balance',quote()['purchase']==3)
ok('campaign remains off',sql('select not exists(select 1 from essay_beta_private.campaigns where enabled)')=='t')
print('Source consent complete; Provider calls 0; Production mutations 0.')
