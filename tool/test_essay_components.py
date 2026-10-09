#!/usr/bin/env python3
"""Actual canonical finalizer + component extension, isolated PG17 only; no provider/DSN."""
import copy,json,hashlib,os,concurrent.futures
from psycopg.types.json import Jsonb
from pathlib import Path
import psycopg
import test_human_quality as h
import test_account_deletion_ownership as o
R=Path(__file__).resolve().parents[1]
def verify(c,rpc,new,scalar,first,second,zero,A,B,OP,session,previous,args,sock):
 for v in ['20260913000200','20260914000100','20260914000200','20260923000100','20260926000100','20260930000100','20260917000200','20261001000200']:
  c.execute(next((R/'supabase/migrations').glob(v+'_*.sql')).read_text())
 c.execute('alter table auth.users add column email_confirmed_at timestamptz default now()')
 admin=o.prepare(c,sock)
 o.execute_as_production(c,admin,(R/'supabase/migrations/20261001000300_account_deletion_lifecycle.sql').read_text())
 checks=[]
 def ok(name,value=True):assert value,name;checks.append(name);print(name,'PASS',flush=True)
 def deny(name,fn):
  try:fn()
  except psycopg.Error as e:assert e.sqlstate in ('42501','PT401','PT403','PT404','PT409','PT422','23514'),(name,str(e));ok(name);return
  raise AssertionError(name+' allowed')
 def snapshot():return scalar("select jsonb_agg(jsonb_build_array(p.oid::text,pg_get_functiondef(p.oid),p.proacl::text) order by p.oid) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','essay_private','account_private')")
 old=snapshot();members=c.execute('select * from pg_auth_members order by oid').fetchall()
 body=(R/'supabase/candidates/essay_components/install.sql').read_text()
 try:o.execute_as_production(c,admin,body.replace('commit;',"do $$begin raise exception 'synthetic install interruption';end$$;commit;"))
 except psycopg.Error:pass
 else:raise AssertionError('interrupted install succeeded')
 ok('interrupted_install_rolls_back',scalar("select to_regclass('public.essay_evaluation_components') is null") and old==snapshot() and members==c.execute('select * from pg_auth_members order by oid').fetchall())
 o.execute_as_production(c,admin,body)
 ok('non_superuser_install');ok('temporary_memberships_restored',members==c.execute('select * from pg_auth_members order by oid').fetchall())
 now=snapshot();oldmap={x[0]:x for x in old};ok('existing_function_bodies_acls_unchanged',all(x in now for x in oldmap.values()))
 ok('rls_enabled',scalar("select relrowsecurity from pg_class where oid='public.essay_evaluation_components'::regclass"))
 for role in ['anon','authenticated','service_role','essay_worker']:
  ok(role+'_no_direct_table',not scalar("select has_table_privilege(%s,'public.essay_evaluation_components','SELECT,INSERT,UPDATE,DELETE')",(role,)))
 rpc('essay_admin_grant',[A,8,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 q=str(scalar('select question_id from public.essay_evaluations where id=%s',(zero,)))
 def spent():return scalar("select coalesce(-sum(t.balance_delta),0) from public.credit_transactions t join public.credit_accounts a on a.id=t.account_id where a.user_id=%s and t.transaction_type='consume'",(A,))
 def pending(s=None):
  s=s or str(rpc('essay_open_session',[new(),q]));answer='Synthetic reviewed answer '+new();revision=scalar('select revision from public.essay_drafts where session_id=%s',(s,))
  revision=rpc('essay_save_draft',[s,revision,answer,'web_desktop','practice',0]);a=str(rpc('essay_submit_attempt',[s,revision,new(),hashlib.sha256(answer.encode()).hexdigest()]))
  key=new();e=str(rpc('essay_request_evaluation',[a,key,'essay-v1.3']));assert str(rpc('essay_request_evaluation',[a,key,'essay-v1.3']))==e
  cl=rpc('essay_claim_components',[e],role='essay_worker');snap=cl['input'];criterion=snap['criteria'][0]
  evidence=[x['id'] for x in snap['evidence']]
  output=dict(contract_version='1.3',attempt_id=a,answer_hash=snap['answer_hash'],summary='Synthetic',strengths=['Synthetic'],checklist=[],dimensions=[dict(criterion_id=criterion['id'],level=4,explanation='Synthetic',evidence_ids=evidence)],improvements=[],core_improvement_keys=[],previous_improvement_reviews=[],sentence_feedback=[],local_reviews=[])
  manifest=dict(version='essay-components-v1',classification_version='synthetic-reviewed-v1',exam_type='business_economics',input_sha256=cl['input_sha256'],requirements=['TEXT_REASONING','QUANTITATIVE'],components=[dict(question_key='q'+str(i),title='문항 '+str(i),capability=cap,rubric_version='synthetic-v1',source_sha256='a'*64) for i,cap in enumerate(['TEXT_REASONING','QUANTITATIVE'])])
  result=dict(version='essay-composition-v1',evaluationId=e,attemptId=a,sections=[dict(questionKey=x['question_key'],title=x['title'],feedback=dict(summary='Synthetic'),requiresReview=False) for x in manifest['components']],requiresReview=False)
  return s,e,cl,output,manifest,result
 def finish(t,role='essay_worker'):
  s,e,cl,out,m,r=t;return rpc('essay_finalize_components',[e,cl['run_id'],cl['lease_token'],out,m,r],role=role)
 before=spent();t=pending();s,e,cl,out,m,r=t
 deny('student_finalize_denied',lambda:finish(t,'authenticated'));deny('anon_finalize_denied',lambda:finish(t,'anon'))
 for name,change in [
  ('missing_section',lambda z:z[-1]['sections'].pop()),
  ('wrong_parent',lambda z:z[-1].update(evaluationId=new())),
  ('wrong_snapshot',lambda z:z[-2].update(input_sha256='b'*64)),
  ('missing_capability',lambda z:z[-2].update(requirements=['TEXT_REASONING'])),
  ('extra_raw_answer',lambda z:z[-1].update(answer='private')),
  ('bad_base',lambda z:z[3].update(summary=''))]:
  bad=copy.deepcopy(t);change(bad);deny(name,lambda:finish(bad))
 ok('invalid_output_no_charge',spent()==before);ok('invalid_output_no_result',scalar('select count(*) from public.essay_evaluation_components where evaluation_id=%s',(e,))==0)
 # Force insertion failure AFTER canonical finalizer; whole transaction must roll back.
 c.execute("alter table public.essay_evaluation_components add constraint synthetic_failure check(false) not valid")
 deny('atomic_insert_failure',lambda:finish(t));ok('atomic_failure_no_charge',spent()==before)
 ok('atomic_failure_parent_processing',scalar('select status from public.essay_evaluations where id=%s',(e,))=='processing')
 c.execute('alter table public.essay_evaluation_components drop constraint synthetic_failure')
 def concurrent_finish():
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres') as worker:
   worker.execute('set local role essay_worker')
   return str(worker.execute('select public.essay_finalize_components(%s,%s,%s,%s,%s,%s)',(e,cl['run_id'],cl['lease_token'],Jsonb(out),Jsonb(m),Jsonb(r))).fetchone()[0])
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(lambda _:concurrent_finish(),range(2)))
 ok('concurrent_finalization',results==[e,e]);ok('single_parent_one_credit',spent()==before+1);finish(t);ok('replay_no_charge',spent()==before+1)
 stale=copy.deepcopy(t);stale[2]['lease_token']=new();deny('stale_fence_replay',lambda:finish(stale))
 changed=copy.deepcopy(t);changed[-1]['sections'][0]['feedback']['summary']='changed';deny('replay_changed_section',lambda:finish(changed))
 ok('owner_result',rpc('essay_component_result',[e])==r)
 deny('foreign_result',lambda:rpc('essay_component_result',[e],uid=B));deny('anonymous_result',lambda:rpc('essay_component_result',[e],uid='',role='anon'))
 # Rewrite stays in the same canonical session; existing included evaluation is reused.
 rewrite=pending(s);finish(rewrite);ok('included_rewrite_no_extra_credit',spent()==before+1)
 ok('history_both_results',rpc('essay_component_result',[e])==r and rpc('essay_component_result',[rewrite[1]])==rewrite[-1])
 science=pending();science[-2].update(exam_type='science',requirements=['SCIENCE_REASONING']);science[-2]['components']=science[-2]['components'][:1];science[-2]['components'][0]['capability']='SCIENCE_REASONING';science[-1]['sections']=science[-1]['sections'][:1]
 finish(science);ok('science_canonical_result',rpc('essay_component_result',[science[1]])==science[-1])
 spent_before_failure=spent();failed=pending();rpc('essay_finalize_failure',[failed[1],failed[2]['run_id'],failed[2]['lease_token']],role='essay_worker')
 ok('failure_no_consumption',spent()==spent_before_failure)
 ok('failed_parent_no_sections',scalar('select count(*) from public.essay_evaluation_components where evaluation_id=%s',(failed[1],))==0)
 rpc('essay_erase',[s]);ok('canonical_erasure_cascades',scalar('select count(*) from public.essay_evaluation_components where evaluation_id in (%s,%s)',(e,rewrite[1]))==0)
 c.execute("insert into account_private.dispatch_health(singleton,last_seen,enabled) values(true,now(),true) on conflict(singleton) do update set enabled=true,last_seen=now()")
 rpc('account_deletion_request');deny('pending_deletion_read_denied',lambda:rpc('essay_component_result',[science[1]]))
 c.execute('delete from auth.users where id=%s',(A,))
 ok('account_fk_cascade',scalar('select count(*) from public.essay_evaluation_components')==0)
 report=dict(scope='isolated PG17, real canonical finalizer, synthetic content/provider; NOT Production E2E',checks=checks,count=len(checks),production_writes=0)
 if os.getenv('ESSAY_COMPONENT_REPORT'):Path(os.environ['ESSAY_COMPONENT_REPORT']).write_text(json.dumps(report,indent=2)+'\n')
h.verify_hqp=verify
h.main(bootstrap_user='supabase_admin')
