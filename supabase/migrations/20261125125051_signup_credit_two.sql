-- Prepared 2026-11-25. Owner applies to stlhijzpjfgwwdgunlsd only after approval.
-- No historical data writes. Keep essay_signup_3_v1 anti-rejoin namespace unchanged.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
lock table public.credit_accounts,public.credit_grants,public.credit_transactions in share row exclusive mode;
do $$begin
 if md5(pg_get_functiondef('account_private.enabled()'::regprocedure)) <> '1c03946e278438c47838876f4f4c4ef1' then raise exception 'PREIMAGE_CHANGED: enabled';end if;
 if md5(pg_get_functiondef('essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamp with time zone)'::regprocedure)) <> '0df3300b46a557380e30867e061594bf' then raise exception 'PREIMAGE_CHANGED: credit_post_grant';end if;
 if md5(pg_get_functiondef('essay_private.credit_profile_signup()'::regprocedure)) <> '55587b0a508e70cbc1592273c74a7762' then raise exception 'PREIMAGE_CHANGED: credit_profile_signup';end if;
 if md5(pg_get_functiondef('essay_private.credit_signup_eligible(uuid)'::regprocedure)) <> 'fb370d5a56eefdf93bef77f0b7f002b1' then raise exception 'PREIMAGE_CHANGED: credit_signup_eligible';end if;
 if md5(pg_get_functiondef('public.essay_claim_signup_credit()'::regprocedure)) <> '9e6634e02768178541e20c4b13fecbe7' then raise exception 'PREIMAGE_CHANGED: essay_claim_signup_credit';end if;
 if md5(pg_get_functiondef('public.account_benefit_claim(uuid,jsonb)'::regprocedure)) <> '28d435421c39957e5546c9e99ee3764f' then raise exception 'PREIMAGE_CHANGED: account_benefit_claim';end if;
 if to_regprocedure('essay_private.credit_signup_grant(uuid,text)') is not null then raise exception 'ALREADY_INSTALLED_OR_CONFLICT';end if;
end$$;
do $$begin
 if exists(select 1 from pg_proc where oid='account_private.enabled()'::regprocedure and (pg_get_userbyid(proowner)<>'postgres' or proacl::text is distinct from '{postgres=X/postgres,essay_executor=X/postgres}')) then raise exception 'ACL_DRIFT: enabled';end if;
 if exists(select 1 from pg_proc where oid='essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamp with time zone)'::regprocedure and (pg_get_userbyid(proowner)<>'essay_executor' or proacl::text is distinct from '{essay_executor=X/essay_executor,postgres=X/essay_executor}')) then raise exception 'ACL_DRIFT: credit_post_grant';end if;
 if exists(select 1 from pg_proc where oid='essay_private.credit_profile_signup()'::regprocedure and (pg_get_userbyid(proowner)<>'essay_executor' or proacl::text is distinct from '{essay_executor=X/essay_executor}')) then raise exception 'ACL_DRIFT: credit_profile_signup';end if;
 if exists(select 1 from pg_proc where oid='essay_private.credit_signup_eligible(uuid)'::regprocedure and (pg_get_userbyid(proowner)<>'postgres' or proacl::text is distinct from '{postgres=X/postgres,essay_executor=X/postgres}')) then raise exception 'ACL_DRIFT: credit_signup_eligible';end if;
 if exists(select 1 from pg_proc where oid='public.essay_claim_signup_credit()'::regprocedure and (pg_get_userbyid(proowner)<>'essay_executor' or proacl::text is distinct from '{essay_executor=X/essay_executor,authenticated=X/essay_executor}')) then raise exception 'ACL_DRIFT: essay_claim_signup_credit';end if;
 if exists(select 1 from pg_proc where oid='public.account_benefit_claim(uuid,jsonb)'::regprocedure and (pg_get_userbyid(proowner)<>'postgres' or proacl::text is distinct from '{postgres=X/postgres,account_lifecycle_worker=X/postgres,service_role=X/postgres}')) then raise exception 'ACL_DRIFT: account_benefit_claim';end if;
end$$;
create temporary table signup_policy_before on commit drop as
select 'grants' kind,count(*) n,md5(coalesce(jsonb_agg(to_jsonb(t) order by id)::text,'[]')) digest from public.credit_grants t
union all select 'transactions',count(*),md5(coalesce(jsonb_agg(to_jsonb(t) order by id)::text,'[]')) from public.credit_transactions t;
do $$begin
 if current_user<>'postgres' then raise exception 'REQUIRES_POSTGRES';end if;
 if has_schema_privilege('essay_executor','essay_private','CREATE') or has_schema_privilege('essay_executor','public','CREATE') then raise exception 'SCHEMA_PRIVILEGE_DRIFT';end if;
end$$;
create temporary table signup_acl_before on commit drop as select oid,proowner,proacl,prosecdef,proconfig from pg_proc where oid in ('essay_private.credit_profile_signup()'::regprocedure,'public.essay_claim_signup_credit()'::regprocedure,'public.account_benefit_claim(uuid,jsonb)'::regprocedure);
create temporary table signup_membership_before on commit drop as select * from pg_auth_members where roleid='essay_executor'::regrole;
create temporary table signup_schema_before on commit drop as select oid,nspacl from pg_namespace where nspname in ('public','essay_private');
grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema essay_private,public to essay_executor;
set local role essay_executor;
create function essay_private.credit_signup_grant(p_user uuid,p_key text) returns uuid
language plpgsql security definer set search_path='' as $$
declare g uuid;
begin
 perform account_private.lock_subject(p_user);
 if not account_private.allowed(p_user) then raise insufficient_privilege using message='ACCOUNT_RESTRICTED';end if;
 -- Return the original entitlement even when exhausted. Never top up or rewrite it.
 select cg.id into g from public.credit_grants cg join public.credit_accounts ca on ca.id=cg.account_id
 where ca.user_id=p_user and cg.origin='signup_bonus';
 if g is not null then return g;end if;
 return essay_private.credit_post_grant(p_user,2,'signup_bonus',p_key,'signup_bonus_v2','system/signup_bonus',null);
