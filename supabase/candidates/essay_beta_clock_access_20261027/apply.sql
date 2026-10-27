-- Owner approval required. Read-only clock access for existing SECURITY DEFINER owner.
begin;
set local lock_timeout='5s';
do $$begin
 if current_user<>'postgres' or pg_has_role('postgres','essay_executor','SET') then raise exception 'ROLE_BASELINE_CHANGED';end if;
 if has_function_privilege('postgres','essay_private.clock()','EXECUTE') then raise exception 'ALREADY_APPLIED';end if;
end$$;
grant essay_executor to postgres with admin false, inherit false, set true;
set local role essay_executor;
grant execute on function essay_private.clock() to postgres;
reset role;
revoke essay_executor from postgres granted by postgres;
commit;
