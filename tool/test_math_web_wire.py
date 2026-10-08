#!/usr/bin/env python3
"""Disposable local PG17 + actual LAB TypeScript wire conversion, synthetic evaluator.
No Production URL, token, provider or student data accepted. Set ESSAY_LAB_CHECKOUT.
Existing isolation/bootstrap guards are inherited from test_math_learning.py.
"""
import json,os,subprocess
from pathlib import Path
import psycopg
R=Path(__file__).resolve().parents[1]

def web_cases(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock):
 checks=[]
 def ok(name,condition=True):assert condition,name;checks.append(name);print(name,'PASS',flush=True)
 def call(surface,action,payload,uid=A,role='authenticated'):
  dto={'input':'math-input-v1','evaluation':'math-worker-v1','learning':'math-learning-v1'}[surface]
  return rpc('math_'+surface,[dict(dto_version=dto,action=action,payload=payload)],uid=uid,role=role)['result']
 def denied(fn):
  try:fn()
  except psycopg.Error as e:assert e.sqlstate in ('42501','22023','PT402','P0002');return
  raise AssertionError('foreign allowed')
 def spent():return scalar("select coalesce(-sum(t.balance_delta),0) from public.credit_transactions t join public.credit_accounts a on a.id=t.account_id where a.user_id=%s and t.transaction_type='consume'",(A,))
 def payload(key=None):return dict(client_submission_id=key or new(),leaf_id=leaf,kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic web answer 2')
 def finish(e):
  claim=call('evaluation','claim',dict(evaluation_id=e),role='math_evaluation_worker')
  lab=Path(os.environ['ESSAY_LAB_CHECKOUT']).resolve()
  output=json.loads(subprocess.check_output(['node',str(lab/'scripts/math-sql-wire-fixture.mjs')],input=json.dumps(dict(isolated_fixture=True,claim=claim)),text=True,cwd=lab))
  req=dict(evaluation_id=e,lease_token=claim['lease_token'],output=output)
  call('evaluation','finalize',req,role='math_evaluation_worker')
  call('evaluation','finalize',req,role='math_evaluation_worker')
  ok('wire_fenced_finalize_replay')
 before=spent();req=payload();a=call('input','create_attempt',req)['attempt_id']
 ok('wire_submit_replay',call('input','create_attempt',req)['attempt_id']==a)
 denied(lambda:call('input','read_input',dict(attempt_id=a),uid=B));ok('wire_foreign_input_denied')
 req=dict(attempt_id=a,client_submission_id=new());e=call('input','request_evaluation',req)['evaluation_id']
 ok('wire_request_replay',call('input','request_evaluation',req)['evaluation_id']==e)
 finish(e);ok('wire_initial_one_credit',spent()==before+1)
 state=call('learning','read_learning_state',dict(evaluation_id=e));ok('wire_completed',state['evaluation_state']=='COMPLETED')
 ok('wire_included_eligible',state['included_reevaluation']['eligible'])
 deadline=scalar("select completed_at+interval '336 hours' from public.math_evaluations where id=%s",(e,))
 ok('wire_14day_boundary',scalar('select math_private.learning_eligibility(%s,%s)',(e,deadline))['status']=='EXPIRED')
 denied(lambda:call('learning','read_learning_state',dict(evaluation_id=e),uid=B));ok('wire_foreign_result_denied')
 req=dict(payload(),kind='SHORT_ANSWER_RESOLVE',predecessor_id=a,prior_evaluation_id=e)
 ra=call('learning','create_resolve_attempt',req)['attempt_id']
 ok('wire_resolve_replay',call('learning','create_resolve_attempt',req)['attempt_id']==ra)
 req=dict(attempt_id=ra,client_submission_id=new());re=call('learning','request_reevaluation',req)['evaluation_id']
 ok('wire_reevaluation_replay',call('learning','request_reevaluation',req)['evaluation_id']==re)
 finish(re);ok('wire_included_no_extra_credit',spent()==before+1)
 history=call('learning','read_learning_history',dict(evaluation_id=e,limit=20));ok('wire_history',any(x['attempt_id']==ra for x in history['attempts']))
 a=call('input','create_attempt',payload())['attempt_id'];e=call('input','request_evaluation',dict(attempt_id=a,client_submission_id=new()))['evaluation_id']
 claim=call('evaluation','claim',dict(evaluation_id=e),role='math_evaluation_worker')
 call('evaluation','fail',dict(evaluation_id=e,lease_token=claim['lease_token'],error_code='INVALID_OUTPUT'),role='math_evaluation_worker')
 ok('wire_failure_no_consumption',spent()==before+1)
 ok('wire_failed_no_result',scalar('select output_sha256 is null from public.math_evaluations where id=%s',(e,)))
 result=dict(scope='isolated PG17 role claims + LAB actual TypeScript wire, synthetic evaluation; NOT hosted JWT/storage/provider E2E',checks=checks,count=len(checks),production_writes=0,provider_calls=0)
 destination=os.environ.get('ESSAY_WIRE_REPORT')
 if destination:Path(destination).write_text(json.dumps(result,indent=2)+'\n')
 return checks

source=(R/'tool/test_math_learning.py').read_text().replace('space.update(V=V,M=M,verify_math_cases=cases)','space.update(V=V,M=M,verify_math_cases=web_cases)')
exec(compile(source,str(R/'tool/test_math_learning.py'),'exec'),{'__file__':str(R/'tool/test_math_learning.py'),'__name__':'__main__','web_cases':web_cases})
