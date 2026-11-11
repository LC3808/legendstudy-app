-- Future reviewed feed only; does not approve the current 37eb530 feed.
begin;
grant execute on function public.university_news_feed(uuid[],integer,timestamptz) to authenticated;
commit;
