-- Candidate only. No production execution without Owner approval.
-- Derived read only; follows admin_learning_analytics interval/eligibility policy.
begin;
create function public.admin_dashboard_study(p_from timestamptz, p_to timestamptz)
returns jsonb language plpgsql stable security definer
set search_path = '' set statement_timeout = '8s'
as $$
declare result jsonb;
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then raise insufficient_privilege; end if;
 if p_from is null or p_to is null or not isfinite(p_from) or not isfinite(p_to) or p_to<=p_from or p_to-p_from>interval '400 days' then raise sqlstate 'PT422' using message='INVALID_PERIOD'; end if;
 with eligible as materialized (
  select id,case when academic_status='retaker' then 'retaker' when academic_status='student' and grade_level in (1,2,3) then grade_level::text else 'unknown' end grade
  from public.profiles where account_private.allowed(id)
 ), intervals as (
  select s.user_id,e.grade,int8range(
   greatest(floor(extract(epoch from p_from)*1000)::bigint,floor(extract(epoch from s.started_at)*1000)::bigint+(v->>0)::bigint),
   least(floor(extract(epoch from p_to)*1000)::bigint,floor(extract(epoch from s.started_at)*1000)::bigint+(v->>1)::bigint),'[)') span
  from public.study_sessions s join eligible e on e.id=s.user_id cross join lateral jsonb_array_elements(s.active_segments) v
  where s.include_in_study_total and s.ended_at>p_from and s.started_at<p_to
   and floor(extract(epoch from s.started_at)*1000)::bigint+(v->>1)::bigint>floor(extract(epoch from p_from)*1000)::bigint
   and floor(extract(epoch from s.started_at)*1000)::bigint+(v->>0)::bigint<floor(extract(epoch from p_to)*1000)::bigint
 ), merged as (select user_id,grade,range_agg(span) spans from intervals group by user_id,grade),
 study as (select user_id,grade,sum(upper(span)-lower(span)) ms from merged cross join lateral unnest(spans) span group by user_id,grade),
 cohorts as (select grade,count(*) users,sum(ms) ms from study group by grade),
 total as (select count(*) users,coalesce(sum(ms),0) ms from study),
 gate as (select not exists(select 1 from cohorts where users<5) and exists(select 1 from cohorts) ready)
 select jsonb_build_object('version','admin-dashboard-study-v1','as_of',statement_timestamp(),'minimum_sample',5,
  'total',jsonb_build_object('users',case when users>=5 then users end,'ms',case when users>=5 then ms end),
  'grades_available',(select ready from gate),
  'grades',case when (select ready from gate) then coalesce((select jsonb_agg(jsonb_build_object('grade',grade,'users',users,'ms',ms) order by grade) from cohorts),'[]'::jsonb) else '[]'::jsonb end)
 into result from total;
 return result;
end $$;
revoke all on function public.admin_dashboard_study(timestamptz,timestamptz) from public,anon,service_role;
grant execute on function public.admin_dashboard_study(timestamptz,timestamptz) to authenticated;
commit;
