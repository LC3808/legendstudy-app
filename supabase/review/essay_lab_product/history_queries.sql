-- READ-ONLY query templates. Set essay_review.user_id / criterion_id / regime_key
-- in a disposable fixture session, or replace with bound parameters in a future API.
-- No private bodies in logs. University/criterion IDs, NEVER labels, identify comparisons.
-- Q1: one student's Hanyang attempts, immutable text and time, in chronological order.
select s.id session_id,a.id attempt_id,a.attempt_no,a.body,a.submitted_at,a.active_writing_seconds,a.character_count
from public.essay_attempts a join public.essay_practice_sessions s on s.id=a.session_id
join public.essay_questions q on q.id=s.question_id join public.essay_exams x on x.id=q.essay_exam_id
join public.universities u on u.id=x.university_id
where s.user_id=current_setting('essay_review.user_id')::uuid and u.slug='hanyang'
order by a.submitted_at,a.id;
-- Q2: every historical result/version, including invalidated records for audit.
select a.attempt_no,e.id evaluation_id,e.contract_version,e.regime_key,e.invalidated_at,d.criterion_id,d.level_1_to_5,d.explanation,
 e.model_provider,e.model_name,e.model_version,e.completed_at
from public.essay_evaluation_dimensions d join public.essay_evaluations e on e.id=d.evaluation_id
join public.essay_attempts a on a.id=e.attempt_id join public.essay_practice_sessions s on s.id=a.session_id
where s.user_id=current_setting('essay_review.user_id')::uuid order by a.submitted_at,e.requested_at,d.display_order;
-- Q3: explicit issue observation timeline, not last-status overwrite.
select i.id issue_id,i.issue_key,p.id progress_id,p.previous_progress_id,a.attempt_no,p.status,p.created_at recorded_at,
 e.id evaluation_id,e.completed_at,p.explanation,e.invalidated_at
from public.essay_improvement_progress p join public.essay_improvement_items i on i.id=p.issue_id
join public.essay_evaluations e on e.id=p.evaluation_id join public.essay_attempts a on a.id=e.attempt_id
join public.essay_practice_sessions s on s.id=p.session_id
where s.user_id=current_setting('essay_review.user_id')::uuid order by i.id,a.submitted_at,e.requested_at,p.id;
-- Q4: last five comparable assessments, one completed evaluation per actual attempt.
with selected as (
 select distinct on (e.attempt_id) e.* from public.essay_evaluations e
 join public.essay_practice_sessions s on s.id=e.session_id
 where s.user_id=current_setting('essay_review.user_id')::uuid and e.status='completed' and e.invalidated_at is null
 and e.regime_key=current_setting('essay_review.regime_key')
 order by e.attempt_id,e.completed_at desc,e.id desc
), recent as (
 select a.submitted_at,e.attempt_id,e.id evaluation_id,d.level_1_to_5,d.criterion_id,e.regime_key
 from selected e join public.essay_attempts a on a.id=e.attempt_id
 join public.essay_evaluation_dimensions d on d.evaluation_id=e.id
 where d.criterion_id=current_setting('essay_review.criterion_id')::uuid
 order by a.submitted_at desc,e.attempt_id desc limit 5
) select * from recent order by submitted_at,attempt_id;
-- Q5: university-specific recurrent categories + reviewed normalized issue identity.
-- A category count is not proof of one identical weakness; NULL/candidate keys are not joined.
select x.university_id,i.normalized_issue_key,i.normalization_version,i.category,
 count(distinct e.attempt_id) observed_attempts,
 array_agg(p.status order by a.submitted_at,e.requested_at) states
from public.essay_improvement_progress p join public.essay_improvement_items i on i.id=p.issue_id
join public.essay_evaluations e on e.id=p.evaluation_id join public.essay_attempts a on a.id=e.attempt_id
join public.essay_practice_sessions s on s.id=e.session_id join public.essay_questions q on q.id=s.question_id
join public.essay_exams x on x.id=q.essay_exam_id
where s.user_id=current_setting('essay_review.user_id')::uuid and e.status='completed' and e.invalidated_at is null
and e.regime_key=current_setting('essay_review.regime_key') and i.normalization_status='reviewed'
and not exists(select 1 from public.essay_evaluations later where later.attempt_id=e.attempt_id and later.regime_key=e.regime_key and later.status='completed' and later.invalidated_at is null and (later.completed_at,later.id)>(e.completed_at,e.id))
group by x.university_id,i.normalized_issue_key,i.normalization_version,i.category;
-- Q6: included revision vs the paid-cycle assessment; same criterion + regime only.
select e1.id before_evaluation,e2.id after_evaluation,d1.criterion_id,d1.level_1_to_5 before_level,d2.level_1_to_5 after_level,
 p1.issue_id,p1.status before_issue_status,p2.status after_issue_status,b.policy_key,b.policy_version,b.reason
