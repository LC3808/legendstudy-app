-- Owner approval required. Additive schema/RPC installation only; no backfill/seed.
-- Existing applications/events, manual D-Days, Essay, finance and ledgers are untouched.
begin;
do $$begin
 if md5(pg_get_functiondef('public.my_application_save(uuid,integer,integer,uuid,text,text,text,uuid)'::regprocedure))<>'65edac758433cde4a123b95be3da42ee' then
  raise exception 'APPLICATION_SAVE_PREIMAGE_CHANGED';
 end if;
end$$;
create schema admissions_private;
revoke all on schema admissions_private from public,anon,authenticated,service_role;

create table public.admission_schedule_events (
 id uuid primary key default gen_random_uuid(),
 university_id uuid not null references public.universities(id) on delete restrict,
 academic_year smallint not null check(academic_year between 1900 and 2200),
 campus text not null check(char_length(btrim(campus)) between 1 and 120),
 title text not null check(char_length(btrim(title)) between 1 and 15),
 event_type text not null check(event_type in ('ESSAY','INTERVIEW','PRACTICAL','STAGE_RESULT','INITIAL_RESULT','REGISTRATION_DEADLINE','OTHER')),
 event_date date check(isfinite(event_date)), event_time time,
 admission_names text[] not null, division_names text[] not null,
 source_url text, source_sha256 text, source_page integer check(source_page>0), source_note text not null default '',
 verification_status text not null check(verification_status in ('PENDING','VERIFIED','CANCELLED')),
 is_published boolean not null default false,
 revision integer not null default 1 check(revision>0),
 created_at timestamptz not null default clock_timestamp(), updated_at timestamptz not null default clock_timestamp(),
 check(cardinality(admission_names) between 1 and 100 and cardinality(division_names) between 1 and 500),
 check(source_sha256 is null or source_sha256 ~ '^[0-9a-f]{64}$'),
 check(not is_published or verification_status='VERIFIED'),
 check(verification_status<>'VERIFIED' or (event_date is not null and source_url is not null and source_url ~ '^https?://[^/[:space:]]+(/[^[:space:]]*)?$' and char_length(btrim(source_note)) between 5 and 4000))
);
create index admission_schedules_match on public.admission_schedule_events(university_id,academic_year);
create table public.admission_schedule_revisions (
 event_id uuid not null references public.admission_schedule_events(id) on delete restrict,
 revision integer not null, snapshot jsonb not null,
 actor_id uuid references auth.users(id) on delete set null,
 request_key uuid not null, command jsonb not null,
 recorded_at timestamptz not null default clock_timestamp(),
 primary key(event_id,revision), unique(actor_id,request_key)
);
create table public.application_schedule_links (
 owner_id uuid not null,
 application_id uuid not null,
 official_event_id uuid not null references public.admission_schedule_events(id) on delete restrict,
 application_revision integer not null, schedule_revision integer not null,
 sync_status text not null check(sync_status in ('MATCHED','PENDING')),
 match_basis jsonb not null,
 updated_at timestamptz not null default clock_timestamp(),
 primary key(application_id,official_event_id),
 foreign key(application_id,owner_id) references public.student_applications(id,user_id) on delete cascade
);
create index application_schedule_owner_event on public.application_schedule_links(owner_id,official_event_id);
create index application_schedule_event_owner on public.application_schedule_links(official_event_id,owner_id);
create table public.student_schedule_preferences (
 owner_id uuid not null references public.profiles(id) on delete cascade,
 official_event_id uuid not null references public.admission_schedule_events(id) on delete restrict,
 day_target_id uuid unique references public.day_targets(id) on delete set null,
 status text not null check(status in ('ACTIVE','DISMISSED','CANCELLED')),
 revision integer not null default 1,
 schedule_revision integer not null,
 ever_activated boolean not null default false,
 updated_at timestamptz not null default clock_timestamp(),
 primary key(owner_id,official_event_id)
);
create index student_schedule_event_owner on public.student_schedule_preferences(official_event_id,owner_id);
create table public.student_schedule_actions (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.profiles(id) on delete cascade,
 official_event_id uuid not null references public.admission_schedule_events(id) on delete restrict,
 action text not null, request_key uuid, command jsonb,
 before_state jsonb, after_state jsonb, result jsonb,
 recorded_at timestamptz not null default clock_timestamp(),
 unique(owner_id,request_key)
);
create index student_schedule_actions_history on public.student_schedule_actions(owner_id,official_event_id,recorded_at);
create index student_schedule_actions_event on public.student_schedule_actions(official_event_id);

