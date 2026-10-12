begin;
set local lock_timeout='5s';
drop function public.essay_registered_questions(uuid);
notify pgrst,'reload schema';
commit;
