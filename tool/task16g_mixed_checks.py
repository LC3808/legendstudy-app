"""Synthetic local fixtures only; never seed fictional records into TEST."""
import json

def verify(c,rpc,new,scalar,A,B,ns,m,sock,R):
 # Minimal pre-existing mixed History surface, preserving the owner check.
 c.execute('create schema essay_exam_private; create table essay_exam_private.runs(id uuid primary key,student_id uuid,wire jsonb)')
 c.execute("create function public.essay_exam_history(p_run uuid default null) returns jsonb language sql security definer set search_path='' as $$ select jsonb_build_object('version','essay-exam-history-v1','runs',coalesce(jsonb_agg(wire),'[]')) from essay_exam_private.runs where student_id=auth.uid() and (p_run is null or id=p_run) $$; grant execute on function public.essay_exam_history(uuid) to authenticated")
 human={'questionId':new(),'evaluation':{'contract_version':'1.3','summary':'HUMAN_UNCHANGED','strengths':['human']}}
 qid=new();rid=new();hid=new();exam=new();secret='NEVER_BEFORE_REVEAL'
 math={'questionId':qid,'evaluation':{'contract_version':'math-eval-v1','steps':[{'id':'s','explanation':secret}], 'errors':[{'id':new(),'step_id':'s','classification':'ROOT','category':'CALCULATION','materiality':'MATERIAL_ERROR'}], 'generated_solution':secret,'overall':{'explanation':secret}}}
 r={'id':rid,'exam_id':exam,'question_ids':[human['questionId'],qid],'state':'completed','title':'Synthetic','answers':[{'questionId':qid,'body':'STUDENT_TEXT'}],'result':{'summary':secret,'questions':[human,math]}}
 pure={'id':hid,'state':'completed','result':{'summary':'HUMAN_SUMMARY','questions':[human]}}
 c.execute('insert into essay_exam_private.runs values(%s,%s,%s),(%s,%s,%s)',(rid,A,ns['Jsonb'](r),hid,A,ns['Jsonb'](pure)))
 with ns['psycopg'].connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True) as admin:
  m.o.execute_as_production(c,admin,(R/'supabase/candidates/task16g_learning_loop/mixed_disclosure.sql').read_text())
  m.o.execute_as_production(c,admin,(R/'supabase/candidates/task16g_learning_loop/mixed_learning.sql').read_text())
 safe=rpc('essay_exam_history',[rid])['runs'][0]
 assert secret not in json.dumps(safe)
 assert safe['result']['questions'][0]==human
 assert rpc('essay_exam_history',[hid])['runs'][0]==pure
 assert rpc('essay_exam_history',[rid],uid=B)['runs']==[]
 def call(action,**args):return rpc('essay_math_coaching',[{'dto_version':'math-coaching-v1','action':action,'payload':{'run_id':rid,'question_id':qid,**args}}])['result']
 assert not call('read')['disclosed']
 task=call('read')['tasks'][0]['id'];hk=new()
 hint=call('hint',task_id=task,level=1,client_submission_id=hk)
 assert secret not in json.dumps(hint)
 call('hint',task_id=task,level=1,client_submission_id=hk)
 assert scalar('select count(*) from math_private.mixed_coaching_hints')==1
 assert call('history')['attempts'][0]['exposed_hint_levels']==[1]
 prior=new();previous=r|{'id':prior,'parent_id':rid};c.execute('insert into essay_exam_private.runs values(%s,%s,%s)',(prior,A,ns['Jsonb'](previous)))
 history=call('history')['attempts'];assert len(history)==2 and {x['run_id'] for x in history}=={rid,prior}
 assert secret not in json.dumps(history)
 key=new();revealed=call('reveal',client_submission_id=key)
 assert revealed['disclosed'] and secret in json.dumps(revealed)
 call('reveal',client_submission_id=key)
 assert scalar('select count(*) from math_private.mixed_coaching_disclosures')==1
 assert rpc('essay_exam_history',[rid])['runs'][0]['result']['questions'][1]['solution_revealed']
 assert secret in json.dumps(rpc('essay_exam_history',[rid]))
 try:rpc('essay_exam_history_before_task16g',[rid])
 except Exception:pass
 else:raise AssertionError('raw mixed history callable')
 print('TASK16G_MIXED_MASK_REVEAL_HISTORY_HUMAN_UNCHANGED_OWNER_IDEMPOTENT PASS',flush=True)