create function admissions_private.history_guard() returns trigger
language plpgsql set search_path='' as $$
begin
 if tg_table_name='admission_schedule_revisions' and tg_op='UPDATE' then
  -- Account erasure may anonymize the source reviewer, never alter evidence.
  if new.actor_id is null and (to_jsonb(new)-'actor_id')=(to_jsonb(old)-'actor_id') then return new;end if;
 elsif tg_table_name='student_schedule_actions' and tg_op='DELETE' then
  if not exists(select 1 from public.profiles where id=old.owner_id) then return old;end if;
 end if;
 raise exception 'ADMISSION_HISTORY_IMMUTABLE';
end$$;
create trigger admission_revision_history before update or delete on public.admission_schedule_revisions for each row execute function admissions_private.history_guard();
create trigger admission_action_history before update or delete on public.student_schedule_actions for each row execute function admissions_private.history_guard();

alter table public.admission_schedule_events enable row level security;
alter table public.admission_schedule_revisions enable row level security;
alter table public.application_schedule_links enable row level security;
alter table public.student_schedule_preferences enable row level security;
alter table public.student_schedule_actions enable row level security;
revoke all on public.admission_schedule_events,public.admission_schedule_revisions,public.application_schedule_links,public.student_schedule_preferences,public.student_schedule_actions from public,anon,authenticated,service_role;
grant select on public.student_schedule_preferences to authenticated;
-- Existing client writes remain on day_targets. This read also supports its invoker guard.
create policy student_schedule_owner_read on public.student_schedule_preferences for select to authenticated
 using(owner_id=(select auth.uid()) and public.account_service_allowed());

create function admissions_private.normalized(p_text text) returns text
language sql immutable set search_path='' as $$select lower(regexp_replace(btrim(p_text),'[[:space:]]+','','g'))$$;

create function admissions_private.require_owner() returns uuid
language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid();begin
 if u is null then raise insufficient_privilege using message='AUTH_REQUIRED';end if;
 perform account_private.lock_subject(u);
 if not account_private.allowed(u) then raise insufficient_privilege using message='ACCOUNT_RESTRICTED';end if;
 return u;
end$$;

create function admissions_private.require_admin() returns void
language plpgsql security definer set search_path='' as $$
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then
  raise insufficient_privilege using message='ADMIN_REQUIRED';
 end if;
end$$;

create function admissions_private.event_metadata(p_owner uuid,p_event uuid) returns jsonb
language sql stable security definer set search_path='' as $$
 select jsonb_build_object('official_event_id',e.id,'day_target_id',p.day_target_id,
 'title',e.title,'university_name',u.name,'academic_year',e.academic_year,'campus',e.campus,
 'event_type',e.event_type,'event_date',e.event_date,'event_time',e.event_time,
 'status',p.status,'source_url',e.source_url,'source_note',e.source_note,
 'revision',p.revision,'updated_at',p.updated_at,
 'can_restore',p.status='DISMISSED' and e.verification_status='VERIFIED' and e.is_published and exists(
  select 1 from public.application_schedule_links l where l.owner_id=p.owner_id and l.official_event_id=e.id and l.sync_status='MATCHED'),
 'unavailable_reason',case
  when not exists(select 1 from public.application_schedule_links l where l.owner_id=p.owner_id and l.official_event_id=e.id) then 'APPLICATION_NOT_MATCHED'
  when e.verification_status<>'VERIFIED' then 'SOURCE_'||e.verification_status
  when not e.is_published then 'NOT_PUBLISHED'
  when p.status='CANCELLED' and not p.ever_activated and e.event_date<(clock_timestamp() at time zone 'Asia/Seoul')::date then 'PAST_EVENT'
  else null end)
 from public.student_schedule_preferences p join public.admission_schedule_events e on e.id=p.official_event_id
 join public.universities u on u.id=e.university_id
 where p.owner_id=p_owner and e.id=p_event
$$;

-- One shared account lock serializes all projection actions. No client-controlled bypass flag.
create function admissions_private.sync_owner(p_owner uuid) returns void
language plpgsql security definer set search_path='' as $$
declare e public.admission_schedule_events; p public.student_schedule_preferences; before_row jsonb;
 target uuid; eligible boolean; has_match boolean; today date=(clock_timestamp() at time zone 'Asia/Seoul')::date;
