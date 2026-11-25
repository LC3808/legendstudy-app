begin read only;
do $$begin
 if strpos(pg_get_functiondef('essay_private.credit_signup_grant(uuid,text)'::regprocedure),'p_user,2,')=0 then raise exception 'EXPECTED_TWO';end if;
 if has_function_privilege('anon','essay_private.credit_signup_grant(uuid,text)','EXECUTE') or has_function_privilege('authenticated','essay_private.credit_signup_grant(uuid,text)','EXECUTE') or has_function_privilege('service_role','essay_private.credit_signup_grant(uuid,text)','EXECUTE') then raise exception 'PRIVATE_GRANT_EXPOSED';end if;
 if strpos(pg_get_functiondef('public.account_benefit_claim(uuid,jsonb)'::regprocedure),'essay_signup_3_v1')=0 then raise exception 'DEDUP_NAMESPACE_CHANGED';end if;
 if has_schema_privilege('essay_executor','essay_private','CREATE') or has_schema_privilege('essay_executor','public','CREATE') then raise exception 'SCHEMA_PRIVILEGE_RESIDUE';end if;
end$$;
select p.oid::regprocedure signature,pg_get_userbyid(p.proowner) owner,p.proacl,md5(pg_get_functiondef(p.oid)) body_md5 from pg_proc p where p.oid in ('essay_private.credit_signup_grant(uuid,text)'::regprocedure,'essay_private.credit_profile_signup()'::regprocedure,'public.essay_claim_signup_credit()'::regprocedure,'public.account_benefit_claim(uuid,jsonb)'::regprocedure);
select position('''essay_signup_3_v1''' in pg_get_functiondef('public.account_benefit_claim(uuid,jsonb)'::regprocedure))>0 dedup_namespace_preserved;
select balance_delta,reason_code,count(*) from public.credit_transactions where transaction_type='signup_bonus' group by 1,2;
rollback;
