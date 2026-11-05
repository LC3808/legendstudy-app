begin read only;
select status,is_current,count(*) from public.grade_cutoff_references group by 1,2;
select e.academic_year,e.exam_month,count(*) as rows,count(*) filter(where r.raw_score is not null or r.raw_score_min is not null) as raw_rows
from public.grade_cutoff_references r join public.exams e using(content_item_id) where r.is_current group by 1,2 order by 1,2;
select relrowsecurity from pg_class where oid='public.grade_cutoff_references'::regclass;
select role,has_table_privilege(role,'public.grade_cutoff_references','SELECT') as can_read,has_table_privilege(role,'public.grade_cutoff_references','INSERT,UPDATE,DELETE,TRUNCATE') as can_write from (values('anon'),('authenticated')) t(role);
set local role anon;
select jsonb_array_length(public.grade_cutoff_lookup('66d59401-acf9-59ce-b497-ccfb89a9adf2')) as published_2024_june_rows;
commit;