begin
 perform account_private.lock_subject(p_owner);
 if not account_private.allowed(p_owner) or not exists(select 1 from public.profiles where id=p_owner) then return;end if;
 -- Recompute only derived links; never rewrite application headers or their event history.
 delete from public.application_schedule_links l where l.owner_id=p_owner and not exists(
  select 1 from public.student_applications a join public.admission_schedule_events s
   on s.university_id=a.university_id and s.academic_year=a.admission_year
  where a.id=l.application_id and s.id=l.official_event_id and a.admission_type='수시'
   and exists(select 1 from unnest(s.admission_names) n where admissions_private.normalized(n)=admissions_private.normalized(a.admission_name))
   and exists(select 1 from unnest(s.division_names) n where admissions_private.normalized(n)=admissions_private.normalized(a.intended_division)));
 insert into public.application_schedule_links(owner_id,application_id,official_event_id,application_revision,schedule_revision,sync_status,match_basis)
 select a.user_id,a.id,s.id,a.revision,s.revision,
  case when s.verification_status='VERIFIED' and s.is_published then 'MATCHED' else 'PENDING' end,
  jsonb_build_object('version',1,'university_id',a.university_id,'academic_year',a.admission_year,'admission_name',a.admission_name,'intended_division',a.intended_division,'campus',s.campus)
 from public.student_applications a join public.admission_schedule_events s
  on s.university_id=a.university_id and s.academic_year=a.admission_year
 where a.user_id=p_owner and a.admission_type='수시'
  and exists(select 1 from unnest(s.admission_names) n where admissions_private.normalized(n)=admissions_private.normalized(a.admission_name))
  and exists(select 1 from unnest(s.division_names) n where admissions_private.normalized(n)=admissions_private.normalized(a.intended_division))
 on conflict(application_id,official_event_id) do update set
  application_revision=excluded.application_revision,schedule_revision=excluded.schedule_revision,
  sync_status=excluded.sync_status,match_basis=excluded.match_basis,updated_at=clock_timestamp()
 where (application_schedule_links.application_revision,application_schedule_links.schedule_revision,application_schedule_links.sync_status,application_schedule_links.match_basis)
  is distinct from (excluded.application_revision,excluded.schedule_revision,excluded.sync_status,excluded.match_basis);

 for e in select s.* from public.admission_schedule_events s where exists(
  select 1 from public.application_schedule_links l where l.owner_id=p_owner and l.official_event_id=s.id)
  or exists(select 1 from public.student_schedule_preferences x where x.owner_id=p_owner and x.official_event_id=s.id) order by s.id loop
  select exists(select 1 from public.application_schedule_links l where l.owner_id=p_owner and l.official_event_id=e.id and l.sync_status='MATCHED') into has_match;
  insert into public.student_schedule_preferences(owner_id,official_event_id,status,schedule_revision)
   values(p_owner,e.id,'CANCELLED',e.revision) on conflict do nothing;
  select * into p from public.student_schedule_preferences where owner_id=p_owner and official_event_id=e.id for update;
  before_row=to_jsonb(p);
  eligible=has_match and e.verification_status='VERIFIED' and e.is_published and e.event_date is not null
   and (e.event_date>=today or p.ever_activated);
  if p.status='DISMISSED' then
   -- Dismissal survives date/source changes and removing/re-adding applications.
   update public.student_schedule_preferences set schedule_revision=e.revision,revision=revision+1,updated_at=clock_timestamp()
    where owner_id=p_owner and official_event_id=e.id and schedule_revision<>e.revision;
  elsif eligible then
   if p.day_target_id is null then
    insert into public.day_targets(owner_id,title,event_date) values(p_owner,e.title,e.event_date) returning id into target;
    update public.student_schedule_preferences set day_target_id=target,status='ACTIVE',ever_activated=true,
     schedule_revision=e.revision,revision=revision+1,updated_at=clock_timestamp() where owner_id=p_owner and official_event_id=e.id;
   else
    update public.day_targets set title=e.title,event_date=e.event_date,updated_at=clock_timestamp()
     where id=p.day_target_id and owner_id=p_owner and (title,event_date) is distinct from (e.title,e.event_date);
    update public.student_schedule_preferences set status='ACTIVE',ever_activated=true,schedule_revision=e.revision,revision=revision+1,updated_at=clock_timestamp()
     where owner_id=p_owner and official_event_id=e.id and (status<>'ACTIVE' or schedule_revision<>e.revision);
   end if;
  else
   -- Unlink first so the old-client DELETE trigger does not record an internal removal as a user dismissal.
   update public.student_schedule_preferences set day_target_id=null,status='CANCELLED',schedule_revision=e.revision,revision=revision+1,updated_at=clock_timestamp()
    where owner_id=p_owner and official_event_id=e.id and (day_target_id is not null or status<>'CANCELLED' or schedule_revision<>e.revision);
   if p.day_target_id is not null then delete from public.day_targets where id=p.day_target_id and owner_id=p_owner;end if;
  end if;
  select * into p from public.student_schedule_preferences where owner_id=p_owner and official_event_id=e.id;
  if before_row is distinct from to_jsonb(p) then
   insert into public.student_schedule_actions(owner_id,official_event_id,action,before_state,after_state)
    values(p_owner,e.id,'SYNC',before_row,to_jsonb(p));
  end if;
 end loop;
