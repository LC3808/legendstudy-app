"""Synthetic timing correction regression. Only existing guarded disposable runners.
Exact elapsed fixtures execute setup + the REAL submit RPC in one transaction;
no sleep, production clock replacement, or production test-only function.
"""
import contextlib, hashlib, io, json, os, sys, uuid
from decimal import Decimal
from pathlib import Path
import scaffolding_runtime as scaffold
ROOT=scaffold.ROOT
FIX=ROOT/'supabase/migrations/20260929000200_essay_submit_timing_correction.sql'
FIXTURE='''
create function public.essay_test_timing_submit(p_session uuid,p_revision bigint,p_key uuid,p_body_hash text,p_elapsed numeric) returns uuid
language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.essay_practice_sessions where id=p_session and user_id=auth.uid()) then
 raise sqlstate 'PT403' using message='FORBIDDEN';end if;
 if p_elapsed<0 then raise sqlstate 'PT422';end if;
 if not exists(select 1 from public.essay_attempts where submission_key=p_key) then
 update public.essay_drafts set started_at=now()-p_elapsed*interval '1 second',revision=revision+1
 where session_id=p_session and revision=p_revision-1;
 end if;
 return public.essay_submit_attempt(p_session,p_revision,p_key,p_body_hash);
end$$;
revoke all on function public.essay_test_timing_submit(uuid,bigint,uuid,text,numeric) from public,anon,service_role;
grant execute on function public.essay_test_timing_submit(uuid,bigint,uuid,text,numeric) to authenticated;
'''

def cases(c,rpc,A,B):
 checks=[]
 def ok(value,label):
  if not value:raise AssertionError(label)
  checks.append(label)
 def rejected(fn,label,code='409'):
  try:fn()
  except scaffold.Rejected as e:
   ok(code in str(e),label);return
  raise AssertionError(label+' allowed')
 q=str(c.execute("select question_id from public.essay_question_evidence group by question_id having count(distinct role)=4 order by question_id limit 1").fetchone()[0])
 c.execute(FIXTURE);c.execute("notify pgrst,'reload schema'")
 # PostgREST schema cache updates asynchronously: poll a non-existent owner context, before mutation.
 probe=getattr(rpc,'await_fixture',None)
 scaffold.PARAMS['essay_test_timing_submit']=['p_session','p_revision','p_key','p_body_hash','p_elapsed']
 if probe:probe()
 try:
  for elapsed in ['0','0.1','0.5','0.7','0.99','1','1.1','2','2.99','10']:
   for active in [None,0,1,2,20]:
    s=rpc('essay_open_session',[str(uuid.uuid4()),q]);body='Synthetic timing 🙂';h=hashlib.sha256(body.encode()).hexdigest()
    rev=rpc('essay_save_draft',[s,1,body,'web_desktop','practice',active]);key=str(uuid.uuid4())
    a=rpc('essay_test_timing_submit',[s,rev+1,key,h,elapsed])
    row=c.execute('select active_writing_seconds,extract(epoch from submitted_at-started_at),body_sha256,character_count,attempt_no from public.essay_attempts where id=%s',(a,)).fetchone()
    expected=None if active is None else min(active,int(Decimal(elapsed)))
    ok(row==(expected,Decimal(elapsed),h,len(body),1),f'elapsed_{elapsed}_active_{active}')
    # Retry calls production RPC DIRECTLY; no fixture clock or draft adjustment.
    ok(rpc('essay_submit_attempt',[s,rev+1,key,h])==a,f'duplicate_{elapsed}_{active}')
    rejected(lambda:rpc('essay_submit_attempt',[s,rev+1,key,'0'*64]),f'mismatch_{elapsed}_{active}')
    rejected(lambda:rpc('essay_submit_attempt',[s,rev,str(uuid.uuid4()),h]),f'stale_{elapsed}_{active}')
    rejected(lambda:rpc('essay_submit_attempt',[s,rev+1,key,h],user=B),f'cross_user_{elapsed}_{active}','403')
    ok(c.execute('select count(*) from public.essay_attempts where session_id=%s',(s,)).fetchone()[0]==1,f'single_attempt_{elapsed}_{active}')
  # Direct unwrapped REST/native submit with unknown and known time as well.
  for active in [None,0,20]:
   s=rpc('essay_open_session',[str(uuid.uuid4()),q]);body='Direct submit';h=hashlib.sha256(body.encode()).hexdigest()
   rev=rpc('essay_save_draft',[s,1,body,'web_desktop','practice',active]);a=rpc('essay_submit_attempt',[s,rev,str(uuid.uuid4()),h])
   value,elapsed=c.execute('select active_writing_seconds,extract(epoch from submitted_at-started_at) from public.essay_attempts where id=%s',(a,)).fetchone()
   ok(value is None if active is None else 0<=value<=elapsed,'direct_submit_'+str(active))
  # No row mutation, constraint or privilege drift when CREATE OR REPLACE runs.
  tables=['essay_attempts','essay_evaluations','essay_improvement_progress','credit_transactions']
  def facts():return [c.execute('select coalesce(jsonb_agg(to_jsonb(t) order by id),\'[]\'::jsonb) from public.'+t+' t').fetchone()[0] for t in tables]
  def catalog():return c.execute("select proowner,proacl,proconfig,prosecdef from pg_proc where oid='public.essay_submit_attempt(uuid,bigint,uuid,text)'::regprocedure").fetchone()
  old=facts();priv=catalog();constraints=c.execute("select conname,pg_get_constraintdef(oid) from pg_constraint where conrelid='public.essay_attempts'::regclass order by conname").fetchall()
  c.execute(FIX.read_text())
  ok(facts()==old,'existing_history_unchanged_on_forward_replace')
  ok(priv==catalog(),'owner_ACL_security_search_path_preserved')
  ok(constraints==c.execute("select conname,pg_get_constraintdef(oid) from pg_constraint where conrelid='public.essay_attempts'::regclass order by conname").fetchall(),'CHECKs_unchanged')
 finally:
  c.execute('drop function public.essay_test_timing_submit(uuid,bigint,uuid,text,numeric)');c.execute("notify pgrst,'reload schema'")
 return checks


