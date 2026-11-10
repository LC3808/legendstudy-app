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
