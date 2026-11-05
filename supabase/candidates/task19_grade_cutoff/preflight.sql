begin read only;
select current_database(),current_user,version();
select to_regclass('public.grade_cutoff_references'),to_regprocedure('public.grade_cutoff_lookup(uuid)');
select conname,pg_get_constraintdef(oid) from pg_constraint where conrelid='public.exam_subjects'::regclass and contype in ('p','u');
select e.academic_year,e.exam_month,e.exam_type,e.content_item_id,c.source_url,c.is_active,count(s.id) as subject_count
from public.exams e join public.content_items c on c.id=e.content_item_id left join public.exam_subjects s on s.content_item_id=e.content_item_id and s.is_active
where e.grade_level=3 and e.academic_year between 2024 and 2027 and ((e.exam_type='evaluation_mock' and e.exam_month in(6,9)) or (e.exam_type='csat' and e.academic_year<2027 and e.exam_month=11))
group by e.academic_year,e.exam_month,e.exam_type,e.content_item_id,c.source_url,c.is_active order by 1,2;
select count(*) as original_grading_version_count from public.grade_cutoff_versions;
select has_table_privilege('anon','public.exams','select'),has_table_privilege('anon','public.exam_subjects','select'),has_table_privilege('anon','public.content_items','select');
commit;
