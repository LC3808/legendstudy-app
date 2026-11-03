-- Additive continuation contract. Existing immutable attempts and ledger are reused.
begin;
alter table math_private.session_runs add column previous_run_id uuid references math_private.session_runs(id), add column submission_index integer;
create unique index math_session_one_live_successor on math_private.session_runs(student_id,previous_run_id) where previous_run_id is not null and state<>'cancelled';

create function math_private.cycle_deadline(p_decision uuid,p_completed timestamptz) returns timestamptz
language plpgsql stable security definer set search_path='' as $$
declare expiry timestamptz;
begin
 -- Existing beta grants carry their authoritative expiry. Ordinary grants do not shorten 14 days.
 select min(g.expires_at) into expiry from public.credit_transactions t join public.credit_grants g on g.id=t.grant_id
 where t.decision_id=p_decision and t.transaction_type='consume' and essay_beta_private.is_beta(g.id);
 return least(p_completed+interval '336 hours',expiry);
end$$;
revoke all on function math_private.cycle_deadline(uuid,timestamptz) from public,anon,authenticated,service_role;
grant execute on function math_private.cycle_deadline(uuid,timestamptz) to essay_executor;

create function public.math_session_quote(p_previous uuid) returns jsonb
language plpgsql volatile security definer set search_path='' as $$
declare r math_private.session_runs; root math_private.session_runs; free boolean;
begin
 perform math_private.require_active(array[auth.uid()]);
 select * into r from math_private.session_runs where id=p_previous and student_id=auth.uid();
 if not found then raise insufficient_privilege;end if;
 select * into root from math_private.session_runs where id=coalesce(r.parent_id,r.id);
 if r.state<>'completed' then raise invalid_parameter_value using message='PREVIOUS_ROUND_INCOMPLETE';end if;
 free=r.parent_id is null and clock_timestamp()<math_private.cycle_deadline(root.decision_id,root.completed_at)
 and not exists(select 1 from math_private.session_runs where parent_id=root.id and state<>'cancelled')
 and not exists(select 1 from public.credit_transactions where decision_id=root.decision_id and transaction_type='refund');
 return jsonb_build_object('version','math-session-quote-v1','previous_run_id',r.id,'exam_id',r.exam_id,'credits_required',case when free then 0 else 1 end,
 'included_parent_id',case when free then root.id else null end,'free_expires_at',math_private.cycle_deadline(root.decision_id,root.completed_at),'submission_index',coalesce(r.submission_index,case when r.parent_id is null then 1 else 2 end)+1);
end$$;
revoke all on function public.math_session_quote(uuid) from public,anon,authenticated,service_role;
grant execute on function public.math_session_quote(uuid) to authenticated;

create function public.math_session_continue(p_exam uuid,p_key uuid,p_attempts uuid[],p_previous uuid,p_expected_credits integer) returns uuid
language plpgsql volatile security definer set search_path='' as $$
declare u uuid=auth.uid(); account uuid; previous math_private.session_runs; existing math_private.session_runs; ids uuid[]; quote jsonb; result uuid;
begin
 perform math_private.require_active(array[u]);
 select id into account from public.credit_accounts where user_id=u for update;
 if account is null then raise insufficient_privilege;end if;
 if p_expected_credits is null or p_expected_credits not in (0,1) or p_key is null or p_exam is null or coalesce(cardinality(p_attempts),0) not between 1 and 100 then raise invalid_parameter_value;end if;
 select array_agg(x order by x) into ids from unnest(p_attempts) x;
 select * into existing from math_private.session_runs where student_id=u and request_key=p_key;
 if found then
  if existing.exam_id<>p_exam or existing.attempt_ids<>ids or existing.previous_run_id is distinct from p_previous
   or (select credits_required from public.essay_billing_decisions where id=existing.decision_id)<>p_expected_credits then raise unique_violation using message='SESSION_REPLAY_CONFLICT';end if;
  return existing.id;
 end if;
 if p_previous is null then
  if p_expected_credits<>1 then raise invalid_parameter_value using message='CHARGE_CHANGED';end if;
  result=public.math_session_submit(p_exam,p_key,p_attempts,null);
  update math_private.session_runs set submission_index=1 where id=result;
  return result;
 end if;
 select * into previous from math_private.session_runs where id=p_previous and student_id=u for update;
 if not found or previous.exam_id<>p_exam then raise insufficient_privilege;end if;
 if exists(select 1 from math_private.session_runs where previous_run_id=previous.id and state<>'cancelled') then raise unique_violation using message='ROUND_ALREADY_CONTINUED';end if;
 quote=public.math_session_quote(previous.id);
 if (quote->>'credits_required')::integer<>p_expected_credits then raise invalid_parameter_value using message='CHARGE_CHANGED';end if;
 if (select array_agg(leaf_id order by leaf_id) from public.math_attempts where id=any(ids) and student_id=u) is distinct from (select array_agg(leaf_id order by leaf_id) from math_private.session_members where run_id=previous.id) then raise invalid_parameter_value using message='FROZEN_QUESTION_SET';end if;
 if exists(select 1 from public.math_attempts child where child.id=any(ids) and not exists(
  select 1 from math_private.session_members pm join math_private.session_evaluations x on x.attempt_id=pm.attempt_id join public.math_evaluations e on e.id=x.evaluation_id
  where pm.run_id=previous.id and pm.leaf_id=child.leaf_id and child.predecessor_id=pm.attempt_id and child.prior_evaluation_id=e.id and e.state='COMPLETED')) then raise invalid_parameter_value using message='INVALID_REWRITE_SOURCE';end if;
 result=public.math_session_submit(p_exam,p_key,p_attempts,(quote->>'included_parent_id')::uuid);
 update math_private.session_runs set previous_run_id=previous.id,submission_index=(quote->>'submission_index')::integer where id=result;
 return result;
