-- AFTER both migrations only; pure reads. Do not run submit/reserve/finish for QA.
begin read only;
select count(*) mapped_leaf_rows from public.math_subproblems where essay_question_id is not null; -- 0, no backfill
select count(*) invalid_mapping from public.math_subproblems l
join public.math_problems p on p.id=l.problem_id join public.math_problem_sets s on s.id=p.problem_set_id
join public.essay_questions q on q.id=l.essay_question_id where q.essay_exam_id<>s.essay_exam_id; -- 0
select r,
 has_function_privilege(r,'public.essay_browse_catalog(text)','EXECUTE') browse,
 has_function_privilege(r,'public.essay_exam_submit(uuid,uuid,uuid,jsonb,uuid)','EXECUTE') submit,
 has_function_privilege(r,'public.essay_exam_submit_cycle(uuid,uuid,uuid,jsonb,uuid,uuid)','EXECUTE') cycle,
 has_function_privilege(r,'essay_exam_private.confirmed_answers(uuid,uuid,uuid,jsonb)','EXECUTE') resolver
from unnest(array['anon','authenticated','service_role','essay_worker']) r;
-- Expected browse true only anon/authenticated; submit/cycle true only essay_worker; resolver false all four.
select count(*) active_cohort from public.essay_exams e join essay_material_private.reviews r on r.exam_id=e.id
where r.state='NEEDS_REVIEW' and e.is_active; -- 0
select count(*) published_cohort from public.essay_questions q join essay_material_private.reviews r on r.exam_id=q.essay_exam_id
where r.state='NEEDS_REVIEW' and q.is_published; -- 0
set local role anon;
select count(*) visible_private_materials from storage.objects where bucket_id='essay-material-originals'; -- 0
select jsonb_array_length(public.essay_browse_catalog('gachon')) gachon_exams; -- >=17
select public.essay_browse_catalog('unknown') unknown_identity; -- []
rollback;
