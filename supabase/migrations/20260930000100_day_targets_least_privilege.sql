-- day_targets ACL only. Owner-applied Production migration; no RLS/data change.
-- GRANT is additive: remove inherited/default application privileges first.
-- ALL also removes PostgreSQL 17 MAINTAIN without adding a version-specific grant.
-- Owner/service_role/default ACLs and every other table remain untouched.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';
revoke all privileges on table public.day_targets from public, anon, authenticated;
grant select, insert, update, delete on table public.day_targets to authenticated;
commit;
