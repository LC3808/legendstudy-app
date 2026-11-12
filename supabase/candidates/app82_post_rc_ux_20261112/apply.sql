-- REVIEW CANDIDATE ONLY. No production application authorized.
-- Existing functions, tables, RLS, thresholds and source records are unchanged.
begin;
do $$ begin
  if not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='my_study_summary' and md5(pg_get_functiondef(p.oid))='fb05ae22eb89f3cce4f0e3fee71a527e') then raise exception 'BASELINE_CHANGED: public.my_study_summary'; end if;
  if not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='student_school_card' and md5(pg_get_functiondef(p.oid))='b6554f69100fb11a9cd5c39fc3589345') then raise exception 'BASELINE_CHANGED: public.student_school_card'; end if;
  if not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='student_school_ranking' and md5(pg_get_functiondef(p.oid))='a12719361e8735a7fbeedbdc7277f845') then raise exception 'BASELINE_CHANGED: public.student_school_ranking'; end if;
  if not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='student_private' and p.proname='study_summary' and md5(pg_get_functiondef(p.oid))='a1622f936527c48df8c24d35a2163650') then raise exception 'BASELINE_CHANGED: student_private.study_summary'; end if;
  if to_regprocedure('public.student_school_ranking_page(text,text,text,integer,integer,timestamp with time zone,text)') is not null
     or to_regprocedure('public.my_study_percentile()') is not null then
    raise exception 'CANDIDATE_ALREADY_EXISTS';
  end if;
end $$;

create function public.student_school_ranking_page(
  p_period text default 'all', p_metric text default 'total',
  p_scope text default 'ranked', p_offset integer default 0,
  p_limit integer default 10, p_as_of timestamptz default null,
  p_revision text default null
) returns jsonb language plpgsql stable security definer
set search_path = '' set statement_timeout = '8s' as $function$
declare
  v_uid uuid := auth.uid();
  v_office text; v_school text;
  v_as_of timestamptz := coalesce(p_as_of, statement_timestamp());
  v_from timestamptz; v_to timestamptz := v_as_of; v_week_start timestamptz;
  v_min_recorders constant int := 3; v_min_users constant int := 3;
  v_min_rank int;
  result jsonb;
begin
  if v_uid is null or not account_private.allowed(v_uid) then raise insufficient_privilege; end if;
  if p_period is null or p_period not in ('all','week','last_week','month')
     or p_metric is null or p_metric not in ('total','average','participation')
     or p_scope is null or p_scope not in ('ranked','unranked')
     or p_offset is null or p_offset < 0 or p_offset % 10 <> 0 or p_offset > 100000
     or p_limit is distinct from 10 then
    raise sqlstate 'PT422' using message='INVALID_RANK_QUERY';
  end if;
  if v_as_of > statement_timestamp() or v_as_of < statement_timestamp() - interval '15 minutes'
     or (p_offset > 0 and (p_as_of is null or p_revision is null)) then
    raise sqlstate 'PT409' using message='RANK_SNAPSHOT_EXPIRED';
  end if;
  v_min_rank := case when p_metric='participation' then 1 else 3 end;
  v_week_start := date_trunc('week',v_to at time zone 'Asia/Seoul') at time zone 'Asia/Seoul';
  if p_period='week' then v_from := v_week_start;
  elsif p_period='last_week' then v_from := v_week_start-interval '7 days'; v_to := v_week_start;
  elsif p_period='month' then v_from := v_to-interval '30 days';
  else v_from := '1970-01-01T00:00:00Z'::timestamptz; end if;
  select neis_office_code,neis_school_code into v_office,v_school from public.profiles where id=v_uid;
  with eligible as materialized (
    select id, neis_office_code as office, neis_school_code as school
    from public.profiles where account_private.allowed(id)
  ),
  intervals as (
    select s.user_id, e.office, e.school, int8range(
      greatest(floor(extract(epoch from v_from)*1000)::bigint, floor(extract(epoch from s.started_at)*1000)::bigint+(v->>0)::bigint),
      least(floor(extract(epoch from v_to)*1000)::bigint,      floor(extract(epoch from s.started_at)*1000)::bigint+(v->>1)::bigint),'[)') span
    from public.study_sessions s
    join eligible e on e.id = s.user_id
    cross join lateral jsonb_array_elements(s.active_segments) v
    where s.include_in_study_total and s.ended_at > v_from and s.started_at < v_to
      and floor(extract(epoch from s.started_at)*1000)::bigint+(v->>1)::bigint > floor(extract(epoch from v_from)*1000)::bigint
      and floor(extract(epoch from s.started_at)*1000)::bigint+(v->>0)::bigint < floor(extract(epoch from v_to)*1000)::bigint
  ),
  merged as (select user_id, office, school, range_agg(span) spans from intervals group by user_id, office, school),
  study  as (select user_id, office, school, sum(upper(span)-lower(span)) ms from merged cross join lateral unnest(spans) span group by user_id, office, school),
  reg as (select office, school, count(*) registered_users from eligible where office is not null and school is not null group by office, school),
  act as (select office, school, count(*) active_users, sum(ms) ms from study where office is not null and school is not null group by office, school),
  by_school as (
    select coalesce(r.office,a.office) office, coalesce(r.school,a.school) school,
           coalesce(r.registered_users,0) registered_users,
           coalesce(a.active_users,0) active_users, coalesce(a.ms,0) ms,
           case when coalesce(a.active_users,0)>0 then a.ms/a.active_users else 0 end avg_ms,
           case when coalesce(a.active_users,0)>=v_min_recorders then a.ms else null end pub_ms,
           case when coalesce(a.active_users,0)>=v_min_users then (a.ms/a.active_users) else null end pub_avg,
           case when coalesce(r.office,a.office)=v_office and coalesce(r.school,a.school)=v_school
                then coalesce(r.registered_users,0) else null end pub_registered,
           case when coalesce(r.office,a.office)=v_office and coalesce(r.school,a.school)=v_school
                then coalesce(a.active_users,0) else null end pub_active
    from reg r full join act a using (office, school)
  ),
  qualified as (
    select *, case p_metric
        when 'total' then ms
        when 'average' then avg_ms
        else active_users::bigint end sort_key
    from by_school
    where (p_metric='total' and active_users>=v_min_recorders)
       or (p_metric='average' and active_users>=v_min_users)
       or (p_metric in ('participation','registered') and active_users>=1)
  ),
  ranked as (
    select *, rank() over (order by sort_key desc) rnk,
           row_number() over (order by sort_key desc, office, school) ord
    from qualified
  ),
  outside as (
    select *, row_number() over(order by office, school) ord
    from by_school where active_users > 0 and active_users < v_min_rank
  ),
  visible as materialized (
    select 'ranked'::text scope, ord, office, school,
      jsonb_build_object('office_code',office,'school_code',school,
        'registered_users',pub_registered,'active_users',pub_active,
        'ms',pub_ms,'avg_ms',pub_avg,'rank',rnk) item from ranked
    union all
    select 'unranked', ord, office, school,
      jsonb_build_object('office_code',office,'school_code',school,
        'registered_users',pub_registered,'active_users',pub_active,
        'ms',null,'avg_ms',null,'rank',null) from outside
  )
  select jsonb_build_object(
    'version','student-school-ranking-page-v1','period',p_period,'metric',p_metric,
    'scope',p_scope,'offset',p_offset,'limit',p_limit,'as_of',v_as_of,
    'min_recorders',v_min_recorders,'min_rank_recorders',v_min_rank,
    -- Digest only already-authorized projections, never masked personal/count data.
    'revision',md5(coalesce((select jsonb_agg(item order by scope,ord)::text from visible),'[]')),
    'rows',coalesce((select jsonb_agg(item order by ord) from visible
      where scope=p_scope and ord>p_offset and ord<=p_offset+p_limit),'[]'::jsonb),
    'next_offset',case when exists(select 1 from visible where scope=p_scope and ord>p_offset+p_limit)
      then p_offset+p_limit else null end,
    'unranked',case when p_scope='ranked' and p_offset=0 then
      coalesce((select jsonb_agg(item order by ord) from visible where scope='unranked' and ord<=10),'[]'::jsonb)
      else '[]'::jsonb end,
    'unranked_next_offset',case when p_scope='ranked' and p_offset=0
      and exists(select 1 from visible where scope='unranked' and ord>10) then 10 else null end,
    'my_school',(select item from visible where scope='ranked' and office=v_office and school=v_school)
  ) into result;
  if p_revision is not null and p_revision is distinct from result->>'revision' then
    raise sqlstate 'PT409' using message='RANK_SNAPSHOT_CHANGED';
  end if;
  return result;
