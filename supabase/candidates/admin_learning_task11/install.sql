-- Approval candidate. Read-only reporting; no source table mutation.
begin;
create function public.admin_learning_analytics(p_from timestamptz,p_to timestamptz)
returns jsonb language plpgsql stable security definer set search_path='' set statement_timeout='8s' as $$
declare result jsonb;
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 if p_from is null or p_to is null or not isfinite(p_from) or not isfinite(p_to) or p_to<=p_from or p_to-p_from>interval '400 days' then raise sqlstate 'PT422' using message='INVALID_PERIOD';end if;
 -- Current projections, not reconstructed historical targets/bookmarks.
 with eligible as materialized (select id from public.profiles where account_private.allowed(id)),
 facts as (
 select 'targets'::text kind,t.university_id::text label,t.user_id from public.student_target_universities t join eligible e on e.id=t.user_id where t.created_at>=p_from and t.created_at<p_to
 union all select 'saved',b.content_item_id::text,b.user_id from public.bookmarks b join eligible e on e.id=b.user_id where b.created_at>=p_from and b.created_at<p_to
 union all select 'recent',r.content_item_id::text,r.user_id from public.recent_views r join eligible e on e.id=r.user_id where r.viewed_at>=p_from and r.viewed_at<p_to
 union all select 'applications',a.university_id::text,a.user_id from public.student_applications a join eligible e on e.id=a.user_id where a.created_at>=p_from and a.created_at<p_to
 ), cohorts as (select kind,label,count(*) records,count(distinct user_id) users from facts group by kind,label),
 ranked as (select *,row_number() over(partition by kind order by users desc,label) rank from cohorts where users>=5),
 intervals as (
 select s.user_id,int8range(greatest(floor(extract(epoch from p_from)*1000)::bigint,floor(extract(epoch from s.started_at)*1000)::bigint+(v->>0)::bigint),least(floor(extract(epoch from p_to)*1000)::bigint,floor(extract(epoch from s.started_at)*1000)::bigint+(v->>1)::bigint),'[)') span
 from public.study_sessions s join eligible e on e.id=s.user_id cross join lateral jsonb_array_elements(s.active_segments) v
 where s.include_in_study_total and s.ended_at>p_from and s.started_at<p_to
 and floor(extract(epoch from s.started_at)*1000)::bigint+(v->>1)::bigint>floor(extract(epoch from p_from)*1000)::bigint
 and floor(extract(epoch from s.started_at)*1000)::bigint+(v->>0)::bigint<floor(extract(epoch from p_to)*1000)::bigint
 ), merged as (select user_id,range_agg(span) spans from intervals group by user_id),
 study as (select user_id,sum(upper(span)-lower(span)) ms from merged cross join lateral unnest(spans) span group by user_id),
 summaries as (select kind,count(*) records,count(distinct user_id) users from facts group by kind)
 select jsonb_build_object('version','admin-learning-analytics-v1','as_of',statement_timestamp(),'from',p_from,'to',p_to,'timezone','Asia/Seoul','minimum_sample',5,
 'metrics',jsonb_build_object(
 'targets',(select case when users>=5 then users end from summaries where kind='targets'),
 'saved',(select case when users>=5 then records end from summaries where kind='saved'),
 'recent',(select case when users>=5 then records end from summaries where kind='recent'),
 'applications',(select case when users>=5 then records end from summaries where kind='applications'),
 'study_users',(select case when count(*)>=5 then count(*) end from study),
 'study_ms',(select case when count(*)>=5 then sum(ms) end from study)),
 'rows',coalesce((select jsonb_agg(jsonb_build_object('kind',kind,'label',coalesce(case when kind in ('targets','applications') then (select name from public.universities where id::text=label) else (select title from public.content_items where id::text=label) end,'명칭 확인 필요'),'users',users,'records',records) order by kind,rank) from ranked where rank<=10),'[]'::jsonb),
 'state',case when not exists(select 1 from facts) and not exists(select 1 from study) then 'EMPTY' when not exists(select 1 from ranked) and (select count(*) from study)<5 then 'SUPPRESSED' else 'READY' end)
 into result;
 return result;
end$$;
revoke all on function public.admin_learning_analytics(timestamptz,timestamptz) from public,anon,authenticated,service_role;
grant execute on function public.admin_learning_analytics(timestamptz,timestamptz) to authenticated;
commit;
