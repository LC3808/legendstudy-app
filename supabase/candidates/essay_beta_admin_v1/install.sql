begin;
-- Read-only guards; v2 must be separately approved and verified first.
do $$begin
if to_regprocedure('public.essay_beta_daily_claim_v2()') is null or (select md5(pg_get_functiondef('public.essay_beta_daily_claim_v2()'::regprocedure)))<>'d42554948c9ef2a483ea5466fbd3a6f7' then raise exception 'BASELINE_MISMATCH public.essay_beta_daily_claim_v2()';end if;
if (select pg_get_userbyid(proowner) from pg_proc where oid='public.essay_beta_daily_claim_v2()'::regprocedure)<>'postgres' or (select proacl::text from pg_proc where oid='public.essay_beta_daily_claim_v2()'::regprocedure) is distinct from '{postgres=X/postgres,authenticated=X/postgres}' then raise exception 'BASELINE_PERMISSION_MISMATCH public.essay_beta_daily_claim_v2()';end if;
if to_regprocedure('essay_beta_private.eligible(uuid,uuid)') is null or (select md5(pg_get_functiondef('essay_beta_private.eligible(uuid,uuid)'::regprocedure)))<>'5cc8547ed15874d932d84e6d74009552' then raise exception 'BASELINE_MISMATCH essay_beta_private.eligible(uuid,uuid)';end if;
if (select pg_get_userbyid(proowner) from pg_proc where oid='essay_beta_private.eligible(uuid,uuid)'::regprocedure)<>'postgres' or (select proacl::text from pg_proc where oid='essay_beta_private.eligible(uuid,uuid)'::regprocedure) is distinct from '{postgres=X/postgres}' then raise exception 'BASELINE_PERMISSION_MISMATCH essay_beta_private.eligible(uuid,uuid)';end if;
if to_regprocedure('essay_beta_private.revision_open(uuid)') is null or (select md5(pg_get_functiondef('essay_beta_private.revision_open(uuid)'::regprocedure)))<>'d2d2c080836b7ba044bd447f7df21cc2' then raise exception 'BASELINE_MISMATCH essay_beta_private.revision_open(uuid)';end if;
if (select pg_get_userbyid(proowner) from pg_proc where oid='essay_beta_private.revision_open(uuid)'::regprocedure)<>'postgres' or (select proacl::text from pg_proc where oid='essay_beta_private.revision_open(uuid)'::regprocedure) is distinct from '{postgres=X/postgres}' then raise exception 'BASELINE_PERMISSION_MISMATCH essay_beta_private.revision_open(uuid)';end if;
if to_regprocedure('essay_beta_private.revision_deadline(uuid)') is null or (select md5(pg_get_functiondef('essay_beta_private.revision_deadline(uuid)'::regprocedure)))<>'ce1e0ce85dc963163145c6ea7fc231a6' then raise exception 'BASELINE_MISMATCH essay_beta_private.revision_deadline(uuid)';end if;
if (select pg_get_userbyid(proowner) from pg_proc where oid='essay_beta_private.revision_deadline(uuid)'::regprocedure)<>'postgres' or (select proacl::text from pg_proc where oid='essay_beta_private.revision_deadline(uuid)'::regprocedure) is distinct from '{postgres=X/postgres}' then raise exception 'BASELINE_PERMISSION_MISMATCH essay_beta_private.revision_deadline(uuid)';end if;
if to_regclass('essay_beta_private.operations_config') is not null then raise exception 'ALREADY_INSTALLED_REVIEW_STATE';end if;
end $$;
-- Candidate only. Requires daily-v2 and separately reviewed campaign/scope bootstrap.
create table essay_beta_private.operations_config (
 campaign_id uuid primary key references essay_beta_private.campaigns(id),
 beta_enabled boolean not null default false,
 beta_start_at timestamptz not null,
 beta_end_at timestamptz not null,
 daily_free_limit integer not null default 1 check(daily_free_limit between 1 and 100),
 reset_timezone text not null default 'Asia/Seoul' check(reset_timezone='Asia/Seoul'),
 next_daily_limit integer check(next_daily_limit between 1 and 100),
 limit_effective_at timestamptz,
 version integer not null default 1,
 check(beta_end_at>beta_start_at),
 check((next_daily_limit is null)=(limit_effective_at is null))
);
-- Capability is an additional restriction, never a replacement for admin_operator.
create table essay_beta_private.settings_editors (
 user_id uuid primary key references auth.users(id), approval_reference text not null check(length(trim(approval_reference))>0)
);
create table essay_beta_private.settings_audit (
 id bigint generated always as identity primary key,
 campaign_id uuid not null references essay_beta_private.campaigns,
 actor uuid not null references auth.users, recorded_at timestamptz not null default clock_timestamp(),
 before_value jsonb, after_value jsonb not null, reason text not null check(length(trim(reason))>0)
);
alter table essay_beta_private.operations_config enable row level security;
alter table essay_beta_private.settings_editors enable row level security;
alter table essay_beta_private.settings_audit enable row level security;
revoke all on essay_beta_private.operations_config,essay_beta_private.settings_editors,essay_beta_private.settings_audit from public,anon,authenticated,service_role;
create trigger beta_settings_audit_immutable before update or delete on essay_beta_private.settings_audit for each row execute function essay_beta_private.immutable();

