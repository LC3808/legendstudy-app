-- Disable new entry points; preserve any append-only reviews already recorded.
begin;
revoke execute on function public.ql_exam_cases(timestamptz,timestamptz,integer,boolean),public.ql_exam_detail(uuid,text),public.ql_exam_submit(jsonb),public.admin_exam_learning(timestamptz,timestamptz) from authenticated;
-- Restore cost-before.sql separately in the same maintenance transaction if needed.
-- Never drop HQP columns/constraints or delete review records during rollback.
commit;