end$$;

create function admissions_private.application_changed() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 perform admissions_private.sync_owner(case when tg_op='DELETE' then old.user_id else new.user_id end);
 return null;
end$$;
create trigger admissions_schedule_sync after insert or update or delete on public.student_applications
 for each row execute function admissions_private.application_changed();

create function admissions_private.day_target_deleted() returns trigger
language plpgsql security definer set search_path='' as $$
declare p public.student_schedule_preferences; before_row jsonb;
begin
 perform account_private.lock_subject(old.owner_id);
 select * into p from public.student_schedule_preferences where owner_id=old.owner_id and day_target_id=old.id for update;
 if found and exists(select 1 from public.profiles where id=old.owner_id) then
  before_row=to_jsonb(p);
  update public.student_schedule_preferences set status='DISMISSED',day_target_id=null,revision=revision+1,updated_at=clock_timestamp()
   where owner_id=old.owner_id and official_event_id=p.official_event_id returning * into p;
  insert into public.student_schedule_actions(owner_id,official_event_id,action,before_state,after_state)
   values(old.owner_id,p.official_event_id,'DISMISS_LEGACY',before_row,to_jsonb(p));
 end if;
 return old;
end$$;
create trigger admissions_day_delete before delete on public.day_targets for each row execute function admissions_private.day_target_deleted();
-- Lock the caller BEFORE PostgreSQL locks a target row (same order as sync/RPC).
create trigger admissions_day_delete_statement before delete on public.day_targets for each statement execute function account_private.caller_write_gate();

-- INVOKER: current_user is authenticated for direct API writes, postgres only inside trusted RPCs.
create function admissions_private.day_target_update_guard() returns trigger
language plpgsql set search_path='' as $$
begin
 if current_user<>'postgres' and (new.id,new.owner_id,new.title,new.event_date) is distinct from (old.id,old.owner_id,old.title,old.event_date)
  and exists(select 1 from public.student_schedule_preferences where owner_id=old.owner_id and day_target_id=old.id) then
  raise insufficient_privilege using message='OFFICIAL_SCHEDULE_READ_ONLY';
 end if;
 return new;
end$$;
create trigger admissions_day_update before update on public.day_targets for each row execute function admissions_private.day_target_update_guard();

create function public.my_admission_day_events() returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid; result jsonb;
begin
 u=admissions_private.require_owner();perform admissions_private.sync_owner(u);
 select coalesce(jsonb_agg(admissions_private.event_metadata(u,official_event_id) order by official_event_id),'[]'::jsonb)
  into result from public.student_schedule_preferences where owner_id=u and ever_activated;
 return jsonb_build_object('events',result);
end$$;

