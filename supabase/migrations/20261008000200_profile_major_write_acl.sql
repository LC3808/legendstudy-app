-- MY/APP intended-major persistence: column-only UPDATE, existing owner RLS intact.
begin;
do $preflight$
declare policy record;
begin
 if not exists(select 1 from pg_class where oid=to_regclass('public.profiles') and relrowsecurity) then
  raise exception 'PROFILE_RLS_REQUIRED';
 end if;
 select * into policy from pg_policy where polrelid='public.profiles'::regclass and polname='profiles_owner_update';
 if not found or policy.polcmd <> 'w' or not policy.polpermissive
 or policy.polroles <> array['authenticated'::regrole::oid]
 or regexp_replace(pg_get_expr(policy.polqual,policy.polrelid),'\s','','g') <> '((SELECTauth.uid()ASuid)=id)'
 or regexp_replace(pg_get_expr(policy.polwithcheck,policy.polrelid),'\s','','g') <> '((SELECTauth.uid()ASuid)=id)' then
  raise exception 'PROFILE_OWNER_POLICY_MISMATCH';
 end if;
 if exists(select 1 from pg_policy where polrelid='public.profiles'::regclass and polname <> 'profiles_owner_update'
  and polpermissive and polcmd in ('w','*') and (0=any(polroles) or 'authenticated'::regrole::oid=any(polroles))) then
  raise exception 'PROFILE_WRITE_POLICY_REVIEW_REQUIRED';
 end if;
end $preflight$;
grant update(intended_major) on public.profiles to authenticated;
commit;
