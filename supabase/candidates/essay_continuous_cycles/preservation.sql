-- Read-only before/after fingerprints; no answers, credentials or balances output.
-- Execute under a short no-submission window. Unrelated live IAP activity can change Ledger.
select 'registry' as dataset,count(*) as rows,md5(coalesce(string_agg(to_jsonb(q)::text,'' order by q.id),'')) as digest from public.essay_questions q
union all
select 'runs',count(*),md5(coalesce(string_agg((to_jsonb(r)-'previous_paid_run_id'-'submission_index')::text,'' order by r.id),'')) from essay_exam_private.runs r
union all
select 'ledger',count(*),md5(coalesce(string_agg(to_jsonb(t)::text,'' order by t.id),'')) from public.credit_transactions t;

select 'package_revisions' as dataset,count(*) as rows,md5(coalesce(string_agg(to_jsonb(r)::text,'' order by r.exam_id,r.revision),'')) as digest from essay_material_private.revisions r;
