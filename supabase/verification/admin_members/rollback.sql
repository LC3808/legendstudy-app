-- Owner-only rollback009. No student data, ledger, existing RPC or profile is changed.
-- First roll LAB back to the preceding application commit / old member search.
begin;
set local lock_timeout='5s';
drop function public.admin_member_list(text,integer,integer,text,text,text,integer,text,text,boolean);
drop table student_private.school_display_cache;
-- Ledger repair, if needed, is a separate reviewed Owner operation; do not
-- automatically remove historical applied evidence or use db push.
commit;
