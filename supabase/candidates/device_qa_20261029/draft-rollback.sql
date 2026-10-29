-- NOT APPLIED. psql from this directory. Restore function only; preserve ALL draft/session/grant records.
-- Leaving the private grant table preserves the approval audit; the restored function ignores it.
begin;
CREATE OR REPLACE FUNCTION public.essay_open_session(p_id uuid, p_question uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=essay_private.uid(); existing public.essay_practice_sessions;
begin
 if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED'; end if;
 if p_id is null or not exists(select 1 from public.essay_questions where id=p_question and is_published) then raise sqlstate 'PT422' using message='INVALID_QUESTION'; end if;
 insert into public.essay_practice_sessions(id,user_id,question_id) values(p_id,u,p_question) on conflict(id) do nothing;
 select * into existing from public.essay_practice_sessions where id=p_id for update;
 if existing.user_id<>u or existing.question_id<>p_question then raise sqlstate 'PT409' using message='CONFLICT'; end if;
 insert into public.essay_drafts(session_id,device_class) values(p_id,'web_desktop') on conflict do nothing;
 return p_id;
end$function$;
commit;
