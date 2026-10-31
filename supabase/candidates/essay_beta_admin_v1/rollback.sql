-- Feature disable, not destructive schema rollback. Run as authenticated approved Owner.
-- Use existing auth session; never paste tokens into source control.
begin;
do $$declare item jsonb;c jsonb;lim integer;begin
 for item in select value from jsonb_array_elements(public.admin_essay_beta_config()->'campaigns') loop
  c:=item->'config';
  if c is null or c='null'::jsonb then continue;end if;
  lim:=case when clock_timestamp()>=(c->>'limit_effective_at')::timestamptz then (c->>'next_daily_limit')::integer else (c->>'daily_free_limit')::integer end;
  perform public.admin_essay_beta_save((item->>'campaign_id')::uuid,(c->>'version')::integer,
   jsonb_build_object('beta_enabled',false,'beta_start_at',c->>'beta_start_at',
   'beta_end_at',c->>'beta_end_at','daily_free_limit',lim,'reset_timezone','Asia/Seoul','limit_application','immediate'),
   'Emergency beta feature rollback');
 end loop;
end $$;
commit;
-- Retain grant snapshots, audit, history and accepted-job settlement.
-- Revert WEB/APP UI separately. Do not restore one-credit runtime with active multi-credit grants.
