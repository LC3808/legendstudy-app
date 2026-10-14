-- This package's preflight requires membership absent before first apply.
begin;
revoke essay_worker from authenticator;
commit;
