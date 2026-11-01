-- TASK10 approval candidate only. Requires installed essay_feedback_v1.
-- No prior rating backfill. Reuses existing payload hash, ownership and 10/hour lock.
begin;
alter table feedback_private.essay_context add column rating smallint check(rating between 1 and 5),
 add column positive_reasons text[] not null default '{}',
 add column negative_reasons text[] not null default '{}',
 add constraint essay_rating_kind check(rating is null or (kind='quality' and satisfaction is null));
create or replace function public.essay_feedback_submit(p jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); k uuid; f uuid; prior text; kind text=p->>'kind'; sat text=p->>'satisfaction';
 cat text=p->>'category'; msg text=btrim(coalesce(p->>'message','')); ref text=nullif(p->>'evaluation_ref','');
 rid uuid; qid uuid; eid uuid; vid uuid; at_time timestamptz; rating integer; positives text[]; negatives text[];
begin
 if u is null or account_private.allowed(u) is not true then raise sqlstate '42501';end if;
 if jsonb_typeof(p)<>'object' or p is null or exists(select 1 from jsonb_object_keys(p) x where x not in
 ('request_key','kind','satisfaction','category','message','evaluation_ref','platform','app_version','error_code','occurred_at','rating','positive_reasons','negative_reasons')) then raise exception 'INVALID_INPUT';end if;

 if p ? 'rating' then
  if jsonb_typeof(p->'rating') <> 'number' or (p->>'rating') !~ '^[1-5]$' or kind <> 'quality' or sat is not null then raise exception 'INVALID_RATING'; end if;
  rating=(p->>'rating')::integer;
 end if;
 if (p ? 'positive_reasons' or p ? 'negative_reasons') and rating is null then raise exception 'INVALID_RATING';end if;
 if jsonb_typeof(coalesce(p->'positive_reasons','[]'::jsonb))<>'array' or jsonb_typeof(coalesce(p->'negative_reasons','[]'::jsonb))<>'array' then raise exception 'INVALID_REASONS';end if;
 select coalesce(array_agg(value),'{}'::text[]) into positives from jsonb_array_elements_text(coalesce(p->'positive_reasons','[]'::jsonb));
 select coalesce(array_agg(value),'{}'::text[]) into negatives from jsonb_array_elements_text(coalesce(p->'negative_reasons','[]'::jsonb));
 if cardinality(positives)>5 or cardinality(negatives)>6
 or not positives <@ array['accurate_diagnosis','rubric_understanding','specific_feedback','rewrite_help','clear_explanation']::text[]
 or not negatives <@ array['inaccurate','abstract','unsupported_claim','rubric_connection','slow','complex']::text[]
 or array_position(positives,null) is not null or array_position(negatives,null) is not null
 or cardinality(positives)<>(select count(distinct x) from unnest(positives) x)
 or cardinality(negatives)<>(select count(distinct x) from unnest(negatives) x) then raise exception 'INVALID_REASONS';end if;
 k=(p->>'request_key')::uuid;
 if k is null or kind is null or kind not in ('quality','bug') or length(msg)>5000
 or p->>'platform' is null or p->>'platform' not in ('ios','android','web','macos','windows','linux','fuchsia')
 or length(coalesce(p->>'app_version','')) not between 1 and 40
 or (p->>'error_code' is not null and p->>'error_code' !~ '^[A-Z0-9_]{1,80}$') then raise exception 'INVALID_INPUT';end if;
 if kind='quality' and ((rating is null and (sat is null or sat not in ('helpful','unhelpful'))) or (cat is not null and cat not in
 ('helpful','inaccurate','rubric','score','unclear','function','other'))) then raise exception 'INVALID_INPUT';end if;
 if kind='bug' and (sat is not null or msg='' or cat is null or cat not in
 ('submission','ocr','evaluation','result','rewrite','credit','display','other')) then raise exception 'INVALID_INPUT';end if;
 perform pg_advisory_xact_lock(hashtextextended('essay-feedback/'||u::text,0));
 select c.feedback_id,c.request_hash into f,prior from feedback_private.essay_context c where c.user_id=u and c.request_key=k;
 if f is not null then
  if prior<>md5(p::text) then raise exception 'IDEMPOTENCY_CONFLICT';end if;
  return f;
 end if;
 if (select count(*) from feedback_private.essay_context where user_id=u and recorded_at>clock_timestamp()-interval '1 hour')>=10 then raise exception 'RATE_LIMIT';end if;
 if ref is not null then
  if ref !~ '^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}$' then raise exception 'RESULT_REFERENCE_UNAVAILABLE';end if;
  rid=split_part(ref,'/',1)::uuid;qid=split_part(ref,'/',2)::uuid;
  select r.exam_id,e.university_id into eid,vid from essay_exam_private.runs r
   join public.credit_accounts a on a.id=r.account_id join public.essay_exams e on e.id=r.exam_id
   where r.id=rid and a.user_id=u and exists(select 1 from jsonb_array_elements(r.snapshot->'answers') x where x->>'questionId'=qid::text);
  if eid is null then raise sqlstate '42501';end if;
 end if;
 at_time=coalesce((p->>'occurred_at')::timestamptz,clock_timestamp());
 if at_time>clock_timestamp()+interval '5 minutes' then raise exception 'INVALID_TIME';end if;
 insert into public.feedback_submissions(user_id,category,title,body,app_version,build_number,platform,os_version)
 values(u,case when kind='bug' then 'bug' else 'suggestion' end,
 case when kind='bug' then '논술 LAB 오류 신고' else '논술 LAB 첨삭 의견' end,
 case when msg<>'' then msg when rating is not null then '만족도 '||rating::text||'/5' when sat='helpful' then '도움이 되었어요' else '아쉬워요' end,p->>'app_version','unknown',p->>'platform','not-collected') returning id into f;
 insert into feedback_private.essay_context(feedback_id,user_id,request_key,request_hash,kind,satisfaction,detail_category,evaluation_ref,run_id,question_id,exam_id,university_id,error_code,occurred_at,rating,positive_reasons,negative_reasons)
 values(f,u,k,md5(p::text),kind,sat,cat,ref,rid,qid,eid,vid,p->>'error_code',at_time,rating,positives,negatives);
 return f;