create function essay_beta_private.operations(p_campaign uuid) returns essay_beta_private.operations_config
language sql stable set search_path='' as $$
 select o from essay_beta_private.operations_config o where o.campaign_id=p_campaign
$$;
create function essay_beta_private.operations_open(p_campaign uuid) returns boolean
language sql volatile set search_path='' as $$
 select coalesce((select beta_enabled and essay_private.clock()>=beta_start_at and essay_private.clock()<beta_end_at
 from essay_beta_private.operations_config o join essay_beta_private.campaigns c on c.id=o.campaign_id where o.campaign_id=p_campaign and c.enabled),false)
$$;
create function essay_beta_private.require_admin(p_write boolean default false) returns void
language plpgsql set search_path='' as $$
begin
 if auth.uid() is null or public.admin_operator() is not true or account_private.allowed(auth.uid()) is not true
 or (p_write and not exists(select 1 from essay_beta_private.settings_editors where user_id=auth.uid()))
 then raise sqlstate 'PT403' using message='BETA_ADMIN_REQUIRED'; end if;
end $$;

create function public.admin_essay_beta_config() returns jsonb
language plpgsql security definer set search_path='' as $$
declare v jsonb;
begin
 perform essay_beta_private.require_admin();
 select jsonb_agg(jsonb_build_object('campaign_id',c.id,'config',to_jsonb(o),'can_edit',exists(select 1 from essay_beta_private.settings_editors where user_id=auth.uid()))) into v
 from essay_beta_private.campaigns c left join essay_beta_private.operations_config o on o.campaign_id=c.id;
 return jsonb_build_object('campaigns',coalesce(v,'[]'),'timezone','Asia/Seoul');
end $$;

