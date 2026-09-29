-- Owner-approved narrow forward correction. NOT APPLIED to Production.
-- Preserve NULL (unknown active time); floor elapsed seconds before integer cast.
-- No CHECK/data/history/ACL/signature/fingerprint/locking/billing change.
begin;
-- Existing function is executor-owned; temporary membership is migration-only.
grant essay_executor to current_user;
create or replace function public.essay_submit_attempt(p_session uuid,p_revision bigint,p_key uuid,p_body_hash text) returns uuid language plpgsql security definer set search_path='' as $$
declare d public.essay_drafts; a public.essay_attempts; q public.essay_questions; h text; n integer;
begin
 perform essay_private.owner(p_session);
 if p_key is null or p_body_hash is null or p_revision is null then raise sqlstate 'PT422' using message='INVALID_INPUT'; end if;
 perform 1 from public.essay_practice_sessions where id=p_session for update;
 h=essay_private.hash(jsonb_build_array(p_session,p_revision,p_body_hash)::text);
 select * into a from public.essay_attempts where submission_key=p_key;
 if a.id is not null then
  if a.session_id<>p_session or a.submission_request_hash is distinct from h then raise sqlstate 'PT409' using message='CONFLICT'; end if;
  return a.id;
 end if;
 select * into d from public.essay_drafts where session_id=p_session for update;
 if d.revision is distinct from p_revision then raise sqlstate 'PT409' using message='STALE_DRAFT'; end if;
 if nullif(btrim(d.body),'') is null or essay_private.hash(d.body)<>p_body_hash then raise sqlstate 'PT409' using message='PAYLOAD_MISMATCH'; end if;
 select x.* into q from public.essay_questions x join public.essay_practice_sessions s on s.question_id=x.id where s.id=p_session;
 select coalesce(max(attempt_no),0)+1 into n from public.essay_attempts where session_id=p_session;
 insert into public.essay_attempts(session_id,attempt_no,body,body_sha256,input_method,device_class,mode,started_at,active_writing_seconds,character_count,count_rule_version,question_metadata_version,conditions_snapshot,submission_key,submission_request_hash)
 values(p_session,n,d.body,p_body_hash,'typed',d.device_class,d.mode,d.started_at,case when d.active_writing_seconds is null then null else least(d.active_writing_seconds,greatest(0,floor(extract(epoch from now()-d.started_at))::int)) end,char_length(d.body),'unicode-codepoints-including-whitespace-v1',q.metadata_version,jsonb_strip_nulls(jsonb_build_object('length_min',q.length_min,'length_max',q.length_max,'length_count_rule',q.length_count_rule,'time_limit_seconds',q.time_limit_seconds)),p_key,h) returning * into a;
 return a.id;
end$$;
revoke essay_executor from current_user;
commit;
