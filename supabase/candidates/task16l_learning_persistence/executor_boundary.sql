begin;
-- Match canonical math executor boundary; public facade may be owned by postgres.
grant math_executor to postgres with admin false,inherit false,set true granted by postgres;
alter function math_private.finalize_with_learning(uuid,uuid,jsonb,jsonb) security definer;
grant create on schema math_private to math_executor;
alter function math_private.finalize_with_learning(uuid,uuid,jsonb,jsonb) owner to math_executor;
set local role math_executor;
grant execute on function math_private.finalize_with_learning(uuid,uuid,jsonb,jsonb) to postgres;
reset role;
revoke create on schema math_private from math_executor;
revoke math_executor from postgres granted by postgres;
commit;