create function public.admin_essay_beta_save(p_campaign uuid,p_expected_version integer,p_value jsonb,p_reason text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare old essay_beta_private.operations_config; newv essay_beta_private.operations_config;
 t timestamptz; lim integer; mode text;
begin
 perform essay_beta_private.require_admin(true);
 if coalesce(length(trim(p_reason)),0)=0 or length(p_reason)>1000 then raise exception 'CHANGE_REASON_REQUIRED';end if;
 -- Same campaign lock as claims; settings never acquire an account lock.
 perform 1 from essay_beta_private.campaigns where id=p_campaign for update;
 if not found then raise exception 'REVIEWED_CAMPAIGN_REQUIRED';end if;
 select * into old from essay_beta_private.operations_config where campaign_id=p_campaign for update;
 if coalesce(old.version,0) is distinct from p_expected_version then raise sqlstate 'PT409' using message='SETTINGS_CHANGED_RELOAD';end if;
 t:=essay_private.clock();
 newv.campaign_id:=p_campaign;
 newv.beta_enabled:=(p_value->>'beta_enabled')::boolean;
 newv.beta_start_at:=(p_value->>'beta_start_at')::timestamptz;
 newv.beta_end_at:=(p_value->>'beta_end_at')::timestamptz;
 newv.reset_timezone:=p_value->>'reset_timezone';
 newv.version:=coalesce(old.version,0)+1;
 lim:=(p_value->>'daily_free_limit')::integer; mode:=p_value->>'limit_application';
 if mode is null or mode not in ('immediate','next_reset') or lim is null or lim not between 1 and 100 then raise exception 'INVALID_LIMIT';end if;
 if newv.beta_enabled then
  if not exists(select 1 from essay_beta_private.exam_scope where campaign_id=p_campaign and not has_math and runtime_policy->>'evaluation_type'='humanities') then raise exception 'APPROVED_SCOPE_REQUIRED';end if;
  if not exists(select 1 from essay_beta_private.campaigns c join notice_private.notices n on n.notice_id=c.notice_id where c.id=p_campaign and n.status='published' and n.category='beta' and n.show_app and n.show_web and n.is_public and n.published_at<=t and (n.expires_at is null or n.expires_at>=newv.beta_end_at)) then raise exception 'PUBLISHED_BETA_NOTICE_REQUIRED';end if;
 end if;
 newv.daily_free_limit:=coalesce(case when t>=old.limit_effective_at then old.next_daily_limit else old.daily_free_limit end,1);
 if mode='immediate' and lim<>newv.daily_free_limit and exists(select 1 from essay_beta_private.daily_grants where grant_day=(t at time zone 'Asia/Seoul')::date) then raise exception 'TODAY_GRANTED_USE_NEXT_RESET';end if;
 if mode='next_reset' and lim<>newv.daily_free_limit then
  newv.next_daily_limit:=lim;
  newv.limit_effective_at:=((t at time zone 'Asia/Seoul')::date+1)::timestamp at time zone 'Asia/Seoul';
 else newv.daily_free_limit:=lim;end if;
 insert into essay_beta_private.operations_config select newv.* on conflict(campaign_id) do update set
 beta_enabled=excluded.beta_enabled,beta_start_at=excluded.beta_start_at,beta_end_at=excluded.beta_end_at,
 daily_free_limit=excluded.daily_free_limit,reset_timezone=excluded.reset_timezone,
 next_daily_limit=excluded.next_daily_limit,limit_effective_at=excluded.limit_effective_at,version=excluded.version;
 insert into essay_beta_private.settings_audit(campaign_id,actor,before_value,after_value,reason)
 values(p_campaign,auth.uid(),case when old.campaign_id is not null then to_jsonb(old) end,to_jsonb(newv),p_reason);
 -- Legacy enable flag remains a second safety fence. Dates and issued grants stay immutable.
 update essay_beta_private.campaigns set enabled=newv.beta_enabled where id=p_campaign;
 return to_jsonb(newv);
end $$;

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

-- Run is the billing evaluation unit; question checkpoint failures remain partial failures.
create view essay_beta_private.beta_run_facts as
select r.id evaluation_id,a.user_id,r.created_at,r.state,r.parent_id,
 d.campaign_id,d.grant_day,
 coalesce(tx.reserved,0) reserved,coalesce(tx.consumed,0) consumed,coalesce(tx.released,0) released,
 tx.recovered_at,
 case when tx.released>0 then case when tx.automatic_release=tx.released then 'automatic' else 'manual_check' end else null end recovery_method,
 coalesce(rr.generation,0) generation,
 coalesce(cp.failed_questions,0) failed_questions,
 cp.failure_codes,
 case when tx.released>0 and tx.released=tx.reserved then 'recovered'
 when tx.released>tx.reserved or (r.state='completed' and r.parent_id is null and coalesce(tx.consumed,0)<>1) then 'manual_check'
 when r.state='completed' then 'completed'
 when r.state='failed' and tx.reserved>coalesce(tx.released,0) then 'recovery_pending'
 when r.state='failed' or coalesce(cp.failed_questions,0)>0 then 'failed'
 else 'processing' end operation_status
from essay_exam_private.runs r
join public.credit_accounts a on a.id=r.account_id
left join essay_exam_private.runs parent on parent.id=r.parent_id
join lateral (
 select distinct dg.* from public.credit_transactions t join essay_beta_private.daily_grants dg on dg.grant_id=t.grant_id
 where t.decision_id=coalesce(parent.decision_id,r.decision_id) and t.transaction_type='reserve'
) d on true
left join lateral (
 select sum(reserved_delta) filter(where transaction_type='reserve') reserved,
 -sum(balance_delta) filter(where transaction_type='consume') consumed,
 -sum(reserved_delta) filter(where transaction_type='release') released,
 max(created_at) filter(where transaction_type='release') recovered_at,
 -sum(reserved_delta) filter(where transaction_type='release' and reason_code='essay_exam_finalization') automatic_release
 from public.credit_transactions where decision_id=r.decision_id and grant_id=d.grant_id
) tx on true
left join lateral (select * from essay_exam_private.retry_requests where run_id=r.id order by generation desc limit 1) rr on true
left join lateral (
 select count(*) filter(where c.payload->>'state'='failed') failed_questions,
 jsonb_agg(jsonb_build_object('question_id',ans.value->>'questionId','state',c.payload->>'state','diagnostics',(select jsonb_agg(jsonb_build_object('code',z.payload->>'code','stage',z.payload->>'stage','http_status',z.payload->>'http_status')) from essay_exam_private.checkpoints z where z.run_id=r.id and z.state='checkpoint' and z.key like 'q'||(ans.ordinality-1)||'-a'||coalesce(rr.attempts->>(ans.ordinality-1)::text,'0')||'-%' and z.payload->>'component' in ('execution_failure','validation_failure')))) filter(where c.payload->>'state'='failed') failure_codes
 from jsonb_array_elements(r.snapshot->'answers') with ordinality ans(value,ordinality)
 left join essay_exam_private.checkpoints c on c.run_id=r.id and c.key='q'||(ans.ordinality-1)||
 case when coalesce((rr.attempts->>(ans.ordinality-1)::text)::integer,0)=0 then '' else '-retry-'||(rr.attempts->>(ans.ordinality-1)::text) end
) cp on true;
revoke all on essay_beta_private.beta_run_facts from public,anon,authenticated,service_role;

create function public.admin_essay_beta_report(p_kind text,p_user uuid default null,p_from timestamptz default null,p_to timestamptz default null,p_sort text default 'recent',p_offset integer default 0) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb; total bigint;
begin
 perform essay_beta_private.require_admin();
 if p_kind not in ('usage','failures','audit') or p_kind is null or p_sort not in ('recent','usage','failures') or p_sort is null or p_offset is null or p_offset<0 or p_offset>100000 or (p_from is not null and p_to is not null and p_from>=p_to) then raise exception 'INVALID_FILTER';end if;
 if p_kind='audit' then
  select count(*) into total from essay_beta_private.settings_audit where (p_user is null or actor=p_user) and (p_from is null or recorded_at>=p_from) and (p_to is null or recorded_at<p_to);
  select jsonb_agg(to_jsonb(x)) into result from (select * from essay_beta_private.settings_audit where (p_user is null or actor=p_user) and (p_from is null or recorded_at>=p_from) and (p_to is null or recorded_at<p_to) order by id desc limit 25 offset p_offset) x;
 elsif p_kind='failures' then
  select count(*) into total from essay_beta_private.beta_run_facts where (state='failed' or failed_questions>0 or released>0 or operation_status='manual_check') and (p_user is null or user_id=p_user) and (p_from is null or created_at>=p_from) and (p_to is null or created_at<p_to);
  select jsonb_agg(to_jsonb(x)) into result from (select * from essay_beta_private.beta_run_facts where (state='failed' or failed_questions>0 or released>0 or operation_status='manual_check') and (p_user is null or user_id=p_user) and (p_from is null or created_at>=p_from) and (p_to is null or created_at<p_to) order by created_at desc,evaluation_id limit 25 offset p_offset) x;
 else
  -- Period applies to evaluation events; today's figures always use the current KST day.
  select count(*) into total from auth.users u where (p_user is null or u.id=p_user);
  with stats as (
   select u.id user_id,max(f.created_at) latest_use,count(f.evaluation_id) filter(where parent_id is null) free_count,
   count(*) filter(where parent_id is not null) rewrite_count,
   count(*) filter(where state='completed') success_count,
   count(*) filter(where state='failed' or failed_questions>0) failure_count,
   count(*) filter(where released>0) recovery_count
   from auth.users u left join essay_beta_private.beta_run_facts f on f.user_id=u.id and (p_from is null or f.created_at>=p_from) and (p_to is null or f.created_at<p_to) where (p_user is null or u.id=p_user) group by u.id
  ), rows as (
   select s.*,u.created_at signup_at,
   coalesce(today.used,0) today_used,coalesce(today.remaining,(select case when essay_beta_private.operations_open(o.campaign_id) then case when essay_private.clock()>=o.limit_effective_at then o.next_daily_limit else o.daily_free_limit end else 0 end from essay_beta_private.operations_config o join essay_beta_private.campaigns c on c.id=o.campaign_id where c.enabled),0) today_remaining
   from stats s join auth.users u on u.id=s.user_id
   left join lateral (
    select greatest(0,coalesce(sum(t.reserved_delta-t.balance_delta) filter(where t.transaction_type in ('reserve','release','consume')),0)) used,
    case when essay_beta_private.operations_open(d.campaign_id) then greatest(0,coalesce(sum(t.balance_delta-t.reserved_delta),0)) else 0 end remaining
    from essay_beta_private.daily_grants d join public.credit_transactions t on t.grant_id=d.grant_id
    where d.user_id=s.user_id and d.grant_day=(essay_private.clock() at time zone 'Asia/Seoul')::date group by d.campaign_id
   ) today on true
   order by case when p_sort='usage' then free_count end desc nulls last,
    case when p_sort='failures' then failure_count end desc nulls last,latest_use desc nulls last,user_id
   limit 25 offset p_offset
  ) select jsonb_agg(to_jsonb(rows)) into result from rows;
 end if;
 return jsonb_build_object('rows',coalesce(result,'[]'),'total',total,'offset',p_offset,'page_size',25);
end $$;
revoke all on function essay_beta_private.operations(uuid),essay_beta_private.operations_open(uuid),essay_beta_private.require_admin(boolean) from public,anon,authenticated,service_role;
revoke all on function public.admin_essay_beta_config(),public.admin_essay_beta_save(uuid,integer,jsonb,text),public.admin_essay_beta_report(text,uuid,timestamptz,timestamptz,text,integer) from public,anon,service_role;
grant execute on function public.admin_essay_beta_config(),public.admin_essay_beta_save(uuid,integer,jsonb,text),public.admin_essay_beta_report(text,uuid,timestamptz,timestamptz,text,integer) to authenticated;

commit;