def main():
 mode=sys.argv[1]
 old_cases=scaffold.cases; timing=[]
 def combined(c,rpc,A,B):
  result=old_cases(c,rpc,A,B)
  timing.extend(cases(c,rpc,A,B));return result
 scaffold.cases=combined
 out=io.StringIO()
 if mode=='--native':
  original=scaffold.SQLText.read_text
  scaffold.SQLText.read_text=lambda self:original(self)+'\n'+FIX.read_text()
  with contextlib.redirect_stdout(out):scaffold.main()
 elif mode=='--supabase':
  import scaffolding_supabase as sb
  prepare=sb.prepare_supabase.main
  def prepared():
   prepare()
   cfg=json.loads(Path(os.environ['ESSAY_REVIEW_SUPABASE_STATUS_FILE']).read_text())
   with scaffold.psycopg.connect(cfg['DB_URL'],autocommit=True) as c:c.execute(FIX.read_text())
  sb.prepare_supabase.main=prepared
  # A bounded cache wait on a forbidden synthetic RPC probe; it does not control elapsed time.
  combined_cases=sb.cases
  def wrapped(c,rpc,A,B):
   import time
   def ready():
    for _ in range(100):
     try:rpc('essay_test_timing_submit',[str(uuid.uuid4()),1,str(uuid.uuid4()),'0'*64,'0'])
     except scaffold.Rejected as e:
      if '403' in str(e):return
      if '404' not in str(e):raise
     time.sleep(.05)
    raise AssertionError('fixture schema cache not ready')
   rpc.await_fixture=ready
   return combined_cases(c,rpc,A,B)
  sb.cases=wrapped
  with contextlib.redirect_stdout(out):sb.main()
 else:raise SystemExit('Use --native or --supabase; never a production DSN')
 raw=out.getvalue();result=json.loads(raw[raw.index('{'):])
 result['submit_timing_checks']=timing;result['submit_timing_check_count']=len(timing)
 result['timing_fixture']='transaction now() exact elapsed; fixture calls unchanged public RPC boundary; direct retry and direct submits also executed'
 result['correction_sha256']=hashlib.sha256(FIX.read_bytes()).hexdigest()
 print(json.dumps(result,indent=2))
if __name__=='__main__':main()
