-- Shared self-reported Application facts, distinct from interests and Essay practice.
-- Additive; no replacement of existing profile/target/payment/deletion functions.
begin;
create schema student_private;
revoke all on schema student_private from public,anon,authenticated;

create table public.student_applications (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 admission_year smallint not null check(admission_year between 1900 and 2200),
 university_id uuid not null references public.universities(id) on delete restrict,
 university_name_snapshot text not null,
 intended_division text not null check(char_length(intended_division) between 1 and 120),
 admission_type text not null check(char_length(admission_type) between 1 and 80),
 admission_name text not null check(char_length(admission_name) between 1 and 120),
 revision integer not null default 1 check(revision>0),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(id,user_id)
);
create index student_applications_owner on public.student_applications(user_id,created_at desc,id);
create table public.student_application_events (
 id uuid primary key default gen_random_uuid(),
 application_id uuid not null,
 user_id uuid not null,
 request_key uuid not null,
 kind text not null check(kind in ('created','details_changed','planned','submitted','stage_pass','accepted','additional_acceptance','rejected','not_registered','registered')),
 occurred_at timestamptz check(occurred_at is null or isfinite(occurred_at)),
 recorded_at timestamptz not null default clock_timestamp(),
 supersedes_event_id uuid,
 -- Server-built snapshot/command for idempotency and historical reconstruction.
 payload jsonb not null,
 unique(user_id,request_key),
 unique(id,application_id,user_id),
 unique(supersedes_event_id),
 foreign key(application_id,user_id) references public.student_applications(id,user_id) on delete cascade,
 foreign key(supersedes_event_id,application_id,user_id) references public.student_application_events(id,application_id,user_id) on delete cascade,
 check(supersedes_event_id is null or supersedes_event_id<>id)
);
create index student_application_events_timeline on public.student_application_events(application_id,recorded_at desc,id desc);
alter table public.student_applications enable row level security;
alter table public.student_application_events enable row level security;
revoke all on public.student_applications,public.student_application_events from public,anon,authenticated;
grant select on public.student_applications,public.student_application_events to authenticated;
create policy application_owner_read on public.student_applications for select to authenticated using(user_id=auth.uid() and public.account_service_allowed());
create policy application_event_owner_read on public.student_application_events for select to authenticated using(user_id=auth.uid() and public.account_service_allowed());

create function public.my_application_save(p_id uuid,p_revision integer,p_year integer,p_university uuid,p_division text,p_admission_type text,p_admission_name text,p_request_key uuid)
returns uuid language plpgsql security definer set search_path='' as $$
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
end$$;

create function public.my_application_event(p_id uuid,p_kind text,p_occurred_at timestamptz,p_supersedes uuid,p_request_key uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); e public.student_application_events; cmd jsonb; result uuid;
begin
 perform account_private.lock_subject(u);
 if not account_private.allowed(u) then raise insufficient_privilege;end if;
 if p_request_key is null or p_kind is null or p_kind not in ('planned','submitted','stage_pass','accepted','additional_acceptance','rejected','not_registered','registered')
 or (p_occurred_at is not null and not isfinite(p_occurred_at)) then raise check_violation;end if;
 perform 1 from public.student_applications where id=p_id and user_id=u for update;
 if not found then raise insufficient_privilege;end if;
 cmd=jsonb_build_object('kind',p_kind,'occurred_at',p_occurred_at,'supersedes',p_supersedes);
 select * into e from public.student_application_events where user_id=u and request_key=p_request_key;
 if found then
  if e.application_id<>p_id or e.payload is distinct from cmd then raise check_violation using message='REQUEST_KEY_REUSED';end if;
  return e.id;
 end if;
 if p_supersedes is not null then
  perform 1 from public.student_application_events old where old.id=p_supersedes and old.application_id=p_id and old.user_id=u
   and old.kind not in ('created','details_changed') and not exists(select 1 from public.student_application_events replacement where replacement.supersedes_event_id=old.id);
  if not found then raise check_violation using message='INVALID_EVENT_CORRECTION';end if;
 end if;
 insert into public.student_application_events(application_id,user_id,request_key,kind,occurred_at,supersedes_event_id,payload)
 values(p_id,u,p_request_key,p_kind,p_occurred_at,p_supersedes,cmd) returning id into result;
 return result;
end$$;

create function public.my_application_delete(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 perform account_private.lock_subject(auth.uid());
 if not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 delete from public.student_applications where id=p_id and user_id=auth.uid();
 if not found then raise insufficient_privilege;end if;
end$$;

-- Pure private read model, bounded per page. No student answer data.
create function student_private.applications(p_user uuid,p_offset integer default 0) returns jsonb language sql stable set search_path='' as $$
 select jsonb_build_object('version','applications-v1','offset',p_offset,'limit',25,
 'has_more',exists(select 1 from public.student_applications where user_id=p_user order by created_at desc,id desc offset p_offset+25 limit 1),
 'items',coalesce((select jsonb_agg(to_jsonb(a)-'user_id'||jsonb_build_object('latest_event',
 (select jsonb_build_object('id',e.id,'kind',e.kind,'occurred_at',e.occurred_at,'recorded_at',e.recorded_at)
 from public.student_application_events e where e.application_id=a.id and e.kind not in ('created','details_changed')
 and not exists(select 1 from public.student_application_events replacement where replacement.supersedes_event_id=e.id)
 order by coalesce(e.occurred_at,e.recorded_at) desc,e.recorded_at desc,e.id desc limit 1)) order by a.created_at desc,a.id desc)
 from (select * from public.student_applications where user_id=p_user order by created_at desc,id desc limit 25 offset p_offset) a),'[]'::jsonb))
$$;
create function public.my_applications(p_offset integer default 0) returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 if p_offset is null or p_offset<0 or p_offset>10000 then raise check_violation;end if;
 return student_private.applications(auth.uid(),p_offset);
end$$;
create function public.my_application_events(p_id uuid,p_offset integer default 0) returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 if p_offset is null or p_offset<0 or p_offset>10000 then raise check_violation;end if;
 if not exists(select 1 from public.student_applications where id=p_id and user_id=auth.uid()) then raise insufficient_privilege;end if;
 return jsonb_build_object('version','application-events-v1','offset',p_offset,'limit',100,
 'has_more',exists(select 1 from public.student_application_events where application_id=p_id order by recorded_at desc,id desc offset p_offset+100 limit 1),
 'items',coalesce((select jsonb_agg(to_jsonb(e)-'user_id'-'request_key' order by e.recorded_at desc,e.id desc)
 from (select * from public.student_application_events where application_id=p_id order by recorded_at desc,id desc limit 100 offset p_offset) e),'[]'::jsonb));
end$$;

revoke all on function student_private.applications(uuid,integer) from public,anon,authenticated;
revoke all on function public.my_application_save(uuid,integer,integer,uuid,text,text,text,uuid),public.my_application_event(uuid,text,timestamptz,uuid,uuid),public.my_application_delete(uuid),public.my_applications(integer),public.my_application_events(uuid,integer) from public,anon,authenticated;
grant execute on function public.my_application_save(uuid,integer,integer,uuid,text,text,text,uuid),public.my_application_event(uuid,text,timestamptz,uuid,uuid),public.my_application_delete(uuid),public.my_applications(integer),public.my_application_events(uuid,integer) to authenticated;
commit;
-- Rollback: revoke the five public RPC grants to disable new writes/reads; preserve facts.
-- Do not DROP these tables after real data has been entered. No existing runtime is replaced.
