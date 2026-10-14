-- Empty candidate installations only. Never erase submitted answers or Ledger rows.
begin;
do $$begin
 if exists(select 1 from essay_exam_private.runs) then raise exception 'NONEMPTY_EXAM_ROLLBACK_DENIED';end if;
end$$;
drop trigger essay_exam_account_erasure on public.credit_accounts;
drop function essay_exam_private.erase_account_runs();
drop function public.essay_exam_preflight(uuid,uuid);
drop function public.essay_exam_submit(uuid,uuid,uuid,jsonb,uuid);
drop function public.essay_exam_claim(uuid,uuid,uuid);
drop function public.essay_exam_finish(uuid,uuid,uuid,jsonb,boolean);
drop function public.essay_exam_history(uuid);
drop function essay_exam_private.runtime_policy(uuid);
drop function essay_exam_private.finish(uuid,jsonb,boolean);
drop function essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid);
drop table essay_exam_private.runs;
drop function essay_exam_private.guard();
drop schema essay_exam_private;
-- Remove these only when installed from this candidate, never shared deployed policy.
drop function essay_private.provider_binding_valid(text,jsonb);
drop function essay_private.provider_policy(text);
commit;
