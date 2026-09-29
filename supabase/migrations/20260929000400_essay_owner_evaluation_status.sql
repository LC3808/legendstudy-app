-- Owner-authorized L1 blocker resolution. Read-only projection, no new status truth.
-- Production apply only after isolated PostgreSQL/JWT validation and exact preflight.
begin;
grant essay_executor to current_user;
grant create on schema public to essay_executor;
-- Caller authenticated owner; STABLE uses one caller snapshot across domain reads.
-- No user_id input, locking, mutation, telemetry disclosure, or provider call.
create function public.essay_evaluation_status(p_evaluation uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare
 u uuid=essay_private.uid(); e public.essay_evaluations; b public.essay_billing_decisions;
 r public.essay_ai_processing_runs; at_time timestamptz=essay_private.clock();
 reserved bigint=0; consumed bigint=0; released bigint=0; per_grant_closed boolean=true;
 release_ok boolean=false; zero_ok boolean=false; settled_ok boolean=false;
 student_state text='reconciling'; credit_state text='pending'; credit_mode text='pending';
begin
 if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED';end if;
 select ev.* into e from public.essay_evaluations ev
 join public.essay_attempts a on a.id=ev.attempt_id and a.session_id=ev.session_id
 join public.essay_practice_sessions s on s.id=a.session_id and s.question_id=ev.question_id
 where ev.id=p_evaluation and s.user_id=u;
 -- Same response for missing, erased, and foreign records; no existence oracle.
 if e.id is null then raise sqlstate 'PT404' using message='NOT_FOUND';end if;
 select bd.* into b from public.essay_billing_decisions bd
 join public.credit_accounts ca on ca.id=bd.account_id and ca.user_id=u where bd.evaluation_id=e.id;
 select * into r from public.essay_ai_processing_runs where evaluation_id=e.id
 order by run_no desc limit 1; -- rewrite jobs have rewrite_id instead; never affect evaluation state.
 if b.id is not null then
  select coalesce(sum(g.reserved),0),coalesce(sum(g.consumed),0),coalesce(sum(g.released),0),
   coalesce(bool_and(g.reserved=g.consumed+g.released),true)
  into reserved,consumed,released,per_grant_closed from (
   select grant_id,
    coalesce(sum(reserved_delta) filter(where transaction_type='reserve'),0) reserved,
    coalesce(sum(-balance_delta) filter(where transaction_type='consume'),0) consumed,
    coalesce(sum(-reserved_delta) filter(where transaction_type='release'),0) released
   from public.credit_transactions where decision_id=b.id and account_id=b.account_id group by grant_id
  ) g;
  credit_mode=case when b.credits_required=0 then 'included' else 'paid' end;
  release_ok=b.status='released' and b.released_at is not null and consumed=0
    and reserved=released and per_grant_closed;
  zero_ok=b.credits_required=0 and b.status in ('authorized','settled')
    and reserved=0 and consumed=0 and released=0;
  settled_ok=b.status='settled' and b.settled_at is not null and per_grant_closed
    and reserved=b.credits_required and consumed=b.credits_required and released=0;
  credit_state=case when release_ok then 'released'
   when settled_ok then 'settled'
   when zero_ok then 'included'
   when b.status='reserved' and reserved=b.credits_required and consumed=0 and released=0 then 'reserved'
   else 'pending' end;
 end if;
 if e.status='completed' and e.invalidated_at is null and e.output_sha256 is not null
   and e.overall_summary is not null and settled_ok then student_state='completed';
 elsif e.status in ('failed','cancelled') then student_state='failed';
 elsif e.status in ('requested','processing') and credit_state in ('reserved','included') then
  if r.id is null and e.status='requested' and e.requested_at+interval '15 minutes'>at_time then
   student_state='processing';
  elsif r.status='processing' and r.lease_expires_at>at_time then student_state='processing';
  end if;
 end if;
 return jsonb_build_object('state',student_state,'credit_state',credit_state,'credit_mode',credit_mode,
  'release_confirmed',release_ok,'no_credit_consumed',student_state<>'reconciling' and (release_ok or zero_ok));
end$$;
alter function public.essay_evaluation_status(uuid) owner to essay_executor;
revoke all on function public.essay_evaluation_status(uuid) from public,anon,authenticated,service_role,essay_worker,essay_finance;
grant execute on function public.essay_evaluation_status(uuid) to authenticated;
revoke create on schema public from essay_executor;
revoke essay_executor from current_user;
commit;
