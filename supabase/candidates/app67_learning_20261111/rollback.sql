-- CANDIDATE ONLY. Reject later function edits; never delete user data/history.
begin;
do $guard$ begin if md5(pg_get_functiondef('public.my_application_save(uuid,integer,integer,uuid,text,text,text,uuid)'::regprocedure)) <> '65edac758433cde4a123b95be3da42ee' then raise exception 'ROLLBACK_BASELINE_CHANGED'; end if; end $guard$;
CREATE OR REPLACE FUNCTION public.my_application_save(p_id uuid, p_revision integer, p_year integer, p_university uuid, p_division text, p_admission_type text, p_admission_name text, p_request_key uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=auth.uid(); a public.student_applications; old_event public.student_application_events; cmd jsonb; previous jsonb; university_name text;
begin
 perform account_private.lock_subject(u);
 if not account_private.allowed(u) then raise insufficient_privilege; end if;
 if p_request_key is null or p_year is null or p_year not between 1900 and 2200 or p_revision is null or p_revision<0
 or coalesce(char_length(btrim(p_division)),0) not between 1 and 120
 or coalesce(char_length(btrim(p_admission_type)),0) not between 1 and 80
 or coalesce(char_length(btrim(p_admission_name)),0) not between 1 and 120 then raise check_violation using message='INVALID_APPLICATION';end if;
 cmd=jsonb_build_object('id',p_id,'revision',p_revision,'year',p_year,'university',p_university,'division',btrim(p_division),'type',btrim(p_admission_type),'name',btrim(p_admission_name));
 select * into old_event from public.student_application_events where user_id=u and request_key=p_request_key;
 if found then
  if old_event.kind not in ('created','details_changed') or old_event.payload->'command' is distinct from cmd then raise check_violation using message='REQUEST_KEY_REUSED';end if;
  return old_event.application_id;
 end if;
 if p_id is null then
  if p_revision<>0 then raise check_violation;end if;
  select name into university_name from public.universities where id=p_university and is_active;
  if not found then raise check_violation using message='UNIVERSITY_NOT_FOUND';end if;
  insert into public.student_applications(user_id,admission_year,university_id,university_name_snapshot,intended_division,admission_type,admission_name)
   values(u,p_year,p_university,university_name,btrim(p_division),btrim(p_admission_type),btrim(p_admission_name)) returning * into a;
 else
  select * into a from public.student_applications where id=p_id and user_id=u for update;
  if not found then raise insufficient_privilege;end if;
  if a.revision<>p_revision then raise exception 'APPLICATION_CHANGED' using errcode='40001';end if;
  previous=to_jsonb(a)-'user_id';
  -- Preserve the year-specific historical name on edits; resolve only a new identity.
  university_name=a.university_name_snapshot;
  if a.university_id<>p_university then
   select name into university_name from public.universities where id=p_university and is_active;
   if not found then raise check_violation using message='UNIVERSITY_NOT_FOUND';end if;
  end if;
  update public.student_applications set admission_year=p_year,university_id=p_university,university_name_snapshot=university_name,
   intended_division=btrim(p_division),admission_type=btrim(p_admission_type),admission_name=btrim(p_admission_name),revision=revision+1,updated_at=clock_timestamp()
   where id=p_id and user_id=u returning * into a;
 end if;
 insert into public.student_application_events(application_id,user_id,request_key,kind,payload)
 values(a.id,u,p_request_key,case when p_id is null then 'created' else 'details_changed' end,jsonb_build_object('command',cmd,'before',previous,'after',to_jsonb(a)-'user_id'));
 return a.id;
end$function$
;
do $guard$ begin if md5(pg_get_functiondef('student_private.study_summary(uuid,timestamp with time zone)'::regprocedure)) <> 'a1622f936527c48df8c24d35a2163650' then raise exception 'ROLLBACK_BASELINE_CHANGED'; end if; end $guard$;
CREATE OR REPLACE FUNCTION student_private.study_summary(p_user uuid, p_now timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
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
end$function$
;
commit;
