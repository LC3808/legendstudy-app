begin;
set local lock_timeout='5s';
select pg_advisory_xact_lock(20261112,53);
update math_private.kau_review_control set enabled=false where singleton;
commit;