create function public.my_admission_day_event_action(p_event_id uuid,p_action text,p_expected_revision integer,p_request_key uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid; p public.student_schedule_preferences; previous public.student_schedule_actions;
 cmd jsonb; result jsonb; before_row jsonb;
begin
 u=admissions_private.require_owner();
 if p_event_id is null or p_action is null or p_action not in ('dismiss','restore') or p_expected_revision is null or p_request_key is null then raise invalid_parameter_value;end if;
 cmd=jsonb_build_object('event',p_event_id,'action',p_action,'revision',p_expected_revision);
 select * into previous from public.student_schedule_actions where owner_id=u and request_key=p_request_key;
 if found then
  if previous.command is distinct from cmd then raise sqlstate 'PT409' using message='REQUEST_KEY_REUSED';end if;
  return previous.result;
 end if;
 perform admissions_private.sync_owner(u);
 select * into p from public.student_schedule_preferences where owner_id=u and official_event_id=p_event_id for update;
 if not found then raise insufficient_privilege using message='SCHEDULE_NOT_FOUND';end if;
 if not p.ever_activated then raise insufficient_privilege using message='SCHEDULE_NOT_FOUND';end if;
 if p.revision<>p_expected_revision then raise sqlstate 'PT409' using message='SCHEDULE_CHANGED';end if;
 before_row=to_jsonb(p);
 if p_action='dismiss' then
  update public.student_schedule_preferences set status='DISMISSED',day_target_id=null,revision=revision+1,updated_at=clock_timestamp()
   where owner_id=u and official_event_id=p_event_id;
  if p.day_target_id is not null then delete from public.day_targets where id=p.day_target_id and owner_id=u;end if;
 else
  if not coalesce((admissions_private.event_metadata(u,p_event_id)->>'can_restore')::boolean,false) then
   raise sqlstate 'PT409' using message='SCHEDULE_NOT_RESTORABLE';
  end if;
  update public.student_schedule_preferences set status='CANCELLED',ever_activated=true,revision=revision+1,updated_at=clock_timestamp()
   where owner_id=u and official_event_id=p_event_id;
  perform admissions_private.sync_owner(u);
 end if;
 result=admissions_private.event_metadata(u,p_event_id);
 insert into public.student_schedule_actions(owner_id,official_event_id,action,request_key,command,before_state,after_state,result)
  select u,p_event_id,upper(p_action),p_request_key,cmd,before_row,to_jsonb(x),result from public.student_schedule_preferences x where owner_id=u and official_event_id=p_event_id;
 return result;
end$$;

create function public.my_set_primary_day_target(p_id uuid) returns void
language plpgsql security definer set search_path='' as $$
declare u uuid;begin
 u=admissions_private.require_owner();
 if not exists(select 1 from public.day_targets where id=p_id and owner_id=u) then raise insufficient_privilege;end if;
 update public.day_targets set is_primary=false where owner_id=u and is_primary and id<>p_id;
 update public.day_targets set is_primary=true where owner_id=u and id=p_id and not is_primary;
end$$;

create function public.admin_admission_schedules() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 perform admissions_private.require_admin();
 return jsonb_build_object('schedules',(select coalesce(jsonb_agg(to_jsonb(e)||jsonb_build_object('university_name',u.name) order by e.academic_year desc,e.event_date,e.id),'[]'::jsonb)
  from public.admission_schedule_events e join public.universities u on u.id=e.university_id),
  'universities',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name) order by name),'[]'::jsonb) from public.universities where is_active));
end$$;

