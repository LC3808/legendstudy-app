-- Disable/remove the web entry before rolling back this new read RPC. No cascade or student DML.
begin;
set local lock_timeout='5s';
drop function public.essay_web_runtime_status();
notify pgrst,'reload schema';
commit;
-- Migration history is not rewritten by this script.
