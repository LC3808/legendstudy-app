-- Optional future Owner-authorized HOLD, not executed during preparation.
-- Retain store verification/approval metadata; no drop or data deletion.
begin;
set local lock_timeout='5s';
update app_release_private.platform_policy set enabled=false where platform in('ios','android');
commit;
