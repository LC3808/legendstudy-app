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
