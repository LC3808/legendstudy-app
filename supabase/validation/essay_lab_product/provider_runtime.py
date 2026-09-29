"""L2-A2 guarded disposable PostgreSQL and real local JWT/PostgREST matrix.
Run submit_timing_runtime first on EMPTY isolated DB. Reuses G1's loopback/container
and consent guards. Installs ONLY synthetic policy fixtures, never approved models.
"""
import contextlib,io,json,hashlib,sys,time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from decimal import Decimal
from psycopg import sql
from psycopg.types.json import Jsonb
import status_projection_runtime as status

g=status.g
MIGRATION=g.ROOT/'supabase/migrations/20260929000500_essay_provider_provenance_telemetry.sql'
checks=[]
g.s.PARAMS['essay_record_provider_telemetry']=['p_evaluation','p_run','p_token','p_input_tokens','p_output_tokens','p_total_tokens','p_latency_ms','p_image_count','p_cost_amount','p_currency']

def cases(c,rpc,make_user,A,B):
 def scalar(q,args=()):
  privileged='select essay_private.' in q
  if privileged:c.execute('grant essay_executor to current_user')
  try:return c.execute(q,args or None).fetchone()[0]
  finally:
   if privileged:c.execute('revoke essay_executor from current_user')
 def ok(flag,label):
  assert flag,label;checks.append(label)
 def deny(fn,label,code=None):
  try:fn()
  except (g.s.Rejected,g.psycopg.Error) as e:
   if code:assert code in str(e),label+':'+str(e)
   checks.append(label);return
  raise AssertionError(label+' allowed')
 def clock(seconds):
  c.execute('grant essay_executor to current_user')
  c.execute(sql.SQL("create or replace function essay_private.clock() returns timestamptz language sql volatile set search_path='' as {} ").format(sql.Literal("select pg_catalog.clock_timestamp()+interval '%s seconds'"%seconds)))
  c.execute('revoke essay_executor from current_user')
 U=make_user();V=make_user()
 rpc('essay_admin_grant',[U,100,'admin_grant',g.uid(),'test_account',None],role='essay_finance')
 Q=str(scalar('select question_id from public.essay_question_evidence group by question_id having count(distinct role)=4 limit 1'))
 C=str(scalar('select id from public.essay_evaluation_criteria where question_id=%s order by id limit 1',(Q,)))
 E=str(scalar("select id from public.essay_question_evidence where question_id=%s and role='scoring_criteria'",(Q,)))
 def session():return rpc('essay_open_session',[g.uid(),Q],user=U)
 def submit(se):
  rev=scalar('select revision from public.essay_drafts where session_id=%s',(se,));body='Synthetic provenance '+g.uid()
  rev=rpc('essay_save_draft',[se,rev,body,'web_desktop','practice',0],user=U)
  return rpc('essay_submit_attempt',[se,rev,g.uid(),hashlib.sha256(body.encode()).hexdigest()],user=U)
 def request(a,regime,key=None):return rpc('essay_request_evaluation',[a,key or g.uid(),regime],user=U)
 def claim(e):return rpc('essay_claim',[e],role='essay_worker')
 def finish(e,l):
  sn=scalar('select input_snapshot from public.essay_evaluations where id=%s',(e,))
  out={'contract_version':sn['contract_version'],'summary':'Synthetic','strengths':[],'checklist':[],'dimensions':[{'criterion_id':C,'level':3,'explanation':'Synthetic','evidence_ids':[E]}],'improvements':[]}
  if sn['contract_version']=='1.3':out.update(attempt_id=sn['attempt_id'],answer_hash=sn['answer_hash'],core_improvement_keys=[],previous_improvement_reviews=[],sentence_feedback=[],local_reviews=[])
  return rpc('essay_finalize_success',[e,l['run_id'],l['lease_token'],out],role='essay_worker')
 def failure(e,l):return rpc('essay_finalize_failure',[e,l['run_id'],l['lease_token']],role='essay_worker')
 def facts():
  return [scalar("select coalesce(jsonb_agg(to_jsonb(t)-'total_tokens' order by id),'[]') from public."+t+' t') for t in ['essay_evaluations','essay_attempts','essay_ai_processing_runs','essay_improvement_progress','credit_transactions']]
 def security():
  return list(c.execute("select p.oid,p.proowner,p.proacl,p.proconfig from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','essay_private') order by p.oid")),list(c.execute('select * from pg_policies order by schemaname,tablename,policyname'))
 # Actual old pending and completed records survive the new migration.
 legacy=[]
 for v in ['essay-v1.2','essay-v1.3']:
  e=request(submit(session()),v);legacy.append((e,claim(e)))
 before=facts();sec=security();c.execute(MIGRATION.read_text());c.execute("notify pgrst,'reload schema'")
 ok(before==facts(),'migration_preserves_every_historical_fact');after=security()
 amap={x[0]:x for x in after[0]};ok(all(amap[x[0]]==x for x in sec[0]) and sec[1]==after[1],'existing_RPC_ACL_owner_search_path_and_RLS_unchanged')
 for e,l in legacy:finish(e,l)
 ok(all(scalar('select provider from public.essay_ai_processing_runs where id=%s',(l['run_id'],))=='unconfigured' for _,l in legacy),'legacy_inflight_v12_v13_provenance_not_rewritten')
 for _ in range(100):
  try:rpc('essay_record_provider_telemetry',[g.uid(),g.uid(),g.uid(),0,0,0,0],role='essay_worker')
  except g.s.Rejected as e:
   if 'PGRST202' not in str(e):break
   time.sleep(.05)
 else:raise AssertionError('schema cache')
 a=submit(session());deny(lambda:request(a,'essay-v1.3/policy/'+'0'*64),'unapproved_policy_closed','422')
 ok(scalar("select essay_private.provider_policy('anything') is null"),'shipped_registry_empty_no_model_selected')
 # Only this guarded disposable suite installs synthetic policy entries.
 p={'policy_version':'synthetic-v1','provider':'synthetic','model':'synthetic-only','model_version':'fixture-1','prompt_version':'scaffolding-1.3-v1','contract_version':'1.3'}
 def regime(p):return 'essay-v1.3/policy/'+scalar('select essay_private.hash(%s::jsonb::text)',(Jsonb(p),))
 r1=regime(p);p2=dict(p,policy_version='synthetic-v2',model_version='fixture-2');r2=regime(p2)
 def install(entries):
  body='select case '+''.join('when p_regime='+sql.Literal(k).as_string(c)+' then '+sql.Literal(json.dumps(v)).as_string(c)+'::jsonb ' for k,v in entries.items())+'else null::jsonb end'
  c.execute('grant essay_executor to current_user')
  c.execute(sql.SQL("create or replace function essay_private.provider_policy(p_regime text) returns jsonb language sql immutable set search_path='' as {}").format(sql.Literal(body)))
  c.execute('revoke essay_executor from current_user')
 install({r1:p,r2:p2})
 se=session();a=submit(se);key=g.uid();e=request(a,r1,key)
 ok(request(a,r1,key)==e and request(a,r1)==e,'bound_request_idempotent')
 deny(lambda:rpc('essay_request_evaluation',[a,g.uid(),r1],user=V),'other_user_request_denied')
 snap=scalar('select input_snapshot from public.essay_evaluations where id=%s',(e,));ok(snap['provider_binding']==p,'request_binding_frozen')
 install({r1:p2,r2:p2})
 deny(lambda:request(submit(session()),r1),'silent_same_regime_model_change_rejected','422')
 l=claim(e)
 ok(l['provider_binding']==p and l['input']['provider_binding']==p,'claim_uses_frozen_binding_not_moving_registry')
 ok(tuple(c.execute('select provider,model_name,model_version,prompt_version from public.essay_ai_processing_runs where id=%s',(l['run_id'],)).fetchone())==tuple(p[k] for k in ['provider','model','model_version','prompt_version']),'claim_response_equals_first_insert_identity')
 install({r1:p,r2:p2})
 def telemetry(e,l,**changes):
  values=dict(p_input_tokens=10,p_output_tokens=20,p_total_tokens=30,p_latency_ms=12,p_image_count=None,p_cost_amount=None,p_currency=None);values.update(changes)
  if sys.argv[1]=='--native' and values['p_cost_amount'] is not None:values['p_cost_amount']=Decimal(str(values['p_cost_amount']))
  return rpc('essay_record_provider_telemetry',[e,l['run_id'],l['lease_token']]+list(values.values()),role='essay_worker')
 invalid=[('negative_input',{'p_input_tokens':-1}),('negative_output',{'p_output_tokens':-1}),('negative_total',{'p_total_tokens':-1}),('inconsistent_total',{'p_total_tokens':29}),('negative_latency',{'p_latency_ms':-1}),('null_latency',{'p_latency_ms':None}),('oversize_latency',{'p_latency_ms':86400001}),('negative_images',{'p_image_count':-1}),('negative_cost',{'p_cost_amount':-1,'p_currency':'USD'}),('unbounded_cost',{'p_cost_amount':1000001,'p_currency':'USD'}),('fractional_precision_loss',{'p_cost_amount':.000000001,'p_currency':'USD'}),('currency_without_cost',{'p_currency':'USD'}),('cost_without_currency',{'p_cost_amount':1}),('invalid_currency',{'p_cost_amount':1,'p_currency':'bad'})]
 for label,kw in invalid:deny(lambda:telemetry(e,l,**kw),'reject_'+label,'422')
 ledger=scalar('select count(*) from public.credit_transactions')
 ok(telemetry(e,l)==l['run_id'] and telemetry(e,l)==l['run_id'],'telemetry_same_retry')
 for kw in [{'p_input_tokens':11,'p_total_tokens':31},{'p_latency_ms':13},{'p_total_tokens':None},{'p_cost_amount':1,'p_currency':'USD'}]:deny(lambda:telemetry(e,l,**kw),'changed_telemetry_conflict','409')
 ok(scalar('select count(*) from public.credit_transactions')==ledger,'telemetry_not_billing')
 ok(scalar('select cost_amount is null and cost_basis is null and total_tokens=30 from public.essay_ai_processing_runs where id=%s',(l['run_id'],)),'unknown_cost_is_null_total_preserved')
 for role in ['authenticated','essay_finance','service_role']:
  deny(lambda:rpc('essay_record_provider_telemetry',[e,l['run_id'],l['lease_token'],10,20,30,12],user=V,role=role),'telemetry_role_denied_'+role)
 for role in ['anon','authenticated','essay_finance','service_role']:
  ok(not scalar("select has_function_privilege(%s,'public.essay_record_provider_telemetry(uuid,uuid,uuid,bigint,bigint,bigint,bigint,integer,numeric,text)','execute')",(role,)),'telemetry_ACL_'+role)
 ok(finish(e,l)==e and finish(e,l)==e,'bound_success_finalize_retry')
 ok(tuple(c.execute('select model_provider,model_name,model_version,prompt_version from public.essay_evaluations where id=%s',(e,)).fetchone())==tuple(p[k] for k in ['provider','model','model_version','prompt_version']),'final_evaluation_inherits_server_identity')
 deny(lambda:telemetry(e,l),'terminal_success_telemetry_denied','409')
 en=request(submit(se),r1);ln=claim(en);telemetry(en,ln,p_cost_amount=.001,p_currency='USD');finish(en,ln)
 ok(scalar('select credits_required=0 and reason=\'included_revision\' from public.essay_billing_decisions where evaluation_id=%s',(en,)),'bound_G1_paid_then_included')
 ok(scalar('select cost_basis from public.essay_ai_processing_runs where id=%s',(ln['run_id'],))=='provider_reported','actual_cost_only')
 # Version coexistence, no old-result rewrite and no incompatible previous core context.
 ev=request(a,r2);lv=claim(ev);ok(lv['provider_binding']==p2 and lv['input']['scaffolding_context']['previous_core_progress_ids']==[],'new_model_new_regime_no_incompatible_core');finish(ev,lv)
 ok(scalar("select count(*) from public.essay_evaluations where attempt_id=%s and status='completed'",(a,))==2,'model_version_coexistence')
 # Usage then timeout/failure; stale and late writes never accepted.
 et=request(submit(session()),r1);lt=claim(et);telemetry(et,lt)
 rpc('essay_timeout',[et,lt['run_id'],lt['lease_token']],role='essay_worker')
 deny(lambda:telemetry(et,lt),'unknown_run_telemetry_denied','409')
 clock(121);lt2=claim(et);deny(lambda:telemetry(et,lt),'stale_worker_denied','409');clock(0)
 telemetry(et,lt2,p_input_tokens=None,p_output_tokens=None,p_total_tokens=17);finish(et,lt2)
 ok(scalar('select input_tokens=10 and status=\'unknown\' from public.essay_ai_processing_runs where id=%s',(lt['run_id'],)),'timeout_usage_history_kept')
 ok(scalar('select input_tokens is null and total_tokens=17 from public.essay_ai_processing_runs where id=%s',(lt2['run_id'],)),'partial_provider_usage_missingness_preserved')
 ef=request(submit(session()),r1);lf=claim(ef);telemetry(ef,lf);failure(ef,lf)
 ok(scalar('select status from public.essay_billing_decisions where evaluation_id=%s',(ef,))=='released','failure_releases_credit')
 ok(scalar('select input_tokens=10 and status=\'failed\' from public.essay_ai_processing_runs where id=%s',(lf['run_id'],)),'failure_usage_preserved')
 deny(lambda:telemetry(ef,lf),'failed_terminal_denied','409')
 ex=request(submit(session()),r1);lx=claim(ex);clock(121);deny(lambda:telemetry(ex,lx),'expired_lease_denied','409');clock(0);failure(ex,lx)
 es=session();ee=request(submit(es),r1);le=claim(ee);rpc('essay_erase',[es],user=U);deny(lambda:telemetry(ee,le),'erased_evaluation_denied')
 # Concurrent same payload is one fact, changed payload is rejected under job lock.
 ec=request(submit(session()),r1);lc=claim(ec)
 with ThreadPoolExecutor(2) as pool:result=list(pool.map(lambda _:telemetry(ec,lc),range(2)))
 ok(result==[lc['run_id']]*2,'concurrent_identical_telemetry_once');failure(ec,lc)
 for field in ['provider','model_name','model_version','prompt_version']:
  deny(lambda:c.execute(sql.SQL('update public.essay_ai_processing_runs set {}=\'tampered\' where id=%s').format(sql.Identifier(field)),(lc['run_id'],)),'immutable_run_'+field)
 for helper in ['provider_policy(text)','provider_binding_valid(text,jsonb)','provider_request_v13(uuid,uuid,text)','provider_claim_v13(uuid,uuid)']:
  ok(not scalar("select has_function_privilege('essay_worker',%s,'execute')",('essay_private.'+helper,)),'private_helper_closed_'+helper)
 ok(scalar("select count(*) from information_schema.columns where table_schema='public' and table_name='essay_ai_processing_runs' and column_name='total_tokens'")==1,'one_nullable_counter_no_new_table')
 clock(0)

if __name__=='__main__':
 original=g.cases
 def combined(c,rpc,user,A,B):
  result=original(c,rpc,user,A,B);status.cases(c,rpc,user,A,B);cases(c,rpc,user,A,B);return result
 g.cases=combined
 capture=io.StringIO()
 with contextlib.redirect_stdout(capture):g.main()
 result=json.loads(capture.getvalue())
 result.update(provider_checks=checks,provider_count=len(checks),status_checks=status.status_checks,status_count=len(status.status_checks),provider_migration_sha256=hashlib.sha256(MIGRATION.read_bytes()).hexdigest(),models_selected=[],real_AI_runs=0)
 print(json.dumps(result,indent=2))
