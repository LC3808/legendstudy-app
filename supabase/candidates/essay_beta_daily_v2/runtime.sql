-- OWNER APPLY CANDIDATE. No campaign activation, financial writes or run execution.
alter table essay_beta_private.campaigns drop constraint campaigns_check;
alter table essay_beta_private.campaigns add constraint beta_dates check(ends_on>=starts_on);
alter table essay_beta_private.campaigns add column daily_limit integer not null default 1 check(daily_limit=1);
alter table essay_beta_private.campaigns add column policy_version text not null default 'daily-v2' check(policy_version='daily-v2');
alter table essay_beta_private.campaigns add column notice_id uuid;
alter table essay_beta_private.daily_grants add column revision_cutoff timestamptz not null;
create table essay_beta_private.notice_receipts (
 user_id uuid not null references auth.users(id) on delete cascade,
 campaign_id uuid not null references essay_beta_private.campaigns(id),
 policy_version text not null,
 seen_at timestamptz not null default clock_timestamp(),
 primary key(user_id,campaign_id,policy_version)
);
alter table essay_beta_private.notice_receipts enable row level security;
revoke all on essay_beta_private.notice_receipts from public,anon,authenticated,service_role;

create function essay_beta_private.freeze_campaign() returns trigger language plpgsql set search_path='' as $$
begin
 if (new.starts_on,new.ends_on,new.daily_limit,new.policy_version) is distinct from
    (old.starts_on,old.ends_on,old.daily_limit,old.policy_version)
 and exists(select 1 from essay_beta_private.daily_grants where campaign_id=old.id) then
  raise exception 'BETA_ISSUED_POLICY_IMMUTABLE';
 end if;
 return new;
end $$;
create trigger beta_campaign_policy before update on essay_beta_private.campaigns
 for each row execute function essay_beta_private.freeze_campaign();

-- Funding comes from the existing immutable reserve ledger, never a client flag.
create function essay_beta_private.revision_open(p_run uuid) returns boolean
language sql volatile set search_path='' as $$
 select r.completed_at is not null and essay_private.clock()<=r.completed_at+interval '14 days'
 and not exists(select 1 from public.credit_transactions t join essay_beta_private.daily_grants d on d.grant_id=t.grant_id
 where t.decision_id=r.decision_id and t.transaction_type='reserve' and essay_private.clock()>=d.revision_cutoff)
 from essay_exam_private.runs r where r.id=p_run
$$;
create function essay_beta_private.revision_deadline(p_run uuid) returns timestamptz
language sql stable set search_path='' as $$
 select least(r.completed_at+interval '14 days',
 (select min(d.revision_cutoff) from public.credit_transactions t join essay_beta_private.daily_grants d on d.grant_id=t.grant_id
 where t.decision_id=r.decision_id and t.transaction_type='reserve'))
 from essay_exam_private.runs r where r.id=p_run
$$;

create function public.essay_beta_daily_claim_v2() returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); c essay_beta_private.campaigns; d essay_beta_private.daily_grants;
 a uuid; t timestamptz; day date; expiry timestamptz; cutoff timestamptz; g uuid; balance bigint;
begin
 if u is null or account_private.allowed(u) is not true then
  raise sqlstate 'PT403' using message='ACCOUNT_REQUIRED';
 end if;
 perform account_private.lock_subject(u);
 -- Account creation is kept inside the same transaction as a successful claim.
 t:=essay_private.clock(); day:=(t at time zone 'Asia/Seoul')::date;
 select * into c from essay_beta_private.campaigns where enabled order by starts_on desc limit 1 for share;
 if c.id is null then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','inactive');end if;
 cutoff:=(c.ends_on+1)::timestamp at time zone 'Asia/Seoul';
 if t>=cutoff then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','ended','ends_at',cutoff);end if;
 if day<c.starts_on or not exists(select 1 from essay_beta_private.exam_scope where campaign_id=c.id and not has_math and runtime_policy->>'evaluation_type'='humanities') then
  return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','inactive');
 end if;
 insert into public.credit_accounts(user_id) values(u) on conflict(user_id) do nothing;
 select id into a from public.credit_accounts where user_id=u for update;
 -- Sample after both shared locks: a request waiting across midnight uses the new day.
 t:=essay_private.clock(); day:=(t at time zone 'Asia/Seoul')::date;
 if t>=cutoff then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','ended','ends_at',cutoff);end if;
 select * into d from essay_beta_private.daily_grants where user_id=u and grant_day=day;
 if d.grant_id is null then
  expiry:=(day+1)::timestamp at time zone 'Asia/Seoul';
  g:=essay_private.credit_post_grant(u,1,'promotion','lab-beta:daily:'||u||':'||day,
   'essay_beta_daily','beta_campaign/'||c.id,expiry);
  insert into essay_beta_private.daily_grants(user_id,grant_day,campaign_id,grant_id,revision_cutoff) values(u,day,c.id,g,cutoff);
 else
  g:=d.grant_id;
  select expires_at into expiry from public.credit_grants where id=g;
 end if;
 select greatest(0,coalesce(sum(balance_delta-reserved_delta),0)) into balance from public.credit_transactions where grant_id=g;
 return jsonb_build_object('version','essay-beta-credit-v2','active',true,'status','active','grant_id',g,'day',day,
  'available',case when expiry>essay_private.clock() and (d.grant_id is null or d.campaign_id=c.id) then balance else 0 end,
  'expires_at',expiry,'ends_at',cutoff,'campaign_id',c.id,'policy_version',c.policy_version,'notice_id',c.notice_id,
  'notice_seen',exists(select 1 from essay_beta_private.notice_receipts where user_id=u and campaign_id=c.id and policy_version=c.policy_version));
end $$;
-- Compatibility for the previous clients; new clients require v2 before showing the new policy.
create or replace function public.essay_beta_daily_claim() returns jsonb
language sql security definer set search_path='' as $$
 select public.essay_beta_daily_claim_v2()||jsonb_build_object('version','essay-beta-credit-v1')
$$;
create function public.essay_beta_notice_ack(p_campaign uuid) returns void
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();
begin
 if u is null or account_private.allowed(u) is not true then raise sqlstate 'PT403' using message='ACCOUNT_REQUIRED';end if;
 perform account_private.lock_subject(u);
 insert into essay_beta_private.notice_receipts(user_id,campaign_id,policy_version)
 select u,c.id,c.policy_version from essay_beta_private.campaigns c
 where c.id=p_campaign and exists(select 1 from essay_beta_private.daily_grants d where d.user_id=u and d.campaign_id=c.id)
 on conflict do nothing;
end $$;
revoke all on function essay_beta_private.freeze_campaign(),essay_beta_private.revision_open(uuid),essay_beta_private.revision_deadline(uuid) from public,anon,authenticated,service_role;
revoke all on function public.essay_beta_daily_claim_v2(),public.essay_beta_notice_ack(uuid) from public,anon,service_role;
grant execute on function public.essay_beta_daily_claim_v2(),public.essay_beta_notice_ack(uuid) to authenticated;
