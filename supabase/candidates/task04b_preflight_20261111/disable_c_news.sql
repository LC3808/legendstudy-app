-- Emergency soft rollback C, ONLY if it is deployed in a future approved rollout.
-- Current C is HOLD and absent in production. Preserve original evidence and revisions.
begin;
revoke all on function public.university_news_feed(uuid[],integer,timestamptz) from public,anon,authenticated;
commit;
-- Also stop the separately authorized ingestion job. Do not DELETE/TRUNCATE evidence.
