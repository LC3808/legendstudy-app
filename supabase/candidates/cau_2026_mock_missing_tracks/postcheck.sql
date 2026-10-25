-- READ ONLY. Metadata only. Does not certify Worker/PDF availability.
select (select count(*)=2 from public.essay_exams where id in ('c7e17f5e-9037-5a78-8e77-7878a98230ca'::uuid,'53bdd6f5-78be-548f-ac1b-23081f9bf74c'::uuid) and not is_active and verification_status='review') as two_inactive_exams,
 (select count(*)=6 from public.essay_questions where essay_exam_id in ('c7e17f5e-9037-5a78-8e77-7878a98230ca'::uuid,'53bdd6f5-78be-548f-ac1b-23081f9bf74c'::uuid) and not is_published) as six_question_units,
 (select count(*)=3 from public.essay_exams where university_id='ffad67a6-107f-47b7-a1cb-ab61687ffb9f' and admission_year=2026 and exam_kind='mock' and field_or_division in ('인문사회','경영경제','자연계열')) as three_tracks,
 (select count(*)=4 from public.resources where id in ('711f74c6-ba77-5d61-ab12-b39b14504f9f'::uuid,'fc2c55e8-7c3c-5d83-9ae3-9ffba848f09e'::uuid,'99533452-4eb1-5eaf-8e24-6b19151722d6'::uuid,'dc1e6b23-4656-562f-83a3-f6a49f959696'::uuid) and is_active) as resources_preserved;
