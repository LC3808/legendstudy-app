-- Disable satisfaction v2 flags and restore prior WEB artifact first. Preserve records/columns.
begin;
revoke all on function public.admin_essay_satisfaction(timestamptz,timestamptz) from public,anon,authenticated,service_role;
create or replace function public.essay_feedback_submit(p jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); k uuid; f uuid; prior text; kind text=p->>'kind'; sat text=p->>'satisfaction';
 cat text=p->>'category'; msg text=btrim(coalesce(p->>'message','')); ref text=nullif(p->>'evaluation_ref','');
 rid uuid; qid uuid; eid uuid; vid uuid; at_time timestamptz;
begin
 if u is null or account_private.allowed(u) is not true then raise sqlstate '42501';end if;
 if jsonb_typeof(p)<>'object' or p is null or exists(select 1 from jsonb_object_keys(p) x where x not in
 ('request_key','kind','satisfaction','category','message','evaluation_ref','platform','app_version','error_code','occurred_at')) then raise exception 'INVALID_INPUT';end if;
 k=(p->>'request_key')::uuid;
 if k is null or kind is null or kind not in ('quality','bug') or length(msg)>5000
 or p->>'platform' is null or p->>'platform' not in ('ios','android','web','macos','windows','linux','fuchsia')
 or length(coalesce(p->>'app_version','')) not between 1 and 40
 or (p->>'error_code' is not null and p->>'error_code' !~ '^[A-Z0-9_]{1,80}$') then raise exception 'INVALID_INPUT';end if;
 if kind='quality' and (sat is null or sat not in ('helpful','unhelpful') or (cat is not null and cat not in
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
 case when msg<>'' then msg when sat='helpful' then '도움이 되었어요' else '아쉬워요' end,p->>'app_version','unknown',p->>'platform','not-collected') returning id into f;
 insert into feedback_private.essay_context(feedback_id,user_id,request_key,request_hash,kind,satisfaction,detail_category,evaluation_ref,run_id,question_id,exam_id,university_id,error_code,occurred_at)
 values(f,u,k,md5(p::text),kind,sat,cat,ref,rid,qid,eid,vid,p->>'error_code',at_time);
 return f;
end $$;


revoke all on function public.essay_feedback_submit(jsonb) from public,anon,service_role;
grant execute on function public.essay_feedback_submit(jsonb) to authenticated;
notify pgrst,'reload schema';
commit;
