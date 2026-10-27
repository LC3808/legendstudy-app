-- Safe shutdown preserves existing grants and reservation settlement.
-- Do NOT restore old unscoped allocators while any beta grants remain.
begin;
update essay_beta_private.campaigns set enabled=false where enabled;
commit;