end$$;
alter function essay_private.credit_signup_grant(uuid,text) owner to essay_executor;
revoke all on function essay_private.credit_signup_grant(uuid,text) from public,anon,authenticated,service_role;
grant execute on function essay_private.credit_signup_grant(uuid,text) to postgres;
CREATE OR REPLACE FUNCTION essay_private.credit_profile_signup()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$begin
 if not account_private.enabled() and essay_private.credit_signup_eligible(new.id) then perform essay_private.credit_signup_grant(new.id,'signup_bonus/'||new.id::text);end if;
 return new;end$function$
;
CREATE OR REPLACE FUNCTION public.essay_claim_signup_credit()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=essay_private.uid();g uuid;begin
 if u is null then raise insufficient_privilege;end if;
 if not account_private.enabled() then
 if not essay_private.credit_signup_eligible(u) then raise sqlstate 'PT403' using message='SIGNUP_NOT_ELIGIBLE';end if;
 return essay_private.credit_signup_grant(u,'signup_bonus/'||u::text);end if;
 select grant_id into g from account_private.benefit_delivery where subject_id=u;
 return g; -- null = eligibility not established, never a second grant
end$function$
;
reset role;
revoke create on schema essay_private,public from essay_executor;
revoke essay_executor from postgres granted by postgres;
do $$begin
 if exists((select * from signup_membership_before except select * from pg_auth_members where roleid='essay_executor'::regrole) union all (select * from pg_auth_members where roleid='essay_executor'::regrole except select * from signup_membership_before)) then raise exception 'MEMBERSHIP_CHANGED';end if;
 if exists(select 1 from signup_schema_before b join pg_namespace n using(oid) where b.nspacl is distinct from n.nspacl) then raise exception 'SCHEMA_ACL_CHANGED';end if;
 if exists(select 1 from signup_acl_before b join pg_proc p using(oid) where (b.proowner,b.proacl,b.prosecdef,b.proconfig) is distinct from (p.proowner,p.proacl,p.prosecdef,p.proconfig)) then raise exception 'RPC_ACL_CHANGED';end if;
end$$;
CREATE OR REPLACE FUNCTION public.account_benefit_claim(p_subject uuid, p_markers jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare m jsonb;known boolean=false;g uuid;begin
 perform account_private.lock_subject(p_subject);
 if not account_private.allowed(p_subject) or not exists(select 1 from auth.users where id=p_subject) then raise insufficient_privilege;end if;
 if jsonb_typeof(p_markers) is distinct from 'array' or jsonb_array_length(p_markers) not between 1 and 16 then raise invalid_parameter_value;end if;
 for m in select value from jsonb_array_elements(p_markers) order by value->>'version',value->>'marker' loop
 if m-array['version','marker']<>'{}' or m->>'version' !~ '^[a-zA-Z0-9_-]{1,32}$' or m->>'marker' !~ '^[a-f0-9]{64}$' or not(m ?& array['version','marker']) then raise invalid_parameter_value;end if;
 perform pg_advisory_xact_lock(hashtextextended(m->>'version'||'/'||(m->>'marker'),91571));
 known=known or exists(select 1 from account_private.benefit_claims where benefit_type='essay_signup_3_v1' and key_version=m->>'version' and marker=m->>'marker');
 end loop;
 select grant_id into g from account_private.benefit_delivery where subject_id=p_subject;
 -- Existing live-account grant seeds coverage; never re-grant on migration.
 if g is null then select cg.id into g from public.credit_grants cg join public.credit_accounts ca on ca.id=cg.account_id where ca.user_id=p_subject and cg.origin='signup_bonus';end if;
 if not known and g is null then
 if not essay_private.credit_signup_eligible(p_subject) then return jsonb_build_object('state','NOT_ELIGIBLE');end if;
 g=essay_private.credit_signup_grant(p_subject,'signup/'||gen_random_uuid()::text);
 end if;
 for m in select value from jsonb_array_elements(p_markers) loop
 insert into account_private.benefit_claims(benefit_type,key_version,marker) values('essay_signup_3_v1',m->>'version',m->>'marker') on conflict do nothing;
 end loop;
 insert into account_private.benefit_delivery values(p_subject,g) on conflict(subject_id) do nothing;
 return jsonb_build_object('state',case when g is null then 'PREVIOUSLY_CLAIMED' else 'GRANTED' end);
end$function$
;do $$begin
 if exists((select * from signup_policy_before) except
 (select 'grants',count(*),md5(coalesce(jsonb_agg(to_jsonb(t) order by id)::text,'[]')) from public.credit_grants t
 union all select 'transactions',count(*),md5(coalesce(jsonb_agg(to_jsonb(t) order by id)::text,'[]')) from public.credit_transactions t))
 then raise exception 'EXISTING_LEDGER_CHANGED';end if;
end$$;
commit;
