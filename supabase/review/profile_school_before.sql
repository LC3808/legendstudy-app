-- Owner: run BEFORE migration; retain this result for comparison. Read-only.
select count(*) as profile_rows,
  md5(coalesce(string_agg(
    jsonb_build_array(id, display_name, grade_level, created_at, updated_at)::text,
    E'\n' order by id
  ), '')) as existing_columns_fingerprint
from public.profiles;
