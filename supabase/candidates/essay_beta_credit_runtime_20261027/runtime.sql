-- CANDIDATE ONLY: requires Owner approval. No campaign is activated by this file.
create schema essay_beta_private;
revoke all on schema essay_beta_private from public, anon, authenticated, service_role;

create table essay_beta_private.campaigns (
 id uuid primary key default gen_random_uuid(),
 starts_on date not null,
 ends_on date not null,
 enabled boolean not null default false,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default clock_timestamp(),
 check (ends_on-starts_on between 4 and 6)
);
-- One program at a time. Changing a program never resets a user's daily grant.
create unique index beta_one_enabled on essay_beta_private.campaigns ((true)) where enabled;
create table essay_beta_private.exam_scope (
 campaign_id uuid not null references essay_beta_private.campaigns(id),
 exam_id uuid not null references public.essay_exams(id),
 runtime_policy jsonb not null,
 question_ids uuid[] not null check(cardinality(question_ids)>0),
 has_math boolean not null,
 owner_math_qa_reference text,
 approval_reference text not null check(length(btrim(approval_reference))>0),
 primary key(campaign_id,exam_id),
 check(coalesce(runtime_policy->>'evaluation_type','') in ('humanities','business')),
 check(not has_math or coalesce(length(btrim(owner_math_qa_reference)),0)>0)
);
create table essay_beta_private.daily_grants (
 user_id uuid not null references auth.users(id),
 grant_day date not null,
 campaign_id uuid not null references essay_beta_private.campaigns(id),
 grant_id uuid not null unique references public.credit_grants(id),
 created_at timestamptz not null default clock_timestamp(),
 primary key(user_id,grant_day)
);
alter table essay_beta_private.campaigns enable row level security;
alter table essay_beta_private.exam_scope enable row level security;
alter table essay_beta_private.daily_grants enable row level security;
revoke all on all tables in schema essay_beta_private from public,anon,authenticated,service_role;

create function essay_beta_private.immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'BETA_GRANT_BINDING_IMMUTABLE';end $$;
create trigger beta_daily_immutable before update or delete on essay_beta_private.daily_grants
 for each row execute function essay_beta_private.immutable();

create function essay_beta_private.is_beta(p_grant uuid) returns boolean
language sql stable set search_path='' as $$
 select exists(select 1 from essay_beta_private.daily_grants where grant_id=p_grant)
$$;

-- Additional spending restriction. Existing gateway public allowlist, preflight,
-- material approval and provider binding checks remain mandatory and unchanged.
create function essay_beta_private.eligible(p_grant uuid,p_exam uuid) returns boolean
language sql volatile set search_path='' as $$
 select exists(
  select 1 from essay_beta_private.daily_grants d
  join essay_beta_private.campaigns c on c.id=d.campaign_id
  join essay_beta_private.exam_scope s on s.campaign_id=c.id and s.exam_id=p_exam
  join public.credit_grants g on g.id=d.grant_id
  where d.grant_id=p_grant and c.enabled
  and (essay_private.clock() at time zone 'Asia/Seoul')::date between c.starts_on and c.ends_on
  and d.grant_day=(essay_private.clock() at time zone 'Asia/Seoul')::date
  and g.expires_at>essay_private.clock()
  and s.runtime_policy=essay_exam_private.runtime_policy(p_exam)
  and (select array_agg(q.id order by q.id) from public.essay_questions q where q.essay_exam_id=p_exam)
      =(select array_agg(q order by q) from unnest(s.question_ids) q)
  and (not s.has_math or length(btrim(s.owner_math_qa_reference))>0)
 )
$$;

create function public.essay_beta_daily_claim() returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); c essay_beta_private.campaigns; d essay_beta_private.daily_grants;
 a uuid; t timestamptz; day date; expiry timestamptz; g uuid; balance bigint;
begin
 if u is null or account_private.allowed(u) is not true then
  raise sqlstate 'PT403' using message='ACCOUNT_REQUIRED';
 end if;
 if not exists(select 1 from essay_beta_private.campaigns where enabled and (essay_private.clock() at time zone 'Asia/Seoul')::date between starts_on and ends_on) then
  return jsonb_build_object('version','essay-beta-credit-v1','active',false);
 end if;
 perform account_private.lock_subject(u);
 insert into public.credit_accounts(user_id) values(u) on conflict(user_id) do nothing;
 select id into a from public.credit_accounts where user_id=u for update;
 -- Take the clock AFTER the shared account lock, including concurrent devices.
 t:=essay_private.clock(); day:=(t at time zone 'Asia/Seoul')::date;
 select * into c from essay_beta_private.campaigns where enabled and day between starts_on and ends_on for share;
 if c.id is null then return jsonb_build_object('version','essay-beta-credit-v1','active',false);end if;
 if not exists(select 1 from essay_beta_private.exam_scope where campaign_id=c.id) then
  return jsonb_build_object('version','essay-beta-credit-v1','active',false);
 end if;
 select * into d from essay_beta_private.daily_grants where user_id=u and grant_day=day;
 if d.grant_id is null then
  expiry:=(day+1)::timestamp at time zone 'Asia/Seoul';
  g:=essay_private.credit_post_grant(u,2,'promotion','lab-beta:daily:'||u||':'||day,
   'essay_beta_daily','beta_campaign/'||c.id,expiry);
  insert into essay_beta_private.daily_grants(user_id,grant_day,campaign_id,grant_id) values(u,day,c.id,g);
 else
  g:=d.grant_id;
  select expires_at into expiry from public.credit_grants where id=g;
 end if;
 select greatest(0,coalesce(sum(balance_delta-reserved_delta),0)) into balance
 from public.credit_transactions where grant_id=g;
 return jsonb_build_object('version','essay-beta-credit-v1','active',true,'grant_id',g,'day',day,
  'available',case when expiry>essay_private.clock() and (d.grant_id is null or d.campaign_id=c.id) then balance else 0 end,'expires_at',expiry);
end $$;
revoke all on all functions in schema essay_beta_private from public,anon,authenticated,service_role;
revoke all on function public.essay_beta_daily_claim() from public,anon,service_role;
grant execute on function public.essay_beta_daily_claim() to authenticated;
