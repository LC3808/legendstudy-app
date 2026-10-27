-- ISOLATED DESIGN PROTOTYPE ONLY. NOT a Production migration.
-- No wallet, grant, transaction or public RPC is created/changed.
-- Callers must pass trusted DB time and server-verified policy, never client claims.
create schema beta_policy_prototype;
revoke all on schema beta_policy_prototype from public;
create function beta_policy_prototype.daily_window(p_now timestamptz,p_start date,p_end date)
returns table(kst_day date,expires_at timestamptz) language plpgsql immutable set search_path='' as $$
begin
 if p_now is null or p_start is null or p_end is null or p_end-p_start not between 4 and 6 then
  raise exception 'INVALID_CAMPAIGN_WINDOW'; end if;
 return query select (p_now at time zone 'Asia/Seoul')::date,
  (((p_now at time zone 'Asia/Seoul')::date+1)::timestamp at time zone 'Asia/Seoul')
 where (p_now at time zone 'Asia/Seoul')::date between p_start and p_end;
end $$;
create function beta_policy_prototype.scope_eligible(p_public boolean,p_full boolean,p_type text,p_has_math boolean,p_owner_qa boolean)
returns boolean language sql immutable set search_path='' as $$
 select coalesce(p_public and p_full and
 (p_type in ('humanities','social','commerce')) and
 (not p_has_math or (p_type='commerce' and p_owner_qa)),false)
$$;
-- Proposed beta-only order: daily, signup, feedback/other non-purchase, purchase.
-- NULL = reject scoped grant. Generic paths must also reject ALL beta grants.
create function beta_policy_prototype.spend_rank(p_origin text,p_kind text,p_eligible boolean,p_active boolean)
returns integer language sql immutable set search_path='' as $$
 select case
 when p_kind='daily' then case when p_eligible and p_active then 0 end
 when p_kind='feedback' then case when p_eligible then 2 end
 when p_kind is not null then null
 when p_origin='signup_bonus' then 1
 when p_origin in ('promotion','admin_grant','compensation','b2b_program') then 2
 when p_origin='purchase' then 3 end
$$;
revoke all on all functions in schema beta_policy_prototype from public;
