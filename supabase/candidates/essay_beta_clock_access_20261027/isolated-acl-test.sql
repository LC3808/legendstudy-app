\set ON_ERROR_STOP on
begin;
create role postgres nosuperuser noinherit createrole;
grant essay_executor to postgres with admin true, inherit false, set false;
alter function essay_private.clock() owner to essay_executor;
revoke all on function essay_private.clock() from public;
grant usage on schema essay_private to postgres;
set session authorization postgres;
select not has_function_privilege('postgres','essay_private.clock()','EXECUTE') before_blocked;
grant essay_executor to postgres with admin false, inherit false, set true;
set local role essay_executor;
grant execute on function essay_private.clock() to postgres;
reset role;
revoke essay_executor from postgres granted by postgres;
select has_function_privilege('postgres','essay_private.clock()','EXECUTE') clock_allowed,not pg_has_role('postgres','essay_executor','SET') role_restored,not has_function_privilege('authenticated','essay_private.clock()','EXECUTE') client_blocked,not has_function_privilege('anon','essay_private.clock()','EXECUTE') anon_blocked;
select essay_private.clock() is not null actual_call;
reset session authorization;
rollback;
