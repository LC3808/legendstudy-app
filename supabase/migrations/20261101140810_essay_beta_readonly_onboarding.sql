-- Additive read-only onboarding; existing allocation/reservation/settlement unchanged.
create function essay_beta_private.daily_status() returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); c essay_beta_private.campaigns; d essay_beta_private.daily_grants;
 t timestamptz:=essay_private.clock(); day date; cutoff timestamptz; starts timestamptz;
 expiry timestamptz; balance bigint; lim integer:=1; cfg jsonb;
begin
 if u is null or account_private.allowed(u) is not true then raise sqlstate 'PT403' using message='ACCOUNT_REQUIRED';end if;
 day:=(t at time zone 'Asia/Seoul')::date;
 select * into c from essay_beta_private.campaigns where enabled order by starts_on desc limit 1;
 if c.id is null then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','inactive');end if;
 cutoff:=(c.ends_on+1)::timestamp at time zone 'Asia/Seoul';
 starts:=c.starts_on::timestamp at time zone 'Asia/Seoul';
 -- Respect the existing optional admin extension without requiring its installation.
 if to_regprocedure('essay_beta_private.operations(uuid)') is not null then
  execute 'select to_jsonb(essay_beta_private.operations($1))' into cfg using c.id;
  if cfg->>'campaign_id' is null or (cfg->>'beta_enabled')::boolean is not true then
   return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','inactive');
  end if;
  cutoff:=(cfg->>'beta_end_at')::timestamptz; starts:=(cfg->>'beta_start_at')::timestamptz;
  lim:=case when t>=(cfg->>'limit_effective_at')::timestamptz then (cfg->>'next_daily_limit')::integer else (cfg->>'daily_free_limit')::integer end;
 end if;
 if t>=cutoff then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','ended','ends_at',cutoff);end if;
 if t<starts or not exists(select 1 from essay_beta_private.exam_scope where campaign_id=c.id and not has_math and runtime_policy->>'evaluation_type'='humanities') then
  return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','inactive');
 end if;
 select * into d from essay_beta_private.daily_grants where user_id=u and grant_day=day;
 expiry:=least((day+1)::timestamp at time zone 'Asia/Seoul',cutoff);
 balance:=lim;
 if d.grant_id is not null then
  select least(expires_at,cutoff) into expiry from public.credit_grants where id=d.grant_id;
  select greatest(0,coalesce(sum(balance_delta-reserved_delta),0)),coalesce(sum(balance_delta) filter(where transaction_type='promotion'),1)
   into balance,lim from public.credit_transactions where grant_id=d.grant_id;
  if d.campaign_id<>c.id or expiry<=t then balance:=0;end if;
 end if;
 return jsonb_build_object('version','essay-beta-credit-v2','active',true,'status','active',
 'grant_id',coalesce(d.grant_id::text,''),'day',day,'available',balance,'daily_limit',lim,
 'expires_at',expiry,'ends_at',cutoff,'campaign_id',c.id,'policy_version',c.policy_version,'notice_id',c.notice_id,
 'notice_seen',exists(select 1 from essay_beta_private.notice_receipts where user_id=u and campaign_id=c.id and policy_version=c.policy_version));
end $$;
revoke all on function essay_beta_private.daily_status() from public,anon,service_role;
grant execute on function essay_beta_private.daily_status() to authenticated;
-- Public entrypoint has the same auth.uid-bound authorization, no parameters.
create function public.essay_beta_daily_status_v2() returns jsonb
language sql security definer set search_path='' as $$select essay_beta_private.daily_status()$$;
revoke all on function public.essay_beta_daily_status_v2() from public,anon,service_role;
grant execute on function public.essay_beta_daily_status_v2() to authenticated;
