create or replace function public.essay_beta_daily_claim_v2() returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); c essay_beta_private.campaigns; d essay_beta_private.daily_grants;
 a uuid; t timestamptz; day date; expiry timestamptz; cutoff timestamptz; g uuid; balance bigint; cfg essay_beta_private.operations_config; lim integer;
begin
 if u is null or account_private.allowed(u) is not true then
  raise sqlstate 'PT403' using message='ACCOUNT_REQUIRED';
 end if;
 perform account_private.lock_subject(u);
 -- Account creation is kept inside the same transaction as a successful claim.
 t:=essay_private.clock(); day:=(t at time zone 'Asia/Seoul')::date;
 select * into c from essay_beta_private.campaigns where enabled order by starts_on desc limit 1 for share;
 if c.id is null then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','inactive');end if;
 cfg:=essay_beta_private.operations(c.id);
 if cfg.campaign_id is null or not cfg.beta_enabled then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','inactive');end if;
 cutoff:=cfg.beta_end_at;
 lim:=case when t>=cfg.limit_effective_at then cfg.next_daily_limit else cfg.daily_free_limit end;
 lim:=case when t>=cfg.limit_effective_at then cfg.next_daily_limit else cfg.daily_free_limit end;
 if t>=cutoff then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','ended','ends_at',cutoff);end if;
 if t<cfg.beta_start_at or not exists(select 1 from essay_beta_private.exam_scope where campaign_id=c.id and not has_math and runtime_policy->>'evaluation_type'='humanities') then
  return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','inactive');
 end if;
 insert into public.credit_accounts(user_id) values(u) on conflict(user_id) do nothing;
 select id into a from public.credit_accounts where user_id=u for update;
 -- Sample after both shared locks: a request waiting across midnight uses the new day.
 t:=essay_private.clock(); day:=(t at time zone 'Asia/Seoul')::date;
 lim:=case when t>=cfg.limit_effective_at then cfg.next_daily_limit else cfg.daily_free_limit end;
 if t>=cutoff then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','ended','ends_at',cutoff);end if;
 select * into d from essay_beta_private.daily_grants where user_id=u and grant_day=day;
 if d.grant_id is null then
  expiry:=(day+1)::timestamp at time zone 'Asia/Seoul';
  g:=essay_private.credit_post_grant(u,lim,'promotion','lab-beta:daily:'||u||':'||day,
   'essay_beta_daily','beta_campaign/'||c.id,expiry);
  insert into essay_beta_private.daily_grants(user_id,grant_day,campaign_id,grant_id,revision_cutoff) values(u,day,c.id,g,cutoff);
 else
  g:=d.grant_id;
  select expires_at into expiry from public.credit_grants where id=g;
 end if;
 select greatest(0,coalesce(sum(balance_delta-reserved_delta),0)) into balance from public.credit_transactions where grant_id=g;
 return jsonb_build_object('version','essay-beta-credit-v2','active',true,'status','active','grant_id',g,'day',day,
  'available',case when expiry>essay_private.clock() and (d.grant_id is null or d.campaign_id=c.id) then balance else 0 end,
  'daily_limit',case when d.grant_id is null then lim else (select sum(balance_delta) from public.credit_transactions where grant_id=g and transaction_type='promotion') end,
 'expires_at',least(expiry,cutoff),'ends_at',cutoff,'campaign_id',c.id,'policy_version',c.policy_version,'notice_id',c.notice_id,
  'notice_seen',exists(select 1 from essay_beta_private.notice_receipts where user_id=u and campaign_id=c.id and policy_version=c.policy_version));
end $$;

CREATE OR REPLACE FUNCTION essay_beta_private.eligible(p_grant uuid, p_exam uuid)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$
 select exists(
  select 1 from essay_beta_private.daily_grants d
  join essay_beta_private.campaigns c on c.id=d.campaign_id
  join essay_beta_private.exam_scope s on s.campaign_id=c.id and s.exam_id=p_exam
  join public.credit_grants g on g.id=d.grant_id
  where d.grant_id=p_grant and c.enabled
  and essay_beta_private.operations_open(c.id)
  and d.grant_day=(essay_private.clock() at time zone 'Asia/Seoul')::date
  and g.expires_at>essay_private.clock()
  and s.runtime_policy=essay_exam_private.runtime_policy(p_exam)
  and (select array_agg(q.id order by q.id) from public.essay_questions q where q.essay_exam_id=p_exam)
      =(select array_agg(q order by q) from unnest(s.question_ids) q)
  and not s.has_math and s.runtime_policy->>'evaluation_type'='humanities'
 )
$function$
;
create or replace function essay_beta_private.revision_open(p_run uuid) returns boolean
language sql volatile set search_path='' as $$
 select r.completed_at is not null and essay_private.clock()<=r.completed_at+interval '14 days'
 and not exists(select 1 from public.credit_transactions t join essay_beta_private.daily_grants d on d.grant_id=t.grant_id
 where t.decision_id=r.decision_id and t.transaction_type='reserve' and (essay_private.clock()>=d.revision_cutoff or not essay_beta_private.operations_open(d.campaign_id)))
 from essay_exam_private.runs r where r.id=p_run
$$;

-- Shortening the current window can shorten access, never extend a grant snapshot.
create or replace function essay_beta_private.revision_deadline(p_run uuid) returns timestamptz
language sql stable set search_path='' as $$
 select least(r.completed_at+interval '14 days',
 (select min(least(d.revision_cutoff,o.beta_end_at)) from public.credit_transactions t
 join essay_beta_private.daily_grants d on d.grant_id=t.grant_id
 left join essay_beta_private.operations_config o on o.campaign_id=d.campaign_id
 where t.decision_id=r.decision_id and t.transaction_type='reserve'))
 from essay_exam_private.runs r where r.id=p_run
$$;
