-- Owner-only rollback. New Quality objects ONLY; no CASCADE. Unexpected dependency aborts.
-- Capture any needed allowlist registration metadata privately before approved rollback.
begin;
set local lock_timeout='5s';
drop function public.ql_case_detail(uuid);
drop function public.ql_list_cases(integer,timestamptz,uuid);
drop function public.is_quality_operator();
drop table public.quality_operators;
commit;
-- SQL rollback and migration ledger rollback are separate Owner-reviewed operations.
-- Do not change provider005/day_targets tracking here.
