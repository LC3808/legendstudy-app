-- NOT APPLIED. Owner approval required. No Registry publication / Ledger / History writes.
-- Empty grants by default: a reviewed per-user/per-question grant is a separate step.
begin;
do $guard$
begin
 if (select md5(prosrc) from pg_proc where oid='public.essay_open_session(uuid,uuid)'::regprocedure)
    is distinct from '3c3dbdc274623c96f25836b9508840af' then
   raise exception 'DRAFT_BASELINE_CHANGED';
 end if;
end $guard$;
create table essay_private.draft_access (
 user_id uuid not null references auth.users(id) on delete cascade,
 question_id uuid not null references public.essay_questions(id),
 expires_at timestamptz not null,
 granted_at timestamptz not null default clock_timestamp(),
 reason text not null check (length(btrim(reason)) between 1 and 200),
 primary key(user_id,question_id)
);
alter table essay_private.draft_access enable row level security;
revoke all on essay_private.draft_access from public,anon,authenticated,service_role;
-- Existing NOLOGIN BYPASSRLS RPC owner only; authenticated cannot inspect grants.
grant select on essay_private.draft_access to essay_executor;

create or replace function public.essay_open_session(p_id uuid,p_question uuid)
returns uuid language plpgsql security definer set search_path='' as $function$
declare u uuid=essay_private.uid(); existing public.essay_practice_sessions;
begin
 if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED';end if;
 -- Preserve account lifecycle fencing in addition to the existing uid() check.
 perform account_private.lock_subject(u);
 if not account_private.allowed(u) then raise insufficient_privilege;end if;
 if p_id is null or not exists(select 1 from public.essay_questions q where q.id=p_question and (
   q.is_published or exists(select 1 from essay_private.draft_access g
     where g.user_id=u and g.question_id=q.id and g.expires_at>clock_timestamp())
 )) then raise sqlstate 'PT422' using message='INVALID_QUESTION';end if;
 insert into public.essay_practice_sessions(id,user_id,question_id) values(p_id,u,p_question) on conflict(id) do nothing;
 select * into existing from public.essay_practice_sessions where id=p_id for update;
 if existing.user_id<>u or existing.question_id<>p_question then raise sqlstate 'PT409' using message='CONFLICT';end if;
 insert into public.essay_drafts(session_id,device_class) values(p_id,'web_desktop') on conflict do nothing;
 return p_id;
end $function$;
-- Existing RPC execution grants and all session/draft RLS policies remain unchanged.
commit;
