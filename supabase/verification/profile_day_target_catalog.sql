select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
  and column_name in ('target_date', 'target_label')
order by column_name;

select conname, convalidated, pg_get_constraintdef(oid) as definition
from pg_constraint where conrelid = 'public.profiles'::regclass
  and conname = 'profiles_target_pair';

select r.role_name, c.column_name,
  has_column_privilege(r.role_name, 'public.profiles', c.column_name, 'SELECT') as can_select,
  has_column_privilege(r.role_name, 'public.profiles', c.column_name, 'INSERT') as can_insert,
  has_column_privilege(r.role_name, 'public.profiles', c.column_name, 'UPDATE') as can_update
from (values ('anon'), ('authenticated'), ('service_role')) r(role_name)
cross join (values ('target_date'), ('target_label')) c(column_name);

select relrowsecurity, relforcerowsecurity
from pg_class where oid = 'public.profiles'::regclass;

select policyname, roles, cmd, qual, with_check
from pg_policies where schemaname = 'public' and tablename = 'profiles'
order by policyname;

select count(*) as profile_rows,
       md5(coalesce(string_agg(
         (to_jsonb(p) - 'target_date' - 'target_label')::text,
         ',' order by p.id), '')) as existing_profile_digest,
       count(*) filter (where target_date is not null or target_label is not null) as populated_targets,
       count(*) filter (where (target_date is null) <> (target_label is null)) as invalid_pairs
from public.profiles p;
