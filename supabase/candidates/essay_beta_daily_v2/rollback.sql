-- Emergency stop only; retains all grants, runs, ledger and beta revision deadlines.
begin;
update essay_beta_private.campaigns set enabled=false where enabled;
commit;
-- Never restore old unscoped allocators or delete grant history after activation.
