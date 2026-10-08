-- Add a bounded school-identity aggregate; retain the existing admin-v1 fields.
-- No school master, profile write, external request, new permission or role.
begin;
do $migration$
declare before_fn record; after_fn record; patched text;
 anchor constant text := $anchor$   'school_code_note','school names are not stored; distribution is by NEIS school code only'$anchor$;
 addition constant text := $addition$   'school_distribution_by_identity',coalesce((select jsonb_agg(jsonb_build_object('school_code',s.code,'school_office_code',s.office,'count',s.c) order by s.c desc,s.office,s.code) from (
     select p.neis_office_code office,p.neis_school_code code,count(*) c
     from public.profiles p where p.neis_school_code is not null
     group by p.neis_office_code,p.neis_school_code order by c desc,office,code limit 20) s),'[]'::jsonb),
   'school_unset_count',(select count(*) from public.profiles where neis_school_code is null),
$addition$;
begin
 select * into before_fn from pg_proc where oid=to_regprocedure('public.admin_dashboard()');
 if not found then raise exception 'ADMIN_DASHBOARD_MISSING'; end if;
 if md5(before_fn.prosrc)<>'a5381ff0409fdfff34578e20735a2d83'
 or not before_fn.prosecdef or before_fn.provolatile<>'s'
 or before_fn.proconfig is distinct from array['search_path=""'] then
  raise exception 'ADMIN_DASHBOARD_AUTHORITY_CHANGED';
 end if;
 if strpos(before_fn.prosrc,anchor)=0 then raise exception 'SCHOOL_ANCHOR_MISSING';end if;
 patched := replace(before_fn.prosrc,anchor,addition||anchor);
 execute format('create or replace function public.admin_dashboard() returns jsonb language plpgsql stable security definer set search_path='''' as %L',patched);
 select * into after_fn from pg_proc where oid=before_fn.oid;
 if not found then raise exception 'ADMIN_FUNCTION_IDENTITY_CHANGED';end if;
 if after_fn.proowner is distinct from before_fn.proowner or after_fn.proacl is distinct from before_fn.proacl
 or after_fn.proconfig is distinct from before_fn.proconfig or after_fn.prosrc is distinct from patched then
  raise exception 'ADMIN_FUNCTION_BOUNDARY_CHANGED';
 end if;
end $migration$;
notify pgrst, 'reload schema';
commit;
