-- READ ONLY. stlhijzpjfgwwdgunlsd. Expected: all true before first application.
select (select count(*)=4 from public.resources where id in ('711f74c6-ba77-5d61-ab12-b39b14504f9f'::uuid,'fc2c55e8-7c3c-5d83-9ae3-9ffba848f09e'::uuid,'99533452-4eb1-5eaf-8e24-6b19151722d6'::uuid,'dc1e6b23-4656-562f-83a3-f6a49f959696'::uuid) and is_active) as four_existing_resources,
 not exists(select 1 from public.essay_exams where university_id='ffad67a6-107f-47b7-a1cb-ab61687ffb9f' and admission_year=2026 and exam_kind='mock' and field_or_division in ('인문사회','경영경제')) as missing_exact_tracks,
 exists(select 1 from public.essay_exams where id='0723cb5a-6061-514d-9e2e-968662ea180f' and exam_kind='mock' and admission_year=2026 and field_or_division='자연계열') as natural_preserved,
 not exists(select 1 from public.essay_exams where id in ('c7e17f5e-9037-5a78-8e77-7878a98230ca'::uuid,'53bdd6f5-78be-548f-ac1b-23081f9bf74c'::uuid)) as new_ids_unused;
