-- CANDIDATE ONLY. Preserve/export newly collected histories BEFORE a future rollback.
-- Never execute this destructive rollback on an existing production deployment without approval.
begin;
drop function public.university_news_feed(uuid[],integer,timestamptz);
drop table public.university_news_revisions;
drop function public.task04_news_immutable();
drop table public.university_official_sources;
drop function public.save_my_home_configuration(jsonb,bigint);
drop function public.my_home_configuration();
drop table public.home_configuration_revisions;
commit;
