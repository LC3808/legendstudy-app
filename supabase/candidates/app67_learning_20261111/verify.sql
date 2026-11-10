-- Read-only: do not call my_application_save on production for testing.
select n.nspname,p.proname,md5(pg_get_functiondef(p.oid)) as definition_md5,p.proacl
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where (n.nspname='student_private' and p.proname='study_summary')
 or (n.nspname='public' and p.proname in ('my_application_save','my_study_summary'));
-- Existing duplicate groups are reported, never merged/deleted by this candidate.
select count(*) as duplicate_groups from (
 select user_id,admission_year,university_id,btrim(intended_division),btrim(admission_type),btrim(admission_name)
 from public.student_applications group by 1,2,3,4,5,6 having count(*)>1
) d;
