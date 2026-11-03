begin;
-- Existing NOLOGIN Math worker roles, only selectable by PostgREST authenticator.
-- Not granted to authenticated, anon or service_role.
grant math_extraction_worker,math_evaluation_worker to authenticator;
commit;
