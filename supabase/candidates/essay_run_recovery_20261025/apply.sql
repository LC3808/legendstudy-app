-- OWNER APPROVAL REQUIRED. Exact abandoned run only; no ledger/reservation writes.
-- Append a retry generation for Q3 failed + Q2 abandoned. Q1 success is reused.
begin;
set local lock_timeout='5s';set local statement_timeout='15s';
do $recovery$
declare r essay_exam_private.runs; b public.essay_billing_decisions; old_hash text;
begin
 select * into r from essay_exam_private.runs where id='b2cbc55f-edc7-423d-bfdc-f5d039b215e5';
 perform 1 from public.credit_accounts where id=r.account_id for update;
 select * into r from essay_exam_private.runs where id=r.id for update;
 select * into b from public.essay_billing_decisions where id=r.decision_id for update;
 if exists(select 1 from essay_exam_private.retry_requests where run_id=r.id) then raise exception 'RECOVERY_ALREADY_STARTED';end if;
 if r.id is null or r.state<>'reserved' or r.exam_id<>'d420ef29-218a-57fd-8524-842a0e551714'
 or r.lease_until is null or r.lease_until>=clock_timestamp()-interval '2 minutes'
 or md5(r.snapshot::text)<>'d36c1fc9189435f3c38b7b0e127263ba'
 or b.id is null or b.status<>'reserved' or b.credits_required<>1
 or md5(b::text)<>'a196fa4509f6dfbdaee6520425d4e423' then raise exception 'RECOVERY_BASELINE_CHANGED';end if;
 perform 1 from essay_exam_private.checkpoints where run_id=r.id for update;
 select md5(jsonb_agg(to_jsonb(c) order by key)::text) into old_hash from essay_exam_private.checkpoints c where run_id=r.id;
 if old_hash is distinct from '157146af4de2738b93259a0f4f970e6f' then raise exception 'CHECKPOINT_BASELINE_CHANGED';end if;
 -- Old pending writer/receipt remains immutable. New attempt uses separate keys.
 -- Operator disposition: expired delivery, primary receipt exists, no reviewed output.
 insert into essay_exam_private.checkpoints(run_id,key,writer,state,payload)
 values(r.id,'owner-reconcile-20261025',gen_random_uuid(),'checkpoint',jsonb_build_object(
 'reason','EXPIRED_DELIVERY_BEFORE_REVIEW_START_PERSISTED','preserved_checkpoint_md5',old_hash,
 'preserved_success_indices',jsonb_build_array(0),'retry_indices',jsonb_build_array(1,2),
 'owner_approved_sql','essay_run_recovery_20261025','recorded_at',clock_timestamp()));
 insert into essay_exam_private.retry_requests(run_id,request_key,generation,attempts)
 values(r.id,'76aab261-c008-453d-91e6-b43a5fc477fd',1,'{"1":1,"2":1}'::jsonb);
end $recovery$;
commit;