end $function$;
revoke all on function public.student_school_ranking_page(text,text,text,integer,integer,timestamptz,text) from public,anon;
grant execute on function public.student_school_ranking_page(text,text,text,integer,integer,timestamptz,text) to authenticated;

-- Personal-only derived percentile; no private helper exposed and no writes.
create function public.my_study_percentile() returns jsonb
language plpgsql stable security definer set search_path = '' set statement_timeout = '8s'
as $function$
declare
  v_uid uuid := auth.uid(); v_as_of timestamptz := statement_timestamp();
  v_min_sample constant int := 20;
  v_n bigint; v_greater bigint; v_equal bigint; v_own numeric;
begin
  if v_uid is null or not account_private.allowed(v_uid) then raise insufficient_privilege; end if;
  with eligible as materialized (select id from public.profiles where account_private.allowed(id)),
  intervals as (
    select s.user_id, int8range(
      floor(extract(epoch from s.started_at)*1000)::bigint+(v->>0)::bigint,
      floor(extract(epoch from s.started_at)*1000)::bigint+(v->>1)::bigint,'[)') span
    from public.study_sessions s join eligible e on e.id=s.user_id
    cross join lateral jsonb_array_elements(s.active_segments) v
    where s.include_in_study_total and s.ended_at<=v_as_of
  ), merged as (select user_id,range_agg(span) spans from intervals group by user_id),
  totals as materialized (
    select user_id,sum(upper(span)-lower(span)) ms from merged cross join lateral unnest(spans) span
    group by user_id having sum(upper(span)-lower(span))>0
  ), own as (select ms from totals where user_id=v_uid)
  select count(*),count(*) filter(where ms>(select ms from own)),
    count(*) filter(where ms=(select ms from own)),coalesce((select ms from own),0)
  into v_n,v_greater,v_equal,v_own from totals;
  return jsonb_build_object(
    'version','study-percentile-v1','as_of',v_as_of,
    'source','completed_synced_sessions','method','ceil_tie_upper_bound',
    'minimum_sample',v_min_sample,
    'status',case when v_own<=0 then 'no_records' when v_n<v_min_sample then 'insufficient_sample' else 'ready' end,
    'population',case when v_own>0 and v_n>=v_min_sample then v_n else null end,
    'rank',case when v_own>0 and v_n>=v_min_sample then v_greater+1 else null end,
    'tie_count',case when v_own>0 and v_n>=v_min_sample then v_equal else null end,
    'top_percent',case when v_own>0 and v_n>=v_min_sample then ceil(100.0*(v_greater+v_equal)/v_n)::int else null end
  );
end $function$;
revoke all on function public.my_study_percentile() from public,anon;
grant execute on function public.my_study_percentile() to authenticated;
commit;
