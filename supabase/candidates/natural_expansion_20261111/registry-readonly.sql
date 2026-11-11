-- Metadata only, no PII/answers/content. Run only against LegendStudy.
select u.id as university_id,u.slug,u.name,
 e.id as exam_id,e.admission_year,e.exam_kind,e.field_or_division,
 e.session_label,e.campus,e.exam_name,e.exam_key,e.official_source_url,
 e.verification_status,e.is_active,
 q.id as question_id,q.label,q.display_order,q.is_published,
 coalesce((select jsonb_agg(jsonb_build_object(
 'leaf_id',s.id,'problem_state',p.state,'set_state',ps.state))
 from public.math_subproblems s
 join public.math_problems p on p.id=s.problem_id
 join public.math_problem_sets ps on ps.id=p.problem_set_id
 where s.essay_question_id=q.id),'[]'::jsonb) as math_bindings
from public.universities u
left join public.essay_exams e on e.university_id=u.id
left join public.essay_questions q on q.essay_exam_id=e.id
order by u.slug,e.admission_year,e.id,q.display_order;
