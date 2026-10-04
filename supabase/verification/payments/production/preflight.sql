-- Run after separately approved ADR installation, before Payment apply. READ ONLY.
begin read only;
set local statement_timeout='15s';
do $$begin
 if current_user<>'postgres' then raise exception 'EXECUTOR_MISMATCH'; end if;
 if (select nspowner from pg_namespace where nspname='public')<>'pg_database_owner'::regrole then raise exception 'PUBLIC_OWNER_DRIFT'; end if;
 if to_regnamespace('payment_private') is not null or to_regclass('public.payment_orders') is not null or to_regprocedure('public.payment_order(jsonb)') is not null or to_regprocedure('public.payment_process(jsonb)') is not null then raise exception 'PAYMENT_COLLISION'; end if;
 if to_regprocedure('account_private.allowed(uuid)') is null or to_regprocedure('account_private.lock_subject(uuid)') is null then raise exception 'ADR_PREREQUISITE_MISSING'; end if;
 if to_regprocedure('essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)') is null then raise exception 'LEDGER_PREREQUISITE_MISSING'; end if;
 if pg_has_role('postgres','essay_executor','SET') or has_schema_privilege('essay_executor','public','CREATE') then raise exception 'BOOTSTRAP_TOPOLOGY_DRIFT'; end if;
 if not exists(select 1 from pg_auth_members where roleid='essay_executor'::regrole and member='postgres'::regrole and grantor='supabase_admin'::regrole and admin_option and not inherit_option and not set_option) then raise exception 'ADMIN_MEMBERSHIP_MISSING'; end if;
 if exists(select 1 from pg_auth_members where roleid='essay_finance'::regrole and member='authenticator'::regrole) then raise exception 'UNREVIEWED_FINANCE_ENROLLMENT'; end if;
end$$;
select 'PREFLIGHT_PASS_IDENTITY_AND_FULL_CATALOG_REVIEW_STILL_REQUIRED' as result;
commit;
