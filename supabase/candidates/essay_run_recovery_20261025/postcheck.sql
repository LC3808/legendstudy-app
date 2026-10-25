-- Run before dispatch. After successful evaluation billing will legitimately settle.
select r.state='reserved' as run_id_preserved,
 md5(r.snapshot::text)='d36c1fc9189435f3c38b7b0e127263ba' as snapshot_preserved,
 md5(b::text)='a196fa4509f6dfbdaee6520425d4e423' as billing_unchanged,
 (select md5(jsonb_agg(to_jsonb(c) order by key)::text) from essay_exam_private.checkpoints c where c.run_id=r.id and key<>'owner-reconcile-20261025')='157146af4de2738b93259a0f4f970e6f' as all_old_checkpoints_preserved,
 (select count(*)=1 from essay_exam_private.retry_requests t where t.run_id=r.id and generation=1 and request_key='76aab261-c008-453d-91e6-b43a5fc477fd' and attempts='{"1":1,"2":1}'::jsonb) as only_incomplete_questions_retried,
 exists(select 1 from essay_exam_private.checkpoints c where c.run_id=r.id and key='owner-reconcile-20261025') as reconciliation_audited
from essay_exam_private.runs r join public.essay_billing_decisions b on b.id=r.decision_id
where r.id='b2cbc55f-edc7-423d-bfdc-f5d039b215e5';
