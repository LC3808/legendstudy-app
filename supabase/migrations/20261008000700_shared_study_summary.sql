-- APP completed Study snapshots -> one shared KST union read model for MY/Admin.
-- No timer writes, profile changes or changes to existing APP functions.
begin;
create function student_private.study_summary(p_user uuid,p_now timestamptz) returns jsonb
language plpgsql stable set search_path='' as $$
declare today date=(p_now at time zone 'Asia/Seoul')::date; first_day timestamptz; last_day timestamptz; n integer; result jsonb;
begin
 first_day=(today-29)::timestamp at time zone 'Asia/Seoul';
 last_day=(today+1)::timestamp at time zone 'Asia/Seoul';
 -- Match APP's bounded 2,000 completed-record contract; never silently truncate totals.
 select count(*) into n from (select 1 from public.study_sessions where user_id=p_user
 and started_at>=first_day-interval '24 hours' and started_at<last_day and ended_at>first_day limit 2001) r;
 if n>2000 then raise exception 'STUDY_HISTORY_LIMIT' using errcode='54000';end if;
 with intervals as (
  select int8range(floor(extract(epoch from s.started_at)*1000)::bigint+(v->>0)::bigint,
   floor(extract(epoch from s.started_at)*1000)::bigint+(v->>1)::bigint,'[)') span
  from public.study_sessions s cross join lateral jsonb_array_elements(s.active_segments) v
  where s.user_id=p_user and s.started_at>=first_day-interval '24 hours' and s.started_at<last_day and s.ended_at>first_day
  and s.include_in_study_total
 ), merged as (select range_agg(span) spans from intervals), bounds as (
  select today-i as bucket_day,
   (extract(epoch from ((today-i)::timestamp at time zone 'Asia/Seoul'))*1000)::bigint lo,
   (extract(epoch from ((today-i+1)::timestamp at time zone 'Asia/Seoul'))*1000)::bigint hi
  from generate_series(0,29) i
 ), totals as (
  select b.bucket_day,coalesce((select sum(greatest(0,least(upper(s),b.hi)-greatest(lower(s),b.lo)))
   from merged cross join lateral unnest(spans) s),0)::bigint ms from bounds b
 ) select jsonb_build_object('version','study-summary-v1','as_of',p_now,'timezone','Asia/Seoul','unit','milliseconds',
 'source','completed_synced_sessions','record_count',n,
 'today_ms',sum(ms) filter(where bucket_day=today),
 'week_ms',sum(ms) filter(where bucket_day>=date_trunc('week',today::timestamp)::date),
 'last30_ms',sum(ms),
 'daily7',jsonb_agg(jsonb_build_object('date',bucket_day,'milliseconds',ms) order by bucket_day) filter(where bucket_day>=today-6)) into result from totals;
 return result;
end$$;
create function public.my_study_summary() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 return student_private.study_summary(auth.uid(),statement_timestamp());
end$$;
revoke all on function student_private.study_summary(uuid,timestamptz),public.my_study_summary() from public,anon,authenticated;
grant execute on function public.my_study_summary() to authenticated;
commit;
-- Safe disable: revoke execute on public.my_study_summary() from authenticated.
-- Original APP Study storage and functions remain untouched.
