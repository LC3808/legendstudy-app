-- Owner approval required. Existing 2/3 grants remain intact. Future grants return to3.
begin;
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
create or replace function essay_private.credit_signup_grant(p_user uuid,p_key text) returns uuid
language plpgsql security definer set search_path='' as $$
declare g uuid;
begin
 perform account_private.lock_subject(p_user);
 if not account_private.allowed(p_user) then raise insufficient_privilege using message='ACCOUNT_RESTRICTED';end if;
 -- Return the original entitlement even when exhausted. Never top up or rewrite it.
 select cg.id into g from public.credit_grants cg join public.credit_accounts ca on ca.id=cg.account_id
 where ca.user_id=p_user and cg.origin='signup_bonus';
 if g is not null then return g;end if;
 return essay_private.credit_post_grant(p_user,3,'signup_bonus',p_key,'signup_bonus_v1','system/signup_bonus',null);
end$$;
alter function essay_private.credit_signup_grant(uuid,text) owner to essay_executor;
revoke all on function essay_private.credit_signup_grant(uuid,text) from public,anon,authenticated,service_role;
grant execute on function essay_private.credit_signup_grant(uuid,text) to postgres;
reset role;
revoke create on schema essay_private,public from essay_executor;
revoke essay_executor from postgres granted by postgres;
do $$begin
 if exists((select * from signup_membership_before except select * from pg_auth_members where roleid='essay_executor'::regrole) union all (select * from pg_auth_members where roleid='essay_executor'::regrole except select * from signup_membership_before)) then raise exception 'MEMBERSHIP_CHANGED';end if;
 if exists(select 1 from signup_schema_before b join pg_namespace n using(oid) where b.nspacl is distinct from n.nspacl) then raise exception 'SCHEMA_ACL_CHANGED';end if;
 if exists(select 1 from signup_acl_before b join pg_proc p using(oid) where (b.proowner,b.proacl,b.prosecdef,b.proconfig) is distinct from (p.proowner,p.proacl,p.prosecdef,p.proconfig)) then raise exception 'RPC_ACL_CHANGED';end if;
end$$;
commit;
