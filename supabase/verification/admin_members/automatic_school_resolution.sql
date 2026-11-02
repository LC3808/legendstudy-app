-- Additive admin-only metadata for the existing verified NEIS resolver. No profile/cache DML.
begin;
do $$begin
 if md5(pg_get_functiondef('public.admin_member_list(text,integer,integer,text,text,text,integer,text,text,boolean)'::regprocedure)) <> '09007b04d6f83adb661c3ff1bfe8fe67' then raise exception 'MEMBER_LIST_DRIFT'; end if;
end$$;
CREATE OR REPLACE FUNCTION public.admin_member_list(p_query text DEFAULT ''::text, p_limit integer DEFAULT 25, p_offset integer DEFAULT 0, p_sort text DEFAULT 'newest'::text, p_account_state text DEFAULT NULL::text, p_academic_status text DEFAULT NULL::text, p_grade integer DEFAULT NULL::integer, p_office text DEFAULT NULL::text, p_school text DEFAULT NULL::text, p_school_unset boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare q text; qid uuid; result jsonb;
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then
  raise sqlstate '42501' using message='OPERATOR_REQUIRED';
 end if;
 q:=btrim(coalesce(p_query,''));
 if length(q)>254 or p_limit is null or p_limit not between 1 and 50
  or p_offset is null or p_offset<0
  or p_sort is null or p_sort not in ('newest','oldest')
  or (p_account_state is not null and p_account_state not in ('NORMAL','DELETION_PENDING','ERASING','ERASED','CANCELLED'))
  or (p_academic_status is not null and p_academic_status not in ('student','retaker','other','unset'))
  or (p_grade is not null and p_grade not between 1 and 3)
  or ((p_office is null) <> (p_school is null))
  or (p_office is not null and (length(btrim(p_office)) not between 1 and 32 or length(btrim(p_school)) not between 1 and 32))
  or p_school_unset is null or (p_school_unset and p_school is not null)
 then raise sqlstate '22023' using message='INVALID_FILTER'; end if;
 if q ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then qid:=q::uuid; end if;
 with latest_state as (
  select distinct on(subject_id) subject_id,state from public.account_deletion_requests
  where subject_id is not null order by subject_id,requested_at desc,id desc
 ), members as materialized (
  select u.id account_id,u.email::text email,u.created_at,p.display_name,p.academic_status,
   p.grade_level,p.intended_major,p.neis_office_code office_code,p.neis_school_code school_code,
   case when d.state in ('ERASED','ERASING','DELETION_PENDING','CANCELLED') then d.state else 'NORMAL' end account_state
  from auth.users u left join public.profiles p on p.id=u.id
  left join latest_state d on d.subject_id=u.id
 ), filtered as materialized (
  select m.* from members m where
   (q='' or (qid is not null and m.account_id=qid) or (qid is null and
    (strpos(lower(coalesce(m.email,'')),lower(q))>0 or strpos(lower(coalesce(m.display_name,'')),lower(q))>0)))
   and (p_account_state is null or m.account_state=p_account_state)
   and (p_academic_status is null or m.academic_status=p_academic_status or (p_academic_status='unset' and m.academic_status is null))
   and (p_grade is null or m.grade_level=p_grade)
   and (not p_school_unset or m.school_code is null)
   and (p_school is null or (m.school_code=p_school and m.office_code=p_office))
 ), page as (
  select * from filtered order by
   case when p_sort='newest' then created_at end desc,
   case when p_sort='oldest' then created_at end asc,account_id
  limit p_limit offset p_offset
 )
 select jsonb_build_object(
  'version','admin-members-v1','as_of',statement_timestamp(),
  'total',(select count(*) from members),'filtered_total',(select count(*) from filtered),
  'limit',p_limit,'offset',p_offset,
  'items',coalesce((select jsonb_agg(jsonb_build_object(
   'account_id',m.account_id,'email',m.email,'display_name',m.display_name,'created_at',m.created_at,
   'account_state',m.account_state,'academic_status',m.academic_status,'grade_level',m.grade_level,
   'intended_major',m.intended_major,'school_name',c.school_name,
   'school_office_code',m.office_code,'school_code',m.school_code,
   'school_state',case when m.school_code is null then 'unset' when c.school_name is null then 'unresolved' else 'resolved' end
  ) order by case when p_sort='newest' then m.created_at end desc,case when p_sort='oldest' then m.created_at end asc,m.account_id)
  from page m left join student_private.school_display_cache c on c.office_code=m.office_code and c.school_code=m.school_code),'[]'::jsonb)
 ) into result;
 return result;
end $function$
;
notify pgrst, 'reload schema';
commit;
