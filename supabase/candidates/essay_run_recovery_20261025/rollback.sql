-- Separate OWNER APPROVAL before fallback. Never delete retry/history/ledger records.
-- Release only via existing finalization policy after ALL dispatch leases expire.
begin;
set local lock_timeout='5s';set local statement_timeout='15s';
do $release$
declare r essay_exam_private.runs;
begin
 select * into r from essay_exam_private.runs where id='b2cbc55f-edc7-423d-bfdc-f5d039b215e5';
 perform 1 from public.credit_accounts where id=r.account_id for update;
 select * into r from essay_exam_private.runs where id=r.id for update;
 if r.id is null then raise exception 'RUN_NOT_FOUND';end if;
 if r.state='failed' then return;end if;
 if r.state<>'reserved' or r.lease_until>=clock_timestamp()-interval '2 minutes'
 or exists(select 1 from essay_exam_private.retry_requests where run_id=r.id and lease_until>=clock_timestamp()-interval '2 minutes')
 or exists(select 1 from essay_exam_private.checkpoints where run_id=r.id and key='final')
 then raise exception 'RELEASE_NOT_SAFE';end if;
 perform essay_exam_private.finish(r.id,null,true);
end $release$;
commit;