end$$;
revoke all on function public.math_session_continue(uuid,uuid,uuid[],uuid,integer) from public,anon,authenticated,service_role;
grant execute on function public.math_session_continue(uuid,uuid,uuid[],uuid,integer) to authenticated;

alter function public.math_session_read(uuid) rename to math_session_read_before_task16g;
revoke all on function public.math_session_read_before_task16g(uuid) from public,anon,authenticated,service_role;
create function public.math_session_read(p_run uuid) returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare answer jsonb; r math_private.session_runs; quote jsonb;
begin
 answer=public.math_session_read_before_task16g(p_run);
 select * into r from math_private.session_runs where id=p_run and student_id=auth.uid();
 if not found then raise insufficient_privilege;end if;
 if r.state='completed' then quote=public.math_session_quote(r.id);end if;
 return answer||jsonb_build_object('previous_run_id',r.previous_run_id,'submission_index',coalesce(r.submission_index,case when r.parent_id is null then 1 else 2 end),'continuous_cycles_supported',true,'next_quote',quote,
 'free_rewrite_available',coalesce((quote->>'credits_required')::integer=0,false),'credits_required',(select credits_required from public.essay_billing_decisions where id=r.decision_id));
end$$;
revoke all on function public.math_session_read(uuid) from public,anon,authenticated,service_role;
grant execute on function public.math_session_read(uuid) to authenticated;

-- Update only recognized source clauses; retain beta allocator/lease/owner/idempotency logic.
grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema math_private to essay_executor;
set role essay_executor;
do $$declare definition text;begin
 definition=pg_get_functiondef('math_private.authorize_billing(uuid)'::regprocedure);
 if position('pe.request_kind=''MATH_INITIAL_EVALUATION''' in definition)=0 then raise exception 'UNEXPECTED_MATH_BILLING_BODY';end if;
 definition=replace(definition,'pe.request_kind=''MATH_INITIAL_EVALUATION''','pe.id=(select latest.id from public.math_evaluations latest join public.math_attempts la on la.id=latest.attempt_id join public.math_billing_bindings lb on lb.math_evaluation_id=latest.id join public.essay_billing_decisions ld on ld.id=lb.billing_decision_id where la.lineage_id=a.lineage_id and la.student_id=a.student_id and latest.state=''COMPLETED'' and ld.reason=''paid_cycle'' and ld.status=''settled'' order by latest.completed_at desc,latest.id desc limit 1)');
 definition=replace(definition,'pe.completed_at+interval ''336 hours''','math_private.cycle_deadline(d.id,pe.completed_at)');
 execute definition;
end$$;
reset role;
revoke create on schema math_private from essay_executor;
revoke essay_executor from postgres granted by postgres;
do $$declare definition text;begin
 definition=pg_get_functiondef('math_private.learning_eligibility(uuid,timestamptz)'::regprocedure);
 if position('e.request_kind=''MATH_INITIAL_EVALUATION''' in definition)=0 then raise exception 'UNEXPECTED_MATH_ELIGIBILITY_BODY';end if;
 definition=replace(definition,'e.request_kind=''MATH_INITIAL_EVALUATION''','exists(select 1 from public.math_billing_bindings b join public.essay_billing_decisions d on d.id=b.billing_decision_id where b.math_evaluation_id=e.id and d.reason=''paid_cycle'' and d.status=''settled'')');
 definition=replace(definition,'initial.completed_at+interval ''336 hours''','math_private.cycle_deadline(decision.id,initial.completed_at)');
 execute definition;
 -- Existing free submit and eligibility use the same beta/14-day deadline.
 definition=pg_get_functiondef('public.math_session_submit(uuid,uuid,uuid[],uuid)'::regprocedure);
 definition=replace(definition,'parent.completed_at+interval ''336 hours''','math_private.cycle_deadline(parent.decision_id,parent.completed_at)');
 execute definition;
 definition=pg_get_functiondef('math_private.session_eligibility(uuid,timestamptz)'::regprocedure);
 definition=replace(definition,'root.completed_at+interval ''336 hours''','math_private.cycle_deadline(root.decision_id,root.completed_at)');
 execute definition;
end$$;
commit;