from public.essay_billing_decisions b join public.essay_billing_decisions paid on paid.id=b.included_by_decision_id
join public.essay_evaluations e1 on e1.id=paid.evaluation_id join public.essay_evaluations e2 on e2.id=b.evaluation_id
join public.essay_practice_sessions s on s.id=e2.session_id
join public.essay_evaluation_dimensions d1 on d1.evaluation_id=e1.id
join public.essay_evaluation_dimensions d2 on d2.evaluation_id=e2.id and d2.criterion_id=d1.criterion_id
left join public.essay_improvement_progress p1 on p1.evaluation_id=e1.id
left join public.essay_improvement_progress p2 on p2.evaluation_id=e2.id and p2.issue_id=p1.issue_id
where s.user_id=current_setting('essay_review.user_id')::uuid and e1.session_id=e2.session_id
and e1.regime_key=e2.regime_key and e1.invalidated_at is null and e2.invalidated_at is null
and e1.status='completed' and e2.status='completed' and b.status='settled' and paid.status='settled'
and b.reason='included_revision' and b.credits_required=0;
-- Q7: first meaningful view stage plus answer/evaluation times; raw inputs for analysis, not causality.
select v.session_id,v.evaluation_id example_source_evaluation,v.learning_stage,v.stage_attempt_id,v.occurred_at,
 a.attempt_no,a.submitted_at,e.id compared_evaluation,e.completed_at,e.regime_key
from public.essay_learning_events v join public.essay_practice_sessions s on s.id=v.session_id
join public.essay_attempts a on a.session_id=s.id
left join public.essay_evaluations e on e.attempt_id=a.id and e.status='completed' and e.invalidated_at is null
where s.user_id=current_setting('essay_review.user_id')::uuid and v.event_type='essay_example_rewrite_viewed'
order by v.occurred_at,a.submitted_at,e.completed_at;
-- Q8: distinguish model/contract change from student change, including retries.
select a.id attempt_id,e.id evaluation_id,e.contract_version,e.evaluation_version,e.regime_key,
 r.run_no,r.provider,r.model_name,r.model_version,r.status,r.timed_out_at,r.selected_result,r.input_tokens,r.output_tokens,r.cost_amount,r.cost_basis
from public.essay_evaluations e join public.essay_attempts a on a.id=e.attempt_id
join public.essay_practice_sessions s on s.id=e.session_id join public.essay_ai_processing_runs r on r.evaluation_id=e.id
where s.user_id=current_setting('essay_review.user_id')::uuid order by a.submitted_at,e.requested_at,r.run_no;
-- Q9: financial fact history, including zero-charge decisions with no ledger consume.
select b.id decision_id,b.policy_key,b.policy_version,b.reason,b.credits_required,b.status,b.created_at,b.reserved_at,b.settled_at,b.released_at,
 t.id transaction_id,t.transaction_type,t.balance_delta,t.reserved_delta,t.reversal_of,t.created_at posted_at
from public.credit_accounts a join public.essay_billing_decisions b on b.account_id=a.id
left join public.credit_transactions t on t.decision_id=b.id
where a.user_id=current_setting('essay_review.user_id')::uuid order by b.created_at,t.created_at,t.id;
-- Q10: definitively failed evaluations with no consumption and released reservation.
select e.id evaluation_id,b.id decision_id,b.status,b.released_at,
 coalesce(sum(t.balance_delta) filter(where t.transaction_type='consume'),0) consumed_delta,
 coalesce(sum(t.reserved_delta),0) outstanding_reserved
from public.essay_evaluations e join public.essay_practice_sessions s on s.id=e.session_id
join public.essay_billing_decisions b on b.evaluation_id=e.id
left join public.credit_transactions t on t.decision_id=b.id
where s.user_id=current_setting('essay_review.user_id')::uuid and e.status='failed' and b.status='released'
group by e.id,b.id having coalesce(sum(t.balance_delta) filter(where t.transaction_type='consume'),0)=0
and coalesce(sum(t.reserved_delta),0)=0;
-- Q11: reviewed cross-session recurrence candidates; NOT a permanent student weakness master.
with observations as (
 select s.user_id,s.id session_id,i.normalized_issue_key,i.normalization_version,i.category,
 p.status,e.id evaluation_id,a.submitted_at,e.regime_key
 from public.essay_improvement_progress p join public.essay_improvement_items i on i.id=p.issue_id
 join public.essay_evaluations e on e.id=p.evaluation_id join public.essay_attempts a on a.id=e.attempt_id
 join public.essay_practice_sessions s on s.id=e.session_id
 where i.normalization_status='reviewed' and e.status='completed' and e.invalidated_at is null
 and s.user_id=current_setting('essay_review.user_id')::uuid
), transitions as (
 select *,lag(status) over w prior_status,lag(session_id) over w prior_session
 from observations window w as(partition by user_id,normalized_issue_key,normalization_version,regime_key order by submitted_at,evaluation_id)
) select * from transitions where prior_status='resolved' and status in ('open','recurred') and session_id<>prior_session;
-- Q12: university-specific practice counts/time/length; not a cross-university star score.
select x.university_id,count(*) submissions,count(*) filter(where a.attempt_no>1) revisions,
 avg(a.active_writing_seconds) average_active_seconds,
 count(*) filter(where a.conditions_snapshot ? 'length_min' and a.conditions_snapshot ? 'length_max') length_rule_samples,
 count(*) filter(where a.character_count between (a.conditions_snapshot->>'length_min')::int and (a.conditions_snapshot->>'length_max')::int) length_compliant
from public.essay_attempts a join public.essay_practice_sessions s on s.id=a.session_id
join public.essay_questions q on q.id=s.question_id join public.essay_exams x on x.id=q.essay_exam_id
where s.user_id=current_setting('essay_review.user_id')::uuid group by x.university_id;
