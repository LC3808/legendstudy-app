-- Owner-approved role-only migration; applied as 20261014020622.
begin;
set local lock_timeout='5s';
set local statement_timeout='15s';
do $$begin
 if current_user<>'postgres' then raise exception 'OWNER_REQUIRED';end if;
 if not exists(select 1 from pg_roles where rolname='essay_worker' and not rolsuper and not rolbypassrls and not rolcanlogin)
 or not exists(select 1 from pg_roles where rolname='authenticator' and not rolsuper and not rolbypassrls and not rolinherit)
 then raise exception 'ROLE_BASELINE_MISMATCH';end if;
 if pg_has_role('essay_worker','essay_executor','MEMBER') then raise exception 'WORKER_EXECUTOR_MEMBERSHIP_FORBIDDEN';end if;
end$$;
grant essay_worker to authenticator with inherit false, set true;
commit;
