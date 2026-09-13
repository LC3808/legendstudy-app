-- Owner: run AFTER migration. Read-only; not proof of JWT/RLS behavior.
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
  and column_name in ('neis_office_code', 'neis_school_code')
order by column_name;
-- Two rows: text / YES / NULL.

select conname, convalidated, pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = 'public.profiles'::regclass
  and conname = 'profiles_neis_school_pair';
-- One validated CHECK: pair NULL equivalence and value validation.

select role_name, column_name,
  has_column_privilege(role_name, 'public.profiles', column_name, 'SELECT') as can_read,
  has_column_privilege(role_name, 'public.profiles', column_name, 'INSERT') as can_insert,
  has_column_privilege(role_name, 'public.profiles', column_name, 'UPDATE') as can_update
from (values ('anon'), ('authenticated'), ('service_role')) as r(role_name)
cross join (values ('id'), ('display_name'), ('grade_level'),
  ('neis_office_code'), ('neis_school_code')) as c(column_name)
order by role_name, column_name;
-- anon false/false/false; authenticated and service_role true/true/true.
-- Existing table-level SELECT/service_role grants remain; RLS applies to authenticated.

select relrowsecurity from pg_class where oid = 'public.profiles'::regclass;
select policyname, roles, cmd, qual, with_check
from pg_policies where schemaname = 'public' and tablename = 'profiles'
order by policyname;
-- RLS true; original four owner policies unchanged.

select count(*) as partial_pairs,
  count(*) filter (where neis_office_code is not null) as partial_with_office
from public.profiles
where (neis_office_code is null) <> (neis_school_code is null);
-- Both counts zero.

select count(*) as profile_rows,
  md5(coalesce(string_agg(
    jsonb_build_array(id, display_name, grade_level, created_at, updated_at)::text,
    E'\n' order by id
  ), '')) as existing_columns_fingerprint
from public.profiles;
-- Compare row count AND fingerprint to profile_school_before.sql results.
-- Avoid concurrent profile writes during comparison. A mismatch requires investigation;
-- without a before snapshot, this query alone cannot prove unchanged existing rows.

select count(*) as non_null_school_rows from public.profiles
where neis_office_code is not null or neis_school_code is not null;
-- Zero immediately after this migration, before any school writes.
