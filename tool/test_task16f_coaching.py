#!/usr/bin/env python3
"""Disposable Unix-only PG17. Existing physical Math contracts + candidate projection/bypass checks.
No network DSN, Provider, production account or real student writes.
"""
import json,copy,os
from pathlib import Path
R=Path(__file__).resolve().parents[1]
ns={'__file__':str(R/'tool/test_math_learning.py'),'__name__':'task16f_fixture'}
exec(compile((R/'tool/test_math_learning.py').read_text().split('def cases(')[0],str(R/'tool/test_math_learning.py'),'exec'),ns)
base=ns['base_cases'];m=ns['m'];candidate=R/'supabase/candidates/task16f_math_coaching'
def cases(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock):
 # Runtime regression before the new response contract is installed.
 prior=base(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock)
 with ns['psycopg'].connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True) as admin:
  m.o.execute_as_production(c,admin,(R/'supabase/migrations/20261002000300_math_learning_runtime.sql').read_text())
  m.o.execute_as_production(c,admin,((R/'supabase/candidates/task16g_learning_loop/coaching.test.sql') if os.getenv('TASK16G_HOSTED_COACHING')=='1' else (candidate/'001_coaching.sql')).read_text())
  m.o.execute_as_production(c,admin,(candidate/'002_disclosure_boundary.sql').read_text())
 checks=[]
 def ok(label,condition):assert condition,label;checks.append(label)
 def call(action,payload,uid=A):return rpc('math_coaching',[{'dto_version':'math-coaching-v1','action':action,'payload':payload}],uid=uid)['result']
 def deny(label,fn):
  try:fn()
  except Exception:checks.append(label);return
  raise AssertionError(label)
 # Reuse an existing completed fixture whose real RPC lineage/owner is intact.
 eid=str(scalar("select e.id from public.math_evaluations e join public.math_attempts a on a.id=e.attempt_id where a.student_id=%s and e.state='COMPLETED' limit 1",(A,)))
 before=scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t')
 safe=call('read',{'evaluation_id':eid});ok('safe_response_no_full_solution',not safe['disclosed'] and 'full_solution' not in safe)
 deny('other_owner_denied',lambda:call('read',{'evaluation_id':eid},B))
 deny('forged_owner_denied',lambda:call('read',{'evaluation_id':eid,'owner_id':A}))
 deny('anonymous_denied',lambda:rpc('math_coaching',[{'dto_version':'math-coaching-v1','action':'read','payload':{'evaluation_id':eid}}],role='anon'))
 legacy=rpc('math_input',[{'dto_version':'math-input-v1','action':'read_result','payload':{'evaluation_id':eid}}])['result']
 ok('legacy_read_result_no_raw',legacy=={'evaluation_id':eid,'disclosed':False,'coaching_required':True})
 deny('private_legacy_not_callable',lambda:rpc('math_evaluation_detail_task16f_legacy',[eid]))
 # Projection never echoes generated strings, including adversarial titles and summaries.
 sample=copy.deepcopy(out);sample['steps']=[{'id':'s','position':1,'status':'VALID','representation':'SECRET_ANSWER','explanation':'SECRET_ANSWER'}]
 sample['errors']=[{'id':str(i),'step_id':'s','classification':'ROOT','category':'CALCULATION','materiality':'MATERIAL_ERROR','explanation':'SECRET_ANSWER'} for i in range(8)]
 with c.transaction():
  c.execute('set local role math_executor')
  projected=scalar('select math_private.coaching_projection(%s,%s,%s,%s,false)',(eid,ns['Jsonb'](sample),'STUDENT_WORK',ns['Jsonb']({})))
 ok('all_generated_fields_excluded','SECRET_ANSWER' not in json.dumps(projected))
 ok('maximum_five_tasks',len(projected['tasks'])==5 and projected['remaining_task_count']==3)
 ok('student_work_visible','STUDENT_WORK' in json.dumps(projected))
 sample['overall']={'status':'NOT_DETERMINABLE','review_status':'HUMAN_REVIEW_REQUIRED'};sample['errors']=[]
 with c.transaction():
  c.execute('set local role math_executor')
  undecided=scalar('select math_private.coaching_projection(%s,%s,%s,%s,false)',(eid,ns['Jsonb'](sample),'STUDENT_WORK',ns['Jsonb']({})))
 ok('undetermined_is_not_no_error','확정 판정할 수 없습니다' in undecided['diagnosis'])
 deny('missing_hint_level_denied',lambda:call('hint',{'evaluation_id':eid,'client_submission_id':new()}))

 key=new();revealed=call('reveal',{'evaluation_id':eid,'client_submission_id':key})
 ok('explicit_reveal_full_response',revealed['disclosed'] and 'full_solution' in revealed)
 ok('disclosure_durable',call('read',{'evaluation_id':eid})['disclosed'])
 call('reveal',{'evaluation_id':eid,'client_submission_id':key})
 ok('reveal_idempotent',scalar('select count(*) from math_private.coaching_disclosures where evaluation_id=%s',(eid,))==1)
 ok('history_same_lineage',call('history',{'evaluation_id':eid})['lineage_id']==revealed['lineage_id'])
 ok('credit_ledger_unchanged',before==scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t'))
 if os.getenv('TASK16G_HOSTED_COACHING')=='1':
  from task16g_mixed_checks import verify
  verify(c,rpc,new,scalar,A,B,ns,m,sock,R)
 with ns['psycopg'].connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True) as admin:
  m.o.execute_as_production(c,admin,(candidate/'rollback.sql').read_text())
 ok('rollback_preserves_disclosure_event',scalar('select count(*) from math_private.coaching_disclosures where evaluation_id=%s',(eid,))==1)
 ok('rollback_restores_legacy_rpc',rpc('math_evaluation_detail',[eid]).get('evaluation_id')==eid)
 print(json.dumps({'task16f_checks':checks,'count':len(checks),'runtime_regressions':len(prior),'production_writes':0,'provider_calls':0},ensure_ascii=False),flush=True)
 return prior
source=ns['ns']['source'];space=dict(m.__dict__);space.update(V=ns['V'],M=R/'supabase/migrations/20261002000200_math_runtime_surface.sql',verify_math_cases=cases)
exec(source,space);m.h.verify_hqp=space['verify'];m.h.main(bootstrap_user='supabase_admin')
