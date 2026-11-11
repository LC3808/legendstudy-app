-- SOFT ROLLBACK A. Owner approval required. Keeps all revisions and dependencies.
begin;
set local lock_timeout='5s';
revoke all on function public.my_home_configuration() from public,anon,authenticated;
revoke all on function public.save_my_home_configuration(jsonb,bigint) from public,anon,authenticated;
commit;
-- APP75 does not call these RPCs. New app read falls back to default home;
-- authenticated saves fail visibly and onboarding skip remains available.