create function public.admin_admission_schedule_save(p_id uuid,p_expected_revision integer,p_request_key uuid,p_schedule jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare e public.admission_schedule_events; old_event public.admission_schedule_events;
 prior public.admission_schedule_revisions; cmd jsonb; result jsonb; u uuid; v text; names text[]; divisions text[];
begin
 perform admissions_private.require_admin();
 if p_request_key is null or p_expected_revision is null or jsonb_typeof(p_schedule) is distinct from 'object' then raise invalid_parameter_value;end if;
 -- Serialize publishers first, then caller lifecycle, then target accounts. Student sync never locks catalog rows.
 perform pg_advisory_xact_lock(6192743107261120);
 perform account_private.lock_subject(auth.uid());
 if not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 cmd=jsonb_build_object('id',p_id,'revision',p_expected_revision,'schedule',p_schedule);
 select * into prior from public.admission_schedule_revisions where actor_id=auth.uid() and request_key=p_request_key;
 if found then
  if prior.command is distinct from cmd then raise sqlstate 'PT409' using message='REQUEST_KEY_REUSED';end if;
  return prior.snapshot;
 end if;
 if p_id is null then
  if p_expected_revision<>0 then raise sqlstate 'PT409' using message='SCHEDULE_CHANGED';end if;
 else
  -- Publisher advisory lock already serializes edits. FOR UPDATE here would conflict
  -- with sync's FK key-share lock while we wait for its owner lock (deadlock).
  select * into old_event from public.admission_schedule_events where id=p_id;
  if not found then raise sqlstate 'PT404' using message='SCHEDULE_NOT_FOUND';end if;
  if old_event.revision<>p_expected_revision then raise sqlstate 'PT409' using message='SCHEDULE_CHANGED';end if;
 end if;
 if jsonb_typeof(p_schedule->'admission_names') is distinct from 'array' or jsonb_typeof(p_schedule->'division_names') is distinct from 'array' then
  raise invalid_parameter_value using message='EXACT_SCOPE_REQUIRED';
 end if;
 if exists(select 1 from jsonb_array_elements(p_schedule->'admission_names') x where jsonb_typeof(x)<>'string')
  or exists(select 1 from jsonb_array_elements(p_schedule->'division_names') x where jsonb_typeof(x)<>'string') then raise invalid_parameter_value;end if;
 select array_agg(distinct btrim(x)) into names from jsonb_array_elements_text(p_schedule->'admission_names') x;
 select array_agg(distinct btrim(x)) into divisions from jsonb_array_elements_text(p_schedule->'division_names') x;
 foreach v in array coalesce(names,'{}'::text[])||coalesce(divisions,'{}'::text[]) loop
  if char_length(v) not between 1 and 120 or v in ('*','전체','ALL') then raise invalid_parameter_value using message='EXACT_SCOPE_REQUIRED';end if;
 end loop;
 e.id=coalesce(p_id,gen_random_uuid());e.university_id=(p_schedule->>'university_id')::uuid;e.academic_year=(p_schedule->>'academic_year')::smallint;
 e.campus=btrim(p_schedule->>'campus');e.title=btrim(p_schedule->>'title');e.event_type=p_schedule->>'event_type';
 e.event_date=nullif(p_schedule->>'event_date','')::date;e.event_time=nullif(p_schedule->>'event_time','')::time;
 e.admission_names=names;e.division_names=divisions;e.source_url=nullif(btrim(p_schedule->>'source_url'),'');
 e.source_sha256=nullif(lower(btrim(p_schedule->>'source_sha256')),'');e.source_page=nullif(p_schedule->>'source_page','')::integer;
 e.source_note=coalesce(btrim(p_schedule->>'source_note'),'');e.verification_status=p_schedule->>'verification_status';
 e.is_published=coalesce((p_schedule->>'is_published')::boolean,false);e.revision=p_expected_revision+1;
 if p_id is not null and (old_event.university_id,old_event.academic_year,old_event.campus,old_event.event_type)
  is distinct from (e.university_id,e.academic_year,e.campus,e.event_type) then raise sqlstate 'PT409' using message='EVENT_IDENTITY_IMMUTABLE';end if;
 if not exists(select 1 from public.universities where id=e.university_id and is_active) then raise invalid_parameter_value using message='UNIVERSITY_NOT_FOUND';end if;
 if e.verification_status='VERIFIED' and (e.event_date is null or e.source_url is null or char_length(e.source_note)<5) then
  raise invalid_parameter_value using message='OFFICIAL_SOURCE_REQUIRED';end if;
 if e.is_published and exists(select 1 from public.admission_schedule_events s
  where s.id<>e.id and s.university_id=e.university_id and s.academic_year=e.academic_year
   and (s.is_published or exists(select 1 from public.student_schedule_preferences p where p.official_event_id=s.id and p.ever_activated))
   and s.campus<>e.campus
   and exists(select 1 from unnest(s.admission_names) a cross join unnest(e.admission_names) b where admissions_private.normalized(a)=admissions_private.normalized(b))
   and exists(select 1 from unnest(s.division_names) a cross join unnest(e.division_names) b where admissions_private.normalized(a)=admissions_private.normalized(b))) then
  raise sqlstate 'PT409' using message='AMBIGUOUS_CAMPUS_SCOPE';
 end if;
 -- Never bypass a dismissal by unpublishing A and publishing equivalent event B.
 -- Reuse the original identity even if it is now cancelled or a draft.
 if e.is_published and exists(select 1 from public.admission_schedule_events s
  where s.id<>e.id and s.university_id=e.university_id and s.academic_year=e.academic_year
   and s.campus=e.campus and s.event_type=e.event_type and (e.event_type<>'OTHER' or s.title=e.title)
   and exists(select 1 from unnest(s.admission_names) a cross join unnest(e.admission_names) b where admissions_private.normalized(a)=admissions_private.normalized(b))
   and exists(select 1 from unnest(s.division_names) a cross join unnest(e.division_names) b where admissions_private.normalized(a)=admissions_private.normalized(b))) then
  raise sqlstate 'PT409' using message='DUPLICATE_EVENT_SCOPE_USE_EXISTING';
 end if;
 if p_id is null then
  insert into public.admission_schedule_events(id,university_id,academic_year,campus,title,event_type,event_date,event_time,admission_names,division_names,source_url,source_sha256,source_page,source_note,verification_status,is_published)
  values(e.id,e.university_id,e.academic_year,e.campus,e.title,e.event_type,e.event_date,e.event_time,e.admission_names,e.division_names,e.source_url,e.source_sha256,e.source_page,e.source_note,e.verification_status,e.is_published) returning * into e;
 else
  update public.admission_schedule_events set title=e.title,event_date=e.event_date,event_time=e.event_time,
   admission_names=e.admission_names,division_names=e.division_names,source_url=e.source_url,source_sha256=e.source_sha256,
   source_page=e.source_page,source_note=e.source_note,verification_status=e.verification_status,is_published=e.is_published,revision=e.revision,updated_at=clock_timestamp()
   where id=p_id returning * into e;
 end if;
 result=to_jsonb(e)||jsonb_build_object('university_name',(select name from public.universities where id=e.university_id));
 insert into public.admission_schedule_revisions(event_id,revision,snapshot,actor_id,request_key,command)
  values(e.id,e.revision,result,auth.uid(),p_request_key,cmd);
 -- Catalog publication is atomic with small owner-specific projections; no external queue required.
 for u in select user_id from public.student_applications where university_id=e.university_id and admission_year=e.academic_year
  union select owner_id from public.student_schedule_preferences where official_event_id=e.id order by 1 loop
  perform admissions_private.sync_owner(u);
 end loop;
 return result;
end$$;

CREATE OR REPLACE FUNCTION public.my_application_save(p_id uuid, p_revision integer, p_year integer, p_university uuid, p_division text, p_admission_type text, p_admission_name text, p_request_key uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=auth.uid(); a public.student_applications; old_event public.student_application_events; cmd jsonb; previous jsonb; university_name text;
begin
 -- Fence catalog publication before taking the existing owner lock.
 perform pg_advisory_xact_lock_shared(6192743107261120);
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
  -- Semantic duplicate prevention inside the existing per-user lock.
  -- Different year/university/department/season/track remains a distinct application.
  if exists(select 1 from public.student_applications d where d.user_id=u
   and d.id is distinct from p_id and d.admission_year=p_year and d.university_id=p_university
   and btrim(d.intended_division)=btrim(p_division)
   and btrim(d.admission_type)=btrim(p_admission_type)
   and btrim(d.admission_name)=btrim(p_admission_name)) then
   raise unique_violation using message='APPLICATION_ALREADY_EXISTS';
  end if;
  insert into public.student_applications(user_id,admission_year,university_id,university_name_snapshot,intended_division,admission_type,admission_name)
   values(u,p_year,p_university,university_name,btrim(p_division),btrim(p_admission_type),btrim(p_admission_name)) returning * into a;
 else
  select * into a from public.student_applications where id=p_id and user_id=u for update;
  if not found then raise insufficient_privilege;end if;
  if a.revision<>p_revision then raise exception 'APPLICATION_CHANGED' using errcode='40001';end if;
  -- Semantic duplicate prevention inside the existing per-user lock.
  -- Different year/university/department/season/track remains a distinct application.
  if exists(select 1 from public.student_applications d where d.user_id=u
   and d.id is distinct from p_id and d.admission_year=p_year and d.university_id=p_university
   and btrim(d.intended_division)=btrim(p_division)
   and btrim(d.admission_type)=btrim(p_admission_type)
   and btrim(d.admission_name)=btrim(p_admission_name)) then
   raise unique_violation using message='APPLICATION_ALREADY_EXISTS';
  end if;
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

revoke all on all functions in schema admissions_private from public,anon,authenticated,service_role;
revoke all on function public.my_admission_day_events(),public.my_admission_day_event_action(uuid,text,integer,uuid),public.my_set_primary_day_target(uuid),public.admin_admission_schedules(),public.admin_admission_schedule_save(uuid,integer,uuid,jsonb) from public,anon,service_role;
grant execute on function public.my_admission_day_events(),public.my_admission_day_event_action(uuid,text,integer,uuid),public.my_set_primary_day_target(uuid),public.admin_admission_schedules(),public.admin_admission_schedule_save(uuid,integer,uuid,jsonb) to authenticated;
notify pgrst,'reload schema';
commit;
