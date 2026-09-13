-- Run on LegendStudy stlhijzpjfgwwdgunlsd only. Keep results locally.
select current_database(), current_setting('server_version') as server_version;

select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
order by ordinal_position;

select conname, convalidated, pg_get_constraintdef(oid) as definition
from pg_constraint where conrelid = 'public.profiles'::regclass
order by conname;

select relrowsecurity, relforcerowsecurity
from pg_class where oid = 'public.profiles'::regclass;

select policyname, roles, cmd, qual, with_check
from pg_policies where schemaname = 'public' and tablename = 'profiles'
order by policyname;

select grantee, column_name, privilege_type
from information_schema.column_privileges
where table_schema = 'public' and table_name = 'profiles'
  and grantee in ('anon', 'authenticated', 'service_role')
order by grantee, column_name, privilege_type;

select count(*) as profile_rows,
       md5(coalesce(string_agg(
         (to_jsonb(p) - 'target_date' - 'target_label')::text,
         ',' order by p.id), '')) as existing_profile_digest
from public.profiles p;
