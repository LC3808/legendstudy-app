begin read only;
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
select current_database(),current_user,account_private.enabled() lifecycle_enabled;
select balance_delta,reason_code,count(*) from public.credit_transactions where transaction_type='signup_bonus' group by 1,2;
select count(*) grants from public.credit_grants;select count(*) transactions from public.credit_transactions;
rollback;
