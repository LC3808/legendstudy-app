#!/usr/bin/env python3
"""TASK16-L disposable Postgres integration, no hosted DB or Provider calls."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
source=(R/'tool/test_task16f_coaching.py').read_text()
setup=r'''

 original_coaching=scalar("select pg_get_functiondef('public.math_coaching(jsonb)'::regprocedure)")
 old_rows=scalar("select md5(jsonb_agg(to_jsonb(e) order by id)::text) from public.math_evaluations e")
 with ns['psycopg'].connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True) as admin:
  admin.execute('alter function public.math_evaluation(jsonb) owner to postgres')
  admin.execute((R/'supabase/candidates/task16l_learning_persistence/20261104060714_task16l_learning_persistence.sql').read_text())
 ok('postgres_facade_helper_execute',scalar("select has_function_privilege('postgres','math_private.finalize_with_learning(uuid,uuid,jsonb,jsonb)','EXECUTE')"))
 ok('old_evaluations_preserved',old_rows==scalar("select md5(jsonb_agg(to_jsonb(e)-'learning_judgement' order by id)::text) from public.math_evaluations e"))
 def worker(action,payload):return rpc('math_evaluation',[dict(dto_version='math-worker-v1',action=action,payload=payload)],role='math_evaluation_worker')['result']
 # Existing full official synthetic rubric. New attempts use real canonical RPCs.
 full=str(scalar("select id from public.math_subproblems where response_format='PROOF' limit 1"))
 criteria=[dict(criterion_id=str(x[0]),verdict='partially_satisfied',explanation='Synthetic criterion') for x in c.execute('select id from public.math_scoring_criteria where leaf_id=%s',(full,)).fetchall()]
 rpc('essay_admin_grant',[A,4,'admin_grant',new(),'test_account',None],uid=B,role='essay_finance')
 initial=str(rpc('math_submit_attempt',[dict(client_submission_id=new(),leaf_id=full,kind='INITIAL',input_kind='TYPED',typed_answer='Synthetic learning answer')]))
 first=str(rpc('math_request_evaluation',[initial,new()]))
 def output(prior=None):
  answer=copy.deepcopy(out)
  answer['overall']['review_status']='NOT_REQUIRED'
  answer.update(steps=[dict(id=new(),position=1,kind='JUSTIFICATION',representation='Synthetic step',status='VALID',explanation='Synthetic',regions=[])],criteria=criteria,rubric=dict(logical_development='ADEQUATE',justification_completeness='ADEQUATE',final_conclusion='ADEQUATE'))
  if prior:answer['progression']=dict(prior_evaluation_id=prior,target_step_id=None,downstream=None,summary='Synthetic revision',delta=[dict(kind='JUSTIFICATION_IMPROVED',explanation='Synthetic')])
  return answer
 def packet(e,answer,level=2):
  return dict(value=dict(version='learning-completeness-v1',evaluation_id=e,question_id=full,rubric_version='pinned-'+'a'*64,assessed_at=scalar('select clock_timestamp()').isoformat(),status='ASSESSED',level=level,rationale='풀이 근거를 확인했습니다.',criterion_refs=[x['criterion_id'] for x in criteria],criterion_evidence=[dict(criterion_id=x['criterion_id'],rationale='공식 조건 적용 근거 확인') for x in criteria],observation_refs=[answer['steps'][0]['id']],strengths=['조건 확인'],improvements=['설명 보완'],next_direction='적용 조건을 설명하세요.'),review=dict(version='learning-independent-review-v1',candidate_sha256='b'*64,accepted=True))
 answer=output();claim=worker('claim',dict(evaluation_id=first));judgement=packet(first,answer)
 def finalize(e,claim,answer,judgement):return worker('finalize',dict(evaluation_id=e,lease_token=claim['lease_token'],output=answer,learning_judgement=judgement))
 wrong=copy.deepcopy(judgement);wrong['value']['evaluation_id']=new()
 deny('foreign_evaluation_rejected',lambda:finalize(first,claim,answer,wrong))
 wrong=copy.deepcopy(judgement);wrong['value']['criterion_refs']=[new()]
 deny('invented_criteria_rejected',lambda:finalize(first,claim,answer,wrong))
 wrong=copy.deepcopy(judgement);wrong['value']['observation_refs']=[new()]
 deny('invented_observation_rejected',lambda:finalize(first,claim,answer,wrong))
 wrong=copy.deepcopy(judgement);wrong['review']['accepted']=False
 deny('unreviewed_rejected',lambda:finalize(first,claim,answer,wrong))
 ok('rejection_keeps_processing',scalar('select state from public.math_evaluations where id=%s',(first,))=='PROCESSING')
 ok('atomic_save',finalize(first,claim,answer,judgement)==first)
 ledger=scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t')
 ok('same_replay',finalize(first,claim,answer,judgement)==first)
 wrong=copy.deepcopy(judgement);wrong['value']['level']=3
 deny('changed_replay_rejected',lambda:finalize(first,claim,answer,wrong))
 ok('read_saved_level',call('read',dict(evaluation_id=first))['learning_completeness']['level']==2)
 deny('other_student_cannot_read_learning',lambda:call('read',dict(evaluation_id=first),B))
 ok('history_saved_level',call('history',dict(evaluation_id=first))['attempts'][0]['learning_completeness']['level']==2)
 ok('read_replay_no_extra_credit',ledger==scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t'))
 revised=rpc('math_learning',[dict(dto_version='math-learning-v1',action='create_resolve_attempt',payload=dict(client_submission_id=new(),leaf_id=full,kind='FULL_RESOLVE',predecessor_id=initial,prior_evaluation_id=first,target_step_id=None,input_kind='TYPED',typed_answer='Synthetic revised work'))])['result']['attempt_id']
 rr=rpc('math_learning',[dict(dto_version='math-learning-v1',action='request_reevaluation',payload=dict(attempt_id=revised,client_submission_id=new()))])['result']
 ok('free_revision_no_additional_credit',rr['additional_credit']==0)
 second=rr['evaluation_id'];answer2=output(first)
 answer2['criteria']=[dict(x,verdict='satisfied') for x in criteria]
 claim2=worker('claim',dict(evaluation_id=second));judgement2=packet(second,answer2,4)
 finalize(second,claim2,answer2,judgement2)
 comparison=call('read',dict(evaluation_id=second))['learning_comparison']
 ok('same_lineage_delta',comparison['comparable'] and comparison['before']==2 and comparison['after']==4 and comparison['delta']==2)
 ok('criterion_change_evidence',comparison['improved_criterion_ids']==[x['criterion_id'] for x in criteria] and comparison['remaining_criterion_ids']==[])
 ok('criterion_notes_compared',len(comparison['improved_elements'])==len(criteria) and comparison['improved_elements'][0]['rationale']=='공식 조건 적용 근거 확인')
 ok('both_history_levels',sorted(x['learning_completeness']['level'] for x in call('history',dict(evaluation_id=second))['attempts'])==[2,4])
 old_claim=dict(lease_token=str(scalar('select lease_token from public.math_evaluations where id=%s',(eid,))))
 deny('historical_backfill_denied',lambda:finalize(eid,old_claim,out,judgement))
 ok('legacy_no_fabricated_level','learning_completeness' not in call('read',dict(evaluation_id=eid)))
 with c.transaction():
  c.execute('set local role math_executor')
  current=scalar('select learning_judgement from public.math_evaluations where id=%s',(second,))
  previous=scalar('select learning_judgement from public.math_evaluations where id=%s',(first,))
  different=copy.deepcopy(previous);different['value']['rubric_version']='pinned-'+'c'*64
  ok('changed_package_not_comparable',scalar('select math_private.learning_comparison(%s,%s)',(ns['Jsonb'](current),ns['Jsonb'](different)))['reason']=='CRITERIA_CHANGED')
  different=copy.deepcopy(previous);different['metadata']['assessment']['prompt_version']='next'
  ok('changed_prompt_not_comparable',not scalar('select math_private.learning_comparison(%s,%s)',(ns['Jsonb'](current),ns['Jsonb'](different)))['comparable'])
 ok('helper_not_public',not scalar("select has_function_privilege('authenticated','math_private.finalize_with_learning(uuid,uuid,jsonb,jsonb)','EXECUTE')"))

 from task16g_mixed_checks import verify as mixed_verify
 mixed_verify(c,rpc,new,scalar,A,B,ns,m,sock,R)
 with ns['psycopg'].connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True) as admin:
  admin.execute((R/'supabase/candidates/task16l_learning_persistence/mixed.sql').read_text())
 mixed_rows=c.execute("select id,wire from essay_exam_private.runs where wire ? 'exam_id' order by (wire->>'parent_id') nulls first").fetchall()
 root_id,root=mixed_rows[0];revision_id,revision=mixed_rows[1]
 qid=root['result']['questions'][1]['questionId']
 for rid,wire,level in [(root_id,root,2),(revision_id,revision,4)]:
  part=copy.deepcopy(current if level==4 else previous)
  part['value']['evaluation_id']=str(rid)
  wire['result']['questions'][1]['evaluation']['learning_judgement']=part
  c.execute('update essay_exam_private.runs set wire=%s where id=%s',(ns['Jsonb'](wire),rid))
 def mixed(action,rid,uid=A):return rpc('essay_math_coaching',[dict(dto_version='math-coaching-v1',action=action,payload=dict(run_id=str(rid),question_id=qid))],uid=uid)['result']
 ok('mixed_initial_level',mixed('read',root_id)['learning_completeness']['level']==2)
 ok('mixed_revision_comparison',mixed('read',revision_id)['learning_comparison']['delta']==2)
 ok('mixed_history_levels',sorted(x['learning_completeness']['level'] for x in mixed('history',revision_id)['attempts'])==[2,4])
 deny('mixed_other_owner_denied',lambda:mixed('read',root_id,B))
 incomplete=copy.deepcopy(revision);incomplete['state']='processing';c.execute('update essay_exam_private.runs set wire=%s where id=%s',(ns['Jsonb'](incomplete),revision_id))
 deny('mixed_partial_exam_not_exposed',lambda:mixed('read',revision_id))

'''
source=source.replace("  m.o.execute_as_production(c,admin,(candidate/'rollback.sql').read_text())", "  admin.execute((R/'supabase/candidates/task16l_learning_persistence/rollback.sql').read_text())\n  ok('rollback_preserves_saved_learning',scalar('select count(*) from public.math_evaluations where learning_judgement is not null')==2)\n  m.o.execute_as_production(c,admin,(candidate/'rollback.sql').read_text())")
source=source.replace(" before=scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t')",setup+"\n before=scalar('select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t')")
exec(compile(source,str(R/'tool/test_task16f_coaching.py'),'exec'),{'__file__':str(R/'tool/test_task16f_coaching.py'),'__name__':'__main__'})
