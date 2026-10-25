select r.state='reserved' as existing_run_reserved,
 r.lease_until<clock_timestamp()-interval '2 minutes' as old_delivery_expired,
 md5(r.snapshot::text)='d36c1fc9189435f3c38b7b0e127263ba' as snapshot_preserved,
 b.status='reserved' and b.credits_required=1 as one_existing_reservation,
 md5(b::text)='a196fa4509f6dfbdaee6520425d4e423' as billing_baseline,
 (select md5(jsonb_agg(to_jsonb(c) order by key)::text) from essay_exam_private.checkpoints c where c.run_id=r.id)='157146af4de2738b93259a0f4f970e6f' as exact_checkpoint_baseline,
 not exists(select 1 from essay_exam_private.retry_requests t where t.run_id=r.id) as no_previous_retry,
 not exists(select 1 from essay_exam_private.checkpoints c where c.run_id=r.id and key='final') as no_final_result
from essay_exam_private.runs r join public.essay_billing_decisions b on b.id=r.decision_id
where r.id='b2cbc55f-edc7-423d-bfdc-f5d039b215e5';