end $$;


revoke all on function public.essay_feedback_submit(jsonb) from public,anon,service_role;
grant execute on function public.essay_feedback_submit(jsonb) to authenticated;
create function public.admin_essay_satisfaction(p_from timestamptz,p_to timestamptz) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 if auth.uid() is null or public.admin_operator() is not true or account_private.allowed(auth.uid()) is not true then raise sqlstate '42501';end if;
 if p_from is null or p_to is null or p_to<=p_from or p_to-p_from>interval '400 days' then raise sqlstate '22023';end if;
 with selected as (
 select c.*,s.status from feedback_private.essay_context c join public.feedback_submissions s on s.id=c.feedback_id
 where c.recorded_at>=p_from and c.recorded_at<p_to
 ), counts as (
 select count(*) filter(where rating is not null) rated,avg(rating) average,
 count(*) filter(where satisfaction is not null) legacy_binary,
 count(*) filter(where kind='bug') reports,
 count(*) filter(where kind='bug' and status='resolved') resolved_reports from selected
 )
 select jsonb_build_object('version','essay-satisfaction-v2','basis','submitted_feedback','stats',(select to_jsonb(counts) from counts),
 'distribution',(select jsonb_agg(jsonb_build_object('rating',n,'count',(select count(*) from selected where rating=n))) from generate_series(1,5)n),
 'universities',(select coalesce(jsonb_agg(x),'[]'::jsonb) from(select university_id,count(*) rated,avg(rating) average from selected where rating is not null group by university_id)x),
 'exams',(select coalesce(jsonb_agg(x),'[]'::jsonb) from(select exam_id,count(*) rated,avg(rating) average from selected where rating is not null group by exam_id)x),
 'positive_reasons',(select coalesce(jsonb_object_agg(reason,n),'{}'::jsonb) from(select reason,count(*) n from selected cross join unnest(positive_reasons)reason group by reason)x),
 'negative_reasons',(select coalesce(jsonb_object_agg(reason,n),'{}'::jsonb) from(select reason,count(*) n from selected cross join unnest(negative_reasons)reason group by reason)x),
 'low_ratings',(select coalesce(jsonb_agg(x),'[]'::jsonb) from(select feedback_id,rating,recorded_at from selected where rating<=2 and evaluation_ref is not null order by recorded_at desc,feedback_id limit 25)x)) into result;
 return result;
end $$;
revoke all on function public.admin_essay_satisfaction(timestamptz,timestamptz) from public,anon,service_role;
grant execute on function public.admin_essay_satisfaction(timestamptz,timestamptz) to authenticated;
notify pgrst,'reload schema';
commit;
